# 🚀 Agrilink Deployment Guide

## 📋 Overview

This comprehensive guide covers the complete deployment process for the Agrilink Digital Marketplace application across all platforms.

## 🎯 Prerequisites

### Development Environment
- **Flutter SDK**: 3.9.2 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio**: Latest stable version
- **Xcode**: 14.0+ (for iOS deployment)
- **VS Code** (recommended) with Flutter extensions

### Accounts Required
- **Supabase Account** - Backend services
- **Firebase Account** - Push notifications (optional)
- **Google Console** - Google Sign-In
- **Facebook Developers** - Facebook Sign-In
- **Apple Developer** - iOS App Store (iOS only)
- **Google Play Console** - Android Play Store

## 🔧 Environment Setup

### 1. Clone and Setup Project
```bash
git clone <repository-url>
cd agrilink1
flutter pub get
flutter doctor
```

### 2. Supabase Configuration

#### Create Supabase Project
1. Visit [supabase.com](https://supabase.com)
2. Create new project
3. Note your Project URL and API keys

#### Database Setup
```sql
-- Run these scripts in Supabase SQL Editor
-- 1. Create tables
\i supabase_setup/01_database_schema.sql

-- 2. Setup storage buckets
\i supabase_setup/02_storage_buckets.sql

-- 3. Configure realtime
\i supabase_setup/03_realtime_setup.sql

-- 4. Insert sample data (optional)
\i supabase_setup/04_sample_data.sql

-- 5. Apply schema improvements
\i supabase_setup/05_schema_improvements.sql
```

#### Configure Authentication
```sql
-- Enable social providers in Supabase Dashboard
-- Auth > Settings > Auth Providers
-- Enable: Email, Google, Facebook
```

#### Row Level Security (RLS)
```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- ... (run for all tables)
```

### 3. Update Configuration Files

#### Supabase Service Configuration
```dart
// lib/core/services/supabase_service.dart
class SupabaseService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

#### Google Sign-In Setup
```yaml
# android/app/google-services.json (Android)
# ios/Runner/GoogleService-Info.plist (iOS)
```

```dart
// Update Google client IDs in auth_service.dart
const webClientId = 'YOUR_WEB_CLIENT_ID';
const androidClientId = 'YOUR_ANDROID_CLIENT_ID';
```

#### Facebook Configuration
```xml
<!-- android/app/src/main/res/values/strings.xml -->
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
<string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
```

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>fbYOUR_FACEBOOK_APP_ID</string>
  </dict>
</array>
```

## 📱 Platform-Specific Deployment

### Android Deployment

#### 1. Configure Signing
```bash
# Generate signing key
keytool -genkey -v -keystore ~/agrilink-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias agrilink
```

Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=agrilink
storeFile=/path/to/agrilink-key.jks
```

#### 2. Update Build Configuration
```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.agrilink.app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}
```

#### 3. Build and Deploy
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Install on device
flutter install --release
```

#### 4. Play Store Deployment
1. Create Play Console account
2. Create new app listing
3. Upload app bundle
4. Complete store listing
5. Submit for review

### iOS Deployment

#### 1. Xcode Configuration
```bash
# Open iOS project
open ios/Runner.xcworkspace
```

#### 2. Update Bundle Identifier
```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleIdentifier</key>
<string>com.agrilink.app</string>
```

#### 3. Configure Signing
- Select development team
- Configure provisioning profiles
- Enable required capabilities

#### 4. Build and Deploy
```bash
# Build for iOS
flutter build ios --release

# Archive and upload to App Store Connect
# (Use Xcode Archive feature)
```

#### 5. App Store Deployment
1. Create App Store Connect app
2. Upload build via Xcode
3. Complete app information
4. Submit for review

### Web Deployment

#### 1. Build for Web
```bash
flutter build web --release
```

#### 2. Firebase Hosting (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase init hosting

