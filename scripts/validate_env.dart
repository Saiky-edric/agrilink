#!/usr/bin/env dart

/// Environment Configuration Validator for Agrilink Digital Marketplace
/// 
/// This script validates that all required environment variables are properly configured
/// and provides helpful feedback for missing or invalid configurations.

import 'dart:io';

void main() async {
  print('🔧 Agrilink Environment Configuration Validator');
  print('=' * 60);
  
  bool allValid = true;
  
  // Check if .env file exists
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found!');
    print('📋 Solution: Copy .env.example to .env and configure it');
    print('   cp .env.example .env');
    exit(1);
  }
  
  print('✅ .env file found');
  
  // Read .env file
  final envContent = await envFile.readAsString();
  final envVars = <String, String>{};
  
  // Parse .env file
  for (String line in envContent.split('\n')) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      envVars[key] = value;
    }
  }
  
  // Required variables
  final requiredVars = {
    'SUPABASE_URL': 'Supabase Project URL',
    'SUPABASE_ANON_KEY': 'Supabase Anonymous/Public Key',
  };
  
  // Optional but recommended variables
  final optionalVars = {
    'GOOGLE_WEB_CLIENT_ID': 'Google OAuth Web Client ID',
    'GOOGLE_ANDROID_CLIENT_ID': 'Google OAuth Android Client ID',
    'FACEBOOK_APP_ID': 'Facebook App ID',
    'SUPABASE_STAGING_URL': 'Staging Environment URL',
    'SUPABASE_PROD_URL': 'Production Environment URL',
  };
  
  print('\n🔍 Validating Required Configuration:');
  print('-' * 40);
  
  // Check required variables
  for (final entry in requiredVars.entries) {
    final key = entry.key;
    final description = entry.value;
    final value = envVars[key];
    
    if (value == null || value.isEmpty) {
      print('❌ $key: Missing');
      print('   Description: $description');
      allValid = false;
    } else if (_isPlaceholder(value)) {
      print('⚠️  $key: Contains placeholder value');
      print('   Current: $value');
      print('   Description: $description');
      allValid = false;
    } else {
      print('✅ $key: Configured');
      if (key == 'SUPABASE_URL') {
        _validateSupabaseUrl(value);
      }
    }
  }
  
  print('\n🔧 Optional Configuration:');
  print('-' * 40);
  
  // Check optional variables
  for (final entry in optionalVars.entries) {
    final key = entry.key;
    final description = entry.value;
    final value = envVars[key];
    
    if (value == null || value.isEmpty) {
      print('⚪ $key: Not configured (optional)');
    } else if (_isPlaceholder(value)) {
      print('⚠️  $key: Contains placeholder value');
      print('   Current: $value');
    } else {
      print('✅ $key: Configured');
    }
  }
  
  print('\n📊 Validation Summary:');
  print('-' * 40);
  
  if (allValid) {
    print('🎉 All required configuration is valid!');
    print('🚀 Your app should connect to Supabase successfully.');
    print('\n💡 Next steps:');
    print('   1. Run: flutter run --dart-define-from-file=.env');
    print('   2. Test authentication and database operations');
    print('   3. Check console logs for any connection issues');
  } else {
    print('❌ Configuration issues found!');
    print('\n🛠️  How to fix:');
    print('   1. Go to: https://supabase.com/dashboard');
    print('   2. Select your Agrilink project');
    print('   3. Go to Settings → API');
    print('   4. Copy Project URL and anon/public key to .env');
    print('   5. Run this validator again');
    exit(1);
  }
  
  print('\n📚 For detailed setup instructions, see: ENVIRONMENT_SETUP_GUIDE.md');
}

bool _isPlaceholder(String value) {
  final placeholders = [
    'your-project.supabase.co',
    'your_actual_dev_anon_key_here',
    'your_anon_key_here',
    'your_google_web_client_id',
    'your_google_android_client_id',
    'your_facebook_app_id',
    'YOUR_',
    'your_',
    'placeholder',
  ];
  
  final lowerValue = value.toLowerCase();
  return placeholders.any((placeholder) => 
    lowerValue.contains(placeholder.toLowerCase())
  );
}

void _validateSupabaseUrl(String url) {
  if (!url.startsWith('https://')) {
    print('   ⚠️  URL should start with https://');
  }
  if (!url.contains('.supabase.co')) {
    print('   ⚠️  URL should contain .supabase.co');
  }
  if (url.length < 30) {
    print('   ⚠️  URL seems too short, verify it\'s correct');
  }
}
