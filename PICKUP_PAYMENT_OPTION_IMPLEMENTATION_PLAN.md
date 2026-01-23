# 🚚 Pick-up Payment Option - Implementation Plan

## 📋 Overview

**Feature**: Add "Pick-up" delivery option alongside existing "Cash on Delivery" for buyers who want to pick up products directly from the farmer's location, eliminating delivery fees.

**Business Value**:
- Gives buyers flexibility to save on delivery fees
- Helps farmers who cannot deliver
- Reduces logistical complexity for small orders
- Builds direct farmer-buyer relationships
- Common in local marketplace apps (like Facebook Marketplace, OLX)

---

## 🎯 User Stories

### **As a Buyer:**
- I want to select "Pick-up" during checkout so I can save on delivery fees
- I want to see the farmer's pick-up location/address before confirming
- I want to coordinate pick-up time with the farmer
- I want clear instructions on where to pick up my order

### **As a Farmer:**
- I want to enable/disable pick-up option for my store
- I want to set my pick-up location (farm address, market stall, etc.)
- I want to set available pick-up hours/days
- I want to be notified when buyers choose pick-up
- I want to mark orders as "Ready for Pick-up"

### **As Admin:**
- I want to see pick-up vs delivery order statistics
- I want to moderate pick-up locations if needed

---

## 🗄️ Database Schema Changes

### **1. Add `delivery_method` to orders table**
```sql
ALTER TABLE orders 
ADD COLUMN delivery_method VARCHAR(20) DEFAULT 'delivery' CHECK (delivery_method IN ('delivery', 'pickup'));

-- Add index for filtering
CREATE INDEX idx_orders_delivery_method ON orders(delivery_method);
```

### **2. Add pick-up settings to users table (farmer profile)**
```sql
ALTER TABLE users 
ADD COLUMN pickup_enabled BOOLEAN DEFAULT false,
ADD COLUMN pickup_address TEXT,
ADD COLUMN pickup_instructions TEXT,
ADD COLUMN pickup_hours TEXT; -- JSON string: {"monday":"9AM-5PM", "tuesday":"9AM-5PM", ...}

-- Index for filtering farmers with pickup enabled
CREATE INDEX idx_users_pickup_enabled ON users(pickup_enabled) WHERE pickup_enabled = true;
```

### **3. Optional: Create dedicated pickup_locations table (for farmers with multiple locations)**
```sql
CREATE TABLE pickup_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  location_name VARCHAR(100) NOT NULL, -- e.g., "Main Farm", "Saturday Market Stall"
  address TEXT NOT NULL,
  municipality VARCHAR(100),
  barangay VARCHAR(100),
  instructions TEXT,
  available_days TEXT[], -- e.g., ['monday', 'tuesday', 'saturday']
  available_hours VARCHAR(50), -- e.g., "9:00 AM - 5:00 PM"
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(farmer_id, location_name)
);

CREATE INDEX idx_pickup_locations_farmer ON pickup_locations(farmer_id);
```

---

## 🎨 UI/UX Design

### **1. Checkout Screen - Delivery Method Selection**

**Location**: Between "Delivery Address" and "Payment Method" cards

```
┌─────────────────────────────────────────────┐
│  📍 Delivery Address                        │
│  Juan dela Cruz                             │
│  Brgy. San Vicente, Bayugan City            │
│  Contact: 09123456789                       │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  🚚 Delivery Method                         │
│                                              │
│  ○ Home Delivery         ₱120.00            │
│    Standard delivery to your address        │
│                                              │
│  ● Pick-up                  FREE            │
│    Pick up from farmer's location           │
│                                              │
│  📍 Pick-up Location:                       │
│  Main Farm, Brgy. Tagubay, Bayugan City    │
│  Available: Mon-Sat, 9AM-5PM                │
│                                              │
│  ℹ️ Farmer will notify when ready for pickup│
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  💳 Payment Method                          │
│  ● Cash on Pick-up                          │
└─────────────────────────────────────────────┘
```

**Behavior**:
- Radio buttons for "Home Delivery" vs "Pick-up"
- If "Pick-up" selected:
  - Hide delivery address (still save for user profile)
  - Show farmer's pick-up location
  - Delivery fee becomes ₱0.00
  - Change "Cash on Delivery" to "Cash on Pick-up"
- If farmer has multiple pick-up locations, show dropdown selector

### **2. Farmer Profile/Store Screen**

