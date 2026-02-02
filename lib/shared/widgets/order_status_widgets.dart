import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/order_model.dart';
import '../../core/theme/app_theme.dart';
import 'order_map_tracking.dart';

class OrderStatusChip extends StatelessWidget {
  final FarmerOrderStatus status;
  final bool showIcon;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(status),
              size: 16,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _getStatusDisplayName(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return Colors.orange.shade700;
      case FarmerOrderStatus.accepted:
        return Colors.teal.shade700;
      case FarmerOrderStatus.toPack:
        return Colors.blue.shade700;
      case FarmerOrderStatus.toDeliver:
        return Colors.indigo.shade700;
      case FarmerOrderStatus.readyForPickup:
        return Colors.purple.shade700;
      case FarmerOrderStatus.completed:
        return Colors.green.shade700;
      case FarmerOrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  IconData _getStatusIcon(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return Icons.new_releases;
      case FarmerOrderStatus.accepted:
        return Icons.check_circle;
      case FarmerOrderStatus.toPack:
        return Icons.inventory_2;
      case FarmerOrderStatus.toDeliver:
        return Icons.local_shipping;
      case FarmerOrderStatus.readyForPickup:
        return Icons.store_rounded;
      case FarmerOrderStatus.completed:
        return Icons.done_all;
      case FarmerOrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDisplayName(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return 'New Order';
      case FarmerOrderStatus.accepted:
        return 'Order Accepted';
      case FarmerOrderStatus.toPack:
        return 'Being Packed';
      case FarmerOrderStatus.toDeliver:
        return 'Out for Delivery';
      case FarmerOrderStatus.readyForPickup:
        return 'Ready for Pick-up';
      case FarmerOrderStatus.completed:
        return 'Delivered';
      case FarmerOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderProgressIndicator extends StatelessWidget {
  final FarmerOrderStatus currentStatus;
  final bool isCompact;

  const OrderProgressIndicator({
    super.key,
    required this.currentStatus,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _getOrderSteps();
    final currentStepIndex = _getCurrentStepIndex();

    if (isCompact) {
      return _buildCompactProgress(steps, currentStepIndex);
    }

    return _buildFullProgress(steps, currentStepIndex);
  }

  Widget _buildFullProgress(List<OrderStep> steps, int currentStepIndex) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepItem(steps[i], i, currentStepIndex),
          if (i < steps.length - 1) _buildStepConnector(i < currentStepIndex),
        ],
      ],
    );
  }

  Widget _buildCompactProgress(List<OrderStep> steps, int currentStepIndex) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: currentStepIndex / (steps.length - 1),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStatusColor(currentStatus),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${currentStepIndex + 1}/${steps.length}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _getStatusColor(currentStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(OrderStep step, int index, int currentStepIndex) {
    final isCompleted = index < currentStepIndex;
    final isCurrent = index == currentStepIndex;
    final isUpcoming = index > currentStepIndex;

    Color color;
    if (isCompleted) {
      color = Colors.green.shade600;
    } else if (isCurrent) {
      color = _getStatusColor(currentStatus);
    } else {
      color = Colors.grey.shade400;
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            size: 18,
            color: isCompleted ? Colors.white : color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUpcoming ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
              if (step.description.isNotEmpty)
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isCompleted ? Colors.green.shade600 : Colors.grey.shade300,
    );
  }

  List<OrderStep> _getOrderSteps() {
    return [
      OrderStep(
        status: FarmerOrderStatus.newOrder,
        title: 'New Order',
        description: 'Waiting for farmer confirmation',
        icon: Icons.new_releases,
      ),
      OrderStep(
        status: FarmerOrderStatus.accepted,
        title: 'Order Accepted',
        description: 'Farmer will prepare your order',
        icon: Icons.check_circle,
      ),
      OrderStep(
        status: FarmerOrderStatus.toPack,
        title: 'Being Prepared',
        description: 'Your order is being packed',
        icon: Icons.inventory_2,
      ),
      OrderStep(
        status: FarmerOrderStatus.toDeliver,
        title: 'Out for Delivery',
        description: 'Your order is on its way',
        icon: Icons.local_shipping,
      ),
      OrderStep(
        status: FarmerOrderStatus.completed,
        title: 'Delivered',
        description: 'Order delivered successfully',
        icon: Icons.done_all,
      ),
    ];
  }

  int _getCurrentStepIndex() {
    final steps = _getOrderSteps();
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].status == currentStatus) {
        return i;
      }
    }
    return 0;
  }

  Color _getStatusColor(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return Colors.orange.shade700;
      case FarmerOrderStatus.accepted:
        return Colors.teal.shade700;
      case FarmerOrderStatus.toPack:
        return Colors.blue.shade700;
      case FarmerOrderStatus.toDeliver:
        return Colors.indigo.shade700;
      case FarmerOrderStatus.readyForPickup:
        return Colors.purple.shade700;
      case FarmerOrderStatus.completed:
        return Colors.green.shade700;
      case FarmerOrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }
}

