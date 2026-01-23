import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Submit a report for a product, user, or order
  Future<void> submitReport({
    required String targetId,
    required String type, // 'product', 'user', 'order'
    required String reason,
    required String description,
    List<String>? imageUrls,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to submit a report');
      }

      // Get reporter details
      final userData = await _client
          .from('users')
          .select('full_name, email')
          .eq('id', currentUser.id)
          .single();

      // Get target details based on type
      String targetName = '';
      if (type == 'product') {
        final product = await _client
            .from('products')
            .select('name')
            .eq('id', targetId)
            .single();
        targetName = product['name'] ?? 'Unknown Product';
      } else if (type == 'user') {
        final user = await _client
            .from('users')
            .select('full_name')
            .eq('id', targetId)
            .single();
        targetName = user['full_name'] ?? 'Unknown User';
      } else if (type == 'order') {
        targetName = 'Order #${targetId.substring(0, 8)}';
      }

      await _client.from('reports').insert({
        'reporter_id': currentUser.id,
        'reporter_name': userData['full_name'] ?? 'Anonymous',
        'reporter_email': userData['email'] ?? '',
        'target_id': targetId,
        'target_type': type,
        'target_name': targetName,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'attachments': imageUrls ?? [],
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Report submitted successfully for $type: $targetId');
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  /// Get all reports submitted by the current user
  Future<List<Map<String, dynamic>>> getMyReports() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to view reports');
      }

      final reports = await _client
          .from('reports')
          .select()
          .eq('reporter_id', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(reports);
    } catch (e) {
      debugPrint('Error getting user reports: $e');
      return [];
    }
  }

  /// Get report by ID
  Future<Map<String, dynamic>?> getReportById(String reportId) async {
    try {
      final report = await _client
          .from('reports')
          .select()
          .eq('id', reportId)
          .single();

      return report;
    } catch (e) {
      debugPrint('Error getting report: $e');
      return null;
    }
  }

  /// Cancel a report (only if pending)
  Future<void> cancelReport(String reportId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in');
      }

      await _client
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('reporter_id', currentUser.id)
          .eq('status', 'pending');

      debugPrint('Report cancelled successfully');
    } catch (e) {
      debugPrint('Error cancelling report: $e');
      rethrow;
    }
  }
}
