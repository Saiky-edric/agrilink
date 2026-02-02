import 'product_model.dart';

/// Model to hold a product with its calculated distance from user
class ProductWithDistance {
  final ProductModel product;
  final double? distance; // Distance in kilometers, null if can't be calculated

  ProductWithDistance({
    required this.product,
    this.distance,
  });

  /// Get formatted distance string
  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).round()} m away';
    } else if (distance! < 10) {
      return '${distance!.toStringAsFixed(1)} km away';
    } else {
      return '${distance!.round()} km away';
    }
  }

  /// Check if product is nearby (within 5km)
  bool get isNearby => distance != null && distance! <= 5;

  /// Check if product is very close (within 2km)
  bool get isVeryClose => distance != null && distance! <= 2;
}
