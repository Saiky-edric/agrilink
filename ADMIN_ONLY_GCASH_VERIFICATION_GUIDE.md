# 🔐 Admin-Only GCash Payment Verification - Complete Guide

## ✅ System Overview

The GCash payment system has been configured for **Admin-Only Verification** for maximum security and control.

### **Payment Flow:**
```
1. Buyer places order → Selects GCash payment
2. Buyer uploads payment proof → Screenshot + Reference number
3. ADMIN verifies payment → Checks GCash app
4. Farmer receives notification → "Payment verified, process order"
5. Farmer processes order → Normal fulfillment flow
```

---

## 🔑 Key Security Features

✅ **Only YOU (admin) have access to AgriLink GCash account**  
✅ **Farmers CANNOT verify payments** - they can only view status  
✅ **Complete audit trail** - all verifications logged  
✅ **Automatic farmer notification** - when you verify payment  
✅ **Centralized control** - all payments verified from admin dashboard  

---

## 📋 Setup Instructions

### **Step 1: Run Database Migrations**

Run these TWO migrations in Supabase SQL Editor:

```sql
-- Migration 1: Base payment system
-- File: supabase_setup/29_add_gcash_payment_proof_system.sql

-- Migration 2: Switch to admin-only
-- File: supabase_setup/30_switch_to_admin_only_payment_verification.sql
```

### **Step 2: Update Your GCash Details**

```sql
UPDATE platform_settings
SET 
  agrilink_gcash_number = '09XX-XXX-XXXX',  -- Your GCash number
  agrilink_gcash_name = 'Your Full Name'     -- Name on your GCash
WHERE singleton_guard = true;

-- Verify it worked:
SELECT agrilink_gcash_number, agrilink_gcash_name 
FROM platform_settings;
```

---

## 🛒 Buyer Journey (What Buyers Experience)

### **Step 1: Checkout with GCash**
- Select GCash as payment method
- See order summary with total amount
- Click "Place Order"

### **Step 2: Upload Payment Proof**
- Redirected to payment proof screen
- See **AgriLink's GCash number** (your number)
- Upload screenshot from GCash app
- Enter 13-digit reference number
- Submit

### **Step 3: Wait for Verification**
- Order shows: **"⏳ Payment Pending Verification"**
- Cannot proceed until admin verifies
- Receives notification when verified

---

## 👨‍💼 Admin Journey (How YOU Verify Payments)

### **Step 1: Access Payment Verification Dashboard**

Navigate to: **`/admin/payment-verification`**

Or add a button to your admin dashboard:
```dart
ListTile(
  leading: Icon(Icons.payment),
  title: Text('Payment Verification'),
  trailing: _pendingCount > 0 
    ? Badge(label: Text('$_pendingCount'), child: Icon(Icons.arrow_forward))
    : Icon(Icons.arrow_forward),
  onTap: () => context.push('/admin/payment-verification'),
)
```

### **Step 2: Review Pending Payments**

You'll see a list of pending GCash payments with:
- ✅ Order number
- ✅ Buyer name
- ✅ Farmer name  
- ✅ Amount paid
- ✅ GCash reference number
- ✅ Upload timestamp

### **Step 3: Verify in Your GCash App**

**On your phone:**
1. Open **GCash app**
2. Go to **Transaction History**
3. Look for the matching:
   - **Amount** (e.g., ₱570.00)
   - **Reference number** (e.g., GC1234567890123)
   - **Date/time** (should match upload time)

### **Step 4: View Payment Screenshot**

In the admin dashboard:
- Tap **"View Payment Screenshot"**
- See full-screen image
- Zoom/pan to verify details
- Compare with your GCash app

### **Step 5: Approve or Reject**

**If payment is VALID:**
- Tap **"Verify"** button (green)
- Add optional notes: "Payment confirmed in GCash"
- Confirm

**If payment is INVALID:**
- Tap **"Reject"** button (red)
- Enter reason: "Payment not received" or "Wrong amount"
- Confirm
- Buyer will be notified and can re-upload

### **Step 6: Automatic Notifications**

When you verify:
- ✅ **Farmer receives notification**: "Payment verified - process order"
- ✅ **Buyer sees status update**: "Payment Verified ✓"
- ✅ **Order can proceed** to fulfillment

---

## 👨‍🌾 Farmer Experience (View Only)

Farmers **CANNOT verify payments** but they can:

### **View Payment Status:**
- See order with GCash payment method
- Status shows: "Payment Pending Verification" or "Payment Verified"
- Cannot accept order until payment is verified

### **Receive Notification:**
When admin verifies payment, farmer gets notification:
```
📬 Payment Verified
Payment for order #ABC12345 has been verified by admin. 
You can now process this order.
```

### **Process Order:**
After verification, farmer can:
- Accept the order
- Prepare products
- Mark as ready for delivery/pickup
- Complete normally

---

## 🔍 Database Audit Trail

Every verification action is logged in `payment_verification_logs`:

