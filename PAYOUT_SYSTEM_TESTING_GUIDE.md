# 🧪 Manual Payout System - Complete Testing Guide

## 🎯 **What We Fixed**

### **CRITICAL: Payment Method Filtering**

The payout system now **correctly excludes** COD (Cash on Delivery) and COP (Cash on Pickup) orders because:

✅ **COD Orders**: Buyer pays farmer directly in cash → Farmer already has the money  
✅ **COP Orders**: Buyer pays farmer directly when picking up → Farmer already has the money  
✅ **GCash/Bank/Card Orders**: Platform receives payment → Farmer gets paid via payout system  

---

## 📋 **Prerequisites**

Before testing, you need:

1. ✅ **Database Migrations Run**:
   - Migration 27: `27_add_manual_payout_system.sql`
   - Migration 28: `28_fix_payout_calculation_payment_method.sql`

2. ✅ **Test Accounts**:
   - 1 Buyer account
   - 1 Farmer account
   - 1 Admin account

3. ✅ **Products**:
   - At least 2-3 products from farmer

---

## 🧪 **Test Scenario 1: Payment Method Differentiation**

### **Objective**: Verify COD/COP orders are excluded from payouts

### **Steps**:

1. **Login as Buyer**

2. **Create Order 1 - GCash Payment** (Should be in payout)
   - Add product to cart (e.g., ₱500)
   - Go to checkout
   - Select payment method: **GCash**
   - Place order
   - **Expected**: Order created with `payment_method = 'gcash'`

3. **Create Order 2 - COD Payment** (Should NOT be in payout)
   - Add product to cart (e.g., ₱300)
   - Go to checkout
   - Select payment method: **Cash on Delivery**
   - Place order
   - **Expected**: Order created with `payment_method = 'cod'`

4. **Create Order 3 - COP Payment** (Should NOT be in payout)
   - Add product to cart (e.g., ₱200)
   - Go to checkout
   - Select delivery method: **Pickup**
   - Select payment method: **Cash on Pickup**
   - Place order
   - **Expected**: Order created with `payment_method = 'cop'`

5. **Login as Farmer**

6. **Accept and Complete All Orders**
   - Go to Orders screen
   - For each order:
     - Tap "Accept Order"
     - Tap "Ready to Pack"
     - For delivery: Tap "Ready for Delivery" → Tap "Mark as Delivered"
     - For pickup: Tap "Ready for Pickup" → Tap "Mark as Picked Up"

7. **Check Wallet Balance**
   - Navigate to Wallet screen
   - **Expected Result**:
     ```
     Available Balance: ₱450.00
     (Only Order 1: ₱500 - 10% commission = ₱450)
     
     NOT included:
     - Order 2 (COD): ₱300 → Farmer already received cash
     - Order 3 (COP): ₱200 → Farmer already received cash
     ```

8. **Verify in Database** (Optional)
   ```sql
   -- Check all orders
   SELECT 
     order_number,
     total_amount,
     payment_method,
     farmer_status,
     total_amount * 0.90 as farmer_earning
   FROM orders
   WHERE farmer_id = 'YOUR_FARMER_ID'
   ORDER BY created_at DESC;
   
   -- Check payout eligible orders
   SELECT * FROM farmer_payout_eligible_orders
   WHERE farmer_id = 'YOUR_FARMER_ID';
   
   -- Check cash orders (excluded from payout)
   SELECT * FROM farmer_cash_orders
   WHERE farmer_id = 'YOUR_FARMER_ID';
   ```

---

## 🧪 **Test Scenario 2: Complete Payout Flow**

### **Objective**: Test end-to-end payout request and approval

### **Steps**:

1. **Login as Farmer**

2. **Setup Payment Details**
   - Navigate to Payment Settings
   - Add GCash Number: `09171234567`
   - Add Account Name: `Juan Dela Cruz`
   - Save

3. **Check Wallet**
   - Go to Wallet screen
   - Verify available balance (should be ₱450 from Scenario 1)
   - **Expected**: "Request Payout" button is enabled

4. **Request Payout**
   - Tap "Request Payout"
   - Amount: `₱450.00` (or use MAX button)
   - Payment Method: **GCash**
   - Verify payment details shown:
     ```
     GCash Number: 09171234567
     Account Name: Juan Dela Cruz
     ```
   - Notes (optional): "Test payout request"
   - Tap "Submit Payout Request"
   - **Expected**: Success message, return to wallet

