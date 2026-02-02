# 🔧 Google Sign-In with Supabase - Complete Fix

## ⚠️ Current Issue

Error: `No ID Token found`

This happens because Google Sign-In isn't properly configured for Supabase.

---

## ✅ Correct Setup for Supabase (No Firebase Needed!)

You're using **Supabase**, so we need to configure Google OAuth directly with Supabase, NOT Firebase.

---

## 📋 Step-by-Step Fix

### **Step 1: Create Google OAuth Credentials** (5 minutes)

1. Go to **Google Cloud Console**: https://console.cloud.google.com
2. Create a new project OR select existing project
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**

---

### **Step 2: Configure OAuth Consent Screen** (First Time Only)

If prompted:

1. Click **Configure Consent Screen**
2. Select **External** (for testing)
3. Fill in:
   - **App name**: Agrilink
   - **User support email**: Your email
   - **Developer contact**: Your email
4. Click **Save and Continue**
5. Skip **Scopes** (click Save and Continue)
6. Skip **Test users** (click Save and Continue)
7. Click **Back to Dashboard**

---

### **Step 3: Create OAuth Client ID**

1. Back to **Credentials** → **Create Credentials** → **OAuth client ID**

2. **Create ANDROID OAuth Client:**
   - Application type: **Android**
   - Name: `Agrilink Android`
   - Package name: `com.example.agrilink1`
   - SHA-1: Get using command below
   - Click **Create**

**Get SHA-1 fingerprint:**
```bash
# On Windows
cd android
gradlew.bat signingReport

# On Mac/Linux
cd android
./gradlew signingReport
```

Copy the SHA1 from the output (debug variant).

3. **Also Create WEB OAuth Client:**
   - Click **Create Credentials** → **OAuth client ID** again
   - Application type: **Web application**
   - Name: `Agrilink Web`
   - Authorized JavaScript origins: (leave empty for now)
   - Authorized redirect URIs:
     - `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
     - Replace `YOUR-PROJECT-REF` with your Supabase project ref
   - Click **Create**
   - **SAVE the Client ID and Client Secret** - you'll need these!

---

### **Step 4: Configure Supabase** (2 minutes)

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your **Agrilink** project
3. Go to **Authentication** → **Providers**
4. Find **Google** in the list
5. Toggle **Enabled** to ON
6. Enter:
   - **Client ID**: (The WEB client ID from Step 3)
   - **Client Secret**: (The WEB client secret from Step 3)
   - **Redirect URL**: Should auto-fill (copy this for later)
7. Click **Save**

---

### **Step 5: Update Your Code** (3 minutes)

#### **Option A: Use Server Client ID (Recommended)**

Update `lib/core/services/auth_service.dart`:

```dart
Future<UserModel?> signInWithGoogle() async {
  try {
    EnvironmentConfig.log('🚀 Starting Google Sign-In process...');
    
    // Use the Web Client ID from Google Cloud Console
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com', // ADD THIS!
    );

    EnvironmentConfig.log('📱 Initiating Google sign-in...');
    final googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Failed to get tokens from Google');
    }

    // Authenticate with Supabase
    final response = await _supabase.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.user != null) {
      // Handle user creation/login
      // ... rest of your code
    }

    return null;
  } catch (e) {
    EnvironmentConfig.logError('Google sign-in error', e);
    rethrow;
  }
}
```

**Replace `YOUR-WEB-CLIENT-ID` with the actual Web Client ID from Google Cloud Console!**

#### **Option B: Store in Environment Config**

Create/update `lib/core/config/environment.dart`:

```dart
class EnvironmentConfig {
  // ... other config
  
  // Google OAuth Web Client ID (from Google Cloud Console)
  static const String googleWebClientId = 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
}
```

Then in `auth_service.dart`:

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: EnvironmentConfig.googleWebClientId,
);
```

---

### **Step 6: Update google-services.json (Android Only)** (2 minutes)

Even though you're using Supabase, you still need a basic `google-services.json` for Android.

**Option 1: Minimal google-services.json (Quick Fix)**

Replace `android/app/google-services.json` with:

