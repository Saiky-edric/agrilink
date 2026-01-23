import 'package:equatable/equatable.dart';

/// Model for pending reviews that need to be submitted by buyers
class PendingReview extends Equatable {
  final String orderId;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String productName;
  final DateTime orderDate;
  final double orderAmount;
  final bool isReviewSubmitted;
  final DateTime? reviewDeadline;

  const PendingReview({
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl,
    required this.productName,
    required this.orderDate,
    required this.orderAmount,
    this.isReviewSubmitted = false,
    this.reviewDeadline,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    final orderData = json['orders'] ?? json;
    final sellerData = json['seller'] ?? json['users'] ?? {};
    final itemData = json['order_items'] ?? [];
    
    // Get first product name from order items
    String productName = 'Order';
    if (itemData is List && itemData.isNotEmpty) {
      productName = itemData[0]['product_name'] ?? 'Order';
    }

    return PendingReview(
      orderId: orderData['id'] ?? json['order_id'] ?? '',
      sellerId: orderData['farmer_id'] ?? json['seller_id'] ?? '',
      sellerName: sellerData['full_name'] ?? sellerData['store_name'] ?? 'Unknown Seller',
      sellerAvatarUrl: sellerData['avatar_url'] ?? sellerData['store_logo_url'],
      productName: productName,
      orderDate: DateTime.parse(orderData['created_at'] ?? DateTime.now().toIso8601String()),
      orderAmount: (orderData['total_amount'] ?? 0).toDouble(),
      isReviewSubmitted: json['is_review_submitted'] ?? false,
      reviewDeadline: json['review_deadline'] != null 
          ? DateTime.parse(json['review_deadline'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_avatar_url': sellerAvatarUrl,
      'product_name': productName,
      'order_date': orderDate.toIso8601String(),
      'order_amount': orderAmount,
      'is_review_submitted': isReviewSubmitted,
      'review_deadline': reviewDeadline?.toIso8601String(),
    };
  }

  bool get isOverdue {
    if (reviewDeadline == null) return false;
    return DateTime.now().isAfter(reviewDeadline!) && !isReviewSubmitted;
  }

  int get daysUntilDeadline {
    if (reviewDeadline == null) return 0;
    return reviewDeadline!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        orderId,
        sellerId,
        sellerName,
        sellerAvatarUrl,
        productName,
        orderDate,
        orderAmount,
        isReviewSubmitted,
        reviewDeadline,
      ];
}