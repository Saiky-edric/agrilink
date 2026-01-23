import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

/// Service for managing user's wishlist/favorites
class WishlistService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Check if a product is in the user's favorites
  Future<bool> isFavorite(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if product is favorite: $e');
      return false;
    }
  }

  /// Add a product to favorites
  Future<bool> addToFavorites(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _client.from('user_favorites').insert({
        'user_id': userId,
        'product_id': productId,
      });

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      // If error is due to duplicate, still return true (already favorited)
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return true;
      }
      rethrow;
    }
  }

  /// Remove a product from favorites
  Future<bool> removeFromFavorites(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Toggle favorite status (add if not favorite, remove if favorite)
  Future<bool> toggleFavorite(String productId) async {
    final isFav = await isFavorite(productId);
    
    if (isFav) {
      await removeFromFavorites(productId);
      return false; // Now not favorite
    } else {
      await addToFavorites(productId);
      return true; // Now favorite
    }
  }

  /// Get all favorited products for the current user
  Future<List<ProductModel>> getFavoriteProducts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get wishlist product IDs
      final wishlistData = await _client
          .from('user_favorites')
          .select('product_id')
          .eq('user_id', userId);

      if (wishlistData.isEmpty) {
        return [];
      }

      final productIds = wishlistData
          .map((item) => item['product_id'] as String)
          .toList();

      // Get product details
      final productsData = await _client
          .from('products')
          .select('''
            *,
            farmer:farmer_id (
              id,
              full_name,
              municipality,
              barangay
            )
          ''')
          .inFilter('id', productIds)
          .eq('is_hidden', false);

      return productsData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting favorite products: $e');
      rethrow;
    }
  }

  /// Get count of favorited products
  Future<int> getFavoritesCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .count();

      return response.count;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Clear all favorites for the current user
  Future<void> clearAllFavorites() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _client
          .from('user_favorites')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing favorites: $e');
      rethrow;
    }
  }
}
