# 🆕 Create Fresh Android OAuth Client

## Situation

You deleted the Android OAuth client, so now you need to create a new one from scratch.

---

## ✅ Step-by-Step: Create Android OAuth Client

### Step 1: Go to Google Cloud Console

1. Open: https://console.cloud.google.com
2. Make sure correct project is selected (top left)
3. Go to: **APIs & Services** → **Credentials**

---

### Step 2: Create New OAuth Client ID

1. Click: **Create Credentials** → **OAuth client ID**
2. If prompted about OAuth consent screen:
   - Click "Configure Consent Screen"
   - Select "External"
   - Fill in basic info (App name, email)
   - Save and go back to create credentials

---

### Step 3: Configure Android OAuth Client

**Application type:** Select **Android**

**Name:** `Agrilink Android`

**Package name:** 
```
com.example.agrlink1
```
(Copy this EXACTLY - no 'i' in agrlink)

**SHA-1 certificate fingerprint:**
```
A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2
```
(Copy this EXACTLY)

**Click:** Create

---

### Step 4: Copy the New Client ID

After creation, you'll see:
```
Your client ID:
XXXXX-YYYYY.apps.googleusercontent.com
```

**COPY THIS!** You'll need it in your code.

---

### Step 5: Update Your Code

Open: `lib/core/config/environment.dart`

Update the Android Client ID:

```dart
static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'YOUR-NEW-ANDROID-CLIENT-ID.apps.googleusercontent.com',
  );
}
```

Replace `YOUR-NEW-ANDROID-CLIENT-ID` with the actual Client ID you copied.

---

### Step 6: Update google-services.json

Open: `android/app/google-services.json`

Find the `oauth_client` array and update it:

```json
"oauth_client": [
  {
    "client_id": "YOUR-NEW-ANDROID-CLIENT-ID.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.agrlink1",
      "certificate_hash": "a93e35d838e56ded58870473f9af23ffe02697d2"
    }
  },
  {
    "client_id": "YOUR-WEB-CLIENT-ID.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

**Note:** The certificate_hash is your SHA-1 in lowercase without colons.

---

### Step 7: Wait for Changes to Sync

**Important:** Google needs time to register the new OAuth client.

- Wait **5-10 minutes** after creating it
- Don't test immediately!

---

### Step 8: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎯 What You Need in Google Cloud Console

After completing the steps above, you should have:

### 1. Android OAuth Client ✅
- **Type:** Android
- **Package:** com.example.agrlink1
- **SHA-1:** A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2
- **Client ID:** (the new one you created)

### 2. Web OAuth Client ✅
- **Type:** Web application
- **Client ID:** `994138854340-gi7a2t1m49jhm8cet70n6qdk5hekutk9.apps.googleusercontent.com`
- **Client Secret:** (should already exist)
- **Used for:** Supabase authentication

---

## 📋 Complete Configuration Checklist

After creating the Android OAuth client:

- [ ] Android OAuth client created in Google Cloud
- [ ] Package name: `com.example.agrlink1` (exactly)
- [ ] SHA-1 added: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
- [ ] New Client ID copied
- [ ] `environment.dart` updated with new Android Client ID
- [ ] `google-services.json` updated with new Android Client ID
- [ ] Web OAuth client still exists (for Supabase)
- [ ] Supabase Google provider configured with Web Client ID
- [ ] Waited 5-10 minutes
- [ ] Ran `flutter clean`
- [ ] Ran `flutter run`
- [ ] Tested Google Sign-In

---

## 🔍 Verify Your Setup

### In Google Cloud Console:

You should see **2 OAuth clients**:

1. **Android client:**
   - Package: com.example.agrlink1
   - Has SHA-1

2. **Web client:**
   - For Supabase
   - No package name (it's web)

### In Your Code:

`lib/core/config/environment.dart`:
```dart
googleWebClientId: "994138854340-gi7a2t1m49jhm8cet70n6qdk5hekutk9.apps.googleusercontent.com"
googleAndroidClientId: "YOUR-NEW-CLIENT-ID.apps.googleusercontent.com"
```

`lib/core/services/auth_service.dart` (line 119):
```dart
GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: EnvironmentConfig.googleWebClientId, // Uses WEB client ID
)
```

---

## 💡 Important Notes

### About Client IDs:

1. **Android Client ID:**
   - Used in `google-services.json`
   - Used in `environment.dart` as `googleAndroidClientId`
   - **NOT used in GoogleSignIn()** for Supabase

2. **Web Client ID:**
   - Used in `GoogleSignIn(serverClientId: ...)` for Supabase
   - Used in Supabase Dashboard Google provider config
   - This is the important one for Supabase authentication!

### Common Confusion:

Many people think you need to use the Android Client ID in `GoogleSignIn()`, but for **Supabase**, you actually use the **Web Client ID**!

---

## 🚀 After Setup

Once everything is configured:

1. App starts ✅
2. Click "Continue with Google" ✅
3. Google account picker appears ✅
4. Select account ✅
5. Returns to app ✅
6. Authenticates with Supabase ✅
7. Logs in successfully! ✅

---

**Create the Android OAuth client and update your code, then it will work!** 🎉
