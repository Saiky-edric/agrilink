import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/delivery_date_picker.dart';
import '../../../shared/widgets/order_status_widgets.dart';
import '../../chat/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/route_names.dart';

class FarmerOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const FarmerOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<FarmerOrderDetailsScreen> createState() => _FarmerOrderDetailsScreenState();
}

class _FarmerOrderDetailsScreenState extends State<FarmerOrderDetailsScreen> {
  final ChatService _chatService = ChatService();
  final OrderService _orderService = OrderService();
  
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;
  DateTime? _selectedDeliveryDate;
  String _deliveryNotes = '';
  String _customTrackingNumber = '';
  final TextEditingController _deliveryNotesController = TextEditingController();
  final TextEditingController _trackingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _order = await _orderService.getOrderById(widget.orderId);

      if (_order == null) {
        _error = 'Order not found';
      }
    } catch (e) {
      _error = 'Failed to load order details: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(FarmerOrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: widget.orderId,
        farmerStatus: newStatus,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_getStatusDisplayName(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Notify parent to refresh and exit quickly for faster list update
      if (mounted) {
        context.pop(true);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusDisplayName(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return 'New Order';
      case FarmerOrderStatus.accepted:
        return 'Accepted';
      case FarmerOrderStatus.toPack:
        return 'To Pack';
      case FarmerOrderStatus.toDeliver:
        return 'To Deliver';
      case FarmerOrderStatus.readyForPickup:
        return 'Ready for Pick-up';
      case FarmerOrderStatus.completed:
        return 'Completed';
      case FarmerOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return Colors.orange;
      case FarmerOrderStatus.accepted:
        return Colors.teal;
      case FarmerOrderStatus.toPack:
        return Colors.blue;
      case FarmerOrderStatus.toDeliver:
        return Colors.purple;
      case FarmerOrderStatus.readyForPickup:
        return Colors.purple.shade700;
      case FarmerOrderStatus.completed:
        return Colors.green;
      case FarmerOrderStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _updateOrderStatusWithDeliveryInfo(FarmerOrderStatus newStatus) async {
    setState(() => _isUpdating = true);
    
    try {
      // If updating to toDeliver, optionally schedule delivery
      if (newStatus == FarmerOrderStatus.toDeliver) {
        await _showDeliverySchedulingDialog();
      }
      
      // If completing order, optionally add delivery notes
      if (newStatus == FarmerOrderStatus.completed) {
        await _showDeliveryNotesDialog();
      }
      
      // Update order status with optional tracking info
      await _orderService.updateOrderStatusWithTracking(
        orderId: widget.orderId,
        farmerStatus: newStatus,
        deliveryDate: _selectedDeliveryDate,
        deliveryNotes: _deliveryNotes.isNotEmpty ? _deliveryNotes : null,
        trackingNumber: _customTrackingNumber.isNotEmpty ? _customTrackingNumber : null,
      );

      if (mounted) {
        // Pop with result so parent list refreshes immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.pop(true);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showDeliverySchedulingDialog() async {
    final completer = Completer<void>();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Schedule Delivery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Delivery Date Picker Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    final selectedDate = await Navigator.of(context).push<DateTime>(
                      MaterialPageRoute(
                        builder: (context) => DeliveryDatePickerScreen(
                          initialDate: _selectedDeliveryDate,
                          onDateSelected: (date) {
                            setState(() => _selectedDeliveryDate = date);
                          },
                          title: 'Select Delivery Date',
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                    if (selectedDate != null) {
                      setState(() => _selectedDeliveryDate = selectedDate);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Delivery Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDeliveryDate != null
                                    ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDeliveryDate!)
                                    : 'Tap to select a date',
                                style: TextStyle(
                                  color: _selectedDeliveryDate != null
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600,
                                  fontWeight: _selectedDeliveryDate != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Custom Tracking Number (Optional)
              TextField(
                controller: _trackingController,
                decoration: InputDecoration(
                  labelText: 'Custom Tracking Number (Optional)',
                  hintText: 'Leave empty for auto-generation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _customTrackingNumber = value,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    return completer.future;
  }

  Future<void> _showDeliveryNotesDialog() async {
    final completer = Completer<void>();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Delivery Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _deliveryNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  hintText: 'e.g., "Left at front door", "Delivered to neighbor"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => _deliveryNotes = value,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        completer.complete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${widget.orderId.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      ElevatedButton(
                        onPressed: _loadOrderDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderHeader(),
                            const SizedBox(height: 20),
                            _buildBuyerInfo(),
                            const SizedBox(height: 20),
                            _buildOrderItems(),
                            const SizedBox(height: 20),
                            _buildDeliveryInfo(),
                            const SizedBox(height: 20),
                            _buildOrderSummary(),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_order!.farmerStatus).withOpacity(0.1),
                          border: Border.all(color: _getStatusColor(_order!.farmerStatus)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusDisplayName(_order!.farmerStatus),
                          style: TextStyle(
                            color: _getStatusColor(_order!.farmerStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   const Text(
                     'Order Date',
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.grey,
                     ),
                   ),
                   Text(
                     _formatDate(_order!.createdAt),
                     style: const TextStyle(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   if (_order!.farmerStatus == FarmerOrderStatus.completed && _order!.completedAt != null) ...[
                     const SizedBox(height: 6),
                     const Text(
                       'Delivered',
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.grey,
                       ),
                     ),
                     Text(
                       _formatDate(_order!.completedAt!),
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ] else if (_order!.deliveryDate != null) ...[
                     const SizedBox(height: 6),
                     const Text(
                       'Delivery',
                       style: TextStyle(
                         fontSize: 12,
                         color: Colors.grey,
                       ),
                     ),
                     Text(
                       _formatDate(_order!.deliveryDate!),
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ]
                 ],
               ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buyer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('Name: '),
                Text(
                  _order!.buyerProfile?.fullName ?? 'Unknown Buyer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('Phone: '),
                Text(
                  _order!.buyerProfile?.phoneNumber ?? 'No phone number',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _order!.items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _order!.items[index];
                return Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: (item.productImageUrl != null && item.productImageUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: item.productImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₱${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           const Text(
             'Delivery Information',
             style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: 12),
           if (_order!.farmerStatus == FarmerOrderStatus.completed && _order!.completedAt != null) ...[
             Row(
               children: [
                 const Icon(Icons.done_all, color: AppTheme.primaryGreen),
                 const SizedBox(width: 8),
                 const Text('Delivered on: '),
                 Text(
                   _formatDate(_order!.completedAt!),
                   style: const TextStyle(fontWeight: FontWeight.bold),
                 ),
               ],
             ),
             const SizedBox(height: 12),
           ] else if (_order!.deliveryDate != null) ...[
             Row(
               children: [
                 const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                 const SizedBox(width: 8),
                 const Text('Delivery date: '),
                 Text(
                   _formatDate(_order!.deliveryDate!),
                   style: const TextStyle(fontWeight: FontWeight.bold),
                 ),
               ],
             ),
             const SizedBox(height: 12),
           ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address:'),
                      Text(
                        _order!.deliveryAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_order!.specialInstructions != null && _order!.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Special Instructions:'),
                        Text(
                          _order!.specialInstructions!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    double sumItemsSubtotal() => _order?.items.fold<double>(0.0, (s, i) => s + i.subtotal) ?? 0.0;
    Widget summaryRow(String label, double amount, {String? subtitle}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('₱${amount.toStringAsFixed(2)}'),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summaryRow('Subtotal', _order!.subtotal ?? _order!.items.fold<double>(0.0, (s, i) => s + i.subtotal)),
                const SizedBox(height: 6),
                summaryRow('Delivery Fee', _order!.deliveryFee ?? 0.0),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:'),
                    Text(
                      '₱${_order!.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_order!.farmerStatus == FarmerOrderStatus.completed ||
        _order!.farmerStatus == FarmerOrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Quick Message Buyer action
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _messageBuyer,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Buyer'),
          ),
        ),
        const SizedBox(height: 8),
        if (_order!.farmerStatus == FarmerOrderStatus.newOrder) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(FarmerOrderStatus.accepted),
              icon: const Icon(Icons.check),
              label: const Text('Accept Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCancelDialog,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ] else if (_order!.farmerStatus == FarmerOrderStatus.accepted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(FarmerOrderStatus.toPack),
              icon: const Icon(Icons.inventory),
              label: const Text('Start Packing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ] else if (_order!.farmerStatus == FarmerOrderStatus.toPack) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatusWithDeliveryInfo(FarmerOrderStatus.toDeliver),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Mark as Packed - Ready for Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ] else if (_order!.farmerStatus == FarmerOrderStatus.toDeliver) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatusWithDeliveryInfo(FarmerOrderStatus.completed),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _orderService.cancelOrder(
                  orderId: widget.orderId,
                  cancelReason: reasonController.text,
                );
                await _loadOrderDetails();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel order: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _messageBuyer() async {
    if (_order == null) return;
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send a message.')),
      );
      context.go(RouteNames.login);
      return;
    }

    try {
      final conversation = await _chatService.getOrCreateConversation(
        buyerId: _order!.buyerId,
        farmerId: _order!.farmerId,
      );
      // Do not send any draft automatically for farmer flow
      if (!mounted) return;
      final path = RouteNames.chatConversation.replaceAll(':conversationId', conversation.id);
      context.push(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: ${e.toString()}')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}