# Order Cancellation & Refund Flow - Complete Documentation

## Overview
This document explains how order cancellation and refunds work in your app, with special focus on GCash payment handling.

---

## 🔄 Order Cancellation Flow

### **When Can Orders Be Cancelled?**

**Location**: `lib/features/buyer/screens/order_details_screen.dart` - `_canCancelOrder()`

```dart
bool _canCancelOrder() {
  if (_order == null) return false;
  
  // OPTION B: Block cancellation for GCash orders with payment proof
  if (_order!.paymentMethod?.toLowerCase() == 'gcash') {
    // Case 1: Payment verified → Must use refund process
    if (_order!.paymentVerified == true) {
      return false; // Force "Request Refund" for verified payments
    }
    
    // Case 2: Payment proof uploaded but not verified yet → Block cancel
    if (_order!.paymentScreenshotUrl != null || _order!.paymentReference != null) {
      return false; // Wait for verification, then use refund process
    }
    
    // Case 3: No payment proof uploaded yet → Allow cancel
    return _order!.farmerStatus == FarmerOrderStatus.newOrder ||
           _order!.farmerStatus == FarmerOrderStatus.accepted;
  }
  
  // Allow cancel for COD/COP orders (no prepayment involved)
  return _order!.farmerStatus == FarmerOrderStatus.newOrder ||
         _order!.farmerStatus == FarmerOrderStatus.accepted;
}
```

---

## 📊 Decision Matrix: Cancel vs Refund

### **Payment Method: Cash on Delivery (COD) / Cash on Pickup (COP)**

| Order Status | Can Cancel? | Can Refund? | Action |
|--------------|-------------|-------------|--------|
| `newOrder` (just placed) | ✅ Yes | ❌ No | Direct cancellation |
| `accepted` (farmer confirmed) | ✅ Yes | ❌ No | Direct cancellation |
| `toPack` (preparing) | ❌ No | ❌ No | Contact farmer via chat |
| `toDeliver` (shipped) | ❌ No | ❌ No | Cannot cancel |
| `readyForPickup` | ❌ No | ❌ No | Cannot cancel |
| `completed` | ❌ No | ❌ No | Cannot cancel |

**Logic**: No prepayment, so simple cancellation allowed in early stages.

---

### **Payment Method: GCash (Prepaid)**

#### **Scenario 1: No Payment Proof Uploaded**
| Order Status | Can Cancel? | Can Refund? | Action |
|--------------|-------------|-------------|--------|
| `newOrder` | ✅ Yes | ❌ No | Direct cancellation (no money transferred) |
| `accepted` | ✅ Yes | ❌ No | Direct cancellation (no money transferred) |
| `toPack` | ❌ No | ❌ No | Contact farmer |
| `toDeliver` | ❌ No | ❌ No | Cannot cancel |

**Logic**: User created GCash order but never uploaded proof = no money involved yet.

---

#### **Scenario 2: Payment Proof Uploaded, Not Verified**
| Order Status | Can Cancel? | Can Refund? | Reason |
|--------------|-------------|-------------|--------|
| `newOrder` | ❌ No | ❌ No | Wait for verification |
| `accepted` | ❌ No | ❌ No | Wait for verification |

**Logic**: Money might already be with farmer. Must wait for admin verification before refund process.

**Info Banner Shown**:
```
⚠️ Your payment is being verified. Please wait for verification 
   to complete before requesting a cancellation. This protects 
   your money from being lost.
```

---

#### **Scenario 3: Payment Verified**
| Order Status | Can Cancel? | Can Refund? | Action |
|--------------|-------------|-------------|--------|
| `newOrder` | ❌ No | ✅ Yes | Request refund |
| `accepted` | ❌ No | ✅ Yes | Request refund |
| `toPack` | ❌ No | ✅ Yes | Request refund |
| `toDeliver` | ❌ No | ✅ Yes | Request refund |
| `readyForPickup` | ❌ No | ✅ Yes | Request refund |
| `completed` | ❌ No | ❌ No | Order delivered |
| `cancelled` | ❌ No | ❌ No | Already cancelled |

