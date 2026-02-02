# 🧹 Clean Up Duplicate Google OAuth Clients

## Problem

Error: "Package name and fingerprint are already in use"

This happens when you have multiple Android OAuth clients with the same package name + SHA-1 combination.

---

## Solution: Delete Duplicate OAuth Clients

### Step 1: Go to Google Cloud Console

1. Open: https://console.cloud.google.com
2. Select your project
3. Go to: **APIs & Services** → **Credentials**

---

### Step 2: Identify Your OAuth Clients

You'll see multiple OAuth 2.0 Client IDs. Look for Android types.

**You currently have (or had):**

1. **Android client for:** `com.example.agrlink1` (no 'i')
   - Client ID: `994138854340-gadnfvoh655eu2s2lha96qbsucdjc8lh.apps.googleusercontent.com`
   - SHA-1: A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2

2. **Android client for:** `com.example.agrilink1` (with 'i')
   - Created when we tried to fix Error 10
   - Same SHA-1

**Both can't exist with the same SHA-1!**

---

### Step 3: Decide Which Package Name to Keep

**Since you reverted to `agrlink1` (no 'i'):**

- ✅ **KEEP:** Android OAuth client with `com.example.agrlink1`
- ❌ **DELETE:** Android OAuth client with `com.example.agrilink1`

---

### Step 4: Delete Duplicate OAuth Client

1. In the Credentials page, find the OAuth client for `com.example.agrilink1`
2. Click the **trash icon** or click on it and select "Delete"
3. Confirm deletion

---

### Step 5: Verify Remaining OAuth Client

1. Click on the remaining Android OAuth client (`agrlink1`)
2. Verify:
   - **Package name:** `com.example.agrlink1`
   - **SHA-1 fingerprint:** `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
3. If SHA-1 is missing, add it
4. Click **Save**

---

### Step 6: Update environment.dart

Make sure your Client IDs are correct:

**Open:** `lib/core/config/environment.dart`

```dart
static String get googleWebClientId {
  return const String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com',
  );
}

static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'THE-ANDROID-CLIENT-ID-YOU-KEPT.apps.googleusercontent.com',
  );
}
```

Use the Client ID from the OAuth client you kept!

---

### Step 7: Wait and Rebuild

1. **Wait 5 minutes** for Google to sync changes
2. Clean and rebuild:
   ```bash
   flutter clean
   flutter run
   ```

---

## Current Situation Summary

### What You Have Now:

- **App package:** `com.example.agrlink1` (reverted)
- **google-services.json:** Uses `agrlink1`
- **build.gradle.kts:** Uses `agrlink1`

### What You Need in Google Cloud:

- **Android OAuth client:** Package `com.example.agrlink1` with SHA-1
- **Web OAuth client:** For Supabase (different, no package name)
- **NO duplicate Android clients**

---

## Alternative: Start Fresh with New OAuth Clients

If you want to completely start over:

### Option A: Delete ALL Android OAuth Clients

1. Delete all Android OAuth clients in Google Cloud Console
2. Keep only the Web OAuth client (for Supabase)
3. Create ONE new Android OAuth client:
   - Package: `com.example.agrlink1`
   - SHA-1: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
4. Update environment.dart with new Client IDs
5. Wait 5 minutes
6. Rebuild

---

## Important Notes

### About `agrlink1` vs `agrilink1`:

**The typo issue:**
- Your app uses: `agrlink1` (missing 'i')
- Should be: `agrilink1` (correct spelling)

**But for now:**
- We're keeping `agrlink1` to avoid crashes
- You can fix the typo later when publishing to production
- For now, just get Google Sign-In working!

### Package Name Best Practices:

1. **Decide on a package name EARLY**
2. **Don't change it after development starts**
3. **Can't change after publishing to Play Store**
4. **All OAuth clients must match exactly**

---

## After Cleanup

Once duplicates are deleted:

1. ✅ Google Sign-In should work
2. ✅ No more "already in use" errors
3. ✅ Error 10 should be fixed (if SHA-1 is correct)

---

## Quick Checklist

- [ ] Went to Google Cloud Console → Credentials
- [ ] Identified duplicate Android OAuth clients
- [ ] Deleted the `agrilink1` OAuth client (with 'i')
- [ ] Kept the `agrlink1` OAuth client (no 'i')
- [ ] Verified SHA-1 is in the kept client
- [ ] Updated environment.dart if needed
- [ ] Waited 5 minutes
- [ ] Ran `flutter clean`
- [ ] Ran `flutter run`
- [ ] Tested Google Sign-In

---

**Clean up the duplicates in Google Cloud Console and it will work!** 🚀
