import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

/// Service for managing user subscriptions
class SubscriptionService {
  final SupabaseClient _client = SupabaseService.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Activate premium subscription for a user
  Future<bool> activatePremiumSubscription({
    required String userId,
    required int durationDays,
    String paymentMethod = 'manual',
    String? paymentReference,
    double amount = 149.00,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: durationDays));

      print('🔄 Activating premium for user: $userId (Duration: $durationDays days)');

      // Update user subscription with .select() to verify
      final updateResult = await _client.from('users').update({
        'subscription_tier': 'premium',
        'subscription_started_at': now.toIso8601String(),
        'subscription_expires_at': expiresAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', userId).select();

      if (updateResult.isEmpty) {
        print('⚠️ WARNING: User update returned empty result. Update may have failed due to RLS.');
        throw Exception('Failed to update user subscription tier. Check RLS policies.');
      }
      
      print('✅ User table updated: ${updateResult.first}');

      // Verify the update
      final verifyUser = await _client
          .from('users')
          .select('subscription_tier')
          .eq('id', userId)
          .single();
      
      if (verifyUser['subscription_tier'] != 'premium') {
        throw Exception('Verification failed: subscription_tier is ${verifyUser['subscription_tier']}, expected premium');
      }

      // Record in subscription history
      await _client.from('subscription_history').insert({
        'user_id': userId,
        'tier': 'premium',
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'started_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': 'active',
        'notes': notes,
        'verified_by': _client.auth.currentUser?.id,
        'verified_at': now.toIso8601String(),
      });

      // Send notification to farmer
      await _notificationService.sendNotification(
        userId: userId,
        title: '🎉 Premium Activated!',
        message: 'Your premium subscription is now active for $durationDays days. Enjoy unlimited product listings and priority placement!',
        type: 'subscription',
      );

      print('✅ Premium subscription activated for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error activating premium subscription: $e');
      rethrow;
    }
  }

