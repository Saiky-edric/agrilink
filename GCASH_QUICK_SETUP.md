# 🚀 GCash Payment System - Quick Setup Guide

## ✅ Fixed for Your Schema

The migration has been updated to work with your `platform_settings` table structure (direct columns instead of key-value pairs).

---

## 📋 Setup Steps (5 Minutes)

### **Step 1: Run Database Migration**

In your Supabase SQL Editor, run this file:
```
supabase_setup/29_add_gcash_payment_proof_system.sql
```

This will:
- ✅ Add payment proof columns to `orders` table
- ✅ Create `payment_verification_logs` table
- ✅ Add GCash settings columns to `platform_settings`
- ✅ Set up RLS policies
- ✅ Create helper functions

### **Step 2: Update Your GCash Number**

After migration, update with your actual details:

```sql
UPDATE platform_settings
SET 
  agrilink_gcash_number = '09XX-XXX-XXXX',  -- Your GCash number
  agrilink_gcash_name = 'Your Name Here'     -- Name on GCash account
WHERE singleton_guard = true;
```

### **Step 3: Test the Flow**

**As Buyer:**
1. Add products to cart
2. Go to checkout
3. Select "GCash" payment
4. See instructions → Place order
5. Upload payment screenshot
6. Enter reference number
7. Submit

**As Farmer:**
1. Navigate to `/farmer/payment-verification`
2. See pending payment
3. View screenshot
4. Verify payment
5. Approve

---

## 🎯 That's It!

Your GCash payment system is now live and ready to use.

---

## 📱 How It Works

```
Buyer → Pays via GCash → Uploads Proof → Farmer Verifies → Order Proceeds
```

Money goes to **AgriLink's master GCash account**, then you handle payouts to farmers using the existing manual payout system.

---

## 🔧 Troubleshooting

**Error: "Failed to load payment details"**
- Make sure migration ran successfully
- Check that `platform_settings` has data:
  ```sql
  SELECT agrilink_gcash_number, agrilink_gcash_name 
  FROM platform_settings;
  ```

**Payment verification not showing**
- Navigate directly to: `/farmer/payment-verification`
- Or add a button in farmer dashboard

**Screenshot upload fails**
- Check storage bucket `verification-documents` exists
- Verify RLS policies allow uploads

---

## 💡 Next Steps

1. **Add navigation button** to farmer dashboard for easy access to payment verification
2. **Train farmers** on verification process
3. **Monitor** first few transactions closely
4. **Go live!** 🎊

---

**Ready to process GCash payments!** 💰
