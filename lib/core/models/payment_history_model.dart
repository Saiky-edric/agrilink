import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,      // GCash uploaded, awaiting verification
  verified,     // Admin confirmed payment
  rejected,     // Admin rejected payment proof
  delivered,    // COD/COP - paid on delivery
  refunded,     // Money returned
  cancelled,    // Order cancelled before payment verified
}

class PaymentHistoryItem extends Equatable {
  final String orderId;
  final DateTime orderDate;
  final String paymentMethod;
  final double amount;
  final PaymentStatus status;
  final String? reference;
  final String? screenshotUrl;
  final bool hasRefund;
  final double? refundedAmount;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? notes;
  final String? farmerName;
  final int itemCount;

  const PaymentHistoryItem({
    required this.orderId,
    required this.orderDate,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.reference,
    this.screenshotUrl,
    this.hasRefund = false,
    this.refundedAmount,
    this.verifiedAt,
    this.verifiedBy,
    this.notes,
    this.farmerName,
    this.itemCount = 0,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    // Determine payment status
    PaymentStatus status;
    final paymentMethod = (json['payment_method'] as String?)?.toLowerCase();
    final farmerStatus = json['farmer_status'] as String?;
    final paymentVerified = json['payment_verified'] as bool?;
    final refundedAmount = json['refunded_amount'];

    if (refundedAmount != null) {
      status = PaymentStatus.refunded;
    } else if (paymentMethod == 'cod' || paymentMethod == 'cop') {
      if (farmerStatus == 'completed') {
        status = PaymentStatus.delivered;
      } else if (farmerStatus == 'cancelled') {
        status = PaymentStatus.cancelled;
      } else {
        status = PaymentStatus.pending;
      }
    } else if (paymentMethod == 'gcash') {
      if (paymentVerified == true) {
        status = PaymentStatus.verified;
      } else if (paymentVerified == false) {
        status = PaymentStatus.rejected;
      } else if (farmerStatus == 'cancelled') {
        status = PaymentStatus.cancelled;
      } else {
        status = PaymentStatus.pending;
      }
    } else {
      status = PaymentStatus.pending;
    }

    return PaymentHistoryItem(
      orderId: json['id'] as String,
      orderDate: DateTime.parse(json['created_at']),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      amount: (json['total_amount'] as num).toDouble(),
      status: status,
      reference: json['payment_reference'] as String?,
      screenshotUrl: json['payment_screenshot_url'] as String?,
      hasRefund: refundedAmount != null,
      refundedAmount: (refundedAmount as num?)?.toDouble(),
      verifiedAt: json['payment_verified_at'] != null
          ? DateTime.parse(json['payment_verified_at'])
          : null,
      verifiedBy: json['payment_verified_by'] as String?,
      notes: json['payment_notes'] as String?,
      farmerName: json['farmer_name'] as String?,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending Verification';
      case PaymentStatus.verified:
        return 'Payment Verified';
      case PaymentStatus.rejected:
        return 'Payment Rejected';
      case PaymentStatus.delivered:
        return 'Paid on Delivery';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'cop':
        return 'Cash on Pickup';
      case 'gcash':
        return 'GCash';
      default:
        return paymentMethod.toUpperCase();
    }
  }

  @override
  List<Object?> get props => [
        orderId,
        orderDate,
        paymentMethod,
        amount,
        status,
        reference,
        screenshotUrl,
        hasRefund,
        refundedAmount,
        verifiedAt,
        verifiedBy,
        notes,
      ];
}

class PaymentSummary {
  final double totalPaid;
  final double pendingVerification;
  final double verified;
  final double refunded;
  final int totalPayments;
  final int pendingCount;
  final int verifiedCount;
  final int refundedCount;
  final Map<String, double> paymentMethodBreakdown;

  PaymentSummary({
    required this.totalPaid,
    required this.pendingVerification,
    required this.verified,
    required this.refunded,
    required this.totalPayments,
    required this.pendingCount,
    required this.verifiedCount,
    required this.refundedCount,
    required this.paymentMethodBreakdown,
  });

  factory PaymentSummary.fromPayments(List<PaymentHistoryItem> payments) {
    double totalPaid = 0;
    double pendingVerification = 0;
    double verified = 0;
    double refunded = 0;
    int pendingCount = 0;
    int verifiedCount = 0;
    int refundedCount = 0;
    Map<String, double> paymentMethodBreakdown = {};

    for (var payment in payments) {
      totalPaid += payment.amount;

      // Count by status
      switch (payment.status) {
        case PaymentStatus.pending:
          pendingVerification += payment.amount;
          pendingCount++;
          break;
        case PaymentStatus.verified:
        case PaymentStatus.delivered:
          verified += payment.amount;
          verifiedCount++;
          break;
        case PaymentStatus.refunded:
          refunded += payment.refundedAmount ?? payment.amount;
          refundedCount++;
          break;
        default:
          break;
      }

      // Count by payment method
      final method = payment.paymentMethodDisplayName;
      paymentMethodBreakdown[method] = 
          (paymentMethodBreakdown[method] ?? 0) + payment.amount;
    }

    return PaymentSummary(
      totalPaid: totalPaid,
      pendingVerification: pendingVerification,
      verified: verified,
      refunded: refunded,
      totalPayments: payments.length,
      pendingCount: pendingCount,
      verifiedCount: verifiedCount,
      refundedCount: refundedCount,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }
}
