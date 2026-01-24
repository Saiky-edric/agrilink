import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Helper service to integrate notifications into business logic flows
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // =============================================
  // VERIFICATION NOTIFICATIONS
  // =============================================

  /// Send notification for verification events
  Future<void> sendVerificationNotification({
    required String farmerId,
    required String verificationId,
    required String type,
  }) async {
    try {
      String title;
      String message;
      
      switch (type) {
        case 'new_verification':
          title = 'Verification Submitted';
          message = 'Your farmer verification has been submitted and is under review.';
          break;
        case 'verification_approved':
          title = 'Verification Approved';
          message = 'Congratulations! Your farmer verification has been approved.';
          break;
        case 'verification_rejected':
          title = 'Verification Needs Attention';
          message = 'Your farmer verification requires additional information.';
          break;
        default:
          title = 'Verification Update';
          message = 'Your verification status has been updated.';
      }

      await _createDatabaseNotification(
        userId: farmerId,
        title: title,
        message: message,
        type: 'verification',
        relatedId: verificationId,
      );

      // Also send local notification if user is active
      await _notificationService.showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.verificationStatus,
        data: {'verification_id': verificationId},
      );
    } catch (e) {
      print('Error sending verification notification: $e');
    }
  }

  // =============================================
  // ORDER NOTIFICATIONS
  // =============================================

  /// Send notification when a new order is placed
  Future<void> notifyNewOrder({
    required String orderId,
    required String farmerId,
    required String buyerName,
    required double totalAmount,
  }) async {
    try {
      await _createDatabaseNotification(
        userId: farmerId,
        title: 'New Order Received',
        message: 'You have a new order from $buyerName worth ₱${totalAmount.toStringAsFixed(2)}',
        type: 'orderUpdate',
        relatedId: orderId,
      );

      // Also send local notification if user is active
      await _notificationService.showLocalNotification(
        title: 'New Order Received',
        body: 'You have a new order from $buyerName worth ₱${totalAmount.toStringAsFixed(2)}',
        type: NotificationType.orderUpdate,
        data: {'order_id': orderId},
      );
    } catch (e) {
      print('Error sending new order notification: $e');
    }
  }

  /// Send notification when order status changes
  /// Pass farmerId to fetch store name for buyer notifications
  Future<void> notifyOrderStatusChange({
    required String orderId,
    required String userId,
    required String status,
    required String otherUserName,
    bool isForFarmer = false,
    String? farmerId, // Optional: to fetch store name for buyers
  }) async {
    try {
      String title = '';
      String message = '';
      
      // If notification is for buyer and we have farmerId, use store name instead
      String displayName = otherUserName;
      if (!isForFarmer && farmerId != null) {
        try {
          final farmerData = await _supabase
              .from('users')
              .select('store_name, full_name')
              .eq('id', farmerId)
              .single();
          
          // Use store_name if available, fallback to full_name
          displayName = (farmerData['store_name'] as String?)?.isNotEmpty == true
              ? farmerData['store_name'] as String
              : (farmerData['full_name'] as String? ?? otherUserName);
        } catch (e) {
          print('Error fetching farmer store name: $e');
          // Keep using otherUserName as fallback
        }
      }

      switch (status) {
        case 'accepted':
          title = 'Order Confirmed';
          message = '$displayName has accepted your order. It will be prepared soon!';
          break;
        case 'rejected':
          title = 'Order Declined';
          message = 'Unfortunately, $displayName cannot fulfill your order at this time.';
          break;
        case 'preparing':
          title = 'Order Being Prepared';
          message = '$displayName is preparing your order. It will be ready soon!';
          break;
        case 'ready':
          title = 'Order Ready';
          message = 'Your order from $displayName is ready for pickup/delivery!';
          break;
        case 'completed':
          title = isForFarmer ? 'Order Completed' : 'Order Delivered';
          message = isForFarmer 
              ? 'Order for $otherUserName has been successfully delivered.'
              : 'Your order from $displayName has been delivered. Thank you for your purchase!';
          break;
        case 'cancelled':
          title = 'Order Cancelled';
          message = isForFarmer
              ? '$otherUserName has cancelled their order.'
              : 'Your order has been cancelled.';
          break;
        default:
          title = 'Order Updated';
          message = 'Your order status has been updated to $status.';
      }

      await _createDatabaseNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'orderUpdate',
        relatedId: orderId,
      );

      await _notificationService.showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.orderUpdate,
        data: {'order_id': orderId, 'status': status},
      );
    } catch (e) {
      print('Error sending order status notification: $e');
    }
  }

  // =============================================
  // VERIFICATION NOTIFICATIONS
  // =============================================

  /// Send notification when verification status changes
  Future<void> notifyVerificationStatusChange({
    required String verificationId,
    required String farmerId,
    required String status,
    required String farmName,
    String? rejectionReason,
    String? reviewedBy,
  }) async {
    try {
      String title = '';
      String message = '';

      switch (status) {
        case 'approved':
          title = 'Verification Approved! 🎉';
          message = 'Congratulations! Your farmer verification has been approved. You can now start selling your products.';
          break;
        case 'rejected':
          title = 'Verification Requires Attention';
          message = 'Your verification needs additional information. Please check the details and resubmit.';
          break;
        case 'pending':
          title = 'Verification Submitted';
          message = 'Your farmer verification has been submitted. We will review it within 2-3 business days.';
          break;
        default:
          title = 'Verification Updated';
          message = 'Your verification status has been updated.';
      }

      await _createDatabaseNotification(
        userId: farmerId,
        title: title,
        message: message,
        type: 'verificationStatus',
        relatedId: verificationId,
      );

      await _notificationService.showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.verificationStatus,
        data: {'verification_id': verificationId, 'status': status},
      );
    } catch (e) {
      print('Error sending verification notification: $e');
    }
  }

  /// Notify all admins about new verification request
  Future<void> notifyAdminsNewVerification({
    required String verificationId,
    required String farmerName,
    required String farmName,
  }) async {
    try {
      // Get all admin users
      final adminsResponse = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'admin')
          .eq('is_active', true);

      final adminIds = (adminsResponse as List)
          .map((admin) => admin['id'] as String)
          .toList();

      // Create notifications for all admins
      for (final adminId in adminIds) {
        await _createDatabaseNotification(
          userId: adminId,
          title: 'New Verification Request',
          message: '$farmerName has submitted farmer verification documents for review.',
          type: 'verificationStatus',
          relatedId: verificationId,
        );
      }
    } catch (e) {
      print('Error notifying admins about verification: $e');
    }
  }

  // =============================================
  // MESSAGE NOTIFICATIONS
  // =============================================

  /// Send notification for new chat message
  Future<void> notifyNewMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String senderName,
    required String messageContent,
  }) async {
    try {
      final truncatedMessage = messageContent.length > 50
          ? '${messageContent.substring(0, 50)}...'
          : messageContent;

      await _createDatabaseNotification(
        userId: receiverId,
        title: 'New Message from $senderName',
        message: truncatedMessage,
        type: 'newMessage',
        relatedId: conversationId,
      );

      await _notificationService.showLocalNotification(
        title: 'New Message from $senderName',
        body: truncatedMessage,
        type: NotificationType.newMessage,
        data: {'conversation_id': conversationId},
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  // =============================================
  // PRODUCT NOTIFICATIONS
  // =============================================

  /// Send notification about new product to local buyers
  Future<void> notifyNewProduct({
    required String productId,
    required String farmerId,
    required String productName,
    required double price,
    required String farmerName,
    required String location,
  }) async {
    try {
      // Get the farmer's municipality and store name
      final farmerResponse = await _supabase
          .from('users')
          .select('municipality, store_name, full_name')
          .eq('id', farmerId)
          .single();

      final farmerMunicipality = farmerResponse['municipality'] as String?;
      
      // Use store_name if available, fallback to full_name or passed farmerName
      final displayName = (farmerResponse['store_name'] as String?)?.isNotEmpty == true
          ? farmerResponse['store_name'] as String
          : (farmerResponse['full_name'] as String? ?? farmerName);

      if (farmerMunicipality != null) {
        // Get all buyers in the same municipality
        final buyersResponse = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'buyer')
            .eq('is_active', true)
            .eq('municipality', farmerMunicipality);

        final buyerIds = (buyersResponse as List)
            .map((buyer) => buyer['id'] as String)
            .toList();

        // Create notifications for all local buyers
        for (final buyerId in buyerIds) {
          await _createDatabaseNotification(
            userId: buyerId,
            title: 'New Product Available',
            message: '$displayName has added fresh $productName in $location',
            type: 'productUpdate',
            relatedId: productId,
          );
        }
      }
    } catch (e) {
      print('Error sending new product notifications: $e');
    }
  }

  /// Send low stock alert to farmer
  Future<void> notifyLowStock({
    required String productId,
    required String farmerId,
    required String productName,
    required int currentStock,
    required String unit,
  }) async {
    try {
      await _createDatabaseNotification(
        userId: farmerId,
        title: 'Low Stock Alert',
        message: 'Your $productName is running low (only $currentStock $unit left)',
        type: 'productUpdate',
        relatedId: productId,
      );

      await _notificationService.showLocalNotification(
        title: 'Low Stock Alert',
        body: 'Your $productName is running low',
        type: NotificationType.productUpdate,
        data: {'product_id': productId, 'action': 'low_stock'},
      );
    } catch (e) {
      print('Error sending low stock notification: $e');
    }
  }

  // =============================================
  // UTILITY METHODS
  // =============================================

  /// Create notification in database
  Future<void> _createDatabaseNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating database notification: $e');
      rethrow;
    }
  }

  /// Get unread notification count for current user
  Future<int> getUnreadNotificationCount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Subscribe to real-time notifications for current user
  Stream<List<Map<String, dynamic>>> subscribeToNotifications() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);
  }
}