# 📧 OTP Email Not Receiving - Troubleshooting Guide

## 🔍 Why You're Not Receiving OTP Emails

Let's check the most common issues:

---

## ⚠️ Most Common Issue: OTP Not Enabled in Supabase

### **Check #1: Is Email OTP Enabled in Supabase?**

This is the #1 reason emails don't arrive!

**Steps to Enable:**

1. Go to: https://supabase.com/dashboard
2. Select your **Agrilink** project
3. Click **Authentication** (left sidebar)
4. Click **Providers** tab
5. Find **Email** provider
6. Scroll down and find **"Enable Email OTP"**
7. Toggle it **ON** ✅
8. Set **OTP Expiry**: 300 seconds (5 minutes)
9. Click **Save**

**Without this enabled, NO OTP emails will be sent!**

---

## 🔍 Check #2: Supabase Email Configuration

### **Verify Email Settings:**

1. Go to **Authentication** → **Email Templates**
2. Check **"Magic Link"** template
3. Make sure template exists and has `{{ .Token }}`
4. Check **From Address** (should be from Supabase)

### **Default Supabase Email:**
- From: `noreply@mail.app.supabase.io`
- Subject: "Your verification code"

---

## 🔍 Check #3: Check Your Spam/Junk Folder

**Supabase emails often go to spam!**

1. Open your email client
2. Check **Spam** or **Junk** folder
3. Look for emails from:
   - `noreply@mail.app.supabase.io`
   - `supabase.io`
   - Subject containing "verification code"

4. If found → Mark as "Not Spam"

---

## 🔍 Check #4: Email Address Typo

**Common Mistake:**

- Did you type the email correctly?
- Check for spaces before/after email
- Check for typos (e.g., `gmial.com` instead of `gmail.com`)

**Test with a known good email:**
- Try with your personal Gmail
- Try with a different email provider

---

## 🔍 Check #5: Supabase Logs

**Check if OTP was actually sent:**

1. Go to Supabase Dashboard
2. Click **Authentication** → **Logs**
3. Look for recent entries
4. Check for:
   - `auth.otp.sent` - OTP was sent ✅
   - `auth.otp.failed` - OTP failed to send ❌
   - Error messages

**What to look for:**
```
✅ Good Log:
  Event: auth.otp.sent
  Email: your-email@example.com
  Status: success

❌ Bad Log:
  Event: auth.otp.failed
  Error: Email provider error
```

---

## 🔍 Check #6: Supabase Email Quota

**Free Tier Limits:**

Supabase Free Tier has email limits:
- **3 emails per hour per user**
- **Custom SMTP not available on free tier**

**Check if you exceeded limit:**
1. Go to **Settings** → **Billing**
2. Check **Usage**
3. Look for email usage

**If exceeded:**
- Wait 1 hour
- Or upgrade to paid plan

---

## 🔍 Check #7: Network/Firewall Issues

**Rare but possible:**

- Corporate email filters
- School email systems
- Government email systems

**These often block automated emails.**

**Solution:**
- Try with Gmail, Yahoo, or Outlook
- Check with IT department about allowlisting

---

## 🔍 Check #8: Supabase Service Status

**Is Supabase down?**

Check: https://status.supabase.com

- Green = All systems operational ✅
- Yellow/Red = Issues ⚠️

---

## 🧪 Testing Steps

### **Test 1: Manual Check in Supabase**

1. Go to **Authentication** → **Providers** → **Email**
2. Click **"Send test email"** (if available)
3. Enter your email
4. Check if you receive test email
5. If YES → Supabase email works ✅
6. If NO → Supabase issue ❌

### **Test 2: Check Console Logs**

When you try to signup or login:

1. Open terminal where `flutter run` is running
2. Look for these logs:
   ```
   ✅ Good:
   📧 Sending signup OTP to: user@email.com
   ✅ Signup OTP sent successfully to: user@email.com
   
   ❌ Bad:
   📧 Sending signup OTP to: user@email.com
   ❌ Failed to send signup OTP
   Error: [error message here]
   ```

3. If you see error → Read error message
4. Common errors:
   - "Email OTP not enabled" → Enable in Supabase
   - "Rate limit exceeded" → Wait 1 hour
   - "Invalid email" → Check email format

### **Test 3: Try Different Email Providers**

Test with multiple providers:
- [ ] Gmail (`@gmail.com`)
- [ ] Yahoo (`@yahoo.com`)
- [ ] Outlook (`@outlook.com`)
- [ ] Your custom domain

If one works but not others → Email provider blocking

---

## 🛠️ Quick Fixes

### **Fix 1: Re-enable Email OTP**

Sometimes toggling helps:

1. Supabase Dashboard → Authentication → Providers
2. Find Email provider
3. Toggle **"Enable Email OTP"** OFF
4. Wait 5 seconds
5. Toggle **"Enable Email OTP"** ON
6. Save
7. Try again

