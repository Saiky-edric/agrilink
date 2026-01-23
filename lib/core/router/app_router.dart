import 'package:flutter/material.dart';
import '../../features/shared/screens/under_development_screen.dart';
import '../../features/farmer/screens/edit_product_screen.dart';
import '../models/product_model.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../services/auth_service.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_role_screen.dart';
import '../../features/auth/screens/signup_buyer_screen.dart';
import '../../features/auth/screens/signup_farmer_screen.dart';
import '../../features/auth/screens/address_setup_screen.dart';
import '../../features/auth/screens/social_role_selection_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/buyer/screens/modern_product_details_screen.dart';
import '../../features/buyer/screens/order_details_screen.dart';
import '../../features/admin/screens/verification_details_screen.dart';
import '../../features/admin/screens/reports_screen.dart';
import '../../features/admin/screens/report_details_screen.dart';
import '../../features/farmer/screens/farmer_profile_screen.dart';
import '../../features/farmer/screens/farmer_profile_edit_screen.dart';
import '../../features/farmer/screens/farm_information_screen.dart';
import '../../features/farmer/screens/sales_analytics_screen.dart';
import '../../features/farmer/screens/farmer_help_support_screen.dart';
import '../../features/farmer/screens/verification_status_screen.dart';
import '../../features/farmer/screens/public_farmer_profile_screen.dart';
import '../../features/farmer/screens/farmer_reviews_screen.dart';
import '../../features/buyer/screens/buyer_profile_screen.dart';
import '../../features/buyer/screens/submit_review_screen.dart';
import '../../features/buyer/screens/submit_product_review_screen.dart';
import '../../features/buyer/screens/followed_stores_screen.dart';
import '../../features/buyer/screens/wishlist_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_user_list_screen.dart';
import '../../features/admin/screens/admin_verification_list_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_reports_management_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/farmer/screens/farmer_dashboard_screen.dart';
import '../../features/buyer/screens/home_screen.dart';
import '../../features/farmer/screens/add_product_screen.dart';
import '../../features/farmer/screens/verification_upload_screen.dart';
import '../../features/farmer/screens/product_list_screen.dart';
import '../../features/farmer/screens/farmer_product_details_screen.dart';
import '../../features/farmer/screens/farmer_orders_screen.dart';
import '../../features/farmer/screens/farmer_order_details_screen.dart';
import '../../features/buyer/screens/cart_screen.dart';
import '../../features/buyer/screens/checkout_screen.dart';
import '../../features/buyer/screens/address_selection_screen.dart';
import '../models/address_model.dart';
import '../../features/buyer/screens/buyer_orders_screen.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/chat/screens/chat_conversation_screen.dart';
import '../../features/chat/screens/support_chat_screen.dart';
import '../../features/buyer/screens/modern_search_screen.dart';
import '../../features/buyer/screens/categories_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/address_management_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/farmer/screens/store_customization_screen.dart';
import '../../features/farmer/screens/store_settings_screen.dart';
import '../../features/farmer/screens/pickup_settings_screen.dart';
import '../../features/farmer/screens/expired_products_screen.dart';
import '../../features/farmer/screens/subscription_screen.dart';
import '../../features/farmer/screens/subscription_request_screen.dart';
import '../../features/admin/screens/admin_subscription_management_screen.dart';
import '../../features/admin/screens/admin_activities_screen.dart';
import 'profile_router_helper.dart';

class AppRouter {
  static final AuthService _authService = AuthService();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: _guard,
    routes: [
      // Global routes
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signupRole,
        name: 'signupRole',
        builder: (context, state) => const SignupRoleScreen(),
      ),
      GoRoute(
        path: RouteNames.signupBuyer,
        name: 'signupBuyer',
        builder: (context, state) => const SignupBuyerScreen(),
      ),
      GoRoute(
        path: RouteNames.signupFarmer,
        name: 'signupFarmer',
        builder: (context, state) => const SignupFarmerScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.addressSetup,
        name: 'addressSetup',
        builder: (context, state) => const AddressSetupScreen(),
      ),

      GoRoute(
        path: RouteNames.socialRoleSelection,
        name: 'socialRoleSelection',
        builder: (context, state) => const SocialRoleSelectionScreen(),
      ),

