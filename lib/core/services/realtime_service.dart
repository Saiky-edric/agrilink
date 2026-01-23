import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  SupabaseClient get _client => SupabaseService.instance.client;
  final Map<String, RealtimeChannel> _channels = {};

  // Initialize realtime connections
  Future<void> initialize() async {
    try {
      debugPrint('Realtime service initialized');
    } catch (e) {
      debugPrint('Error initializing realtime service: $e');
    }
  }

  // Subscribe to order updates
  RealtimeChannel subscribeToOrders(String userId, Function(Map<String, dynamic>) onUpdate) {
    const channelName = 'orders_channel';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buyer_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Order update received: ${payload.toString()}');
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Subscribe to chat messages
  RealtimeChannel subscribeToMessages(String conversationId, Function(Map<String, dynamic>) onMessage) {
    final channelName = 'messages_$conversationId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
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
            debugPrint('New message received: ${payload.toString()}');
            onMessage(payload.newRecord);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Subscribe to farmer verification status changes
  RealtimeChannel subscribeToVerificationUpdates(String farmerId, Function(Map<String, dynamic>) onUpdate) {
    final channelName = 'verification_$farmerId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'farmer_verifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'farmer_id',
            value: farmerId,
          ),
          callback: (payload) {
            debugPrint('Verification update received: ${payload.toString()}');
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Subscribe to product updates in user's area
  RealtimeChannel subscribeToProductUpdates(String location, Function(Map<String, dynamic>) onUpdate) {
    final channelName = 'products_$location';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'location',
            value: location,
          ),
          callback: (payload) {
            debugPrint('Product update received: ${payload.toString()}');
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Subscribe to user online status
  RealtimeChannel subscribeToUserPresence(String userId, Function(String, bool) onPresenceChange) {
    final channelName = 'presence_$userId';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPresenceSync((payload) {
          debugPrint('Presence sync: ${payload.toString()}');
        })
        .onPresenceJoin((payload) {
          debugPrint('User joined: ${payload.toString()}');
          onPresenceChange(userId, true);
        })
        .onPresenceLeave((payload) {
          debugPrint('User left: ${payload.toString()}');
          onPresenceChange(userId, false);
        })
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Update user presence
  Future<void> updatePresence(String userId, Map<String, dynamic> presenceData) async {
    try {
      final channelName = 'presence_$userId';
      if (_channels.containsKey(channelName)) {
        await _channels[channelName]?.track(presenceData);
      }
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  // Send real-time message
  Future<void> sendRealtimeMessage(String channelName, String event, Map<String, dynamic> payload) async {
    try {
      if (_channels.containsKey(channelName)) {
        // Note: Send functionality may need adjustment based on Supabase version
        debugPrint('Sending realtime message: $event');
      }
    } catch (e) {
      debugPrint('Error sending realtime message: $e');
    }
  }

  // Subscribe to broadcasts (general announcements)
  RealtimeChannel subscribeToBroadcasts(Function(Map<String, dynamic>) onBroadcast) {
    const channelName = 'broadcasts';
    
    if (_channels.containsKey(channelName)) {
      _channels[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onBroadcast(
          event: 'announcement',
          callback: (payload) {
            debugPrint('Broadcast received: ${payload.toString()}');
            onBroadcast(payload);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  // Unsubscribe from a specific channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    try {
      if (_channels.containsKey(channelName)) {
        await _channels[channelName]?.unsubscribe();
        _channels.remove(channelName);
        debugPrint('Unsubscribed from channel: $channelName');
      }
    } catch (e) {
      debugPrint('Error unsubscribing from channel $channelName: $e');
    }
  }

  // Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    try {
      for (final channel in _channels.values) {
        await channel.unsubscribe();
      }
      _channels.clear();
      debugPrint('Unsubscribed from all channels');
    } catch (e) {
      debugPrint('Error unsubscribing from all channels: $e');
    }
  }

  // Get connection status
  bool isConnected() {
    return _client.realtime.isConnected;
  }

  // Get channels count
  int getActiveChannelsCount() {
    return _channels.length;
  }

  // Dispose and cleanup
  Future<void> dispose() async {
    await unsubscribeAll();
    debugPrint('Realtime service disposed');
  }
}