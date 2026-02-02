import 'package:flutter_test/flutter_test.dart';
import 'package:agrilink/core/models/order_model.dart';

void main() {
  group('Order Timestamp Tests', () {
    test('OrderModel initializes with created_at timestamp', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.newOrder,
        createdAt: now,
        updatedAt: now,
        items: const [],
      );

      expect(order.createdAt, equals(now));
      expect(order.updatedAt, equals(now));
    });

    test('OrderModel stores individual status timestamps', () {
      final now = DateTime.now();
      final acceptedTime = now.add(const Duration(hours: 1));
      final packTime = now.add(const Duration(hours: 2));
      final deliveryTime = now.add(const Duration(hours: 4));
      final completedTime = now.add(const Duration(hours: 6));

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.completed,
        farmerStatus: FarmerOrderStatus.completed,
        createdAt: now,
        updatedAt: completedTime,
        acceptedAt: acceptedTime,
        toPackAt: packTime,
        toDeliverAt: deliveryTime,
        completedAt: completedTime,
        items: const [],
      );

      expect(order.acceptedAt, equals(acceptedTime));
      expect(order.toPackAt, equals(packTime));
      expect(order.toDeliverAt, equals(deliveryTime));
      expect(order.completedAt, equals(completedTime));
    });

    test('OrderModel handles null timestamps for pending statuses', () {
      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.accepted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        acceptedAt: DateTime.now(),
        items: const [],
      );

      // These should be null since order hasn't reached those statuses
      expect(order.toPackAt, isNull);
      expect(order.toDeliverAt, isNull);
      expect(order.completedAt, isNull);
      expect(order.cancelledAt, isNull);

      // This should be set
      expect(order.acceptedAt, isNotNull);
    });

    test('OrderModel stores delivery tracking timestamps', () {
      final now = DateTime.now();
      final deliveryStarted = now.add(const Duration(hours: 3));
      final lastUpdate = now.add(const Duration(hours: 3, minutes: 30));

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.toDeliver,
        createdAt: now,
        updatedAt: now,
        deliveryStartedAt: deliveryStarted,
        deliveryLastUpdatedAt: lastUpdate,
        deliveryLatitude: 7.0731,
        deliveryLongitude: 125.6128,
        items: const [],
      );

      expect(order.deliveryStartedAt, equals(deliveryStarted));
      expect(order.deliveryLastUpdatedAt, equals(lastUpdate));
      expect(order.deliveryLatitude, equals(7.0731));
      expect(order.deliveryLongitude, equals(125.6128));
    });

    test('OrderModel stores location coordinates', () {
      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.newOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        farmerLatitude: 7.1907,
        farmerLongitude: 125.4553,
        buyerLatitude: 7.0731,
        buyerLongitude: 125.6128,
        items: const [],
      );

      expect(order.farmerLatitude, equals(7.1907));
      expect(order.farmerLongitude, equals(125.4553));
      expect(order.buyerLatitude, equals(7.0731));
      expect(order.buyerLongitude, equals(125.6128));
    });

    test('OrderModel stores estimated delivery times', () {
      final now = DateTime.now();
      final estimatedDelivery = now.add(const Duration(hours: 5));
      final estimatedPickup = now.add(const Duration(hours: 4));

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.accepted,
        createdAt: now,
        updatedAt: now,
        estimatedDeliveryAt: estimatedDelivery,
        estimatedPickupAt: estimatedPickup,
        items: const [],
      );

      expect(order.estimatedDeliveryAt, equals(estimatedDelivery));
      expect(order.estimatedPickupAt, equals(estimatedPickup));
    });

    test('OrderModel serializes timestamps to JSON correctly', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.accepted,
        createdAt: now,
        updatedAt: now,
        acceptedAt: now,
        items: const [],
      );

      // Note: toJson is not typically implemented in models
      // This test would verify that fromJson works correctly
      final json = {
        'id': 'test-1',
        'buyer_id': 'buyer-1',
        'farmer_id': 'farmer-1',
        'total_amount': 500.0,
        'delivery_address': '123 Test St',
        'buyer_status': 'pending',
        'farmer_status': 'accepted',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'accepted_at': now.toIso8601String(),
      };

      final deserializedOrder = OrderModel.fromJson(json);

      expect(deserializedOrder.id, equals(order.id));
      expect(deserializedOrder.acceptedAt, isNotNull);
      expect(
        deserializedOrder.acceptedAt!.difference(order.acceptedAt!).inSeconds,
        lessThan(1),
      );
    });

    test('Calculate order processing duration', () {
      final createdAt = DateTime(2024, 1, 1, 10, 0);
      final acceptedAt = DateTime(2024, 1, 1, 10, 30);
      final toPackAt = DateTime(2024, 1, 1, 11, 0);
      final toDeliverAt = DateTime(2024, 1, 1, 12, 0);
      final completedAt = DateTime(2024, 1, 1, 14, 0);

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.completed,
        farmerStatus: FarmerOrderStatus.completed,
        createdAt: createdAt,
        updatedAt: completedAt,
        acceptedAt: acceptedAt,
        toPackAt: toPackAt,
        toDeliverAt: toDeliverAt,
        completedAt: completedAt,
        items: const [],
      );

      // Total duration
      final totalDuration = order.completedAt!.difference(order.createdAt);
      expect(totalDuration.inHours, equals(4));

      // Time to accept
      final acceptDuration = order.acceptedAt!.difference(order.createdAt);
      expect(acceptDuration.inMinutes, equals(30));

      // Time to pack
      final packDuration = order.toPackAt!.difference(order.acceptedAt!);
      expect(packDuration.inMinutes, equals(30));

      // Time to deliver
      final deliverDuration = order.toDeliverAt!.difference(order.toPackAt!);
      expect(deliverDuration.inHours, equals(1));

      // Delivery duration
      final completionDuration = order.completedAt!.difference(order.toDeliverAt!);
      expect(completionDuration.inHours, equals(2));
    });

    test('Pickup order has ready_for_pickup_at timestamp', () {
      final now = DateTime.now();
      final readyTime = now.add(const Duration(hours: 3));

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.readyForPickup,
        createdAt: now,
        updatedAt: readyTime,
        readyForPickupAt: readyTime,
        deliveryMethod: 'pickup',
        pickupAddress: 'Farm Location, Barangay San Jose',
        items: const [],
      );

      expect(order.deliveryMethod, equals('pickup'));
      expect(order.readyForPickupAt, equals(readyTime));
      expect(order.pickupAddress, isNotNull);
    });

    test('Cancelled order has cancelled_at timestamp', () {
      final now = DateTime.now();
      final cancelledTime = now.add(const Duration(hours: 1));

      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St',
        buyerStatus: BuyerOrderStatus.cancelled,
        farmerStatus: FarmerOrderStatus.cancelled,
        createdAt: now,
        updatedAt: cancelledTime,
        cancelledAt: cancelledTime,
        items: const [],
      );

      expect(order.cancelledAt, equals(cancelledTime));
    });
  });
}
