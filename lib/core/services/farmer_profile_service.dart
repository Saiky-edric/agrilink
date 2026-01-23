import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/seller_store_model.dart';
import '../models/followed_store_model.dart';

class FarmerProfileService {
  static final FarmerProfileService _instance = FarmerProfileService._internal();
  factory FarmerProfileService() => _instance;
  FarmerProfileService._internal();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get farmer profile data
  Future<FarmerProfileData> getFarmerProfile(String farmerId) async {
    try {
      final response = await _client
          .from('users')
          .select('*, farmer_verifications!farmer_verifications_farmer_id_fkey(*)')
          .eq('id', farmerId)
          .single();

      return FarmerProfileData.fromJson(response);
    } catch (e) {
      debugPrint('Error getting farmer profile: $e');
      throw Exception('Failed to load farmer profile: $e');
    }
  }

  // Update farmer profile
  Future<void> updateFarmerProfile({
    required String farmerId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _client
          .from('users')
          .update(updates)
          .eq('id', farmerId);

      debugPrint('Farmer profile updated successfully');
    } catch (e) {
      debugPrint('Error updating farmer profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get sales analytics
  Future<SalesAnalytics> getSalesAnalytics(String farmerId) async {
    try {
      // Get all orders with items
      final ordersResponse = await _client
          .from('orders')
          .select('id, total_amount, subtotal, delivery_fee, created_at, farmer_status')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      // Get order items with product details for top products analysis
      final orderItemsResponse = await _client
          .from('order_items')
          .select('product_id, product_name, quantity, unit_price, subtotal, orders!inner(farmer_id, farmer_status)')
          .eq('orders.farmer_id', farmerId);

      // Get total products count
      final productsResponse = await _client
          .from('products')
          .select('id')
          .eq('farmer_id', farmerId);
      
      final totalProducts = (productsResponse as List).length;

      return SalesAnalytics.fromAccurateData(
        ordersResponse, 
        orderItemsResponse,
        totalProducts,
      );
    } catch (e) {
      debugPrint('Error getting sales analytics: $e');
      throw Exception('Failed to load analytics: $e');
    }
  }

  // Get farm information
  Future<FarmInformation> getFarmInformation(String farmerId) async {
    try {
      final response = await _client
          .from('farm_information')
          .select()
          .eq('farmer_id', farmerId)
          .maybeSingle();

      if (response == null) {
        return FarmInformation.empty();
      }

      return FarmInformation.fromJson(response);
    } catch (e) {
      debugPrint('Error getting farm information: $e');
      throw Exception('Failed to load farm information: $e');
    }
  }

  // Update farm information
  Future<void> updateFarmInformation({
    required String farmerId,
    required FarmInformation farmInfo,
  }) async {
    try {
      await _client
          .from('farm_information')
          .upsert({
            'farmer_id': farmerId,
            'location': farmInfo.location,
            'size': farmInfo.size,
            'primary_crops': farmInfo.primaryCrops,
            'years_experience': farmInfo.yearsExperience,
            'farming_methods': farmInfo.farmingMethods,
            'description': farmInfo.description,
            'updated_at': DateTime.now().toIso8601String(),
          });

      debugPrint('Farm information updated successfully');
    } catch (e) {
      debugPrint('Error updating farm information: $e');
      throw Exception('Failed to update farm information: $e');
    }
  }

  // Get recent activities
  Future<List<RecentActivity>> getRecentActivities(String farmerId) async {
    try {
      final ordersResponse = await _client
          .from('orders')
          .select('id, created_at, farmer_status, total_amount')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(10);

      final productsResponse = await _client
          .from('products')
          .select('id, name, created_at')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(5);

      List<RecentActivity> activities = [];

      // Add order activities
      for (var order in ordersResponse) {
        activities.add(RecentActivity(
          id: order['id'],
          type: 'order',
          title: 'New Order Received',
          description: 'Order worth ₱${order['total_amount']}',
          timestamp: DateTime.parse(order['created_at']),
          icon: 'shopping_cart',
        ));
      }

      // Add product activities
      for (var product in productsResponse) {
        activities.add(RecentActivity(
          id: product['id'],
          type: 'product',
          title: 'Product Added',
          description: product['name'],
          timestamp: DateTime.parse(product['created_at']),
          icon: 'inventory',
        ));
      }

      // Sort by timestamp
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return activities.take(10).toList();
    } catch (e) {
      debugPrint('Error getting recent activities: $e');
      return [];
    }
  }
}

// Data models
class FarmerProfileData {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? municipality;
  final String? barangay;
  final String? street;
  final DateTime createdAt;
  final bool isVerified;

  FarmerProfileData({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.municipality,
    this.barangay,
    this.street,
    required this.createdAt,
    this.isVerified = false,
  });

  factory FarmerProfileData.fromJson(Map<String, dynamic> json) {
    // farmer_verifications may be embedded as a List (via relationship embed) or a Map
    final verifications = json['farmer_verifications'];
    bool isVerified = false;
    if (verifications is List) {
      if (verifications.isNotEmpty) {
        final first = verifications.first;
        if (first is Map<String, dynamic>) {
          isVerified = (first['status']?.toString() ?? '') == 'approved';
        }
      }
    } else if (verifications is Map<String, dynamic>) {
      isVerified = (verifications['status']?.toString() ?? '') == 'approved';
    }

    return FarmerProfileData(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      municipality: json['municipality'],
      barangay: json['barangay'],
      street: json['street'],
      createdAt: DateTime.parse(json['created_at']),
      isVerified: isVerified,
    );
  }
}

class SalesAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final double averageOrderValue;
  final List<MonthlyRevenue> monthlyRevenue;
  final List<ProductPerformance> topProducts;

  SalesAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.averageOrderValue,
    required this.monthlyRevenue,
    required this.topProducts,
  });

