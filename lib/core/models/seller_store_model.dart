import 'package:flutter/material.dart';

// Add SupabaseService import

/// Model representing a seller's store information
class SellerStore {
  final String id;
  final String storeName;
  final String ownerName;
  final String? storeLogoUrl;
  final String? storeBannerUrl;
  final String description;
  final String location;
  final DateTime joinDate;
  final bool isVerified;
  final SellerRating rating;
  final SellerStats stats;
  final List<String> categories;
  final StoreSettings settings;

  // Contact
  final String? email;
  final String? phoneNumber;
  
  // Premium subscription status
  final bool isPremium;

  const SellerStore({
    required this.id,
    required this.storeName,
    required this.ownerName,
    this.storeLogoUrl,
    this.storeBannerUrl,
    required this.description,
    required this.location,
    required this.joinDate,
    required this.isVerified,
    required this.rating,
    required this.stats,
    required this.categories,
    required this.settings,
    this.email,
    this.phoneNumber,
    this.isPremium = false,
  });

  // Factory for creating basic store from minimal user data
  factory SellerStore.fromBasicData(Map<String, dynamic> data) {
    return SellerStore(
      id: data['id'] ?? '',
      storeName: data['store_name'] ?? 'Farmer Store',
      ownerName: data['owner_name'] ?? 'Farmer',
      storeLogoUrl: data['avatar_url'],
      storeBannerUrl: data['store_banner_url'],
      description: data['description'] ?? 'Fresh agricultural products from our farm.',
      location: data['location'] ?? '',
      joinDate: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      isVerified: false,
      rating: SellerRating(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        recentReviews: [],
      ),
      stats: SellerStats(
        totalProducts: 0,
        totalSales: 0,
        activeOrders: 0,
        responseRate: 0.95,
        averageResponseTime: const Duration(hours: 2),
        followers: 0,
        shipmentRating: 4.8,
        monthsOnPlatform: 1,
      ),
      categories: [],
      settings: StoreSettings(
       isStoreOpen: true,
       storeMessage: null,
       shippingMethods: ['Standard Delivery', 'Pickup Available'],
       paymentMethods: {
         'Cash on Delivery': true,
         'GCash': false,
         'Credit Card': false,
       },
       businessHours: 'Mon-Sun 6:00 AM - 6:00 PM',
     ),
     email: data['email'],
     phoneNumber: data['phone_number'] ?? data['phone'],
     isPremium: false,
   );
  }

  factory SellerStore.fromJson(Map<String, dynamic> json) {
    // Priority order for store name: store_name (from store customization) > farm_name from verification > "{full_name}'s Farm"
    String storeName = 'Farm Store';
    String farmerName = json['full_name']?.toString().trim() ?? 'Farmer';
    
    // First priority: store customization store_name
    final customStoreName = json['store_name']?.toString().trim();
    if (customStoreName != null && customStoreName.isNotEmpty) {
      storeName = customStoreName;
    } else {
      // Second priority: farm name from farmer_verifications
      final verifications = json['farmer_verifications'];
      bool foundFarmName = false;
      
      if (verifications is List && verifications.isNotEmpty) {
        final farmName = verifications.first['farm_name'];
        if (farmName != null && farmName.toString().trim().isNotEmpty) {
          storeName = farmName.toString().trim();
          foundFarmName = true;
        }
      } else if (verifications is Map) {
        final farmName = verifications['farm_name'];
        if (farmName != null && farmName.toString().trim().isNotEmpty) {
          storeName = farmName.toString().trim();
          foundFarmName = true;
        }
      }
      
      // Third priority: direct farm_name field
      if (!foundFarmName) {
        final directFarmName = json['farm_name']?.toString().trim();
        if (directFarmName != null && directFarmName.isNotEmpty) {
          storeName = directFarmName;
          foundFarmName = true;
        }
      }
      
      // Final fallback: "{farmer_name}'s Farm"
      if (!foundFarmName) {
        storeName = "$farmerName's Farm";
      }
    }

    // Get store description from customization first, then fallback
    String storeDescription = json['store_description']?.toString().trim() ?? 
                            json['description']?.toString().trim() ?? 
                            'Fresh agricultural products from our farm.';
    
    // Get verification status
    bool isVerified = json['verification_status'] == 'approved';
    if (!isVerified) {
      // Check farmer_verifications for status
      final verifications = json['farmer_verifications'];
      if (verifications is List && verifications.isNotEmpty) {
        isVerified = verifications.first['status'] == 'approved';
      } else if (verifications is Map) {
        isVerified = verifications['status'] == 'approved';
      }
    }

    // Create store settings with customization data
    final customSettings = {
      'is_open': json['is_store_open'] ?? true,
      'store_message': json['store_message'],
      'business_hours': json['business_hours'] ?? 'Mon-Sun 6:00 AM - 6:00 PM',
    };

    // Check premium status
    bool isPremium = false;
    final subscriptionTier = json['subscription_tier'] ?? 'free';
    if (subscriptionTier == 'premium') {
      final expiresAt = json['subscription_expires_at'];
      if (expiresAt == null) {
        // Lifetime premium
        isPremium = true;
      } else {
        // Check if not expired
        final expiryDate = DateTime.tryParse(expiresAt);
        isPremium = expiryDate != null && expiryDate.isAfter(DateTime.now());
      }
    }

    return SellerStore(
      id: json['id'] ?? '',
      storeName: storeName,
      ownerName: json['full_name'] ?? '',
      storeLogoUrl: json['store_logo_url'] ?? json['avatar_url'],
      storeBannerUrl: json['store_banner_url'],
      description: storeDescription,
      location: '${json['municipality'] ?? ''}, ${json['barangay'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
      joinDate: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isVerified: isVerified,
      rating: SellerRating.fromJson(json),
      stats: SellerStats.fromJson(json),
      categories: List<String>.from(json['categories'] ?? []),
      settings: StoreSettings.fromJson({...json, ...customSettings}),
      email: json['email'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      isPremium: isPremium,
    );
  }
}

/// Seller rating and review information
class SellerRating {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final List<String> recentReviews;

