import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      // Validate credentials before initialization
      final url = EnvironmentConfig.supabaseUrl;
      final anonKey = EnvironmentConfig.supabaseAnonKey;
      
      if (url.isEmpty || url == 'https://your-project.supabase.co') {
        throw Exception('❌ Invalid Supabase URL: $url\nPlease update your .env file or environment.dart');
      }
      
      if (anonKey.isEmpty || anonKey.startsWith('YOUR_') || anonKey == 'your_anon_key_here') {
        throw Exception('❌ Invalid Supabase API key\nPlease update your .env file with a valid anon key');
      }
      
      EnvironmentConfig.log('🔐 Initializing Supabase...');
      EnvironmentConfig.log('📍 URL: $url');
      EnvironmentConfig.log('🔑 Key: ${anonKey.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      // Test the connection
      // Connection initialized; avoid protected queries that may fail under RLS.
      EnvironmentConfig.log('✅ Supabase initialized successfully for ${EnvironmentConfig.current} environment');
    } catch (e) {
      EnvironmentConfig.logError('💥 Failed to initialize Supabase', e);
      
      if (e.toString().contains('401') || e.toString().contains('Invalid API key')) {
        EnvironmentConfig.logError('🔧 API Key Issue Detected:', 
          'Your Supabase API key may be expired or incorrect.\n'
          '1. Go to: https://supabase.com/dashboard/project/cfzjgxfxkvujtrrjkhvu/settings/api\n'
          '2. Copy the "anon/public" key\n'
          '3. Update your .env file with the new key'
        );
      }
      rethrow;
    }
  }

  // Auth helpers
  User? get currentUser => client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Database helpers
  SupabaseQueryBuilder get users => client.from('users');
  SupabaseQueryBuilder get farmerVerifications =>
      client.from('farmer_verifications');
  SupabaseQueryBuilder get products => client.from('products');
  SupabaseQueryBuilder get orders => client.from('orders');
  SupabaseQueryBuilder get orderItems => client.from('order_items');
  SupabaseQueryBuilder get conversations => client.from('conversations');
  SupabaseQueryBuilder get messages => client.from('messages');
  SupabaseQueryBuilder get feedback => client.from('feedback');
  SupabaseQueryBuilder get reports => client.from('reports');
  SupabaseQueryBuilder get cart => client.from('cart');
  SupabaseQueryBuilder get paymentMethods => client.from('payment_methods');
  SupabaseQueryBuilder get userAddresses => client.from('user_addresses');
  SupabaseQueryBuilder get userFavorites => client.from('user_favorites');
  
  // New table helpers to match schema
  SupabaseQueryBuilder get notifications => client.from('notifications');
  SupabaseQueryBuilder get productReviews => client.from('product_reviews');
  SupabaseQueryBuilder get sellerReviews => client.from('seller_reviews');
  SupabaseQueryBuilder get sellerStatistics => client.from('seller_statistics');
  SupabaseQueryBuilder get storeSettings => client.from('store_settings');
  SupabaseQueryBuilder get userSettings => client.from('user_settings');
  SupabaseQueryBuilder get platformSettings => client.from('platform_settings');
  SupabaseQueryBuilder get adminActivities => client.from('admin_activities');

  // Storage helpers
  SupabaseStorageClient get storage => client.storage;

  String getPublicUrl(String bucket, String path) {
    return storage.from(bucket).getPublicUrl(path);
  }

  // Realtime helpers
  RealtimeChannel subscribe(String channelName) {
    return client.channel(channelName);
  }

  // Edge Function helpers
  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return await client.functions.invoke(
      functionName,
      body: body,
      headers: headers,
    );
  }
}

// Database table names
class Tables {
  static const String users = 'users';
  static const String farmerVerifications = 'farmer_verifications';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String conversations = 'conversations';
  static const String messages = 'messages';
  static const String feedback = 'feedback';
  static const String reports = 'reports';
  static const String cart = 'cart';
}

// Storage bucket names
class StorageBuckets {
  static const String verificationDocuments = 'verification-documents';
  static const String productImages = 'product-images';
  static const String reportImages = 'report-images';
  static const String userAvatars = 'user-avatars';
  static const String storeBanners = 'store-banners';
  static const String storeLogos = 'store-logos';
}

// Edge function names
class EdgeFunctions {
  static const String hideExpiredProducts = 'hide-expired-products';
  static const String exportUsers = 'export-users';
  static const String exportProducts = 'export-products';
  static const String exportOrders = 'export-orders';
  static const String exportReports = 'export-reports';
  static const String exportFeedback = 'export-feedback';
  static const String exportVerifications = 'export-verifications';
}
