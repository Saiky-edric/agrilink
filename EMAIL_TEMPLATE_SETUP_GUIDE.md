# 📧 OTP Email Template Customization Guide

## 🎨 How to Customize Your OTP Email Template

### Step 1: Access Email Templates in Supabase

1. Go to: https://supabase.com/dashboard
2. Select your **Agrilink** project
3. Click **Authentication** in the left sidebar
4. Click **Email Templates** tab
5. Find **"Magic Link"** template (this is used for OTP emails)
6. Click **Edit**

---

## ✨ Recommended Agrilink Email Template

### Professional Version (Recommended):

```html
<html>
<head>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
      padding: 30px 20px;
      text-align: center;
    }
    .header h1 {
      color: #ffffff;
      margin: 0;
      font-size: 28px;
      font-weight: 600;
    }
    .header p {
      color: rgba(255,255,255,0.9);
      margin: 8px 0 0 0;
      font-size: 14px;
    }
    .content {
      padding: 40px 30px;
      text-align: center;
    }
    .greeting {
      font-size: 18px;
      color: #333;
      margin-bottom: 20px;
    }
    .message {
      font-size: 16px;
      color: #666;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .otp-container {
      background-color: #f8f9fa;
      border: 2px dashed #4CAF50;
      border-radius: 10px;
      padding: 25px;
      margin: 30px 0;
    }
    .otp-label {
      font-size: 14px;
      color: #666;
      margin-bottom: 10px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .otp-code {
      font-size: 36px;
      font-weight: 700;
      color: #4CAF50;
      letter-spacing: 8px;
      font-family: 'Courier New', monospace;
      margin: 10px 0;
    }
    .expiry {
      font-size: 14px;
      color: #999;
      margin-top: 10px;
    }
    .warning {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 25px 0;
      text-align: left;
    }
    .warning-title {
      font-weight: 600;
      color: #856404;
      margin-bottom: 5px;
    }
    .warning-text {
      font-size: 14px;
      color: #856404;
      margin: 0;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 25px 30px;
      text-align: center;
      border-top: 1px solid #e9ecef;
    }
    .footer-text {
      font-size: 13px;
      color: #999;
      margin: 5px 0;
    }
    .footer-link {
      color: #4CAF50;
      text-decoration: none;
    }
    .social-links {
      margin-top: 15px;
    }
    .social-links a {
      display: inline-block;
      margin: 0 5px;
      color: #4CAF50;
      text-decoration: none;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <h1>🌾 Agrilink</h1>
      <p>Connecting Farmers & Buyers in Agusan del Sur</p>
    </div>
    
    <!-- Content -->
    <div class="content">
      <div class="greeting">Hello there! 👋</div>
      
      <div class="message">
        You requested a verification code to log in to your Agrilink account. 
        Enter the code below in the app to continue.
      </div>
      
      <!-- OTP Code -->
      <div class="otp-container">
        <div class="otp-label">Your Verification Code</div>
        <div class="otp-code">{{ .Token }}</div>
        <div class="expiry">⏱️ Expires in 5 minutes</div>
      </div>
      
      <div class="message">
        Simply enter this code in the Agrilink app to complete your login.
      </div>
      
      <!-- Security Warning -->
      <div class="warning">
        <div class="warning-title">🔒 Security Reminder</div>
        <div class="warning-text">
          Never share this code with anyone. Agrilink staff will never ask for your verification code.
          If you didn't request this code, please ignore this email.
        </div>
      </div>
    </div>
    
    <!-- Footer -->
    <div class="footer">
      <div class="footer-text">
        <strong>Agrilink Digital Marketplace</strong>
      </div>
      <div class="footer-text">
        Supporting local agriculture in Agusan del Sur
      </div>
      <div class="footer-text" style="margin-top: 15px;">
        Need help? Email us at <a href="mailto:support@agrilink.ph" class="footer-link">support@agrilink.ph</a>
      </div>
      <div class="social-links">
        <a href="#">Facebook</a> • 
        <a href="#">Terms</a> • 
        <a href="#">Privacy</a>
      </div>
      <div class="footer-text" style="margin-top: 15px; font-size: 11px;">
        © 2026 Agrilink. All rights reserved.
      </div>
    </div>
  </div>
</body>
</html>
```

---

## 🎯 Simple Version (Lightweight):

If you prefer a simpler email:

