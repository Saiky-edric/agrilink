# 🔧 Fix Google Sign-In Error 10 - API Exception

## ⚠️ Error:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

**Error Code 10 means:** "Developer Error" - Your SHA-1 certificate is not registered or doesn't match.

---

## ✅ Solution: Register SHA-1 with Android OAuth Client

### **Step 1: Verify Your SHA-1 Fingerprint**

Your SHA-1 is:
```
A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2
```

---

### **Step 2: Add SHA-1 to Google Cloud Console**

1. **Go to:** https://console.cloud.google.com
2. **Select** your project
3. **Go to:** APIs & Services → Credentials
4. **Find** your Android OAuth client ID:
   ```
   994138854340-gadnfvoh655eu2s2lha96qbsucdjc8lh.apps.googleusercontent.com
   ```
5. **Click** on it to edit
6. **In the "SHA-1 certificate fingerprints" section:**
   - Click "Add fingerprint"
   - Paste: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
   - Click "Save"

---

### **Step 3: Verify Package Name**

While editing the Android OAuth client, check:
- **Package name:** Should be `com.example.agrilink1`
- Make sure it matches your app's package name

---

### **Step 4: Wait 5 Minutes**

Google needs time to propagate the changes.
- Wait 5 minutes after adding SHA-1
- Then try again

---

### **Step 5: Clean and Rebuild**

```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

---

## 🔍 Alternative: Re-create Android OAuth Client

If adding SHA-1 doesn't work, create a new Android OAuth client:

### **Delete Old Android Client (Optional):**
1. Google Cloud Console → Credentials
2. Find Android client: `994138854340-gadnfvoh655eu2s2lha96qbsucdjc8lh`
3. Click Delete

### **Create New Android Client:**
1. Click "Create Credentials" → "OAuth client ID"
2. Application type: **Android**
3. Name: `Agrilink Android`
4. Package name: `com.example.agrilink1`
5. SHA-1: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
6. Click "Create"
7. **Copy the new Client ID**

### **Update environment.dart with new Android Client ID:**
```dart
static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'YOUR-NEW-ANDROID-CLIENT-ID.apps.googleusercontent.com',
  );
}
```

---

## 📱 Verify Your Package Name

Open: `android/app/build.gradle`

Check that `applicationId` matches:
```gradle
android {
    ...
    defaultConfig {
        applicationId "com.example.agrilink1"  // ← Must match Google Cloud
        ...
    }
}
```

---

## 🔍 Common Causes of Error 10:

1. ❌ **SHA-1 not added** to Android OAuth client
2. ❌ **Wrong SHA-1** (using release instead of debug)
3. ❌ **Package name mismatch** (app vs Google Cloud)
4. ❌ **Changes not propagated** (need to wait 5 minutes)
5. ❌ **Wrong OAuth client** being used

---

## 🧪 Testing Checklist:

After adding SHA-1:

- [ ] SHA-1 added to Android OAuth client in Google Cloud
- [ ] Package name matches: `com.example.agrilink1`
- [ ] Waited 5 minutes for changes to propagate
- [ ] Ran `flutter clean`
- [ ] Rebuilt the app
- [ ] Tried Google Sign-In again

---

## 💡 Quick Debug:

### **Check if SHA-1 is correct:**
```bash
cd android
./gradlew signingReport

# Look for:
# Variant: debug
# SHA1: A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2
```

### **Check package name:**
```bash
# In android/app/build.gradle
# Look for: applicationId "com.example.agrilink1"
```

### **Check OAuth clients in Google Cloud:**
- Web client: `994138854340-gi7a2t1m49jhm8cet70n6qdk5hekutk9.apps.googleusercontent.com`
- Android client: `994138854340-gadnfvoh655eu2s2lha96qbsucdjc8lh.apps.googleusercontent.com`

---

## 🎯 Most Likely Fix:

**The SHA-1 is not added to your Android OAuth client.**

1. Go to Google Cloud Console
2. Find Android OAuth client
3. Add SHA-1: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
4. Save
5. Wait 5 minutes
6. Try again

---

## ⚠️ Important Notes:

### **Debug vs Release SHA-1:**
- **Debug SHA-1** (what we have): Works for development/testing
- **Release SHA-1** (for production): Need when releasing to Play Store

### **Multiple SHA-1s:**
- You can add BOTH debug and release SHA-1s to the same OAuth client
- Recommended: Add debug now, add release later

### **Each Developer Needs Their Own SHA-1:**
- If multiple developers, each needs to add their debug SHA-1
- Each computer has a different debug keystore

---

## 🚀 After Fix:

Google Sign-In should:
1. Open Google account picker ✅
2. Select account ✅
3. Return to app ✅
4. Generate tokens ✅
5. Authenticate with Supabase ✅
6. Log in successfully ✅

---

**The fix is simple: Add the SHA-1 to your Android OAuth client in Google Cloud Console!**
