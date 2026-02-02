import 'package:equatable/equatable.dart';

enum TransactionType {
  payment,
  refund,
  cancellation,
}

enum TransactionStatus {
  pending,
  completed,
  processing,
  failed,
  cancelled,
}

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final String orderId;
  final String? orderNumber;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String paymentMethod; // 'gcash', 'cod', 'cop'
  final String? paymentScreenshotUrl;
  final String? paymentReference;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? refundedBy; // Admin user ID who processed refund
  final String? refundReason;
  final String? refundNotes;
  
  // Buyer and order details for display
  final String? buyerName;
  final String? buyerEmail;
  final String? farmerName;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.orderId,
    this.orderNumber,
    required this.type,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    this.paymentScreenshotUrl,
    this.paymentReference,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.refundedBy,
    this.refundReason,
    this.refundNotes,
    this.buyerName,
    this.buyerEmail,
    this.farmerName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String?,
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TransactionType.payment,
      ),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      paymentReference: json['payment_reference'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      refundedBy: json['refunded_by'] as String?,
      refundReason: json['refund_reason'] as String?,
      refundNotes: json['refund_notes'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      farmerName: json['farmer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'order_number': orderNumber,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_screenshot_url': paymentScreenshotUrl,
      'payment_reference': paymentReference,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'refunded_by': refundedBy,
      'refund_reason': refundReason,
      'refund_notes': refundNotes,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    String? orderNumber,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? paymentMethod,
    String? paymentScreenshotUrl,
    String? paymentReference,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? refundedBy,
    String? refundReason,
    String? refundNotes,
    String? buyerName,
    String? buyerEmail,
    String? farmerName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedBy: refundedBy ?? this.refundedBy,
      refundReason: refundReason ?? this.refundReason,
      refundNotes: refundNotes ?? this.refundNotes,
      buyerName: buyerName ?? this.buyerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      farmerName: farmerName ?? this.farmerName,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.cancellation:
        return 'Cancellation';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        orderId,
        orderNumber,
        type,
        status,
        amount,
        paymentMethod,
        paymentScreenshotUrl,
        paymentReference,
        description,
        createdAt,
        completedAt,
        refundedBy,
        refundReason,
        refundNotes,
      ];
}

class RefundRequestModel extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final String? transactionId;
  final double amount;
  final String reason;
  final String? additionalDetails;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? adminNotes;
  
  // Related data
  final String? orderNumber;
  final String? buyerName;
  final String? buyerEmail;
  final String? paymentMethod;
  final String? paymentScreenshotUrl;

  const RefundRequestModel({
    required this.id,
    required this.orderId,
    required this.userId,
    this.transactionId,
    required this.amount,
    required this.reason,
    this.additionalDetails,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
    this.adminNotes,
    this.orderNumber,
    this.buyerName,
    this.buyerEmail,
    this.paymentMethod,
    this.paymentScreenshotUrl,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    return RefundRequestModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      additionalDetails: json['additional_details'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      processedAt: json['processed_at'] != null 
          ? DateTime.parse(json['processed_at']) 
          : null,
      processedBy: json['processed_by'] as String?,
      adminNotes: json['admin_notes'] as String?,
      orderNumber: json['order_number'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      paymentMethod: json['payment_method'] as String?,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'transaction_id': transactionId,
      'amount': amount,
      'reason': reason,
      'additional_details': additionalDetails,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'processed_by': processedBy,
      'admin_notes': adminNotes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        transactionId,
        amount,
        reason,
        additionalDetails,
        status,
        createdAt,
        processedAt,
        processedBy,
        adminNotes,
      ];
}