**Add Pick-up Badge:**
```
┌─────────────────────────────────────────────┐
│  🌾 Juan's Organic Farm                     │
│  ⭐ 4.8 (120 reviews)                       │
│  🚚 Free Pick-up Available                  │ ← NEW BADGE
│  📍 Brgy. Tagubay, Bayugan City            │
└─────────────────────────────────────────────┘
```

### **3. Order Details Screen**

**For Pick-up Orders:**
```
┌─────────────────────────────────────────────┐
│  Order #AG-2025-00123                       │
│  Status: Ready for Pick-up                  │
│                                              │
│  🚶 PICK-UP ORDER                           │
│                                              │
│  📍 Pick-up Location:                       │
│  Main Farm, Brgy. Tagubay, Bayugan City    │
│  Contact: Juan dela Cruz - 09123456789      │
│                                              │
│  ⏰ Available Hours:                        │
│  Mon-Sat: 9:00 AM - 5:00 PM                │
│                                              │
│  📝 Pick-up Instructions:                   │
│  Enter through main gate, farm office      │
│  is on the right. Ring bell if closed.      │
│                                              │
│  [🗺️ Get Directions]  [📞 Call Farmer]    │
└─────────────────────────────────────────────┘
```

### **4. Farmer Store Settings Screen**

**New Section: Pick-up Settings**
```
┌─────────────────────────────────────────────┐
│  🚚 Pick-up Settings                        │
│                                              │
│  [✓] Enable pick-up for my store           │
│                                              │
│  📍 Pick-up Address:                        │
│  ┌─────────────────────────────────────┐  │
│  │ Main Farm, Brgy. Tagubay            │  │
│  └─────────────────────────────────────┘  │
│                                              │
│  ⏰ Available Days:                         │
│  [✓] Mon [✓] Tue [✓] Wed [✓] Thu          │
│  [✓] Fri [✓] Sat [ ] Sun                   │
│                                              │
│  ⏰ Pick-up Hours:                          │
│  ┌──────────┐  to  ┌──────────┐           │
│  │ 9:00 AM  │      │ 5:00 PM  │           │
│  └──────────┘      └──────────┘           │
│                                              │
│  📝 Pick-up Instructions:                   │
│  ┌─────────────────────────────────────┐  │
│  │ Enter through main gate...          │  │
│  │                                      │  │
│  └─────────────────────────────────────┘  │
│                                              │
│  [Save Settings]                            │
└─────────────────────────────────────────────┘
```

---

## 🔄 Order Flow Changes

### **Current Flow (Delivery Only):**
```
1. Buyer places order → "pending"
2. Farmer accepts → "accepted"
3. Farmer prepares → "toPack"
4. Farmer delivers → "toDeliver"
5. Buyer receives → "completed"
```

### **New Flow (Pick-up Option):**
```
1. Buyer places order with "pickup" → "pending"
2. Farmer accepts → "accepted"
3. Farmer prepares → "toPack"
4. Farmer marks ready → "readyForPickup" (NEW STATUS)
5. Buyer picks up → "completed"
```

**New Order Status**:
- Add `readyForPickup` to `FarmerOrderStatus` enum
- Display as "Ready for Pick-up" in UI

---

## 📱 Feature Components

### **Frontend Changes**

#### **1. Checkout Screen (`checkout_screen.dart`)**
```dart
enum DeliveryMethod { delivery, pickup }

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryMethod _deliveryMethod = DeliveryMethod.delivery;
  Map<String, dynamic>? _pickupLocation;
  
  double get _deliveryFee {
    if (_deliveryMethod == DeliveryMethod.pickup) {
      return 0.0; // No fee for pickup
    }
    // ... existing delivery fee calculation
  }
  
  Widget _buildDeliveryMethodCard() {
    // Radio buttons for delivery vs pickup
    // Show pickup location details if pickup selected
  }
}
```

#### **2. Order Model (`order_model.dart`)**
```dart
class OrderModel {
  // ... existing fields
  final String deliveryMethod; // 'delivery' or 'pickup'
  final String? pickupLocation;
  final String? pickupInstructions;
  
  // Add to copyWith, fromJson, toJson
}
```

#### **3. Farmer Store Settings Screen** (NEW)
```dart
// lib/features/farmer/screens/pickup_settings_screen.dart
class PickupSettingsScreen extends StatefulWidget {
  // Form for configuring pickup options
  // - Enable/disable toggle
  // - Address input
  // - Day checkboxes
  // - Time pickers
  // - Instructions text area
}
```