**Logic**: Payment confirmed and farmer has money. Formal refund process required.

**Info Banner Shown**:
```
ℹ️ Since your payment is verified, please use "Request Refund" 
   below to cancel this order. Our admin will process your 
   request within 24 hours.
```

---

## 🔄 Cancellation Process

### **Direct Cancellation (COD/COP or GCash without proof)**

**Location**: `lib/core/services/order_service.dart` - `cancelOrder()`

**Flow**:
```
1. User clicks "Cancel Order"
   ↓
2. Select cancellation reason (required)
   ↓
3. Confirm "Cancel Order" button
   ↓
4. System checks:
   - Current status is newOrder or accepted? ✓
   - Payment method is not verified GCash? ✓
   ↓
5. Update database:
   - farmer_status = 'cancelled'
   - buyer_status = 'cancelled'
   - special_instructions = 'CANCELLED: {reason}'
   ↓
6. Send notification to farmer
   ↓
7. Show success message
```

**Database Changes**:
```sql
UPDATE orders SET
  farmer_status = 'cancelled',
  buyer_status = 'cancelled',
  cancelled_at = NOW(),
  updated_at = NOW()
WHERE id = {order_id};
```

**Stock Impact**: ❌ No stock deduction (order cancelled before processing)

---

## 💰 Refund Request Process

### **When Can Refunds Be Requested?**

**Location**: `lib/features/buyer/screens/order_details_screen.dart` - `_canRequestRefund()`

```dart
bool _canRequestRefund() {
  if (_order == null) return false;
  
  // Can request refund if:
  return _order!.paymentMethod?.toLowerCase() == 'gcash' &&  // 1. GCash payment
         _order!.paymentVerified == true &&                   // 2. Payment verified
         _order!.farmerStatus != FarmerOrderStatus.completed && // 3. Not completed
         _order!.farmerStatus != FarmerOrderStatus.cancelled && // 4. Not cancelled
         !_order!.refundRequested;                            // 5. No existing refund
}
```

---

### **Refund Request Flow**

**Location**: `lib/features/buyer/screens/order_details_screen.dart` - `_requestRefund()`

**Step-by-Step**:
```
1. User clicks "Request Refund"
   ↓
2. Dialog appears with:
   - Refund amount display
   - Reason dropdown (required)
   - Additional details (optional)
   ↓
3. User selects reason:
   - Order taking too long to process
   - Need to cancel due to changed plans
   - Found product elsewhere
   - Financial reasons
   - Farmer not responding
   - Product quality concerns
   - Other
   ↓
4. User clicks "Submit Request"
   ↓
5. System calls TransactionService.createRefundRequest()
   ↓
6. Database records:
   - Creates entry in refund_requests table
   - Sets order.refund_requested = true
   - Status = 'pending'
   ↓
7. Admin notification sent
   ↓
8. User sees refund status card
```

**Refund Request Data Structure**:
```dart
{
  'order_id': order.id,
  'user_id': buyer.id,
  'transaction_id': transaction?.id, // If exists
  'amount': order.totalAmount,
  'reason': selectedReason,
  'additional_details': userInput,
  'status': 'pending',
  'created_at': now,
}
```

---

## 👨‍💼 Admin Refund Processing

### **Refund Statuses**

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `pending` | 🟡 Awaiting admin review | Admin reviews and decides |
| `approved` | 🟢 Refund approved | Admin processes payment |
| `rejected` | 🔴 Refund denied | Buyer notified with reason |
| `processing` | 🔵 Payment being processed | Money being transferred |
| `completed` | ✅ Refund completed | Money returned to buyer |

---

### **Admin Refund Dashboard**

**Location**: `lib/features/admin/screens/admin_refund_management_screen.dart`

**Admin Actions**:
1. **Review Request**
   - See order details
   - View payment proof
   - Check buyer's reason

