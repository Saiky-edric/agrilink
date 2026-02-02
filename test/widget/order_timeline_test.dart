import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrilink/shared/widgets/order_status_widgets.dart';
import 'package:agrilink/core/models/order_model.dart';

void main() {
  group('DetailedOrderTimeline Widget Tests', () {
    late OrderModel testOrder;

    setUp(() {
      // Create a test order with mock data
      testOrder = OrderModel(
        id: 'test-order-123',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 500.0,
        deliveryAddress: '123 Test St, Test City',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.toPack,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        acceptedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        toPackAt: DateTime.now().subtract(const Duration(hours: 1)),
        deliveryMethod: 'delivery',
        items: const [],
      );
    });

    testWidgets('renders timeline with order data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: testOrder,
              showDuration: true,
              enableRealtime: false, // Disable for testing
            ),
          ),
        ),
      );

      // Verify timeline title is displayed
      expect(find.text('Order Timeline'), findsOneWidget);

      // Verify timeline events are displayed
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Preparing Order'), findsOneWidget);
    });

    testWidgets('displays timestamps correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: testOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Check that relative time is displayed (e.g., "3 hours ago")
      expect(find.textContaining('hr ago'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows live badge when realtime enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: testOrder,
              showDuration: true,
              enableRealtime: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify live badge is shown
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('shows duration between steps when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: testOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show duration chips
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles completed order correctly', (WidgetTester tester) async {
      final completedOrder = testOrder.copyWith(
        farmerStatus: FarmerOrderStatus.completed,
        completedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: completedOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify completed status is shown
      expect(find.text('Order Delivered'), findsOneWidget);
      
      // Verify total duration is shown
      expect(find.textContaining('Total Duration:'), findsOneWidget);
    });

    testWidgets('handles cancelled order correctly', (WidgetTester tester) async {
      final cancelledOrder = testOrder.copyWith(
        farmerStatus: FarmerOrderStatus.cancelled,
        cancelledAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: cancelledOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify cancelled status is shown
      expect(find.text('Order Cancelled'), findsOneWidget);
    });

    testWidgets('shows pickup flow for pickup orders', (WidgetTester tester) async {
      final pickupOrder = testOrder.copyWith(
        deliveryMethod: 'pickup',
        farmerStatus: FarmerOrderStatus.readyForPickup,
        readyForPickupAt: DateTime.now(),
        pickupAddress: 'Farm Location, Barangay San Jose',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: pickupOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify pickup-specific text
      expect(find.text('Ready for Pickup'), findsOneWidget);
      expect(find.textContaining('Farm Location'), findsOneWidget);
    });

    testWidgets('shows delivery flow for delivery orders', (WidgetTester tester) async {
      final deliveryOrder = testOrder.copyWith(
        deliveryMethod: 'delivery',
        farmerStatus: FarmerOrderStatus.toDeliver,
        toDeliverAt: DateTime.now(),
        trackingNumber: 'TRK-2024-001234',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: deliveryOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify delivery-specific text
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.textContaining('TRK-2024-001234'), findsOneWidget);
    });

    testWidgets('shows estimated delivery time', (WidgetTester tester) async {
      final orderWithETA = testOrder.copyWith(
        farmerStatus: FarmerOrderStatus.toDeliver,
        toDeliverAt: DateTime.now(),
        estimatedDeliveryAt: DateTime.now().add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: orderWithETA,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify estimated delivery is shown
      expect(find.textContaining('Estimated Delivery'), findsOneWidget);
    });

    testWidgets('displays pending steps with empty circles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailedOrderTimeline(
              order: testOrder,
              showDuration: true,
              enableRealtime: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should have both completed (filled) and pending (empty) status indicators
      expect(find.byType(Icon), findsWidgets);
    });
  });

  group('OrderModel copyWith Tests', () {
    test('copyWith creates new instance with updated values', () {
      final order = OrderModel(
        id: 'test-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        totalAmount: 100.0,
        deliveryAddress: 'Test Address',
        buyerStatus: BuyerOrderStatus.pending,
        farmerStatus: FarmerOrderStatus.newOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [],
      );

      final updated = order.copyWith(
        farmerStatus: FarmerOrderStatus.accepted,
        acceptedAt: DateTime.now(),
      );

      expect(updated.id, equals(order.id));
      expect(updated.farmerStatus, equals(FarmerOrderStatus.accepted));
      expect(updated.acceptedAt, isNotNull);
    });
  });
}
