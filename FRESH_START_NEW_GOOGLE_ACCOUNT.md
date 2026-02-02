# 🆕 Fresh Start with Different Google Account

## ✅ Yes, You Can Use a Different Google Account!

This is actually a **great idea** to start fresh without all the conflicts.

---

## 🎯 Benefits of Using a New Account

1. **No conflicts** - No duplicate OAuth clients
2. **Clean slate** - No confusing configurations
3. **Easier setup** - Follow steps without cleanup
4. **Better organization** - Separate from personal projects
5. **Professional** - Use a dedicated account for your app

---

## 📋 Complete Setup with New Google Account

### Step 1: Create New Google Cloud Project

1. **Log in** with your different Google account
2. Go to: https://console.cloud.google.com
3. Click **Select a project** (top left)
4. Click **New Project**
5. **Project name:** `Agrilink App` (or any name)
6. Click **Create**
7. Wait for project to be created
8. Select the new project (top left)

---

### Step 2: Enable Required APIs

1. In your new project, go to: **APIs & Services** → **Library**
2. Search for and enable:
   - **Google Sign-In API** (or Google+ API)
   - Click **Enable**

---

### Step 3: Configure OAuth Consent Screen

1. Go to: **APIs & Services** → **OAuth consent screen**
2. Select **External**
3. Fill in:
   - **App name:** Agrilink
   - **User support email:** Your email
   - **Developer contact:** Your email
4. Click **Save and Continue**
5. **Scopes:** Skip (click Save and Continue)
6. **Test users:** Skip (click Save and Continue)
7. Click **Back to Dashboard**

---

### Step 4: Create Android OAuth Client

1. Go to: **APIs & Services** → **Credentials**
2. Click: **Create Credentials** → **OAuth client ID**
3. **Application type:** Android
4. Fill in:
   - **Name:** Agrilink Android
   - **Package name:** `com.example.agrlink1`
   - **SHA-1:** `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
5. Click **Create**
6. **COPY** the Client ID (save it!)

---

### Step 5: Create Web OAuth Client

1. Still in **Credentials**, click: **Create Credentials** → **OAuth client ID**
2. **Application type:** Web application
3. Fill in:
   - **Name:** Agrilink Web
   - **Authorized redirect URIs:**
     - Add: `https://YOUR-SUPABASE-PROJECT-REF.supabase.co/auth/v1/callback`
     - (Get YOUR-SUPABASE-PROJECT-REF from Supabase dashboard URL)
4. Click **Create**
5. **COPY** both:
   - Client ID
   - Client Secret

---

### Step 6: Update Your Code

**Open:** `lib/core/config/environment.dart`

Replace with your NEW Client IDs:

```dart
static String get googleWebClientId {
  return const String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR-NEW-WEB-CLIENT-ID.apps.googleusercontent.com',
  );
}

static String get googleAndroidClientId {
  return const String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'YOUR-NEW-ANDROID-CLIENT-ID.apps.googleusercontent.com',
  );
}
```

---

### Step 7: Update google-services.json

**Option A: Keep Current Structure**

Open: `android/app/google-services.json`

Update the `oauth_client` array:

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
    "client_id": "YOUR-NEW-WEB-CLIENT-ID.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

**Option B: Generate Fresh One (Better)**

Actually, for a completely fresh start, you should create a Firebase project:

1. Go to: https://console.firebase.google.com
2. Click **Add project**
3. Use your NEW Google Cloud project
4. Add Android app:
   - Package name: `com.example.agrlink1`
   - SHA-1: `A9:3E:35:D8:38:E5:6D:ED:58:87:04:73:F9:AF:23:FF:E0:26:97:D2`
5. Download `google-services.json`
6. Replace: `android/app/google-services.json`

---

### Step 8: Update Supabase Configuration

1. Go to: https://supabase.com/dashboard
2. Select your **Agrilink** project
3. Go to: **Authentication** → **Providers** → **Google**
4. **Enable** it
5. Fill in:
   - **Client ID:** YOUR-NEW-WEB-CLIENT-ID
   - **Client Secret:** YOUR-NEW-WEB-CLIENT-SECRET
6. Click **Save**

---

### Step 9: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

---

### Step 10: Wait Before Testing

**Important:** Wait **5-10 minutes** after creating OAuth clients before testing.

Google needs time to sync the new configurations.

---

## 🔄 What About Your Old Account?

### Your Old Google Cloud Project:

- **Still exists** - Nothing deleted
- **Can access anytime** - Just switch accounts
- **No data lost** - All configurations saved
- **Can reuse** - If you want to go back

### To Switch Back (If Needed):

1. Log in with old account
2. Get old Client IDs from Google Cloud Console
3. Update `environment.dart` with old IDs
4. Update Supabase with old IDs
5. Rebuild

---

## 💡 Recommended Approach

**For Production App:**

Use a **dedicated Google account** for your business:
- Not your personal account
- Create: `agrilink.dev@gmail.com` (or similar)
- This becomes your official developer account
- Better for Play Store publishing later
- Easier to transfer or share access

---

## 📋 Complete Checklist (New Account)

- [ ] Logged in with different Google account
- [ ] Created new Google Cloud project
- [ ] Enabled Google Sign-In API
- [ ] Configured OAuth consent screen
- [ ] Created Android OAuth client (with SHA-1)
- [ ] Created Web OAuth client
- [ ] Copied both Client IDs + Secret
- [ ] Updated `environment.dart` with new IDs
- [ ] Updated `google-services.json` (or created new one)
- [ ] Updated Supabase with new Web Client ID + Secret
- [ ] Waited 5-10 minutes
- [ ] Ran `flutter clean`
- [ ] Ran `flutter run`
- [ ] Tested Google Sign-In

---

## 🎯 Expected Result

After setup with new account:

1. No more "already in use" errors ✅
2. No duplicate OAuth clients ✅
3. Clean configuration ✅
4. Google Sign-In works ✅
5. No more Error 10 ✅

---

## ⚠️ Important Notes

### About Switching Accounts:

**Your app will work with whichever account's OAuth clients you configure.**

If you use:
- Account A's OAuth clients → App authenticates via Account A's project
- Account B's OAuth clients → App authenticates via Account B's project

The **users** (people logging into your app) don't need the same Google account. They can use any Google account to log in.

**Example:**
- **Developer account:** yourdev@gmail.com (creates OAuth clients)
- **User account:** anyone@gmail.com (can log into your app)

These are separate!

---

## 🚀 Quick Start Summary

**Fastest way with new account:**

1. New Google Cloud project (5 min)
2. Create 2 OAuth clients: Android + Web (5 min)
3. Update `environment.dart` with new IDs (1 min)
4. Update Supabase with Web client ID (2 min)
5. `flutter clean && flutter run` (2 min)
6. Wait 10 min before testing
7. Test Google Sign-In ✅

**Total time:** ~25 minutes (including wait time)

---

**Using a fresh Google account is actually the CLEANEST solution!** 🎉

No messy cleanup, no conflicts, just fresh setup from scratch.