5. **Verify Request Created**
   - Check Wallet screen
   - **Expected**: 
     - Available balance: ₱0.00
     - Warning message: "Payout Request Pending"
     - Cannot request another payout
   - Check history section
   - **Expected**: See request with status "Pending"

6. **Login as Admin**

7. **View Payout Requests**
   - Navigate to Admin Dashboard
   - Open "Payout Management" (or Payouts)
   - **Expected**:
     ```
     Statistics:
     - Pending: ₱450.00 (1 request)
     - Total Paid: ₱0.00
     
     Tabs:
     - All: 1 request
     - Pending: 1 request
     - Processing: 0
     - History: 0
     ```

8. **Review Request**
   - Tap on pending request
   - **Expected to see**:
     ```
     Farmer: Juan Dela Cruz (or store name)
     Amount: ₱450.00
     Payment Method: GCash
     GCash Number: 09171234567 (with copy button)
     Account Name: Juan Dela Cruz
     Farmer Notes: "Test payout request"
     
     Order Breakdown:
     - Order #XXX: ₱500 → ₱450 (after commission)
     
     Activity Log:
     - Requested by farmer at [timestamp]
     ```

9. **Approve Request**
   - Tap "Approve & Start Processing"
   - Add notes (optional): "Processing payment"
   - Confirm
   - **Expected**: Status changes to "Processing"

10. **Simulate Sending Money**
    - Copy GCash number (09171234567)
    - (In real scenario: Open GCash app, send ₱450)
    - For testing: Just pretend you sent it

11. **Mark as Completed**
    - Tap "Mark as Completed"
    - Add payment reference: "GCash Ref: GC123456789"
    - Confirm
    - **Expected**: 
      - Status changes to "Completed"
      - Return to dashboard
      - Statistics updated

12. **Login as Farmer**

13. **Verify Payout Received**
    - Go to Wallet screen
    - **Expected**:
      ```
      Available Balance: ₱0.00
      Total Paid Out: ₱450.00
      
      Payout History:
      - ₱450.00 - Completed
      - GCash: 09171234567
      - Requested: [date]
      - Processed: [date]
      ```

---

## 🧪 **Test Scenario 3: Minimum Balance Validation**

### **Objective**: Verify ₱100 minimum requirement

### **Steps**:

1. **Login as Buyer**

2. **Create Small Order**
   - Order total: ₱80 via GCash
   - Complete order

3. **Login as Farmer**

4. **Complete Order**
   - Accept and complete the ₱80 order

5. **Check Wallet**
   - Navigate to Wallet
   - **Expected**:
     ```
     Available Balance: ₱72.00 (₱80 - 10% = ₱72)
     Request Payout button: DISABLED
     Warning: "Minimum ₱100 required to request payout"
     ```

6. **Try to Request Payout**
   - Button should be grayed out
   - **Expected**: Cannot submit request

---

## 🧪 **Test Scenario 4: Pending Earnings Calculation**

### **Objective**: Verify pending earnings from incomplete orders

### **Steps**:

1. **Login as Buyer**

