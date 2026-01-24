// Payout Request Model
// Represents a farmer's request to withdraw earnings

class PayoutRequest {
  final String id;
  final String farmerId;
  final double amount;
  final PayoutStatus status;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic> paymentDetails;
  final String? requestNotes;
  final String? adminNotes;
  final String? rejectionReason;
  final String? processedBy;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display
  final String? farmerName;
  final String? farmerStoreName;
  final String? processedByName;

  const PayoutRequest({
    required this.id,
    required this.farmerId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.paymentDetails,
    this.requestNotes,
    this.adminNotes,
    this.rejectionReason,
    this.processedBy,
    required this.requestedAt,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    this.farmerName,
    this.farmerStoreName,
    this.processedByName,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: PayoutStatus.fromString(json['status'] as String),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String),
      paymentDetails: json['payment_details'] as Map<String, dynamic>? ?? {},
      requestNotes: json['request_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      processedBy: json['processed_by'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] != null 
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      farmerName: json['farmer_name'] as String?,
      farmerStoreName: json['farmer_store_name'] as String?,
      processedByName: json['processed_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'amount': amount,
      'status': status.value,
      'payment_method': paymentMethod.value,
      'payment_details': paymentDetails,
      'request_notes': requestNotes,
      'admin_notes': adminNotes,
      'rejection_reason': rejectionReason,
      'processed_by': processedBy,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PayoutRequest copyWith({
    String? id,
    String? farmerId,
    double? amount,
    PayoutStatus? status,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? requestNotes,
    String? adminNotes,
    String? rejectionReason,
    String? processedBy,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmerName,
    String? farmerStoreName,
    String? processedByName,
  }) {
    return PayoutRequest(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      requestNotes: requestNotes ?? this.requestNotes,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      processedBy: processedBy ?? this.processedBy,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmerName: farmerName ?? this.farmerName,
      farmerStoreName: farmerStoreName ?? this.farmerStoreName,
      processedByName: processedByName ?? this.processedByName,
    );
  }

  // Helper getters
  String get statusDisplayName => status.displayName;
  String get paymentMethodDisplayName => paymentMethod.displayName;
  
  String get accountNumber {
    if (paymentMethod == PaymentMethod.gcash) {
      return paymentDetails['gcash_number'] ?? '';
    } else {
      return paymentDetails['bank_account_number'] ?? '';
    }
  }

  String get accountName {
    if (paymentMethod == PaymentMethod.gcash) {
      return paymentDetails['gcash_name'] ?? '';
    } else {
      return paymentDetails['bank_account_name'] ?? '';
    }
  }

  String? get bankName => paymentDetails['bank_name'] as String?;

  bool get isPending => status == PayoutStatus.pending;
  bool get isProcessing => status == PayoutStatus.processing;
  bool get isCompleted => status == PayoutStatus.completed;
  bool get isRejected => status == PayoutStatus.rejected;
  bool get canCancel => status == PayoutStatus.pending;
}

// Payout Status Enum
enum PayoutStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  rejected('rejected');

  final String value;
  const PayoutStatus(this.value);

  static PayoutStatus fromString(String value) {
    return PayoutStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PayoutStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.rejected:
        return 'Rejected';
    }
  }
}

// Payment Method Enum
enum PaymentMethod {
  gcash('gcash'),
  bankTransfer('bank_transfer');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.gcash,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

// Payout Log Model
class PayoutLog {
  final String id;
  final String payoutRequestId;
  final PayoutAction action;
  final String? performedBy;
  final String? performedByName;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const PayoutLog({
    required this.id,
    required this.payoutRequestId,
    required this.action,
    this.performedBy,
    this.performedByName,
    this.notes,
    required this.metadata,
    required this.createdAt,
  });

  factory PayoutLog.fromJson(Map<String, dynamic> json) {
    return PayoutLog(
      id: json['id'] as String,
      payoutRequestId: json['payout_request_id'] as String,
      action: PayoutAction.fromString(json['action'] as String),
      performedBy: json['performed_by'] as String?,
      performedByName: json['performed_by_name'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payout_request_id': payoutRequestId,
      'action': action.value,
      'performed_by': performedBy,
      'notes': notes,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionDisplayName => action.displayName;
}

// Payout Action Enum
enum PayoutAction {
  requested('requested'),
  approved('approved'),
  rejected('rejected'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const PayoutAction(this.value);

  static PayoutAction fromString(String value) {
    return PayoutAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => PayoutAction.requested,
    );
  }

  String get displayName {
    switch (this) {
      case PayoutAction.requested:
        return 'Requested';
      case PayoutAction.approved:
        return 'Approved';
      case PayoutAction.rejected:
        return 'Rejected';
      case PayoutAction.completed:
        return 'Completed';
      case PayoutAction.cancelled:
        return 'Cancelled';
    }
  }
}

// Farmer Wallet Summary Model
class FarmerWalletSummary {
  final String farmerId;
  final String farmerName;
  final String? storeName;
  final double availableBalance;
  final double pendingEarnings;
  final double totalPaidOut;
  final int pendingRequestsCount;

  const FarmerWalletSummary({
    required this.farmerId,
    required this.farmerName,
    this.storeName,
    required this.availableBalance,
    required this.pendingEarnings,
    required this.totalPaidOut,
    required this.pendingRequestsCount,
  });

  factory FarmerWalletSummary.fromJson(Map<String, dynamic> json) {
    return FarmerWalletSummary(
      farmerId: json['farmer_id'] as String,
      farmerName: json['full_name'] as String,
      storeName: json['store_name'] as String?,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pending_earnings'] as num?)?.toDouble() ?? 0.0,
      totalPaidOut: (json['total_paid_out'] as num?)?.toDouble() ?? 0.0,
      pendingRequestsCount: json['pending_requests_count'] as int? ?? 0,
    );
  }

  double get totalEarnings => availableBalance + pendingEarnings + totalPaidOut;

  bool get canRequestPayout => availableBalance >= 100.0; // Minimum ₱100
}
