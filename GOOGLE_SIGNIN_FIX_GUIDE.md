# 🔧 Google Sign-In OAuth Fix Guide

## 🚨 **Error Analysis**
```
Error: AuthApiException(message: Unacceptable audience in id_token: [206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu.apps.googleusercontent.com], statusCode: 400, code: null)
```

This error means your **Google OAuth Client ID** doesn't match between your app and Supabase configuration.

## 🔍 **Root Cause**
The Google Client ID `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu.apps.googleusercontent.com` is:
- ✅ Working in your Android app
- ❌ **NOT configured** in your Supabase Auth settings
- ❌ **NOT matching** the expected audience

## 🛠️ **Fix Steps**

### **Option A: Update Supabase with Your Current Google Client ID**

#### **Step 1: Get Your Current Client ID**
From the error, your Client ID is: `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu.apps.googleusercontent.com`

#### **Step 2: Configure Supabase Auth**
1. Go to [Supabase Dashboard](https://supabase.com)
2. Open your Agrilink project
3. Navigate to **Authentication** → **Providers**
4. Click on **Google** provider
5. Enable Google authentication
6. Add your Client ID: `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu`
7. Get the **Client Secret** from Google Cloud Console (see Step 3)
8. Save the configuration

#### **Step 3: Get Client Secret from Google Cloud Console**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your OAuth Client ID: `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu`
4. Click on it to view details
5. Copy the **Client Secret**
6. Paste it in your Supabase Google provider settings

---

### **Option B: Create New Google OAuth Credentials**

If you can't access the existing Google Cloud project:

#### **Step 1: Create New Google Cloud Project**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project for Agrilink
3. Enable **Google+ API** and **Google Sign-In API**

#### **Step 2: Create OAuth 2.0 Credentials**
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client IDs**
3. Choose **Android** as application type
4. For package name: `com.example.agrlink1`
5. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
6. Copy the SHA-1 from the debug variant
7. Create the credential

#### **Step 3: Configure Supabase with New Credentials**
1. Copy the new Client ID
2. Go to Supabase → Authentication → Providers → Google
3. Enable and configure with new credentials

---

## ⚡ **Quick Fix (Recommended)**

### **Update Supabase with Current Client ID:**

1. **Supabase Dashboard** → **Authentication** → **Providers** → **Google**
2. **Enable Google provider**
3. **Client ID**: `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu`
4. **Client Secret**: Get from Google Cloud Console
5. **Save Configuration**

### **Get Client Secret:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. **APIs & Services** → **Credentials**
3. Find client ID `206730168668-hv89al7dvrrp258bkcs0kkslcli1ojiu`
4. Copy the secret and add to Supabase

## 🔗 **Redirect URIs to Add in Google Console**
Make sure these are added to your Google OAuth configuration:
```
https://your-project-id.supabase.co/auth/v1/callback
```
Replace `your-project-id` with your actual Supabase project ID.

## 🧪 **Test After Fix**
1. Restart your app
2. Try Google Sign-In again
3. Should work without the "Unacceptable audience" error

## 📱 **Alternative: Disable Google Sign-In Temporarily**
If you want to test other features first:

```dart
// In your login screen, comment out Google sign-in button
// SocialSignInButton(
//   onPressed: () => _authService.signInWithGoogle(),
//   icon: 'assets/images/logos/google_logo.png',
//   text: 'Continue with Google',
// ),
```

## 🎯 **Expected Result**
After fixing the OAuth configuration:
- ✅ Google Sign-In works smoothly
- ✅ Users can authenticate with Google accounts
- ✅ Seamless integration with Supabase Auth
- ✅ No more "Unacceptable audience" errors

## 🔧 **Common Issues**
- **Wrong Package Name**: Ensure `com.example.agrlink1` matches in Google Console
- **Missing SHA-1**: Android apps need SHA-1 fingerprint
- **Wrong Redirect URI**: Must match Supabase callback URL
- **Client Secret Missing**: Required for server-side validation

**Once you fix the OAuth config, your Google Sign-In will work perfectly! 🚀**