      // Buyer routes
      GoRoute(
        path: RouteNames.buyerHome,
        name: 'buyerHome',
        builder: (context, state) => const BuyerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.productDetails,
        name: 'productDetails',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ModernProductDetailsScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/public-farmer/:id',
        name: 'publicFarmerProfile',
        builder: (context, state) {
          final farmerId = state.pathParameters['id']!;
          return PublicFarmerProfileScreen(farmerId: farmerId);
        },
      ),

      // Review System Routes
      GoRoute(
        path: '/submit-review/:orderId',
        name: 'submitReview',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          final sellerId = state.uri.queryParameters['sellerId'];
          return SubmitReviewScreen(
            orderId: orderId,
            sellerId: sellerId,
          );
        },
      ),
      GoRoute(
        path: '/submit-product-review/:orderId',
        name: 'submitProductReview',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return SubmitProductReviewScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/farmer-reviews',
        name: 'farmerReviews',
        builder: (context, state) => const FarmerReviewsScreen(),
      ),

      // Following System Routes
      GoRoute(
        path: '/followed-stores',
        name: 'followedStores',
        builder: (context, state) => const FollowedStoresScreen(),
      ),
      GoRoute(
        path: RouteNames.wishlist,
        name: 'wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: RouteNames.categories,
        name: 'categories',
        builder: (context, state) {
          final initial = state.uri.queryParameters['category'];
          return CategoriesScreen(initialCategory: initial);
        },
      ),
      GoRoute(
        path: RouteNames.search,
        name: 'search',
        builder: (context, state) => const ModernSearchScreen(),
      ),
      GoRoute(
        path: RouteNames.cart,
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: RouteNames.checkout,
        name: 'checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CheckoutScreen(
            farmerId: extra?['farmerId'],
            items: extra?['items'],
            storeInfo: extra?['storeInfo'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.buyerOrders,
        name: 'buyerOrders',
        builder: (context, state) => const BuyerOrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.buyerOrderDetails,
        name: 'buyerOrderDetails',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: RouteNames.buyerProfile,
        name: 'buyerProfile',
        builder: (context, state) => const BuyerProfileScreen(),
      ),

      // Farmer routes
      GoRoute(
        path: RouteNames.farmerDashboard,
        name: 'farmerDashboard',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialIndex = int.tryParse(tabParam ?? '') ?? 0;
          return FarmerDashboardScreen(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/farmer/profile',
        name: 'farmerProfile',
        builder: (context, state) => const FarmerProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerProfileEdit,
        name: 'farmerProfileEdit',
        builder: (context, state) => const FarmerProfileEditScreen(),
      ),
      GoRoute(
        path: RouteNames.farmInformation,
        name: 'farmInformation',
        builder: (context, state) => const FarmInformationScreen(),
      ),
      GoRoute(
        path: RouteNames.salesAnalytics,
        name: 'salesAnalytics',
        builder: (context, state) => const SalesAnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerHelpSupport,
        name: 'farmerHelpSupport',
        builder: (context, state) => const FarmerHelpSupportScreen(),
      ),
      GoRoute(
        path: '/farmer/verification-status',
        name: 'farmerVerificationStatus',
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      GoRoute(
        path: RouteNames.uploadVerification,
        name: 'uploadVerification',
        builder: (context, state) => const VerificationUploadScreen(),
      ),
      GoRoute(
        path: RouteNames.verificationStatus,
        name: 'verificationStatus',
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      GoRoute(
        path: RouteNames.productList,
        name: 'productList',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: RouteNames.addProduct,
        name: 'addProduct',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: RouteNames.editProduct,
        name: 'editProduct',
        builder: (context, state) {
          // final productId = state.pathParameters['id']!;
          final product = state.extra as ProductModel;
          return EditProductScreen(product: product);
        },
      ),
      GoRoute(
        path: RouteNames.farmerProductDetails,
        name: 'farmerProductDetails',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return FarmerProductDetailsScreen(productId: productId);
        },
      ),
      GoRoute(
        path: RouteNames.farmerOrders,
        name: 'farmerOrders',
        builder: (context, state) => const FarmerOrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerOrderDetails,
        name: 'farmerOrderDetails',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return FarmerOrderDetailsScreen(orderId: orderId);
        },
      ),

      // Store Management Routes
      GoRoute(
        path: '/farmer/store-customization',
        name: 'storeCustomization',
        builder: (context, state) => const StoreCustomizationScreen(),
      ),
      GoRoute(
        path: '/farmer/store-settings',
        name: 'storeSettings',
        builder: (context, state) => const StoreSettingsScreen(),
      ),
      GoRoute(
        path: '/farmer/pickup-settings',
        name: 'pickupSettings',
        builder: (context, state) => const PickupSettingsScreen(),
      ),
      GoRoute(
        path: '/farmer/expired-products',
        name: 'expiredProducts',
        builder: (context, state) => const ExpiredProductsScreen(),
      ),

      // Notifications routes
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Chat routes
      GoRoute(
        path: RouteNames.chatInbox,
        name: 'chatInbox',
        builder: (context, state) {
          final extra = state.extra;
          String? origin;
          if (extra is Map) {
            final o = extra['origin'];
            if (o is String) origin = o;
          }
          return ChatInboxScreen(origin: origin);
        },
      ),
      GoRoute(
        path: RouteNames.chatConversation,
        name: 'chatConversation',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatConversationScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: RouteNames.supportChat,
        name: 'supportChat',
        builder: (context, state) => const SupportChatScreen(),
      ),

      // Profile routes
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => ProfileRouterHelper.getProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.addresses,
        name: 'addresses',
        builder: (context, state) => const AddressManagementScreen(),
      ),
      GoRoute(
        path: '/buyer/address-selection',
        name: 'addressSelection',
        builder: (context, state) {
          final extra = state.extra as AddressModel?;
          return AddressSelectionScreen(currentlySelected: extra);
        },
      ),

      // Feedback routes
      GoRoute(
        path: RouteNames.submitFeedback,
        name: 'submitFeedback',
        builder: (context, state) => const UnderDevelopmentScreen(featureName: 'Submit Feedback'),
      ),
      GoRoute(
        path: RouteNames.submitReport,
        name: 'submitReport',
        builder: (context, state) => const UnderDevelopmentScreen(featureName: 'Submit Report'),
      ),

      // Admin routes
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminLogin,
        name: 'adminLogin',
        builder: (context, state) => const UnderDevelopmentScreen(featureName: 'Admin Login'),
      ),
      GoRoute(
        path: RouteNames.verificationRequests,
        name: 'verificationRequests',
        builder: (context, state) => const AdminVerificationListScreen(),
      ),
      GoRoute(
        path: RouteNames.reviewVerification,
        name: 'reviewVerification',
        builder: (context, state) {
          final verificationId = state.pathParameters['id']!;
          return VerificationDetailsScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: RouteNames.adminProductList,
        name: 'adminProductList',
        builder: (context, state) => const UnderDevelopmentScreen(featureName: 'Admin Product List'),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder: (context, state) => const AdminUserListScreen(),
      ),
      GoRoute(
        path: '/admin/verifications',
        name: 'adminVerifications',
        builder: (context, state) => const AdminVerificationListScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'adminAnalytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'adminReportsManagement',
        builder: (context, state) => const AdminReportsManagementScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'adminSettings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/activities',
        name: 'adminActivities',
        builder: (context, state) => const AdminActivitiesScreen(),
      ),
      GoRoute(
        path: RouteNames.reportList,
        name: 'reportList',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.reportDetails,
        name: 'reportDetails',
        builder: (context, state) {
          final reportId = state.pathParameters['id']!;
          return ReportDetailsScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: RouteNames.exportCenter,
        name: 'exportCenter',
        builder: (context, state) => const UnderDevelopmentScreen(featureName: 'Export Center'),
      ),

      // Subscription routes
      GoRoute(
        path: RouteNames.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: RouteNames.subscriptionRequest,
        name: 'subscriptionRequest',
        builder: (context, state) => const SubscriptionRequestScreen(),
      ),
      GoRoute(
        path: RouteNames.adminSubscriptionManagement,
        name: 'adminSubscriptionManagement',
        builder: (context, state) => const AdminSubscriptionManagementScreen(),
      ),
    ],
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    // Allow access to splash screen
    if (state.matchedLocation == RouteNames.splash) {
      return null;
    }

    // Allow access to public routes
    final publicRoutes = [
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.signupRole,
      RouteNames.signupBuyer,
      RouteNames.signupFarmer,
      RouteNames.forgotPassword,
    ];

    if (publicRoutes.contains(state.matchedLocation)) {
      return null;
    }

    // For protected routes, check authentication
    if (!_authService.isLoggedIn) {
      return RouteNames.login;
    }

    // Additional role-based checks can be added here
    return null;
  }
}
