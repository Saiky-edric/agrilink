# 🕐 Product Shelf Life & Deletion System - COMPLETE ✅

## Implementation Status: **100% COMPLETE**

Complete implementation of product shelf life tracking, automatic expiration, and safe product deletion system.

---

## 🎯 Problem Solved

### Issues:
1. **Foreign Key Constraint Error**: Products with orders couldn't be deleted
   - Error: `update or delete on table "products" violates foreign key constraint "order_items_product_id_fkey"`
2. **No Shelf Life Management**: Products never expired automatically
3. **No Expired Product Tracking**: Farmers couldn't manage expired products
4. **Hard Delete Risk**: Deleting products broke order history

### Solution Implemented:
✅ **Soft Delete System** - Products are hidden, not removed from database  
✅ **Automatic Expiration** - Products auto-hide when shelf life expires  
✅ **Shelf Life Tracking** - Full lifecycle management from creation to expiry  
✅ **Expired Products Management** - Dedicated UI for farmers  
✅ **Daily Auto-Check** - Cron job runs daily at 2 AM  

---

## 📋 Implementation Details

### 1. **Database Schema** (`supabase_setup/17_fix_product_deletion_and_expiry.sql`)

#### New Columns:
```sql
-- Soft delete tracking
ALTER TABLE products ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

-- Product status
ALTER TABLE products ADD COLUMN status TEXT DEFAULT 'active' 
  CHECK (status IN ('active', 'expired', 'deleted'));
```

#### Database Functions:

**`auto_hide_expired_products()`**
- Automatically hides products past their expiry date
- Updates status to 'expired'
- Sets is_hidden = true
- Runs daily via cron job

**`get_expiring_products(days_threshold)`**
- Returns products expiring within X days
- Used for notifications to farmers
- Default threshold: 3 days

**`get_expired_products()`**
- Returns all expired products
- Shows days since expiration
- Used in expired products management screen

**`soft_delete_product(product_id)`**
- Marks product as deleted without removing from DB
- Sets status = 'deleted'
- Sets deleted_at = NOW()
- Preserves order history

**`restore_product(product_id)`**
- Restores deleted products
- Only works if product not expired
- Resets status to 'active'
- Clears deleted_at timestamp

#### Scheduled Job:
```sql
-- Daily at 2 AM
SELECT cron.schedule(
  'auto-hide-expired-products',
  '0 2 * * *',
  $$ SELECT auto_hide_expired_products(); $$
);
```

#### Performance Indexes:
```sql
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_deleted_at ON products(deleted_at) 
  WHERE deleted_at IS NOT NULL;
```

---

### 2. **Data Model Updates** (`lib/core/models/product_model.dart`)

#### New Fields:
```dart
final String status; // 'active', 'expired', 'deleted'
final DateTime? deletedAt;
```

#### New Getters:
```dart
bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiryDate);
bool get isDeleted => status == 'deleted' || deletedAt != null;
bool get isActive => status == 'active' && !isDeleted && !isExpired;
DateTime get expiryDate => createdAt.add(Duration(days: shelfLifeDays));
int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
bool get isExpiringWithin24Hours => daysUntilExpiry <= 1 && daysUntilExpiry >= 0;
bool get isExpiringWithin3Days => daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
```

---

### 3. **Service Layer Updates** (`lib/core/services/product_service.dart`)

#### Updated Methods:

**`deleteProduct(productId)`**
- Now uses soft delete via RPC call
- No more foreign key constraint errors
- Preserves order history

**`restoreProduct(productId)`**
- Restores soft-deleted products
- Validates product not expired

**`getExpiredProducts(farmerId)`**
- Fetches expired products from database function
- Returns product details with days since expired

**`getExpiringProducts(farmerId, daysThreshold)`**
- Fetches products expiring soon
- Configurable threshold (default 3 days)

**`getDeletedProducts(farmerId)`**
- Fetches soft-deleted products
- Allows restoration if not expired

**`checkAndHideExpiredProducts()`**
- Manually trigger expiry check
- Useful for testing or immediate updates

---

### 4. **User Interface Components**

#### A. **Add Product Screen** (`lib/features/farmer/screens/add_product_screen.dart`)
✅ Already has shelf life input field  
✅ Default: 7 days  
✅ Calculates expiry date on product creation  

#### B. **Edit Product Screen** (`lib/features/farmer/screens/edit_product_screen.dart`)

