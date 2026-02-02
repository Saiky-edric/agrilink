# Strict Refund Policy - Testing Guide

## 🧪 Test Scenarios

### **Test 1: Normal Cancellation (Before Packing)**

**Setup:**
```sql
-- Create a test order
INSERT INTO orders (id, buyer_id, farmer_id, total_amount, delivery_address, 
                    buyer_status, farmer_status, created_at)
VALUES (
  gen_random_uuid(),
  '[buyer_user_id]',
  '[farmer_user_id]',
  350.00,
  'Test Address, Agusan del Sur',
  'pending',
  'newOrder',
  NOW()
);
```

**Test Steps:**
1. Open order details as buyer
2. Verify "Cancel Order" button is visible
3. Verify green banner shows: "Cancellation Available"
4. Click "Cancel Order"
5. Select reason from dropdown
6. Confirm cancellation

**Expected Result:**
- ✅ Order status changes to `cancelled`
- ✅ Farmer receives notification
- ✅ Success message shown to buyer

---

### **Test 2: Blocked Cancellation (After Packing Starts)**

**Setup:**
```sql
-- Update order to toPack status
UPDATE orders 
SET farmer_status = 'toPack',
    to_pack_at = NOW()
WHERE id = '[test_order_id]';
```

**Test Steps:**
1. Open order details as buyer
2. Verify "Cancel Order" button is NOT visible
3. Verify red banner shows: "Cancellation Not Allowed"
4. Verify message explains farmer has started preparing

**Expected Result:**
- ✅ No cancel button shown
- ✅ Clear explanation displayed
- ✅ Tip about refund policy shown

---

### **Test 3: Automatic Overdue Detection**

**Setup:**
```sql
-- Create order with past deadline
INSERT INTO orders (id, buyer_id, farmer_id, total_amount, delivery_address,
                    buyer_status, farmer_status, created_at, accepted_at,
                    delivery_deadline)
VALUES (
  gen_random_uuid(),
  '[buyer_user_id]',
  '[farmer_user_id]',
  450.00,
  'Test Address',
  'pending',
  'toDeliver',
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '3 days'  -- Deadline was 3 days ago
);

-- Run overdue detection
SELECT * FROM mark_overdue_orders();
```

**Test Steps:**
1. Run `mark_overdue_orders()` function
2. Check order is marked as overdue:
   ```sql
   SELECT farmer_fault, is_overdue, fault_reason 
   FROM orders 
   WHERE id = '[test_order_id]';
   ```
3. Verify buyer received notification
4. Open order details as buyer
5. Verify "Request Refund" button is visible
6. Verify orange banner shows: "Refund Available - Delivery Issue"

**Expected Result:**
- ✅ `farmer_fault = true`
- ✅ `is_overdue = true`
- ✅ `fault_reason` populated
- ✅ Buyer notified
- ✅ Refund button visible

---

### **Test 4: Manual Fault Reporting (Admin)**

**Setup:**
```sql
-- Create order in toPack status (normally no refund)
UPDATE orders
SET farmer_status = 'toPack',
    to_pack_at = NOW()
WHERE id = '[test_order_id]';
```

**Test Steps:**
1. As admin, report farmer fault:
   ```sql
   SELECT report_farmer_fault(
     '[test_order_id]',
     'Product quality issue reported by buyer',
     '[admin_user_id]'
   );
   ```
2. Verify buyer receives notification
3. Open order details as buyer
4. Verify "Request Refund" button is now visible
5. Verify banner shows farmer fault detected

**Expected Result:**
- ✅ Order marked with `farmer_fault = true`
- ✅ Buyer notified
- ✅ Refund available despite toPack status

---

### **Test 5: Refund Eligibility Check**

**Test 5a: Before Packing**
```dart
final eligibility = await orderService.checkRefundEligibility(orderId);
// Expected:
{
  "eligible": true,
  "reason": "Order can be cancelled before farmer starts preparing",
  "eligibility_type": "before_packing",
  "current_status": "accepted",
  "farmer_fault": false,
  "is_overdue": false
}
```

**Test 5b: After Packing (No Fault)**
```dart
final eligibility = await orderService.checkRefundEligibility(orderId);
// Expected:
{
  "eligible": false,
  "reason": "Cannot request refund. Farmer has already started preparing...",
  "eligibility_type": null,
  "current_status": "toPack",
  "farmer_fault": false,
  "is_overdue": false
}
```

