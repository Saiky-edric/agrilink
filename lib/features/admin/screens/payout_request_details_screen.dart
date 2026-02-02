import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/services/payout_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/payout_request_model.dart';
import '../../../core/theme/app_theme.dart';

class PayoutRequestDetailsScreen extends StatefulWidget {
  final PayoutRequest request;

  const PayoutRequestDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  State<PayoutRequestDetailsScreen> createState() =>
      _PayoutRequestDetailsScreenState();
}

class _PayoutRequestDetailsScreenState
    extends State<PayoutRequestDetailsScreen> {
  final PayoutService _payoutService = PayoutService();

  List<PayoutLog> _logs = [];
  List<Map<String, dynamic>> _orderBreakdown = [];
  bool _isLoadingDetails = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      setState(() => _isLoadingDetails = true);

      final logs = await _payoutService.getPayoutLogs(widget.request.id);
      final orders =
          await _payoutService.getOrdersForPayout(widget.request.farmerId);

      setState(() {
        _logs = logs;
        _orderBreakdown = orders;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _approveRequest() async {
    final confirmed = await _showConfirmDialog(
      'Approve Payout Request',
      'Mark this request as "Processing"? This indicates you are sending the payment.',
      Colors.blue,
    );

    if (!confirmed) return;

    final notes = await _showNotesDialog('Add notes (optional)');
    if (notes == null) return; // User cancelled

    setState(() => _isProcessing = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _payoutService.approvePayoutRequest(
        widget.request.id,
        currentUser.id,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout request approved!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _markAsCompleted() async {
    final confirmed = await _showConfirmDialog(
      'Mark as Completed',
      'Confirm that you have sent ₱${widget.request.amount.toStringAsFixed(2)} to the farmer?',
      Colors.green,
    );

    if (!confirmed) return;

    final notes = await _showNotesDialog(
      'Add payment reference/notes',
      hint: 'e.g., GCash Ref: GC123456789',
    );
    if (notes == null) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _payoutService.markPayoutAsCompleted(
        widget.request.id,
        currentUser.id,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout marked as completed!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest() async {
    final reason = await _showNotesDialog(
      'Rejection Reason',
      hint: 'Enter reason for rejection',
      required: true,
    );
    if (reason == null || reason.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Reject Payout Request',
      'Are you sure you want to reject this request?',
      Colors.red,
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _payoutService.rejectPayoutRequest(
        widget.request.id,
        currentUser.id,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout request rejected'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showConfirmDialog(
      String title, String message, Color color) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _showNotesDialog(String title,
      {String? hint, bool required = false}) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint ?? 'Enter notes here...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This field is required')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Payout Request Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Request Summary Card
                _buildSummaryCard(),

                const SizedBox(height: 16),

                // Payment Details Card
                _buildPaymentDetailsCard(),

                const SizedBox(height: 16),

                // Order Breakdown
                if (_orderBreakdown.isNotEmpty) ...[
                  _buildOrderBreakdownCard(),
                  const SizedBox(height: 16),
                ],

                // Activity Log
                if (_logs.isNotEmpty) ...[
                  _buildActivityLogCard(),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (!widget.request.isCompleted && !widget.request.isRejected)
                  _buildActionButtons(),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                      widget.request.farmerStoreName ??
                          widget.request.farmerName ??
                          'Unknown Farmer',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested ${DateFormat('MMM dd, yyyy - hh:mm a').format(widget.request.requestedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.request.status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments,
                    color: AppTheme.primaryGreen, size: 32),
                const SizedBox(width: 12),
                Text(
                  '₱${widget.request.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          if (widget.request.requestNotes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farmer Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.request.requestNotes!,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.request.paymentMethod == PaymentMethod.gcash
                      ? Icons.phone_android
                      : Icons.account_balance,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Method',
            widget.request.paymentMethodDisplayName,
            canCopy: false,
          ),
          if (widget.request.paymentMethod == PaymentMethod.gcash) ...[
            _buildDetailRow(
              'GCash Number',
              widget.request.accountNumber,
              canCopy: true,
            ),
            _buildDetailRow(
              'Account Name',
              widget.request.accountName,
              canCopy: true,
            ),
          ] else ...[
            _buildDetailRow(
              'Bank',
              widget.request.bankName ?? 'N/A',
              canCopy: false,
            ),
            _buildDetailRow(
              'Account Number',
              widget.request.accountNumber,
              canCopy: true,
            ),
            _buildDetailRow(
              'Account Name',
              widget.request.accountName,
              canCopy: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (canCopy)
                  IconButton(
                    icon:
                        Icon(Icons.copy, size: 18, color: Colors.grey.shade600),
                    onPressed: () => _copyToClipboard(value, label),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_orderBreakdown.length} completed order(s)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ..._orderBreakdown.take(5).map((order) {
            final amount = (order['total_amount'] as num).toDouble();
            final commission = amount * 0.10;
            final farmerEarning = amount - commission;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(order['created_at']),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₱${farmerEarning.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (_orderBreakdown.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${_orderBreakdown.length - 5} more order(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._logs.map((log) => _buildLogItem(log)).toList(),
        ],
      ),
    );
  }

  Widget _buildLogItem(PayoutLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getLogIcon(log.action),
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.actionDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (log.performedByName != null)
                  Text(
                    'by ${log.performedByName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(log.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (log.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLogIcon(PayoutAction action) {
    switch (action) {
      case PayoutAction.requested:
        return Icons.add_circle_outline;
      case PayoutAction.approved:
        return Icons.check_circle_outline;
      case PayoutAction.rejected:
        return Icons.cancel_outlined;
      case PayoutAction.completed:
        return Icons.check_circle;
      case PayoutAction.cancelled:
        return Icons.remove_circle_outline;
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.request.isPending) ...[
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _approveRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Approve & Start Processing'),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.request.isProcessing) ...[
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _markAsCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.payments),
              label: const Text('Mark as Completed'),
            ),
            const SizedBox(height: 12),
          ],
          if (!widget.request.isCompleted && !widget.request.isRejected)
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _rejectRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.cancel),
              label: const Text('Reject Request'),
            ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
