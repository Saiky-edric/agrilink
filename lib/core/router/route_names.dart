class RouteNames {
  // Global routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signupRole = '/signup-role';
  static const String signupBuyer = '/signup-buyer';
  static const String signupFarmer = '/signup-farmer';
  static const String forgotPassword = '/forgot-password';
  static const String addressSetup = '/address-setup';
  static const String socialRoleSelection = '/auth/social-role-selection';
  
  // Buyer routes
  static const String buyerHome = '/buyer/home';
  static const String productDetails = '/buyer/product/:id';
  static const String categories = '/buyer/categories';
  static const String search = '/buyer/search';
  static const String cart = '/buyer/cart';
  static const String checkout = '/buyer/checkout';
  static const String buyerOrders = '/buyer/orders';
  static const String buyerOrderDetails = '/buyer/order/:id';
  
  // Farmer routes
  static const String farmerDashboard = '/farmer/dashboard';
  static const String farmerProfile = '/farmer/profile';
  static const String farmerProfileEdit = '/farmer/profile/edit';
  static const String publicFarmerProfile = '/public-farmer';
  static const String farmInformation = '/farmer/farm-info';
  static const String salesAnalytics = '/farmer/analytics';
  static const String farmerHelpSupport = '/farmer/help';
  static const String uploadVerification = '/farmer/verification/upload';
  static const String verificationStatus = '/farmer/verification/status';
  static const String productList = '/farmer/products';
  static const String farmerProducts = '/farmer/products';
  static const String addProduct = '/farmer/products/add';
  static const String editProduct = '/farmer/products/edit/:id';
  static const String farmerProductDetails = '/farmer/products/view/:id';
  static const String farmerMain = '/farmer/main';
  static const String farmerOrders = '/farmer/orders';
  static const String farmerOrderDetails = '/farmer/order/:id';
  static const String expiredProducts = '/farmer/expired-products';
  
  // Store Management routes
  static const String storeCustomization = '/farmer/store-customization';
  static const String storeSettings = '/farmer/store-settings';
  static const String pickupSettings = '/farmer/pickup-settings';
  
  // Subscription routes
  static const String subscription = '/farmer/subscription';
  static const String subscriptionRequest = '/farmer/subscription/request';
  static const String adminSubscriptionManagement = '/admin/subscriptions';
  
  // Chat routes
  static const String chatInbox = '/chat';
  static const String chatConversation = '/chat/:conversationId';
  
  // Notifications routes
  static const String notifications = '/notifications';
  
  // Support / AI Chat
  static const String supportChat = '/support-chat';
  
  // Payout routes (Farmer)
  static const String farmerWallet = '/farmer/wallet';
  static const String paymentSettings = '/farmer/payment-settings';
  static const String requestPayout = '/farmer/request-payout';
  
  // Payout routes (Admin)
  static const String adminPayouts = '/admin/payouts';
  
  // Profile routes
  static const String profile = '/profile'; // General profile (defaults to buyer)
  static const String buyerProfile = '/buyer/profile';
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String paymentMethods = '/profile/payment';
  
  // Following routes
  static const String followedStores = '/followed-stores';
  
  // Wishlist routes
  static const String wishlist = '/buyer/wishlist';
  
  // Feedback routes
  static const String submitFeedback = '/feedback';
  static const String submitReport = '/report';
  
  // Admin routes
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminVerifications = '/admin/verifications';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';
  static const String verificationRequests = '/admin/verifications';
  static const String reviewVerification = '/admin/verification/:id';
  static const String adminProductList = '/admin/products';
  static const String adminUserList = '/admin/users';
  static const String reportList = '/admin/reports';
  static const String reportDetails = '/admin/report/:id';
  static const String exportCenter = '/admin/export';
}