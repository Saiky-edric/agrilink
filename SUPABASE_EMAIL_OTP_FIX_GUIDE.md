# 🔧 Fix Supabase Email OTP - Complete Guide

## ❌ The Error You're Seeing

```
AuthApiException(message: Signups not allowed for otp, statusCode: 422, code: otp_disabled)
```

This means Email OTP is **disabled** in your Supabase project settings.

---

## ✅ Step-by-Step Fix

### **Step 1: Go to Supabase Dashboard**

1. Open your browser and go to: **https://supabase.com/dashboard**
2. Sign in to your account
3. Select your **Agrilink** project from the list

---

### **Step 2: Navigate to Authentication Settings**

1. In the left sidebar, click **"Authentication"** (shield icon)
2. You'll see several tabs at the top
3. Click on the **"Providers"** tab

---

### **Step 3: Find Email Provider Settings**

1. Scroll down the providers list
2. Look for **"Email"** provider (should be near the top)
3. Click on it to expand the settings panel

---

### **Step 4: Find the Correct Email Settings** ⚠️ **CRITICAL STEP**

The setting location depends on your Supabase UI version. Try these locations:

#### **Option A: In Email Provider Panel (Newer UI)**
After clicking "Email" provider, look for:
- **Enable Email Provider**: Toggle **ON** ✅
- **Confirm email**: Can be OFF
- **Enable email OTP / Magic Link**: Toggle **ON** ✅
- Or it might say **"Enable Passwordless Sign-In"**: Toggle **ON** ✅

#### **Option B: In Authentication Settings (Alternative Location)**
If you don't see the toggle in the Email provider:

1. Go to **Authentication** → **Settings** (not Providers)
2. Scroll to **"Email Auth"** or **"Auth Methods"** section
3. Look for:
   - **Email OTP** or **Magic Link**: Enable it
   - **Passwordless / One-Time Password**: Enable it

#### **Option C: Project Settings (Older UI)**
1. Go to **Settings** (gear icon in sidebar)
2. Click **Authentication**
3. Look for **"Enable Email OTP"** or **"Email OTP Sign In"**
4. Toggle it **ON**

### **What Setting Names to Look For:**
The setting might be called any of these:
- ✅ "Enable Email OTP"
- ✅ "Email OTP Sign In"
- ✅ "Enable Magic Link"
- ✅ "Passwordless Sign-In"
- ✅ "One-Time Password"

**They all refer to the same feature!**

---

### **Step 4.5: Can't Find the Setting? Try This!**

If you still can't find "Enable Email OTP", here's what to check:

#### **Method 1: Check URL Configuration Method**
Instead of looking for a toggle, Supabase might use **redirect URLs**:

1. In **Authentication** → **Providers** → **Email**
2. Look for **"Site URL"** or **"Redirect URLs"** section
3. You might need to configure these first:
   - **Site URL**: `http://localhost:3000` (for testing)
   - **Redirect URLs**: Add your app's deep link or leave empty for now

#### **Method 2: Check if it's Already Enabled**
The error `otp_disabled` might be misleading. Check:

1. Go to **Authentication** → **Settings**
2. Look at **"Auth Providers"** section
3. If you see **Email** listed and enabled, OTP might already be on
4. The issue could be with **sign-up settings** instead

#### **Method 3: Enable Sign-Ups**
Your error says "Signups not allowed for otp". Try this:

1. Go to **Authentication** → **Providers** → **Email**
2. Look for **"Sign-up methods"** or **"Allowed methods"**
3. Make sure **"Sign-up"** or **"Allow sign-ups"** is enabled
4. OR look for **"Enable sign-ups"** toggle at the top

#### **Method 4: Check Email Authentication Method**
1. In **Authentication** → **Providers** → **Email**
2. Look for **"Authentication method"** dropdown or radio buttons
3. You might see options like:
   - **Password** (traditional login)
   - **Magic Link / OTP** ← Select this one!
   - **Both** ← Or select this to allow both methods

