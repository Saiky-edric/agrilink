import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing store customization and settings
class StoreManagementService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Update store branding information
  Future<void> updateStoreBranding({
    required String farmerId,
    String? storeName,
    String? storeDescription,
    String? storeMessage,
    String? businessHours,
    bool? isStoreOpen,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (storeName != null) updateData['store_name'] = storeName;
      if (storeDescription != null) updateData['store_description'] = storeDescription;
      if (storeMessage != null) updateData['store_message'] = storeMessage;
      if (businessHours != null) updateData['business_hours'] = businessHours;
      if (isStoreOpen != null) updateData['is_store_open'] = isStoreOpen;

      await _client
          .from('users')
          .update(updateData)
          .eq('id', farmerId);

      debugPrint('Store branding updated successfully');
    } catch (e) {
      debugPrint('Error updating store branding: $e');
      throw Exception('Failed to update store branding: $e');
    }
  }

  /// Upload store banner image
  Future<String> uploadStoreBanner(String farmerId, Uint8List imageData, String fileName) async {
    try {
      final path = '${StorageBuckets.storeBanners}/$farmerId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _client.storage
          .from(StorageBuckets.storeBanners)
          .uploadBinary(path, imageData);

      final bannerUrl = _client.storage
          .from(StorageBuckets.storeBanners)
          .getPublicUrl(path);

      // Update user record with new banner URL
      await _client
          .from('users')
          .update({
            'store_banner_url': bannerUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);

      debugPrint('Store banner uploaded successfully');
      return bannerUrl;
    } catch (e) {
      debugPrint('Error uploading store banner: $e');
      throw Exception('Failed to upload store banner: $e');
    }
  }

  /// Upload store logo image
  Future<String> uploadStoreLogo(String farmerId, Uint8List imageData, String fileName) async {
    try {
      final path = '${StorageBuckets.storeLogos}/$farmerId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await _client.storage
          .from(StorageBuckets.storeLogos)
          .uploadBinary(path, imageData);

      final logoUrl = _client.storage
          .from(StorageBuckets.storeLogos)
          .getPublicUrl(path);

      // Update user record with new logo URL
      await _client
          .from('users')
          .update({
            'store_logo_url': logoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);

      debugPrint('Store logo uploaded successfully');
      return logoUrl;
    } catch (e) {
      debugPrint('Error uploading store logo: $e');
      throw Exception('Failed to upload store logo: $e');
    }
  }

  /// Get store settings
  Future<StoreSettings> getStoreSettings(String farmerId) async {
    try {
      final response = await _client
          .from('store_settings')
          .select('*')
          .eq('seller_id', farmerId)
          .maybeSingle();

      if (response == null) {
        // Create default store settings if none exist
        return await createDefaultStoreSettings(farmerId);
      }

      return StoreSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error getting store settings: $e');
      throw Exception('Failed to load store settings: $e');
    }
  }

  /// Create default store settings
  Future<StoreSettings> createDefaultStoreSettings(String farmerId) async {
    try {
      final defaultSettings = {
        'seller_id': farmerId,
        'shipping_methods': ['Standard Delivery', 'Express Delivery', 'Pickup Available'],
        'payment_methods': {
          'Cash on Delivery': true,
          'GCash': true,
          'Bank Transfer': false,
          'Credit Card': false,
        },
        'auto_accept_orders': false,
        'vacation_mode': false,
        'min_order_amount': 0.00,
        'free_shipping_threshold': 500.00,
        'processing_time_days': 1,
      };

      await _client
          .from('store_settings')
          .insert(defaultSettings);

      return StoreSettings.fromJson(defaultSettings);
    } catch (e) {
      debugPrint('Error creating default store settings: $e');
      throw Exception('Failed to create store settings: $e');
    }
  }

  /// Update store settings
  Future<void> updateStoreSettings({
    required String farmerId,
    List<String>? shippingMethods,
    Map<String, bool>? paymentMethods,
    bool? autoAcceptOrders,
    bool? vacationMode,
    String? vacationMessage,
    double? minOrderAmount,
    double? freeShippingThreshold,
    int? processingTimeDays,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (shippingMethods != null) updateData['shipping_methods'] = shippingMethods;
      if (paymentMethods != null) updateData['payment_methods'] = paymentMethods;
      if (autoAcceptOrders != null) updateData['auto_accept_orders'] = autoAcceptOrders;
      if (vacationMode != null) updateData['vacation_mode'] = vacationMode;
      if (vacationMessage != null) updateData['vacation_message'] = vacationMessage;
      if (minOrderAmount != null) updateData['min_order_amount'] = minOrderAmount;
      if (freeShippingThreshold != null) updateData['free_shipping_threshold'] = freeShippingThreshold;
      if (processingTimeDays != null) updateData['processing_time_days'] = processingTimeDays;

      await _client
          .from('store_settings')
          .update(updateData)
          .eq('seller_id', farmerId);

      debugPrint('Store settings updated successfully');
    } catch (e) {
      debugPrint('Error updating store settings: $e');
      throw Exception('Failed to update store settings: $e');
    }
  }

  /// Get store analytics data
  Future<StoreAnalytics> getStoreAnalytics(String farmerId) async {
    try {
      // Get basic statistics
      final stats = await _client
          .from('seller_statistics')
          .select('*')
          .eq('seller_id', farmerId)
          .maybeSingle();

      if (stats == null) {
        throw Exception('Store statistics not found');
      }

      // Get monthly sales data for the last 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final salesData = await _client
          .from('orders')
          .select('total_amount, created_at')
          .eq('farmer_id', farmerId)
          .eq('farmer_status', 'delivered')
          .gte('created_at', sixMonthsAgo.toIso8601String())
          .order('created_at');

      // Get top products
      final topProducts = await _client
          .from('order_items')
          .select('''
            product_name,
            quantity,
            products!product_id (
              cover_image_url,
              price
            ),
            orders!order_id (
              farmer_id
            )
          ''')
          .eq('orders.farmer_id', farmerId)
          .eq('farmer_status', 'delivered');

      // Get recent reviews
      final recentReviews = await _client
          .from('seller_reviews')
          .select('''
            rating,
            review_text,
            created_at,
            users!buyer_id (
              full_name
            )
          ''')
          .eq('seller_id', farmerId)
          .order('created_at', ascending: false)
          .limit(5);

      return StoreAnalytics.fromData(
        stats: stats,
        salesData: salesData,
        topProducts: topProducts,
        recentReviews: recentReviews,
      );
    } catch (e) {
      debugPrint('Error getting store analytics: $e');
      throw Exception('Failed to load analytics: $e');
    }
  }

  /// Delete store banner
  Future<void> deleteStoreBanner(String farmerId, String bannerUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(bannerUrl);
      final pathSegments = uri.pathSegments;
      final path = pathSegments.skip(3).join('/'); // Skip /storage/v1/object/public/store-assets

      // Delete from storage
      await _client.storage
          .from('store-assets')
          .remove([path]);

      // Update user record
      await _client
          .from('users')
          .update({
            'store_banner_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);

      debugPrint('Store banner deleted successfully');
    } catch (e) {
      debugPrint('Error deleting store banner: $e');
      throw Exception('Failed to delete store banner: $e');
    }
  }

  /// Delete store logo
  Future<void> deleteStoreLogo(String farmerId, String logoUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(logoUrl);
      final pathSegments = uri.pathSegments;
      final path = pathSegments.skip(3).join('/'); // Skip /storage/v1/object/public/store-assets

      // Delete from storage
      await _client.storage
          .from('store-assets')
          .remove([path]);

      // Update user record
      await _client
          .from('users')
          .update({
            'store_logo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);

      debugPrint('Store logo deleted successfully');
    } catch (e) {
      debugPrint('Error deleting store logo: $e');
      throw Exception('Failed to delete store logo: $e');
    }
  }
}

/// Store settings model
class StoreSettings {
  final String sellerId;
  final List<String> shippingMethods;
  final Map<String, bool> paymentMethods;
  final bool autoAcceptOrders;
  final bool vacationMode;
  final String? vacationMessage;
  final double minOrderAmount;
  final double freeShippingThreshold;
  final int processingTimeDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreSettings({
    required this.sellerId,
    required this.shippingMethods,
    required this.paymentMethods,
    required this.autoAcceptOrders,
    required this.vacationMode,
    this.vacationMessage,
    required this.minOrderAmount,
    required this.freeShippingThreshold,
    required this.processingTimeDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      sellerId: json['seller_id'] ?? '',
      shippingMethods: List<String>.from(json['shipping_methods'] ?? []),
      paymentMethods: Map<String, bool>.from(json['payment_methods'] ?? {}),
      autoAcceptOrders: json['auto_accept_orders'] ?? false,
      vacationMode: json['vacation_mode'] ?? false,
      vacationMessage: json['vacation_message'],
      minOrderAmount: (json['min_order_amount'] ?? 0.0).toDouble(),
      freeShippingThreshold: (json['free_shipping_threshold'] ?? 500.0).toDouble(),
      processingTimeDays: json['processing_time_days'] ?? 1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Store analytics model
class StoreAnalytics {
  final int totalProducts;
  final int totalOrders;
  final int totalSales;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int totalFollowers;
  final List<MonthlySales> monthlySales;
  final List<TopProduct> topProducts;
  final List<RecentReview> recentReviews;

  const StoreAnalytics({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalSales,
    required this.totalRevenue,
    required this.averageRating,
    required this.totalReviews,
    required this.totalFollowers,
    required this.monthlySales,
    required this.topProducts,
    required this.recentReviews,
  });

  factory StoreAnalytics.fromData({
    required Map<String, dynamic> stats,
    required List<dynamic> salesData,
    required List<dynamic> topProducts,
    required List<dynamic> recentReviews,
  }) {
    // Process monthly sales data
    final salesByMonth = <String, double>{};
    double totalRevenue = 0;
    
    for (final sale in salesData) {
      final date = DateTime.parse(sale['created_at']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = (sale['total_amount'] ?? 0.0).toDouble();
      
      salesByMonth[monthKey] = (salesByMonth[monthKey] ?? 0) + amount;
      totalRevenue += amount;
    }

    final monthlySalesList = salesByMonth.entries
        .map((e) => MonthlySales(month: e.key, sales: e.value))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    // Process top products
    final productSales = <String, int>{};
    final productDetails = <String, Map<String, dynamic>>{};
    
    for (final item in topProducts) {
      final productName = item['product_name'] ?? '';
      final quantity = item['quantity'] ?? 0;
      final product = item['products'];
      
      final currentSales = productSales[productName] ?? 0;
      productSales[productName] = currentSales + (quantity as num).toInt();
      if (product != null) {
        productDetails[productName] = product;
      }
    }

    final topProductsList = productSales.entries
        .map((e) => TopProduct(
              name: e.key,
              quantitySold: e.value,
              imageUrl: productDetails[e.key]?['cover_image_url'],
              price: (productDetails[e.key]?['price'] ?? 0.0).toDouble(),
            ))
        .toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold))
      ..take(5);

    // Process recent reviews
    final recentReviewsList = recentReviews
        .map((review) => RecentReview(
              rating: review['rating'] ?? 5,
              reviewText: review['review_text'],
              buyerName: review['users']?['full_name'] ?? 'Anonymous',
              createdAt: DateTime.parse(review['created_at'] ?? DateTime.now().toIso8601String()),
            ))
        .toList();

    return StoreAnalytics(
      totalProducts: stats['total_products'] ?? 0,
      totalOrders: stats['total_orders'] ?? 0,
      totalSales: stats['total_sales'] ?? 0,
      totalRevenue: totalRevenue,
      averageRating: (stats['average_rating'] ?? 0.0).toDouble(),
      totalReviews: stats['total_reviews'] ?? 0,
      totalFollowers: stats['total_followers'] ?? 0,
      monthlySales: monthlySalesList,
      topProducts: topProductsList.toList(),
      recentReviews: recentReviewsList,
    );
  }
}

/// Monthly sales data
class MonthlySales {
  final String month;
  final double sales;

  const MonthlySales({
    required this.month,
    required this.sales,
  });
}

/// Top product data
class TopProduct {
  final String name;
  final int quantitySold;
  final String? imageUrl;
  final double price;

  const TopProduct({
    required this.name,
    required this.quantitySold,
    this.imageUrl,
    required this.price,
  });
}

/// Recent review data
class RecentReview {
  final int rating;
  final String? reviewText;
  final String buyerName;
  final DateTime createdAt;

  const RecentReview({
    required this.rating,
    this.reviewText,
    required this.buyerName,
    required this.createdAt,
  });
}