2. **Approve Refund**
   - Set status = 'approved'
   - Add admin notes
   - Notify buyer

3. **Reject Refund**
   - Set status = 'rejected'
   - Provide rejection reason
   - Notify buyer

4. **Process Payment**
   - Manual GCash transfer to buyer
   - Upload transaction proof
   - Set status = 'completed'
   - Mark order as cancelled

---

## 📱 Buyer UI Flow

### **Scenario A: COD Order Cancellation**
```
Order Details Screen
├─ Order #ABC123
├─ Status: Order Received
├─ Payment: Cash on Delivery
├─ Items: [Fresh Tomatoes, ₱100]
│
├─ [Contact Farmer] button
└─ [Cancel Order] button ← AVAILABLE
    │
    └─ Click → Reason Dialog
        └─ Select Reason → Confirm
            └─ Order Cancelled ✓
```

---

### **Scenario B: GCash - No Payment Proof**
```
Order Details Screen
├─ Order #XYZ789
├─ Status: Order Received
├─ Payment: GCash
├─ Payment Status: Payment Proof Required
│
├─ [Upload Payment Proof] button
├─ [Contact Farmer] button
└─ [Cancel Order] button ← AVAILABLE (no money transferred yet)
```

---

### **Scenario C: GCash - Proof Uploaded, Not Verified**
```
Order Details Screen
├─ Order #DEF456
├─ Status: Order Accepted
├─ Payment: GCash
├─ Payment Status: 🟡 Pending Verification
│
├─ ⚠️ Info Banner:
│   "Your payment is being verified. Please wait for 
│    verification to complete before requesting cancellation."
│
├─ [Contact Farmer] button
└─ [Cancel Order] button ← HIDDEN (protection against loss)
```

---

### **Scenario D: GCash - Payment Verified**
```
Order Details Screen
├─ Order #GHI123
├─ Status: Being Packed
├─ Payment: GCash
├─ Payment Status: ✅ Verified (verified on Jan 29, 2026)
│
├─ ℹ️ Info Banner:
│   "Since your payment is verified, please use 
│    'Request Refund' below to cancel this order."
│
├─ [Contact Farmer] button
├─ [Cancel Order] button ← HIDDEN
└─ [Request Refund] button ← AVAILABLE
    │
    └─ Click → Refund Dialog
        ├─ Amount: ₱350.00
        ├─ Reason: [Dropdown]
        ├─ Details: [Text input]
        └─ Submit → Creates refund_requests entry
            │
            └─ Refund Status Card Appears:
                ├─ Status: 🟡 PENDING
                ├─ Amount: ₱350.00
                ├─ Reason: Order taking too long
                └─ "Refunds processed within 3-5 business days"
```

---

## 🗄️ Database Tables

### **orders Table - Refund Fields**
```sql
payment_method          text        -- 'cod', 'cop', 'gcash'
payment_verified        boolean     -- true if admin verified
payment_verified_at     timestamp   -- when verified
payment_verified_by     uuid        -- admin who verified
payment_screenshot_url  text        -- proof image
payment_reference       text        -- reference number
refund_requested        boolean     -- true if refund requested
refund_status           text        -- 'none', 'pending', 'approved', 'rejected', 'completed'
refunded_at             timestamp   -- when refund completed
refunded_amount         numeric     -- amount refunded
```

### **refund_requests Table**
```sql
CREATE TABLE refund_requests (
  id                    uuid PRIMARY KEY,
  order_id              uuid REFERENCES orders(id),
  user_id               uuid REFERENCES users(id),
  transaction_id        uuid REFERENCES transactions(id),
  amount                numeric NOT NULL,
  reason                text NOT NULL,
  additional_details    text,
  status                text DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'processing'
  created_at            timestamp DEFAULT now(),
  processed_at          timestamp,
  processed_by          uuid REFERENCES users(id),
  admin_notes           text
);
```

---

