-- ================================================
-- PRE-MIGRATION VERIFICATION SCRIPT
-- ================================================
-- Run this BEFORE executing 39_add_order_status_timestamps.sql
-- to ensure your database is ready for the migration
-- ================================================

-- 1. Check if orders table exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'orders'
    ) THEN '✅ orders table exists'
    ELSE '❌ orders table NOT FOUND - cannot proceed'
  END AS orders_table_check;

-- 2. Check current columns in orders table
SELECT 
  '📋 Current orders table columns:' AS info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'orders'
ORDER BY ordinal_position;

-- 3. Check if new timestamp columns already exist (they shouldn't)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'orders' 
      AND column_name IN (
        'accepted_at', 'to_pack_at', 'to_deliver_at', 
        'ready_for_pickup_at', 'cancelled_at',
        'estimated_delivery_at', 'estimated_pickup_at',
        'delivery_started_at', 'delivery_latitude', 'delivery_longitude'
      )
    ) THEN '⚠️ Some new columns already exist - migration may partially fail'
    ELSE '✅ New columns do not exist yet - ready for migration'
  END AS new_columns_check;

-- 4. Check if order_status_history table already exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'order_status_history'
    ) THEN '⚠️ order_status_history table already exists - will be skipped'
    ELSE '✅ order_status_history table does not exist - will be created'
  END AS history_table_check;

-- 5. Check farmer_status and buyer_status enum values
SELECT 
  '📋 Current farmer_order_status enum values:' AS info,
  enumlabel 
FROM pg_enum 
WHERE enumtypid = (
  SELECT oid FROM pg_type WHERE typname = 'farmer_order_status'
)
ORDER BY enumsortorder;

-- 6. Count existing orders for backfill estimate
SELECT 
  '📊 Order counts for backfill:' AS info,
  farmer_status,
  COUNT(*) AS order_count
FROM orders
GROUP BY farmer_status
ORDER BY order_count DESC;

-- 7. Check for orders without timestamps
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN 
      CONCAT('⚠️ ', COUNT(*), ' orders will be backfilled with estimated timestamps')
    ELSE '✅ All orders have timestamps'
  END AS backfill_check
FROM orders
WHERE created_at IS NOT NULL;

-- 8. Final readiness check
SELECT 
  '═══════════════════════════════════════════' AS separator,
  '🎯 MIGRATION READINESS SUMMARY' AS summary,
  '═══════════════════════════════════════════' AS separator2;

SELECT 
  CASE 
    WHEN (
      EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders')
      AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'accepted_at'
      )
    ) THEN '✅ ✅ ✅ READY TO MIGRATE - Proceed with 39_add_order_status_timestamps.sql'
    ELSE '⚠️ Review warnings above before proceeding'
  END AS migration_status;

-- ================================================
-- NEXT STEPS:
-- ================================================
-- If all checks pass:
--   1. Run: supabase_setup/39_add_order_status_timestamps.sql
--   2. Then run: supabase_setup/39_VERIFY_AFTER_MIGRATION.sql
-- 
-- If any checks fail:
--   1. Review the warnings above
--   2. Fix any issues
--   3. Re-run this verification script
-- ================================================