### **Fix 2: Restart App**

Sometimes helps:

1. Stop the app (`Ctrl+C` in terminal)
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run`
5. Try signup/login again

### **Fix 3: Clear Supabase Cache**

In your code:

1. Log out completely
2. Clear app data (Settings → Apps → Agrilink → Clear Data)
3. Restart app
4. Try again

### **Fix 4: Check Supabase URL and Keys**

Make sure your Supabase configuration is correct:

1. Open `lib/core/services/supabase_service.dart`
2. Check:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL', // Correct?
     anonKey: 'YOUR_SUPABASE_ANON_KEY', // Correct?
   );
   ```
3. Compare with Supabase Dashboard → Settings → API
4. Make sure they match!

---

## 📊 Diagnostic Checklist

Run through this checklist:

- [ ] Email OTP enabled in Supabase?
- [ ] Checked spam/junk folder?
- [ ] Email address typed correctly?
- [ ] Checked Supabase Auth Logs?
- [ ] Under email quota limit?
- [ ] Supabase status page shows green?
- [ ] Console shows OTP sent successfully?
- [ ] Tried different email provider?
- [ ] Supabase URL and keys correct?
- [ ] App restarted after enabling OTP?

---

## 🔍 Advanced Debugging

### **Step 1: Enable Verbose Logging**

In your app, check console for:
```
🚀 AGRILINK APP STARTING - Main function called
📧 Sending signup OTP to: user@email.com
✅ Signup OTP sent successfully to: user@email.com
```

If you see ✅ → Supabase sent it (check email/spam)
If you see ❌ → Read error message

### **Step 2: Test with Supabase CLI**

If you have Supabase CLI:

```bash
supabase functions invoke auth/otp \
  --data '{"email":"your@email.com"}'
```

### **Step 3: Check Email Template**

1. Supabase → Authentication → Email Templates → Magic Link
2. Make sure template is valid
3. Must contain `{{ .Token }}`
4. Save and try again

---

## 💡 Common Solutions

### **Solution 1: Wait and Check Spam**

**Most common fix:**
1. Wait 1-2 minutes (emails can be delayed)
2. Check spam/junk folder
3. Check all email tabs (Promotions, Updates, etc.)

### **Solution 2: Use Gmail**

**Gmail is most reliable:**
1. Create a test Gmail account
2. Use that for testing
3. Once working, try your real email

### **Solution 3: Enable OTP (Most Important!)**

**This fixes 90% of issues:**
1. Supabase Dashboard
2. Authentication → Providers → Email
3. Enable Email OTP → ON
4. Save
5. Restart your app
6. Try again

---

## 📧 Expected Email Example

**When it works, you should receive:**

```
From: noreply@mail.app.supabase.io
To: your@email.com
Subject: Your verification code

Your verification code is:

123456

This code will expire in 5 minutes.

Enter this code in the Agrilink app to complete your registration.

If you didn't request this code, please ignore this email.
```

---

## 🆘 Still Not Working?

### **If you've tried everything:**

1. **Check Supabase Dashboard:**
   - Go to Authentication → Logs
   - Screenshot any errors
   - Look for clues

2. **Check Console Output:**
   - Copy any error messages
   - Look for "Failed to send OTP"

3. **Try Different Email:**
   - Use Gmail for testing
   - If Gmail works → Your email provider blocks it

4. **Verify Supabase Settings:**
   - Email OTP: ON ✅
   - OTP Expiry: 300 seconds
   - Email template exists
   - Supabase URL/keys correct

5. **Check Quota:**
   - Supabase free tier: 3 emails/hour
   - Wait 1 hour if exceeded

---

## ✅ Quick Test Procedure

**Follow these steps in order:**

1. ✅ **Enable OTP in Supabase**
   - Authentication → Providers → Email
   - Enable Email OTP → ON
   - Save

2. ✅ **Restart App**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. ✅ **Use Gmail for Test**
   - Don't use work/school email
   - Use personal Gmail

4. ✅ **Try Signup**
   - Fill form correctly
   - Click "Create Account"
   - Watch console for logs

5. ✅ **Wait 1-2 Minutes**
   - Emails can be delayed
   - Check spam folder
   - Check all email tabs

6. ✅ **Check Supabase Logs**
   - Authentication → Logs
   - Look for recent OTP events
   - Check for errors

---

## 🎯 Most Likely Solution

**90% of the time, it's one of these:**

1. ❌ **Email OTP not enabled in Supabase**
   - Fix: Enable it in dashboard

2. ❌ **Email in spam folder**
   - Fix: Check spam/junk

3. ❌ **Email typo**
   - Fix: Type carefully, use Gmail

4. ❌ **Rate limit exceeded**
   - Fix: Wait 1 hour

5. ❌ **Supabase URL/keys wrong**
   - Fix: Check configuration

---

**Try these fixes in order, and one of them will work!** 🚀