  factory SalesAnalytics.fromAccurateData(
    List<dynamic> orders, 
    List<dynamic> orderItems,
    int totalProducts,
  ) {
    double totalRevenue = 0;
    int completedOrders = 0;
    
    // Filter completed orders and calculate revenue
    final validStatuses = ['completed', 'delivered'];
    for (var order in orders) {
      final status = order['farmer_status']?.toString() ?? '';
      if (validStatuses.contains(status)) {
        completedOrders++;
        totalRevenue += (order['total_amount'] ?? 0).toDouble();
      }
    }

    double averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0;

    // Calculate monthly revenue from actual order dates
    Map<String, double> monthlyRevenueMap = {};
    final now = DateTime.now();
    
    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = _getMonthKey(date);
      monthlyRevenueMap[monthKey] = 0;
    }
    
    // Aggregate revenue by month
    for (var order in orders) {
      final status = order['farmer_status']?.toString() ?? '';
      if (validStatuses.contains(status)) {
        final createdAt = DateTime.parse(order['created_at']);
        final monthKey = _getMonthKey(createdAt);
        monthlyRevenueMap[monthKey] = (monthlyRevenueMap[monthKey] ?? 0) + 
            (order['total_amount'] ?? 0).toDouble();
      }
    }
    
    // Convert to list
    List<MonthlyRevenue> monthlyRevenue = monthlyRevenueMap.entries
        .map((e) => MonthlyRevenue(month: e.key, revenue: e.value))
        .toList();

    // Calculate product performance from order items
    Map<String, ProductPerformanceData> productMap = {};
    
