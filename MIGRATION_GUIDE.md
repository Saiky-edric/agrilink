# 📘 Database Migration Guide - Order Timeline Enhancement

## Overview
This guide walks you through safely migrating your database to support the advanced order timeline features.

---

## ⚠️ Before You Start

### Prerequisites
- [ ] Access to Supabase SQL Editor
- [ ] Database backup (recommended)
- [ ] Current schema matches provided schema
- [ ] No active critical orders being processed (or plan for brief downtime)

### Estimated Time
- **Verification**: 2 minutes
- **Migration**: 5 minutes
- **Testing**: 10 minutes
- **Total**: ~15-20 minutes

---

## 🔍 Step 1: Pre-Migration Verification

### Run Verification Script
1. Open Supabase Dashboard → SQL Editor
2. Open `supabase_setup/39_VERIFY_BEFORE_MIGRATION.sql`
3. Execute the entire script
4. Review the output

### Expected Results
You should see:
```
✅ orders table exists
✅ New columns do not exist yet - ready for migration
✅ order_status_history table does not exist - will be created
📊 Order counts for backfill: (shows your order distribution)
✅ ✅ ✅ READY TO MIGRATE
```

### ⚠️ If You See Warnings
- **"Some columns already exist"**: Some timestamp columns were added previously
  - **Action**: Review which columns exist, may need to modify migration
- **"orders table NOT FOUND"**: Critical error
  - **Action**: Verify you're in correct database, check schema
- **"order_status_history already exists"**: Table was created before
  - **Action**: Migration will skip table creation (safe)

---

## 🚀 Step 2: Run Migration

### Execute Migration Script

1. In Supabase SQL Editor, open `supabase_setup/39_add_order_status_timestamps.sql`
2. **Read through the script** to understand what it does
3. **Execute the entire script**
4. Wait for completion (usually 5-30 seconds depending on order count)

### What the Migration Does

#### ✅ Adds 14 New Columns to `orders` Table
- `accepted_at` - When farmer accepts order
- `to_pack_at` - When packing starts
- `to_deliver_at` - When delivery begins  
- `ready_for_pickup_at` - When ready for pickup
- `cancelled_at` - When order cancelled
- `estimated_delivery_at` - Estimated completion time
- `estimated_pickup_at` - Estimated pickup time
- `delivery_started_at` - Actual delivery start
- `delivery_latitude` / `delivery_longitude` - Current delivery location
- `delivery_last_updated_at` - Last location update
- `farmer_latitude` / `farmer_longitude` - Farm location
- `buyer_latitude` / `buyer_longitude` - Delivery destination

#### ✅ Creates `order_status_history` Table
Complete audit trail of all status changes with:
- Old and new status
- Who made the change
- Timestamp
- Notes/reason
- Location data

#### ✅ Creates Automatic Trigger
Automatically sets timestamps when order status changes

#### ✅ Creates Helper Functions
- `calculate_estimated_delivery_time()` - Smart ETA calculation
- `update_delivery_location()` - For real-time map tracking

#### ✅ Backfills Existing Orders
Estimates timestamps for historical orders based on:
- Created date + typical processing time
- Current status
- Completed date (if available)

---

## ✅ Step 3: Post-Migration Verification

### Run Verification Script

1. In Supabase SQL Editor, open `supabase_setup/39_VERIFY_AFTER_MIGRATION.sql`
2. Execute the entire script
3. Review the output

### Expected Results

You should see:
```
✅ All 14 new columns added successfully
✅ order_status_history table created
✅ Trigger created
✅ All 3 functions created
✅ Indexes created
📊 Backfill results showing populated timestamps
✅ ✅ ✅ MIGRATION SUCCESSFUL
```

### Verify Sample Data

Check a few orders manually:
```sql
SELECT 
  id,
  farmer_status,
  created_at,
  accepted_at,
  to_pack_at,
  completed_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;
```

You should see timestamps populated based on order status.

---

## 🧪 Step 4: Test in Application

### Test Timeline Display

1. **Run your Flutter app**
2. **Navigate to an order details screen**
3. **Verify you see**:
   - Timeline with events
   - Timestamps showing relative time ("2 hrs ago")
   - Duration between steps
   - "🟢 Live" badge (real-time indicator)

### Test Real-Time Updates

1. **Open order details on one device**
2. **Update order status in Supabase dashboard**:
   ```sql
   UPDATE orders 
   SET farmer_status = 'accepted',
       accepted_at = NOW()
   WHERE id = 'your-order-id';
   ```
3. **Watch timeline update automatically** (no refresh needed!)

### Test Completed Orders

1. **Find a completed order**
2. **Verify you see**:
   - All status timestamps populated
   - Total duration displayed
   - Green "Completed" badge

---

## 🐛 Troubleshooting

### Migration Fails

**Error: Column already exists**
```sql
-- Check which columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name LIKE '%_at';

-- Skip existing columns in migration
-- Edit migration to wrap conflicting lines in:
-- ALTER TABLE orders ADD COLUMN IF NOT EXISTS ...
```