# Deploy
firebase deploy
```

#### 3. Custom Server Deployment
```nginx
# nginx.conf
server {
    listen 80;
    server_name agrilink.ph;
    
    location / {
        root /var/www/agrilink/build/web;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
}
```

### Desktop Deployment

#### Windows
```bash
# Build Windows app
flutter build windows --release

# Create installer (optional)
# Use tools like Inno Setup or WiX
```

#### macOS
```bash
# Build macOS app
flutter build macos --release

# Create DMG (optional)
# Use create-dmg tool
```

#### Linux
```bash
# Build Linux app
flutter build linux --release

# Create AppImage or Snap package
```

## 🔐 Security Configuration

### Certificate Pinning
```dart
// Add to main.dart for production
class SecurityConfig {
  static void configureSecurity() {
    // Implement certificate pinning
    // Disable debug features
    // Enable obfuscation
  }
}
```

### Environment Variables
```dart
// Create lib/config/environment.dart
class Environment {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');
}
```

### Build with Environment
```bash
# Production build
flutter build apk --release --dart-define=SUPABASE_URL=prod_url
```

## 🔔 Push Notifications Setup

### Firebase Configuration
1. Create Firebase project
2. Add Android/iOS apps
3. Download configuration files
4. Enable Firebase Cloud Messaging

### Server Setup
```javascript
// Firebase Cloud Functions example
exports.sendNotification = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const notification = {
      title: 'Order Update',
      body: 'Your order status has changed',
    };
    
    return admin.messaging().send(notification);
  });
```

## 📊 Monitoring and Analytics

### Error Tracking
```dart
// Add to main.dart
FlutterError.onError = (FlutterErrorDetails details) {
  // Send to crash reporting service
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};
```

### Performance Monitoring
```dart
// Add performance tracking
final Trace trace = FirebasePerformance.instance.newTrace('api_call');
await trace.start();
// ... API call
await trace.stop();
```

### Analytics Setup
```dart
// Firebase Analytics
await FirebaseAnalytics.instance.logEvent(
  name: 'product_view',
  parameters: {
    'product_id': productId,
    'category': category,
  },
);
```

## 🧪 Testing Before Deployment

### Pre-deployment Checklist
```bash
# Run all tests
flutter test

# Integration tests
flutter test integration_test/

# Performance testing
flutter drive --target=test_driver/app.dart

# Build verification
flutter build apk --debug
flutter build ios --debug
flutter build web
```

### Manual Testing
- [ ] All authentication flows
- [ ] Product browsing and search
- [ ] Cart and checkout process
- [ ] Order management
- [ ] Chat functionality
- [ ] Push notifications
- [ ] Offline behavior
- [ ] Different screen sizes
- [ ] Network conditions

## 🚀 Continuous Deployment

### GitHub Actions Example
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter test

  deploy-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - name: Build APK
        run: flutter build apk --release
      - name: Deploy to Play Store
        uses: r0adkll/upload-google-play@v1
```

### Fastlane Configuration
```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to Google Play"
  lane :deploy do
    gradle(task: "bundle", build_type: "Release")
    upload_to_play_store
  end
end
```

## 📋 Post-Deployment

### Monitoring Checklist
- [ ] App store approvals
- [ ] User feedback monitoring
- [ ] Performance metrics
- [ ] Error rates
- [ ] Database performance
- [ ] Server resources
- [ ] Third-party service status

### Maintenance Tasks
- Regular security updates
- Dependency updates
- Performance optimization
- User feedback incorporation
- Feature flag management
- Database maintenance

## 🔧 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build <platform>
```

#### Performance Issues
```dart
// Profile mode testing
flutter run --profile
flutter drive --profile
```

#### Network Issues
```dart
// Add network debugging
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

### Platform-Specific Issues

#### Android
- Check ProGuard rules for release builds
- Verify permissions in AndroidManifest.xml
- Check for 64-bit support

#### iOS
- Verify provisioning profiles
- Check Info.plist permissions
- Ensure proper code signing

#### Web
- Check CORS configuration
- Verify PWA manifest
- Test service worker caching

## 📞 Support

### Development Support
- Email: dev-support@agrilink.ph
- Slack: #agrilink-dev
- Documentation: docs.agrilink.ph

### Production Issues
- Email: ops@agrilink.ph
- Phone: +63 (915) 123-4567
- Status Page: status.agrilink.ph

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Status**: Production Ready ✅