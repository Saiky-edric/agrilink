import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

/// Service for managing seller reviews and ratings
class ReviewService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Submit product reviews for an order
  Future<void> submitProductReviews({
    required String orderId,
    required String buyerId,
    required List<ProductReviewSubmission> productReviews,
  }) async {
    try {
      // Check if already reviewed
      final existingReviews = await _client
          .from('product_reviews')
          .select('id')
          .eq('user_id', buyerId)
          .inFilter('product_id', productReviews.map((r) => r.productId).toList());

      if (existingReviews.isNotEmpty) {
        throw Exception('You have already reviewed one or more of these products');
      }

      final storageService = StorageService.instance;
      
      // Process each review with images
      for (var review in productReviews) {
        List<String> imageUrls = [];
        
        // Upload images if provided
        if (review.images.isNotEmpty) {
          try {
            imageUrls = await storageService.uploadReviewImages(
              userId: buyerId,
              productId: review.productId,
              images: review.images,
            );
            debugPrint('Uploaded ${imageUrls.length} images for product ${review.productId}');
          } catch (e) {
            debugPrint('Error uploading review images: $e');
            // Continue without images if upload fails
          }
        }
        
        // Insert review with image URLs
        await _client.from('product_reviews').insert({
          'product_id': review.productId,
          'user_id': buyerId,
          'rating': review.rating,
          'review_text': review.reviewText,
          'image_urls': imageUrls.isNotEmpty ? imageUrls : null,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('Product reviews submitted successfully');
    } catch (e) {
      debugPrint('Error submitting product reviews: $e');
      throw Exception('Failed to submit product reviews: $e');
    }
  }

  /// Submit complete review (products + seller)
  Future<void> submitCompleteReview({
    required String orderId,
    required String buyerId,
    required String sellerId,
    required List<ProductReviewSubmission> productReviews,
    required int sellerRating,
    String? sellerReviewText,
    String sellerReviewType = 'general',
  }) async {
    try {
      // Submit product reviews
      await submitProductReviews(
        orderId: orderId,
        buyerId: buyerId,
        productReviews: productReviews,
      );

      // Submit seller review
      await submitSellerReview(
        sellerId: sellerId,
        buyerId: buyerId,
        orderId: orderId,
        rating: sellerRating,
        reviewText: sellerReviewText,
        reviewType: sellerReviewType,
        isVerifiedPurchase: true,
      );

      // Mark order as reviewed
      await _client.rpc('mark_order_as_reviewed', params: {
        'order_id_param': orderId,
      });

      debugPrint('Complete review submitted successfully');
    } catch (e) {
      debugPrint('Error submitting complete review: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Submit a review for a seller
  Future<void> submitSellerReview({
    required String sellerId,
    required String buyerId,
    String? orderId,
    required int rating,
    String? reviewText,
    String reviewType = 'general',
    bool isVerifiedPurchase = false,
  }) async {
    try {
      // Check if buyer has already reviewed this seller for this order
      if (orderId != null) {
        final existingReview = await _client
            .from('seller_reviews')
            .select('id')
            .eq('seller_id', sellerId)
            .eq('buyer_id', buyerId)
            .eq('order_id', orderId)
            .maybeSingle();

        if (existingReview != null) {
          throw Exception('You have already reviewed this seller for this order');
        }
      }

      // Insert the review
      await _client.from('seller_reviews').insert({
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'order_id': orderId,
        'rating': rating,
        'review_text': reviewText,
        'review_type': reviewType,
        'is_verified_purchase': isVerifiedPurchase,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update order review status if orderId provided (only for backward compatibility)
      // New system uses mark_order_as_reviewed() in submitCompleteReview()

      debugPrint('Seller review submitted successfully');
    } catch (e) {
      debugPrint('Error submitting review: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Get all reviews for a seller
  Future<List<SellerReviewModel>> getSellerReviews(
    String sellerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('seller_reviews')
          .select('''
            *,
            users!buyer_id (
              full_name,
              avatar_url
            ),
            orders (
              id,
              total_amount,
              created_at
            )
          ''')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<SellerReviewModel>((json) => SellerReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting seller reviews: $e');
      return [];
    }
  }

  /// Get review summary for a seller
  Future<ReviewSummary> getReviewSummary(String sellerId) async {
    try {
      final response = await _client
          .from('seller_reviews')
          .select('rating')
          .eq('seller_id', sellerId);

      if (response.isEmpty) {
        return ReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        );
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final totalReviews = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      // Calculate rating distribution
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating] = distribution[rating]! + 1;
      }

      return ReviewSummary(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: distribution,
      );
    } catch (e) {
      debugPrint('Error getting review summary: $e');
      return ReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }
  }

  /// Check if buyer can review seller for specific order
  Future<bool> canReviewSeller(String sellerId, String buyerId, String orderId) async {
    try {
      // Check if order exists and is completed
      final order = await _client
          .from('orders')
          .select('farmer_status, seller_reviewed')
          .eq('id', orderId)
          .eq('buyer_id', buyerId)
          .eq('farmer_id', sellerId)
          .maybeSingle();

      if (order == null) return false;

      // Only allow review for delivered orders that haven't been reviewed
      return order['farmer_status'] == 'delivered' && 
             order['seller_reviewed'] == false;
    } catch (e) {
      debugPrint('Error checking review eligibility: $e');
      return false;
    }
  }

  /// Get buyer's pending reviews (orders ready for review)
  Future<List<PendingReview>> getPendingReviews(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            id,
            farmer_id,
            total_amount,
            created_at,
            users!farmer_id (
              full_name,
              store_name,
              avatar_url
            )
          ''')
          .eq('buyer_id', buyerId)
          .eq('farmer_status', 'delivered')
          .eq('seller_reviewed', false);

      return response
          .map<PendingReview>((json) => PendingReview.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending reviews: $e');
      return [];
    }
  }

  /// Update review
  Future<void> updateReview({
    required String reviewId,
    required String buyerId,
    int? rating,
    String? reviewText,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) updateData['rating'] = rating;
      if (reviewText != null) updateData['review_text'] = reviewText;

      await _client
          .from('seller_reviews')
          .update(updateData)
          .eq('id', reviewId)
          .eq('buyer_id', buyerId);

      debugPrint('Review updated successfully');
    } catch (e) {
      debugPrint('Error updating review: $e');
      throw Exception('Failed to update review: $e');
    }
  }

  /// Delete review
  Future<void> deleteReview(String reviewId, String buyerId) async {
    try {
      await _client
          .from('seller_reviews')
          .delete()
          .eq('id', reviewId)
          .eq('buyer_id', buyerId);

      debugPrint('Review deleted successfully');
    } catch (e) {
      debugPrint('Error deleting review: $e');
      throw Exception('Failed to delete review: $e');
    }
  }
}

/// Model for seller review
// Helper class for product review submission
class ProductReviewSubmission {
  final String productId;
  final int rating;
  final String? reviewText;
  final List<File> images;

  ProductReviewSubmission({
    required this.productId,
    required this.rating,
    this.reviewText,
    this.images = const [],
  });
}

class SellerReviewModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String? orderId;
  final int rating;
  final String? reviewText;
  final String reviewType;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final BuyerInfo? buyerInfo;
  final OrderInfo? orderInfo;

  const SellerReviewModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    this.orderId,
    required this.rating,
    this.reviewText,
    required this.reviewType,
    required this.isVerifiedPurchase,
    required this.createdAt,
    this.buyerInfo,
    this.orderInfo,
  });

  factory SellerReviewModel.fromJson(Map<String, dynamic> json) {
    return SellerReviewModel(
      id: json['id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      buyerId: json['buyer_id'] ?? '',
      orderId: json['order_id'],
      rating: json['rating'] ?? 5,
      reviewText: json['review_text'],
      reviewType: json['review_type'] ?? 'general',
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      buyerInfo: json['users'] != null ? BuyerInfo.fromJson(json['users']) : null,
      orderInfo: json['orders'] != null ? OrderInfo.fromJson(json['orders']) : null,
    );
  }
}

/// Model for buyer information in reviews
class BuyerInfo {
  final String fullName;
  final String? avatarUrl;

  const BuyerInfo({
    required this.fullName,
    this.avatarUrl,
  });

  factory BuyerInfo.fromJson(Map<String, dynamic> json) {
    return BuyerInfo(
      fullName: json['full_name'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
    );
  }
}

/// Model for order information in reviews
class OrderInfo {
  final String id;
  final double totalAmount;
  final DateTime createdAt;

  const OrderInfo({
    required this.id,
    required this.totalAmount,
    required this.createdAt,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Model for review summary
class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });
}

/// Model for pending review
class PendingReview {
  final String orderId;
  final String farmerId;
  final double totalAmount;
  final DateTime createdAt;
  final String farmerName;
  final String? storeName;
  final String? farmerAvatar;

  const PendingReview({
    required this.orderId,
    required this.farmerId,
    required this.totalAmount,
    required this.createdAt,
    required this.farmerName,
    this.storeName,
    this.farmerAvatar,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    final farmerData = json['users'];
    return PendingReview(
      orderId: json['id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      farmerName: farmerData?['full_name'] ?? 'Unknown Farmer',
      storeName: farmerData?['store_name'],
      farmerAvatar: farmerData?['avatar_url'],
    );
  }
}