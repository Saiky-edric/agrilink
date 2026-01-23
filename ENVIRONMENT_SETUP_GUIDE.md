# 🔧 Environment Configuration Guide - Agrilink Digital Marketplace

## 🚨 **CRITICAL: Replace All Placeholder Values Before Running**

The application will **NOT work** until you configure proper environment variables with your actual project credentials.

## 📋 **Step-by-Step Setup**

### 1. **Supabase Configuration** (REQUIRED)

#### Get Your Supabase Credentials:
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your **Agrilink** project (or create a new one)
3. Navigate to **Settings** → **API**
4. Copy the following values:
   - **Project URL** (e.g., `https://abc123.supabase.co`)
   - **Anon/Public Key** (starts with `eyJ...`)

#### Update .env file:
```bash
# Replace these placeholder values with your actual Supabase credentials
SUPABASE_URL=https://your-actual-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...your_actual_key
```

### 2. **Google OAuth Setup** (Optional - for Google Sign-In)

#### Configure Google Console:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select your project
3. Enable **Google+ API**
4. Create **OAuth 2.0 credentials**
5. Add your app's package name and SHA-1 certificate

#### Update .env file:
```bash
GOOGLE_WEB_CLIENT_ID=your_actual_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_actual_android_client_id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your_actual_ios_client_id.apps.googleusercontent.com
```

### 3. **Facebook OAuth Setup** (Optional - for Facebook Sign-In)

#### Configure Facebook Developer:
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or use existing
3. Add **Facebook Login** product
4. Get your **App ID**

#### Update .env file:
```bash
FACEBOOK_APP_ID=1234567890123456
```

### 4. **Environment-Specific Configuration**

#### For Different Environments:
```bash
# Development (used during local development)
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=dev_key_here

# Staging (used for testing)
SUPABASE_STAGING_URL=https://staging-project.supabase.co
SUPABASE_STAGING_ANON_KEY=staging_key_here

# Production (used for live app)
SUPABASE_PROD_URL=https://prod-project.supabase.co
SUPABASE_PROD_ANON_KEY=prod_key_here
```

## 🔐 **Security Best Practices**

### ✅ **DO:**
- Keep separate Supabase projects for dev/staging/production
- Use different API keys for each environment
- Add `.env` to your `.gitignore` file (already done)
- Store production secrets in your deployment platform's secret management
- Rotate API keys regularly

### ❌ **DON'T:**
- Commit real credentials to version control
- Share API keys in chat/email
- Use production credentials for development
- Hardcode credentials in your code

## 🛠️ **How Flutter Uses These Variables**

The app reads environment variables through `lib/core/config/environment.dart`:

```dart
// Automatically selects the right environment based on build mode
static String get supabaseUrl {
  switch (current) {
    case Environment.development:    // Debug builds
      return const String.fromEnvironment('SUPABASE_URL');
    case Environment.staging:       // Profile builds  
      return const String.fromEnvironment('SUPABASE_STAGING_URL');
    case Environment.production:    // Release builds
      return const String.fromEnvironment('SUPABASE_PROD_URL');
  }
}
```

## 🚀 **Running the App**

### Development Mode:
```bash
flutter run --dart-define-from-file=.env
```

### Staging Mode:
```bash
flutter run --profile --dart-define-from-file=.env
```

### Production Mode:
```bash
flutter build apk --dart-define-from-file=.env
```

## ⚠️ **Troubleshooting**

### App Won't Start / Supabase Errors:

1. **Check .env file exists**: Ensure `.env` is in the project root
2. **Verify credentials**: Test your Supabase URL and key in the dashboard
3. **Check build command**: Use `--dart-define-from-file=.env`
4. **Review console logs**: Look for "AGRILINK ERROR" messages

### Common Errors:

```
❌ Invalid Supabase URL: https://your-project.supabase.co
✅ Fix: Replace with actual URL like https://abc123.supabase.co

❌ Invalid Supabase API key
✅ Fix: Copy anon/public key from Supabase dashboard

❌ Network error / 401 Unauthorized  
✅ Fix: Check if API key is correct and project is active
```

## 📋 **Verification Checklist**

Before running the app, ensure:

- [ ] `.env` file exists in project root
- [ ] `SUPABASE_URL` contains your actual project URL (not placeholder)
- [ ] `SUPABASE_ANON_KEY` contains your actual anon key (not placeholder)
- [ ] Supabase project is active and accessible
- [ ] Database schema is set up (run SQL files in `supabase_setup/`)
- [ ] Row Level Security (RLS) policies are configured
- [ ] Storage buckets are created (if using file uploads)

## 🆘 **Need Help?**

1. **Check Supabase Documentation**: [docs.supabase.com](https://docs.supabase.com)
2. **Review Error Logs**: Look for specific error messages in console
3. **Test Database Connection**: Use Supabase dashboard SQL editor
4. **Verify Environment**: Print `EnvironmentConfig.current` to check environment detection

---

**⚡ Quick Start**: Copy `.env.example` to `.env`, replace placeholder values with your credentials, and run `flutter run --dart-define-from-file=.env`