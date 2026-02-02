import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment get current {
    if (kDebugMode) {
      return Environment.development;
    } else if (kProfileMode) {
      return Environment.staging;
    } else {
      return Environment.production;
    }
  }

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  // Feature flags
  static bool get enableDevicePreview => isDevelopment;
  static bool get enableDebugLogs => isDevelopment || isStaging;
  static bool get enablePerformanceOverlay => isDevelopment;

  // API Configuration
  static String get supabaseUrl {
    switch (current) {
      case Environment.development:
        return 'https://cfzjgxfxkvujtrrjkhvu.supabase.co';
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_STAGING_URL',
          defaultValue: 'https://cfzjgxfxkvujtrrjkhvu.supabase.co',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'SUPABASE_PROD_URL',
          defaultValue: 'https://cfzjgxfxkvujtrrjkhvu.supabase.co',
        );
    }
  }

  static String get supabaseAnonKey {
    switch (current) {
      case Environment.development:
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmempneGZ4a3Z1anRycmpraHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzQ0NzksImV4cCI6MjA3OTY1MDQ3OX0.yDkoBH556SrR9hyE9A6z-mg-oF_TJ1hDN-EXoSuJktY';
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_STAGING_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmempneGZ4a3Z1anRycmpraHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzQ0NzksImV4cCI6MjA3OTY1MDQ3OX0.yDkoBH556SrR9hyE9A6z-mg-oF_TJ1hDN-EXoSuJktY',
        );
      case Environment.production:
        return const String.fromEnvironment(
          'SUPABASE_PROD_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmempneGZ4a3Z1anRycmpraHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNzQ0NzksImV4cCI6MjA3OTY1MDQ3OX0.yDkoBH556SrR9hyE9A6z-mg-oF_TJ1hDN-EXoSuJktY',
        );
    }
  }

  // OAuth Configuration
  static String get googleWebClientId {
    return const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '205313374680-nkbkq2q6eoreveun82auft1qfripdnh8.apps.googleusercontent.com',
    );
  }

  static String get googleAndroidClientId {
    return const String.fromEnvironment(
      'GOOGLE_ANDROID_CLIENT_ID',
      defaultValue:
          '205313374680-clvjt5uumap75r9jkjbqpa484j20c3mc.apps.googleusercontent.com',
    );
  }

  static String get googleIosClientId {
    return const String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: 'YOUR_GOOGLE_IOS_CLIENT_ID',
    );
  }

  // Logging configuration
  static void log(String message) {
    if (enableDebugLogs) {
      debugPrint('🟢 AGRILINK: $message');
    }
    // Also print to console in debug mode for visibility
    if (kDebugMode) {
      print('🟢 AGRILINK: $message');
    }
  }

  // Test logging method to verify logs are working
  static void testLogging() {
    log('🧪 LOGGING TEST - Normal log message');
    logError('🧪 LOGGING TEST - Error log message', Exception('Test error'),
        StackTrace.current);
    print('🔍 DIRECT PRINT - This should always appear in terminal');
  }

  static void logError(String message,
      [Object? error, StackTrace? stackTrace]) {
    if (enableDebugLogs) {
      debugPrint('🔴 AGRILINK ERROR: $message');
      if (error != null) debugPrint('💥 Error Details: $error');
      if (stackTrace != null) debugPrint('📍 Stack Trace: $stackTrace');
    }
    // Also print to console in debug mode for visibility
    if (kDebugMode) {
      print('🔴 AGRILINK ERROR: $message');
      if (error != null) print('💥 Error Details: $error');
      if (stackTrace != null) print('📍 Stack Trace: $stackTrace');
    }
  }
}
