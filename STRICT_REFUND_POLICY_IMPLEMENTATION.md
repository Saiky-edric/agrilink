# Strict Refund Policy Implementation - Complete

## 📋 Overview

This implementation adds a **strict refund policy** that only allows refunds **before the farmer starts packing (toPack status)**, with **automatic exception handling** for farmer-caused delivery failures.

---

## 🎯 Policy Rules

### **Rule 1: Refunds Only Before Packing**
- ✅ **Allowed**: Orders in `newOrder` or `accepted` status
- 🚫 **Blocked**: Orders in `toPack`, `toDeliver`, `readyForPickup`, `completed`
- **Reason**: Once the farmer starts preparing, inventory is committed and perishable products may be affected

### **Rule 2: Exception for Farmer Fault**
- ✅ **Allowed**: Refunds at any stage if farmer is at fault
- **Triggers**:
  - Delivery deadline exceeded (automatic detection)
  - Manual admin reporting of farmer fault
  - Product not delivered as promised
  - Quality issues (farmer's responsibility)

### **Rule 3: Automatic Fault Detection**
- 🤖 **Automatic**: System marks orders as overdue when delivery deadline passes
- ⏰ **Deadline**: Set to 5 days after farmer accepts order (configurable)
- 🔔 **Notification**: Buyer is notified when refund becomes available

---

## 🗄️ Database Schema Changes

### **New Columns in `orders` Table**

```sql
-- Fault tracking
farmer_fault              BOOLEAN DEFAULT false
fault_reason              TEXT
fault_reported_at         TIMESTAMP WITH TIME ZONE
fault_reported_by         UUID REFERENCES users(id)

-- Deadline tracking
delivery_deadline         TIMESTAMP WITH TIME ZONE
is_overdue                BOOLEAN DEFAULT false
```

### **New Column in `refund_requests` Table**

```sql
eligibility_reason        TEXT CHECK (eligibility_reason IN (
  'before_packing',           -- Order cancelled before farmer started
  'farmer_fault_delay',       -- Farmer delayed delivery
  'farmer_fault_no_delivery', -- Farmer never delivered
  'farmer_fault_quality',     -- Product quality issues
  'farmer_fault_wrong_item',  -- Wrong item delivered
  'admin_override'            -- Admin manually approved
))
```

---

## 🔧 New Functions

### **1. `check_refund_eligibility(p_order_id UUID)`**
Determines if buyer is eligible for refund based on strict rules.

**Returns:**
```json
{
  "eligible": true/false,
  "reason": "Explanation message",
  "eligibility_type": "before_packing" | "farmer_fault_delay" | etc,
  "current_status": "newOrder" | "toPack" | etc,
  "farmer_fault": true/false,
  "is_overdue": true/false
}
```

**Usage:**
```dart
final eligibility = await orderService.checkRefundEligibility(orderId);
if (eligibility['eligible'] == true) {
  // Show refund button
}
```

### **2. `report_farmer_fault(p_order_id UUID, p_fault_reason TEXT, p_reported_by UUID)`**
Marks an order as farmer fault, enabling refund eligibility.

**Usage:**
```dart
await orderService.reportFarmerFault(
  orderId: orderId,
  faultReason: 'Delivery deadline exceeded by 3 days',
  reportedBy: currentUser.id,
);
```

### **3. `mark_overdue_orders()`**
Batch function to automatically mark overdue orders as farmer fault.

**Should be run periodically** (e.g., via cron job or scheduled function):
```sql
-- Run this query periodically (e.g., every hour)
SELECT * FROM mark_overdue_orders();
```

---

## 🔄 Automatic Features

### **Delivery Deadline Setting**
Automatically set when farmer accepts order:

```sql
-- Trigger: set_delivery_deadline()
-- When: farmer_status changes from 'newOrder' to 'accepted'
-- Action: delivery_deadline = NOW() + INTERVAL '5 days'
```

### **Overdue Detection**
When `mark_overdue_orders()` runs:
```sql
-- Finds orders where:
-- 1. NOW() > delivery_deadline
-- 2. Status is toPack, toDeliver, or readyForPickup
-- 3. Not already marked as overdue

-- Actions:
-- 1. Sets is_overdue = true
-- 2. Sets farmer_fault = true
-- 3. Records fault_reason
-- 4. Sends notification to buyer
```

---

## 💻 Frontend Implementation

### **Service Layer Changes**

#### **OrderService**
```dart
// Check eligibility
Future<Map<String, dynamic>> checkRefundEligibility(String orderId)

// Report fault (admin or automatic)
Future<void> reportFarmerFault({
  required String orderId,
  required String faultReason,
  String? reportedBy,
})

// Updated cancelOrder - now checks eligibility first
Future<void> cancelOrder({
  required String orderId,
  String? cancelReason,
})
```

#### **TransactionService**
```dart
// Check eligibility
Future<Map<String, dynamic>> checkRefundEligibility(String orderId)

// Updated createRefundRequest - validates eligibility first
Future<RefundRequestModel> createRefundRequest({
  required String orderId,
  required double amount,
  required String reason,
  String? additionalDetails,
})
```

### **UI Changes**

#### **Order Details Screen**
```dart
// New state variables
Map<String, dynamic>? _refundEligibility;
bool _checkingEligibility = false;

// Checks eligibility on load
await _checkRefundEligibility();

// Updated button visibility logic
bool _canCancelOrder() {
  // Only show cancel button for 'before_packing' scenarios
  return eligible && eligibilityType == 'before_packing';
}

bool _canRequestRefund() {
  // Show refund button for farmer fault scenarios
  return eligible && eligibilityType.startsWith('farmer_fault');
}
```

#### **Enhanced Info Banner**
Shows context-aware messages:
- ✅ **Green**: "Cancellation Available - Farmer hasn't started yet"
- ⚠️ **Orange**: "Refund Available - Delivery Issue Detected"
- 🚫 **Red**: "Cancellation Not Allowed - Farmer has started preparing"

#### **Smart Refund Reasons**
Different reason lists based on eligibility type:

**Regular Cancellation:**
- Changed my mind
- Found better price
- Financial reasons

**Farmer Fault:**
- Delivery taking too long
- Product not delivered on time
- Order never arrived
- Delivery deadline exceeded

---

## 🧪 Testing Scenarios

### **Scenario 1: Normal Cancellation (Before Packing)**
```
1. Buyer places order → Status: newOrder
2. Check eligibility → eligible: true, type: 'before_packing'
3. UI shows "Cancel Order" button
4. Buyer cancels → Order cancelled successfully
```

### **Scenario 2: Blocked Cancellation (After Packing)**
```
1. Order status: toPack
2. Check eligibility → eligible: false, reason: "Farmer has started preparing"
3. UI hides "Cancel Order" button
4. Banner shows: "Cannot cancel - Farmer has started preparing"
```

### **Scenario 3: Farmer Fault - Delayed Delivery**
```
1. Order accepted on Jan 1 → delivery_deadline = Jan 6
2. Current date: Jan 8 → Overdue!
3. System runs mark_overdue_orders()
4. Order marked: is_overdue = true, farmer_fault = true
5. Buyer notified: "Refund now available due to delivery delay"
6. Check eligibility → eligible: true, type: 'farmer_fault_delay'
7. UI shows "Request Refund" button
8. Buyer requests refund → Approved by admin
```

### **Scenario 4: Manual Fault Reporting (Admin)**
```
1. Admin reviews complaint about farmer
2. Admin marks order as farmer fault:
   reportFarmerFault(orderId, "Product quality issues")
3. Buyer notified: "Refund available due to quality issue"
4. Buyer can now request refund despite being in toPack status
```

### **Scenario 5: GCash Payment with Strict Policy**
```
1. GCash order verified → Status: accepted
2. Check eligibility → eligible: true, type: 'before_packing'
3. UI shows "Request Refund" button (not cancel, because payment verified)
4. Buyer requests refund → Admin reviews and approves
5. Money refunded to buyer's GCash
```

---

## 📊 Admin Dashboard Changes

Updated `admin_refund_dashboard` view now includes:
```sql
SELECT
  rr.*,
  o.farmer_fault,           -- NEW
  o.fault_reason,           -- NEW
  o.is_overdue,             -- NEW
  o.delivery_deadline,      -- NEW
  rr.eligibility_reason     -- NEW
FROM refund_requests rr
JOIN orders o ON rr.order_id = o.id
```

Admins can now see:
- Why refund was allowed (eligibility_reason)
- If order was overdue
- Fault details
- Delivery deadlines

---

## 🔔 Notification Flow

### **When Order Becomes Overdue**
```
→ Buyer receives notification:
   "Refund Available"
   "Due to a delivery issue, you are now eligible to request a refund."
```

### **When Farmer Fault Reported**
```
→ Buyer receives notification:
   "Refund Available"
   "Due to [fault_reason], you can now request a refund for your order."
```

### **When Refund Approved**
```
→ Buyer receives notification:
   "Refund Approved"
   "Your refund of ₱350.00 has been approved. Amount will be refunded within 3-5 business days."
```

---

## 🚀 Deployment Steps

### **1. Run Database Migration**
```bash
# Connect to Supabase SQL Editor
# Run: supabase_setup/41_add_strict_refund_policy_with_fault_detection.sql
```

### **2. Set Up Periodic Job (Optional but Recommended)**
```sql
-- Option A: Supabase Edge Function (scheduled)
-- Create edge function that calls mark_overdue_orders() every hour

-- Option B: External cron job
-- Run this query hourly via API or pg_cron
SELECT * FROM mark_overdue_orders();
```

### **3. Deploy Flutter App**
```bash
flutter build apk --release
# or
flutter build ios --release
```

### **4. Test with Real Scenarios**
- Create test orders
- Advance time (manually update delivery_deadline in DB)
- Run mark_overdue_orders()
- Verify notifications sent
- Test refund request flow

---

## 📈 Benefits

### **For Buyers**
- ✅ Clear refund policy - know when you can cancel
- ✅ Automatic protection from farmer delays
- ✅ Fair system - can get refund if farmer is at fault
- ✅ Transparent process - see why refund is/isn't allowed

### **For Farmers**
- ✅ Protected from frivolous cancellations after starting work
- ✅ Clear expectations - deliver on time or refund
- ✅ Fair accountability - only penalized for actual faults
- ✅ Inventory protection - buyers can't cancel after packing starts

### **For Platform**
- ✅ Reduced disputes - clear automated rules
- ✅ Better accountability - automatic fault tracking
- ✅ Trust building - fair to both parties
- ✅ Audit trail - complete fault history

---

## 🛠️ Configuration Options

### **Adjust Delivery Deadline**
In `set_delivery_deadline()` function:
```sql
-- Current: 5 days
NEW.delivery_deadline := NOW() + INTERVAL '5 days';

-- Change to 3 days:
NEW.delivery_deadline := NOW() + INTERVAL '3 days';

-- Or make it dynamic based on delivery method:
NEW.delivery_deadline := CASE 
  WHEN NEW.delivery_method = 'pickup' THEN NOW() + INTERVAL '2 days'
  WHEN NEW.delivery_method = 'delivery' THEN NOW() + INTERVAL '5 days'
END;
```

### **Customize Fault Reasons**
Add more eligibility types in schema:
```sql
ALTER TABLE refund_requests 
DROP CONSTRAINT IF EXISTS refund_requests_eligibility_reason_check;

ALTER TABLE refund_requests
ADD CONSTRAINT refund_requests_eligibility_reason_check
CHECK (eligibility_reason IN (
  'before_packing',
  'farmer_fault_delay',
  'farmer_fault_no_delivery',
  'farmer_fault_quality',
  'farmer_fault_wrong_item',
  'farmer_fault_custom',      -- NEW
  'admin_override'
));
```

---

## 📝 Summary

| Feature | Status |
|---------|--------|
| Database schema | ✅ Complete |
| Eligibility checking | ✅ Complete |
| Automatic fault detection | ✅ Complete |
| Service layer integration | ✅ Complete |
| UI updates | ✅ Complete |
| Admin dashboard | ✅ Complete |
| Notifications | ✅ Complete |
| Documentation | ✅ Complete |

**Status**: ✅ **Production Ready**  
**Last Updated**: January 29, 2026  
**Version**: 1.0.0

---

## 🔗 Related Files

- Database: `supabase_setup/41_add_strict_refund_policy_with_fault_detection.sql`
- Service: `lib/core/services/order_service.dart`
- Service: `lib/core/services/transaction_service.dart`
- UI: `lib/features/buyer/screens/order_details_screen.dart`
- Admin: `lib/features/admin/screens/admin_refund_management_screen.dart`