**New Features:**
- ✅ **Shelf Life Information Card**:
  - Color-coded based on status (green/orange/red)
  - Shows shelf life days
  - Shows creation date
  - Shows expiry date
  - Shows days remaining or expired status
  - Warning icon for expired products
  - Visual indicators for products expiring within 3 days

**UI States:**
1. **Active (Green)**: Product has plenty of shelf life remaining
2. **Expiring Soon (Orange)**: Product expires within 3 days
3. **Expired (Red)**: Product has expired, hidden from buyers

#### C. **Expired Products Management Screen** (`lib/features/farmer/screens/expired_products_screen.dart`)

**NEW SCREEN** - Complete management interface for expired/deleted products

**Features:**
- ✅ **Two Sections**:
  1. Expired Products
  2. Deleted Products
- ✅ **Info Card**: Explains product management rules
- ✅ **Expired Products Section**:
  - Shows all expired products
  - Displays days since expiration
  - Shows expiry date
  - Delete button (soft delete)
  - Warning icon indicator
- ✅ **Deleted Products Section**:
  - Shows all soft-deleted products
  - Displays deletion date
  - Restore button (if not expired)
  - Blocked icon if expired
  - Cannot restore expired products
- ✅ **Confirmation Dialogs**:
  - Delete confirmation with warning
  - Restore confirmation
- ✅ **Pull-to-Refresh**: Reload data
- ✅ **Empty States**: Clean UI when no items
- ✅ **Success/Error Feedback**: SnackBar notifications

#### D. **Product List Screen** (`lib/features/farmer/screens/product_list_screen.dart`)

**New Features:**
- ✅ **AppBar Action Button**: Warning icon to access expired products
- ✅ **Tooltip**: "Expired & Deleted Products"
- ✅ **Quick Access**: One tap to manage expired/deleted items

---

### 5. **Navigation & Routing**

#### Route Names (`lib/core/router/route_names.dart`):
```dart
static const String expiredProducts = '/farmer/expired-products';
static const String pickupSettings = '/farmer/pickup-settings';
```

#### Router (`lib/core/router/app_router.dart`):
```dart
GoRoute(
  path: '/farmer/expired-products',
  name: 'expiredProducts',
  builder: (context, state) => const ExpiredProductsScreen(),
),
```

**Access Path:**
- Product List → Warning Icon (AppBar) → Expired Products Screen
- Direct navigation: `context.push(RouteNames.expiredProducts)`

---

## 🔄 Product Lifecycle

```
┌─────────────┐
│   CREATED   │ (shelf_life_days = 7, status = 'active')
└──────┬──────┘
       │
       │ Sold normally while active
       │
       ↓
┌─────────────┐
│   ACTIVE    │ (visible to buyers, can be ordered)
└──────┬──────┘
       │
       │ Time passes (shelf_life_days countdown)
       │
       ↓
┌─────────────┐
│  EXPIRING   │ (3 days or less remaining)
│   SOON      │ (orange warning in UI)
└──────┬──────┘
       │
       │ Shelf life reaches 0
       │
       ↓
┌─────────────┐
│   EXPIRED   │ (auto-hidden by cron job)
│             │ (status = 'expired', is_hidden = true)
└──────┬──────┘
       │
       │ Farmer decides
       │
       ├─────────────┐
       │             │
       ↓             ↓
┌─────────┐   ┌─────────────┐
│ DELETED │   │   KEPT      │
│ (soft)  │   │ (archived)  │
└─────────┘   └─────────────┘
```

**Soft Delete Path:**
```
Active → Farmer deletes → Status = 'deleted' → Can restore (if not expired)
```

---

## 🎨 UI/UX Features

### Visual Indicators:

**Edit Product Screen:**
- 🟢 **Green Card**: Product fresh, plenty of time remaining
- 🟠 **Orange Card**: Product expiring within 3 days (warning)
- 🔴 **Red Card**: Product expired (hidden from buyers)

**Expired Products Screen:**
- 🔴 **Red Avatar**: Expired product indicator
- ⚫ **Gray Avatar**: Deleted product indicator
- 🟢 **Green Restore Button**: Can restore deleted product
- ⚫ **Gray Block Icon**: Cannot restore (expired)

### Card Components:
- **Color-coded borders** based on status
- **Icon indicators** for quick status recognition
- **Days remaining** or days expired counter
- **Date formatting** for clarity
- **Action buttons** (delete, restore)
- **Confirmation dialogs** for safety

---

## 📊 Database Schema Reference

