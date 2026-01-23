# 🔐 Complete Guide: Enable Google & Facebook Authentication

## 📋 Overview

Your Agrilink app **already has Google and Facebook authentication implemented** in the code! You just need to configure the OAuth credentials. This guide will walk you through the complete setup process.

**Current Status:**
- ✅ Code implementation complete
- ✅ UI components ready (social sign-in buttons)
- ⚠️ **Configuration needed** - OAuth credentials must be set up
- ⚠️ **Supabase providers** - Must be enabled in dashboard

---

## 🎯 What You'll Accomplish

By following this guide, you'll enable:
1. **Google Sign-In** - One-tap authentication with Google accounts
2. **Facebook Sign-In** - Seamless login with Facebook
3. **Automatic Profile Creation** - Users automatically get profiles in your database
4. **Role Selection Flow** - New social users choose buyer/farmer role

---

## 🚀 Step-by-Step Setup

### **STEP 1: Configure Google OAuth** 🔴

#### **1.1 - Access Google Cloud Console**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Create a new project or select existing one
   - Project name: `Agrilink` (or your preferred name)

#### **1.2 - Enable Required APIs**
1. In the Google Cloud Console, go to **APIs & Services** → **Library**
2. Search and enable:
   - **Google Sign-In API** (or Google Identity Services)
   - ~~Google+ API~~ (deprecated, not needed)

#### **1.3 - Create OAuth 2.0 Credentials**

**For Android:**
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Choose **Android** as application type
4. Fill in:
   - **Name**: `Agrilink Android`
   - **Package name**: `com.example.agrlink1` (from your build.gradle.kts)
   - **SHA-1 certificate fingerprint**: Get it by running:
     ```bash
     cd android
     ./gradlew signingReport
     ```
     Copy the SHA-1 from **debug** variant (looks like: `AA:BB:CC:...`)
5. Click **Create**
6. **Save the Client ID** (format: `xxxxx.apps.googleusercontent.com`)

**For Web (Required for Supabase):**
1. Click **Create Credentials** → **OAuth 2.0 Client ID** again
2. Choose **Web application**
3. Fill in:
   - **Name**: `Agrilink Web`
   - **Authorized redirect URIs**: Add your Supabase callback URL:
     ```
     https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback
     ```
4. Click **Create**
5. **Save both**:
   - Client ID (looks like: `xxxxx.apps.googleusercontent.com`)
   - Client Secret (looks like: `GOCSPX-xxxxx`)

#### **1.4 - Configure OAuth Consent Screen**
1. Go to **OAuth consent screen** in Google Cloud Console
2. Choose **External** (unless you have Google Workspace)
3. Fill in required information:
   - **App name**: `Agrilink`
   - **User support email**: Your email
   - **Developer contact**: Your email
4. Add scopes:
   - `email`
   - `profile`
5. Save and continue

---

### **STEP 2: Configure Facebook OAuth** 🔵

#### **2.1 - Create Facebook App**
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Choose **Consumer** as app type
4. Fill in:
   - **App name**: `Agrilink`
   - **App contact email**: Your email
5. Click **Create App**

#### **2.2 - Add Facebook Login Product**
1. In your app dashboard, click **Add Product**
2. Find **Facebook Login** and click **Set Up**
3. Choose **Android** platform
4. Follow the setup wizard:
   - **Package Name**: `com.example.agrlink1`
   - **Default Activity Class Name**: `com.example.agrlink1.MainActivity`
   - **Key Hashes**: Generate by running:
     ```bash
     keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
     ```
     Password is usually: `android`

#### **2.3 - Get Facebook App ID**
1. In your Facebook App dashboard, go to **Settings** → **Basic**
2. Copy your **App ID** (looks like: `123456789012345`)
3. Copy your **App Secret** (click **Show** button)

#### **2.4 - Configure Android for Facebook**

**Create/Update `android/app/src/main/res/values/strings.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Agrilink</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```
Replace `YOUR_FACEBOOK_APP_ID` with your actual App ID.

**Update `android/app/src/main/AndroidManifest.xml`:**
Add inside the `<application>` tag (after the existing `<meta-data>` tags):
```xml
<!-- Facebook Configuration -->
<meta-data 
    android:name="com.facebook.sdk.ApplicationId" 
    android:value="@string/facebook_app_id"/>
    
<meta-data 
    android:name="com.facebook.sdk.ClientToken" 
    android:value="@string/facebook_client_token"/>

<!-- Facebook Login Activity -->
<activity 
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />
    
<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

---

### **STEP 3: Configure Supabase Authentication Providers** 🟢

#### **3.1 - Enable Google Provider in Supabase**
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `cfzjgxfxkvujtrrjkhvu`
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the list
5. Click to expand and configure:
   - **Enable Google provider**: Toggle ON
   - **Client ID (for OAuth)**: Paste your **Web Client ID** from Step 1.3
   - **Client Secret (for OAuth)**: Paste your **Client Secret** from Step 1.3
   - **Authorized Client IDs**: Add your **Android Client ID** from Step 1.3
6. Click **Save**

#### **3.2 - Enable Facebook Provider in Supabase**
1. In the same **Authentication** → **Providers** page
2. Find **Facebook** in the list
3. Click to expand and configure:
   - **Enable Facebook provider**: Toggle ON
   - **Facebook App ID**: Paste your **App ID** from Step 2.3
   - **Facebook App Secret**: Paste your **App Secret** from Step 2.3
   - **Authorized Client IDs**: Leave empty (uses App ID)
4. Click **Save**

#### **3.3 - Add Redirect URLs to Provider Platforms**

**In Google Cloud Console:**
1. Go back to your Web OAuth Client
2. Add to **Authorized redirect URIs**:
   ```
   https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback
   ```

**In Facebook Developers:**
1. Go to **Facebook Login** → **Settings**
2. Add to **Valid OAuth Redirect URIs**:
   ```
   https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback
   ```
3. Save changes

---

### **STEP 4: Update Your App Configuration** 📝

#### **4.1 - Update Environment Configuration**

The app already has default Google Client IDs in `lib/core/config/environment.dart`, but you should update them with your own:

**Option A: Use .env file (Recommended):**
1. Create a `.env` file in your project root (it's already in .gitignore)
2. Add your credentials:
```env
GOOGLE_WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your_ios_client_id.apps.googleusercontent.com
FACEBOOK_APP_ID=your_facebook_app_id
```

**Option B: Directly update the code:**
Edit `lib/core/config/environment.dart` and replace the default values:
```dart
static String get googleWebClientId {
  return const String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Replace this
  );
}

