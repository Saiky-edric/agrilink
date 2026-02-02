import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  
  Map<String, List<CartItemModel>> _cartByStore = {};
  Map<String, Map<String, dynamic>> _storeInfo = {};
  bool _isLoading = true;
  bool _isUpdating = false;
  
  // Track unavailable items
  Map<String, dynamic>? _cartValidation;
  
  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadJtStep();
  }

  double _jtPer2kgStep = 25.0;
  Future<void> _loadJtStep() async {
    try {
      final step = await OrderService.jtPer2kgStep();
      if (mounted) setState(() => _jtPer2kgStep = step);
    } catch (_) {}
  }
  
  Future<void> _loadCart() async {
    try {
      setState(() => _isLoading = true);
      
      // Validate cart for unavailable items
      final validation = await _cartService.validateCart();
      
      final cartByStore = await _cartService.getCartByStore();
      final Map<String, Map<String, dynamic>> storeInfoMap = {};
      
      // Load store information for each farmer
      for (final farmerId in cartByStore.keys) {
        final storeInfo = await _cartService.getStoreInfo(farmerId);
        if (storeInfo != null) {
          storeInfoMap[farmerId] = storeInfo;
        }
      }
      
      setState(() {
        _cartByStore = cartByStore;
        _storeInfo = storeInfoMap;
        _cartValidation = validation;
        _isLoading = false;
      });
      
      // Show warning if there are unavailable items
      if (mounted && validation['hasIssues'] == true) {
        _showUnavailableItemsDialog(validation);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  void _showUnavailableItemsDialog(Map<String, dynamic> validation) {
    final unavailableItems = validation['unavailableItems'] as List<CartItemModel>;
    final outOfStockItems = validation['outOfStockItems'] as List<CartItemModel>;
    
    if (unavailableItems.isEmpty && outOfStockItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Cart Items Unavailable'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unavailableItems.isNotEmpty) ...[
                const Text(
                  'The following items are no longer available:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...unavailableItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.close, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.product?.name ?? 'Unknown Product',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              if (outOfStockItems.isNotEmpty) ...[
                const Text(
                  'The following items have insufficient stock:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...outOfStockItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.product?.name ?? 'Unknown'} (${item.quantity} needed, ${item.product?.stock ?? 0} available)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
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
                        'Would you like to remove unavailable items from your cart?',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep in Cart'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeUnavailableItems(validation);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove Unavailable'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeUnavailableItems(Map<String, dynamic> validation) async {
    try {
      setState(() => _isUpdating = true);
      
      final removedCount = await _cartService.removeUnavailableItems();
      await _loadCart();
      
      setState(() => _isUpdating = false);
      
      if (mounted && removedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$removedCount unavailable item${removedCount > 1 ? 's' : ''} removed from cart'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove items: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  List<CartItemModel> get _allCartItems {
    return _cartByStore.values.expand((items) => items).toList();
  }

  double get _totalCartItems => _allCartItems.length.toDouble();
  
  double _getStoreSubtotal(List<CartItemModel> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  
  double _getStoreDeliveryFee(List<CartItemModel> items) {
    // Estimated delivery fee using weight-based calculation (single parcel).
    // Uses weight_per_unit from product; if missing, applies a small unit-based fallback.
    double totalKg = 0.0;
    for (final it in items) {
      final p = it.product;
      if (p == null) continue;
      double unitKg = 0.0;
      try {
        final m = p.toJson();
        unitKg = (m['weight_per_unit'] as num?)?.toDouble() ?? 0.0;
        if (unitKg == 0.0) {
          final u = (p.unit).toLowerCase();
          if (u == 'kg' || u == 'kilo' || u == 'kilogram') {
            unitKg = 1.0;
          } else {
            final kgMatch = RegExp(r'([0-9]+\.?[0-9]*)\s*kg').firstMatch(u);
            if (kgMatch != null) {
              unitKg = double.tryParse(kgMatch.group(1)!) ?? 0.0;
            } else if (u.contains('sack') || u.contains('bag')) {
              final sackMatch = RegExp(r'([0-9]+)\s*kg').firstMatch(u);
              unitKg = sackMatch != null ? double.tryParse(sackMatch.group(1)!) ?? 25.0 : 25.0;
            }
          }
        }
      } catch (_) {
        unitKg = 0.0;
      }
      totalKg += unitKg * it.quantity;
    }
    return OrderService.jtFeeForKgWithStep(totalKg, _jtPer2kgStep);
  }
  
  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(cartItemId);
      return;
    }
    
    try {
      setState(() => _isUpdating = true);
      
      await _cartService.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
      );
      await _loadCart(); // Reload cart to get updated data
      
      setState(() => _isUpdating = false);
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  Future<void> _removeItem(String cartItemId) async {
    try {
      setState(() => _isUpdating = true);
      
      await _cartService.removeFromCart(cartItemId);
      await _loadCart(); // Reload cart to get updated data
      
      setState(() => _isUpdating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  Future<void> _clearCart() async {
    try {
      setState(() => _isUpdating = true);
      
      await _cartService.clearCart();
      await _loadCart(); // Reload cart to get updated data
      
      setState(() => _isUpdating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cart: $e'),
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
        title: const Text('My Cart'),
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
              // If accessed directly (e.g., from bottom nav), go to home
              context.go(RouteNames.buyerHome);
            }
          },
        ),
        actions: [
          if (_allCartItems.isNotEmpty)
            TextButton(
              onPressed: _isUpdating ? null : _clearCart,
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allCartItems.isEmpty
              ? _buildEmptyCart()
              : _buildModernCartContent(),
    );
  }
  
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            Lottie.asset(
              'assets/lottie/empty_cart.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Your cart is empty',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add some fresh products to get started!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.buyerHome),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModernCartContent() {
    return Column(
      children: [
        // Modern Cart Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopping Cart',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_allCartItems.length} items from ${_cartByStore.length} ${_cartByStore.length == 1 ? 'store' : 'stores'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Store Groups
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _cartByStore.length,
            itemBuilder: (context, index) {
              final farmerId = _cartByStore.keys.elementAt(index);
              final items = _cartByStore[farmerId]!;
              final storeInfo = _storeInfo[farmerId];
              
              return _buildStoreGroup(farmerId, items, storeInfo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreGroup(String farmerId, List<CartItemModel> items, Map<String, dynamic>? storeInfo) {
    final storeSubtotal = _getStoreSubtotal(items);
    final storeDeliveryFee = _getStoreDeliveryFee(items);
    final storeTotal = storeSubtotal + storeDeliveryFee;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Store Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen,
                  backgroundImage: storeInfo?['store_logo_url'] != null
                      ? NetworkImage(storeInfo!['store_logo_url'])
                      : null,
                  child: storeInfo?['store_logo_url'] == null
                      ? const Icon(Icons.store, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeInfo?['store_name'] ?? storeInfo?['full_name'] ?? 'Farm Store',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (storeInfo?['municipality'] != null)
                        Text(
                          '${storeInfo!['barangay'] ?? ''}, ${storeInfo['municipality']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Store Items
          ...items.map((item) => _buildModernCartItem(item)),
          
          // Store Summary & Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Store Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal (${items.length} items)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '₱${storeSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee', style: TextStyle(fontSize: 14)),
                    Text(
                      '₱${storeDeliveryFee.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Store Total',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₱${storeTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Store Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _checkoutStore(farmerId, items),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Checkout from ${storeInfo?['store_name'] ?? 'Store'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernCartItem(CartItemModel item) {
    // Check if item is unavailable
    final isUnavailable = item.product == null || 
                          item.product!.isDeleted || 
                          item.product!.isHidden || 
                          item.product!.isExpired;
    final isOutOfStock = item.product != null && item.product!.stock < item.quantity;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isUnavailable || isOutOfStock ? BoxDecoration(
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ) : null,
      child: Row(
        children: [
          // Product Image with overlay for unavailable
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.product?.coverImageUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.agriculture,
                      color: AppTheme.primaryGreen,
                      size: 30,
                    ),
                  ),
                ),
              ),
              if (isUnavailable)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Product Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isUnavailable ? TextDecoration.lineThrough : null,
                    color: isUnavailable ? Colors.grey : AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${item.product?.price.toStringAsFixed(2) ?? '0.00'} per ${item.product?.unit ?? 'unit'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                // Show unavailable badge
                if (isUnavailable) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 12, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          item.product == null 
                              ? 'Not Available'
                              : item.product!.isExpired
                                  ? 'Expired'
                                  : 'Removed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isOutOfStock) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Only ${item.product!.stock} available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                
                // Quantity and Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _isUpdating ? null : () => _updateQuantity(item.id, item.quantity - 1),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: _isUpdating ? Colors.grey : AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isUpdating ? null : () => _updateQuantity(item.id, item.quantity + 1),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: _isUpdating ? Colors.grey : AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Item Subtotal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeItem(item.id),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Store-specific checkout method with validation
  void _checkoutStore(String farmerId, List<CartItemModel> items) async {
    // Validate items before checkout
    final validation = await _cartService.validateCart();
    final storeItems = items.map((i) => i.id).toSet();
    
    // Filter validation results for this specific store
    final unavailableInStore = (validation['unavailableItems'] as List<CartItemModel>)
        .where((item) => storeItems.contains(item.id))
        .toList();
    final outOfStockInStore = (validation['outOfStockItems'] as List<CartItemModel>)
        .where((item) => storeItems.contains(item.id))
        .toList();
    
    // Prevent checkout if there are issues
    if (unavailableInStore.isNotEmpty || outOfStockInStore.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text('Cannot Checkout'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Some items in your cart are unavailable or out of stock.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (unavailableInStore.isNotEmpty)
                  Text(
                    '• ${unavailableInStore.length} unavailable item${unavailableInStore.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                if (outOfStockInStore.isNotEmpty)
                  Text(
                    '• ${outOfStockInStore.length} out of stock item${outOfStockInStore.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 14),
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
                          'Please remove these items or adjust quantities before proceeding.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _removeUnavailableItems(validation);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove Unavailable'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // Navigate to checkout with specific store items
    if (mounted) {
      context.push(
        RouteNames.checkout,
        extra: {
          'farmerId': farmerId,
          'items': items,
          'storeInfo': _storeInfo[farmerId],
        },
      );
    }
  }
}

