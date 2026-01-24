import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/delivery_date_picker.dart';
import '../../../core/theme/app_theme.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSub;

  late TabController _tabController;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _newOrders = [];
  List<OrderModel> _acceptedOrders = [];
  List<OrderModel> _toPackOrders = [];
  List<OrderModel> _toDeliverOrders = [];
  List<OrderModel> _readyForPickupOrders = [];
  List<OrderModel> _completedOrders = [];

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadOrders().then((_) async {
      final user = await _authService.getCurrentUserProfile();
      if (user == null) return;
      _ordersSub?.cancel();
      _ordersSub = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('farmer_id', user.id)
          .listen((rows) async {
            await _loadOrders();
          });
    });
  }

  // Realtime via table stream initialized in initState

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final farmerId = _authService.currentUser!.id;
      _allOrders = await _orderService.getFarmerOrders(farmerId: farmerId);

      // Filter orders by status
      _newOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.newOrder)
          .toList();
      _acceptedOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.accepted)
          .toList();
      _toPackOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.toPack)
          .toList();
      _toDeliverOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.toDeliver)
          .toList();
      _readyForPickupOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.readyForPickup)
          .toList();
      _completedOrders = _allOrders
          .where((order) => order.farmerStatus == FarmerOrderStatus.completed)
          .toList();

    } catch (e) {
      _error = 'Failed to load orders: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(OrderModel order, FarmerOrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: order.id,
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

      // Reload orders
      await _loadOrders();
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

  Future<void> _updateOrderStatusWithDeliveryInfo(OrderModel order, FarmerOrderStatus newStatus) async {
    DateTime? selectedDeliveryDate;
    String deliveryNotes = '';
    String customTrackingNumber = '';
    
    try {
      // If updating to toDeliver, show delivery scheduling dialog
      if (newStatus == FarmerOrderStatus.toDeliver) {
        final result = await _showDeliverySchedulingDialog(order);
        if (result == null) return; // User cancelled
        selectedDeliveryDate = result['deliveryDate'];
        customTrackingNumber = result['trackingNumber'] ?? '';
      }
      
      // If completing order, show delivery notes dialog
      if (newStatus == FarmerOrderStatus.completed && order.deliveryMethod != 'pickup') {
        final result = await _showDeliveryNotesDialog(order);
        if (result == null) return; // User cancelled
        deliveryNotes = result['notes'] ?? '';
      }
      
      // Update order status with optional tracking info
      await _orderService.updateOrderStatusWithTracking(
        orderId: order.id,
        farmerStatus: newStatus,
        deliveryDate: selectedDeliveryDate,
        deliveryNotes: deliveryNotes.isNotEmpty ? deliveryNotes : null,
        trackingNumber: customTrackingNumber.isNotEmpty ? customTrackingNumber : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }

      // Reload orders
      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showDeliverySchedulingDialog(OrderModel order) async {
    DateTime? selectedDeliveryDate;
    final trackingController = TextEditingController();
    
    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.indigo.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule Delivery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            initialDate: selectedDeliveryDate,
                            onDateSelected: (date) {
                              setState(() => selectedDeliveryDate = date);
                            },
                            title: 'Select Delivery Date',
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                      if (selectedDate != null) {
                        setState(() => selectedDeliveryDate = selectedDate);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: selectedDeliveryDate != null 
                                ? Colors.green.shade600 
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedDeliveryDate != null
                                      ? DateFormat('EEEE, MMM d, yyyy').format(selectedDeliveryDate!)
                                      : 'Tap to select a date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedDeliveryDate != null
                                        ? Colors.green.shade700
                                        : Colors.grey.shade500,
                                    fontWeight: selectedDeliveryDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Custom Tracking Number (Optional)
                TextField(
                  controller: trackingController,
                  decoration: InputDecoration(
                    labelText: 'Tracking Number (Optional)',
                    hintText: 'Leave empty for auto-generation',
                    prefixIcon: Icon(Icons.qr_code_2, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'deliveryDate': selectedDeliveryDate,
                            'trackingNumber': trackingController.text.trim(),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showDeliveryNotesDialog(OrderModel order) async {
    final notesController = TextEditingController();
    
    return await showDialog<Map<String, dynamic>?>(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Confirmation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  hintText: 'e.g., "Left at front door", "Received by neighbor"',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop({'notes': ''});
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'notes': notesController.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Delivery',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_allOrders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by order ID or buyer name...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('All'),
                  if (_allOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_allOrders.length}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('New'),
                  if (_newOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_newOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Accepted'),
                  if (_acceptedOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade400,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_acceptedOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('To Pack'),
                  if (_toPackOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_toPackOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('To Deliver'),
                  if (_toDeliverOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade400,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_toDeliverOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ready Pickup'),
                  if (_readyForPickupOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade400,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_readyForPickupOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Done'),
                  if (_completedOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_completedOrders.length}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
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
          ),
        ),
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
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(_allOrders, 'No orders yet'),
                      _buildOrdersList(_newOrders, 'No new orders'),
                      _buildOrdersList(_acceptedOrders, 'No accepted orders'),
                      _buildOrdersList(_toPackOrders, 'No orders to pack'),
                      _buildOrdersList(_toDeliverOrders, 'No orders to deliver'),
                      _buildOrdersList(_readyForPickupOrders, 'No orders ready for pickup'),
                      _buildOrdersList(_completedOrders, 'No completed orders'),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New orders will appear here',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildOrderCard(orders[index]),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final changed = await context.push(
              RouteNames.farmerOrderDetails.replaceAll(':id', order.id),
            );
            if (changed == true) {
              await _loadOrders();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header with Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.farmerStatus).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(order.farmerStatus),
                        color: _getStatusColor(order.farmerStatus),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.buyerProfile?.fullName ?? 'Unknown Buyer',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(order.farmerStatus),
                            _getStatusColor(order.farmerStatus).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(order.farmerStatus).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusDisplayName(order.farmerStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Order Items Summary with icon
                Row(
                  children: [
                    Icon(Icons.shopping_basket_rounded, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Item thumbnails with modern styling
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: (item.productImageUrl != null && item.productImageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: item.productImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[100],
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[100],
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 24),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[100],
                                    alignment: Alignment.center,
                                    child: Icon(Icons.image_rounded, color: Colors.grey[400], size: 24),
                                  ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemCount: order.items.length.clamp(0, 6),
                  ),
                ),

                const SizedBox(height: 16),

                // Order Total and Date with modern layout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade50.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.green.shade700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (order.farmerStatus == FarmerOrderStatus.completed && order.completedAt != null) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delivered',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatExactDateTime(order.completedAt!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ] else if (order.deliveryDate != null) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_shipping_rounded, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delivery',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatExactDateTime(order.deliveryDate!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ] else ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatExactDateTime(order.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

              // Action Buttons with modern styling
              if (order.farmerStatus == FarmerOrderStatus.newOrder) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(order, FarmerOrderStatus.accepted),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shadowColor: Colors.teal.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          'Accept',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300, width: 2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showCancelDialog(order),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.close_rounded, size: 22, color: Colors.red.shade600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (order.farmerStatus == FarmerOrderStatus.accepted) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order, FarmerOrderStatus.toPack),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.inventory_2_rounded, size: 20),
                    label: const Text(
                      'Start Packing',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ] else if (order.farmerStatus == FarmerOrderStatus.toPack) ...[
                // Check delivery method to show correct next status
                if (order.deliveryMethod == 'pickup') ...[
                  // Pickup orders: toPack → readyForPickup
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order, FarmerOrderStatus.readyForPickup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.purple.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.store_rounded, size: 20),
                      label: const Text(
                        'Mark Ready for Pickup',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Delivery orders: toPack → toDeliver (with popup)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatusWithDeliveryInfo(order, FarmerOrderStatus.toDeliver),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.indigo.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 20),
                      label: const Text(
                        'Ready for Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else if (order.farmerStatus == FarmerOrderStatus.toDeliver) ...[
                // Delivery orders: toDeliver → completed (with popup)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatusWithDeliveryInfo(order, FarmerOrderStatus.completed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Mark as Delivered',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ] else if (order.farmerStatus == FarmerOrderStatus.readyForPickup) ...[
                // Pickup orders: readyForPickup → completed
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order, FarmerOrderStatus.completed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Mark as Picked Up',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Keep Order',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () async {
              Navigator.pop(context);
              try {
                await _orderService.cancelOrder(
                  orderId: order.id,
                  cancelReason: reasonController.text,
                );
                await _loadOrders();
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return _formatExactDate(date);
    }
  }

  String _formatExactDate(DateTime date) {
    return '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';
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