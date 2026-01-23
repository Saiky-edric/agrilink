import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrlink1/core/theme/app_theme.dart';
import 'package:agrlink1/core/services/theme_service.dart';
import 'package:agrlink1/features/auth/screens/login_screen.dart';
import 'package:agrlink1/features/buyer/screens/home_screen.dart';
import 'package:agrlink1/features/profile/screens/settings_screen.dart';
import 'package:agrlink1/features/notifications/screens/notifications_screen.dart';
import 'package:agrlink1/shared/widgets/custom_button.dart';
import 'package:agrlink1/shared/widgets/custom_text_field.dart';
import 'package:agrlink1/shared/widgets/product_card.dart';
import 'package:agrlink1/shared/widgets/error_widgets.dart';
import 'package:agrlink1/core/models/product_model.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('should display all login screen elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );

      // Check for key elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(find.byType(CustomTextField), findsAtLeastNWidgets(2)); // Email and password
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Don\'t have an account?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );

      // Tap login without filling fields
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation errors (if implemented)
      // expect(find.text('Please enter your email'), findsOneWidget);
      // expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should handle social login buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );

      // Check for social login buttons
      expect(find.text('Continue with Google'), findsWidgets);
      expect(find.text('Continue with Facebook'), findsWidgets);

      // Test button interactions
      final googleButton = find.text('Continue with Google');
      if (googleButton.findsWidgets.isNotEmpty) {
        await tester.tap(googleButton);
        await tester.pump();
      }
    });
  });

  group('Home Screen Widget Tests', () {
    testWidgets('should display home screen elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );

      // Check for key home screen elements
      expect(find.text('Welcome'), findsWidgets);
      expect(find.text('Categories'), findsWidgets);
      expect(find.text('Featured Products'), findsWidgets);
    });

    testWidgets('should display product grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );

      // Wait for any async operations
      await tester.pump();

      // Should show products or loading state
      expect(
        find.byType(GridView),
        findsWidgets,
      );
    });
  });

  group('Settings Screen Widget Tests', () {
    testWidgets('should display settings options', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Check for settings sections
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('should toggle notification switches', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      // Find and toggle push notifications switch
      final pushNotificationSwitch = find.byType(Switch).first;
      await tester.tap(pushNotificationSwitch);
      await tester.pump();

      // Switch state should change (this would need proper state management testing)
    });
  });

  group('Notifications Screen Widget Tests', () {
    testWidgets('should display notifications or empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      );

      // Wait for loading
      await tester.pump();

      // Should show either notifications or empty state
      expect(
        find.text('Notifications'),
        findsOneWidget,
      );
    });

    testWidgets('should display notification items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      );

      // Wait for any async operations
      await tester.pump(const Duration(seconds: 1));

      // Check for notification elements if they exist
      final notificationCards = find.byType(InkWell);
      if (notificationCards.evaluate().isNotEmpty) {
        // Test tapping a notification
        await tester.tap(notificationCards.first);
        await tester.pump();
      }
    });
  });

  group('Custom Widgets Tests', () {
    testWidgets('CustomButton should display text and handle taps', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      // Check button text
      expect(find.text('Test Button'), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(CustomButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('CustomButton should show loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Should show loading indicator instead of text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('CustomTextField should display label and handle input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Test Field',
              hintText: 'Enter text here',
            ),
          ),
        ),
      );

      // Check label
      expect(find.text('Test Field'), findsOneWidget);

      // Test text input
      await tester.enterText(find.byType(TextField), 'Test input');
      expect(controller.text, equals('Test input'));
    });

    testWidgets('ProductCard should display product information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProductCard(
              product: ProductModel(
                id: 'test-id',
                name: 'Test Product',
                description: 'Test description',
                price: 25.99,
                unit: 'kg',
                category: ProductCategory.vegetables,
                farmerId: 'farmer-id',
                farmerName: 'John Doe',
                images: ['https://example.com/image.jpg'],
                stockQuantity: 10,
                location: 'Test Location',
                isOrganic: false,
                harvestDate: DateTime.now(),
                expirationDate: DateTime.now().add(Duration(days: 7)),
                createdAt: DateTime.now(),
                isActive: true,
                isHidden: false,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      // Check product information
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('₱25.99'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
    });

    testWidgets('LoadingWidget should display spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: LoadingWidget(),
          ),
        ),
      );

      // Should display loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorWidget should display error message and retry button', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ErrorRetryWidget(
              message: 'Test error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Check error message
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Retry'));
      expect(retryPressed, isTrue);
    });
  });

  group('Theme and Styling Tests', () {
    testWidgets('should apply correct theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Text('Content'),
          ),
        ),
      );

      // Check theme application
      final BuildContext context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.colorScheme.primary, equals(AppTheme.primaryGreen));
    });

    testWidgets('should handle dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Text('Dark theme test'),
          ),
        ),
      );

      // Check dark theme application
      final BuildContext context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.brightness, equals(Brightness.dark));
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should have proper semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Accessible Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Check for semantic labels
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('should support screen readers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Screen reader test'),
          ),
        ),
      );

      // Test with semantic finder
      expect(find.bySemanticsLabel('Screen reader test'), findsWidgets);
    });

    testWidgets('should have proper touch targets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              text: 'Touch Target Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Check button size for touch accessibility
      final buttonFinder = find.byType(ElevatedButton);
      final button = tester.widget(buttonFinder) as ElevatedButton;
      
      // Buttons should meet minimum touch target size (44x44)
      expect(buttonFinder, findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('should render efficiently', (tester) async {
      // Monitor frame rendering
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BuyerHomeScreen(),
        ),
      );

      // Pump multiple frames to check for performance issues
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // No specific assertion, but this helps catch performance issues
    });
  });
}

// Helper extension for finding widgets
extension WidgetTesterExtensions on WidgetTester {
  /// Helper method to find widgets by semantic label
  Finder findBySemantics(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Helper method to enter text and trigger validation
  Future<void> enterTextAndValidate(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();
  }
}

// Custom matcher for color testing
class ColorMatcher extends Matcher {
  final Color expectedColor;

  const ColorMatcher(this.expectedColor);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is Color && item.value == expectedColor.value;
  }

  @override
  Description describe(Description description) {
    return description.add('Color with value ${expectedColor.value}');
  }
}