  /// Downgrade user to free tier
  Future<bool> downgradeToFree({
    required String userId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();

      // Update user subscription
      await _client.from('users').update({
        'subscription_tier': 'free',
        'subscription_expires_at': null,
      }).eq('id', userId);

      // Update subscription history
      await _client
          .from('subscription_history')
          .update({
            'status': 'cancelled',
            'notes': reason,
          })
          .eq('user_id', userId)
          .eq('status', 'active');

      // Send notification to farmer
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Subscription Updated',
        message: 'Your account has been downgraded to Free tier. You can upgrade anytime.',
        type: 'subscription',
      );

      print('✅ User downgraded to free tier: $userId');
      return true;
    } catch (e) {
      print('Error downgrading to free tier: $e');
      rethrow;
    }
  }

  /// Extend premium subscription
  Future<bool> extendSubscription({
    required String userId,
    required int additionalDays,
  }) async {
    try {
      // Get current subscription
      final userData = await _client
          .from('users')
          .select('subscription_expires_at')
          .eq('id', userId)
          .single();

      final currentExpiry = userData['subscription_expires_at'] != null
          ? DateTime.parse(userData['subscription_expires_at'] as String)
          : DateTime.now();

      // Calculate new expiry (extend from current or now, whichever is later)
      final baseDate = currentExpiry.isAfter(DateTime.now())
          ? currentExpiry
          : DateTime.now();
      final newExpiry = baseDate.add(Duration(days: additionalDays));

      // Update subscription
      await _client.from('users').update({
        'subscription_expires_at': newExpiry.toIso8601String(),
      }).eq('id', userId);

      // Send notification
      await _notificationService.sendNotification(
        userId: userId,
        title: '✨ Subscription Extended',
        message: 'Your premium subscription has been extended by $additionalDays days!',
        type: 'subscription',
      );

      print('✅ Subscription extended for user: $userId');
      return true;
    } catch (e) {
      print('Error extending subscription: $e');
      rethrow;
    }
  }

  /// Submit subscription request (for farmers to request premium)
  Future<bool> submitSubscriptionRequest({
    required String userId,
    required String paymentMethod,
    required String paymentReference,
    String? paymentProofUrl,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      // Create pending subscription record
      await _client.from('subscription_history').insert({
        'user_id': userId,
        'tier': 'premium',
        'amount': 149.00,
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'payment_proof_url': paymentProofUrl,
        'started_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': 'pending',
        'notes': notes,
      });

      // Get all admin users
      final admins = await _client
          .from('users')
          .select('id')
          .eq('role', 'admin');

      // Notify all admins
      for (var admin in admins) {
        await _notificationService.sendNotification(
          userId: admin['id'] as String,
          title: '💰 New Premium Request',
          message: 'A farmer has submitted a premium subscription request. Please review and activate.',
          type: 'admin',
          data: {
            'request_type': 'subscription',
            'user_id': userId,
          },
        );
      }

      print('✅ Subscription request submitted for user: $userId');
      return true;
    } catch (e) {
      print('Error submitting subscription request: $e');
      rethrow;
    }
  }

  /// Get subscription history for a user
  Future<List<Map<String, dynamic>>> getSubscriptionHistory(String userId) async {
    try {
      final history = await _client
          .from('subscription_history')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(history);
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  /// Get pending subscription requests (for admins)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final requests = await _client
          .from('subscription_history')
          .select('''
            *,
            user:user_id (
              id,
              full_name,
              email,
              phone,
              municipality,
              role
            )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(requests);
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get all subscription history (for admins)
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    try {
      final subscriptions = await _client
          .from('subscription_history')
          .select('''
            *,
            user:user_id (
              id,
              full_name,
              email,
              municipality,
              role
            )
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(subscriptions);
    } catch (e) {
      print('Error getting all subscriptions: $e');
      return [];
    }
  }

  /// Check for expiring subscriptions (within 3 days)
  Future<List<Map<String, dynamic>>> getExpiringSubscriptions() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      final expiring = await _client
          .from('users')
          .select('id, full_name, email, subscription_expires_at')
          .eq('subscription_tier', 'premium')
          .gte('subscription_expires_at', now.toIso8601String())
          .lte('subscription_expires_at', threeDaysFromNow.toIso8601String());

      return List<Map<String, dynamic>>.from(expiring);
    } catch (e) {
      print('Error getting expiring subscriptions: $e');
      return [];
    }
  }

  /// Get subscription statistics (for admin dashboard)
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      // Get counts
      final allUsers = await _client
          .from('users')
          .select('subscription_tier')
          .eq('role', 'farmer');

      final freeCount = allUsers.where((u) => u['subscription_tier'] == 'free').length;
      final premiumCount = allUsers.where((u) => u['subscription_tier'] == 'premium').length;

      // Get pending requests count
      final pendingRequestsData = await _client
          .from('subscription_history')
          .select('id')
          .eq('status', 'pending');

      final pendingRequests = pendingRequestsData.length;

      // Get revenue (sum of active/completed subscriptions)
      final revenue = await _client
          .from('subscription_history')
          .select('amount')
          .inFilter('status', ['active', 'completed']);

      double totalRevenue = 0;
      for (var record in revenue) {
        totalRevenue += (record['amount'] as num).toDouble();
      }

      return {
        'total_users': allUsers.length,
        'free_users': freeCount,
        'premium_users': premiumCount,
        'pending_requests': pendingRequests,
        'total_revenue': totalRevenue,
        'conversion_rate': allUsers.isNotEmpty 
            ? (premiumCount / allUsers.length * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error getting subscription stats: $e');
      return {
        'total_users': 0,
        'free_users': 0,
        'premium_users': 0,
        'pending_requests': 0,
        'total_revenue': 0.0,
        'conversion_rate': '0.0',
      };
    }
  }

  /// Approve a pending subscription request
  Future<bool> approvePendingRequest(String historyId) async {
    try {
      // Get the pending request
      final request = await _client
          .from('subscription_history')
          .select('*')
          .eq('id', historyId)
          .single();

      final userId = request['user_id'] as String;
      final expiresAt = request['expires_at'] as String;
      final startedAt = request['started_at'] as String;

      // Activate premium - with detailed logging
      print('🔄 Activating premium for user: $userId');
      print('   Started at: $startedAt');
      print('   Expires at: $expiresAt');
      
      // Update users table with .select() to verify the update
      final updateResult = await _client.from('users').update({
        'subscription_tier': 'premium',
        'subscription_started_at': startedAt,
        'subscription_expires_at': expiresAt,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId).select();
      
      if (updateResult.isEmpty) {
        print('⚠️ WARNING: User update returned empty result. Trying RLS bypass...');
        
        // Try using RPC function to bypass RLS if direct update fails
        try {
          await _client.rpc('admin_activate_premium', params: {
            'target_user_id': userId,
            'start_date': startedAt,
            'expire_date': expiresAt,
          });
          print('✅ Premium activated via RPC function (RLS bypass)');
        } catch (rpcError) {
          print('❌ RPC function failed: $rpcError');
          print('⚠️ Please run CREATE_RLS_BYPASS_FUNCTION.sql to create the helper function');
          throw Exception('Failed to update user subscription tier. RLS policy may be blocking the update. Error: $rpcError');
        }
      } else {
        print('✅ User table updated with premium status: ${updateResult.first}');
      }

      // Verify the update actually worked
      final verifyUser = await _client
          .from('users')
          .select('id, email, subscription_tier, subscription_expires_at')
          .eq('id', userId)
          .single();
      
      print('🔍 Verification - User subscription_tier: ${verifyUser['subscription_tier']}');
      
      if (verifyUser['subscription_tier'] != 'premium') {
        throw Exception('Update verification failed: subscription_tier is still ${verifyUser['subscription_tier']}');
      }

      // Update request status
      await _client.from('subscription_history').update({
        'status': 'active',
        'verified_by': _client.auth.currentUser?.id,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', historyId);
      
      print('✅ Subscription history updated to active');

      // Notify farmer
      await _notificationService.sendNotification(
        userId: userId,
        title: '🎉 Premium Approved!',
        message: 'Your premium subscription has been approved and activated. Enjoy unlimited listings!',
        type: 'subscription',
      );
      
      print('✅ Notification sent to farmer');

      return true;
    } catch (e) {
      print('❌ Error approving subscription request: $e');
      rethrow;
    }
  }

  /// Reject a pending subscription request
  Future<bool> rejectPendingRequest(String historyId, String reason) async {
    try {
      final request = await _client
          .from('subscription_history')
          .select('user_id')
          .eq('id', historyId)
          .single();

      final userId = request['user_id'] as String;

      // Update request status
      await _client.from('subscription_history').update({
        'status': 'cancelled',
        'notes': 'Rejected: $reason',
        'verified_by': _client.auth.currentUser?.id,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', historyId);

      // Notify farmer
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Subscription Request Status',
        message: 'Your premium subscription request could not be approved. Reason: $reason',
        type: 'subscription',
      );

      return true;
    } catch (e) {
      print('Error rejecting subscription request: $e');
      rethrow;
    }
  }
}