```html
<html>
<head>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 500px;
      margin: 0 auto;
      background-color: #ffffff;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .logo {
      text-align: center;
      font-size: 24px;
      color: #4CAF50;
      font-weight: bold;
      margin-bottom: 20px;
    }
    .title {
      font-size: 20px;
      color: #333;
      margin-bottom: 15px;
      text-align: center;
    }
    .message {
      font-size: 15px;
      color: #666;
      line-height: 1.6;
      margin-bottom: 25px;
      text-align: center;
    }
    .otp-box {
      background-color: #f0f0f0;
      border: 2px solid #4CAF50;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 25px 0;
    }
    .otp-code {
      font-size: 32px;
      font-weight: bold;
      color: #4CAF50;
      letter-spacing: 5px;
      font-family: monospace;
    }
    .expiry {
      font-size: 13px;
      color: #999;
      margin-top: 10px;
    }
    .note {
      font-size: 13px;
      color: #999;
      text-align: center;
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #eee;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">🌾 Agrilink</div>
    
    <div class="title">Your Verification Code</div>
    
    <div class="message">
      Enter this code in the Agrilink app to log in:
    </div>
    
    <div class="otp-box">
      <div class="otp-code">{{ .Token }}</div>
      <div class="expiry">Valid for 5 minutes</div>
    </div>
    
    <div class="message">
      If you didn't request this code, you can safely ignore this email.
    </div>
    
    <div class="note">
      Need help? Contact us at support@agrilink.ph
    </div>
  </div>
</body>
</html>
```

---

## 📱 Plain Text Version (Fallback):

Some email clients don't support HTML. Here's a plain text version:

```
AGRILINK - Your Verification Code

Hello!

Your verification code is:

{{ .Token }}

This code will expire in 5 minutes.

Enter this code in the Agrilink app to complete your login.

SECURITY REMINDER:
Never share this code with anyone. Agrilink staff will never ask for your verification code.

If you didn't request this code, please ignore this email.

---
Agrilink Digital Marketplace
Supporting local agriculture in Agusan del Sur
Need help? Email: support@agrilink.ph

© 2026 Agrilink. All rights reserved.
```

---

## 🔧 How to Apply the Template

### Method 1: Via Supabase Dashboard (Recommended)

1. **Navigate to Email Templates**
   - Dashboard → Authentication → Email Templates
   
2. **Select "Magic Link" Template**
   - This template is used for OTP codes
   
3. **Replace the Content**
   - Delete existing HTML
   - Paste your chosen template above
   - Keep the `{{ .Token }}` placeholder (important!)
   
4. **Preview**
   - Click "Send test email" to see how it looks
   
5. **Save**
   - Click "Save" to apply changes

### Method 2: Via Supabase CLI (Advanced)

```bash
# In your project folder
supabase functions deploy auth/magic-link

# Or update via SQL
UPDATE auth.email_templates 
SET content = 'YOUR_HTML_HERE'
WHERE template = 'magic_link';
```

---

## 🎨 Customization Tips

### Brand Colors:
Replace `#4CAF50` (green) with your brand color throughout the template.

```css
/* Change from */
color: #4CAF50;

/* To your brand color */
color: #YOUR_COLOR;
```

### Logo:
Replace `🌾 Agrilink` with:
- Your actual logo image
- Different emoji
- Custom text

```html
<!-- Text only -->
<h1>Agrilink</h1>

<!-- With image -->
<img src="https://yourdomain.com/logo.png" alt="Agrilink" style="height: 50px;">

<!-- With emoji -->
<h1>🌾 Agrilink</h1>
```

### Add Your Links:
```html
<div class="social-links">
  <a href="https://facebook.com/agrilink">Facebook</a> • 
  <a href="https://agrilink.ph/terms">Terms</a> • 
  <a href="https://agrilink.ph/privacy">Privacy</a>
</div>
```

---

## 📋 Template Variables Available

Supabase provides these variables you can use:

| Variable | Description | Example |
|----------|-------------|---------|
| `{{ .Token }}` | The OTP code | 123456 |
| `{{ .TokenHash }}` | Hashed token | abc123... |
| `{{ .Email }}` | User's email | user@example.com |
| `{{ .SiteURL }}` | Your site URL | https://agrilink.ph |
| `{{ .ConfirmationURL }}` | Magic link (not used for OTP) | https://... |

**Important:** Always keep `{{ .Token }}` in your template!

---

## ✅ Email Template Best Practices