    for (var item in orderItems) {
      final orders = item['orders'];
      if (orders != null) {
        final status = orders['farmer_status']?.toString() ?? '';
        if (validStatuses.contains(status)) {
          final productId = item['product_id'];
          final productName = item['product_name'] ?? 'Unknown';
          final quantity = (item['quantity'] ?? 0) as int;
          final subtotal = (item['subtotal'] ?? 0).toDouble();
          
          if (productMap.containsKey(productId)) {
            productMap[productId]!.totalSales += quantity;
            productMap[productId]!.totalRevenue += subtotal;
          } else {
            productMap[productId] = ProductPerformanceData(
              name: productName,
              totalSales: quantity,
              totalRevenue: subtotal,
            );
          }
        }
      }
    }
    
    // Get top 5 products by revenue
    List<ProductPerformance> topProducts = productMap.values
        .map((data) => ProductPerformance(
              name: data.name,
              sales: data.totalSales,
              revenue: data.totalRevenue,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    
    topProducts = topProducts.take(5).toList();

    return SalesAnalytics(
      totalRevenue: totalRevenue,
      totalOrders: completedOrders,
      totalProducts: totalProducts,
      averageOrderValue: averageOrderValue,
      monthlyRevenue: monthlyRevenue,
      topProducts: topProducts,
    );
  }
  
  static String _getMonthKey(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}

class MonthlyRevenue {
  final String month;
  final double revenue;

  MonthlyRevenue({required this.month, required this.revenue});
}

class ProductPerformance {
  final String name;
  final int sales;
  final double revenue;

  ProductPerformance({
    required this.name,
    required this.sales,
    required this.revenue,
  });
}

// Helper class for aggregating product data
class ProductPerformanceData {
  final String name;
  int totalSales;
  double totalRevenue;

  ProductPerformanceData({
    required this.name,
    required this.totalSales,
    required this.totalRevenue,
  });
}

class FarmInformation {
  final String location;
  final String size;
  final List<String> primaryCrops;
  final int yearsExperience;
  final List<String> farmingMethods;
  final String? description;

  FarmInformation({
    required this.location,
    required this.size,
    required this.primaryCrops,
    required this.yearsExperience,
    required this.farmingMethods,
    this.description,
  });

  factory FarmInformation.empty() {
    return FarmInformation(
      location: '',
      size: '',
      primaryCrops: [],
      yearsExperience: 0,
      farmingMethods: [],
    );
  }

  factory FarmInformation.fromJson(Map<String, dynamic> json) {
    return FarmInformation(
      location: json['location'] ?? '',
      size: json['size'] ?? '',
      primaryCrops: List<String>.from(json['primary_crops'] ?? []),
      yearsExperience: json['years_experience'] ?? 0,
      farmingMethods: List<String>.from(json['farming_methods'] ?? []),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'size': size,
      'primary_crops': primaryCrops,
      'years_experience': yearsExperience,
      'farming_methods': farmingMethods,
      'description': description,
    };
  }
}

class RecentActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });

}

