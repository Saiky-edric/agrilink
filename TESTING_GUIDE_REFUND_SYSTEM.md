# Testing Guide - GCash Refund System

## Pre-Testing Setup

### 1. Run Database Migration
```sql
-- Execute this in your Supabase SQL Editor
-- File: supabase_setup/33_add_transaction_and_refund_system.sql
```

This will create:
- `transactions` table
- `refund_requests` table
- Refund columns in `orders` table
- Automatic triggers
- RLS policies
- Helper functions

### 2. Verify Tables Created
```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('transactions', 'refund_requests');

-- Check columns added to orders
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('refund_requested', 'refund_status', 'refunded_at', 'refunded_amount');
```

## Testing Flow

### Test 1: Transaction Creation (Automatic)

**Steps:**
1. Login as a buyer
2. Add products to cart
3. Proceed to checkout
4. Select **GCash** as payment method
5. Upload payment screenshot
6. Place order

**Expected Results:**
- ✅ Order created successfully
- ✅ Transaction automatically created in `transactions` table
- ✅ Transaction type: `payment`
- ✅ Transaction status: `pending`
- ✅ Transaction amount matches order total

**Verify in Database:**
```sql
SELECT * FROM transactions 
WHERE order_id = 'YOUR_ORDER_ID'
ORDER BY created_at DESC;
```

### Test 2: Pending Payment Tab

**Steps:**
1. As buyer, navigate to "My Orders"
2. Check the tabs at top

**Expected Results:**
- ✅ Three tabs visible: Active, Pending, History
- ✅ **Pending tab shows badge** with count (e.g., "Pending 🔶 1")
- ✅ Order appears in Pending tab
- ✅ Orange warning banner: "Waiting for payment confirmation"
- ✅ GCash badge visible on order card
- ✅ "View Details" link works

**Visual Check:**
- Orange theme for pending cards
- Warning icon present
- Clear messaging about payment verification

### Test 3: Payment Verification (Admin)

**Steps:**
1. Login as admin
2. Go to Admin Dashboard → Payment Verification
3. Find the pending GCash payment
4. Verify the payment

**Expected Results:**
- ✅ Transaction status updated to `completed`
- ✅ Transaction `completed_at` timestamp set
- ✅ Order payment_verified = true
- ✅ Order moves from Pending to Active tab (for buyer)

**Verify in Database:**
```sql
SELECT status, completed_at 
FROM transactions 
WHERE order_id = 'YOUR_ORDER_ID';

SELECT payment_verified, payment_verified_at 
FROM orders 
WHERE id = 'YOUR_ORDER_ID';
```

### Test 4: Transaction History Screen

**Steps:**
1. As buyer, go to Profile
2. Tap "Transaction History"
3. Browse through tabs (All, Payments, Refunds)

**Expected Results:**
- ✅ Screen loads successfully
- ✅ Statistics cards show at top (Total Paid, Refunded, Pending)
- ✅ Payment transaction visible in "All" and "Payments" tabs
- ✅ Transaction card shows:
  - Amount (negative for payment)
  - Payment method (GCASH)
  - Date and time
  - Status chip (Completed)
  - Order number
- ✅ Pull-to-refresh works
- ✅ Empty state shows when no transactions

### Test 5: Refund Request (Buyer)

**Steps:**
1. As buyer, go to order details (with verified GCash payment)
2. Check for "Request Refund" button
3. Tap "Request Refund"
4. Select a reason from dropdown
5. Add optional details
6. Submit request

**Expected Results:**
- ✅ "Request Refund" button visible (orange)
- ✅ Dialog appears with refund amount
- ✅ Reason selection required
- ✅ Info message about 3-5 business days
- ✅ Success message: "Refund request submitted successfully"
- ✅ Order details refresh
- ✅ Refund status card appears showing "PENDING"

**Button Visibility Check:**
Should show when:
- Payment method is GCash
- Payment is verified
- Order not completed/cancelled
- No existing refund request

**Verify in Database:**
```sql
SELECT * FROM refund_requests 
WHERE order_id = 'YOUR_ORDER_ID';

SELECT refund_requested, refund_status 
FROM orders 
WHERE id = 'YOUR_ORDER_ID';
```

### Test 6: Admin Refund Management

**Steps:**
1. Login as admin
2. Navigate to Admin Dashboard
3. Go to "Refund Management" (add this to admin menu if needed)
4. View pending requests

**Expected Results:**
- ✅ Screen loads with two tabs (Pending, Processed)
- ✅ Pending tab shows count badge
- ✅ Refund request card visible with:
  - Buyer name and email
  - Order number
  - Amount
  - Reason
  - Request date
  - Approve/Reject buttons
- ✅ Tap card to see full details modal
- ✅ Payment screenshot viewable

### Test 7: Approve Refund (Admin)

**Steps:**
1. As admin in Refund Management
2. Find pending request
3. Tap "Approve"
4. Add optional admin notes
5. Confirm approval

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Info about 3-5 business days shown
- ✅ Success message after approval
- ✅ Request moves to "Processed" tab
- ✅ Status shows "Approved" with green color
- ✅ Refund transaction created in transactions table
- ✅ Order refund_status = 'completed'
- ✅ Buyer receives notification

**Verify in Database:**
```sql
-- Check refund request status
SELECT status, processed_at, processed_by, admin_notes 
FROM refund_requests 
WHERE id = 'YOUR_REFUND_REQUEST_ID';

-- Check refund transaction created
SELECT * FROM transactions 
WHERE order_id = 'YOUR_ORDER_ID' 
AND type = 'refund';

-- Check order updated
SELECT refund_status, refunded_at, refunded_amount 
FROM orders 
WHERE id = 'YOUR_ORDER_ID';
```