#### **What Your Screen Should Show:**
Look for ANY of these text labels or toggles:
- "Enable Email Provider" ✅
- "Allow sign-ups" ✅
- "Authentication method" → Select "Magic Link" or "OTP"
- "Passwordless sign-in" ✅
- "Email OTP" ✅

---

### **Step 5: Configure OTP Settings (Optional)**

While you're there, you can adjust:

- **OTP Expiry Time**: `300` seconds (5 minutes) - recommended
- **OTP Length**: `6` digits (default is fine)

---

### **Step 6: Save Changes**

1. Scroll to the bottom of the Email provider panel
2. Click the green **"Save"** button
3. Wait for the success message: "Successfully updated settings"

---

### **Step 7: Configure Email Template (Your Beautiful Template!)**

Now that Email OTP is enabled, let's add your custom template:

1. Still in **Authentication** section
2. Click the **"Email Templates"** tab
3. You'll see several template options:
   - Confirm signup
   - Invite user
   - **Magic Link** ← Use this one for OTP
   - Reset Password
   - Change Email

4. Click on **"Magic Link"** template
5. Replace the entire HTML content with your template (the one you showed me)
6. **Important**: Make sure your template includes `{{ .Token }}` - which it does! ✅
7. Click **"Save"** at the bottom

---

### **Step 8: Verify Configuration**

Let's make sure everything is set up correctly:

#### **Check Authentication Settings:**
1. Go to **Authentication** → **Settings** (not Providers)
2. Scroll to **"Auth Providers"** section
3. Confirm **Email** shows as enabled

#### **Check Email Rate Limits:**
- **Free Tier**: 3 emails per hour per email address
- **Pro Tier**: Higher limits
- If you hit the limit, wait 60 minutes before testing again

---

### **Step 9: Test in Your App**

1. **Stop your Flutter app** (Ctrl+C in terminal)
2. **Clean and rebuild** (optional but recommended):
   ```bash
   flutter clean
   flutter pub get
   ```
3. **Run the app again**:
   ```bash
   flutter run
   ```
4. **Test the signup flow**:
   - Go to signup screen
   - Fill in the form with a **real email** (use Gmail for best results)
   - Click "Create Account"
   - Check console logs for success message
   - **Check your email inbox** (and spam folder!)

---

## 🧪 Expected Console Output (Success)

After enabling Email OTP, you should see:

```
I/flutter: 📧 Sending signup OTP to: your.email@gmail.com
I/flutter: ✅ Signup OTP sent successfully
I/flutter: 📱 Navigating to OTP verification screen
```

---

## 📧 Expected Email

You should receive an email with:
- **Subject**: "Your Agrilink Verification Code" (or similar)
- **From**: noreply@mail.supabase.io (or your custom domain)
- **Content**: Your beautiful green template with the 6-digit code

---

## 🔍 Troubleshooting

### **Can't Find "Enable Email OTP" Setting?**

Here's a systematic approach:

#### **Take a Screenshot Method:**
1. Go to **Authentication** → **Providers** → **Email**
2. Take a screenshot of EVERYTHING you see on that page
3. Share it (or describe what toggles/options you see)
4. Common options you might see:
   - "Enable Email Provider"
   - "Confirm email"
   - "Secure email change"
   - "Double confirm email changes"

#### **Check Your Supabase Version:**
Supabase updates their UI frequently. Your dashboard might show:
- **New UI (2024+)**: Settings under Authentication → Configuration
- **Older UI**: Settings under Project Settings → Auth

#### **Try the API Configuration Method:**
If the UI doesn't have the option, use SQL instead:

1. Go to **SQL Editor** in Supabase
2. Run this query to check current auth config:
```sql
SELECT * FROM auth.config;
```
3. This will show you what auth methods are enabled

#### **Alternative: Use Email/Password Instead**
If you can't enable OTP, switch to traditional password authentication:

1. In your Flutter code (`auth_service.dart`), change from:
   ```dart
   await supabase.auth.signInWithOtp(email: email);
   ```
   
   To:
   ```dart
   await supabase.auth.signUp(email: email, password: password);
   ```