// Additional methods for FarmerProfileService
extension FarmerProfileServiceMethods on FarmerProfileService {
  // Search farmer stores by name/location
  Future<List<Map<String, dynamic>>> searchStores(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];
      final client = SupabaseService.instance.client;
      final res = await client
          .from('users')
          .select('''
            id, full_name, store_name, store_logo_url, store_banner_url, avatar_url, municipality, barangay, is_store_open, is_active, role,
            seller_statistics (
              total_products,
              average_rating,
              total_reviews
            ),
            farmer_verifications!farmer_verifications_farmer_id_fkey (
              farm_name,
              status
            )
          ''')
          .eq('role', 'farmer')
          .eq('is_active', true)
          // Only sellers with an explicit store_name (buyers typically have null)
          .not('store_name', 'is', null)
          .neq('store_name', '')
          // Match on store_name, full_name, or location fields
          .or('store_name.ilike.%$q%,full_name.ilike.%$q%,municipality.ilike.%$q%,barangay.ilike.%$q%')
          .order('store_name', ascending: true)
          .limit(20);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error searching stores: $e');
      return [];
    }
  }
  // Get seller store information for e-commerce-style display
  Future<SellerStore> getSellerStore(String farmerId) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('users')
          .select('''
           id, full_name, email, phone_number, avatar_url, municipality, barangay, created_at,
           store_name, store_description, store_message, business_hours, is_store_open,
            store_banner_url, store_logo_url,
            farmer_verifications!farmer_verifications_farmer_id_fkey (
              farm_name, farm_address, farm_details, status
            ),
            products (
              id, name, price, unit, category, cover_image_url, is_hidden
            )
          ''')
          .eq('id', farmerId)
          .eq('role', 'farmer')
          .eq('is_active', true)
          .single();

      // Get additional store statistics
      final stats = await _getSellerStatistics(farmerId);
      final storeData = Map<String, dynamic>.from(response);
      storeData.addAll(stats);

      return SellerStore.fromJson(storeData);
    } catch (e) {
      debugPrint('Error getting seller store: $e');
      throw Exception('Failed to load store: $e');
    }
  }

  // Get comprehensive seller statistics
  Future<Map<String, dynamic>> _getSellerStatistics(String farmerId) async {
    try {
      final client = SupabaseService.instance.client;
      // Get product count
      final productRows = await client
          .from('products')
          .select('id')
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false);
      final productCount = (productRows as List).length;

      // Get sales data (from orders)
      final salesData = await client
          .from('order_items')
          .select('quantity, orders!inner(farmer_id)')
          .eq('orders.farmer_id', farmerId);

      final totalSales = salesData.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));

      // Get active orders count
      final activeRows = await client
          .from('orders')
          .select('id')
          .eq('farmer_id', farmerId)
          .inFilter('farmer_status', ['newOrder', 'accepted', 'toPack', 'toDeliver']);
      final activeOrders = (activeRows as List).length;

      // Get product categories
      final categoryData = await client
          .from('products')
          .select('category')
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false);

      final categories = categoryData
          .map((p) => p['category'] as String?)
          .where((c) => c != null)
          .cast<String>()
          .toSet()
          .toList();

      // Followers count from user_follows
      final followersRows = await client
          .from('user_follows')
          .select('user_id')
          .eq('seller_id', farmerId);
      final followersCount = (followersRows as List).length;
     if (kDebugMode) {
       debugPrint('Followers (service) count for $farmerId = $followersCount');
     }

      // Get seller reviews and calculate average rating
      final reviews = await client
          .from('seller_reviews')
          .select('rating')
          .eq('seller_id', farmerId);

      double averageRating = 0.0;
      int totalReviews = reviews.length;
      
      if (totalReviews > 0) {
        int totalRating = 0;
        for (final review in reviews) {
          totalRating += (review['rating'] as int? ?? 0);
        }
        averageRating = totalRating / totalReviews;
      }

      return {
        'total_products': productCount,
        'total_sales': totalSales,
        'active_orders': activeOrders,
        'categories': categories,
        'response_rate': 0.95, // Default values for demo
        'avg_response_hours': 2,
        'total_followers': followersCount,
        'shipment_rating': 4.8,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
      };
    } catch (e) {
      debugPrint('Error getting seller statistics: $e');
      return {
        'total_products': 0,
        'total_sales': 0,
        'active_orders': 0,
        'categories': <String>[],
        'response_rate': 0.95,
        'avg_response_hours': 2,
        'followers': 0,
        'shipment_rating': 4.8,
        'average_rating': 4.5,
        'total_reviews': 0,
      };
    }
  }

  // Get featured products for store display
  Future<List<Map<String, dynamic>>> getFeaturedProducts(String farmerId, {int limit = 6}) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('products')
          .select('*')
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting featured products: $e');
      return [];
    }
  }

  // Get products by category for store browsing
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String farmerId,
    String category, {
    int limit = 20,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('products')
          .select('*')
          .eq('farmer_id', farmerId)
          .eq('category', category)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  // Follow/unfollow a seller
  Future<void> toggleFollowSeller(String farmerId, bool isFollowing) async {
    try {
      final client = SupabaseService.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      if (isFollowing) {
        await client
            .from('user_follows')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('seller_id', farmerId);
      } else {
        await client
            .from('user_follows')
            .insert({
          'user_id': currentUser.id,
          'seller_id': farmerId,
          'followed_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('Seller follow status updated');
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
      throw Exception('Failed to update follow status: $e');
    }
  }

  // Check if user is following a seller
  Future<bool> isFollowingSeller(String farmerId) async {
    try {
      final client = SupabaseService.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await client
         .from('user_follows')
         .select('user_id')
         .eq('user_id', currentUser.id)
         .eq('seller_id', farmerId)
         .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  // Get all stores that a user is following
  Future<List<FollowedStore>> getFollowedStores(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('user_follows')
          .select('''
            seller_id,
            followed_at,
            users!user_follows_seller_id_fkey (
              id,
              full_name,
              store_name,
              store_logo_url,
              avatar_url,
              store_description,
              municipality,
              barangay,
              is_store_open,
              seller_statistics (
                total_products,
                average_rating,
                total_reviews,
                seller_id
              )
            )
          ''')
          .eq('user_id', userId)
          .order('followed_at', ascending: false);

      if (kDebugMode) {
        debugPrint('FollowedStores raw rows: \\${response.length} for user \\$userId');
      }

      // Get verification status for each seller
      final sellerIds = response.map((r) => r['seller_id'] as String).toList();
      
      Map<String, String> verificationStatuses = {};
      if (sellerIds.isNotEmpty) {
        final verifications = await client
            .from('farmer_verifications')
            .select('farmer_id, status')
            .inFilter('farmer_id', sellerIds);
        
        for (final v in verifications) {
          verificationStatuses[v['farmer_id']] = v['status']?.toString() ?? 'pending';
        }
      }

      return response.map((json) {
        final sellerId = json['seller_id'] as String;
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['verification_status'] = verificationStatuses[sellerId] ?? 'pending';
        return FollowedStore.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      debugPrint('Error getting followed stores: $e');
      return [];
    }
  }

  // Get farmer verification status
  Future<Map<String, dynamic>> getVerificationStatus(String farmerId) async {
    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('farmer_verifications')
          .select('status, rejection_reason, admin_notes, reviewed_at')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return {'status': 'not_submitted', 'message': 'Verification not submitted'};
      }

      return response.first;
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return {'status': 'error', 'message': 'Failed to load verification status'};
    }
  }
}

// Public farmer profile model for buyers to browse
class PublicFarmerProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? municipality;
  final String? barangay;
  final String? farmName;
  final String? farmAddress;
  final Map<String, dynamic>? farmDetails;
  final String verificationStatus;
  final List<Map<String, dynamic>> products;

  const PublicFarmerProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.municipality,
    this.barangay,
    this.farmName,
    this.farmAddress,
    this.farmDetails,
    required this.verificationStatus,
    required this.products,
  });

  factory PublicFarmerProfile.fromJson(Map<String, dynamic> json) {
    final verification = json['farmer_verifications'] as List?;
    final verificationData = verification?.isNotEmpty == true ? verification!.first : null;
    
    return PublicFarmerProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      municipality: json['municipality'],
      barangay: json['barangay'],
      farmName: verificationData?['farm_name'],
      farmAddress: verificationData?['farm_address'],
      farmDetails: verificationData?['farm_details'],
      verificationStatus: verificationData?['status'] ?? 'not_verified',
      products: List<Map<String, dynamic>>.from(json['products'] ?? [])
          .where((p) => p['is_hidden'] != true)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'municipality': municipality,
      'barangay': barangay,
      'farm_name': farmName,
      'farm_address': farmAddress,
      'farm_details': farmDetails,
      'verification_status': verificationStatus,
      'products': products,
    };
  }
}