### Do's:
✅ Keep it simple and clean
✅ Make the code large and easy to read
✅ Use high contrast colors
✅ Include expiry time
✅ Add security reminders
✅ Test on multiple email clients
✅ Include support contact
✅ Make it mobile-responsive

### Don'ts:
❌ Don't make it too long
❌ Don't use tiny fonts
❌ Don't hide the code
❌ Don't use complex layouts
❌ Don't forget the token variable
❌ Don't use too many images (may go to spam)
❌ Don't forget plain text fallback

---

## 🧪 Testing Your Template

### Test in Supabase Dashboard:

1. Go to **Email Templates** → **Magic Link**
2. Click **"Send test email"**
3. Enter your email
4. Check how it renders

### Test in Your App:

1. Go to Login screen
2. Click "Login with Email Code"
3. Enter your email
4. Check email inbox
5. Verify:
   - ✅ Email arrives quickly (< 30 seconds)
   - ✅ Template renders correctly
   - ✅ Code is visible and readable
   - ✅ Links work (if any)
   - ✅ Mobile display looks good

### Test Across Email Clients:

- [ ] Gmail (web)
- [ ] Gmail (mobile app)
- [ ] Outlook (web)
- [ ] Outlook (desktop)
- [ ] Yahoo Mail
- [ ] Apple Mail
- [ ] Android email apps

---

## 📱 Mobile-Responsive Template

The templates above are already mobile-responsive, but here's what makes them work:

```css
/* Max width for email container */
.container {
  max-width: 600px; /* Desktop */
  width: 100%; /* Mobile adapts */
}

/* Readable font sizes */
.otp-code {
  font-size: 36px; /* Large on desktop */
  /* Scales automatically on mobile */
}

/* Proper padding */
.content {
  padding: 40px 30px; /* Desktop */
}

@media only screen and (max-width: 600px) {
  .content {
    padding: 20px 15px; /* Mobile */
  }
}
```

---

## 🔒 Security Considerations

### Always Include:
1. **Security warning** - Don't share code
2. **Expiry notice** - 5 minutes
3. **Ignore if not requested** - Prevents confusion
4. **Official contact** - Prevents phishing

### Example Security Section:
```html
<div class="warning">
  <strong>🔒 Security Notice</strong>
  <ul>
    <li>Never share this code with anyone</li>
    <li>Agrilink staff will never ask for this code</li>
    <li>This code expires in 5 minutes</li>
    <li>If you didn't request this, ignore this email</li>
  </ul>
</div>
```

---

## 🌍 Multi-Language Support (Future)

To add Tagalog support later:

```html
<!-- English -->
<div class="message">Your verification code is:</div>

<!-- Tagalog -->
<div class="message">Ang iyong verification code ay:</div>

<!-- Detect language -->
{{ if eq .Locale "tl" }}
  Ang iyong verification code ay:
{{ else }}
  Your verification code is:
{{ end }}
```

---

## 📊 Email Deliverability Tips

### To Avoid Spam Folder:

1. **Keep HTML simple** - Complex HTML triggers spam filters
2. **Use standard fonts** - Arial, Helvetica, sans-serif
3. **Include plain text version** - Always provide fallback
4. **Avoid spam trigger words** - "Free", "Winner", "Click here"
5. **Add unsubscribe link** - For promotional emails (not required for OTP)
6. **Verify sender domain** - Configure SPF/DKIM records
7. **Don't use URL shorteners** - Use full URLs
8. **Test spam score** - Use tools like Mail-Tester.com

### Improve Delivery:

1. **Warm up your domain** - Start with small volumes
2. **Monitor bounce rates** - Remove invalid emails
3. **Check blacklists** - Ensure IP not blacklisted
4. **Use custom SMTP** - Upgrade Supabase plan for better delivery
5. **Authenticate your domain** - Add SPF, DKIM, DMARC records

---

## 🎉 Quick Setup Summary

1. **Copy template** from above (Professional or Simple)
2. **Go to Supabase** → Authentication → Email Templates → Magic Link
3. **Paste template** (keep `{{ .Token }}`)
4. **Customize** colors, text, links
5. **Test** by sending to yourself
6. **Save** and you're done!

---

## 📞 Need More Help?

Check these resources:
- Supabase Email Docs: https://supabase.com/docs/guides/auth/auth-email-templates
- HTML Email Guide: https://www.campaignmonitor.com/dev-resources/guides/coding/
- Email Testing: https://www.mail-tester.com/

---

**Your OTP emails will look amazing! 🎨✨**
