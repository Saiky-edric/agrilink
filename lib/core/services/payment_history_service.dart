import 'package:agrilink/core/models/payment_history_model.dart';
import 'package:agrilink/core/services/supabase_service.dart';
import 'package:agrilink/core/services/auth_service.dart';

class PaymentHistoryService {
  final SupabaseService _supabase = SupabaseService.instance;
  final AuthService _authService = AuthService();

  /// Get all payment history for current user
  Future<List<PaymentHistoryItem>> getUserPaymentHistory() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('orders')
          .select('''
            id,
            created_at,
            payment_method,
            total_amount,
            payment_verified,
            payment_verified_at,
            payment_verified_by,
            payment_reference,
            payment_screenshot_url,
            payment_notes,
            farmer_status,
            refunded_amount,
            farmer:farmer_id(store_name, full_name)
          ''')
          .eq('buyer_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        // Get item count
        final farmerData = json['farmer'] as Map<String, dynamic>?;
        
        return PaymentHistoryItem.fromJson({
          ...json,
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
          'item_count': 0, // Will be populated if needed
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payment history: $e');
    }
  }

  /// Get payment history filtered by payment method
  Future<List<PaymentHistoryItem>> getPaymentHistoryByMethod(String method) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('orders')
          .select('''
            id,
            created_at,
            payment_method,
            total_amount,
            payment_verified,
            payment_verified_at,
            payment_verified_by,
            payment_reference,
            payment_screenshot_url,
            payment_notes,
            farmer_status,
            refunded_amount,
            farmer:farmer_id(store_name, full_name)
          ''')
          .eq('buyer_id', currentUser.id)
          .eq('payment_method', method)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final farmerData = json['farmer'] as Map<String, dynamic>?;
        
        return PaymentHistoryItem.fromJson({
          ...json,
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
          'item_count': 0,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payment history by method: $e');
    }
  }

  /// Get payment history filtered by status
  Future<List<PaymentHistoryItem>> getPaymentHistoryByStatus(PaymentStatus status) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase.client
          .from('orders')
          .select('''
            id,
            created_at,
            payment_method,
            total_amount,
            payment_verified,
            payment_verified_at,
            payment_verified_by,
            payment_reference,
            payment_screenshot_url,
            payment_notes,
            farmer_status,
            refunded_amount,
            farmer:farmer_id(store_name, full_name)
          ''')
          .eq('buyer_id', currentUser.id);

      // Apply status-specific filters
      switch (status) {
        case PaymentStatus.pending:
          query = query
              .eq('payment_method', 'gcash')
              .isFilter('payment_verified', null)
              .neq('farmer_status', 'cancelled');
          break;
        case PaymentStatus.verified:
          query = query
              .eq('payment_method', 'gcash')
              .eq('payment_verified', true);
          break;
        case PaymentStatus.rejected:
          query = query
              .eq('payment_method', 'gcash')
              .eq('payment_verified', false);
          break;
        case PaymentStatus.delivered:
          query = query
              .inFilter('payment_method', ['cod', 'cop'])
              .eq('farmer_status', 'completed');
          break;
        case PaymentStatus.refunded:
          query = query.not('refunded_amount', 'is', 'null');
          break;
        case PaymentStatus.cancelled:
          query = query.eq('farmer_status', 'cancelled');
          break;
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) {
        final farmerData = json['farmer'] as Map<String, dynamic>?;
        
        return PaymentHistoryItem.fromJson({
          ...json,
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
          'item_count': 0,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payment history by status: $e');
    }
  }

  /// Get payment history for a specific date range
  Future<List<PaymentHistoryItem>> getPaymentHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.client
          .from('orders')
          .select('''
            id,
            created_at,
            payment_method,
            total_amount,
            payment_verified,
            payment_verified_at,
            payment_verified_by,
            payment_reference,
            payment_screenshot_url,
            payment_notes,
            farmer_status,
            refunded_amount,
            farmer:farmer_id(store_name, full_name)
          ''')
          .eq('buyer_id', currentUser.id)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final farmerData = json['farmer'] as Map<String, dynamic>?;
        
        return PaymentHistoryItem.fromJson({
          ...json,
          'farmer_name': farmerData?['store_name'] ?? farmerData?['full_name'],
          'item_count': 0,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load payment history by date range: $e');
    }
  }

  /// Get payment summary statistics
  Future<PaymentSummary> getPaymentSummary() async {
    try {
      final payments = await getUserPaymentHistory();
      return PaymentSummary.fromPayments(payments);
    } catch (e) {
      throw Exception('Failed to get payment summary: $e');
    }
  }

  /// Get monthly payment history (for trending)
  Future<Map<String, double>> getMonthlySpending({int months = 6}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final startDate = DateTime.now().subtract(Duration(days: months * 30));
      
      final response = await _supabase.client
          .from('orders')
          .select('created_at, total_amount, farmer_status')
          .eq('buyer_id', currentUser.id)
          .gte('created_at', startDate.toIso8601String())
          .neq('farmer_status', 'cancelled')
          .order('created_at', ascending: true);

      final Map<String, double> monthlyData = {};

      for (var order in response as List) {
        final date = DateTime.parse(order['created_at']);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final amount = (order['total_amount'] as num).toDouble();
        
        monthlyData[key] = (monthlyData[key] ?? 0) + amount;
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get monthly spending: $e');
    }
  }

  /// Get payment method statistics
  Future<Map<String, int>> getPaymentMethodStats() async {
    try {
      final payments = await getUserPaymentHistory();
      final Map<String, int> stats = {};

      for (var payment in payments) {
        final method = payment.paymentMethodDisplayName;
        stats[method] = (stats[method] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get payment method stats: $e');
    }
  }

  /// Search payment history
  Future<List<PaymentHistoryItem>> searchPaymentHistory(String query) async {
    try {
      final allPayments = await getUserPaymentHistory();
      
      return allPayments.where((payment) {
        final searchLower = query.toLowerCase();
        return payment.orderId.toLowerCase().contains(searchLower) ||
               payment.reference?.toLowerCase().contains(searchLower) == true ||
               payment.farmerName?.toLowerCase().contains(searchLower) == true ||
               payment.paymentMethodDisplayName.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search payment history: $e');
    }
  }
}
