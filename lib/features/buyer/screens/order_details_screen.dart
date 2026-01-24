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
  
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

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
      
      setState(() {
        _order = order;
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
    return _order!.farmerStatus == FarmerOrderStatus.newOrder ||
           _order!.farmerStatus == FarmerOrderStatus.accepted;
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
            child: Row(
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
}