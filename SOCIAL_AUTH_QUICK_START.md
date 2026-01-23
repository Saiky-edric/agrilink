# 🚀 Social Auth Quick Start - 5 Minute Setup

## ⚡ Fast Track Setup Guide

If you just want to get Google and Facebook login working ASAP, follow these steps:

---

## 📋 Prerequisites

- Google account
- Facebook account
- Supabase project already running (✅ You have this: `cfzjgxfxkvujtrrjkhvu.supabase.co`)

---

## 🔴 STEP 1: Google Setup (2 minutes)

### 1. Get SHA-1 Fingerprint
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 from **debug** section (looks like `AA:BB:CC:DD:...`)

### 2. Create Google OAuth Client
1. Go to: https://console.cloud.google.com/
2. Create project → Name it "Agrilink"
3. **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
4. Create **Android** client:
   - Package: `com.example.agrlink1`
   - SHA-1: Paste what you copied above
   - Click **Create** → Copy the **Client ID**
5. Create **Web** client:
   - Authorized redirect URI: `https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback`
   - Click **Create** → Copy **Client ID** and **Client Secret**

### 3. Configure OAuth Consent Screen
1. **OAuth consent screen** → **External**
2. Fill: App name: `Agrilink`, Your email
3. Add scopes: `email`, `profile`
4. Save

---

## 🔵 STEP 2: Facebook Setup (2 minutes)

### 1. Create Facebook App
1. Go to: https://developers.facebook.com/
2. **My Apps** → **Create App** → **Consumer**
3. App name: `Agrilink`
4. Add **Facebook Login** product

### 2. Configure Android
1. Settings → Basic → Copy your **App ID** and **App Secret**
2. Add Platform → **Android**:
   - Package: `com.example.agrlink1`
   - Class: `com.example.agrlink1.MainActivity`
   - Key Hash: Generate using:
     ```bash
     keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
     ```
     (Password: `android`)

### 3. Update strings.xml
**File already created at:** `android/app/src/main/res/values/strings.xml`

Replace the placeholders:
```xml
<string name="facebook_app_id">PASTE_YOUR_APP_ID_HERE</string>
<string name="fb_login_protocol_scheme">fbPASTE_YOUR_APP_ID_HERE</string>
<string name="facebook_client_token">PASTE_YOUR_CLIENT_TOKEN_HERE</string>
```

---

## 🟢 STEP 3: Supabase Configuration (1 minute)

1. Go to: https://supabase.com/dashboard
2. Select your project
3. **Authentication** → **Providers**

### Enable Google:
- Toggle **ON**
- Paste **Web Client ID** and **Client Secret** from Step 1
- Add your **Android Client ID** to "Authorized Client IDs"
- **Save**

### Enable Facebook:
- Toggle **ON**  
- Paste **App ID** and **App Secret** from Step 2
- **Save**

### Add Redirect URIs:
**In Google Console:**
- Add to redirect URIs: `https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback`

**In Facebook Settings:**
- Facebook Login → Settings → Valid OAuth Redirect URIs
- Add: `https://cfzjgxfxkvujtrrjkhvu.supabase.co/auth/v1/callback`

---

## 📝 STEP 4: Update App Config (30 seconds)

Edit: `lib/core/config/environment.dart`

Replace lines 67 and 74 with your Client IDs:
```dart
static String get googleWebClientId {
  return const String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // ← Replace
  );
}

static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com', // ← Replace
  );
}
```

---

## 🧪 STEP 5: Test It! (1 minute)

```bash
flutter clean
flutter pub get
flutter run
```

1. Navigate to Login screen
2. Tap **"Continue with Google"** → Should work! ✅
3. Tap **"Continue with Facebook"** → Should work! ✅

---

## ✅ What's Already Done

Your app already has:
- ✅ Google Sign-In package installed
- ✅ Facebook Auth package installed
- ✅ Social login buttons in UI
- ✅ Authentication service with social methods
- ✅ Role selection flow for social users
- ✅ Android manifest updated with Facebook config
- ✅ strings.xml file created

You just need to add your OAuth credentials!

---

## 🐛 Quick Troubleshooting

**Google sign-in cancelled immediately?**
→ Check SHA-1 fingerprint matches exactly

**Facebook "Invalid Key Hash"?**
→ Regenerate key hash and add to Facebook App settings

**"Unacceptable audience" error?**
→ Web Client ID must be in Supabase "Authorized Client IDs"

**Still not working?**
→ Read the full guide: `ENABLE_SOCIAL_AUTH_GUIDE.md`

---

## 📱 Expected User Flow

**New User:**
1. Taps Google/Facebook button
2. Signs in with their account
3. **Role Selection Screen** → Chooses Buyer or Farmer
4. **Address Setup** → Completes profile
5. Redirected to dashboard ✅

**Existing User:**
1. Taps social button
2. Instantly logged in
3. Goes straight to dashboard ✅

---

## 🎉 You're Done!

Total setup time: **~5 minutes**

Need detailed instructions? Check `ENABLE_SOCIAL_AUTH_GUIDE.md` for the comprehensive guide.

Happy coding! 🚀
