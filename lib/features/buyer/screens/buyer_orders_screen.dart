import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../../shared/widgets/modern_bottom_nav.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;
  final OrderService _orderService = OrderService();
  
  late TabController _tabController;
  
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _completedOrders = [];
  bool _isLoading = true;
  bool _isCancelling = false;
  
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final response = await _supabase.orders
          .select('''
            *,
            order_items (*)
          ''')
          .eq('buyer_id', currentUser.id)
          .order('created_at', ascending: false);

      final orders = response.map((json) => OrderModel.fromJson(json)).toList();
      
      setState(() {
        _activeOrders = orders.where((order) => 
          order.farmerStatus != FarmerOrderStatus.completed && 
          order.farmerStatus != FarmerOrderStatus.cancelled
        ).toList();
        _completedOrders = orders.where((order) => 
          order.farmerStatus == FarmerOrderStatus.completed || 
          order.farmerStatus == FarmerOrderStatus.cancelled
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelOrder(OrderModel order, String reason) async {
    if (_isCancelling) return;
    
    // Check if order can be cancelled
    if (order.farmerStatus != FarmerOrderStatus.newOrder && 
        order.farmerStatus != FarmerOrderStatus.accepted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot cancel order. Farmer has already started preparing your order.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isCancelling = true);
    
    try {
      await _orderService.cancelOrder(
        orderId: order.id,
        cancelReason: reason,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        // Reload orders to refresh the list
        await _loadOrders();
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

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    String? selectedReason;
    
    showDialog(
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
                      Navigator.pop(context);
                      _cancelOrder(order, selectedReason!);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () {
            // Smart navigation - check if we can pop back
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              // If accessed directly, go to buyer home
              context.go(RouteNames.buyerHome);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order search coming soon!')),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              text: 'Active (${_activeOrders.length})',
            ),
            Tab(
              text: 'Completed (${_completedOrders.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_activeOrders, isActive: true),
                _buildOrdersList(_completedOrders, isActive: false),
              ],
            ),
      bottomNavigationBar: const ModernBottomNav(currentIndex: 2),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: 100, // Space for bottom navigation
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            Lottie.asset(
              'assets/lottie/empty_orders.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isActive ? 'No active orders' : 'No order history',
              style: AppTextStyles.heading2.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isActive 
                  ? 'Start shopping for fresh products from local farmers!'
                  : 'Your completed orders will appear here.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.buyerHome),
                icon: const Icon(Icons.shopping_bag, color: Colors.white),
                label: const Text('Start Shopping', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push(
          RouteNames.buyerOrderDetails.replaceAll(':id', order.id),
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildStatusChip(order.farmerStatus),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Order details
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Builder(
                    builder: (_) {
                      if (order.farmerStatus == FarmerOrderStatus.completed && order.completedAt != null) {
                        return Text('Delivered: ${_formatExactDateTime(order.completedAt!)}', style: AppTextStyles.bodySmall);
                      } else if (order.deliveryDate != null) {
                        return Text('Delivery: ${_formatExactDateTime(order.deliveryDate!)}', style: AppTextStyles.bodySmall);
                      } else {
                        return Text('Ordered: ${_formatExactDateTime(order.createdAt)}', style: AppTextStyles.bodySmall);
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.shopping_bag,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Order items preview
              if (order.items.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.items.map((item) => item.productName).join(', '),
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              
              // Order footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      if (order.farmerStatus == FarmerOrderStatus.newOrder || 
                          order.farmerStatus == FarmerOrderStatus.accepted)
                        TextButton(
                          onPressed: _isCancelling ? null : () {
                            _showCancelOrderDialog(context, order);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                          ),
                          child: _isCancelling 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Cancel'),
                        ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(FarmerOrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case FarmerOrderStatus.newOrder:
        color = Colors.orange.shade700;
        text = 'Order Received';
        break;
      case FarmerOrderStatus.accepted:
        color = Colors.teal.shade700;
        text = 'Order Accepted';
        break;
      case FarmerOrderStatus.toPack:
        color = Colors.blue.shade700;
        text = 'Being Packed';
        break;
      case FarmerOrderStatus.toDeliver:
        color = Colors.indigo.shade700;
        text = 'Out for Delivery';
        break;
      case FarmerOrderStatus.readyForPickup:
        color = Colors.purple.shade700;
        text = 'Ready for Pick-up';
        break;
      case FarmerOrderStatus.completed:
        color = AppTheme.successGreen;
        text = 'Delivered';
        break;
      case FarmerOrderStatus.cancelled:
        color = AppTheme.errorRed;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatExactDateTime(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }
}