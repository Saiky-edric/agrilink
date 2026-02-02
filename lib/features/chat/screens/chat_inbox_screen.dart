import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/user_model.dart';
import '../services/chat_service.dart';
import 'dart:convert';
import '../../../shared/widgets/modern_bottom_nav.dart';
import '../../../shared/widgets/farmer_bottom_nav.dart';
import '../../../core/services/badge_service.dart';

class ChatInboxScreen extends StatefulWidget {
  final String? origin; // 'farmer' or 'buyer'
  const ChatInboxScreen({super.key, this.origin});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  
  List<ConversationModel> _conversations = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatService.getConversations();
      final user = await _authService.getCurrentUserProfile();
      
      setState(() {
        _conversations = conversations;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () {
            // Smart navigation - check if we can pop back
            if (Navigator.of(context).canPop()) {
             context.pop();
           } else {
             // Prefer explicit origin when available to avoid role-loading flicker
             if (widget.origin == 'farmer') {
               context.go(RouteNames.farmerDashboard);
             } else if (widget.origin == 'buyer') {
               context.go(RouteNames.buyerHome);
             } else {
               // Fallback to role-based routing
               if (_currentUser?.role == UserRole.farmer) {
                 context.go(RouteNames.farmerDashboard);
               } else {
                 context.go(RouteNames.buyerHome);
               }
             }
           }
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              // Navigate to role-specific AI support
              if (_currentUser?.role == UserRole.farmer) {
                context.push(RouteNames.farmerSupportChat);
              } else {
                context.push(RouteNames.supportChat); // Buyer support
              }
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message search coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New conversation coming soon!')),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
      // Default to buyer bottom nav while role is loading to prevent flicker
      bottomNavigationBar: (
              // Prefer explicit origin to avoid flicker/mismatch
              (widget.origin == 'buyer') ||
              (_currentUser != null && _currentUser!.role == UserRole.buyer)
            )
          ? const ModernBottomNav(currentIndex: 3)
          : FarmerBottomNav(
              currentIndex: 3,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('${RouteNames.farmerDashboard}?tab=0');
                    break;
                  case 1:
                    context.go('${RouteNames.farmerDashboard}?tab=1');
                    break;
                  case 2:
                    context.go('${RouteNames.farmerDashboard}?tab=2');
                    break;
                  case 3:
                    // already here
                    break;
                  case 4:
                    context.go('${RouteNames.farmerDashboard}?tab=4');
                    break;
                }
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'No messages yet',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _currentUser?.role == UserRole.buyer
                  ? 'Start shopping and chat with farmers about their fresh products!'
                  : 'Buyers will message you when they have questions about your products',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentUser?.role == UserRole.buyer) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go(RouteNames.buyerHome),
                    child: const Text('Start Shopping'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => context.go(RouteNames.categories),
                    child: const Text('Find Farmers'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: Column(
        children: [
          // Messages header with count
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, color: AppTheme.primaryGreen),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${_conversations.length} conversation${_conversations.length > 1 ? 's' : ''}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mark all as read coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.mark_chat_read, size: 18),
                  label: const Text('Mark all read'),
                ),
              ],
            ),
          ),
          
          // Conversations list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: 100, // Space for bottom navigation
              ),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationCard(conversation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(ConversationModel conversation) {
    final isCurrentUserBuyer = _currentUser?.role == UserRole.buyer;
    final otherUserId = isCurrentUserBuyer 
        ? conversation.farmerId 
        : conversation.buyerId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push(
          RouteNames.chatConversation.replaceAll(':conversationId', conversation.id),
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Avatar
              FutureBuilder<String?>(
                future: _getOtherUserAvatarUrl(
                  otherUserId,
                  isCurrentUserBuyer ? true : false,
                ),
                builder: (context, snapshot) {
                  final url = snapshot.data;
                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    backgroundImage: (url != null && url.isNotEmpty)
                        ? NetworkImage(url)
                        : null,
                    child: (url == null || url.isEmpty)
                        ? Icon(
                            isCurrentUserBuyer ? Icons.agriculture : Icons.person,
                            color: AppTheme.primaryGreen,
                            size: 30,
                          )
                        : null,
                  );
                },
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    FutureBuilder<String>(
                      future: _getOtherUserName(
                        otherUserId,
                        otherIsFarmer: isCurrentUserBuyer,
                      ),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Last message
                    FutureBuilder<MessageModel?>(
                      future: ChatService().getLastMessage(conversation.id),
                      builder: (context, snapshot) {
                        final last = snapshot.data;
                        if (last == null) {
                          return Text(
                            'No messages yet',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          );
                        }
                        // If it's a product card, show friendly caption with product name
                        String preview;
                        try {
                          final data = jsonDecode(last.content);
                          if (data is Map && data['type'] == 'product_card') {
                            final isFromCurrentUser = last.senderId == (AuthService().currentUser?.id);
                            final name = (data['product_name'] as String?)?.trim();
                            final suffix = (name != null && name.isNotEmpty) ? ': $name' : '';
                            preview = isFromCurrentUser
                                ? 'You sent product details$suffix'
                                : 'Buyer sent product details$suffix';
                          } else {
                            preview = last.content;
                          }
                        } catch (_) {
                          preview = last.content;
                        }
                        return Text(
                          preview,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Time
                    if (conversation.lastMessageAt != null)
                      Text(
                        _formatTime(conversation.lastMessageAt!),
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getOtherUserName(String userId, {required bool otherIsFarmer}) async {
    try {
      final response = await _chatService.supabaseService.users
          .select('full_name, store_name')
          .eq('id', userId)
          .single();
      if (otherIsFarmer) {
        final store = (response['store_name'] as String?)?.trim();
        if (store != null && store.isNotEmpty) return store;
      }
      return response['full_name'] as String;
    } catch (e) {
      return 'Unknown User';
    }
  }

  Future<String?> _getOtherUserAvatarUrl(String userId, bool otherIsFarmer) async {
    try {
      final response = await _chatService.supabaseService.users
          .select('avatar_url, store_logo_url')
          .eq('id', userId)
          .single();
      if (otherIsFarmer) {
        return (response['store_logo_url'] as String?) ?? (response['avatar_url'] as String?);
      } else {
        return response['avatar_url'] as String?;
      }
    } catch (e) {
      return null;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      // When a message is very recent, show actual send time instead of "Just now"
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
  }
}