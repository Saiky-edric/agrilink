import 'package:equatable/equatable.dart';

enum ProductCategory {
  vegetables,
  fruits,
  grains,
  herbs,
  livestock,
  dairy,
  others
}

class ProductModel extends Equatable {
  final String id;
  final String farmerId;
  final String name;
  final double price;
  final int stock;
  final String unit;
  final int shelfLifeDays;
  final ProductCategory category;
  final String description;
  final String coverImageUrl;
  final List<String> additionalImageUrls;
  final String farmName;
  final String farmLocation;
  // Weight per unit in kilograms (for shipping calculations)
  final double weightPerUnitKg;
  // Seller store location derived from farmer profile
  final String? sellerMunicipality;
  final String? sellerBarangay;
  final bool isHidden;
  final String status; // 'active', 'expired', 'deleted'
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Rating and sales statistics
  final double averageRating;
  final int totalReviews;
  final int totalSold;
  final List<ProductReview> recentReviews;
  
  // Farmer premium status
  final bool farmerIsPremium;
  
  const ProductModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    required this.shelfLifeDays,
    required this.category,
    required this.description,
    required this.coverImageUrl,
    this.additionalImageUrls = const [],
    required this.farmName,
    required this.farmLocation,
    this.weightPerUnitKg = 0.0,
    this.sellerMunicipality,
    this.sellerBarangay,
    this.isHidden = false,
    this.status = 'active',
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalSold = 0,
    this.recentReviews = const [],
    this.farmerIsPremium = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final farmer = json['farmer'] as Map<String, dynamic>?;
    final muni = farmer != null ? farmer['municipality'] as String? : null;
    final brgy = farmer != null ? farmer['barangay'] as String? : null;
    
    // Check farmer premium status
    bool farmerIsPremium = false;
    if (farmer != null) {
      final subscriptionTier = farmer['subscription_tier'] ?? 'free';
      if (subscriptionTier == 'premium') {
        final expiresAt = farmer['subscription_expires_at'];
        if (expiresAt == null) {
          // Lifetime premium
          farmerIsPremium = true;
        } else {
          // Check if not expired
          final expiryDate = DateTime.tryParse(expiresAt);
          farmerIsPremium = expiryDate != null && expiryDate.isAfter(DateTime.now());
        }
      }
    }
    
    return ProductModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      unit: json['unit'] as String,
      shelfLifeDays: json['shelf_life_days'] as int,
      category: ProductCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => ProductCategory.others,
      ),
      description: json['description'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      additionalImageUrls: json['additional_image_urls'] != null
          ? List<String>.from(json['additional_image_urls'])
          : [],
      farmName: json['farm_name'] as String,
      farmLocation: json['farm_location'] as String,
      weightPerUnitKg: (json['weight_per_unit'] as num?)?.toDouble() ?? 0.0,
      sellerMunicipality: muni,
      sellerBarangay: brgy,
      isHidden: json['is_hidden'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      totalSold: json['total_sold'] as int? ?? 0,
      recentReviews: json['recent_reviews'] != null
          ? (json['recent_reviews'] as List)
              .map((r) => ProductReview.fromJson(r))
              .toList()
          : [],
      farmerIsPremium: farmerIsPremium,
    );
  }

  String get storeLocation {
    final muni = sellerMunicipality?.trim() ?? '';
    final brgy = sellerBarangay?.trim() ?? '';
    final composed = [muni, brgy].where((s) => s.isNotEmpty).join(', ');
    return composed.isNotEmpty ? composed : farmLocation;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'name': name,
      'price': price,
      'stock': stock,
      'unit': unit,
      'shelf_life_days': shelfLifeDays,
      'category': category.name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'additional_image_urls': additionalImageUrls,
      'farm_name': farmName,
      'farm_location': farmLocation,
      'seller_municipality': sellerMunicipality,
      'seller_barangay': sellerBarangay,
      'weight_per_unit': weightPerUnitKg,
      'is_hidden': isHidden,
      'status': status,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? name,
    double? price,
    int? stock,
    String? unit,
    int? shelfLifeDays,
    ProductCategory? category,
    String? description,
    String? coverImageUrl,
    List<String>? additionalImageUrls,
    String? farmName,
    String? farmLocation,
    double? weightPerUnitKg,
    bool? isHidden,
    String? status,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? averageRating,
    int? totalReviews,
    int? totalSold,
    List<ProductReview>? recentReviews,
    bool? farmerIsPremium,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      category: category ?? this.category,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      weightPerUnitKg: weightPerUnitKg ?? this.weightPerUnitKg,
      isHidden: isHidden ?? this.isHidden,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSold: totalSold ?? this.totalSold,
      recentReviews: recentReviews ?? this.recentReviews,
      farmerIsPremium: farmerIsPremium ?? this.farmerIsPremium,
    );
  }

  bool get isInStock => stock > 0;
  
  DateTime get expiryDate => createdAt.add(Duration(days: shelfLifeDays));
  
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiryDate);
  
  bool get isDeleted => status == 'deleted' || deletedAt != null;
  
  bool get isActive => status == 'active' && !isDeleted && !isExpired;
  
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  
  bool get isExpiringWithin24Hours => daysUntilExpiry <= 1 && daysUntilExpiry >= 0;
  
  bool get isExpiringWithin3Days => daysUntilExpiry <= 3 && daysUntilExpiry >= 0;

  String get categoryDisplayName {
    switch (category) {
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.grains:
        return 'Grains';
      case ProductCategory.herbs:
        return 'Herbs';
      case ProductCategory.livestock:
        return 'Livestock';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.others:
        return 'Others';
    }
  }

  String get priceDisplay => '₱${price.toStringAsFixed(2)} / $unit';

  @override
  List<Object?> get props => [
        id,
        farmerId,
        name,
        price,
        stock,
        unit,
        shelfLifeDays,
        category,
        description,
        coverImageUrl,
        additionalImageUrls,
        farmName,
        farmLocation,
        isHidden,
        status,
        deletedAt,
        createdAt,
        updatedAt,
        weightPerUnitKg,
        averageRating,
        totalReviews,
        totalSold,
        recentReviews,
        farmerIsPremium,
      ];
}

/// Product review model
class ProductReview {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String? reviewText;
  final List<String> imageUrls;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.reviewText,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    // Handle rating as both int and string (database inconsistency fix)
    final ratingValue = json['rating'];
    int rating = 0;
    if (ratingValue is int) {
      rating = ratingValue;
    } else if (ratingValue is String) {
      rating = int.tryParse(ratingValue) ?? 0;
    }
    
    return ProductReview(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: user?['full_name'] as String? ?? 'Anonymous',
      userAvatar: user?['avatar_url'] as String?,
      rating: rating,
      reviewText: json['review_text'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.grains:
        return 'Grains';
      case ProductCategory.herbs:
        return 'Herbs';
      case ProductCategory.livestock:
        return 'Livestock';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.others:
        return 'Others';
    }
  }
}