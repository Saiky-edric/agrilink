import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItemModel extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final ProductModel? product; // For display purposes

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at']),
      product: json['product'] != null 
          ? ProductModel.fromJson(json['product']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    DateTime? createdAt,
    ProductModel? product,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
    );
  }

  double get subtotal {
    if (product == null) return 0.0;
    return product!.price * quantity;
  }

  bool get isAvailable {
    if (product == null) return false;
    return product!.isInStock && 
           product!.stock >= quantity && 
           !product!.isExpired;
  }

  @override
  List<Object?> get props => [id, userId, productId, quantity, createdAt, product];
}

class CartModel extends Equatable {
  final List<CartItemModel> items;
  final double total;
  final int totalItems;

  const CartModel({
    this.items = const [],
    this.total = 0.0,
    this.totalItems = 0,
  });

  factory CartModel.fromItems(List<CartItemModel> items) {
    final total = items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return CartModel(
      items: items,
      total: total,
      totalItems: totalItems,
    );
  }

  CartModel copyWith({
    List<CartItemModel>? items,
    double? total,
    int? totalItems,
  }) {
    return CartModel(
      items: items ?? this.items,
      total: total ?? this.total,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  List<CartItemModel> get availableItems => 
      items.where((item) => item.isAvailable).toList();

  List<CartItemModel> get unavailableItems => 
      items.where((item) => !item.isAvailable).toList();

  Map<String, List<CartItemModel>> get itemsByFarmer {
    final Map<String, List<CartItemModel>> grouped = {};
    for (final item in availableItems) {
      final farmerId = item.product?.farmerId ?? 'unknown';
      grouped.putIfAbsent(farmerId, () => []).add(item);
    }
    return grouped;
  }

  @override
  List<Object?> get props => [items, total, totalItems];
}