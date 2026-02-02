import 'package:agrilink/core/models/transaction_model.dart';
import 'package:agrilink/core/services/supabase_service.dart';
import 'package:agrilink/core/services/auth_service.dart';

class TransactionService {
  final SupabaseService _supabase = SupabaseService.instance;
  final AuthService _authService = AuthService();

  /// Get all transactions for current user
  Future<List<TransactionModel>> getUserTransactions() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('transactions')
          .select('''
            *,
            order:orders!inner(
              id,
              buyer:buyer_id(full_name, email),
              farmer:farmer_id(store_name, full_name)
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Flatten the joined data
        final orderData = json['order'] as Map<String, dynamic>?;
        final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
        final farmerData = orderData?['farmer'] as Map<String, dynamic>?;
        
        return TransactionModel.fromJson({
          ...json,
          'order_number': orderData?['id']?.toString(),
          'buyer_name': buyerData?['full_name'],
          'buyer_email': buyerData?['email'],
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  /// Get transactions by type (payment, refund, cancellation)
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('transactions')
          .select('''
            *,
            order:orders!inner(
              id,
              buyer:buyer_id(full_name, email),
              farmer:farmer_id(store_name, full_name)
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('type', type.name)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final orderData = json['order'] as Map<String, dynamic>?;
        final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
        final farmerData = orderData?['farmer'] as Map<String, dynamic>?;
        
        return TransactionModel.fromJson({
          ...json,
          'order_number': orderData?['id']?.toString(),
          'buyer_name': buyerData?['full_name'],
          'buyer_email': buyerData?['email'],
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load transactions by type: $e');
    }
  }

  /// Get transaction details by ID
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final response = await _supabase.client
          .from('transactions')
          .select('''
            *,
            order:orders!inner(
              id,
              buyer:buyer_id(full_name, email),
              farmer:farmer_id(store_name, full_name)
            )
          ''')
          .eq('id', transactionId)
          .single();

      final orderData = response['order'] as Map<String, dynamic>?;
      final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
      final farmerData = orderData?['farmer'] as Map<String, dynamic>?;
      
      return TransactionModel.fromJson({
        ...response,
        'order_number': orderData?['id']?.toString(),
        'buyer_name': buyerData?['full_name'],
        'buyer_email': buyerData?['email'],
        'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
      });
    } catch (e) {
      throw Exception('Failed to load transaction: $e');
    }
  }