```sql
-- View all payment verifications
SELECT 
  pvl.action,
  pvl.notes,
  pvl.created_at,
  o.id as order_id,
  o.total_amount,
  o.payment_reference,
  u.full_name as verified_by_admin
FROM payment_verification_logs pvl
JOIN orders o ON pvl.order_id = o.id
JOIN users u ON pvl.performed_by = u.id
ORDER BY pvl.created_at DESC;
```

---

## 📊 Admin Analytics View

A special view has been created for admins:

```sql
-- View all pending payment verifications
SELECT * FROM admin_pending_payment_verifications;
```

This shows:
- Buyer details (name, email, phone)
- Farmer details (name, store name, email, phone)
- Payment details (amount, reference, screenshot URL)
- Timestamps

---

## ⚠️ Important Security Notes

### **1. Never Share GCash Account Access**
- ❌ Don't give farmers your GCash password
- ❌ Don't use shared GCash accounts
- ✅ Only YOU (admin) should access the GCash account

### **2. Verify EVERY Payment**
- ✅ Check GCash app for actual money received
- ✅ Match reference numbers exactly
- ✅ Verify amounts match
- ✅ Check timestamps are reasonable

### **3. Common Fraud Attempts**
- 🚩 Edited screenshots (Photoshop)
- 🚩 Screenshots from other transactions
- 🚩 Wrong reference numbers
- 🚩 Partial payments
- 🚩 Very old screenshots

**How to protect:**
- Always verify in your actual GCash app
- Don't rely only on screenshot
- Check reference number matches
- Verify transaction is recent

---

## 🧪 Testing Guide

### **Test as Buyer:**
1. Login as buyer
2. Add products to cart
3. Checkout with GCash
4. Upload a test image
5. Enter ref: `1234567890123`
6. Submit

### **Test as Admin (You):**
1. Login as admin
2. Go to `/admin/payment-verification`
3. See 1 pending payment
4. View screenshot
5. Tap "Verify"
6. Confirm

### **Test as Farmer:**
1. Login as farmer
2. Check orders
3. See order with "Payment Pending"
4. Cannot accept until verified
5. Wait for admin verification
6. Receive notification
7. Can now process order

---

## 💡 Best Practices

### **Daily Routine:**
1. Check payment verification dashboard 2-3 times daily
2. Verify payments within 2-4 hours
3. Add notes for reference
4. Monitor for suspicious patterns

### **Weekends/Holidays:**
- Set expectations with buyers (verification within 24h)
- Consider hiring verification staff as you scale
- Enable email notifications for new payment uploads

### **Scaling Beyond 50 Orders/Day:**
- Hire dedicated verification staff
- Create verification checklist
- Implement batch verification tools
- Consider automated payment gateway

---

## 🆘 Troubleshooting

### **Issue: Can't access /admin/payment-verification**
**Solution:** 
- Make sure you're logged in as admin
- Check user role in database:
  ```sql
  SELECT id, email, role FROM users WHERE email = 'your@email.com';
  ```

### **Issue: No pending payments showing**
**Solution:**
- Check if orders have payment proof:
  ```sql
  SELECT id, payment_screenshot_url, payment_verified 
  FROM orders 
  WHERE payment_method = 'gcash';
  ```

### **Issue: Farmer can still verify payments**
**Solution:**
- Run migration 30 again
- Check RLS policies:
  ```sql
  SELECT * FROM pg_policies 
  WHERE tablename = 'payment_verification_logs';
  ```

---

## 📱 Adding Navigation Button

### **In Admin Dashboard:**

Add this to your admin menu:

```dart
ListTile(
  leading: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.account_balance_wallet, color: Colors.blue.shade700),
  ),
  title: Text('Payment Verification'),
  subtitle: Text('Review GCash payments'),
  trailing: pendingCount > 0
      ? Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$pendingCount',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      : Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push('/admin/payment-verification'),
)
```

---

## 📈 Success Metrics

Track these metrics:
- ✅ Average verification time
- ✅ Number of rejected payments
- ✅ Payment fraud attempts
- ✅ Buyer satisfaction with verification speed
- ✅ Total GCash revenue processed

---

## 🎯 What's Different from Before

| Aspect | Before | After (Admin-Only) |
|--------|--------|-------------------|
| Who verifies | Farmers | Admin ONLY |
| GCash access | Shared/farmers need access | Admin private account |
| Security | Medium risk | High security |
| Control | Distributed | Centralized |
| Speed | Potentially faster | Slight delay (admin bottleneck) |
| Fraud risk | Higher | Lower |

---

## ✅ Checklist Before Going Live

- [ ] Both migrations run successfully
- [ ] GCash number updated in platform_settings
- [ ] Tested complete buyer flow
- [ ] Tested admin verification
- [ ] Tested farmer notification
- [ ] Navigation button added to admin dashboard
- [ ] Trained on fraud detection
- [ ] Set verification time expectations

---

## 🚀 You're Ready!

Your GCash payment system is now configured with **Admin-Only Verification** for maximum security and control.

**Key Takeaway:** Only YOU verify payments by checking your GCash app. Farmers just receive notifications and process orders after you verify.

---

**Questions? Issues? Check the troubleshooting section or review the testing guide!** 💪