#### **4. Order Service (`order_service.dart`)**
```dart
class OrderService {
  Future<String> createOrder({
    required String buyerId,
    required String farmerId,
    required List<CartItemModel> items,
    String? deliveryAddress,
    required String paymentMethod,
    String? specialInstructions,
    required String deliveryMethod, // NEW
    String? pickupLocationId, // NEW (optional)
  }) async {
    // Calculate delivery fee based on delivery method
    final deliveryFee = deliveryMethod == 'pickup' ? 0.0 : calculateDeliveryFee();
    
    // Insert order with delivery_method field
  }
}
```

### **Backend Changes (Supabase SQL)**

**Migration Script**: `supabase_setup/16_add_pickup_option.sql`

```sql
-- 1. Add delivery_method to orders
ALTER TABLE orders 
ADD COLUMN delivery_method VARCHAR(20) DEFAULT 'delivery' 
CHECK (delivery_method IN ('delivery', 'pickup'));

ALTER TABLE orders 
ADD COLUMN pickup_location_id UUID REFERENCES pickup_locations(id);

-- 2. Add pickup settings to users
ALTER TABLE users 
ADD COLUMN pickup_enabled BOOLEAN DEFAULT false,
ADD COLUMN pickup_address TEXT,
ADD COLUMN pickup_instructions TEXT,
ADD COLUMN pickup_hours JSONB;

-- 3. Create pickup_locations table (optional, for multiple locations)
CREATE TABLE pickup_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  location_name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  municipality VARCHAR(100),
  barangay VARCHAR(100),
  instructions TEXT,
  available_days TEXT[],
  available_hours VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Add new order status for pickup
-- (Already handled in FarmerOrderStatus enum: readyForPickup)

-- 5. Create indexes
CREATE INDEX idx_orders_delivery_method ON orders(delivery_method);
CREATE INDEX idx_users_pickup_enabled ON users(pickup_enabled) WHERE pickup_enabled = true;
CREATE INDEX idx_pickup_locations_farmer ON pickup_locations(farmer_id);

-- 6. Update RLS policies
ALTER POLICY "Users can view own orders" ON orders USING (buyer_id = auth.uid() OR farmer_id = auth.uid());
ALTER POLICY "Farmers can update own orders" ON orders USING (farmer_id = auth.uid());
```

---

## 🎯 Implementation Phases

### **Phase 1: Basic Pick-up Support** ✅ RECOMMENDED START
**Scope**: Single pick-up location per farmer, basic UI

**Tasks**:
1. ✅ Database migration (add columns to orders & users)
2. ✅ Update OrderModel to include deliveryMethod
3. ✅ Add delivery method selector to checkout screen
4. ✅ Modify delivery fee calculation (₱0 for pickup)
5. ✅ Add pick-up settings to farmer store settings
6. ✅ Update order details screens to show pickup info
7. ✅ Add "readyForPickup" status to order flow
8. ✅ Update notifications to mention pickup
9. ✅ Testing & bug fixes

**Estimated Effort**: 2-3 days

---

### **Phase 2: Enhanced Pick-up Features** 🔄 FUTURE
**Scope**: Multiple locations, scheduling, directions

**Tasks**:
1. Create pickup_locations table
2. Allow farmers to add multiple pickup locations
3. Location selector for buyers during checkout
4. "Get Directions" button (Google Maps integration)
5. Pick-up time slot scheduling
6. QR code for order verification at pickup
7. Pick-up history analytics

**Estimated Effort**: 3-4 days

---

### **Phase 3: Advanced Features** 🚀 OPTIONAL
**Scope**: Community pickup points, delivery partners

**Tasks**:
1. Community pickup hubs (central locations)
2. Pickup reminders (SMS/email)
3. Pickup location ratings
4. Delivery partner assignment for pickup orders
5. Batch pickup for multiple orders

**Estimated Effort**: 5+ days

---

## 📊 Analytics & Metrics

**Track**:
- % of orders using pickup vs delivery
- Average order value for pickup vs delivery
- Pickup adoption rate per farmer
- Pickup location popularity
- Time to pickup completion

**Dashboard Widgets**:
```
┌──────────────────────────────────────┐
│  Delivery Method Split               │
│                                       │
│  🚚 Home Delivery: 65% (320 orders) │
│  🚶 Pick-up: 35% (172 orders)       │
│                                       │
│  💰 Avg Order Value:                 │
│  Delivery: ₱850 | Pick-up: ₱1,200   │
└──────────────────────────────────────┘
```