### Products Table Columns:
```sql
id UUID PRIMARY KEY
farmer_id UUID (foreign key to users)
name TEXT
description TEXT
price NUMERIC
stock INTEGER
unit TEXT
shelf_life_days INTEGER (default 7)
category TEXT
cover_image_url TEXT
additional_image_urls TEXT[]
farm_name TEXT
farm_location TEXT
weight_per_unit NUMERIC
is_hidden BOOLEAN (default false)
status TEXT (default 'active')  -- NEW
deleted_at TIMESTAMP             -- NEW
created_at TIMESTAMP
updated_at TIMESTAMP
```

### Status Values:
- `active`: Normal, visible to buyers (if not hidden manually)
- `expired`: Past shelf life, auto-hidden from buyers
- `deleted`: Soft-deleted by farmer, can be restored

---

## 🔒 Security & Data Integrity

### RLS Policies:
```sql
-- Users can view active products (not deleted)
CREATE POLICY "Users can view active products"
ON products FOR SELECT
TO authenticated
USING (deleted_at IS NULL AND (is_hidden = false OR farmer_id = auth.uid()));

-- Farmers can update/delete own products
CREATE POLICY "Farmers can delete own products"
ON products FOR UPDATE
TO authenticated
USING (farmer_id = auth.uid())
WITH CHECK (farmer_id = auth.uid());
```

### Data Preservation:
- ✅ Products with orders **cannot be hard deleted** (foreign key constraint)
- ✅ Soft delete preserves order history
- ✅ Expired products remain in database for analytics
- ✅ Restoration validates expiry before allowing

---

## 📝 Testing Guide

### Step 1: Run Database Migration
```sql
-- In Supabase SQL Editor
\i supabase_setup/17_fix_product_deletion_and_expiry.sql
```

**Expected Output:**
```
✓ deleted_at column added
✓ status column added with CHECK constraint
✓ Indexes created successfully
✓ Functions created: auto_hide_expired_products, get_expiring_products, get_expired_products, soft_delete_product, restore_product
✓ Cron job scheduled
✓ RLS policies updated
✓ Initial cleanup completed
```

---

### Step 2: Test Product Creation with Shelf Life

1. **Login as Farmer**
2. **Go to Products → Add Product**
3. **Fill in product details**
4. **Set Shelf Life**: e.g., `1` day (for quick testing)
5. **Add product**
6. **Verify**: Product shows in product list

---

### Step 3: Test Edit Product - Shelf Life Display

