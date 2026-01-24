import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agrilink/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Flow Integration Tests', () {
    testWidgets('Complete buyer flow - Browse and purchase', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test app initialization
      expect(find.byType(MaterialApp), findsOneWidget);

      // Navigate through onboarding (if present)
      await _skipOnboardingIfPresent(tester);

      // Test login flow
      await _performLogin(tester, 'buyer@test.com', 'password123');

      // Test home screen navigation
      await _testHomeScreenNavigation(tester);

      // Test product browsing
      await _testProductBrowsing(tester);

      // Test cart functionality
      await _testCartFunctionality(tester);

      // Test checkout process
      await _testCheckoutProcess(tester);
    });

    testWidgets('Complete farmer flow - Add product and manage orders', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through onboarding
      await _skipOnboardingIfPresent(tester);

      // Login as farmer
      await _performLogin(tester, 'farmer@test.com', 'password123');

      // Test farmer dashboard
      await _testFarmerDashboard(tester);

      // Test adding a new product
      await _testAddProduct(tester);

      // Test viewing and managing orders
      await _testOrderManagement(tester);
    });

    testWidgets('Admin flow - User management and verification', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through onboarding
      await _skipOnboardingIfPresent(tester);

      // Login as admin
      await _performLogin(tester, 'admin@test.com', 'password123');

      // Test admin dashboard
      await _testAdminDashboard(tester);

      // Test user management
      await _testUserManagement(tester);

      // Test verification process
      await _testVerificationProcess(tester);
    });

    testWidgets('Chat functionality test', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      await _skipOnboardingIfPresent(tester);
      await _performLogin(tester, 'buyer@test.com', 'password123');

      // Test chat functionality
      await _testChatFunctionality(tester);
    });

    testWidgets('Profile and settings test', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      await _skipOnboardingIfPresent(tester);
      await _performLogin(tester, 'buyer@test.com', 'password123');

      // Test profile management
      await _testProfileManagement(tester);

      // Test settings
      await _testSettings(tester);
    });
  });
}

// Helper functions for test flows
Future<void> _skipOnboardingIfPresent(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Look for onboarding screens and skip them
  while (find.text('Skip').evaluate().isNotEmpty || 
         find.text('Get Started').evaluate().isNotEmpty) {
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
    } else if (find.text('Get Started').evaluate().isNotEmpty) {
      await tester.tap(find.text('Get Started'));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}

Future<void> _performLogin(WidgetTester tester, String email, String password) async {
  // Wait for login screen
  await tester.pumpAndSettle();
  
  // Look for email and password fields
  final emailField = find.byKey(const Key('email_field'));
  final passwordField = find.byKey(const Key('password_field'));
  final loginButton = find.text('Login');

  if (emailField.findsWidgets.isNotEmpty) {
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

Future<void> _testHomeScreenNavigation(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test bottom navigation
  if (find.byIcon(Icons.home).findsWidgets.isNotEmpty) {
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
  }
  
  // Test categories navigation
  if (find.byIcon(Icons.category).findsWidgets.isNotEmpty) {
    await tester.tap(find.byIcon(Icons.category));
    await tester.pumpAndSettle();
  }
  
  // Test search navigation
  if (find.byIcon(Icons.search).findsWidgets.isNotEmpty) {
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
  }
}

Future<void> _testProductBrowsing(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Look for product cards and tap one
  final productCards = find.byType(Card);
  if (productCards.findsWidgets.isNotEmpty) {
    await tester.tap(productCards.first);
    await tester.pumpAndSettle();
    
    // Test product details screen
    expect(find.text('Add to Cart'), findsWidgets);
  }
}

Future<void> _testCartFunctionality(WidgetTester tester) async {
  // Add item to cart if on product details screen
  final addToCartButton = find.text('Add to Cart');
  if (addToCartButton.findsWidgets.isNotEmpty) {
    await tester.tap(addToCartButton);
    await tester.pumpAndSettle();
  }
  
  // Navigate to cart
  final cartIcon = find.byIcon(Icons.shopping_cart);
  if (cartIcon.findsWidgets.isNotEmpty) {
    await tester.tap(cartIcon);
    await tester.pumpAndSettle();
  }
}

Future<void> _testCheckoutProcess(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Look for checkout button
  final checkoutButton = find.text('Checkout');
  if (checkoutButton.findsWidgets.isNotEmpty) {
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();
    
    // Test checkout form
    expect(find.text('Delivery Address'), findsWidgets);
  }
}

Future<void> _testFarmerDashboard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test farmer dashboard elements
  expect(find.text('Dashboard'), findsWidgets);
  
  // Test quick actions
  final addProductButton = find.text('Add Product');
  if (addProductButton.findsWidgets.isNotEmpty) {
    await tester.tap(addProductButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _testAddProduct(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Fill product form if present
  final productNameField = find.byKey(const Key('product_name'));
  if (productNameField.findsWidgets.isNotEmpty) {
    await tester.enterText(productNameField, 'Test Product');
    await tester.pumpAndSettle();
  }
}

Future<void> _testOrderManagement(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Navigate to orders
  final ordersTab = find.text('Orders');
  if (ordersTab.findsWidgets.isNotEmpty) {
    await tester.tap(ordersTab);
    await tester.pumpAndSettle();
  }
}

Future<void> _testAdminDashboard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test admin dashboard elements
  expect(find.text('Admin Dashboard'), findsWidgets);
}

Future<void> _testUserManagement(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test user management features
  final userManagementButton = find.text('User Management');
  if (userManagementButton.findsWidgets.isNotEmpty) {
    await tester.tap(userManagementButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _testVerificationProcess(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test verification features
  final verificationsButton = find.text('Farmer Verifications');
  if (verificationsButton.evaluate().isNotEmpty) {
    await tester.tap(verificationsButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _testChatFunctionality(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Test chat navigation
  final chatIcon = find.byIcon(Icons.chat);
  if (chatIcon.evaluate().isNotEmpty) {
    await tester.tap(chatIcon);
    await tester.pumpAndSettle();
  }
}

Future<void> _testProfileManagement(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Navigate to profile
  final profileIcon = find.byIcon(Icons.person);
  if (profileIcon.evaluate().isNotEmpty) {
    await tester.tap(profileIcon);
    await tester.pumpAndSettle();
    
    // Test profile elements
    expect(find.text('Profile'), findsOneWidget);
  }
}

Future<void> _testSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  // Navigate to settings
  final settingsIcon = find.byIcon(Icons.settings);
  if (settingsIcon.evaluate().isNotEmpty) {
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();
    
    // Test settings elements
    expect(find.text('Settings'), findsOneWidget);
  }
}
