import 'package:uuid/uuid.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class CartService {
  final SupabaseService _supabase = SupabaseService.instance;
  final AuthService _authService = AuthService();

  // Get cart items for current user with availability check
  Future<CartModel> getCart() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return const CartModel();
      }

      final response = await _supabase.cart
          .select('''
            *,
            product:product_id (
              id,
              farmer_id,
              name,
              price,
              stock,
              unit,
              shelf_life_days,
              category,
              description,
              cover_image_url,
              additional_image_urls,
              farm_name,
              farm_location,
              weight_per_unit,
              is_hidden,
              status,
              deleted_at,
              created_at,
              updated_at,
              farmer:farmer_id (
                id,
                full_name,
                store_name,
                store_description,
                store_banner_url,
                store_logo_url,
                municipality,
                barangay
              )
            )
          ''')
          .eq('user_id', currentUser.id);

      final items = response
          .map((json) => CartItemModel.fromJson(json))
          .toList();

      return CartModel.fromItems(items);
    } catch (e) {
      return const CartModel();
    }
  }

  // Check if cart items are available and valid
  Future<Map<String, dynamic>> validateCart() async {
    try {
      final cart = await getCart();
      final unavailableItems = <CartItemModel>[];
      final outOfStockItems = <CartItemModel>[];
      final availableItems = <CartItemModel>[];

      for (final item in cart.items) {
        if (item.product == null) {
          unavailableItems.add(item);
          continue;
        }

        final product = item.product!;
        
        // Check if product is deleted, hidden, or expired
        if (product.isDeleted || product.isHidden || product.isExpired) {
          unavailableItems.add(item);
        }
        // Check if product has insufficient stock
        else if (product.stock < item.quantity) {
          outOfStockItems.add(item);
        } else {
          availableItems.add(item);
        }
      }

      return {
        'isValid': unavailableItems.isEmpty && outOfStockItems.isEmpty,
        'availableItems': availableItems,
        'unavailableItems': unavailableItems,
        'outOfStockItems': outOfStockItems,
        'hasIssues': unavailableItems.isNotEmpty || outOfStockItems.isNotEmpty,
      };
    } catch (e) {
      return {
        'isValid': false,
        'availableItems': <CartItemModel>[],
        'unavailableItems': <CartItemModel>[],
        'outOfStockItems': <CartItemModel>[],
        'hasIssues': true,
        'error': e.toString(),
      };
    }
  }

  // Auto-remove unavailable items from cart
  Future<int> removeUnavailableItems() async {
    try {
      final validation = await validateCart();
      final unavailableItems = validation['unavailableItems'] as List<CartItemModel>;
      
      int removedCount = 0;
      for (final item in unavailableItems) {
        await removeFromCart(item.id);
        removedCount++;
      }
      
      return removedCount;
    } catch (e) {
      return 0;
    }
  }

  // Get cart items grouped by store
  Future<Map<String, List<CartItemModel>>> getCartByStore() async {
    try {
      final cart = await getCart();
      final Map<String, List<CartItemModel>> groupedCart = {};

      for (final item in cart.availableItems) {
        if (item.product != null) {
          final farmerId = item.product!.farmerId;
          // Use putIfAbsent for safer map operations
          groupedCart.putIfAbsent(farmerId, () => []).add(item);
        }
      }

      return groupedCart;
    } catch (e) {
      return {};
    }
  }

  // Get store information for a farmer
  Future<Map<String, dynamic>?> getStoreInfo(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('users')
          .select('id, full_name, store_name, store_description, store_banner_url, store_logo_url, municipality, barangay')
          .eq('id', farmerId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Add item to cart
  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if item already exists in cart
      final existingItem = await _supabase.cart
          .select()
          .eq('user_id', currentUser.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        // Update quantity
        await _supabase.cart
            .update({
              'quantity': existingItem['quantity'] + quantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      } else {
        // Add new item
        const uuid = Uuid();
        await _supabase.cart.insert({
          'id': uuid.v4(),
          'user_id': currentUser.id,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update cart item quantity
  Future<void> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      await _supabase.cart
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cartItemId);
    } catch (e) {
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _supabase.cart.delete().eq('id', cartItemId);
    } catch (e) {
      rethrow;
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.cart.delete().eq('user_id', currentUser.id);
    } catch (e) {
      rethrow;
    }
  }

  // Remove specific cart items (used after successful order)
  Future<void> removeCartItems(List<CartItemModel> itemsToRemove) async {
    try {
      final itemIds = itemsToRemove.map((item) => item.id).toList();
      
      for (final itemId in itemIds) {
        await _supabase.cart.delete().eq('id', itemId);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase.cart
          .select('quantity')
          .eq('user_id', currentUser.id);

      return response.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      return 0;
    }
  }

  // Check product availability before checkout
  Future<bool> validateCartItems(List<CartItemModel> items) async {
    try {
      for (final item in items) {
        final product = await _supabase.products
            .select()
            .eq('id', item.productId)
            .single();

        final productModel = ProductModel.fromJson(product);
        
        // Check if product is still available and in stock
        if (productModel.isHidden || 
            productModel.isExpired || 
            productModel.stock < item.quantity) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}