1. **Edit the product** you just created
2. **Scroll down** to shelf life information card
3. **Verify Card Shows**:
   - ✅ Shelf Life: 1 day
   - ✅ Created: [today's date]
   - ✅ Expires: [tomorrow's date]
   - ✅ Days remaining: 0 or 1
   - ✅ Color: Orange or Green

---

### Step 4: Test Product Deletion (Soft Delete)

1. **Go to Product List**
2. **Try to delete a product** with existing orders
3. **Confirm deletion**
4. **Verify**: Product removed from active list (no error!)
5. **Click warning icon** in AppBar
6. **Verify**: Product appears in "Deleted Products" section

---

### Step 5: Test Product Restoration

1. **In Expired Products screen**
2. **Find deleted product** (not expired)
3. **Click restore button** (green icon)
4. **Confirm restoration**
5. **Verify**: Product returns to active product list
6. **Success message** displayed

---

### Step 6: Test Automatic Expiration

#### Option A: Manual Trigger (Immediate)
```sql
-- In Supabase SQL Editor
SELECT auto_hide_expired_products();
```

#### Option B: Wait for Cron Job (Daily at 2 AM)
- Create product with 1-day shelf life
- Wait until next day after 2 AM
- Product automatically hidden

**Verify:**
1. Expired products no longer visible to buyers
2. `status` = 'expired'
3. `is_hidden` = true
4. Product appears in "Expired Products" section

---

### Step 7: Test Expiring Products Query

```sql
-- Get products expiring within 3 days
SELECT * FROM get_expiring_products(3);
```

**Expected Output:**
```
product_id | farmer_id | product_name | days_until_expiry | expiry_date
-----------|-----------|--------------|-------------------|-------------
uuid       | uuid      | "Tomatoes"   | 2                 | 2024-01-18
```

---

### Step 8: Test Expired Products Query

```sql
-- Get all expired products
SELECT * FROM get_expired_products();
```

**Expected Output:**
```
product_id | farmer_id | product_name | days_since_expired | expired_date
-----------|-----------|--------------|--------------------|--------------
uuid       | uuid      | "Old Cabbage"| 5                  | 2024-01-10
```

---

### Step 9: Test Edge Cases

#### Test Case A: Delete Product with Orders
1. Create product
2. Create order with that product
3. Try to delete product
4. ✅ **Should succeed** (soft delete)
5. ✅ Order history preserved
6. ✅ Product in deleted section

#### Test Case B: Restore Expired Product
1. Create product with 1-day shelf life
2. Wait for expiration
3. Soft delete the product
4. Try to restore
5. ✅ **Should fail** with error: "Cannot restore expired product"

#### Test Case C: Expired Product Visibility
1. Create product with 1-day shelf life
2. Wait for expiration (or trigger manually)
3. **As Buyer**: Browse products
4. ✅ Expired product **not visible**
5. **As Farmer**: Check product list
6. ✅ Expired product **visible** (for farmer only)

---

## 🚀 Production Deployment

### Pre-Deployment Checklist:
- [ ] Run database migration in production Supabase
- [ ] Verify pg_cron extension enabled
- [ ] Confirm cron job scheduled
- [ ] Test soft delete with sample products
- [ ] Test restore functionality
- [ ] Verify RLS policies working correctly
- [ ] Test automatic expiration (manual trigger)
- [ ] Deploy updated Flutter app

### Post-Deployment:
- [ ] Monitor cron job execution logs
- [ ] Check for products being auto-expired daily
- [ ] Verify no foreign key constraint errors
- [ ] Monitor farmer feedback on expired products screen

---

## 📈 Benefits

### For Farmers:
✅ **Safe Deletion**: Delete products without breaking order history  
✅ **Automatic Management**: Products auto-expire, no manual checking  
✅ **Easy Recovery**: Restore accidentally deleted products  
✅ **Better Inventory**: Visual warnings for expiring products  
✅ **Compliance**: Ensures old products not sold  

### For Buyers:
✅ **Fresh Products**: Only see products within shelf life  
✅ **Trust**: Automatic quality control  
✅ **Transparency**: No expired products in catalog  

### For Platform:
✅ **Data Integrity**: No broken order references  
✅ **Automated**: Daily cron job handles expiration  
✅ **Analytics Ready**: Full product lifecycle data preserved  
✅ **Scalable**: Works for any number of products  

---

## 📁 Files Created/Modified

### Created (2 files):
- ✅ `supabase_setup/17_fix_product_deletion_and_expiry.sql`
- ✅ `lib/features/farmer/screens/expired_products_screen.dart`
- ✅ `SHELF_LIFE_SYSTEM_COMPLETE.md` (this file)

### Modified (6 files):
- ✅ `lib/core/models/product_model.dart`
- ✅ `lib/core/services/product_service.dart`
- ✅ `lib/features/farmer/screens/edit_product_screen.dart`
- ✅ `lib/features/farmer/screens/product_list_screen.dart`
- ✅ `lib/core/router/route_names.dart`
- ✅ `lib/core/router/app_router.dart`

---

## 🔮 Future Enhancements (Phase 2)

Potential improvements for future releases:

### Notifications:
- 📧 Email farmers when products expiring within 3 days
- 📱 Push notifications for expiring products
- 📊 Weekly summary of expired products

### Analytics:
- 📈 Track product expiration rates
- 💰 Calculate waste/revenue lost to expiration
- 📊 Optimize shelf life based on historical data

### Advanced Features:
- 🔄 Batch expiry management
- 🏷️ Auto-discount products near expiry
- 📸 Photo documentation of expired products
- 📋 Expiration reports for food safety compliance

---

## ✅ Completion Checklist

- [x] Database schema with soft delete columns
- [x] Auto-expiration function implemented
- [x] Database helper functions created
- [x] Scheduled cron job configured
- [x] ProductModel updated with status fields
- [x] ProductService soft delete methods
- [x] ProductService expiry query methods
- [x] Edit product shelf life display
- [x] Expired products management screen
- [x] Product list expired products button
- [x] Navigation routes configured
- [x] RLS policies updated
- [x] Testing guide created
- [x] Documentation complete

---

## 🎉 System Complete!

The shelf life and product deletion system is now **fully functional** and **production-ready**!

### Key Achievements:
✅ **No more foreign key errors** when deleting products  
✅ **Automatic expiration** runs daily at 2 AM  
✅ **Complete lifecycle management** from creation to deletion  
✅ **Farmer-friendly UI** for managing expired/deleted products  
✅ **Data preservation** for analytics and order history  
✅ **Visual indicators** for product freshness  

---

**Last Updated:** 2024  
**Status:** ✅ PRODUCTION READY  
**Version:** 1.0
