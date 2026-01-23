import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../../core/models/order_model.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';

class ChatService {
  final SupabaseService _supabase = SupabaseService.instance;
  final AuthService _authService = AuthService();

  // Expose supabase instance for internal use
  SupabaseService get supabaseService => _supabase;

  // Get or create conversation between buyer and farmer
  Future<ConversationModel> getOrCreateConversation({
    required String buyerId,
    required String farmerId,
  }) async {
    try {
      // Check if conversation already exists
      final existing = await _supabase.conversations
          .select()
          .eq('buyer_id', buyerId)
          .eq('farmer_id', farmerId)
          .maybeSingle();

      if (existing != null) {
        return ConversationModel.fromJson(existing);
      }

      // Create new conversation
      const uuid = Uuid();
      final conversationId = uuid.v4();
      
      await _supabase.conversations.insert({
        'id': conversationId,
        'buyer_id': buyerId,
        'farmer_id': farmerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return ConversationModel(
        id: conversationId,
        buyerId: buyerId,
        farmerId: farmerId,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get conversations for current user
  Future<List<ConversationModel>> getConversations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return [];

      final response = await _supabase.conversations
          .select('''
            *,
            buyer:users!conversations_buyer_id_fkey(full_name, phone_number),
            farmer:users!conversations_farmer_id_fkey(full_name, phone_number)
          ''')
          .or('buyer_id.eq.${currentUser.id},farmer_id.eq.${currentUser.id}')
          .order('last_message_at', ascending: false);

      return response.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Send plain text message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      const uuid = Uuid();
      final messageId = uuid.v4();
      final now = DateTime.now();

      // Insert message
      await _supabase.messages.insert({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'content': content,
        'created_at': now.toIso8601String(),
      });

      // Update conversation last message
      await _supabase.conversations
          .update({
            'last_message': content,
            'last_message_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', conversationId);

      return MessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: currentUser.id,
        content: content,
        createdAt: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Send a structured "product card" message (JSON payload)
  Future<MessageModel> sendProductCard({
    required String conversationId,
    required OrderItemModel item,
  }) async {
    final payload = {
      'type': 'product_card',
      'product_id': item.productId,
      'product_name': item.productName,
      'image_url': item.productImageUrl,
      'unit_price': item.unitPrice,
      'unit': item.unit,
      'quantity': item.quantity,
      'subtotal': item.subtotal,
    };
    return sendMessage(
      conversationId: conversationId,
      content: jsonEncode(payload),
    );
  }

  // Get the latest message in a conversation
  Future<MessageModel?> getLastMessage(String conversationId) async {
    try {
      final rows = await _supabase.messages
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return MessageModel.fromJson(rows.first);
    } catch (e) {
      return null;
    }
  }

  // Get messages for conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _supabase.messages
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return response.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Subscribe to real-time messages
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(MessageModel) onMessage,
  }) {
    final channel = _supabase.subscribe('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final message = MessageModel.fromJson(payload.newRecord);
            onMessage(message);
          },
        );

    channel.subscribe();
    return channel;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase.messages
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      // Ignore errors for read receipts
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase.messages
          .select('id')
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}