import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

class ProductService {
  static const String _cancelled = 'cancelled';
  final SupabaseService _supabase = SupabaseService.instance;
  final StorageService _storageService = StorageService.instance;

  // Aggregate committed quantities for a set of product IDs (non-cancelled orders)
  Future<Map<String, int>> _getCommittedQuantities(Set<String> productIds) async {
    if (productIds.isEmpty) return {};
    final rows = await _supabase.client
        .from('order_items')
        .select('product_id, quantity, orders!inner(buyer_status, farmer_status)')
        .inFilter('product_id', productIds.toList());

    final Map<String, int> committed = {};
    for (final r in rows) {
      final orders = r['orders'] as Map<String, dynamic>?;
      final buyerStatus = orders != null ? (orders['buyer_status'] as String? ?? '') : '';
      final farmerStatus = orders != null ? (orders['farmer_status'] as String? ?? '') : '';
      final isCancelled = buyerStatus == _cancelled || farmerStatus == _cancelled;
      final isCompleted = buyerStatus == 'completed' || farmerStatus == 'completed';
      // Count only active pipeline orders (not cancelled, not completed)
      if (!isCancelled && !isCompleted) {
        final pid = r['product_id'] as String;
        final qty = r['quantity'] as int? ?? 0;
        committed[pid] = (committed[pid] ?? 0) + qty;
      }
    }
    return committed;
  }

  List<ProductModel> _applyRemainingStock(List<ProductModel> products, Map<String, int> committed) {
    return products.map((p) {
      final used = committed[p.id] ?? 0;
      final remaining = p.stock - used;
      return p.copyWith(stock: remaining < 0 ? 0 : remaining);
    }).toList();
  }

