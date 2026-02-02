import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/custom_button.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, get all orders (you may want to add admin service method)
      // This is a simplified version - ideally add a proper admin order list method
      final orders = await _getAllOrders();
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Temporary method - should be in admin_service.dart
  Future<List<OrderModel>> _getAllOrders() async {
    // This would need a proper admin RPC or service method
    // For now, returning empty list as placeholder
    return [];
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'all') return _orders;
    if (_selectedFilter == 'overdue') {
      return _orders.where((o) => 
        o.farmerStatus != FarmerOrderStatus.completed &&
        o.farmerStatus != FarmerOrderStatus.cancelled
      ).toList();
    }
    if (_selectedFilter == 'fault') {
      return _orders.where((o) => 
        o.toJson()['farmer_fault'] == true
      ).toList();
    }
    return _orders;
  }

  Future<void> _reportFarmerFault(OrderModel order) async {
    final reasons = [
      'Delivery deadline exceeded',
      'Product quality issues',
      'Wrong items delivered',
      'Product never delivered',
      'Farmer not responding',
      'Damaged products',
      'Incomplete order',
      'Other',
    ];

    String? selectedReason;
    final detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Farmer Fault'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${order.farmerStatusDisplayName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
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
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will mark the order as farmer fault and allow the buyer to request a refund.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select reason:',
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
                      items: reasons.map((reason) {
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
                    labelText: 'Additional details',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Provide more information about the fault',
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
                foregroundColor: Colors.orange,
              ),
              child: const Text('Report Fault'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final faultReason = selectedReason! + 
        (detailsController.text.trim().isEmpty 
          ? '' 
          : ': ${detailsController.text.trim()}');

      await _orderService.reportFarmerFault(
        orderId: order.id,
        faultReason: faultReason,
        reportedBy: currentUser.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farmer fault reported successfully. Buyer can now request refund.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        await _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting fault: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterChip('All Orders', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Overdue', 'overdue'),
                const SizedBox(width: 8),
                _buildFilterChip('Faults', 'fault'),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? LoadingWidgets.fullScreenLoader(message: 'Loading orders...')
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'all'
                                      ? 'No orders found'
                                      : _selectedFilter == 'overdue'
                                          ? 'No overdue orders'
                                          : 'No orders with faults',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(_filteredOrders[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isFault = order.toJson()['farmer_fault'] == true;
    final isOverdue = order.toJson()['is_overdue'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFault ? Colors.orange.shade300 : Colors.grey.shade200,
          width: isFault ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(order.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.farmerStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.farmerStatusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(order.farmerStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Order details
            _buildInfoRow(Icons.person, 'Buyer', order.buyerProfile?.fullName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.store, 'Farmer', order.farmerProfile?.storeName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Amount', '₱${order.totalAmount.toStringAsFixed(2)}'),

            // Fault indicators
            if (isFault) ...[
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
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farmer Fault Reported',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                          if (order.toJson()['fault_reason'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.toJson()['fault_reason'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (isOverdue && !isFault) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order is overdue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (!isFault && 
                order.farmerStatus != FarmerOrderStatus.completed &&
                order.farmerStatus != FarmerOrderStatus.cancelled) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Report Farmer Fault',
                onPressed: () => _reportFarmerFault(order),
                width: double.infinity,
                backgroundColor: Colors.orange,
                icon: Icons.flag,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(FarmerOrderStatus status) {
    switch (status) {
      case FarmerOrderStatus.newOrder:
        return Colors.blue;
      case FarmerOrderStatus.accepted:
        return Colors.green;
      case FarmerOrderStatus.toPack:
        return Colors.orange;
      case FarmerOrderStatus.toDeliver:
        return Colors.purple;
      case FarmerOrderStatus.readyForPickup:
        return Colors.teal;
      case FarmerOrderStatus.completed:
        return AppTheme.successGreen;
      case FarmerOrderStatus.cancelled:
        return AppTheme.errorRed;
    }
  }
}