## ⚠️ Important Business Rules

### **1. No Direct Cancellation for Verified GCash Payments**
**Reason**: Money already transferred to farmer. Formal refund process ensures:
- Proper accounting
- Admin oversight
- Buyer protection
- Audit trail

### **2. Block Cancellation During Verification**
**Reason**: Unknown if money actually transferred. Protection against:
- Buyer loses money but order cancelled
- Farmer keeps money but no order
- Disputes and conflicts

### **3. Late-Stage Cancellation Not Allowed**
**Reason**: Once farmer starts packing (`toPack` status):
- Inventory already committed
- Farmer invested time/resources
- Products may be perishable
- Alternative: Request refund (admin reviews case)

### **4. COD/COP Flexible Cancellation**
**Reason**: No prepayment means:
- No money to refund
- Lower friction
- Simple cancellation process
- Buyer-friendly

---

## 🔔 Notification Flow

### **Direct Cancellation (COD/COP)**
```
Buyer cancels order
    ↓
Farmer receives notification:
    "🔴 Order Cancelled"
    "A buyer has cancelled their order. 
     Reason: Changed my mind"
```

### **Refund Request (GCash)**
```
Buyer requests refund
    ↓
Admin receives notification:
    "💰 New Refund Request"
    "Buyer requesting ₱350.00 refund for Order #ABC123"
    ↓
Admin approves
    ↓
Buyer receives notification:
    "✅ Refund Approved"
    "Your refund of ₱350.00 has been approved and 
     will be processed within 3-5 business days"
    ↓
Admin processes payment
    ↓
Buyer receives notification:
    "💵 Refund Completed"
    "₱350.00 has been transferred to your GCash"
```

---

## 📊 Complete Flow Diagram

```
ORDER PLACED
    ↓
┌───────────────────────────────────────┐
│  Payment Method?                      │
└───────┬───────────────────┬───────────┘
        │                   │
    COD/COP             GCASH
        │                   │
        │         ┌─────────┴──────────┐
        │         │ Upload Proof?      │
        │         └──┬───────────┬─────┘
        │            │           │
        │           NO         YES
        │            │           │
        ↓            ↓           ↓
    [Status]    [Status]   [Verification]
        │            │           │
    newOrder    newOrder    ┌────┴────┐
        │            │       │Verified?│
    accepted    accepted    └─┬─────┬─┘
        │            │         │     │
        ↓            ↓        NO   YES
   [CANCEL]     [CANCEL]      │     │
   ALLOWED      ALLOWED    [WAIT] [REFUND]
                                    │
                                    ↓
                              [Admin Reviews]
                                    │
                          ┌─────────┴──────────┐
                          │                    │
                      APPROVED             REJECTED
                          │                    │
                  [Process Payment]      [Notify Buyer]
                          │
                          ↓
                    [COMPLETED]
```

---

## ✅ Summary

### **Key Points**

1. **COD/COP Orders**:
   - ✅ Simple cancellation in early stages
   - ❌ No refund process needed
   - 🚫 Cannot cancel after `toPack`

2. **GCash Orders - No Proof**:
   - ✅ Can cancel (no money involved)
   - ❌ No refund needed

3. **GCash Orders - Unverified Proof**:
   - 🚫 Cannot cancel (protection)
   - ⏳ Must wait for verification
   - ℹ️ Clear info banner shown

4. **GCash Orders - Verified**:
   - 🚫 Cannot cancel directly
   - ✅ Must request refund
   - 👨‍💼 Admin reviews and processes
   - ⏱️ 3-5 business days processing

### **User Protection Mechanisms**
- 🛡️ Block cancel during verification (prevents money loss)
- 🛡️ Require refund for verified payments (proper process)
- 🛡️ Admin oversight on all refunds (fraud prevention)
- 🛡️ Audit trail via refund_requests table

---

**Status**: ✅ Complete Implementation  
**Last Updated**: January 29, 2026  
**Version**: 1.0.0
