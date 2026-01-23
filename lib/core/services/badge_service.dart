import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeService extends ChangeNotifier {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Badge counts
  int _cartItemCount = 0;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  int _pendingOrders = 0;
  int _newOrders = 0;
  int _acceptedOrders = 0;
  int _toPackOrders = 0;
  int _toDeliverOrders = 0;

  // Getters
  int get cartItemCount => _cartItemCount;
  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;
  int get pendingOrders => _pendingOrders;
  int get newOrders => _newOrders;
  int get acceptedOrders => _acceptedOrders;
  int get toPackOrders => _toPackOrders;
  int get toDeliverOrders => _toDeliverOrders;
  
  // Total orders requiring attention
  int get totalActiveOrders => _newOrders + _acceptedOrders + _toPackOrders + _toDeliverOrders;
  
  // Total notifications (orders + notifications + messages)
  int get totalNotifications => _unreadNotifications + totalActiveOrders;
  
  // Pure notification count (without orders) for notification bell
  int get pureNotificationCount => _unreadNotifications;

  // Initialize all badge counts
  Future<void> initializeBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await Future.wait([
      loadCartCount(),
      _loadNotificationCount(),
      _loadMessageCount(),
      _loadOrderCount(),
    ]);
  }

  // Cart count (public so other services can call it)
  Future<void> loadCartCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('cart')
          .select('quantity')
          .eq('user_id', user.id);

      _cartItemCount = response.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  // Notification count  
  Future<void> _loadNotificationCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      _unreadNotifications = response.length;
      notifyListeners();
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  // Message count
  Future<void> _loadMessageCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Count unread messages in conversations where user is participant
      // Get conversations user participates in
      final conversations = await _supabase
          .from('conversations')
          .select('id')
          .or('buyer_id.eq.${user.id},farmer_id.eq.${user.id}');

      final conversationIds = conversations.map((conv) => conv['id']).toList();
      if (conversationIds.isEmpty) {
        _unreadMessages = 0;
        notifyListeners();
        return;
      }

      final unreadMessages = await _supabase
          .from('messages')
          .select('id')
          .neq('sender_id', user.id)
          .eq('is_read', false)
          .inFilter('conversation_id', conversationIds);

      _unreadMessages = unreadMessages.length;
      notifyListeners();
    } catch (e) {
      print('Error loading message count: $e');
    }
  }

  // Order count (pending actions)
  Future<void> _loadOrderCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final userProfile = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = userProfile['role'];

      if (role == 'buyer') {
        // For buyers: orders that need their attention (shipped, delivered, etc.)
        final response = await _supabase
            .from('orders')
            .select('id')
            .eq('buyer_id', user.id)
            .inFilter('buyer_status', ['shipped', 'delivered']);

        _pendingOrders = response.length;
      } else if (role == 'farmer') {
        // For farmers: get all order statuses that need attention
        final response = await _supabase
            .from('orders')
            .select('farmer_status')
            .eq('farmer_id', user.id);

        _newOrders = response.where((order) => order['farmer_status'] == 'newOrder').length;
        _acceptedOrders = response.where((order) => order['farmer_status'] == 'accepted').length;
        _toPackOrders = response.where((order) => order['farmer_status'] == 'toPack').length;
        _toDeliverOrders = response.where((order) => order['farmer_status'] == 'toDeliver').length;
        
        // Legacy support for existing components
        _pendingOrders = _newOrders + _acceptedOrders;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading order count: $e');
    }
  }

  // Update methods (call after actions)
  void updateCartCount(int newCount) {
    _cartItemCount = newCount;
    notifyListeners();
  }

  void markNotificationAsRead() {
    if (_unreadNotifications > 0) {
      _unreadNotifications--;
      notifyListeners();
    }
  }

  // Mark multiple notifications as read
  void markNotificationsAsRead(int count) {
    _unreadNotifications = (_unreadNotifications - count).clamp(0, _unreadNotifications);
    notifyListeners();
  }

  // Force refresh notification count (call after visiting notification screen)
  Future<void> refreshNotificationCount() async {
    await _loadNotificationCount();
  }

  void markMessageAsRead() {
    if (_unreadMessages > 0) {
      _unreadMessages--;
      notifyListeners();
    }
  }

  void markOrderAsProcessed() {
    if (_pendingOrders > 0) {
      _pendingOrders--;
      notifyListeners();
    }
  }

  // Real-time listeners
  void startListening() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Listen to cart changes
    _supabase
        .channel('cart_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cart',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => loadCartCount(),
        )
        .subscribe();

    // Listen to notification changes
    _supabase
        .channel('notification_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _loadNotificationCount(),
        )
        .subscribe();

    // Listen to message changes
    _supabase
        .channel('message_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadMessageCount(),
        )
        .subscribe();

    // Listen to order changes
    _supabase
        .channel('order_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _loadOrderCount(),
        )
        .subscribe();
  }

  void stopListening() {
    _supabase.removeAllChannels();
  }
}