**Test 5c: After Packing (With Fault)**
```dart
final eligibility = await orderService.checkRefundEligibility(orderId);
// Expected:
{
  "eligible": true,
  "reason": "Refund allowed due to farmer fault: Delivery failure",
  "eligibility_type": "farmer_fault_delay",
  "current_status": "toDeliver",
  "farmer_fault": true,
  "is_overdue": true
}
```

---

### **Test 6: Complete Refund Flow with Fault**

**Setup:**
```sql
-- Create overdue order
INSERT INTO orders (id, buyer_id, farmer_id, total_amount, delivery_address,
                    buyer_status, farmer_status, payment_method, payment_verified,
                    created_at, delivery_deadline, farmer_fault, is_overdue)
VALUES (
  gen_random_uuid(),
  '[buyer_user_id]',
  '[farmer_user_id]',
  500.00,
  'Test Address',
  'pending',
  'toDeliver',
  'gcash',
  true,
  NOW() - INTERVAL '7 days',
  NOW() - INTERVAL '2 days',
  true,
  true
);
```

**Test Steps:**
1. Buyer opens order details
2. Sees orange banner: "Refund Available - Delivery Issue"
3. Clicks "Request Refund"
4. Selects reason: "Delivery is taking too long"
5. Adds details: "Expected delivery 2 days ago, still not received"
6. Submits refund request
7. Admin reviews in refund management screen
8. Admin sees `eligibility_reason = 'farmer_fault_delay'`
9. Admin approves refund with notes
10. Buyer receives approval notification
11. Order status changes to cancelled

**Expected Result:**
- ✅ Refund request created with correct eligibility reason
- ✅ Admin can see fault details
- ✅ Refund processed successfully
- ✅ All parties notified

---

### **Test 7: GCash Verified Payment**

**Test 7a: Before Packing**
```sql
UPDATE orders
SET payment_method = 'gcash',
    payment_verified = true,
    payment_screenshot_url = 'https://...',
    farmer_status = 'accepted'
WHERE id = '[test_order_id]';
```

**Expected:**
- ✅ "Request Refund" button shown (not cancel)
- ✅ Blue banner explains to use refund process
- ✅ Refund request works correctly

**Test 7b: After Packing (No Fault)**
```sql
UPDATE orders
SET payment_method = 'gcash',
    payment_verified = true,
    farmer_status = 'toPack'
WHERE id = '[test_order_id]';
```

**Expected:**
- ✅ No cancel button
- ✅ No refund button (not eligible)
- ✅ Red banner explains policy

---

### **Test 8: COD Order (More Flexible)**

**Setup:**
```sql
UPDATE orders
SET payment_method = 'cod',
    farmer_status = 'accepted'
WHERE id = '[test_order_id]';
```

**Expected:**
- ✅ "Cancel Order" button visible (before packing)
- ✅ Can cancel easily (no prepayment)
- ✅ Green banner shows cancellation available

---

### **Test 9: Deadline Trigger**

**Test automatic deadline setting:**
```sql
-- Create order in newOrder
INSERT INTO orders (id, buyer_id, farmer_id, total_amount, delivery_address,
                    buyer_status, farmer_status, created_at)
VALUES (gen_random_uuid(), '[buyer]', '[farmer]', 300.00, 'Address',
        'pending', 'newOrder', NOW());

-- Update to accepted (should trigger deadline)
UPDATE orders
SET farmer_status = 'accepted',
    accepted_at = NOW()
WHERE id = '[test_order_id]';

-- Check deadline was set
SELECT delivery_deadline, 
       delivery_deadline - NOW() as time_until_deadline
FROM orders
WHERE id = '[test_order_id]';
-- Expected: ~5 days from now
```

---

### **Test 10: Edge Cases**

**Test 10a: Already Cancelled Order**
```sql
UPDATE orders SET farmer_status = 'cancelled' WHERE id = '[test_order_id]';
```
**Expected:** No refund/cancel buttons, no eligibility banner

**Test 10b: Completed Order**
```sql
UPDATE orders 
SET farmer_status = 'completed',
    completed_at = NOW()
WHERE id = '[test_order_id]';
```
**Expected:** No refund/cancel buttons, review button shown

