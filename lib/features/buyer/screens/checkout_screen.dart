import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/address_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/cart_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/modern_checkout_widgets.dart';
import '../../../shared/widgets/delivery_method_selector.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final String? farmerId;
  final List<CartItemModel>? items;
  final Map<String, dynamic>? storeInfo;

  const CheckoutScreen({
    super.key,
    this.farmerId,
    this.items,
    this.storeInfo,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final AddressService _addressService = AddressService();
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  CartModel _cart = const CartModel();
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  String _paymentMethod = 'cod';
  String _deliveryMethod = 'delivery'; // NEW: 'delivery' or 'pickup'
  Map<String, dynamic>? _farmerPickupInfo; // NEW: Farmer's pickup settings
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  Map<String, UserModel> _farmerProfiles = {};
  String _specialInstructions = '';
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadCartItems(),
        _loadAddresses(),
      ]);
      // Load configurable per-2kg step from platform settings
      try {
        final step = await OrderService.jtPer2kgStep();
        if (mounted) setState(() => _jtPer2kgStep = step);
      } catch (_) {}
      await _loadFarmerProfiles();
      await _loadFarmerPickupInfo(); // NEW: Load pickup settings
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading checkout data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCartItems() async {
    try {
      if (widget.farmerId != null && widget.items != null) {
        // Use specific farmer's items passed from cart
        setState(() {
          _cart = CartModel.fromItems(widget.items!);
        });
      } else {
        // Load all cart items (fallback for direct navigation)
        final cart = await _cartService.getCart();
        setState(() {
          _cart = cart;
        });
      }
    } catch (e) {
      throw Exception('Failed to load cart items: $e');
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;
      
      final addresses = await _addressService.getUserAddresses(currentUser.id);
      setState(() {
        _addresses = addresses;
        _selectedAddress = addresses.isNotEmpty 
            ? addresses.firstWhere(
                (address) => address.isDefault,
                orElse: () => addresses.first,
              )
            : null;
      });
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  Future<void> _loadFarmerProfiles() async {
    try {
      final profiles = <String, UserModel>{};
      
      if (widget.farmerId != null && widget.storeInfo != null) {
        // Use store info passed from cart for single farmer checkout
        final farmerId = widget.farmerId!;
        final storeInfo = widget.storeInfo!;
        
        final profile = UserModel(
          id: storeInfo['id'] ?? farmerId,
          email: '',
          fullName: storeInfo['full_name'] ?? storeInfo['store_name'] ?? 'Unknown Farmer',
          phoneNumber: '',
          role: UserRole.farmer,
          municipality: storeInfo['municipality'],
          barangay: storeInfo['barangay'],
          createdAt: DateTime.now(),
        );
        profiles[farmerId] = profile;
      } else {
        // Load profiles for all farmers in cart (fallback)
        final farmerIds = _cart.itemsByFarmer.keys.toList();
        
        for (final farmerId in farmerIds) {
          try {
            // Get farmer profile from cart service store info
            final storeInfo = await _cartService.getStoreInfo(farmerId);
            if (storeInfo != null) {
              // Create a simplified UserModel from store info
              final profile = UserModel(
                id: storeInfo['id'],
                email: '',
                fullName: storeInfo['full_name'] ?? 'Unknown Farmer',
                phoneNumber: '',
                role: UserRole.farmer,
                municipality: storeInfo['municipality'],
                barangay: storeInfo['barangay'],
                createdAt: DateTime.now(),
              );
              profiles[farmerId] = profile;
            }
          } catch (e) {
            // Continue loading other profiles even if one fails
            debugPrint('Failed to load farmer profile for $farmerId: $e');
          }
        }
      }
      
      setState(() {
        _farmerProfiles = profiles;
      });
    } catch (e) {
      // Non-critical error, just log it
      debugPrint('Error loading farmer profiles: $e');
    }
  }

  Future<void> _loadFarmerPickupInfo() async {
    try {
      // Only load pickup info if single farmer checkout
      if (widget.farmerId != null) {
        final farmerId = widget.farmerId!;
        
        // Query farmer's pickup settings from users table
        final response = await SupabaseService.instance.client
            .from('users')
            .select('pickup_enabled, pickup_addresses, pickup_instructions, pickup_hours')
            .eq('id', farmerId)
            .maybeSingle();
        
        if (response != null && mounted) {
          setState(() {
            _farmerPickupInfo = response;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading farmer pickup info: $e');
      // Non-critical error, just log it
    }
  }

  double get _subtotal => _cart.total;
  double _jtPer2kgStep = 25.0;
  
  String? _getFormattedPickupAddress() {
    if (_farmerPickupInfo == null) return null;
    
    final addresses = _farmerPickupInfo!['pickup_addresses'];
    if (addresses == null || addresses is! List || addresses.isEmpty) {
      return null;
    }
    
    // Get the first (default) address
    final defaultAddress = addresses[0] as Map<String, dynamic>;
    final municipality = defaultAddress['municipality'] ?? '';
    final barangay = defaultAddress['barangay'] ?? '';
    final street = defaultAddress['street_address'] ?? '';
    
    // Format: "Street, Barangay, Municipality"
    return '$street, $barangay, $municipality';
  }

  // Calculate the actual delivery fee based on weight (always calculated)
  double get _calculatedDeliveryFee {
    // J&T Express incremental policy (single parcel)
    // Base tiers: <=3kg: ₱70, <=5kg: ₱120, <=8kg: ₱160
    // Above 8kg: add per 2kg step (configurable, default ₱25)
    // Group ALL cart items by farmer to ensure fee matches subtotal, even if some items are marked unavailable in UI
    final Map<String, List<CartItemModel>> itemsByFarmer = {};
    for (final it in _cart.items) {
      final fid = it.product?.farmerId ?? 'unknown';
      itemsByFarmer.putIfAbsent(fid, () => []).add(it);
    }
    double totalFee = 0.0;

    // Compute per store group (cart is grouped per farmer)
    itemsByFarmer.forEach((farmerId, items) {
      // Sum total kg for this store
      double totalKg = 0.0;
      for (final it in items) {
        final p = it.product;
        double unitKg = 0.0;
        if (p != null) {
          try {
            final m = p.toJson();
            unitKg = (m['weight_per_unit'] as num?)?.toDouble() ?? 0.0;
            if (unitKg == 0.0) {
              // Fallback: derive from unit label if missing
              final u = (p.unit).toLowerCase();
              final name = p.name.toLowerCase();
              if (u == 'kg' || u == 'kilo' || u == 'kilogram') {
                unitKg = 1.0;
              } else {
                final kgMatch = RegExp(r'([0-9]+\.?[0-9]*)\s*kg').firstMatch(u);
                if (kgMatch != null) {
                  unitKg = double.tryParse(kgMatch.group(1)!) ?? 0.0;
                } else if (u.contains('sack') || u.contains('bag')) {
                  // Heuristic for sacks/bags (common for rice). Default 25kg if unspecified.
                  final sackMatch = RegExp(r'([0-9]+)\s*kg').firstMatch(u);
                  unitKg = sackMatch != null ? double.tryParse(sackMatch.group(1)!) ?? 25.0 : 25.0;
                }
              }
            }
            // TEMP DEBUG: log product weight contribution
            // ignore: avoid_print
            print('[Checkout] ${p.name} x${it.quantity} unitKg=$unitKg -> add ${(unitKg * it.quantity).toStringAsFixed(2)} kg');
          } catch (e) {
            // ignore: avoid_print
            print('[Checkout] weight read failed for ${p.name}: $e');
            unitKg = 0.0;
          }
        }
        totalKg += unitKg * it.quantity;
      }
      // TEMP DEBUG: log per-store total and fee
      final feeForStore = OrderService.jtFeeForKgWithStep(totalKg, _jtPer2kgStep);
      // ignore: avoid_print
      print('[Checkout] Store $farmerId totalKg=${totalKg.toStringAsFixed(2)} -> fee=$feeForStore');
      totalFee += feeForStore;
      return;

    });

    return totalFee;
  }
  // Delivery fee for total calculation (0 if pickup)
  double get _deliveryFee {
    return _deliveryMethod == 'pickup' ? 0.0 : _calculatedDeliveryFee;
  }
  
  double get _total => _subtotal + _deliveryFee;

  Future<void> _placeOrder() async {
    // Only require address for delivery orders
    if (_deliveryMethod == 'delivery' && _selectedAddress == null) {
      _showErrorSnackBar('Please select a delivery address');
      return;
    }

    if (_cart.isEmpty) {
      _showErrorSnackBar('Your cart is empty');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create orders for each farmer (store-based grouping)
      final itemsByFarmer = _cart.itemsByFarmer;
      final List<String> orderIds = [];
      final List<CartItemModel> orderedItems = [];

      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final items = entry.value;
        
        try {
          // Create real order using OrderService
          final orderId = await _orderService.createOrder(
            buyerId: currentUser.id,
            farmerId: farmerId,
            items: items,
            deliveryAddress: _deliveryMethod == 'delivery' 
                ? _selectedAddress!.fullAddress 
                : (_farmerPickupInfo?['pickup_address'] ?? 'Pickup Location'),
            paymentMethod: _paymentMethod,
            specialInstructions: _specialInstructions.isNotEmpty ? _specialInstructions : null,
            deliveryMethod: _deliveryMethod, // NEW
            pickupAddress: _deliveryMethod == 'pickup' ? _getFormattedPickupAddress() : null, // NEW
            pickupInstructions: _deliveryMethod == 'pickup' ? (_farmerPickupInfo?['pickup_instructions'] as String?) : null, // NEW
          );
          
          orderIds.add(orderId);
          orderedItems.addAll(items);
        } catch (e) {
          throw Exception('Failed to create order for farmer $farmerId: $e');
        }
      }

      // Remove only the ordered items from cart (not all items)
      await _cartService.removeCartItems(orderedItems);

      if (mounted) {
        if (_paymentMethod == 'gcash') {
          // Handle GCash payment - temporarily disabled until service is properly implemented
          _showSuccessAndNavigate('Order placed successfully! GCash payment will be available soon.');
        } else if (_deliveryMethod == 'pickup') {
          // Cash on Pickup - show success
          _showSuccessAndNavigate('Order placed successfully! You will pay when you pick up your order.');
        } else {
          // Cash on Delivery - show success
          _showSuccessAndNavigate('Order placed successfully! You will pay upon delivery.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error placing order: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _showSuccessAndNavigate(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent tapping outside to close (force user to choose action)
      builder: (context) => PopScope(
        canPop: false, // Prevent back button from closing (force user to choose action)
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.surfaceGreen.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon with gradient background
                    Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentGreen,
                        AppTheme.primaryGreen,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGreen.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success Title
                Text(
                  'Order Placed!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Order Number (if available)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Order Confirmed',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Success Message
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go(RouteNames.buyerHome);
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Shop More'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToOrders();
                        },
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('My Orders'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tip/Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Track your order status in the Orders section',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
              // Close button - positioned in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: Colors.grey.shade700),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      context.go(RouteNames.buyerHome); // Navigate away from checkout
                    },
                    tooltip: 'Close',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _navigateToOrders() {
    // Navigate to buyer orders screen
    context.go(RouteNames.buyerOrders);
  }

  void _navigateToAddressSelection() async {
    final result = await context.push<AddressModel>(
      '/buyer/address-selection',
      extra: _selectedAddress,
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  void _navigateToStore(String farmerId) {
    context.push('${RouteNames.publicFarmerProfile}/$farmerId');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: LoadingWidgets.fullScreenLoader(message: 'Loading checkout data...'),
      );
    }

    if (_cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: _buildEmptyCart(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.farmerId != null ? 'Store Checkout' : 'Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cart.totalItems} item${_cart.totalItems == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  DeliveryAddressCard(
                    selectedAddress: _selectedAddress,
                    onTap: _navigateToAddressSelection,
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery Method Section (NEW)
                  DeliveryMethodSelector(
                    selectedMethod: _deliveryMethod,
                    deliveryFee: _calculatedDeliveryFee, // Always show actual fee
                    pickupInfo: _farmerPickupInfo,
                    onMethodChanged: (method) {
                      setState(() {
                        _deliveryMethod = method;
                        // Update payment method label
                        if (method == 'pickup') {
                          _paymentMethod = 'cop'; // Cash on Pickup
                        } else {
                          _paymentMethod = 'cod'; // Cash on Delivery
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Store Groups Section
                  ..._buildStoreGroups(),
                  const SizedBox(height: 16),
                  
                  // Payment Method Section
                  PaymentMethodCard(
                    selectedMethod: _paymentMethod,
                    deliveryMethod: _deliveryMethod, // Pass delivery method
                    onMethodChanged: (method) {
                      setState(() => _paymentMethod = method);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Special Instructions Section
                  Card(
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
                                  color: AppTheme.surfaceWarm,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.note_add,
                                  color: AppTheme.accentOrange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Special Instructions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _instructionsController,
                            onChanged: (value) => _specialInstructions = value,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any special delivery instructions for the farmer (optional)',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppTheme.accentGreen, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Order Summary Section
                  OrderSummaryCard(
                    subtotal: _subtotal,
                    deliveryFee: _deliveryFee,
                    total: _total,
                    totalItems: _cart.totalItems,
                  ),
                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
          
          // Floating Checkout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ModernCheckoutButton(
                isLoading: _isPlacingOrder,
                isEnabled: _selectedAddress != null && _cart.isNotEmpty,
                onPressed: _placeOrder,
                text: 'Place Order • ₱${_total.toStringAsFixed(2)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStoreGroups() {
    final itemsByFarmer = _cart.itemsByFarmer;
    
    return itemsByFarmer.entries.map((entry) {
      final farmerId = entry.key;
      final items = entry.value;
      final farmerProfile = _farmerProfiles[farmerId];
      
      return Column(
        children: [
          StoreGroupCard(
            farmerId: farmerId,
            farmerName: farmerProfile?.fullName ?? 'Unknown Farmer',
            farmerImage: null, // Profile images will be added later when the feature is implemented
            items: items,
            onViewStore: () => _navigateToStore(farmerId),
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some fresh products to continue',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreenDark,
                ],
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.buyerHome),
              icon: const Icon(Icons.agriculture, color: Colors.white),
              label: const Text(
                'Explore Products',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}