import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/payout_service.dart';
import '../../../core/models/payout_request_model.dart';
import '../../../core/theme/app_theme.dart';
import 'payout_request_details_screen.dart';

class AdminPayoutDashboardScreen extends StatefulWidget {
  const AdminPayoutDashboardScreen({super.key});

  @override
  State<AdminPayoutDashboardScreen> createState() => _AdminPayoutDashboardScreenState();
}

class _AdminPayoutDashboardScreenState extends State<AdminPayoutDashboardScreen>
    with SingleTickerProviderStateMixin {
  final PayoutService _payoutService = PayoutService();
  late TabController _tabController;

  List<PayoutRequest> _allRequests = [];
  List<PayoutRequest> _pendingRequests = [];
  List<PayoutRequest> _processingRequests = [];
  List<PayoutRequest> _completedRequests = [];
  
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPayoutData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final allRequests = await _payoutService.getAllPayoutRequests();
      final stats = await _payoutService.getPayoutStatistics();

      setState(() {
        _allRequests = allRequests;
        _pendingRequests = allRequests
            .where((r) => r.status == PayoutStatus.pending)
            .toList();
        _processingRequests = allRequests
            .where((r) => r.status == PayoutStatus.processing)
            .toList();
        _completedRequests = allRequests
            .where((r) => r.status == PayoutStatus.completed || r.status == PayoutStatus.rejected)
            .toList();
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openRequestDetails(PayoutRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayoutRequestDetailsScreen(request: request),
      ),
    );

    if (result == true) {
      _loadPayoutData(); // Refresh if changes were made
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Payout Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayoutData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryGreen,
              tabs: [
                Tab(
                  text: 'All (${_allRequests.length})',
                  icon: const Icon(Icons.list, size: 18),
                ),
                Tab(
                  text: 'Pending (${_pendingRequests.length})',
                  icon: const Icon(Icons.pending_actions, size: 18),
                ),
                Tab(
                  text: 'Processing (${_processingRequests.length})',
                  icon: const Icon(Icons.sync, size: 18),
                ),
                Tab(
                  text: 'History (${_completedRequests.length})',
                  icon: const Icon(Icons.history, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildStatistics(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestList(_allRequests, 'No payout requests yet'),
                          _buildRequestList(_pendingRequests, 'No pending requests'),
                          _buildRequestList(_processingRequests, 'No processing requests'),
                          _buildRequestList(_completedRequests, 'No completed requests'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading payouts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPayoutData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '₱${(_statistics['total_pending'] as num? ?? 0).toStringAsFixed(2)}',
                  '${_statistics['pending_count'] ?? 0} requests',
                  Colors.orange,
                  Icons.pending,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Paid',
                  '₱${(_statistics['total_paid_out'] as num? ?? 0).toStringAsFixed(2)}',
                  '${_statistics['completed_count'] ?? 0} completed',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<PayoutRequest> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayoutData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildPayoutRequestCard(request);
        },
      ),
    );
  }

  Widget _buildPayoutRequestCard(PayoutRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRequestDetails(request),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.farmerStoreName ?? request.farmerName ?? 'Unknown Farmer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested ${_formatDate(request.requestedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Amount',
                        '₱${request.amount.toStringAsFixed(2)}',
                        Icons.payments,
                        AppTheme.primaryGreen,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Method',
                        request.paymentMethodDisplayName,
                        request.paymentMethod == PaymentMethod.gcash
                            ? Icons.phone_android
                            : Icons.account_balance,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      request.paymentMethod == PaymentMethod.gcash
                          ? Icons.phone
                          : Icons.credit_card,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.accountNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request.requestNotes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request.requestNotes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (request.status == PayoutStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openRequestDetails(request),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: BorderSide(color: AppTheme.primaryGreen),
                          ),
                          child: const Text('Review'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PayoutStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case PayoutStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case PayoutStatus.processing:
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case PayoutStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case PayoutStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
