import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationType {
  orderUpdate,
  verificationStatus,
  newMessage,
  productUpdate,
  paymentUpdate,
  deliveryUpdate,
  systemAlert,
  promotion,
  general
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // In a real app, you would initialize Firebase Cloud Messaging here
      // await Firebase.initializeApp();
      // FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request permission for notifications
      // NotificationSettings settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   provisional: false,
      //   sound: true,
      // );
      
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  // Get FCM token for device
  Future<String?> getToken() async {
    try {
      // In a real app: return await FirebaseMessaging.instance.getToken();
      return 'mock-fcm-token-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      // In a real app: await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // In a real app: await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    try {
      // In a real app, you would use flutter_local_notifications
      debugPrint('Local notification: $title - $body');
      
      // For demo purposes, we'll simulate the notification
      _simulateNotification(title, body, type, data);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Send push notification (server-side simulation)
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    try {
      // In a real app, this would send a request to your backend
      // which would then use Firebase Admin SDK to send the notification
      
      debugPrint('Push notification sent to $token: $title - $body');
      
      // Simulate the notification locally for demo
      await showLocalNotification(
        title: title,
        body: body,
        type: type,
        data: data,
      );
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  // Handle background message (when app is in background)
  Future<void> handleBackgroundMessage() async {
    // In a real app: FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Background message handler configured');
  }

  // Handle foreground message (when app is active)
  void handleForegroundMessage(BuildContext context) {
    // In a real app:
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   _showInAppNotification(context, message);
    // });
    debugPrint('Foreground message handler configured');
  }

  // Get notification history from database
  Future<List<NotificationItem>> getNotificationHistory() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return [];
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((notification) => NotificationItem.fromJson(notification))
          .toList();
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      // Fallback to mock notifications for demo
      return _getMockNotifications();
    }
  }

  // Clear notification history
  Future<void> clearNotificationHistory() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', currentUser.id);

      debugPrint('Notification history cleared');
    } catch (e) {
      debugPrint('Error clearing notification history: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      debugPrint('Notification $notificationId marked as read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      debugPrint('All notifications marked as read for user ${currentUser.id}');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Send notification to a specific user (create in database)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Try direct insert first
      final result = await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (result.isNotEmpty) {
        debugPrint('✅ Notification sent to user $userId: $title');
      } else {
        debugPrint('⚠️ Direct insert returned empty, trying RLS bypass...');
        await _sendNotificationViaRPC(userId, title, message, type, data);
      }
    } catch (e) {
      debugPrint('❌ Error sending notification (direct): $e');
      
      // Try using RPC function as fallback
      try {
        await _sendNotificationViaRPC(userId, title, message, type, data);
      } catch (rpcError) {
        debugPrint('❌ Error sending notification (RPC): $rpcError');
        debugPrint('⚠️ Please run FIX_NOTIFICATION_RLS.sql to fix notification permissions');
        // Don't throw - notifications shouldn't break the main flow
      }
    }
  }

  // Helper method to send notification via RPC function (bypasses RLS)
  Future<void> _sendNotificationViaRPC(
    String userId,
    String title,
    String message,
    String type,
    Map<String, dynamic>? data,
  ) async {
    final notificationId = await _supabase.rpc('send_notification', params: {
      'target_user_id': userId,
      'notification_title': title,
      'notification_message': message,
      'notification_type': type,
      'notification_data': data,
    });
    
    debugPrint('✅ Notification sent via RPC to user $userId: $title (ID: $notificationId)');
  }

  // Private helper methods
  void _simulateNotification(
    String title,
    String body,
    NotificationType type,
    Map<String, dynamic>? data,
  ) {
    // This would trigger the actual notification display
    debugPrint('📱 Notification: $title');
    debugPrint('   Body: $body');
    debugPrint('   Type: $type');
    if (data != null) debugPrint('   Data: $data');
  }

  List<NotificationItem> _getMockNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'Order Confirmed',
        body: 'Your order #12345 has been confirmed by the farmer.',
        type: NotificationType.orderUpdate,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Verification Approved',
        body: 'Your farmer verification has been approved!',
        type: NotificationType.verificationStatus,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: 'New Message',
        body: 'You have a new message from John Doe',
        type: NotificationType.newMessage,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      NotificationItem(
        id: '4',
        title: 'Product Available',
        body: 'Fresh tomatoes are now available in your area!',
        type: NotificationType.productUpdate,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}

// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      timestamp: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      // Handle missing data column gracefully
      data: json.containsKey('data') ? json['data'] as Map<String, dynamic>? : null,
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.shopping_cart;
      case NotificationType.verificationStatus:
        return Icons.verified;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.productUpdate:
        return Icons.inventory;
      case NotificationType.paymentUpdate:
        return Icons.payment;
      case NotificationType.deliveryUpdate:
        return Icons.local_shipping;
      case NotificationType.systemAlert:
        return Icons.warning;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  // Get color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.verificationStatus:
        return Colors.green;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.productUpdate:
        return Colors.orange;
      case NotificationType.paymentUpdate:
        return Colors.green;
      case NotificationType.deliveryUpdate:
        return Colors.blue;
      case NotificationType.systemAlert:
        return Colors.red;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }
}