class OrderStep {
  final FarmerOrderStatus status;
  final String title;
  final String description;
  final IconData icon;

  OrderStep({
    required this.status,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class CancelOrderDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelOrderDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange),
          const SizedBox(width: 8),
          const Text('Cancel Order'),
        ],
      ),
      content: const Text(
        'Are you sure you want to cancel this order? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Keep Order',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}

class DeliveryInformationCard extends StatelessWidget {
  final OrderModel order;
  final bool showBuyerInfo;

  const DeliveryInformationCard({
    super.key,
    required this.order,
    this.showBuyerInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery Address
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Delivery Address',
              value: order.deliveryAddress,
              color: Colors.green.shade700,
            ),
            
            // Tracking Number
            if (order.trackingNumber != null) ...[
              const SizedBox(height: 12),
              _buildTrackingRow(context, order.trackingNumber!),
            ],
            
            // Delivery Date
            if (order.deliveryDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Scheduled Delivery',
                value: DateFormat('MMM dd, yyyy').format(order.deliveryDate!),
                color: AppTheme.accentOrange,
              ),
            ],
            
            // Delivery Notes
            if (order.deliveryNotes != null && order.deliveryNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.note,
                label: 'Delivery Notes',
                value: order.deliveryNotes!,
                color: Colors.purple.shade700,
                isMultiline: true,
              ),
            ],
            
            // Special Instructions
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.info,
                label: 'Special Instructions',
                value: order.specialInstructions!,
                color: Colors.teal.shade700,
                isMultiline: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingRow(BuildContext context, String trackingNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_shipping, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trackingNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16, color: Colors.blue.shade700),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: trackingNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tracking number copied to clipboard'),
                          backgroundColor: Colors.green.shade600,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy tracking number',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BuyerInformationCard extends StatelessWidget {
  final OrderModel order;

  const BuyerInformationCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.person,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buyer Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Buyer Name
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Customer Name',
              value: order.buyerProfile?.fullName ?? 'Loading...',
              color: Colors.green.shade700,
            ),
            
            // Phone Number with Call Action
            if (order.buyerProfile?.phoneNumber != null) ...[
              const SizedBox(height: 12),
              _buildContactRow(
                context,
                order.buyerProfile!.phoneNumber,
              ),
            ],
            
            // Order Date
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Order Date',
              value: DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
              color: Colors.blue.shade700,
            ),
            
            // Order Value
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Order Total',
              value: '₱${order.totalAmount.toStringAsFixed(2)}',
              color: AppTheme.accentOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, String phoneNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phone, size: 16, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone, size: 16, color: Colors.green.shade700),
                    onPressed: () {
                      // Copy phone number to clipboard
                      Clipboard.setData(ClipboardData(text: phoneNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Phone number copied to clipboard'),
                          backgroundColor: Colors.green.shade600,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy phone number',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Detailed order timeline widget that shows all status changes with timestamps
/// Supports real-time updates via Supabase subscriptions
class DetailedOrderTimeline extends StatefulWidget {
  final OrderModel order;
  final bool showDuration;
  final bool enableRealtime;

  const DetailedOrderTimeline({
    super.key,
    required this.order,
    this.showDuration = true,
    this.enableRealtime = true,
  });

  @override
  State<DetailedOrderTimeline> createState() => _DetailedOrderTimelineState();
}

class _DetailedOrderTimelineState extends State<DetailedOrderTimeline> {
  late OrderModel _currentOrder;
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    if (widget.enableRealtime) {
      _subscribeToOrderUpdates();
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToOrderUpdates() {
    // Subscribe to real-time order updates
    _orderSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.order.id)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _currentOrder = OrderModel.fromJson(data.first);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final timelineEvents = _buildTimelineEvents();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (widget.enableRealtime)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Timeline events
            ...List.generate(timelineEvents.length, (index) {
              final event = timelineEvents[index];
              final isLast = index == timelineEvents.length - 1;
              
              return _buildTimelineItem(
                event: event,
                isLast: isLast,
                showDuration: widget.showDuration && index > 0 && event.timestamp != null,
                previousEvent: index > 0 ? timelineEvents[index - 1] : null,
              );
            }),
            
            // Map tracking (for delivery orders in transit)
            if (_currentOrder.farmerStatus == FarmerOrderStatus.toDeliver &&
                _currentOrder.deliveryMethod == 'delivery' &&
                _currentOrder.buyerLatitude != null &&
                _currentOrder.buyerLongitude != null) ...[
              const SizedBox(height: 20),
              _buildMapTracking(),
            ],
            
            // Total order duration (if completed)
            if (_currentOrder.completedAt != null && widget.showDuration) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Total Duration: ${_formatDuration(_currentOrder.createdAt, _currentOrder.completedAt!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Estimated delivery time (for pending orders)
            if (_currentOrder.farmerStatus == FarmerOrderStatus.toDeliver &&
                _currentOrder.estimatedDeliveryAt != null) ...[
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
                    Icon(Icons.access_time, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(_currentOrder.estimatedDeliveryAt!),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade600,
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
      ),
    );
  }

  Widget _buildTimelineItem({
    required TimelineEvent event,
    required bool isLast,
    bool showDuration = false,
    TimelineEvent? previousEvent,
  }) {
    final isCompleted = event.timestamp != null;
    final isPending = !isCompleted;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                // Status circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? event.color : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? event.color : Colors.grey.shade300,
                      width: 2.5,
                    ),
                    boxShadow: isCompleted ? [
                      BoxShadow(
                        color: event.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : event.icon,
                    size: 20,
                    color: isCompleted ? Colors.white : Colors.grey.shade400,
                  ),
                ),
                
                // Connecting line
                if (!isLast)
                  Container(
                    width: 2.5,
                    height: showDuration ? 60 : 50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isCompleted
                            ? [event.color, event.color.withOpacity(0.3)]
                            : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status title
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey.shade900 : Colors.grey.shade500,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Timestamp
                  if (event.timestamp != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(event.timestamp!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Duration since previous event
                    if (showDuration && previousEvent?.timestamp != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(previousEvent!.timestamp!, event.timestamp!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Pending...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<TimelineEvent> _buildTimelineEvents() {
    final events = <TimelineEvent>[];
    
    // Order placed
    events.add(TimelineEvent(
      status: FarmerOrderStatus.newOrder,
      title: 'Order Placed',
      description: _currentOrder.deliveryMethod == 'pickup' 
          ? 'Your order has been submitted for pickup'
          : 'Your order has been submitted',
      icon: Icons.receipt_long,
      color: Colors.blue.shade600,
      timestamp: _currentOrder.createdAt,
    ));
    
    // For non-cancelled orders, add progression steps
    if (_currentOrder.farmerStatus != FarmerOrderStatus.cancelled) {
      // Order accepted
      events.add(TimelineEvent(
        status: FarmerOrderStatus.accepted,
        title: 'Order Confirmed',
        description: 'Farmer has accepted your order',
        icon: Icons.verified,
        color: Colors.teal.shade600,
        timestamp: _getStatusTimestamp(FarmerOrderStatus.accepted),
      ));
      
      // Being prepared
      events.add(TimelineEvent(
        status: FarmerOrderStatus.toPack,
        title: 'Preparing Order',
        description: 'Your items are being packed',
        icon: Icons.inventory_rounded,
        color: Colors.orange.shade600,
        timestamp: _getStatusTimestamp(FarmerOrderStatus.toPack),
      ));
      
      // Check if pickup or delivery
      if (_currentOrder.deliveryMethod == 'pickup') {
        // Pickup flow
        events.add(TimelineEvent(
          status: FarmerOrderStatus.readyForPickup,
          title: 'Ready for Pickup',
          description: _currentOrder.pickupAddress != null 
              ? 'Available at: ${_currentOrder.pickupAddress}'
              : 'Your order is ready to be picked up',
          icon: Icons.storefront_rounded,
          color: Colors.purple.shade600,
          timestamp: _getStatusTimestamp(FarmerOrderStatus.readyForPickup),
        ));
      } else {
        // Delivery flow
        events.add(TimelineEvent(
          status: FarmerOrderStatus.toDeliver,
          title: 'Out for Delivery',
          description: _currentOrder.trackingNumber != null 
              ? 'Tracking: ${_currentOrder.trackingNumber}'
              : 'Your order is on the way',
          icon: Icons.local_shipping_rounded,
          color: Colors.indigo.shade600,
          timestamp: _getStatusTimestamp(FarmerOrderStatus.toDeliver),
        ));
      }
      
      // Completed
      events.add(TimelineEvent(
        status: FarmerOrderStatus.completed,
        title: _currentOrder.deliveryMethod == 'pickup' ? 'Order Picked Up' : 'Order Delivered',
        description: _currentOrder.deliveryNotes ?? 'Order completed successfully',
        icon: Icons.task_alt_rounded,
        color: Colors.green.shade600,
        timestamp: _currentOrder.completedAt,
      ));
    } else {
      // Cancelled order
      events.add(TimelineEvent(
        status: FarmerOrderStatus.cancelled,
        title: 'Order Cancelled',
        description: 'This order has been cancelled',
        icon: Icons.cancel_rounded,
        color: Colors.red.shade600,
        timestamp: _currentOrder.updatedAt ?? _currentOrder.createdAt,
      ));
    }
    
    return events;
  }

  DateTime? _getStatusTimestamp(FarmerOrderStatus targetStatus) {
    // Use individual timestamps from the order model
    switch (targetStatus) {
      case FarmerOrderStatus.newOrder:
        return _currentOrder.createdAt;
      case FarmerOrderStatus.accepted:
        return _currentOrder.acceptedAt;
      case FarmerOrderStatus.toPack:
        return _currentOrder.toPackAt;
      case FarmerOrderStatus.toDeliver:
        return _currentOrder.toDeliverAt;
      case FarmerOrderStatus.readyForPickup:
        return _currentOrder.readyForPickupAt;
      case FarmerOrderStatus.completed:
        return _currentOrder.completedAt;
      case FarmerOrderStatus.cancelled:
        return _currentOrder.cancelledAt;
    }
  }

  bool _isStatusReached(FarmerOrderStatus targetStatus) {
    final currentIndex = _getStatusIndex(_currentOrder.farmerStatus);
    final targetIndex = _getStatusIndex(targetStatus);
    return currentIndex >= targetIndex;
  }

  int _getStatusIndex(FarmerOrderStatus status) {
    const statusOrder = [
      FarmerOrderStatus.newOrder,
      FarmerOrderStatus.accepted,
      FarmerOrderStatus.toPack,
      FarmerOrderStatus.toDeliver,
      FarmerOrderStatus.readyForPickup,
      FarmerOrderStatus.completed,
    ];
    final index = statusOrder.indexOf(status);
    return index >= 0 ? index : 0;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    
    return DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp);
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    
    if (duration.inMinutes < 1) {
      return 'Less than a minute';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inDays < 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hours';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '$days days $hours hr';
      }
      return '$days days';
    }
  }

  Widget _buildMapTracking() {
    // Import the map tracking widget dynamically
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_rounded, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Delivery Tracking',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your order is on the way! Track real-time location below.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to full map tracking screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      // Lazy load the map widget
                      try {
                        // Import is done at top of file, so we can use it directly
                        return Scaffold(
                          appBar: AppBar(
                            title: const Text('Delivery Tracking'),
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          body: OrderMapTracking(
                            order: _currentOrder,
                            showRoute: true,
                            height: double.infinity,
                          ),
                        );
                      } catch (e) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Map Unavailable')),
                          body: Center(
                            child: Text('Map tracking is not available: $e'),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('View Live Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineEvent {
  final FarmerOrderStatus status;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? timestamp;

  TimelineEvent({
    required this.status,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.timestamp,
  });
}