import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum BuyerOrderStatus { pending, toShip, toReceive, completed, cancelled }
enum FarmerOrderStatus { newOrder, accepted, toPack, toDeliver, readyForPickup, completed, cancelled }

class OrderModel extends Equatable {
  final String id;
  final String buyerId;
  final String farmerId;
  final double totalAmount;
  final String deliveryAddress;
  final String? specialInstructions;
  final BuyerOrderStatus buyerStatus;
  final FarmerOrderStatus farmerStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? trackingNumber;
  final DateTime? deliveryDate;
  final String? deliveryNotes;
  final List<OrderItemModel> items;
  final UserModel? buyerProfile;
  final UserModel? farmerProfile;
  // Optional DB amounts for accurate summaries
  final double? subtotal;
  final double? deliveryFee;
  final double? serviceFee;
  // Pickup option fields
  final String deliveryMethod; // 'delivery' or 'pickup'
  final String? pickupAddress;
  final String? pickupInstructions;
  // Payment method
  final String? paymentMethod; // 'cod', 'cop', 'gcash', 'card'
  // Review tracking
  final bool buyerReviewed;
  final bool reviewReminderSent;
  // Payment proof fields (for GCash)
  final String? paymentScreenshotUrl;
  final String? paymentReference;
  final bool? paymentVerified;
  final DateTime? paymentVerifiedAt;
  final String? paymentVerifiedBy;
  final String? paymentNotes;
  // Refund fields
  final bool refundRequested;
  final String? refundStatus;
  final DateTime? refundedAt;
  final double? refundedAmount;
  
  // Individual status timestamps for precise tracking
  final DateTime? acceptedAt;
  final DateTime? toPackAt;
  final DateTime? toDeliverAt;
  final DateTime? readyForPickupAt;
  final DateTime? cancelledAt;
  
  // Estimated delivery tracking
  final DateTime? estimatedDeliveryAt;
  final DateTime? estimatedPickupAt;
  
  // Real-time delivery tracking
  final DateTime? deliveryStartedAt;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final DateTime? deliveryLastUpdatedAt;
  
