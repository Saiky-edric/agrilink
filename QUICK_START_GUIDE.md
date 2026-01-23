# 🚀 Agrilink Quick Start Guide

## ⚡ **Get the App Running in 5 Minutes**

### **Step 1: Configure Environment (2 minutes)**

#### Option A: Interactive Setup (Recommended)
```bash
# Run the setup script (Windows users can run in Git Bash or WSL)
bash scripts/setup_env.sh
```

#### Option B: Manual Setup
```bash
# Copy template to .env
cp .env.example .env

# Edit .env with your preferred editor
code .env
# OR
notepad .env
```

### **Step 2: Get Supabase Credentials (2 minutes)**

1. Go to **[Supabase Dashboard](https://supabase.com/dashboard)**
2. Select your **Agrilink** project (or create new one)
3. Navigate to **Settings** → **API** 
4. Copy these two values:
   - **Project URL**: `https://abc123.supabase.co`
   - **anon/public key**: `eyJhbGciOiJI...` (long string)

### **Step 3: Update .env File (30 seconds)**

Replace these lines in your `.env` file:
```bash
# FROM:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_actual_dev_anon_key_here

# TO: (with your actual values)
SUPABASE_URL=https://cfzjgxfxkvujtrrjkhvu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **Step 4: Validate Configuration (30 seconds)**

```bash
# Check if everything is configured correctly
dart run scripts/validate_env.dart
```

You should see:
```
✅ SUPABASE_URL: Configured
✅ SUPABASE_ANON_KEY: Configured
🎉 All required configuration is valid!
```

### **Step 5: Run the App! (10 seconds)**

```bash
# Start the app with environment configuration
flutter run --dart-define-from-file=.env
```

## 🎉 **Success! Your App Should Now:**

- ✅ **Connect to Supabase** successfully
- ✅ **Show the splash screen** and onboarding
- ✅ **Allow user registration** and login
- ✅ **Display proper error messages** instead of crashes
- ✅ **Navigate between screens** without placeholder errors

## 🚨 **If Something Goes Wrong:**

### **App Crashes on Startup:**
```bash
# Check for configuration errors
dart run scripts/validate_env.dart
```

### **"Invalid Supabase URL" Error:**
- Double-check your project URL from Supabase dashboard
- Ensure it starts with `https://` and ends with `.supabase.co`

### **"401 Unauthorized" Error:**
- Verify your anon key is copied correctly (it's a very long string)
- Check that your Supabase project is active

### **Still Having Issues?**
1. **Check the console logs** for specific error messages
2. **Review ENVIRONMENT_SETUP_GUIDE.md** for detailed troubleshooting
3. **Test your credentials** directly in Supabase dashboard

## 📱 **Next Steps After Setup:**

1. **Test user registration** - Create a new account
2. **Try farmer verification** - Upload test documents  
3. **Browse products** - Add some test products as a farmer
4. **Test ordering** - Place a test order as a buyer
5. **Check admin features** - Log in with admin role

## 🛠️ **Development Workflow:**

```bash
# For daily development
flutter run --dart-define-from-file=.env

# For testing/staging
flutter run --profile --dart-define-from-file=.env

# For production builds
flutter build apk --dart-define-from-file=.env
```

## 🔧 **Optional: Set Up Social Auth**

If you want Google/Facebook login:

### **Google OAuth:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth credentials
3. Add to .env:
```bash
GOOGLE_WEB_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id.apps.googleusercontent.com
```

### **Facebook OAuth:**
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create app and get App ID
3. Add to .env:
```bash
FACEBOOK_APP_ID=1234567890123456
```

## 📋 **Quick Commands Reference:**

```bash
# Setup environment
bash scripts/setup_env.sh

# Validate configuration  
dart run scripts/validate_env.dart

# Run app
flutter run --dart-define-from-file=.env

# Build for production
flutter build apk --dart-define-from-file=.env

# Clean and rebuild
flutter clean && flutter pub get
```

---

**🎯 Goal**: Get from "git clone" to "running app" in under 5 minutes!

**📚 Need more details?** See `ENVIRONMENT_SETUP_GUIDE.md` for comprehensive documentation.