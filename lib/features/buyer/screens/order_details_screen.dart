import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/auth_service.dart';
import '../../chat/services/chat_service.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/order_status_widgets.dart';
import '../../chat/screens/chat_conversation_screen.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/models/transaction_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TransactionService _transactionService = TransactionService();
  
  OrderModel? _order;
  RefundRequestModel? _refundRequest;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;
  bool _isRequestingRefund = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final order = await _orderService.getOrderById(widget.orderId);
      
      // Load refund request if it exists
      RefundRequestModel? refundRequest;
      if (order?.paymentMethod?.toLowerCase() == 'gcash' && order?.refundRequested == true) {
        try {
          refundRequest = await _transactionService.getRefundRequestByOrderId(widget.orderId);
        } catch (e) {
          // Refund request not found or error, continue without it
        }
      }
      
      setState(() {
        _order = order;
        _refundRequest = refundRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  Future<void> _contactFarmer() async {
    if (_order == null) return;
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to contact farmer')),
        );
        return;
      }

      // Get or create conversation
      final conversation = await _chatService.getOrCreateConversation(
        buyerId: currentUser.id,
        farmerId: _order!.farmerId,
      );

      // Prepare draft product card (do not send yet)
      final draftItem = _order!.items.isNotEmpty ? _order!.items.first : null;

      if (mounted) {
        // Navigate to chat conversation with optional draft
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation.id,
              productCardDraft: draftItem,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    }
  }

  // Common cancellation reasons
  final List<String> _cancellationReasons = [
    'Changed my mind',
    'Found a better price elsewhere',
    'Ordered by mistake',
    'Delivery time too long',
    'Need items sooner',
    'Product no longer needed',
    'Concerns about product quality',
    'Want to change order items',
    'Financial reasons',
    'Other',
  ];

  Future<void> _cancelOrder() async {
    if (_order == null || _isCancelling) return;

    // Check if cancellation is allowed
    if (_order!.farmerStatus != FarmerOrderStatus.newOrder && 
        _order!.farmerStatus != FarmerOrderStatus.accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot cancel order. Farmer has already started preparing your order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show cancellation dialog with reason selector
    String? selectedReason;
    
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to cancel this order?'),
                const SizedBox(height: 16),
                const Text(
                  'Please select a reason:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      hint: const Text('Select reason'),
                      isExpanded: true,
                      items: _cancellationReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone',
                          style: TextStyle(fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Order'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(context, selectedReason);
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null) return;

    setState(() => _isCancelling = true);

    try {
      await _orderService.cancelOrder(
        orderId: _order!.id,
        cancelReason: confirmed,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        // Refresh order details
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  bool _canCancelOrder() {
    if (_order == null) return false;
    
    // OPTION B: Block cancellation for GCash orders with payment proof
    // This protects buyers from losing money on unverified payments
    if (_order!.paymentMethod?.toLowerCase() == 'gcash') {
      // Case 1: Payment verified → Must use refund process
      if (_order!.paymentVerified == true) {
        return false; // Force "Request Refund" for verified payments
      }
      
      // Case 2: Payment proof uploaded but not verified yet → Block cancel
      // Reason: Money might already be with farmer, need admin verification first
      if (_order!.paymentScreenshotUrl != null || _order!.paymentReference != null) {
        return false; // Wait for verification, then use refund process
      }
      
      // Case 3: No payment proof uploaded yet → Allow cancel
      // Reason: No money transferred yet, safe to cancel
      return _order!.farmerStatus == FarmerOrderStatus.newOrder ||
             _order!.farmerStatus == FarmerOrderStatus.accepted;
    }
    
    // Allow cancel for COD/COP orders (no prepayment involved)
    return _order!.farmerStatus == FarmerOrderStatus.newOrder ||
           _order!.farmerStatus == FarmerOrderStatus.accepted;
  }

  bool _canRequestRefund() {
    if (_order == null) return false;
    // Can request refund if:
    // 1. Payment method is GCash
    // 2. Payment is verified
    // 3. Order is not completed or cancelled
    // 4. No existing refund request
    return _order!.paymentMethod?.toLowerCase() == 'gcash' &&
           _order!.paymentVerified == true &&
           _order!.farmerStatus != FarmerOrderStatus.completed &&
           _order!.farmerStatus != FarmerOrderStatus.cancelled &&
           !_order!.refundRequested;
  }

  Future<void> _requestRefund() async {
    if (_order == null || _isRequestingRefund) return;

    final refundReasons = [
      'Order taking too long to process',
      'Need to cancel due to changed plans',
      'Found product elsewhere',
      'Financial reasons',
      'Farmer not responding',
      'Product quality concerns',
      'Other',
    ];

    String? selectedReason;
    final detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Refund'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a refund of ₱${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select a reason:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      hint: const Text('Select reason'),
                      isExpanded: true,
                      items: refundReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Additional details (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Provide more information about your refund request',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Refunds will be processed within 3-5 business days after approval',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    setState(() => _isRequestingRefund = true);

    try {
      await _transactionService.createRefundRequest(
        orderId: _order!.id,
        amount: _order!.totalAmount,
        reason: selectedReason!, // Non-null because we check above
        additionalDetails: detailsController.text.trim().isEmpty 
            ? null 
            : detailsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund request submitted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting refund request: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingRefund = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_order != null) ...[
            // Contact Farmer Button
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: Colors.green.shade700),
              onPressed: _contactFarmer,
              tooltip: 'Contact Farmer',
            ),
            // Cancel Order Button (only if cancellation is allowed)
            if (_canCancelOrder())
              IconButton(
                icon: _isCancelling 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                        ),
                      )
                    : Icon(Icons.cancel_outlined, color: Colors.red.shade600),
                onPressed: _isCancelling ? null : _cancelOrder,
                tooltip: 'Cancel Order',
              ),
            // Report Order Button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: AppTheme.errorRed, size: 20),
                      SizedBox(width: 8),
                      Text('Report Issue'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'report') {
                  _reportOrder();
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorWidget(_error!)
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order status card with real farmer status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${_order!.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Use the modern OrderStatusChip to show real farmer status
                OrderStatusChip(
                  status: _order!.farmerStatus,
                  showIcon: true,
                ),
                const SizedBox(height: AppSpacing.md),
               // Add order progress indicator
               OrderProgressIndicator(
                 currentStatus: _order!.farmerStatus,
                 isCompact: true,
               ),
               const SizedBox(height: AppSpacing.md),
               // Dates
               Row(
                 children: [
                   const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                   const SizedBox(width: AppSpacing.xs),
                   Expanded(
                     child: Text(
                       'Ordered: ${_formatExactDateTime(_order!.createdAt)}',
                       style: AppTextStyles.bodySmall,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                 ],
               ),
               if (_order!.farmerStatus == FarmerOrderStatus.completed && _order!.completedAt != null) ...[
                 const SizedBox(height: AppSpacing.xs),
                 Row(
                   children: [
                     const Icon(Icons.done_all, size: 16, color: AppTheme.textSecondary),
                     const SizedBox(width: AppSpacing.xs),
                     Expanded(
                       child: Text(
                         'Delivered: ${_formatExactDateTime(_order!.completedAt!)}',
                         style: AppTextStyles.bodySmall,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ],
                 ),
               ] else if (_order!.deliveryDate != null) ...[
                 const SizedBox(height: AppSpacing.xs),
                 Row(
                   children: [
                     const Icon(Icons.local_shipping, size: 16, color: AppTheme.textSecondary),
                     const SizedBox(width: AppSpacing.xs),
                     Expanded(
                       child: Text(
                         'Delivery: ${_formatExactDateTime(_order!.deliveryDate!)}',
                         style: AppTextStyles.bodySmall,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ],
                 ),
               ]
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Payment Method
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPaymentIcon(_order!.paymentMethod),
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPaymentMethodLabel(_order!.paymentMethod),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Show payment status for GCash orders
                if (_order!.paymentMethod?.toLowerCase() == 'gcash') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildPaymentStatus(),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Order items
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ..._order!.items.map((item) => _buildOrderItem(item)),

          const SizedBox(height: AppSpacing.lg),

          // Order summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryRow('Subtotal', '₱${(_order!.subtotal ?? _order!.items.fold<double>(0.0, (s, i) => s + i.subtotal)).toStringAsFixed(2)}'),
                _buildSummaryRow('Delivery Fee', '₱${(_order!.deliveryFee ?? 0.0).toStringAsFixed(2)}'),
                const Divider(),
                _buildSummaryRow(
                  'Total',
                  '₱${_order!.totalAmount.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Delivery information
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _order!.deliveryAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Delivery Information Card
          DeliveryInformationCard(order: _order!),

          const SizedBox(height: AppSpacing.xl),

          // Refund request status if exists
          if (_refundRequest != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _getRefundStatusColor(_refundRequest!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRefundStatusColor(_refundRequest!.status)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getRefundStatusIcon(_refundRequest!.status),
                        color: _getRefundStatusColor(_refundRequest!.status),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Refund ${_refundRequest!.status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getRefundStatusColor(_refundRequest!.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ₱${_refundRequest!.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Reason: ${_refundRequest!.reason}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_refundRequest!.processedAt != null)
                    Text(
                      'Processed: ${DateFormat('MMM dd, yyyy').format(_refundRequest!.processedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (_refundRequest!.adminNotes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Admin Notes: ${_refundRequest!.adminNotes}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Info banner for GCash orders (explaining why cancel is blocked)
          if (_order!.paymentMethod?.toLowerCase() == 'gcash' && 
              !_canCancelOrder() &&
              (_order!.farmerStatus == FarmerOrderStatus.newOrder ||
               _order!.farmerStatus == FarmerOrderStatus.accepted)) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _order!.paymentVerified == true 
                    ? Colors.blue.shade50 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _order!.paymentVerified == true 
                      ? Colors.blue.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline, 
                    color: _order!.paymentVerified == true 
                        ? Colors.blue.shade700 
                        : Colors.orange.shade700, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _order!.paymentVerified == true
                          ? 'Since your payment is verified, please use "Request Refund" below to cancel this order. Our admin will process your request within 24 hours.'
                          : 'Your payment is being verified. Please wait for verification to complete before requesting a cancellation. This protects your money from being lost.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: _order!.paymentVerified == true 
                            ? Colors.blue.shade700 
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Action buttons based on real farmer status
          if (_canCancelOrder()) ...[
            CustomButton(
              text: _isCancelling ? 'Cancelling...' : 'Cancel Order',
              onPressed: _isCancelling ? null : _cancelOrder,
              isLoading: _isCancelling,
              width: double.infinity,
              backgroundColor: AppTheme.errorRed,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Request refund button for GCash orders
          if (_canRequestRefund()) ...[
            CustomButton(
              text: _isRequestingRefund ? 'Submitting...' : 'Request Refund',
              onPressed: _isRequestingRefund ? null : _requestRefund,
              isLoading: _isRequestingRefund,
              width: double.infinity,
              backgroundColor: Colors.orange,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          CustomButton(
            text: 'Contact Farmer',
            onPressed: _contactFarmer,
            width: double.infinity,
            isOutlined: true,
          ),

          // Show review button if order is completed and not reviewed
          if (_order!.farmerStatus == FarmerOrderStatus.completed && !_order!.buyerReviewed) ...[
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              text: '⭐ Leave a Review',
              onPressed: _goToReview,
              width: double.infinity,
              backgroundColor: AppTheme.primaryGreen,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _formatExactDateTime(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Widget _buildOrderItem(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.productImageUrl != null && item.productImageUrl!.isNotEmpty)
                  ? Image.network(
                      item.productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          color: AppTheme.textSecondary,
                        );
                      },
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.quantity} x ₱${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '₱${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppTheme.primaryGreen : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuyerOrderStatus status) {
    switch (status) {
      case BuyerOrderStatus.pending:
        return AppTheme.warningOrange;
      case BuyerOrderStatus.toShip:
        return AppTheme.primaryGreen;
      case BuyerOrderStatus.toReceive:
        return AppTheme.primaryGreen;
      case BuyerOrderStatus.completed:
        return AppTheme.successGreen;
      case BuyerOrderStatus.cancelled:
        return AppTheme.errorRed;
      default:
        return AppTheme.lightGrey;
    }
  }

  IconData _getStatusIcon(BuyerOrderStatus status) {
    switch (status) {
      case BuyerOrderStatus.pending:
        return Icons.access_time;
      case BuyerOrderStatus.toShip:
        return Icons.local_shipping;
      case BuyerOrderStatus.toReceive:
        return Icons.delivery_dining;
      case BuyerOrderStatus.completed:
        return Icons.check_circle;
      case BuyerOrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(BuyerOrderStatus status) {
    switch (status) {
      case BuyerOrderStatus.pending:
        return 'Pending Confirmation';
      case BuyerOrderStatus.toShip:
        return 'To Ship';
      case BuyerOrderStatus.toReceive:
        return 'To Receive';
      case BuyerOrderStatus.completed:
        return 'Completed';
      case BuyerOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _goToReview() async {
    final result = await context.push(
      '/submit-product-review/${_order!.id}',
    );
    
    // Reload order if review was submitted
    if (result == true && mounted) {
      _loadOrder();
    }
  }

  String _getPaymentMethodLabel(String? paymentMethod) {
    switch (paymentMethod?.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'cop':
        return 'Cash on Pickup';
      case 'gcash':
        return 'GCash';
      default:
        return 'Cash on Delivery';
    }
  }

  IconData _getPaymentIcon(String? paymentMethod) {
    switch (paymentMethod?.toLowerCase()) {
      case 'cod':
      case 'cop':
        return Icons.money;
      case 'gcash':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Future<void> _reportOrder() async {
    if (_order == null) return;
    
    final result = await showReportDialog(
      context,
      targetId: _order!.id,
      targetType: 'order',
      targetName: 'Order #${_order!.id.substring(0, 8).toUpperCase()}',
    );
    
    if (result == true && mounted) {
      // Report submitted successfully
    }
  }

  Widget _buildPaymentStatus() {
    final hasScreenshot = _order!.paymentScreenshotUrl != null;
    final isVerified = _order!.paymentVerified ?? false;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isVerified) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Payment Verified';
    } else if (hasScreenshot) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending Verification';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Payment Proof Required';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        
        if (_order!.paymentReference != null) ...[
          const SizedBox(height: 8),
          Text(
            'Ref: ${_order!.paymentReference}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
        
        if (!hasScreenshot) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please upload payment proof to process your order',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (hasScreenshot && !isVerified) ...[
          const SizedBox(height: 8),
          Text(
            'Your payment is being verified by the farmer',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        
        if (isVerified && _order!.paymentVerifiedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Verified on ${DateFormat('MMM dd, yyyy').format(_order!.paymentVerifiedAt!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Color _getRefundStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRefundStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'processing':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }
}