  // Location coordinates
  final double? farmerLatitude;
  final double? farmerLongitude;
  final double? buyerLatitude;
  final double? buyerLongitude;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.totalAmount,
    required this.deliveryAddress,
    this.specialInstructions,
    required this.buyerStatus,
    required this.farmerStatus,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.trackingNumber,
    this.deliveryDate,
    this.deliveryNotes,
    this.items = const [],
    this.buyerProfile,
    this.farmerProfile,
    this.subtotal,
    this.deliveryFee,
    this.serviceFee,
    this.deliveryMethod = 'delivery', // Default to delivery for backward compatibility
    this.pickupAddress,
    this.pickupInstructions,
    this.paymentMethod,
    this.buyerReviewed = false,
    this.reviewReminderSent = false,
    this.paymentScreenshotUrl,
    this.paymentReference,
    this.paymentVerified,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy,
    this.paymentNotes,
    this.refundRequested = false,
    this.refundStatus,
    this.refundedAt,
    this.refundedAmount,
    this.acceptedAt,
    this.toPackAt,
    this.toDeliverAt,
    this.readyForPickupAt,
    this.cancelledAt,
    this.estimatedDeliveryAt,
    this.estimatedPickupAt,
    this.deliveryStartedAt,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryLastUpdatedAt,
    this.farmerLatitude,
    this.farmerLongitude,
    this.buyerLatitude,
    this.buyerLongitude,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      farmerId: json['farmer_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as String,
      specialInstructions: json['special_instructions'] as String?,
      buyerStatus: BuyerOrderStatus.values.firstWhere(
        (status) => status.name == json['buyer_status'],
        orElse: () => BuyerOrderStatus.pending,
      ),
      farmerStatus: FarmerOrderStatus.values.firstWhere(
        (status) => status.name == json['farmer_status'],
        orElse: () => FarmerOrderStatus.newOrder,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      trackingNumber: json['tracking_number'] as String?,
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      deliveryNotes: json['delivery_notes'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble(),
      deliveryMethod: json['delivery_method'] as String? ?? 'delivery',
      pickupAddress: json['pickup_address'] as String?,
      pickupInstructions: json['pickup_instructions'] as String?,
      paymentMethod: json['payment_method'] as String?,
      buyerReviewed: (json['buyer_reviewed'] as bool?) ?? false,
      reviewReminderSent: (json['review_reminder_sent'] as bool?) ?? false,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      paymentReference: json['payment_reference'] as String?,
      paymentVerified: json['payment_verified'] as bool?,
      paymentVerifiedAt: json['payment_verified_at'] != null 
          ? DateTime.parse(json['payment_verified_at']) 
          : null,
      paymentVerifiedBy: json['payment_verified_by'] as String?,
      paymentNotes: json['payment_notes'] as String?,
      refundRequested: (json['refund_requested'] as bool?) ?? false,
      refundStatus: json['refund_status'] as String?,
      refundedAt: json['refunded_at'] != null ? DateTime.parse(json['refunded_at']) : null,
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      toPackAt: json['to_pack_at'] != null ? DateTime.parse(json['to_pack_at']) : null,
      toDeliverAt: json['to_deliver_at'] != null ? DateTime.parse(json['to_deliver_at']) : null,
      readyForPickupAt: json['ready_for_pickup_at'] != null ? DateTime.parse(json['ready_for_pickup_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      estimatedDeliveryAt: json['estimated_delivery_at'] != null ? DateTime.parse(json['estimated_delivery_at']) : null,
      estimatedPickupAt: json['estimated_pickup_at'] != null ? DateTime.parse(json['estimated_pickup_at']) : null,
      deliveryStartedAt: json['delivery_started_at'] != null ? DateTime.parse(json['delivery_started_at']) : null,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      deliveryLastUpdatedAt: json['delivery_last_updated_at'] != null ? DateTime.parse(json['delivery_last_updated_at']) : null,
      farmerLatitude: (json['farmer_latitude'] as num?)?.toDouble(),
      farmerLongitude: (json['farmer_longitude'] as num?)?.toDouble(),
      buyerLatitude: (json['buyer_latitude'] as num?)?.toDouble(),
      buyerLongitude: (json['buyer_longitude'] as num?)?.toDouble(),
      buyerProfile: json['buyer'] != null ? UserModel.fromJson(json['buyer']) : null,
      farmerProfile: json['farmer'] != null ? UserModel.fromJson(json['farmer']) : null,
      items: (json['items'] ?? json['order_items']) != null
          ? ((json['items'] ?? json['order_items']) as List)
              .map((item) => OrderItemModel.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'special_instructions': specialInstructions,
      'buyer_status': buyerStatus.name,
      'farmer_status': farmerStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'delivery_method': deliveryMethod,
      'pickup_address': pickupAddress,
      'pickup_instructions': pickupInstructions,
      'payment_method': paymentMethod,
      'buyer_reviewed': buyerReviewed,
      'review_reminder_sent': reviewReminderSent,
      'payment_screenshot_url': paymentScreenshotUrl,
      'payment_reference': paymentReference,
      'payment_verified': paymentVerified,
      'payment_verified_at': paymentVerifiedAt?.toIso8601String(),
      'payment_verified_by': paymentVerifiedBy,
      'payment_notes': paymentNotes,
      'refund_requested': refundRequested,
      'refund_status': refundStatus,
      'refunded_at': refundedAt?.toIso8601String(),
      'refunded_amount': refundedAmount,
    };
  }

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? farmerId,
    double? totalAmount,
    String? deliveryAddress,
    String? specialInstructions,
    BuyerOrderStatus? buyerStatus,
    FarmerOrderStatus? farmerStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    String? deliveryMethod,
    String? pickupAddress,
    String? pickupInstructions,
    String? paymentMethod,
    bool? buyerReviewed,
    bool? reviewReminderSent,
    String? paymentScreenshotUrl,
    String? paymentReference,
    bool? paymentVerified,
    DateTime? paymentVerifiedAt,
    String? paymentVerifiedBy,
    String? paymentNotes,
    bool? refundRequested,
    String? refundStatus,
    DateTime? refundedAt,
    double? refundedAmount,
    DateTime? acceptedAt,
    DateTime? toPackAt,
    DateTime? toDeliverAt,
    DateTime? readyForPickupAt,
    DateTime? cancelledAt,
    DateTime? estimatedDeliveryAt,
    DateTime? estimatedPickupAt,
    DateTime? deliveryStartedAt,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? deliveryLastUpdatedAt,
    double? farmerLatitude,
    double? farmerLongitude,
    double? buyerLatitude,
    double? buyerLongitude,
    String? trackingNumber,
    DateTime? deliveryDate,
    String? deliveryNotes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      buyerStatus: buyerStatus ?? this.buyerStatus,
      farmerStatus: farmerStatus ?? this.farmerStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      items: items ?? this.items,
      buyerProfile: buyerProfile,
      farmerProfile: farmerProfile,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      buyerReviewed: buyerReviewed ?? this.buyerReviewed,
      reviewReminderSent: reviewReminderSent ?? this.reviewReminderSent,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      paymentVerifiedBy: paymentVerifiedBy ?? this.paymentVerifiedBy,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      refundRequested: refundRequested ?? this.refundRequested,
      refundStatus: refundStatus ?? this.refundStatus,
      refundedAt: refundedAt ?? this.refundedAt,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      toPackAt: toPackAt ?? this.toPackAt,
      toDeliverAt: toDeliverAt ?? this.toDeliverAt,
      readyForPickupAt: readyForPickupAt ?? this.readyForPickupAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      estimatedDeliveryAt: estimatedDeliveryAt ?? this.estimatedDeliveryAt,
      estimatedPickupAt: estimatedPickupAt ?? this.estimatedPickupAt,
      deliveryStartedAt: deliveryStartedAt ?? this.deliveryStartedAt,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryLastUpdatedAt: deliveryLastUpdatedAt ?? this.deliveryLastUpdatedAt,
      farmerLatitude: farmerLatitude ?? this.farmerLatitude,
      farmerLongitude: farmerLongitude ?? this.farmerLongitude,
      buyerLatitude: buyerLatitude ?? this.buyerLatitude,
      buyerLongitude: buyerLongitude ?? this.buyerLongitude,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
    );
  }

  String get buyerStatusDisplayName {
    switch (buyerStatus) {
      case BuyerOrderStatus.pending:
        return 'Pending';
      case BuyerOrderStatus.toShip:
        return 'To Ship';
      case BuyerOrderStatus.toReceive:
        return 'To Receive';
      case BuyerOrderStatus.completed:
        return 'Completed';
      case BuyerOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get farmerStatusDisplayName {
    switch (farmerStatus) {
      case FarmerOrderStatus.newOrder:
        return 'New Order';
      case FarmerOrderStatus.accepted:
        return 'Accepted';
      case FarmerOrderStatus.toPack:
        return 'To Pack';
      case FarmerOrderStatus.toDeliver:
        return 'To Deliver';
      case FarmerOrderStatus.readyForPickup:
        return 'Ready for Pick-up';
      case FarmerOrderStatus.completed:
        return 'Completed';
      case FarmerOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Helper getter to check if order is pickup
  bool get isPickup => deliveryMethod == 'pickup';
  
  // Helper getter to check if order is delivery
  bool get isDelivery => deliveryMethod == 'delivery';

  @override
  List<Object?> get props => [
        id,
        buyerId,
        farmerId,
        totalAmount,
        deliveryAddress,
        specialInstructions,
        buyerStatus,
        farmerStatus,
        createdAt,
        updatedAt,
        completedAt,
        items,
        deliveryMethod,
        pickupAddress,
        pickupInstructions,
        paymentMethod,
        buyerReviewed,
        reviewReminderSent,
        paymentScreenshotUrl,
        paymentReference,
        paymentVerified,
        paymentVerifiedAt,
        paymentVerifiedBy,
        paymentNotes,
        refundRequested,
        refundStatus,
        refundedAt,
        refundedAmount,
        acceptedAt,
        toPackAt,
        toDeliverAt,
        readyForPickupAt,
        cancelledAt,
        estimatedDeliveryAt,
        estimatedPickupAt,
        deliveryStartedAt,
        deliveryLatitude,
        deliveryLongitude,
        deliveryLastUpdatedAt,
        farmerLatitude,
        farmerLongitude,
        buyerLatitude,
        buyerLongitude,
      ];
}

class OrderItemModel extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String unit;
  final double subtotal;
  // Optional joined image URL from products.cover_image_url
  final String? productImageUrl;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.subtotal,
    this.productImageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final coverImageFromProduct = product != null ? product['cover_image_url'] as String? : null;
    final coverImageFlat = json['cover_image_url'] as String?;

    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      productImageUrl: coverImageFromProduct ?? coverImageFlat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'subtotal': subtotal,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        unitPrice,
        quantity,
        unit,
        subtotal,
        productImageUrl,
      ];
}