**Test 10c: Existing Refund Request**
```sql
INSERT INTO refund_requests (order_id, user_id, amount, reason, status)
VALUES ('[test_order_id]', '[buyer_id]', 300.00, 'Test', 'pending');
```
**Expected:** Refund request card shown, no new request button

---

## 🔍 SQL Debugging Queries

### Check Order Eligibility Details
```sql
SELECT 
  id,
  farmer_status,
  farmer_fault,
  is_overdue,
  delivery_deadline,
  fault_reason,
  created_at,
  to_pack_at,
  delivery_deadline - NOW() as time_until_deadline,
  check_refund_eligibility(id) as eligibility
FROM orders
WHERE id = '[test_order_id]';
```

### Find Overdue Orders
```sql
SELECT 
  id,
  farmer_status,
  delivery_deadline,
  NOW() - delivery_deadline as overdue_by,
  is_overdue,
  farmer_fault
FROM orders
WHERE delivery_deadline IS NOT NULL
  AND NOW() > delivery_deadline
  AND farmer_status IN ('toPack', 'toDeliver', 'readyForPickup')
ORDER BY delivery_deadline;
```

### Test Refund Eligibility Function
```sql
SELECT 
  o.id,
  o.farmer_status,
  o.farmer_fault,
  check_refund_eligibility(o.id) as eligibility
FROM orders o
WHERE o.buyer_id = '[test_buyer_id]'
ORDER BY o.created_at DESC
LIMIT 5;
```

### Simulate Overdue Detection
```sql
-- Manually set old deadline for testing
UPDATE orders
SET delivery_deadline = NOW() - INTERVAL '2 days'
WHERE id = '[test_order_id]';

-- Run detection
SELECT * FROM mark_overdue_orders();

-- Verify results
SELECT 
  id,
  farmer_fault,
  is_overdue,
  fault_reason
FROM orders
WHERE id = '[test_order_id]';
```

---

## ✅ Checklist

### Database Tests
- [ ] Delivery deadlines set automatically on acceptance
- [ ] Overdue detection works correctly
- [ ] Fault reporting creates proper records
- [ ] Eligibility check returns correct results
- [ ] Refund request includes eligibility reason

### Service Tests
- [ ] `checkRefundEligibility()` returns proper JSON
- [ ] `reportFarmerFault()` updates order correctly
- [ ] `cancelOrder()` validates eligibility first
- [ ] `createRefundRequest()` validates eligibility first

### UI Tests
- [ ] Cancel button shows/hides correctly
- [ ] Refund button shows/hides correctly
- [ ] Banner displays context-aware messages
- [ ] Colors match eligibility status
- [ ] Refund reasons change based on fault type
- [ ] Loading states work properly

### Notification Tests
- [ ] Buyer notified when order becomes overdue
- [ ] Buyer notified when fault reported
- [ ] Farmer notified of cancellation
- [ ] Admin notified of refund requests
- [ ] Buyer notified of refund approval/rejection

### Integration Tests
- [ ] Complete flow: Order → Overdue → Refund → Approval
- [ ] GCash payment with strict policy
- [ ] COD order with flexible cancellation
- [ ] Manual fault reporting by admin
- [ ] Multiple orders with different statuses

---

## 📊 Test Results Template

```markdown
## Test Results - [Date]

### Environment
- Platform: Android / iOS
- Flutter Version: 3.x.x
- Database: Supabase (Production/Staging)

### Test 1: Normal Cancellation
- Status: ✅ Pass / ❌ Fail
- Notes: 

### Test 2: Blocked Cancellation
- Status: ✅ Pass / ❌ Fail
- Notes:

### Test 3: Overdue Detection
- Status: ✅ Pass / ❌ Fail
- Notes:

[Continue for all tests...]

### Issues Found
1. [Issue description]
   - Severity: High/Medium/Low
   - Steps to reproduce:
   - Expected vs Actual:

### Summary
- Tests Passed: X/10
- Tests Failed: X/10
- Critical Issues: X
- Ready for Production: Yes/No
```

---

**Status**: 🧪 Ready for Testing  
**Last Updated**: January 29, 2026  
**Version**: 1.0.0