  /// Get transactions for a specific order
  Future<List<TransactionModel>> getOrderTransactions(String orderId) async {
    try {
      final response = await _supabase.client
          .from('transactions')
          .select('''
            *,
            order:orders!inner(
              id,
              buyer:buyer_id(full_name, email),
              farmer:farmer_id(store_name, full_name)
            )
          ''')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final orderData = json['order'] as Map<String, dynamic>?;
        final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
        final farmerData = orderData?['farmer'] as Map<String, dynamic>?;
        
        return TransactionModel.fromJson({
          ...json,
          'order_number': orderData?['id']?.toString(),
          'buyer_name': buyerData?['full_name'],
          'buyer_email': buyerData?['email'],
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load order transactions: $e');
    }
  }

  /// Create a refund request
  Future<RefundRequestModel> createRefundRequest({
    required String orderId,
    required double amount,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the transaction for this order
      final transactions = await getOrderTransactions(orderId);
      final paymentTransaction = transactions.firstWhere(
        (t) => t.type == TransactionType.payment,
        orElse: () => throw Exception('No payment transaction found for this order'),
      );

      // Create refund request
      final response = await _supabase.client
          .from('refund_requests')
          .insert({
            'order_id': orderId,
            'user_id': currentUser.id,
            'transaction_id': paymentTransaction.id,
            'amount': amount,
            'reason': reason,
            'additional_details': additionalDetails,
            'status': 'pending',
          })
          .select()
          .single();

      // Update order refund status
      await _supabase.client
          .from('orders')
          .update({
            'refund_requested': true,
            'refund_status': 'pending',
          })
          .eq('id', orderId);

      return RefundRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create refund request: $e');
    }
  }

  /// Get refund requests for current user
  Future<List<RefundRequestModel>> getUserRefundRequests() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('refund_requests')
          .select('''
            *,
            order:orders!inner(
              id,
              payment_method,
              payment_screenshot_url,
              buyer:buyer_id(full_name, email)
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final orderData = json['order'] as Map<String, dynamic>?;
        final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
        
        return RefundRequestModel.fromJson({
          ...json,
          'order_number': orderData?['id']?.toString(),
          'payment_method': orderData?['payment_method'],
          'payment_screenshot_url': orderData?['payment_screenshot_url'],
          'buyer_name': buyerData?['full_name'],
          'buyer_email': buyerData?['email'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load refund requests: $e');
    }
  }

  /// Get refund request by order ID
  Future<RefundRequestModel?> getRefundRequestByOrderId(String orderId) async {
    try {
      final response = await _supabase.client
          .from('refund_requests')
          .select('''
            *,
            order:orders!inner(
              id,
              payment_method,
              payment_screenshot_url,
              buyer:buyer_id(full_name, email)
            )
          ''')
          .eq('order_id', orderId)
          .eq('status', 'pending')
          .maybeSingle();

      if (response == null) return null;

      final orderData = response['order'] as Map<String, dynamic>?;
      final buyerData = orderData?['buyer'] as Map<String, dynamic>?;
      
      return RefundRequestModel.fromJson({
        ...response,
        'order_number': orderData?['id']?.toString(),
        'payment_method': orderData?['payment_method'],
        'payment_screenshot_url': orderData?['payment_screenshot_url'],
        'buyer_name': buyerData?['full_name'],
        'buyer_email': buyerData?['email'],
      });
    } catch (e) {
      throw Exception('Failed to load refund request: $e');
    }
  }

  /// Check if order has pending refund request
  Future<bool> hasRefundRequest(String orderId) async {
    try {
      final refundRequest = await getRefundRequestByOrderId(orderId);
      return refundRequest != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all refund requests (admin only)
  Future<List<RefundRequestModel>> getAllRefundRequests({String? status}) async {
    try {
      var query = _supabase.client
          .from('admin_refund_dashboard')
          .select('*');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) => RefundRequestModel.fromJson({
        'id': json['id'],
        'order_id': json['order_id'],
        'user_id': json['user_id'],
        'amount': json['amount'],
        'reason': json['reason'],
        'additional_details': json['additional_details'],
        'status': json['status'],
        'created_at': json['created_at'],
        'processed_at': json['processed_at'],
        'order_number': json['order_number'],
        'payment_method': json['payment_method'],
        'payment_screenshot_url': json['payment_screenshot_url'],
        'buyer_name': json['buyer_name'],
        'buyer_email': json['buyer_email'],
      })).toList();
    } catch (e) {
      throw Exception('Failed to load refund requests: $e');
    }
  }

  /// Process refund request (admin only)
  Future<void> processRefundRequest({
    required String refundRequestId,
    required bool approve,
    String? adminNotes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final action = approve ? 'approve' : 'reject';
      
      await _supabase.client.rpc('process_refund_request', params: {
        'p_refund_request_id': refundRequestId,
        'p_admin_id': currentUser.id,
        'p_action': action,
        'p_admin_notes': adminNotes,
      });
    } catch (e) {
      throw Exception('Failed to process refund request: $e');
    }
  }

  /// Get transaction statistics for user
  Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final transactions = await getUserTransactions();
      
      final payments = transactions.where((t) => t.type == TransactionType.payment).toList();
      final refunds = transactions.where((t) => t.type == TransactionType.refund).toList();
      
      final totalPaid = payments
          .where((t) => t.status == TransactionStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final totalRefunded = refunds
          .where((t) => t.status == TransactionStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final pendingPayments = payments
          .where((t) => t.status == TransactionStatus.pending)
          .length;

      return {
        'total_transactions': transactions.length,
        'total_paid': totalPaid,
        'total_refunded': totalRefunded,
        'pending_payments': pendingPayments,
        'completed_payments': payments.where((t) => t.status == TransactionStatus.completed).length,
        'completed_refunds': refunds.where((t) => t.status == TransactionStatus.completed).length,
      };
    } catch (e) {
      throw Exception('Failed to get transaction stats: $e');
    }
  }
}