2. **Create Orders** (don't complete yet):
   - Order 1: ₱200 via GCash
   - Order 2: ₱150 via Bank Transfer
   - Order 3: ₱100 via COD (should be excluded)

3. **Login as Farmer**

4. **Accept Orders** (but don't complete):
   - Accept all 3 orders
   - Mark as "To Pack"
   - Stop here (don't deliver)

5. **Check Wallet**
   - **Expected**:
     ```
     Available Balance: ₱0.00
     Pending Earnings: ₱315.00
     (Order 1: ₱200 * 0.9 = ₱180)
     (Order 2: ₱150 * 0.9 = ₱135)
     (Order 3: COD = NOT COUNTED)
     ```

6. **Complete Orders**
   - Complete Order 1 and Order 2
   - **Expected**:
     ```
     Available Balance: ₱315.00
     Pending Earnings: ₱0.00
     ```

---

## 🧪 **Test Scenario 5: Rejection Flow**

### **Objective**: Test request rejection

### **Steps**:

1. **As Farmer**: Request payout for ₱300

2. **As Admin**:
   - Open request
   - Tap "Reject Request"
   - Enter reason: "Please upload valid ID first"
   - Confirm

3. **Verify**:
   - Request status: "Rejected"
   - Reason visible to farmer

4. **As Farmer**:
   - Check wallet
   - **Expected**:
     - Balance returned: ₱300 available again
     - History shows rejected request with reason
     - Can submit new request

---

## 🧪 **Test Scenario 6: Multiple Payment Methods**

### **Objective**: Test both GCash and Bank Transfer

### **Steps**:

1. **As Farmer**:
   - Setup both payment methods:
     - GCash: 09171234567
     - Bank: BDO, 1234567890, Juan Dela Cruz

2. **Request Payout via Bank**:
   - Amount: ₱500
   - Select: Bank Transfer
   - Verify bank details shown

3. **As Admin**:
   - Review request
   - **Expected to see**:
     ```
     Payment Method: Bank Transfer
     Bank: BDO
     Account Number: 1234567890
     Account Name: Juan Dela Cruz
     ```

4. **Process**: Approve → Mark Completed

---

## 📊 **Expected Results Summary**

### **Payment Method Matrix**:

| Order Payment | Platform Receives? | In Payout Balance? | Farmer Gets Cash? |
|---------------|-------------------|-------------------|------------------|
| GCash         | ✅ Yes            | ✅ Yes            | Via payout       |
| Bank Transfer | ✅ Yes            | ✅ Yes            | Via payout       |
| Credit Card   | ✅ Yes            | ✅ Yes            | Via payout       |
| COD           | ❌ No             | ❌ No             | From buyer directly |
| COP           | ❌ No             | ❌ No             | From buyer directly |

### **Commission Calculation**:

```
Order Total: ₱1,000
Platform Commission (10%): ₱100
Farmer Earning: ₱900

If COD: Farmer gets ₱1,000 from buyer (no payout)
If GCash: Farmer gets ₱900 via payout
```

---

## 🐛 **Common Issues & Solutions**

### **Issue 1**: "Balance shows ₱0 even though I have completed orders"

**Check**:
- Are orders paid via GCash/Bank/Card? (Not COD/COP)
- Are orders status = "completed"?
- Run SQL: `SELECT * FROM farmer_payout_eligible_orders WHERE farmer_id = 'YOUR_ID'`

### **Issue 2**: "Cannot request payout"

**Check**:
- Balance ≥ ₱100?
- No pending request already?
- Payment details setup?

### **Issue 3**: "Balance calculation seems wrong"

**Check**:
- 10% commission being deducted?
- COD/COP orders excluded?
- Already paid out orders excluded?

---

## ✅ **Final Verification Checklist**

Before going live:

- [ ] Database migrations 27 and 28 run successfully
- [ ] Test Scenario 1 passed (payment method filtering)
- [ ] Test Scenario 2 passed (complete flow)
- [ ] Test Scenario 3 passed (minimum validation)
- [ ] Test Scenario 4 passed (pending earnings)
- [ ] Test Scenario 5 passed (rejection flow)
- [ ] Test Scenario 6 passed (multiple methods)
- [ ] Admin can copy payment details
- [ ] Activity logs show all actions
- [ ] Farmers see accurate balance
- [ ] COD/COP orders excluded from balance
- [ ] Notifications work (optional)

---

## 📱 **Quick Test Commands**

### **Check Farmer Balance**:
```sql
SELECT calculate_farmer_available_balance('YOUR_FARMER_ID');
SELECT calculate_farmer_pending_earnings('YOUR_FARMER_ID');
```

### **View Eligible Orders**:
```sql
SELECT * FROM farmer_payout_eligible_orders
WHERE farmer_id = 'YOUR_FARMER_ID';
```

### **View Cash Orders (Excluded)**:
```sql
SELECT * FROM farmer_cash_orders
WHERE farmer_id = 'YOUR_FARMER_ID';
```

### **View All Payout Requests**:
```sql
SELECT * FROM payout_requests
WHERE farmer_id = 'YOUR_FARMER_ID'
ORDER BY created_at DESC;
```

---

## 🎉 **Success Criteria**

System is working correctly if:

✅ COD orders are NOT in farmer balance  
✅ COP orders are NOT in farmer balance  
✅ GCash/Bank/Card orders ARE in farmer balance  
✅ 10% commission is correctly deducted  
✅ Farmers can request payout when balance ≥ ₱100  
✅ Admins can review payment details  
✅ Admins can approve/reject requests  
✅ Complete audit trail is visible  
✅ Balance updates correctly after payout  

---

## 📞 **Need Help?**

If something doesn't work:

1. Check database migrations ran successfully
2. Verify RLS policies enabled
3. Check user roles (buyer/farmer/admin)
4. Review logs in `payout_logs` table
5. Test with small amounts first (₱100-500)

---

**Happy Testing! 🧪✅**