**Error: Permission denied**
```sql
-- Verify you have sufficient permissions
SELECT current_user, current_database();

-- Should be service_role or postgres user
```

**Error: Trigger conflicts**
```sql
-- Drop existing trigger if needed
DROP TRIGGER IF EXISTS trigger_update_order_status_timestamps ON orders;

-- Then re-run trigger creation from migration
```

### Timeline Not Showing Data

**Check if columns have data:**
```sql
SELECT 
  COUNT(*) as total,
  COUNT(accepted_at) as has_accepted,
  COUNT(to_pack_at) as has_to_pack
FROM orders;
```

**If counts are 0, re-run backfill:**
```sql
-- Re-run backfill section from migration
UPDATE orders
SET accepted_at = created_at + INTERVAL '30 minutes'
WHERE farmer_status IN ('accepted', 'toPack', 'toDeliver', 'completed')
  AND accepted_at IS NULL;
```

### Real-Time Not Working

**Check Supabase Realtime is enabled:**
1. Go to Supabase Dashboard → Database → Replication
2. Verify `orders` table has realtime enabled
3. If not, enable it:
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE orders;
   ```

**Check in Flutter app:**
```dart
// Verify subscription is active
print('Realtime subscription status: ${_orderSubscription != null}');
```

### Map Not Showing

**Verify location data exists:**
```sql
SELECT 
  COUNT(*) as total,
  COUNT(buyer_latitude) as has_buyer_loc,
  COUNT(delivery_latitude) as has_delivery_loc
FROM orders
WHERE farmer_status = 'toDeliver';
```

**If missing, coordinates need to be populated:**
- Buyer location: Set when order is created (from address)
- Delivery location: Updated by farmer during delivery
- Farmer location: Set in user profile

---

## 🔄 Rollback (If Needed)

If you need to rollback the migration:

```sql
-- 1. Drop trigger
DROP TRIGGER IF EXISTS trigger_update_order_status_timestamps ON orders;

-- 2. Drop functions
DROP FUNCTION IF EXISTS update_order_status_timestamps();
DROP FUNCTION IF EXISTS calculate_estimated_delivery_time(uuid, text);
DROP FUNCTION IF EXISTS update_delivery_location(uuid, double precision, double precision);

-- 3. Drop history table
DROP TABLE IF EXISTS order_status_history;

-- 4. Remove new columns (CAUTION: This deletes data!)
ALTER TABLE orders 
  DROP COLUMN IF EXISTS accepted_at,
  DROP COLUMN IF EXISTS to_pack_at,
  DROP COLUMN IF EXISTS to_deliver_at,
  DROP COLUMN IF EXISTS ready_for_pickup_at,
  DROP COLUMN IF EXISTS cancelled_at,
  DROP COLUMN IF EXISTS estimated_delivery_at,
  DROP COLUMN IF EXISTS estimated_pickup_at,
  DROP COLUMN IF EXISTS delivery_started_at,
  DROP COLUMN IF EXISTS delivery_latitude,
  DROP COLUMN IF EXISTS delivery_longitude,
  DROP COLUMN IF EXISTS delivery_last_updated_at,
  DROP COLUMN IF EXISTS farmer_latitude,
  DROP COLUMN IF EXISTS farmer_longitude,
  DROP COLUMN IF EXISTS buyer_latitude,
  DROP COLUMN IF EXISTS buyer_longitude;
```

---

## 📊 Monitoring After Migration

### Check Migration Impact

```sql
-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_status_history')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check history table growth
SELECT 
  DATE(created_at) as date,
  COUNT(*) as status_changes
FROM order_status_history
GROUP BY DATE(created_at)
ORDER BY date DESC
LIMIT 7;
```

### Performance Checks

```sql
-- Check if indexes are being used
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE farmer_status = 'toDeliver' 
AND delivery_latitude IS NOT NULL
LIMIT 10;

-- Should show "Index Scan" in output
```

---

## ✅ Success Criteria

Migration is successful when:
- ✅ All verification scripts pass
- ✅ Timeline displays with timestamps
- ✅ Real-time updates work without refresh
- ✅ No errors in application logs
- ✅ Order status changes record timestamps automatically
- ✅ History table captures all changes

---

## 📞 Support

If you encounter issues:

1. **Check the verification scripts output** - They show detailed diagnostics
2. **Review error messages** - Most errors are self-explanatory
3. **Check Supabase logs** - Dashboard → Logs → Database
4. **Review documentation** - See ADVANCED_ORDER_TIMELINE_COMPLETE.md

---

## 🎉 Next Steps After Successful Migration

1. ✅ **Test timeline features** in your app
2. 🚀 **Implement farmer location updates** for map tracking
3. 📱 **Add push notifications** for status changes (optional)
4. 📊 **Monitor performance** and user feedback
5. 🎨 **Customize timeline** appearance if needed

---

**Migration prepared by**: Rovo AI Agent  
**Date**: January 29, 2026  
**Version**: 1.0  
**Status**: Production Ready ✅
