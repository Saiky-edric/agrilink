# 🔧 Platform Settings Duplicate Row Fix

## 🐛 **Problem**

**Error Message:**
```
Failed to load platform settings for order creation: 
PostgrestException(message: JSON object requested, multiple (or no) rows returned, 
code: 406, details: Results contain 2 rows, application/vnd.pgrst.object+json requires 1 row)
```

**What Happened:**
- The `platform_settings` table has **2 rows**
- The code uses `.maybeSingle()` which expects **0 or 1 row**
- When placing an order, the app tries to load settings but fails

---

## 🔍 **Root Cause**

### **The Code:**
```dart
// In order_service.dart
final settings = await client
    .from('platform_settings')
    .select()
    .maybeSingle();  // ← Expects 0 or 1 row only!
```

### **The Database:**
```sql
SELECT COUNT(*) FROM platform_settings;
-- Result: 2 rows ← Too many!
```

**Why This Is a Problem:**
- `platform_settings` is a **singleton table** (should only have 1 row)
- It stores global app configuration (like `jt_per2kg_fee`, `commission_rate`)
- Multiple rows cause ambiguity (which settings to use?)

---

## ✅ **Solution**

### **SQL Fix Created:**
```
supabase_setup/FIX_PLATFORM_SETTINGS_DUPLICATE.sql
```

### **What It Does:**

1. **Deletes Duplicates**
   - Keeps the most recently updated row
   - Deletes all other rows

2. **Adds Constraint**
   - Adds `singleton_guard` column (always TRUE)
   - Creates unique index on it
   - Prevents future duplicates

---

## 🚀 **How to Fix**

### **Step 1: Run SQL Fix**

**In Supabase SQL Editor:**
```sql
-- Copy and paste entire file:
supabase_setup/FIX_PLATFORM_SETTINGS_DUPLICATE.sql

-- Then execute
```

### **Step 2: Verify**

**Check row count:**
```sql
SELECT COUNT(*) FROM platform_settings;
-- Should return: 1
```

**Check the data:**
```sql
SELECT * FROM platform_settings;
-- Should show only 1 row with your settings
```

### **Step 3: Test Order**

1. Go to checkout screen
2. Add a product
3. Try to place order
4. Should work now! ✅

---

## 📊 **What Gets Deleted**

The SQL keeps the **most recent** row based on `updated_at`:

```sql
-- Keeps this row:
ORDER BY updated_at DESC NULLS LAST LIMIT 1

-- Deletes all others
```

**If both rows have the same `updated_at`:**
- The one with the higher `id` (UUID) will be kept
- This ensures deterministic behavior

---

## 🔒 **Future Prevention**

### **Unique Constraint Added:**

```sql
ALTER TABLE platform_settings 
ADD COLUMN singleton_guard BOOLEAN DEFAULT TRUE NOT NULL;

CREATE UNIQUE INDEX platform_settings_singleton_idx 
ON platform_settings(singleton_guard);
```

**How It Works:**
- All rows must have `singleton_guard = TRUE`
- Only ONE row can have TRUE (unique constraint)
- Attempting to insert a 2nd row will fail with error

**Example:**
```sql
-- This will succeed (first row)
INSERT INTO platform_settings (...) VALUES (...);

-- This will FAIL (duplicate TRUE value)
INSERT INTO platform_settings (...) VALUES (...);
-- ERROR: duplicate key value violates unique constraint
```

---

## 🎯 **Why This Happened**

### **Common Causes:**

1. **Manual Inserts**
   - Someone ran INSERT twice in SQL editor
   - Migration script ran multiple times

2. **Migration Issues**
   - Schema setup script ran twice
   - No unique constraint originally

3. **Testing**
   - Duplicate inserts during development
   - Reset/restore operations

---

## ✅ **Expected Behavior After Fix**

### **Before (Broken):**
```
[Checkout] Store xxx totalKg=1.00 -> fee=70.0
! Failed to load platform settings: 406 error
❌ Cannot place order
```

### **After (Fixed):**
```
[Checkout] Store xxx totalKg=1.00 -> fee=70.0
✓ Platform settings loaded: jt_per2kg_fee=25.0
✓ Order created successfully
✅ Order placed!
```

---

## 🔍 **Debugging Tips**

### **If Error Persists:**

1. **Check row count:**
   ```sql
   SELECT COUNT(*) FROM platform_settings;
   ```
   - Should be exactly 1

2. **Check for NULL updated_at:**
   ```sql
   SELECT id, updated_at FROM platform_settings;
   ```
   - If NULL, the wrong row might have been kept

3. **Check constraint:**
   ```sql
   SELECT * FROM pg_indexes 
   WHERE tablename = 'platform_settings' 
   AND indexname = 'platform_settings_singleton_idx';
   ```
   - Should exist

4. **Try inserting duplicate:**
   ```sql
   INSERT INTO platform_settings (app_name) VALUES ('Test');
   ```
   - Should fail with unique constraint error

---

## 📝 **Platform Settings Fields**

After fix, your single row should contain:

```sql
{
  id: uuid,
  app_name: 'AgriLink',
  maintenance_mode: false,
  new_user_registration: true,
  max_product_images: 5,
  commission_rate: 0.05,
  min_order_amount: 0.00,
  max_order_amount: 10000.00,
  jt_per2kg_fee: 25.0,        ← Used for delivery fee calculation
  featured_categories: [],
  notification_settings: {},
  payment_methods: {},
  shipping_zones: {},
  updated_at: timestamp,
  updated_by: uuid,
  singleton_guard: true        ← New field to prevent duplicates
}
```

---

## 🎉 **Summary**

**Problem:** 2 rows in `platform_settings` table  
**Impact:** Cannot place orders  
**Solution:** SQL fix to delete duplicates + add constraint  
**Prevention:** Unique index prevents future duplicates  
**Result:** Orders work again! ✅

---

## 🚨 **Quick Fix (Alternative)**

If you can't run the SQL file, you can manually fix it:

### **Option 1: In Supabase Dashboard**
1. Go to Table Editor
2. Open `platform_settings` table
3. Delete one of the two rows (keep the one you want)

### **Option 2: In SQL Editor**
```sql
-- Quick one-liner fix
DELETE FROM platform_settings 
WHERE id NOT IN (
    SELECT id FROM platform_settings 
    ORDER BY updated_at DESC NULLS LAST 
    LIMIT 1
);
```

---

**Date:** January 23, 2026  
**Status:** ✅ Fix Ready  
**Impact:** Critical - Blocks order placement