  const SellerRating({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory SellerRating.fromJson(Map<String, dynamic> json) {
    return SellerRating(
      averageRating: (json['average_rating'] ?? 4.5).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {
        5: 45, 4: 30, 3: 15, 2: 8, 1: 2
      }),
      recentReviews: List<String>.from(json['recent_reviews'] ?? [
        'Fresh products and fast delivery!',
        'Great quality vegetables.',
        'Reliable farmer with good products.'
      ]),
    );
  }

  String get ratingText {
    if (averageRating >= 4.5) return 'Excellent';
    if (averageRating >= 4.0) return 'Very Good';
    if (averageRating >= 3.5) return 'Good';
    if (averageRating >= 3.0) return 'Average';
    return 'Below Average';
  }
}

/// Store statistics and performance metrics
class SellerStats {
  final int totalProducts;
  final int totalSales;
  final int activeOrders;
  final double responseRate;
  final Duration averageResponseTime;
  final int followers;
  final double shipmentRating;
  final int monthsOnPlatform;

  const SellerStats({
    required this.totalProducts,
    required this.totalSales,
    required this.activeOrders,
    required this.responseRate,
    required this.averageResponseTime,
    required this.followers,
    required this.shipmentRating,
    required this.monthsOnPlatform,
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    final joinDate = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
    final monthsOnPlatform = DateTime.now().difference(joinDate).inDays ~/ 30;

    return SellerStats(
      totalProducts: json['total_products'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      responseRate: (json['response_rate'] ?? 0.95).toDouble(),
      averageResponseTime: Duration(hours: json['avg_response_hours'] ?? 2),
      followers: json['total_followers'] ?? 0,
      shipmentRating: (json['shipment_rating'] ?? 4.8).toDouble(),
      monthsOnPlatform: monthsOnPlatform > 0 ? monthsOnPlatform : 1,
    );
  }

  String get responseTimeText {
    if (averageResponseTime.inHours < 1) {
      return 'Within ${averageResponseTime.inMinutes} minutes';
    } else if (averageResponseTime.inHours < 24) {
      return 'Within ${averageResponseTime.inHours} hours';
    } else {
      return 'Within ${averageResponseTime.inDays} days';
    }
  }

  String get performanceLevel {
    if (responseRate >= 0.95 && shipmentRating >= 4.5) return 'Top Performer';
    if (responseRate >= 0.90 && shipmentRating >= 4.0) return 'Reliable Seller';
    if (responseRate >= 0.80 && shipmentRating >= 3.5) return 'Good Seller';
    return 'New Seller';
  }

  Color get performanceColor {
    switch (performanceLevel) {
      case 'Top Performer': return Colors.green;
      case 'Reliable Seller': return Colors.blue;
      case 'Good Seller': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

/// Store settings and configuration
class StoreSettings {
  final bool isStoreOpen;
  final String? storeMessage;
  final List<String> shippingMethods;
  final Map<String, bool> paymentMethods;
  final String businessHours;

  const StoreSettings({
    required this.isStoreOpen,
    this.storeMessage,
    required this.shippingMethods,
    required this.paymentMethods,
    required this.businessHours,
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      isStoreOpen: json['is_open'] ?? true,
      storeMessage: json['store_message'],
      shippingMethods: List<String>.from(json['shipping_methods'] ?? [
        'Standard Delivery',
        'Express Delivery',
        'Pickup Available'
      ]),
      paymentMethods: Map<String, bool>.from(json['payment_methods'] ?? {
        'Cash on Delivery': true,
        'GCash': true,
        'Bank Transfer': false,
        'Credit Card': false,
      }),
      businessHours: json['business_hours'] ?? 'Mon-Sun 6:00 AM - 6:00 PM',
    );
  }
}

/// Product category with count
class ProductCategory {
  final String name;
  final String icon;
  final int productCount;
  final Color color;

  const ProductCategory({
    required this.name,
    required this.icon,
    required this.productCount,
    required this.color,
  });

  static List<ProductCategory> getDefaultCategories(List<Map<String, dynamic>> products) {
    final Map<String, int> categoryCount = {};
    for (final product in products) {
      final category = product['category'] as String? ?? 'Other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final List<ProductCategory> categories = [];
    categoryCount.forEach((name, count) {
      categories.add(ProductCategory(
        name: name,
        icon: _getCategoryIcon(name),
        productCount: count,
        color: _getCategoryColor(name),
      ));
    });

    return categories;
  }

  static String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return '🥬';
      case 'fruits': return '🍎';
      case 'grains': return '🌾';
      case 'herbs': return '🌿';
      case 'roots': return '🥕';
      default: return '🌱';
    }
  }

  static Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return Colors.green;
      case 'fruits': return Colors.orange;
      case 'grains': return Colors.amber;
      case 'herbs': return Colors.teal;
      case 'roots': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }
}