  // Add new product
  Future<ProductModel> addProduct({
    required String farmerId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String unit,
    required String category,
    required List<File> images,
    String? storeLocation,
    int? shelfLifeDays,
    String? weightPerUnitKgString,
  }) async {
    try {
      // Generate proper UUID for product ID
      const uuid = Uuid();
      final productId = uuid.v4();

      // Upload product images
      final imageUrls = await _storageService.uploadProductImages(
        farmerId: farmerId,
        productId: productId,
        images: images,
      );

      // Create product record
      final productData = {
        'id': productId,
        'farmer_id': farmerId,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'unit': unit,
        'shelf_life_days': shelfLifeDays ?? 7,
        'category': category,
        'cover_image_url': imageUrls.isNotEmpty ? imageUrls[0] : '',
        'additional_image_urls': imageUrls.length > 1 ? imageUrls.sublist(1) : [],
        'farm_name': 'Farm', // Default value
        'farm_location': storeLocation ?? 'Location', // Use provided store location
        'is_hidden': false,
        'weight_per_unit': double.tryParse(weightPerUnitKgString ?? '') ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('products')
          .insert(productData)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get products by farmer (applies remaining stock)
  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return response.map((item) => ProductModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get farmer products: $e');
    }
  }

  // Get all available products (for buyers) with remaining stock applied
  Future<List<ProductModel>> getAvailableProducts({
    String? category,
    String? searchQuery,
    bool organicOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Build the query with proper chaining
      var query = _supabase.client
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
          .eq('is_hidden', false)
          .gt('stock', 0);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Map<String, dynamic>> productData = List<Map<String, dynamic>>.from(response);
      final ids = productData.map((p) => p['id'] as String).toSet();
      
      // Fetch all reviews in batch
      final allReviews = await _supabase.client
          .from('product_reviews')
          .select('product_id, rating')
          .inFilter('product_id', ids.toList());
      
      debugPrint('📊 Fetched ${allReviews.length} reviews for ${ids.length} products');
      debugPrint('📊 Product IDs queried: $ids');
      if (allReviews.isNotEmpty) {
        debugPrint('📊 Sample review data: ${allReviews.first}');
      }
      
      // Fetch all completed order items in batch
      final allOrderItems = await _supabase.client
          .from('order_items')
          .select('product_id, quantity, orders!inner(farmer_status)')
          .inFilter('product_id', ids.toList());
      
      debugPrint('📦 Fetched ${allOrderItems.length} order items for sold count');
      
      // Group reviews by product
      final reviewsByProduct = <String, List<Map<String, dynamic>>>{};
      for (final review in allReviews) {
        final productId = review['product_id'] as String;
        reviewsByProduct.putIfAbsent(productId, () => []).add(review);
      }
      
      debugPrint('📊 Reviews grouped by product: ${reviewsByProduct.length} products have reviews');
      
      // Group sold items by product
      final soldByProduct = <String, int>{};
      for (final item in allOrderItems) {
        final productId = item['product_id'] as String;
        final orders = item['orders'] as Map<String, dynamic>?;
        final farmerStatus = orders?['farmer_status'] as String? ?? '';
        if (farmerStatus == 'completed') {
          final qty = item['quantity'] as int? ?? 0;
          soldByProduct[productId] = (soldByProduct[productId] ?? 0) + qty;
        }
      }
      
      // Add statistics to each product
      for (final data in productData) {
        final productId = data['id'] as String;
        final reviews = reviewsByProduct[productId] ?? [];
        
        double avgRating = 0.0;
        if (reviews.isNotEmpty) {
          int totalRating = 0;
          debugPrint('📊 Processing ${reviews.length} reviews for product $productId');
          for (final review in reviews) {
            // Handle rating as both int and string
            final rating = review['rating'];
            debugPrint('  - Rating value: $rating, Type: ${rating.runtimeType}');
            if (rating is int) {
              totalRating += rating;
              debugPrint('  - Added as int: $rating');
            } else if (rating is String) {
              final parsed = int.tryParse(rating) ?? 0;
              totalRating += parsed;
              debugPrint('  - Parsed string "$rating" as: $parsed');
            } else {
              debugPrint('  - WARNING: Unknown rating type: ${rating.runtimeType}');
            }
          }
          avgRating = totalRating / reviews.length;
          debugPrint('  ✅ Final: Total=$totalRating, Avg=$avgRating');
        }
        
        data['average_rating'] = avgRating;
        data['total_reviews'] = reviews.length;
        data['total_sold'] = soldByProduct[productId] ?? 0;
        
        if (reviews.isNotEmpty || soldByProduct[productId] != null) {
          debugPrint('✅ Product $productId: Rating=$avgRating, Reviews=${reviews.length}, Sold=${soldByProduct[productId] ?? 0}');
        }
      }
      
      final products = productData.map((item) => ProductModel.fromJson(item)).toList();
      final committed = await _getCommittedQuantities(ids);
      return _applyRemainingStock(products, committed);
    } catch (e) {
      throw Exception('Failed to get available products: $e');
    }
  }

  // Get product by ID including computed remaining stock, ratings, and sold count
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _supabase.client
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
          .eq('id', productId)
          .maybeSingle();

      if (response == null) return null;

      // Compute remaining stock = product.stock - sum(order_items.quantity) for active orders
      final aggregate = await _supabase.client
          .from('order_items')
          .select('quantity, orders!inner(buyer_status, farmer_status)')
          .eq('product_id', productId);

      int committed = 0;
      int totalSold = 0;
      for (final item in aggregate) {
        final orders = item['orders'] as Map<String, dynamic>?;
        final buyerStatus = orders != null ? (orders['buyer_status'] as String? ?? '') : '';
        final farmerStatus = orders != null ? (orders['farmer_status'] as String? ?? '') : '';
        final isCancelled = buyerStatus == _cancelled || farmerStatus == _cancelled;
        final isCompleted = buyerStatus == 'completed' || farmerStatus == 'completed';
        
        final quantity = (item['quantity'] as int? ?? 0);
        
        // Count completed orders as sold
        if (isCompleted) {
          totalSold += quantity;
        }
        
        // Count only active pipeline orders (not cancelled, not completed)
        if (!isCancelled && !isCompleted) {
          committed += quantity;
        }
      }

      // Get product reviews with user information and calculate average rating
      final reviews = await _supabase.client
          .from('product_reviews')
          .select('''
            id,
            user_id,
            rating,
            review_text,
            image_urls,
            created_at,
            user:user_id (
              full_name,
              avatar_url
            )
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      double averageRating = 0.0;
      int totalReviews = reviews.length;
      
      if (totalReviews > 0) {
        int totalRating = 0;
        for (final review in reviews) {
          // Handle rating as both int and string
          final rating = review['rating'];
          if (rating is int) {
            totalRating += rating;
          } else if (rating is String) {
            totalRating += int.tryParse(rating) ?? 0;
          }
        }
        averageRating = totalRating / totalReviews;
      }

      // Get recent reviews with text (limit to 5 most recent)
      final recentReviews = reviews
          .where((r) => r['review_text'] != null && (r['review_text'] as String).isNotEmpty)
          .take(5)
          .toList();

      int remaining = (response['stock'] as int) - committed;
      if (remaining < 0) remaining = 0;
      
      // Add computed fields to response
      response['average_rating'] = averageRating;
      response['total_reviews'] = totalReviews;
      response['total_sold'] = totalSold;
      response['recent_reviews'] = recentReviews;
      
      final product = ProductModel.fromJson(response);
      return product.copyWith(stock: remaining);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Update product
  Future<ProductModel> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? unit,
    String? category,
    List<File>? newImages,
    List<String>? existingImageUrls,
    DateTime? expiryDate,
    bool? isOrganic,
    bool? isHidden,
    double? weightPerUnitKg,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (stock != null) updateData['stock'] = stock;
      if (unit != null) updateData['unit'] = unit;
      if (category != null) updateData['category'] = category;
      if (expiryDate != null) updateData['expiry_date'] = expiryDate.toIso8601String();
      if (isOrganic != null) updateData['is_organic'] = isOrganic;
      if (isHidden != null) updateData['is_hidden'] = isHidden;
      if (weightPerUnitKg != null) updateData['weight_per_unit'] = weightPerUnitKg;

      // Handle image updates
      if (newImages != null && newImages.isNotEmpty) {
        // Get current product to get farmer ID
        final currentProduct = await getProductById(productId);
        if (currentProduct == null) {
          throw Exception('Product not found');
        }

        // Upload new images
        final newImageUrls = await _storageService.uploadProductImages(
          farmerId: currentProduct.farmerId,
          productId: productId,
          images: newImages,
        );

        // Combine existing and new image URLs
        final allImageUrls = [
          ...(existingImageUrls ?? []),
          ...newImageUrls,
        ];

        updateData['image_urls'] = allImageUrls;
      } else if (existingImageUrls != null) {
        updateData['image_urls'] = existingImageUrls;
      }

      final response = await _supabase.client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      // Use soft delete to avoid foreign key constraint issues
      await _supabase.client.rpc('soft_delete_product', params: {
        'product_id_param': productId,
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
  
  // Restore deleted product
  Future<void> restoreProduct(String productId) async {
    try {
      await _supabase.client.rpc('restore_product', params: {
        'product_id_param': productId,
      });
    } catch (e) {
      throw Exception('Failed to restore product: $e');
    }
  }

  // Hide/unhide product
  Future<ProductModel> toggleProductVisibility(String productId) async {
    try {
      final currentProduct = await getProductById(productId);
      if (currentProduct == null) {
        throw Exception('Product not found');
      }

      return await updateProduct(
        productId: productId,
        isHidden: !currentProduct.isHidden,
      );
    } catch (e) {
      throw Exception('Failed to toggle product visibility: $e');
    }
  }

  // Update stock
  Future<ProductModel> updateStock({
    required String productId,
    required int newStock,
  }) async {
    try {
      return await updateProduct(
        productId: productId,
        stock: newStock,
      );
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Get products by category (remaining stock applied) - Premium sellers prioritized
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select('''
            *,
            farmer:farmer_id (
              id,
              full_name,
              municipality,
              barangay,
              subscription_tier,
              subscription_expires_at
            )
          ''')
          .eq('category', category)
          .eq('is_hidden', false)
          .gt('stock', 0)
          .order('created_at', ascending: false);

      final products = response.map((item) => ProductModel.fromJson(item)).toList();
      
      // Sort products: Premium sellers first, then by creation date
      products.sort((a, b) {
        final aData = response.firstWhere((r) => r['id'] == a.id);
        final bData = response.firstWhere((r) => r['id'] == b.id);
        
        final aFarmer = aData['farmer'] as Map<String, dynamic>?;
        final bFarmer = bData['farmer'] as Map<String, dynamic>?;
        
        final aTier = aFarmer?['subscription_tier'] as String? ?? 'free';
        final bTier = bFarmer?['subscription_tier'] as String? ?? 'free';
        
        final aExpires = aFarmer?['subscription_expires_at'] as String?;
        final bExpires = bFarmer?['subscription_expires_at'] as String?;
        
        // Check if subscriptions are active
        final aIsPremium = aTier == 'premium' && 
            (aExpires == null || DateTime.parse(aExpires).isAfter(DateTime.now()));
        final bIsPremium = bTier == 'premium' && 
            (bExpires == null || DateTime.parse(bExpires).isAfter(DateTime.now()));
        
        // Premium products come first
        if (aIsPremium && !bIsPremium) return -1;
        if (!aIsPremium && bIsPremium) return 1;
        
        // If both same tier, sort by date
        return b.createdAt.compareTo(a.createdAt);
      });
      
      final ids = products.map((p) => p.id).toSet();
      final committed = await _getCommittedQuantities(ids);
      return _applyRemainingStock(products, committed);
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  // Search products (remaining stock applied) - Premium sellers prioritized
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select('''
            *,
            farmer:farmer_id (
              id,
              full_name,
              municipality,
              barangay,
              subscription_tier,
              subscription_expires_at
            )
          ''')
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .eq('is_hidden', false)
          .gt('stock', 0)
          .order('created_at', ascending: false);

      final products = response.map((item) => ProductModel.fromJson(item)).toList();
      
      // Sort products: Premium sellers first, then by relevance/date
      products.sort((a, b) {
        final aData = response.firstWhere((r) => r['id'] == a.id);
        final bData = response.firstWhere((r) => r['id'] == b.id);
        
        final aFarmer = aData['farmer'] as Map<String, dynamic>?;
        final bFarmer = bData['farmer'] as Map<String, dynamic>?;
        
        final aTier = aFarmer?['subscription_tier'] as String? ?? 'free';
        final bTier = bFarmer?['subscription_tier'] as String? ?? 'free';
        
        final aExpires = aFarmer?['subscription_expires_at'] as String?;
        final bExpires = bFarmer?['subscription_expires_at'] as String?;
        
        // Check if subscriptions are active
        final aIsPremium = aTier == 'premium' && 
            (aExpires == null || DateTime.parse(aExpires).isAfter(DateTime.now()));
        final bIsPremium = bTier == 'premium' && 
            (bExpires == null || DateTime.parse(bExpires).isAfter(DateTime.now()));
        
        // Premium products come first
        if (aIsPremium && !bIsPremium) return -1;
        if (!aIsPremium && bIsPremium) return 1;
        
        // If both same tier, sort by date
        return b.createdAt.compareTo(a.createdAt);
      });
      
      final ids = products.map((p) => p.id).toSet();
      final committed = await _getCommittedQuantities(ids);
      return _applyRemainingStock(products, committed);
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get product statistics for farmer
  Future<Map<String, dynamic>> getFarmerProductStats(String farmerId) async {
    try {
      final products = await getProductsByFarmer(farmerId);

      final totalProducts = products.length;
      final activeProducts = products.where((p) => !p.isHidden && p.stock > 0).length;
      final outOfStock = products.where((p) => p.stock == 0).length;
      final hiddenProducts = products.where((p) => p.isHidden).length;
      final organicProducts = products.where((p) => p.category.name == 'organic').length;

      // Simplified revenue calculation
      final totalRevenue = products
          .where((p) => !p.isHidden)
          .fold(0.0, (sum, product) => sum + product.price);

      return {
        'totalProducts': totalProducts,
        'activeProducts': activeProducts,
        'outOfStock': outOfStock,
        'hiddenProducts': hiddenProducts,
        'organicProducts': organicProducts,
        'estimatedRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get product stats: $e');
    }
  }

  // Get low stock products
  Future<List<ProductModel>> getLowStockProducts(String farmerId, {int threshold = 5}) async {
    try {
      final products = await getProductsByFarmer(farmerId);
      return products
          .where((p) => !p.isHidden && p.stock > 0 && p.stock <= threshold)
          .toList();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // Get expired products (from database function)
  Future<List<Map<String, dynamic>>> getExpiredProducts(String farmerId) async {
    try {
      final response = await _supabase.client.rpc('get_expired_products');
      
      // Filter by farmer
      final farmerExpired = (response as List)
          .where((item) => item['farmer_id'] == farmerId)
          .toList();
      
      return farmerExpired.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get expired products: $e');
    }
  }

  // Get products expiring soon (from database function)
  Future<List<Map<String, dynamic>>> getExpiringProducts(String farmerId, {int daysThreshold = 3}) async {
    try {
      final response = await _supabase.client.rpc('get_expiring_products', params: {
        'days_threshold': daysThreshold,
      });
      
      // Filter by farmer
      final farmerExpiring = (response as List)
          .where((item) => item['farmer_id'] == farmerId)
          .toList();
      
      return farmerExpiring.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get expiring products: $e');
    }
  }
  
  // Get deleted products for farmer
  Future<List<ProductModel>> getDeletedProducts(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .eq('status', 'deleted')
          .order('deleted_at', ascending: false);

      return response.map((item) => ProductModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get deleted products: $e');
    }
  }
  
  // Get hidden products for farmer
  Future<List<ProductModel>> getHiddenProducts(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .eq('is_hidden', true)
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);

      return response.map((item) => ProductModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get hidden products: $e');
    }
  }
  
  // Get available (visible, active, not expired) products for farmer
  Future<List<ProductModel>> getAvailableProductsForFarmer(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false)
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return response.map((item) => ProductModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get available products: $e');
    }
  }
  
  // Manually trigger expiry check
  Future<void> checkAndHideExpiredProducts() async {
    try {
      await _supabase.client.rpc('auto_hide_expired_products');
    } catch (e) {
      throw Exception('Failed to check expired products: $e');
    }
  }

  // Get daily random featured products (up to 10, or all available if less)
  Future<List<ProductModel>> getDailyFeaturedProducts({int maxCount = 10}) async {
    try {
      // Get today's date as seed for consistent daily randomization
      final today = DateTime.now();
      final daysSinceEpoch = today.difference(DateTime(1970, 1, 1)).inDays;
      
      // Query all available products
      var query = _supabase.client
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
          .eq('is_hidden', false)
          .gt('stock', 0);

      final response = await query.order('created_at', ascending: false);

      final List<Map<String, dynamic>> productData = List<Map<String, dynamic>>.from(response);
      
      if (productData.isEmpty) {
        return [];
      }
      
      final ids = productData.map((p) => p['id'] as String).toSet();
      
      // Fetch all reviews in batch
      final allReviews = await _supabase.client
          .from('product_reviews')
          .select('product_id, rating')
          .inFilter('product_id', ids.toList());
      
      // Fetch all completed order items in batch
      final allOrderItems = await _supabase.client
          .from('order_items')
          .select('product_id, quantity, orders!inner(farmer_status)')
          .inFilter('product_id', ids.toList());
      
      // Group reviews by product
      final reviewsByProduct = <String, List<Map<String, dynamic>>>{};
      for (final review in allReviews) {
        final productId = review['product_id'] as String;
        reviewsByProduct.putIfAbsent(productId, () => []).add(review);
      }
      
      // Group sold items by product
      final soldByProduct = <String, int>{};
      for (final item in allOrderItems) {
        final productId = item['product_id'] as String;
        final orders = item['orders'] as Map<String, dynamic>?;
        final farmerStatus = orders?['farmer_status'] as String? ?? '';
        if (farmerStatus == 'completed') {
          final qty = item['quantity'] as int? ?? 0;
          soldByProduct[productId] = (soldByProduct[productId] ?? 0) + qty;
        }
      }
      
      // Add statistics to each product
      for (final data in productData) {
        final productId = data['id'] as String;
        final reviews = reviewsByProduct[productId] ?? [];
        
        double avgRating = 0.0;
        if (reviews.isNotEmpty) {
          int totalRating = 0;
          for (final review in reviews) {
            final rating = review['rating'];
            if (rating is int) {
              totalRating += rating;
            } else if (rating is String) {
              totalRating += int.tryParse(rating) ?? 0;
            }
          }
          avgRating = totalRating / reviews.length;
        }
        
        data['average_rating'] = avgRating;
        data['total_reviews'] = reviews.length;
        data['total_sold'] = soldByProduct[productId] ?? 0;
      }
      
      // Convert to ProductModel list
      final allProducts = productData.map((item) => ProductModel.fromJson(item)).toList();
      
      // Apply remaining stock calculation
      final committed = await _getCommittedQuantities(ids);
      final productsWithStock = _applyRemainingStock(allProducts, committed);
      
      // Filter out products with no remaining stock
      final availableProducts = productsWithStock.where((p) => p.stock > 0).toList();
      
      // Use deterministic random selection based on day
      // This ensures the same products are featured throughout the day
      final random = _SeededRandom(daysSinceEpoch);
      final shuffled = List<ProductModel>.from(availableProducts);
      
      // Fisher-Yates shuffle with seeded random
      for (int i = shuffled.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = shuffled[i];
        shuffled[i] = shuffled[j];
        shuffled[j] = temp;
      }
      
      // Return up to maxCount products, or all if less than maxCount available
      final featuredCount = shuffled.length < maxCount ? shuffled.length : maxCount;
      return shuffled.take(featuredCount).toList();
      
    } catch (e) {
      debugPrint('❌ Failed to get daily featured products: $e');
      throw Exception('Failed to get daily featured products: $e');
    }
  }

  // Get product count for a specific farmer (for subscription limits)
  Future<int> getProductCount(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('products')
          .select('id')
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false);
      
      return response.length;
    } catch (e) {
      debugPrint('Error getting product count: $e');
      return 0;
    }
  }
}

// Simple seeded random number generator for consistent daily rotation
class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  int nextInt(int max) {
    // Linear congruential generator
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed % max;
  }
}