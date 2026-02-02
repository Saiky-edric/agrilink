# Buyer to Admin Reporting Flow - Complete Guide

## 📱 How Buyers Report Order Issues

### **Option 1: Report Button in Order Details**

```
1. Buyer opens order details
   ↓
2. Clicks the "⋮" menu (three dots) in top-right
   ↓
3. Selects "Report Issue"
   ↓
4. Dialog opens with order-specific reasons:
   - Product never delivered
   - Delivery is very late
   - Product quality issues (rotten/damaged)
   - Wrong items delivered
   - Farmer not responding
   - Incomplete order
   - Payment issue
   - Fraudulent transaction
   - Other
   ↓
5. Buyer selects reason
   ↓
6. Buyer adds detailed description
   ↓
7. Buyer submits report
   ↓
8. ✅ Success message: "Report submitted successfully"
   ↓
9. Special notice shown: 
   "⚡ Priority Report: Order issues are reviewed by admins 
   within 24 hours. For delivery failures, a refund may be granted."
```

---

## 👨‍💼 **Admin Receives the Report**

### **Step 1: Admin Notification**
```
Admin sees new report in:
- Admin Dashboard → "Content Moderation" card (with badge)
- Shows unresolved reports count
```

### **Step 2: Admin Reviews Report**
```
1. Admin clicks "Content Moderation"
   ↓
2. Sees list of all reports
   ↓
3. Filters by "Order" type
   ↓
4. Clicks on buyer's report
   ↓
5. Sees full details:
   - Reporter: [Buyer Name]
   - Order ID: #ABC123
   - Reason: "Product never delivered"
   - Description: "Ordered 3 days ago, still not received..."
   - Status: Pending
   ↓
6. Admin investigates:
   - Checks order status
   - Contacts farmer if needed
   - Reviews delivery timeline
```

### **Step 3: Admin Takes Action**

**Option A: Mark as Farmer Fault**
```
1. Admin clicks "Order Management" from dashboard
   ↓
2. Finds the reported order
   ↓
3. Clicks "Report Farmer Fault"
   ↓
4. Selects matching reason from report
   ↓
5. Adds admin notes
   ↓
6. Submits → Order marked as farmer_fault = true
   ↓
7. Buyer receives notification: "Refund Available"
   ↓
8. Buyer can now request refund
```

**Option B: Dismiss Report (No Fault)**
```
1. Admin reviews and finds order is on track
   ↓
2. Marks report as "Dismissed"
   ↓
3. Adds resolution notes: "Order is still within delivery window"
   ↓
4. Buyer receives notification: "Your report has been reviewed"
```

---

## 🔄 **Complete Flow Diagram**

```
BUYER SIDE                  ADMIN SIDE                  SYSTEM ACTION
─────────────────────────────────────────────────────────────────────

Order Issue
    ↓
Reports via UI
    ↓                      
Report Created          →  Notification sent
    ↓                          ↓
Waits for review           Admin Dashboard
                               ↓
                          Views Report
                               ↓
                          Investigates
                               ↓
                     ┌─────────┴─────────┐
                     ↓                   ↓
              Farmer Fault          No Fault Found
                     ↓                   ↓
            Reports Fault          Dismisses Report
                     ↓                   ↓
Notification: "Refund Available"    Notified
    ↓
Requests Refund
    ↓                          ↓
Refund Request            Admin Approves
    ↓                          ↓
✅ Refunded                ✅ Case Closed
```

---

## 🎯 **Critical Order Issues (Auto-Escalated)**

These reports are flagged as **HIGH PRIORITY**:

1. **"Product never delivered"**
   - Automatically escalated to admin
   - Shown with 🔴 red badge
   
2. **"Delivery is very late"**
   - Admin checks against delivery deadline
   - May auto-mark as overdue if deadline passed

3. **"Product quality issues"**
   - Priority review within 24 hours
   - May trigger immediate farmer fault if photos provided

4. **"Farmer not responding"**
   - Admin attempts to contact farmer
   - 24-hour response deadline

---

## 📊 **Admin Dashboard View**

### **Content Moderation Card**
```
┌─────────────────────────────────┐
│ 🚩 Content Moderation           │
│                                 │
│ Review flagged content          │
│ and reports                     │
│                                 │
│ [5] NEW →                       │
└─────────────────────────────────┘
```

### **Reports List (Filtered by Orders)**
```
┌────────────────────────────────────────┐
│ Order Reports (Pending)                │
├────────────────────────────────────────┤
│ 🔴 Order #A1B2C3                       │
│    Reporter: John Doe                  │
│    Reason: Product never delivered     │
│    Status: PENDING                     │
│    Created: 2 hours ago                │
│    [View Details] →                    │
├────────────────────────────────────────┤
│ 🟠 Order #D4E5F6                       │
│    Reporter: Jane Smith                │
│    Reason: Delivery is very late       │
│    Status: INVESTIGATING               │
│    Created: 5 hours ago                │
│    [View Details] →                    │
└────────────────────────────────────────┘
```

---

## 🛠️ **Admin Tools Available**

