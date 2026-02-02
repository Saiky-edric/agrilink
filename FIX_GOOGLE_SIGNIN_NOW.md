# 🔧 Fix Google Sign-In - "No ID Token" Error

## ⚠️ Problem Found

Your `google-services.json` file has an empty `oauth_client` array:
```json
"oauth_client": [],  // ❌ EMPTY - This is the problem!
```

This means Google Sign-In is **not configured** in Firebase.

---

## ✅ Solution: Configure Google Sign-In in Firebase

### **Step 1: Go to Firebase Console**

1. Open: https://console.firebase.google.com
2. Select your project: **agrilink-c5893**
3. Click on your **Android app** in the project

---

### **Step 2: Enable Google Sign-In**

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Find **Google** in the providers list
4. Click **Google** → Click **Enable** toggle
5. **Important**: Select the support email (your email)
6. Click **Save**

---

### **Step 3: Get SHA-1 Certificate Fingerprint**

Google Sign-In on Android requires SHA-1 fingerprint.

**For Debug (Testing):**

Open terminal and run:

```bash
cd android
./gradlew signingReport
```

**Or on Windows:**
```bash
cd android
gradlew.bat signingReport
```

**Look for output like this:**
```
Variant: debug
Config: debug
Store: C:\Users\ASUS\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Copy the SHA1 value!**

---

### **Step 4: Add SHA-1 to Firebase**

1. Go back to Firebase Console
2. Click **Project Settings** (gear icon)
3. Scroll down to **Your apps** section
4. Find your Android app
5. Click **Add fingerprint**
6. Paste your SHA-1 fingerprint
7. Click **Save**

---

### **Step 5: Download NEW google-services.json**

1. Still in Firebase Console
2. Click **Project Settings**
3. Scroll to **Your apps**
4. Click **google-services.json** download button
5. Replace the old file in: `android/app/google-services.json`

**New file should have oauth_client with data:**
```json
"oauth_client": [
  {
    "client_id": "XXXXX.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

---

### **Step 6: Get Web Client ID for Supabase**

1. Go to **Google Cloud Console**: https://console.cloud.google.com
2. Select your project: **agrilink-c5893**
3. Go to **APIs & Services** → **Credentials**
4. You should see:
   - **Web client (auto created by Google Service)**
   - Copy the **Client ID** (ends with `.apps.googleusercontent.com`)

**Example:**
```
123456789-abc123def456.apps.googleusercontent.com
```

---

### **Step 7: Configure Supabase**

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your **Agrilink** project
3. Go to **Authentication** → **Providers**
4. Find **Google** provider
5. Click **Enable**
6. Enter:
   - **Client ID**: (The web client ID from step 6)
   - **Client Secret**: (Get from Google Cloud Console → Credentials → Web client → Client Secret)
7. Click **Save**

---

### **Step 8: Update Your Code (If Needed)**

Check if you need to add the Web Client ID to your code.

Open: `lib/core/config/environment.dart`

Make sure you have:
```dart
class EnvironmentConfig {
  // ... other config
  
  static String get googleWebClientId {
    return 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
  }
}
```

---

### **Step 9: Clean and Rebuild**

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

---

## 🧪 Test Google Sign-In

1. Run your app
2. Go to Login screen
3. Click **Continue with Google**
4. Select your Google account
5. Should log in successfully! ✅

---

## 🔍 Quick Checklist

- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] SHA-1 fingerprint added to Firebase
- [ ] Downloaded NEW google-services.json with oauth_client data
- [ ] Web Client ID configured in Supabase
- [ ] Client Secret configured in Supabase
- [ ] Cleaned and rebuilt the app
- [ ] Tested on device/emulator

---

## 📝 Common Issues

### **Issue 1: Still getting "No ID Token"**
- Make sure you downloaded the NEW google-services.json
- Check that oauth_client is NOT empty
- Rebuild the app completely

### **Issue 2: "PlatformException(sign_in_failed)"**
- SHA-1 not added to Firebase
- Wrong package name in google-services.json
- Check package name matches: `com.example.agrilink1`

### **Issue 3: "Invalid Client"**
- Web Client ID not configured in Supabase
- Wrong Client ID/Secret in Supabase
- Check Supabase Google provider is enabled

---

## 🎯 Quick Fix Summary

**The main issue:**
Your `google-services.json` doesn't have OAuth client configuration.

**The fix:**
1. Enable Google Sign-In in Firebase
2. Add SHA-1 fingerprint
3. Download NEW google-services.json
4. Configure Supabase with Web Client ID
5. Rebuild app

---

## 🔑 Get SHA-1 Fingerprint (Detailed)

### **Method 1: Using Gradle (Recommended)**

```bash
cd android
./gradlew signingReport
```

Look for:
```
Variant: debug
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### **Method 2: Using Keytool**

**Debug Keystore:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**On Windows:**
```bash
keytool -list -v -keystore C:\Users\ASUS\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## 💡 Why This Happens

Google Sign-In requires:
1. ✅ Firebase project created (you have this)
2. ❌ Google Sign-In enabled (you're missing this)
3. ❌ SHA-1 fingerprint added (you're missing this)
4. ❌ OAuth client configured (you're missing this)

Without these, the Google Sign-In SDK can't generate ID tokens.

---

## 🚀 After Fixing

Once fixed, your Google Sign-In will:
- ✅ Show Google account picker
- ✅ Generate ID token
- ✅ Authenticate with Supabase
- ✅ Create/login user account
- ✅ Navigate to role selection or home

---

**Start with Step 1 and follow through Step 9. This will fix your Google Sign-In!** 🎉
