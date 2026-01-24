import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payout_request_model.dart';
import 'supabase_service.dart';

class PayoutService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // ========================================
  // FARMER METHODS
  // ========================================

  /// Get farmer's wallet summary (balance, earnings, etc.)
  Future<FarmerWalletSummary> getWalletSummary(String farmerId) async {
    try {
      debugPrint('💰 Fetching wallet summary for farmer: $farmerId');

      // Get user info
      final userResponse = await _client
          .from('users')
          .select('id, full_name, store_name')
          .eq('id', farmerId)
          .single();

      // Calculate balances using database functions
      final availableBalance = await _calculateAvailableBalance(farmerId);
      final pendingEarnings = await _calculatePendingEarnings(farmerId);

      // Get total paid out
      final payoutResponse = await _client
          .from('payout_requests')
          .select('amount')
          .eq('farmer_id', farmerId)
          .eq('status', 'completed');

      double totalPaidOut = 0.0;
      for (var payout in payoutResponse) {
        totalPaidOut += (payout['amount'] as num).toDouble();
      }

      // Get pending requests count
      final pendingResponse = await _client
          .from('payout_requests')
          .select('id')
          .eq('farmer_id', farmerId)
          .eq('status', 'pending');

      final summary = FarmerWalletSummary(
        farmerId: farmerId,
        farmerName: userResponse['full_name'] as String,
        storeName: userResponse['store_name'] as String?,
        availableBalance: availableBalance,
        pendingEarnings: pendingEarnings,
        totalPaidOut: totalPaidOut,
        pendingRequestsCount: pendingResponse.length,
      );

      debugPrint('💰 Wallet summary: Available=₱${availableBalance.toStringAsFixed(2)}, Pending=₱${pendingEarnings.toStringAsFixed(2)}');
      return summary;
    } catch (e) {
      debugPrint('❌ Error fetching wallet summary: $e');
      rethrow;
    }
  }

  /// Calculate available balance (completed orders not yet paid out)
  Future<double> _calculateAvailableBalance(String farmerId) async {
    try {
      final result = await _client.rpc('calculate_farmer_available_balance', 
        params: {'farmer_uuid': farmerId}
      );
      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('⚠️ Error calculating available balance: $e');
      // Fallback: calculate manually
      return await _calculateAvailableBalanceManual(farmerId);
    }
  }

  /// Fallback method to calculate available balance
  Future<double> _calculateAvailableBalanceManual(String farmerId) async {
    final orders = await _client
        .from('orders')
        .select('total_amount, payment_method')
        .eq('farmer_id', farmerId)
        .eq('farmer_status', 'completed')
        .not('payment_method', 'in', '(cod,cop)') // Exclude cash payments
        .or('farmer_payout_status.is.null,farmer_payout_status.eq.pending,farmer_payout_status.eq.available');

    double total = 0.0;
    const commission = 0.10; // 10% platform commission

    for (var order in orders) {
      final amount = (order['total_amount'] as num).toDouble();
      total += amount * (1 - commission);
    }

    return total;
  }

  /// Calculate pending earnings (orders in progress)
  Future<double> _calculatePendingEarnings(String farmerId) async {
    try {
      final result = await _client.rpc('calculate_farmer_pending_earnings',
        params: {'farmer_uuid': farmerId}
      );
      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('⚠️ Error calculating pending earnings: $e');
      return await _calculatePendingEarningsManual(farmerId);
    }
  }

  /// Fallback method to calculate pending earnings
  Future<double> _calculatePendingEarningsManual(String farmerId) async {
    final orders = await _client
        .from('orders')
        .select('total_amount, payment_method')
        .eq('farmer_id', farmerId)
        .not('payment_method', 'in', '(cod,cop)') // Exclude cash payments
        .inFilter('farmer_status', ['newOrder', 'accepted', 'toPack', 'toDeliver', 'readyForPickup']);

    double total = 0.0;
    const commission = 0.10;

    for (var order in orders) {
      final amount = (order['total_amount'] as num).toDouble();
      total += amount * (1 - commission);
    }

    return total;
  }

  /// Get farmer's payout requests
  Future<List<PayoutRequest>> getMyPayoutRequests(String farmerId) async {
    try {
      debugPrint('📋 Fetching payout requests for farmer: $farmerId');

      final response = await _client
          .from('payout_requests')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      final requests = (response as List)
          .map((json) => PayoutRequest.fromJson(json))
          .toList();

      debugPrint('📋 Found ${requests.length} payout requests');
      return requests;
    } catch (e) {
      debugPrint('❌ Error fetching payout requests: $e');
      rethrow;
    }
  }

  /// Request a payout
  Future<PayoutRequest> requestPayout({
    required String farmerId,
    required double amount,
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> paymentDetails,
    String? notes,
  }) async {
    try {
      debugPrint('💸 Creating payout request: ₱${amount.toStringAsFixed(2)}');

      // Validate minimum amount
      if (amount < 100.0) {
        throw Exception('Minimum payout amount is ₱100.00');
      }

      // Check available balance
      final availableBalance = await _calculateAvailableBalance(farmerId);
      if (amount > availableBalance) {
        throw Exception('Insufficient balance. Available: ₱${availableBalance.toStringAsFixed(2)}');
      }

      // Create payout request
      final response = await _client
          .from('payout_requests')
          .insert({
            'farmer_id': farmerId,
            'amount': amount,
            'status': 'pending',
            'payment_method': paymentMethod.value,
            'payment_details': paymentDetails,
            'request_notes': notes,
            'requested_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('✅ Payout request created: ${response['id']}');
      return PayoutRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating payout request: $e');
      rethrow;
    }
  }

  /// Cancel a pending payout request
  Future<void> cancelPayoutRequest(String requestId) async {
    try {
      debugPrint('🚫 Cancelling payout request: $requestId');

      await _client
          .from('payout_requests')
          .delete()
          .eq('id', requestId)
          .eq('status', 'pending');

      debugPrint('✅ Payout request cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling payout request: $e');
      rethrow;
    }
  }

  /// Get payment details for farmer
  Future<Map<String, dynamic>> getPaymentDetails(String farmerId) async {
    try {
      final response = await _client
          .from('users')
          .select('gcash_number, gcash_name, bank_name, bank_account_number, bank_account_name')
          .eq('id', farmerId)
          .single();

      return {
        'gcash_number': response['gcash_number'],
        'gcash_name': response['gcash_name'],
        'bank_name': response['bank_name'],
        'bank_account_number': response['bank_account_number'],
        'bank_account_name': response['bank_account_name'],
      };
    } catch (e) {
      debugPrint('❌ Error fetching payment details: $e');
      rethrow;
    }
  }

  /// Update payment details for farmer
  Future<void> updatePaymentDetails(String farmerId, Map<String, dynamic> details) async {
    try {
      debugPrint('💳 Updating payment details for farmer: $farmerId');

      await _client
          .from('users')
          .update(details)
          .eq('id', farmerId);

      debugPrint('✅ Payment details updated');
    } catch (e) {
      debugPrint('❌ Error updating payment details: $e');
      rethrow;
    }
  }

  // ========================================
  // ADMIN METHODS
  // ========================================

  /// Get all payout requests (admin view)
  Future<List<PayoutRequest>> getAllPayoutRequests({String? status}) async {
    try {
      debugPrint('🔍 Fetching all payout requests${status != null ? ' with status: $status' : ''}');

      var query = _client
          .from('payout_requests')
          .select('''
            *,
            users!payout_requests_farmer_id_fkey(full_name, store_name),
            admins:users!payout_requests_processed_by_fkey(full_name)
          ''')
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;

      final requests = (response as List).map((json) {
        // Add farmer and admin names
        final farmerData = json['users'] as Map<String, dynamic>?;
        final adminData = json['admins'] as Map<String, dynamic>?;

        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['farmer_name'] = farmerData?['full_name'];
        modifiedJson['farmer_store_name'] = farmerData?['store_name'];
        modifiedJson['processed_by_name'] = adminData?['full_name'];

        return PayoutRequest.fromJson(modifiedJson);
      }).toList();

      debugPrint('🔍 Found ${requests.length} payout requests');
      return requests;
    } catch (e) {
      debugPrint('❌ Error fetching payout requests: $e');
      rethrow;
    }
  }

  /// Get payout statistics for admin dashboard
  Future<Map<String, dynamic>> getPayoutStatistics() async {
    try {
      // Count by status
      final pendingCount = await _client
          .from('payout_requests')
          .select('id', const FetchOptions(count: CountOption.exact, head: true))
          .eq('status', 'pending');

      final processingCount = await _client
          .from('payout_requests')
          .select('id', const FetchOptions(count: CountOption.exact, head: true))
          .eq('status', 'processing');

      final completedCount = await _client
          .from('payout_requests')
          .select('id', const FetchOptions(count: CountOption.exact, head: true))
          .eq('status', 'completed');

      // Get total amounts
      final completedPayouts = await _client
          .from('payout_requests')
          .select('amount')
          .eq('status', 'completed');

      double totalPaidOut = 0.0;
      for (var payout in completedPayouts) {
        totalPaidOut += (payout['amount'] as num).toDouble();
      }

      final pendingPayouts = await _client
          .from('payout_requests')
          .select('amount')
          .eq('status', 'pending');

      double totalPending = 0.0;
      for (var payout in pendingPayouts) {
        totalPending += (payout['amount'] as num).toDouble();
      }

      return {
        'pending_count': pendingCount.count ?? 0,
        'processing_count': processingCount.count ?? 0,
        'completed_count': completedCount.count ?? 0,
        'total_paid_out': totalPaidOut,
        'total_pending': totalPending,
      };
    } catch (e) {
      debugPrint('❌ Error fetching payout statistics: $e');
      return {
        'pending_count': 0,
        'processing_count': 0,
        'completed_count': 0,
        'total_paid_out': 0.0,
        'total_pending': 0.0,
      };
    }
  }

  /// Approve payout request (change to processing)
  Future<void> approvePayoutRequest(String requestId, String adminId, {String? notes}) async {
    try {
      debugPrint('✅ Approving payout request: $requestId');

      await _client
          .from('payout_requests')
          .update({
            'status': 'processing',
            'processed_by': adminId,
            'admin_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      debugPrint('✅ Payout request approved');
    } catch (e) {
      debugPrint('❌ Error approving payout request: $e');
      rethrow;
    }
  }

  /// Mark payout as completed
  Future<void> markPayoutAsCompleted(String requestId, String adminId, {String? notes}) async {
    try {
      debugPrint('🎉 Marking payout as completed: $requestId');

      await _client
          .from('payout_requests')
          .update({
            'status': 'completed',
            'processed_by': adminId,
            'admin_notes': notes,
            'processed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      debugPrint('🎉 Payout marked as completed - orders will be marked as paid out via trigger');
    } catch (e) {
      debugPrint('❌ Error marking payout as completed: $e');
      rethrow;
    }
  }

  /// Reject payout request
  Future<void> rejectPayoutRequest(String requestId, String adminId, String reason) async {
    try {
      debugPrint('❌ Rejecting payout request: $requestId');

      await _client
          .from('payout_requests')
          .update({
            'status': 'rejected',
            'processed_by': adminId,
            'rejection_reason': reason,
            'processed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      debugPrint('❌ Payout request rejected');
    } catch (e) {
      debugPrint('❌ Error rejecting payout request: $e');
      rethrow;
    }
  }

  /// Get payout logs for a request
  Future<List<PayoutLog>> getPayoutLogs(String requestId) async {
    try {
      final response = await _client
          .from('payout_logs')
          .select('''
            *,
            users(full_name)
          ''')
          .eq('payout_request_id', requestId)
          .order('created_at', ascending: true);

      final logs = (response as List).map((json) {
        final userData = json['users'] as Map<String, dynamic>?;
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['performed_by_name'] = userData?['full_name'];

        return PayoutLog.fromJson(modifiedJson);
      }).toList();

      return logs;
    } catch (e) {
      debugPrint('❌ Error fetching payout logs: $e');
      return [];
    }
  }

  /// Get detailed breakdown of orders for a farmer
  Future<List<Map<String, dynamic>>> getOrdersForPayout(String farmerId) async {
    try {
      final orders = await _client
          .from('orders')
          .select('id, order_number, total_amount, payment_method, created_at, farmer_status, farmer_payout_status')
          .eq('farmer_id', farmerId)
          .eq('farmer_status', 'completed')
          .not('payment_method', 'in', '(cod,cop)') // Only platform-paid orders
          .or('farmer_payout_status.is.null,farmer_payout_status.eq.pending,farmer_payout_status.eq.available')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(orders);
    } catch (e) {
      debugPrint('❌ Error fetching orders for payout: $e');
      return [];
    }
  }
}