### **In Report Details Screen:**
- ✅ Mark as "Investigating"
- ✅ Mark as "Resolved"
- ✅ Mark as "Dismissed"
- ✅ Add admin notes
- ✅ Link to order details
- ✅ Contact reporter
- ✅ Contact farmer

### **In Order Management Screen:**
- ✅ Report farmer fault
- ✅ View all order details
- ✅ See buyer and farmer info
- ✅ Check delivery timeline
- ✅ View payment status

---

## 💡 **Best Practices for Admins**

### **Response Time Guidelines:**
- 🔴 **Critical** (never delivered): < 4 hours
- 🟠 **High** (very late, quality issues): < 24 hours
- 🟡 **Medium** (unresponsive farmer): < 48 hours
- 🟢 **Low** (general complaints): < 72 hours

### **Decision Making:**

**Grant Refund (Farmer Fault) When:**
- ✅ Delivery deadline exceeded by 2+ days
- ✅ Product quality clearly compromised (with evidence)
- ✅ Wrong items delivered (confirmed)
- ✅ Farmer admits fault
- ✅ Farmer not responding after 48 hours

**Dismiss Report When:**
- ❌ Order still within delivery window
- ❌ Buyer expectations unrealistic
- ❌ Issue already resolved
- ❌ Insufficient evidence
- ❌ Buyer's fault (wrong address, etc.)

---

## 📝 **Example Admin Response Templates**

### **Farmer Fault Confirmed:**
```
"Thank you for reporting this issue. After investigation, we've 
confirmed that the delivery failure was the farmer's responsibility. 
Your order has been marked for refund eligibility. You can now 
request a refund from your order details page. The refund will be 
processed within 3-5 business days after approval."
```

### **No Fault Found:**
```
"Thank you for your report. After reviewing your order, we found 
that it is still within the expected delivery timeframe. The farmer 
has confirmed shipment and provided a tracking number. Please allow 
1-2 more business days for delivery. If you still don't receive 
your order by [date], please report again."
```

### **Need More Information:**
```
"Thank you for your report. To help us investigate further, could 
you please provide:
- Photos of the product condition
- Any communication with the farmer
- Delivery attempt evidence

You can reply via support chat or update your report with these details."
```

---

## 🔔 **Notification Flow**

### **To Buyer:**
1. **Report Submitted**: "Your report has been submitted. We'll review it within 24 hours."
2. **Under Investigation**: "Your report is being reviewed by our admin team."
3. **Fault Confirmed**: "Refund available! You can now request a refund for your order."
4. **Resolved**: "Your report has been resolved. Check admin notes for details."
5. **Dismissed**: "Your report has been reviewed. [Reason provided]"

### **To Farmer:**
1. **Report Filed**: "A buyer has reported an issue with order #ABC123"
2. **Fault Reported**: "Order #ABC123 marked as delivery failure. Please explain."
3. **Resolution Required**: "Please respond to the issue within 24 hours."

---

## ⚡ **Quick Action Guide for Common Issues**

| Issue Reported | Admin Action | Farmer Fault? | Refund? |
|----------------|--------------|---------------|---------|
| Never delivered (past deadline) | Report farmer fault | ✅ Yes | ✅ Yes |
| Late but within window | Dismiss with explanation | ❌ No | ❌ No |
| Quality issues with photos | Report farmer fault | ✅ Yes | ✅ Yes |
| Wrong items | Report farmer fault | ✅ Yes | ✅ Yes |
| Farmer unresponsive 48h+ | Report farmer fault | ✅ Yes | ✅ Yes |
| Buyer changed mind | Dismiss | ❌ No | ❌ No |

---

## 📱 **Buyer Experience Summary**

### **Easy Reporting:**
✅ One-click "Report Issue" button  
✅ Clear, predefined reasons  
✅ Add photos and details  
✅ Instant confirmation  

### **Transparent Process:**
✅ Status updates via notifications  
✅ 24-hour review guarantee  
✅ Clear refund eligibility  
✅ Admin notes visible  

### **Fair Protection:**
✅ Automated fault detection (overdue orders)  
✅ Manual reporting for quality issues  
✅ Admin oversight on all decisions  
✅ No direct conflict with farmer  

---

## 🎯 **Current Implementation Status**

| Feature | Status |
|---------|--------|
| Buyer report button | ✅ Complete |
| Order-specific reasons | ✅ Enhanced |
| Priority notice | ✅ Added |
| Admin report dashboard | ✅ Complete |
| Admin order management | ✅ Complete |
| Farmer fault reporting | ✅ Complete |
| Automatic notifications | ✅ Complete |
| Refund eligibility check | ✅ Complete |

---

## 🚀 **Ready to Use!**

Everything is **fully functional** right now:

1. ✅ Buyers can report issues via UI
2. ✅ Admins see reports in dashboard
3. ✅ Admins can mark farmer faults
4. ✅ System automatically enables refunds
5. ✅ All parties get notifications

**No additional setup needed!** The flow works end-to-end.

---

**Last Updated**: January 29, 2026  
**Version**: 1.0.0