2. Update your signup form to include a password field
3. This bypasses the OTP requirement entirely

---

### **Still Not Working?**

#### **1. Check Supabase Logs:**
- Go to **Authentication** → **Logs** in Supabase dashboard
- Filter by `auth.otp` events
- Look for any error messages

#### **2. Check Email Spam Folder:**
- Supabase emails often land in spam initially
- Mark as "Not Spam" to train your email provider

#### **3. Try Different Email Provider:**
- **✅ Works well**: Gmail, Outlook, Yahoo
- **⚠️ May block**: Custom domains, school emails, work emails
- Test with Gmail first to verify it's working

#### **4. Rate Limit Check:**
- Supabase Free Tier: Maximum 3 OTP emails per hour per email address
- If you've been testing a lot, wait 60 minutes
- Try a different email address in the meantime

#### **5. Check Template Variable:**
- Make sure your email template contains `{{ .Token }}`
- This is the placeholder Supabase replaces with the actual OTP code
- Your template already has this, so you're good! ✅

#### **6. Verify Email Provider in Code:**
- Check `lib/core/services/auth_service.dart`
- Make sure it's using `supabase.auth.signInWithOtp()`
- The method should be called with `emailRedirectTo: null` for OTP flow

---

## 💡 Common Mistakes

### ❌ **Mistake 1: Enabling Wrong Setting**
- Don't confuse "Email Confirmations" with "Email OTP"
- You need **Email OTP** specifically enabled

### ❌ **Mistake 2: Not Saving Changes**
- Always click the **Save** button after making changes
- Wait for the success notification

### ❌ **Mistake 3: Using Wrong Email Template**
- Use **"Magic Link"** template for OTP codes
- Don't use "Confirm Signup" template

### ❌ **Mistake 4: Testing Too Quickly**
- If you hit rate limits, wait the full 60 minutes
- Use different email addresses for testing

---

## 🎯 Quick Checklist

Before testing, verify all these are ✅:

- [ ] Logged into Supabase Dashboard
- [ ] Selected correct Agrilink project
- [ ] Went to Authentication → Providers
- [ ] Found Email provider
- [ ] **Enabled "Enable Email OTP"** toggle
- [ ] Saved changes and saw success message
- [ ] Went to Authentication → Email Templates
- [ ] Selected "Magic Link" template
- [ ] Pasted your custom HTML template
- [ ] Verified `{{ .Token }}` is in the template
- [ ] Saved the template
- [ ] Restarted Flutter app
- [ ] Testing with real email address (Gmail recommended)

---

## 🚀 After It Works

Once your OTP emails are working:

1. **Test the complete flow**:
   - Signup → Receive OTP → Verify → Login → Success!

2. **Monitor usage**:
   - Check Authentication → Logs in Supabase
   - Watch for any errors or rate limit issues

3. **Consider upgrading** (if needed):
   - Free Tier: 3 emails/hour per email
   - Pro Tier: Higher email limits + custom SMTP

4. **Custom SMTP** (optional, for production):
   - Go to Project Settings → Auth → SMTP Settings
   - Use SendGrid, Mailgun, or AWS SES
   - This gives you custom "From" email address
   - Better deliverability and no Supabase rate limits

---

## 📞 Still Stuck?

If you've followed all steps and it's still not working:

1. **Share your Supabase logs** (Authentication → Logs)
2. **Check console output** for the exact error
3. **Verify your Supabase project tier** (Free vs Pro)
4. **Test with a fresh email address** you haven't used before

---

## ✅ Success Criteria

You'll know it's working when:
- ✅ No errors in console logs
- ✅ Email arrives within 1-2 minutes
- ✅ Email contains your beautiful green template
- ✅ 6-digit code is displayed in the email
- ✅ Entering the code in app logs you in successfully

---

**Your email template is already perfect! Just enable Email OTP in Supabase and you're good to go!** 🎉
