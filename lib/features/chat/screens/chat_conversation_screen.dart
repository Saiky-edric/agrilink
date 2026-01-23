import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/user_model.dart';
import '../services/chat_service.dart';
import '../../../core/models/order_model.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final OrderItemModel? productCardDraft; // optional draft for buyer flow
  
  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    this.productCardDraft,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  ConversationModel? _conversation;
  UserModel? _currentUser;
  String? _otherUserName;
  bool _isLoading = true;
  bool _isSending = false;
  OrderItemModel? _draftItem;
  RealtimeChannel? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _draftItem = widget.productCardDraft;
    _loadConversationData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversationData() async {
    try {
      final messages = await _chatService.getMessages(widget.conversationId);
      final user = await _authService.getCurrentUserProfile();
      
      setState(() {
        _messages = messages;
        _currentUser = user;
        _isLoading = false;
      });

      // Subscribe to real-time messages
      _subscribeToMessages();
      
      // Mark messages as read
      if (user != null) {
        await _chatService.markMessagesAsRead(
          conversationId: widget.conversationId,
          userId: user.id,
        );
      }

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription = _chatService.subscribeToMessages(
      conversationId: widget.conversationId,
      onMessage: (message) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        _messageController.text = content; // Restore message
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftBar = _buildDraftCardBar();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _getOtherUserName(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Chat',
                  style: const TextStyle(fontSize: 18),
                );
              },
            ),
            const Text(
              'Last seen recently', // Online status implementation needed
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options menu
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(),
                ),

                // Optional draft product card (buyer flow)
                if (_draftItem != null) draftBar,
                
                // Message input
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Start the conversation',
              style: AppTextStyles.bodyLarge,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Send a message to begin chatting',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromCurrentUser = message.senderId == _currentUser?.id;
        
        return _buildMessageBubble(message, isFromCurrentUser);
      },
    );
  }

 Future<String?> _getUserAvatarUrl(String userId) async {
   try {
     final res = await _chatService.supabaseService.users
         .select('avatar_url, store_logo_url, role')
         .eq('id', userId)
         .single();
     final role = res['role'] as String?;
     if (role == 'farmer') {
       return (res['store_logo_url'] as String?) ?? (res['avatar_url'] as String?);
     }
     return res['avatar_url'] as String?;
   } catch (_) {
     return null;
   }
 }

  Widget _buildMessageBubble(MessageModel message, bool isFromCurrentUser) {
    final otherUserId = isFromCurrentUser
        ? (_conversation?.buyerId == _currentUser?.id ? _conversation?.farmerId : _conversation?.buyerId)
        : (_currentUser?.id);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isFromCurrentUser)
          FutureBuilder<String?>(
            future: _getUserAvatarUrl(message.senderId),
            builder: (context, snapshot) {
              final url = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                  child: (url == null || url.isEmpty)
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              );
            },
          ),
        Flexible(
          child: Align(
            alignment: isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Column(
                crossAxisAlignment: isFromCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isFromCurrentUser ? AppTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.large),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(message, isFromCurrentUser),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isFromCurrentUser)
          FutureBuilder<String?>(
            future: _getUserAvatarUrl(message.senderId),
            builder: (context, snapshot) {
              final url = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                  child: (url == null || url.isEmpty)
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }
    // cleaned: removed duplicate block
    // (block intentionally deleted)
  
  Widget _buildDraftCardBar() {
    final item = _draftItem;
    if (item == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
                ? Image.network(item.productImageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.white,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('${item.quantity} x ₱${item.unitPrice.toStringAsFixed(2)} • ${item.unit}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('₱${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove',
            onPressed: () => setState(() => _draftItem = null),
          ),
          const SizedBox(width: AppSpacing.xs),
          ElevatedButton(
            onPressed: _sendDraftCard,
            child: const Text('Send'),
          )
        ],
      ),
    );
  }

  Future<void> _sendDraftCard() async {
    final item = _draftItem;
    if (item == null || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _chatService.sendProductCard(conversationId: widget.conversationId, item: item);
      setState(() => _draftItem = null);
      await _loadConversationData();
      _scrollToBottom();
    } catch (_) {
      // show error
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getOtherUserName() async {
    try {
      if (_currentUser == null) return 'Chat';
      
      // Get conversation to determine other user
      final response = await _chatService.supabaseService.conversations
          .select('''
            *,
            buyer:users!conversations_buyer_id_fkey(full_name),
            farmer:users!conversations_farmer_id_fkey(full_name, store_name)
          ''')
          .eq('id', widget.conversationId)
          .single();
      
      final conversation = ConversationModel.fromJson(response);
      final isCurrentUserBuyer = _currentUser!.role == UserRole.buyer;

      if (isCurrentUserBuyer) {
        // Show store name for farmers if available
        final store = (response['farmer']['store_name'] as String?)?.trim();
        if (store != null && store.isNotEmpty) return store;
        return response['farmer']['full_name'] as String;
      } else {
        return response['buyer']['full_name'] as String;
      }
    } catch (e) {
      return 'Chat';
    }
  }

  Widget _buildMessageContent(MessageModel message, bool isFromCurrentUser) {
    try {
      final data = jsonDecode(message.content);
      if (data is Map && data['type'] == 'product_card') {
        return _buildProductCardMessage(data, isFromCurrentUser);
      }
    } catch (_) {
      // Not JSON, treat as plain text
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isFromCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildProductCardMessage(Map data, bool isFromCurrentUser) {
    final imageUrl = data['image_url'] as String?;
    final productName = data['product_name'] as String? ?? 'Product';
    final unitPrice = (data['unit_price'] as num?)?.toDouble();
    final qty = data['quantity'] as int?;
    final unit = data['unit'] as String?;
    final subtotal = (data['subtotal'] as num?)?.toDouble();

    final caption = isFromCurrentUser
        ? 'You sent a message'
        : 'Buyer has sent you a message';

    return Column(
      crossAxisAlignment:
          isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            caption,
            style: TextStyle(
              color: isFromCurrentUser ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.white,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      color: isFromCurrentUser ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (unitPrice != null && qty != null && unit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$qty x ₱${unitPrice.toStringAsFixed(2)} • $unit',
                      style: TextStyle(
                        color: isFromCurrentUser ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (subtotal != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '₱${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isFromCurrentUser ? Colors.white : AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    )
                  ]
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}