### Test 8: Reject Refund (Admin)

**Steps:**
1. Create another refund request (repeat Test 5)
2. As admin, tap "Reject" on the request
3. **Enter reason** (required for rejection)
4. Confirm rejection

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Admin notes field is required
- ✅ Shows error if notes empty
- ✅ Success message after rejection
- ✅ Request moves to "Processed" tab
- ✅ Status shows "Rejected" with red color
- ✅ Buyer receives notification with reason

**Verify in Database:**
```sql
SELECT status, admin_notes 
FROM refund_requests 
WHERE id = 'YOUR_REFUND_REQUEST_ID';

SELECT refund_status 
FROM orders 
WHERE id = 'YOUR_ORDER_ID';
-- Should be 'rejected'
```

### Test 9: Transaction History After Refund

**Steps:**
1. As buyer, go back to Transaction History
2. Check "All" and "Refunds" tabs

**Expected Results:**
- ✅ Both payment and refund transactions visible in "All" tab
- ✅ Refund appears in "Refunds" tab
- ✅ Refund transaction shows:
  - Amount (positive, with + sign)
  - Green color for amount
  - Refund reason
  - Status: Completed
  - Date processed
- ✅ Statistics updated:
  - Total Refunded shows refund amount
  - Total Paid remains same

### Test 10: Refund Status on Order Details

**Steps:**
1. As buyer, view order details with approved refund
2. Check refund status card

**Expected Results:**
- ✅ Green status card visible
- ✅ Shows "Refund APPROVED"
- ✅ Displays refund amount
- ✅ Shows refund reason
- ✅ Shows processed date
- ✅ Shows admin notes if any

### Test 11: Edge Cases

#### A. Refund Button Not Visible
Test that button doesn't show when:
- [ ] Payment method is COD/COP
- [ ] Payment not verified yet
- [ ] Order already completed
- [ ] Order cancelled
- [ ] Refund request already exists

#### B. Duplicate Refund Prevention
- [ ] Try to create second refund request for same order
- [ ] Should fail with appropriate error

#### C. Transaction Stats Accuracy
- [ ] Place multiple orders
- [ ] Request and process multiple refunds
- [ ] Verify stats calculations correct

#### D. Empty States
- [ ] No pending payments → Check empty state in Pending tab
- [ ] No transactions → Check empty state in Transaction History
- [ ] No refund requests → Check empty state in Admin panel

## Verification Checklist

### Database Integrity
- [ ] All tables created successfully
- [ ] RLS policies active
- [ ] Triggers functioning
- [ ] Foreign keys intact
- [ ] Indexes created

### UI/UX
- [ ] All screens load without errors
- [ ] Navigation works smoothly
- [ ] Color schemes appropriate
- [ ] Icons display correctly
- [ ] Text is readable and clear
- [ ] Loading states show properly
- [ ] Error messages are helpful

### Functionality
- [ ] Transactions auto-create on order placement
- [ ] Transactions update on payment verification
- [ ] Pending tab filters correctly
- [ ] Refund requests create successfully
- [ ] Admin can approve/reject refunds
- [ ] Refund transactions created properly
- [ ] Notifications sent correctly
- [ ] Stats calculate accurately

### Security
- [ ] Buyers only see own transactions
- [ ] Buyers only see own refund requests
- [ ] Admins can see all transactions
- [ ] Admins can process all refunds
- [ ] No unauthorized access possible

## Common Issues & Solutions

### Issue: Transaction not created
**Solution:** Check trigger is installed:
```sql
SELECT * FROM pg_trigger 
WHERE tgname = 'trigger_create_transaction_on_gcash_order';
```

### Issue: Pending tab not showing orders
**Solution:** Verify filtering logic in buyer_orders_screen.dart:
- Check `paymentMethod?.toLowerCase() == 'gcash'`
- Check `paymentVerified != true`

### Issue: Refund button not visible
**Solution:** Check order conditions:
- Payment method is GCash
- Payment is verified
- Order status is not completed/cancelled
- No existing refund request

### Issue: Admin can't process refund
**Solution:** Verify admin role in database:
```sql
SELECT id, role FROM profiles WHERE id = 'YOUR_ADMIN_ID';
```

## Performance Testing

### Load Testing
- [ ] Create 50+ transactions
- [ ] Create 20+ refund requests
- [ ] Check screen load times
- [ ] Verify pagination works (if implemented)
- [ ] Test refresh performance

### Concurrent Testing
- [ ] Multiple buyers requesting refunds simultaneously
- [ ] Admin processing multiple refunds at once
- [ ] Transaction history loading for multiple users

## Success Criteria

✅ **All Tests Pass** when:
1. Transactions auto-create for GCash orders
2. Pending tab shows unverified payments correctly
3. Transaction history displays all transactions
4. Buyers can request refunds successfully
5. Admins can approve/reject refunds
6. Refund transactions are created
7. All notifications work
8. Stats calculate correctly
9. No security vulnerabilities
10. UI is responsive and clear

## Next Steps After Testing

1. Monitor system in production
2. Gather user feedback
3. Add analytics tracking
4. Consider additional features:
   - Auto-refund for cancelled orders
   - Partial refunds
   - Refund analytics dashboard
   - CSV export for refunds

---

**Happy Testing! 🎉**

For issues or questions, refer to `REFUND_SYSTEM_IMPLEMENTATION_COMPLETE.md`