---

## ✅ Testing Checklist

### **Buyer Flow**:
- [ ] Can select "Pick-up" during checkout
- [ ] Delivery fee shows ₱0.00 for pickup
- [ ] Can see farmer's pickup location
- [ ] Can place pickup order successfully
- [ ] Receives notification when order ready for pickup
- [ ] Can see pickup instructions in order details
- [ ] Can complete order after pickup

### **Farmer Flow**:
- [ ] Can enable/disable pickup in store settings
- [ ] Can set pickup address and hours
- [ ] Can add pickup instructions
- [ ] Receives pickup orders with correct info
- [ ] Can mark order as "Ready for Pick-up"
- [ ] Can see pickup vs delivery orders separately

### **Edge Cases**:
- [ ] Farmer disables pickup mid-order
- [ ] Buyer changes mind (delivery → pickup)
- [ ] Invalid pickup location
- [ ] Pickup outside available hours
- [ ] Multiple items from different farmers (split pickup/delivery)

---

## 🎨 UI Components to Create

### **New Widgets**:
1. `DeliveryMethodSelector` - Radio button group for delivery/pickup
2. `PickupLocationCard` - Displays pickup address, hours, instructions
3. `PickupSettingsForm` - Farmer's pickup configuration form
4. `PickupBadge` - "Free Pick-up Available" badge for stores
5. `PickupStatusWidget` - Order status for pickup orders

### **Updated Widgets**:
1. `CheckoutScreen` - Add delivery method selection
2. `OrderDetailsScreen` - Show pickup info for pickup orders
3. `StoreCustomizationScreen` - Add pickup settings section
4. `OrderStatusWidget` - Add "Ready for Pick-up" status
5. `DeliveryAddressCard` - Hide/show based on delivery method

---

## 💡 Best Practices & Recommendations

### **User Experience**:
1. **Default to Delivery** - Don't confuse existing users
2. **Clear Savings** - Highlight "Save ₱120 on delivery" for pickup
3. **Visible Location** - Always show pickup address before order
4. **Flexible Toggle** - Easy to switch between delivery/pickup
5. **Clear Instructions** - Farmers should provide detailed pickup directions

### **Business Logic**:
1. **Validate Address** - Ensure farmer has set pickup location before enabling
2. **No Refunds** - Clear policy on pickup no-shows
3. **Time Limits** - Auto-cancel if not picked up within X days
4. **Verification** - Consider QR code or pickup code for security

### **Technical**:
1. **Backward Compatibility** - Default `delivery_method = 'delivery'` for existing orders
2. **Index Performance** - Add indexes on delivery_method for fast filtering
3. **Null Safety** - Handle missing pickup_address gracefully
4. **Feature Flag** - Use platform_settings to enable/disable globally

---

## 🚀 Deployment Plan

### **Step 1: Database Migration**
```bash
# Run migration script
psql -d agrilink -f supabase_setup/16_add_pickup_option.sql

# Verify columns added
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'delivery_method';
```

### **Step 2: Code Deployment**
1. Deploy backend changes (order_service.dart)
2. Deploy UI changes (checkout, order screens)
3. Deploy farmer settings (store customization)

### **Step 3: Testing**
1. Test on staging environment
2. Create test orders with pickup
3. Verify notifications
4. Test farmer settings

### **Step 4: Gradual Rollout**
1. Enable for 10 farmers (beta test)
2. Monitor for 1 week
3. Fix any issues
4. Enable for all farmers

---

## 📝 Next Steps

**Immediate Actions**:
1. ✅ Review this plan with stakeholders
2. ⏳ Get approval for Phase 1 scope
3. ⏳ Create database migration script
4. ⏳ Start UI mockups/prototypes
5. ⏳ Update UNIVERSAL_PROJECT_STATUS.md when starting

**Questions to Answer**:
- Should pickup be enabled by default for all farmers?
- Do we need approval process for pickup locations?
- Should there be a minimum order amount for pickup?
- How long should orders wait before auto-cancelling if not picked up?

---

## 🎉 Success Criteria

**Phase 1 Launch Success** =
- ✅ At least 20% of new orders use pickup within first month
- ✅ No major bugs reported
- ✅ Positive feedback from 80%+ of farmers
- ✅ Reduction in delivery-related complaints
- ✅ 5-10% increase in average order value for pickup orders

---

**Document Version**: 1.0  
**Created**: 2025-01-15  
**Status**: Planning Phase  
**Owner**: Development Team
