import 'package:equatable/equatable.dart';

class PaymentMethodModel extends Equatable {
  final String id;
  final String userId;
  final String cardType;
  final String lastFourDigits;
  final int expiryMonth;
  final int expiryYear;
  final String cardholderName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get masked card number (e.g., "**** **** **** 1234")
  String get maskedNumber => '**** **** **** $lastFourDigits';

  /// Get expiry date (e.g., "12/25")
  String get expiryDate {
    final yearStr = expiryYear.toString().substring(2);
    return '$expiryMonth/$yearStr';
  }

  /// Get full expiry display (e.g., "Expires 12/25")
  String get expiryDisplay => 'Expires $expiryDate';

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardType: json['card_type'] as String,
      lastFourDigits: json['last_four_digits'] as String,
      expiryMonth: json['expiry_month'] as int,
      expiryYear: json['expiry_year'] as int,
      cardholderName: json['cardholder_name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_type': cardType,
      'last_four_digits': lastFourDigits,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cardholder_name': cardholderName,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? cardType,
    String? lastFourDigits,
    int? expiryMonth,
    int? expiryYear,
    String? cardholderName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardType: cardType ?? this.cardType,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    cardType,
    lastFourDigits,
    expiryMonth,
    expiryYear,
    cardholderName,
    isDefault,
    createdAt,
    updatedAt,
  ];
}
