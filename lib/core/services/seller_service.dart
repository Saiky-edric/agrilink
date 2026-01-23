import '../config/environment.dart';
import 'supabase_service.dart';

class SellerStatisticsModel {
  final String id;
  final String sellerId;
  final int totalProducts;
  final int totalSales;
  final int totalOrders;
  final int activeOrders;
  final int totalFollowers;
  final int totalReviews;
  final double averageRating;
  final double responseRate;
  final int averageResponseHours;
  final double shippingRating;
  final DateTime lastActiveAt;
  final DateTime statsUpdatedAt;

  const SellerStatisticsModel({
    required this.id,
    required this.sellerId,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.totalOrders = 0,
    this.activeOrders = 0,
    this.totalFollowers = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.responseRate = 0.95,
    this.averageResponseHours = 2,
    this.shippingRating = 4.8,
    required this.lastActiveAt,
    required this.statsUpdatedAt,
  });

  factory SellerStatisticsModel.fromJson(Map<String, dynamic> json) {
    return SellerStatisticsModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      totalProducts: json['total_products'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      totalFollowers: json['total_followers'] ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0.95,
      averageResponseHours: json['average_response_hours'] ?? 2,
      shippingRating: (json['shipping_rating'] as num?)?.toDouble() ?? 4.8,
      lastActiveAt: DateTime.parse(json['last_active_at']),
      statsUpdatedAt: DateTime.parse(json['stats_updated_at']),
    );
  }
}

class StoreSettingsModel {
  final String id;
  final String sellerId;
  final Map<String, dynamic> shippingMethods;
  final Map<String, dynamic> paymentMethods;
  final bool autoAcceptOrders;
  final bool vacationMode;
  final String? vacationMessage;
  final double minOrderAmount;
  final double freeShippingThreshold;
  final int processingTimeDays;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StoreSettingsModel({
    required this.id,
    required this.sellerId,
    this.shippingMethods = const {},
    this.paymentMethods = const {},
    this.autoAcceptOrders = false,
    this.vacationMode = false,
    this.vacationMessage,
    this.minOrderAmount = 0.0,
    this.freeShippingThreshold = 500.0,
    this.processingTimeDays = 1,
    required this.createdAt,
    this.updatedAt,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      shippingMethods: json['shipping_methods'] as Map<String, dynamic>? ?? {},
      paymentMethods: json['payment_methods'] as Map<String, dynamic>? ?? {},
      autoAcceptOrders: json['auto_accept_orders'] ?? false,
      vacationMode: json['vacation_mode'] ?? false,
      vacationMessage: json['vacation_message'] as String?,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      freeShippingThreshold: (json['free_shipping_threshold'] as num?)?.toDouble() ?? 500.0,
      processingTimeDays: json['processing_time_days'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class SellerService {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get seller statistics
  Future<SellerStatisticsModel?> getSellerStatistics(String sellerId) async {
    try {
      final response = await _supabase.sellerStatistics
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (response == null) {
        return await createDefaultStatistics(sellerId);
      }

      return SellerStatisticsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error getting seller statistics', e);
      return null;
    }
  }

  // Create default statistics for new seller
  Future<SellerStatisticsModel> createDefaultStatistics(String sellerId) async {
    try {
      final response = await _supabase.sellerStatistics.insert({
        'seller_id': sellerId,
        'total_products': 0,
        'total_sales': 0,
        'total_orders': 0,
        'active_orders': 0,
        'total_followers': 0,
        'total_reviews': 0,
        'average_rating': 0.0,
        'response_rate': 0.95,
        'average_response_hours': 2,
        'shipping_rating': 4.8,
        'last_active_at': DateTime.now().toIso8601String(),
        'stats_updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return SellerStatisticsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error creating seller statistics', e);
      rethrow;
    }
  }

  // Get store settings
  Future<StoreSettingsModel?> getStoreSettings(String sellerId) async {
    try {
      final response = await _supabase.storeSettings
          .select()
          .eq('seller_id', sellerId)
          .maybeSingle();

      if (response == null) {
        return await createDefaultStoreSettings(sellerId);
      }

      return StoreSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error getting store settings', e);
      return null;
    }
  }

  // Create default store settings
  Future<StoreSettingsModel> createDefaultStoreSettings(String sellerId) async {
    try {
      final response = await _supabase.storeSettings.insert({
        'seller_id': sellerId,
        'shipping_methods': ["Standard Delivery", "Express Delivery", "Pickup Available"],
        'payment_methods': {
          "GCash": true,
          "Credit Card": false,
          "Bank Transfer": false,
          "Cash on Delivery": true
        },
        'auto_accept_orders': false,
        'vacation_mode': false,
        'min_order_amount': 0.0,
        'free_shipping_threshold': 500.0,
        'processing_time_days': 1,
      }).select().single();

      return StoreSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error creating store settings', e);
      rethrow;
    }
  }

  // Update store settings
  Future<StoreSettingsModel> updateStoreSettings({
    required String sellerId,
    Map<String, dynamic>? shippingMethods,
    Map<String, dynamic>? paymentMethods,
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

      final response = await _supabase.storeSettings
          .update(updateData)
          .eq('seller_id', sellerId)
          .select()
          .single();

      return StoreSettingsModel.fromJson(response);
    } catch (e) {
      EnvironmentConfig.logError('Error updating store settings', e);
      rethrow;
    }
  }

  // Update seller statistics (usually called by triggers or background processes)
  Future<void> updateSellerStatistics(String sellerId) async {
    try {
      // This would typically be handled by database triggers
      // But can be called manually for recalculation
      await _supabase.sellerStatistics
          .update({
            'last_active_at': DateTime.now().toIso8601String(),
            'stats_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('seller_id', sellerId);
    } catch (e) {
      EnvironmentConfig.logError('Error updating seller statistics', e);
      rethrow;
    }
  }

  // Toggle vacation mode
  Future<StoreSettingsModel> toggleVacationMode(String sellerId, {String? message}) async {
    final settings = await getStoreSettings(sellerId);
    if (settings == null) throw Exception('Store settings not found');

    return await updateStoreSettings(
      sellerId: sellerId,
      vacationMode: !settings.vacationMode,
      vacationMessage: message,
    );
  }

  // Delete seller data (for account deletion)
  Future<void> deleteSellerData(String sellerId) async {
    try {
      // Delete in order due to foreign key constraints
      await _supabase.storeSettings.delete().eq('seller_id', sellerId);
      await _supabase.sellerStatistics.delete().eq('seller_id', sellerId);
    } catch (e) {
      EnvironmentConfig.logError('Error deleting seller data', e);
      rethrow;
    }
  }
}