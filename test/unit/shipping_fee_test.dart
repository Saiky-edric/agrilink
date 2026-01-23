import 'package:flutter_test/flutter_test.dart';
import 'package:agrlink1/core/services/order_service.dart';

void main() {
  group('J&T incremental fee (single parcel) - jtFeeForKg', () {
    test('Tiers at and below thresholds', () {
      expect(OrderService.jtFeeForKg(0), 70.0);
      expect(OrderService.jtFeeForKg(1.5), 70.0);
      expect(OrderService.jtFeeForKg(3.0), 70.0);
      expect(OrderService.jtFeeForKg(4.0), 120.0);
      expect(OrderService.jtFeeForKg(5.0), 120.0);
      expect(OrderService.jtFeeForKg(7.9), 160.0);
      expect(OrderService.jtFeeForKg(8.0), 160.0);
    });

    test('Above 8kg increments every 2kg at ₱25', () {
      expect(OrderService.jtFeeForKg(8.1), 185.0); // ceil((0.1)/2)=1 -> 160+25
      expect(OrderService.jtFeeForKg(10.0), 185.0); // extra=2 -> +25
      expect(OrderService.jtFeeForKg(10.1), 210.0); // extra>2 up to 4 -> +50
      expect(OrderService.jtFeeForKg(12.0), 210.0); // +50
      expect(OrderService.jtFeeForKg(12.01), 235.0); // +75
      expect(OrderService.jtFeeForKg(15.0), 235.0); // +75
    });
  });
}