```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "agrilink-app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abc123",
        "android_client_info": {
          "package_name": "com.example.agrilink1"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR-ANDROID-CLIENT-ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.agrilink1",
            "certificate_hash": "YOUR_SHA1_FINGERPRINT"
          }
        },
        {
          "client_id": "YOUR-WEB-CLIENT-ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "YOUR_ANDROID_API_KEY"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

**Replace:**
- `YOUR-ANDROID-CLIENT-ID` - From Step 3 (Android client)
- `YOUR-WEB-CLIENT-ID` - From Step 3 (Web client)
- `YOUR_SHA1_FINGERPRINT` - Your SHA-1 from signingReport
- `YOUR_ANDROID_API_KEY` - From Google Cloud Console → Credentials → API Keys

**Option 2: Download from Google Cloud (Better)**

1. Go to Google Cloud Console
2. Enable **Firebase API** (even if not using Firebase)
3. This will create a Firebase project
4. Download `google-services.json` from Firebase Console
5. The file will have proper oauth_client array

---

### **Step 7: Clean and Rebuild** (1 minute)

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Test Google Sign-In

1. Run the app
2. Go to Login screen
3. Click "Continue with Google"
4. Select Google account
5. Should work! ✅

---

## 🔍 Troubleshooting

### **Still getting "No ID Token"?**

**Check 1: serverClientId Added?**
```dart
GoogleSignIn(
  serverClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com', // Must have this!
)
```

**Check 2: Web Client ID Correct?**
- Go to Google Cloud Console → Credentials
- Copy the Web Client ID (not Android!)
- Ends with `.apps.googleusercontent.com`

**Check 3: Supabase Google Provider Enabled?**
- Supabase Dashboard → Authentication → Providers → Google
- Toggle should be ON
- Client ID and Secret should be filled

**Check 4: oauth_client in google-services.json?**
- Open `android/app/google-services.json`
- Check `oauth_client` array is NOT empty
- Should have both Android and Web client entries

---

### **Error: "Sign in failed" or "PlatformException"?**

**Cause**: SHA-1 fingerprint not registered or wrong

**Fix:**
1. Get SHA-1: `cd android && ./gradlew signingReport`
2. Go to Google Cloud Console → Credentials
3. Edit your Android OAuth client
4. Update SHA-1 fingerprint
5. Wait 5 minutes for changes to propagate
6. Try again

---

### **Error: "Invalid client"?**

**Cause**: Wrong Client ID or not configured in Supabase

**Fix:**
1. Double-check Web Client ID in Supabase matches Google Cloud
2. Make sure Client Secret is correct
3. Verify Google provider is enabled in Supabase
4. Check redirect URL matches

---

## 📝 Summary of What You Need

### **From Google Cloud Console:**
1. ✅ **Android OAuth Client** (with SHA-1)
2. ✅ **Web OAuth Client** (Client ID + Secret)

### **In Supabase:**
1. ✅ **Google provider enabled**
2. ✅ **Web Client ID configured**
3. ✅ **Web Client Secret configured**

### **In Your Code:**
1. ✅ **serverClientId added to GoogleSignIn()**
2. ✅ **Using Web Client ID**

### **In google-services.json:**
1. ✅ **oauth_client array has data**
2. ✅ **Both Android and Web clients listed**

---

## 🎯 Key Difference: Firebase vs Supabase

### **With Firebase (NOT your case):**
- Use Firebase SDK
- Configure in Firebase Console
- Use Firebase Auth

### **With Supabase (YOUR case):**
- Use Google Sign-In package directly
- Configure in Google Cloud Console
- Use Supabase Auth with IdToken
- **Must provide `serverClientId`** ✅

---

## ✅ Quick Checklist

- [ ] Created Android OAuth client in Google Cloud (with SHA-1)
- [ ] Created Web OAuth client in Google Cloud
- [ ] Enabled Google provider in Supabase
- [ ] Added Web Client ID to Supabase
- [ ] Added Web Client Secret to Supabase
- [ ] Added `serverClientId` to GoogleSignIn() in code
- [ ] Updated google-services.json with oauth_client data
- [ ] Ran flutter clean and rebuilt

---

## 🔑 The Most Important Part

**You MUST add `serverClientId` to GoogleSignIn:**

```dart
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com', // ← THIS!
);
```

Without this, no ID token will be generated!

---

**Follow these steps and Google Sign-In will work with Supabase!** 🚀
