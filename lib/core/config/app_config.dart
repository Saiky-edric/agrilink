class AppConfig {
  // App Information
  static const String appName = 'Agrilink Digital Marketplace';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Company Information
  static const String companyName = 'Agrilink';
  static const String supportEmail = 'support@agrilink.com';
  static const String supportPhone = '+63 123 456 7890';
  
  // Feature Flags
  static const bool enableSocialAuth = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int cacheExpiryHours = 24;
  
  // UI Configuration
  static const int itemsPerPage = 20;
  static const int maxImageSizeMB = 5;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  
  // Business Rules
  static const int minPasswordLength = 8;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const double minOrderAmount = 50.0;
  static const double maxOrderAmount = 50000.0;
  
  // Validation Rules
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^(\+63|0)[0-9]{10}$';
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String serverErrorMessage = 'Something went wrong. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please sign in again.';
  static const String permissionErrorMessage = 'Permission denied. Please contact support.';
  
  // Agusan del Sur Municipalities (for address validation)
  static const List<String> municipalities = [
    'Agusan',
    'Bayugan',
    'Bunawan',
    'Esperanza',
    'La Paz',
    'Loreto',
    'Prosperidad',
    'Rosario',
    'San Francisco',
    'San Luis',
    'Santa Josefa',
    'Sibagat',
    'Talacogon',
    'Trento',
    'Veruela',
  ];
  
  // User Roles
  static const List<String> userRoles = ['buyer', 'farmer', 'admin'];
  
  // Product Categories
  static const List<String> productCategories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Livestock',
    'Dairy',
    'Seafood',
    'Herbs & Spices',
    'Others',
  ];
}