static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com', // Replace this
  );
}
```

---

### **STEP 5: Test Your Implementation** 🧪

#### **5.1 - Build and Run**
```bash
# Clean build
flutter clean
flutter pub get

# Build for Android
flutter build apk --debug

# Or run directly on device/emulator
flutter run
```

#### **5.2 - Test Google Sign-In**
1. Launch the app
2. Navigate to the **Login Screen**
3. You should see the **"Continue with Google"** button
4. Tap it and sign in with your Google account
5. You should be redirected to **Role Selection** screen (for new users)
6. Choose **Buyer** or **Farmer**
7. Complete address setup
8. Verify you're logged in!

#### **5.3 - Test Facebook Sign-In**
1. On the login screen, tap **"Continue with Facebook"**
2. Log in with your Facebook account
3. Grant permissions
4. Complete role selection and address setup
5. Verify successful login!

---

## 🐛 Troubleshooting

### **Google Sign-In Issues**

**Error: "Unacceptable audience in id_token"**
- ✅ **Fix**: Make sure your Web Client ID is added to Supabase
- ✅ Check that Android Client ID is added to "Authorized Client IDs" in Supabase

**Error: "Developer Error"**
- ✅ Verify SHA-1 fingerprint matches in Google Cloud Console
- ✅ Check package name is exactly `com.example.agrlink1`

**Sign-in cancelled immediately**
- ✅ Make sure Google Play Services is installed on device/emulator
- ✅ Try on a real device instead of emulator

### **Facebook Sign-In Issues**

**Error: "Invalid Key Hash"**
- ✅ Regenerate your key hash and add it to Facebook App settings
- ✅ Debug and release key hashes are different

**App not approved**
- ✅ For testing, add your Facebook account as a test user in App Roles

**Error: "Invalid redirect URI"**
- ✅ Verify callback URL in Facebook Login settings matches Supabase

### **General Issues**

**Social buttons not showing**
- ✅ They're already in `lib/features/auth/screens/login_screen.dart`
- ✅ Check lines 319-345 for Google button
- ✅ Check lines 347-373 for Facebook button

**Profile not created**
- ✅ Check Supabase logs in Dashboard → Logs → Postgres Logs
- ✅ Verify RLS policies allow inserts to `users` table

---

## 📱 User Flow After Setup

### **New User Experience:**
1. User taps Google/Facebook button on login screen
2. Authenticates with social provider
3. Redirected to **Role Selection Screen** (buyer/farmer)
4. Redirected to **Address Setup Screen**
5. Lands on appropriate dashboard (buyer home or farmer dashboard)

### **Returning User Experience:**
1. User taps social login button
2. Instantly authenticated
3. Lands directly on their dashboard

---

## 🔒 Security Notes

- ✅ **Never commit** `.env` file with real credentials
- ✅ Use different OAuth credentials for **production**
- ✅ Keep your **Client Secrets** private
- ✅ Enable **App Check** in production for additional security
- ✅ Review OAuth scopes - only request what you need

---

## 📚 Additional Resources

- [Google Sign-In Setup](https://pub.dev/packages/google_sign_in)
- [Facebook Login Setup](https://pub.dev/packages/flutter_facebook_auth)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth 2.0 Overview](https://oauth.net/2/)

---

## ✅ Checklist

Before going live, make sure:

- [ ] Google OAuth credentials created
- [ ] Facebook App created and configured
- [ ] Supabase providers enabled
- [ ] Android manifest updated
- [ ] strings.xml created with Facebook credentials
- [ ] Redirect URIs added to all platforms
- [ ] Tested on real device
- [ ] Tested both Google and Facebook flows
- [ ] Address setup works for social users
- [ ] Role selection works correctly

---

## 🎉 Success!

Once you complete these steps, your users will be able to:
- ✅ Sign in with Google in one tap
- ✅ Sign in with Facebook seamlessly  
- ✅ Get automatic profile creation
- ✅ Choose their role (buyer/farmer)
- ✅ Enjoy a smooth onboarding experience

**Need help?** Check the troubleshooting section or review the existing documentation files:
- `SOCIAL_AUTH_SETUP.md`
- `GOOGLE_SIGNIN_FIX_GUIDE.md`

Good luck! 🚀
