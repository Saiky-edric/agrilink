import 'package:equatable/equatable.dart';

/// Model for followed store information
class FollowedStore extends Equatable {
  final String sellerId;
  final String sellerName;
  final String storeName;
  final String? storeLogoUrl;
  final String location;
  final String description;
  final bool isVerified;
  final bool isStoreOpen;
  final double averageRating;
  final int totalReviews;
  final int totalProducts;
  final DateTime followedAt;

  const FollowedStore({
    required this.sellerId,
    required this.sellerName,
    required this.storeName,
    this.storeLogoUrl,
    required this.location,
    required this.description,
    required this.isVerified,
    required this.isStoreOpen,
    required this.averageRating,
    required this.totalReviews,
    required this.totalProducts,
    required this.followedAt,
  });

  factory FollowedStore.fromJson(Map<String, dynamic> json) {
    final sellerData = json['users'] ?? {};
    final statsDataRaw = json['seller_statistics'] ?? (json['users'] != null ? json['users']['seller_statistics'] : null) ?? {};
    final statsData = Map<String, dynamic>.from(statsDataRaw);
    
    return FollowedStore(
      sellerId: json['seller_id'] ?? '',
      sellerName: sellerData['full_name'] ?? '',
      storeName: sellerData['store_name'] ?? sellerData['full_name'] ?? 'Unknown Store',
      storeLogoUrl: sellerData['store_logo_url'] ?? sellerData['avatar_url'],
      location: '${sellerData['municipality'] ?? ''}, ${sellerData['barangay'] ?? ''}'
          .trim()
          .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
      description: sellerData['store_description'] ?? '',
      isVerified: json['verification_status'] == 'approved',
      isStoreOpen: sellerData['is_store_open'] ?? true,
      averageRating: (statsData['average_rating'] ?? 0.0).toDouble(),
      totalReviews: statsData['total_reviews'] ?? 0,
      totalProducts: statsData['total_products'] ?? 0,
      followedAt: DateTime.parse(json['followed_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'seller_name': sellerName,
      'store_name': storeName,
      'store_logo_url': storeLogoUrl,
      'location': location,
      'description': description,
      'is_verified': isVerified,
      'is_store_open': isStoreOpen,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'total_products': totalProducts,
      'followed_at': followedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        sellerId,
        sellerName,
        storeName,
        storeLogoUrl,
        location,
        description,
        isVerified,
        isStoreOpen,
        averageRating,
        totalReviews,
        totalProducts,
        followedAt,
      ];
}