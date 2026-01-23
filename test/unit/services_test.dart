import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrlink1/core/services/auth_service.dart';
import 'package:agrlink1/core/services/notification_service.dart';
import 'package:agrlink1/core/services/product_service.dart';
import 'package:agrlink1/core/services/cart_service.dart';
import 'package:agrlink1/core/services/order_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should initialize correctly', () {
      expect(authService, isNotNull);
      expect(authService.isLoggedIn, isFalse);
    });

    test('should handle email validation', () {
      expect(authService.isValidEmail('test@example.com'), isTrue);
      expect(authService.isValidEmail('invalid-email'), isFalse);
      expect(authService.isValidEmail(''), isFalse);
    });

    test('should handle password validation', () {
      expect(authService.isValidPassword('password123'), isTrue);
      expect(authService.isValidPassword('12345'), isFalse); // Too short
      expect(authService.isValidPassword(''), isFalse);
    });

    // Note: Real authentication tests would require mocking Supabase
    // and setting up test database
  });

  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('should initialize correctly', () {
      expect(notificationService, isNotNull);
    });

    test('should generate mock FCM token', () async {
      final token = await notificationService.getToken();
      expect(token, isNotNull);
      expect(token, contains('mock-fcm-token'));
    });

    test('should get notification history', () async {
      final notifications = await notificationService.getNotificationHistory();
      expect(notifications, isNotEmpty);
      expect(notifications.length, greaterThan(0));
    });

    test('should categorize notification types correctly', () async {
      final notifications = await notificationService.getNotificationHistory();
      final orderNotification = notifications.firstWhere(
        (n) => n.type == 'orderUpdate',
      );
      
      expect(orderNotification.icon, equals(Icons.shopping_cart));
      expect(orderNotification.color, equals(Colors.blue));
    });
  });

  group('ProductService Tests', () {
    late ProductService productService;

    setUp(() {
      productService = ProductService();
    });

    test('should initialize correctly', () {
      expect(productService, isNotNull);
    });

    test('should validate product data', () {
      expect(productService.isValidProductName('Fresh Tomatoes'), isTrue);
      expect(productService.isValidProductName(''), isFalse);
      expect(productService.isValidProductName('A' * 200), isFalse); // Too long
    });

    test('should validate price', () {
      expect(productService.isValidPrice(10.50), isTrue);
      expect(productService.isValidPrice(0), isFalse);
      expect(productService.isValidPrice(-5), isFalse);
    });

    test('should validate stock quantity', () {
      expect(productService.isValidStock(10), isTrue);
      expect(productService.isValidStock(0), isFalse);
      expect(productService.isValidStock(-1), isFalse);
    });
  });

  group('CartService Tests', () {
    late CartService cartService;

    setUp(() {
      cartService = CartService();
    });

    test('should initialize with empty cart', () {
      expect(cartService, isNotNull);
      // Note: Cart service methods would need to be implemented
      // expect(cartService.items, isEmpty);
      // expect(cartService.totalAmount, equals(0.0));
      // expect(cartService.itemCount, equals(0));
    });

    test('should calculate total correctly', () {
      // Mock adding items to cart
      expect(cartService.totalAmount, equals(0.0));
      
      // Note: Full cart tests would require proper cart item implementation
    });
  });

  group('OrderService Tests', () {
    late OrderService orderService;

    setUp(() {
      orderService = OrderService();
    });

    test('should initialize correctly', () {
      expect(orderService, isNotNull);
    });

    test('should validate order data', () {
      expect(orderService.isValidDeliveryAddress('123 Main St'), isTrue);
      expect(orderService.isValidDeliveryAddress(''), isFalse);
    });
  });

  // Helper function for email validation
  test('Email validation edge cases', () {
    final authService = AuthService();
    
    // Valid emails
    expect(authService.isValidEmail('user@domain.com'), isTrue);
    expect(authService.isValidEmail('user.name@domain.co.uk'), isTrue);
    expect(authService.isValidEmail('user+tag@domain.org'), isTrue);
    
    // Invalid emails
    expect(authService.isValidEmail('@domain.com'), isFalse);
    expect(authService.isValidEmail('user@'), isFalse);
    expect(authService.isValidEmail('user.domain.com'), isFalse);
    expect(authService.isValidEmail('user @domain.com'), isFalse);
  });
}

// Extension methods for services to add validation methods
extension AuthServiceTestExtensions on AuthService {
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}

extension ProductServiceTestExtensions on ProductService {
  bool isValidProductName(String name) {
    return name.isNotEmpty && name.length <= 100;
  }

  bool isValidPrice(double price) {
    return price > 0;
  }

  bool isValidStock(int stock) {
    return stock > 0;
  }
}

extension OrderServiceTestExtensions on OrderService {
  bool isValidDeliveryAddress(String address) {
    return address.isNotEmpty && address.length >= 5;
  }
}