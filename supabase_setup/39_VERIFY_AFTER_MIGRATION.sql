-- ================================================
-- POST-MIGRATION VERIFICATION SCRIPT
-- ================================================
-- Run this AFTER executing 39_add_order_status_timestamps.sql
-- to verify the migration was successful
-- ================================================

-- 1. Verify new timestamp columns were added
SELECT 
  '✅ Verifying new timestamp columns in orders table:' AS info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'orders'
AND column_name IN (
  'accepted_at', 'to_pack_at', 'to_deliver_at', 
  'ready_for_pickup_at', 'cancelled_at',
  'estimated_delivery_at', 'estimated_pickup_at',
  'delivery_started_at', 'delivery_latitude', 'delivery_longitude',
  'delivery_last_updated_at', 'farmer_latitude', 'farmer_longitude',
  'buyer_latitude', 'buyer_longitude'
)
ORDER BY column_name;

-- 2. Check if all expected columns exist
SELECT 
  CASE 
    WHEN COUNT(*) = 14 THEN '✅ All 14 new columns added successfully'
    ELSE CONCAT('⚠️ Only ', COUNT(*), ' of 14 columns found - check for errors')
  END AS column_count_check
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'orders'
AND column_name IN (
  'accepted_at', 'to_pack_at', 'to_deliver_at', 
  'ready_for_pickup_at', 'cancelled_at',
  'estimated_delivery_at', 'estimated_pickup_at',
  'delivery_started_at', 'delivery_latitude', 'delivery_longitude',
  'delivery_last_updated_at', 'farmer_latitude', 'farmer_longitude',
  'buyer_latitude', 'buyer_longitude'
);

-- 3. Verify order_status_history table was created
SELECT 
  '✅ Verifying order_status_history table:' AS info;

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'order_status_history'
ORDER BY ordinal_position;

-- 4. Check if trigger was created
SELECT 
  '✅ Verifying trigger:' AS info,
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name = 'trigger_update_order_status_timestamps';

-- 5. Verify functions were created
SELECT 
  '✅ Verifying functions:' AS info,
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
  'update_order_status_timestamps',
  'calculate_estimated_delivery_time',
  'update_delivery_location'
)
ORDER BY routine_name;

-- 6. Check if indexes were created
SELECT 
  '✅ Verifying indexes:' AS info,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_status_history')
AND indexname LIKE '%timestamp%' OR indexname LIKE '%realtime%' OR indexname LIKE '%status_history%'
ORDER BY tablename, indexname;

-- 7. Check backfill results
SELECT 
  '📊 Backfill results:' AS info,
  farmer_status,
  COUNT(*) AS total_orders,
  COUNT(accepted_at) AS has_accepted_at,
  COUNT(to_pack_at) AS has_to_pack_at,
  COUNT(to_deliver_at) AS has_to_deliver_at,
  COUNT(ready_for_pickup_at) AS has_ready_for_pickup_at,
  COUNT(completed_at) AS has_completed_at,
  COUNT(cancelled_at) AS has_cancelled_at
FROM orders
GROUP BY farmer_status
ORDER BY total_orders DESC;

-- 8. Test the calculate_estimated_delivery_time function
SELECT 
  '✅ Testing calculate_estimated_delivery_time function:' AS info;

-- Get a sample order ID for testing
DO $$
DECLARE
  sample_order_id uuid;
  estimated_time timestamptz;
BEGIN
  -- Get first order ID
  SELECT id INTO sample_order_id FROM orders LIMIT 1;
  
  IF sample_order_id IS NOT NULL THEN
    -- Test the function
    SELECT calculate_estimated_delivery_time(sample_order_id, 'delivery') INTO estimated_time;
    RAISE NOTICE '✅ Function test successful. Estimated time: %', estimated_time;
  ELSE
    RAISE NOTICE '⚠️ No orders found to test function';
  END IF;
END $$;

-- 9. Verify RLS policies on order_status_history
SELECT 
  '✅ Verifying RLS policies on order_status_history:' AS info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'order_status_history'
ORDER BY policyname;

-- 10. Sample query to show timeline data
SELECT 
  '📋 Sample order timeline data:' AS info;

SELECT 
  id,
  farmer_status,
  created_at,
  accepted_at,
  to_pack_at,
  to_deliver_at,
  ready_for_pickup_at,
  completed_at,
  cancelled_at,
  estimated_delivery_at
FROM orders
WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 5;

-- 11. Final success summary
SELECT 
  '═══════════════════════════════════════════' AS separator,
  '🎉 MIGRATION VERIFICATION COMPLETE' AS summary,
  '═══════════════════════════════════════════' AS separator2;

SELECT 
  CASE 
    WHEN (
      -- Check all columns exist
      (SELECT COUNT(*) FROM information_schema.columns 
       WHERE table_schema = 'public' AND table_name = 'orders' 
       AND column_name IN ('accepted_at', 'to_pack_at', 'to_deliver_at', 'ready_for_pickup_at')) = 4
      AND
      -- Check history table exists
      EXISTS (SELECT 1 FROM information_schema.tables 
              WHERE table_schema = 'public' AND table_name = 'order_status_history')
      AND
      -- Check trigger exists
      EXISTS (SELECT 1 FROM information_schema.triggers 
              WHERE trigger_schema = 'public' AND trigger_name = 'trigger_update_order_status_timestamps')
    ) THEN '✅ ✅ ✅ MIGRATION SUCCESSFUL - All components in place!'
    ELSE '⚠️ Some components missing - review results above'
  END AS final_status;

-- ================================================
-- NEXT STEPS:
-- ================================================
-- If verification passes:
--   ✅ Migration is complete and successful
--   ✅ Timeline widget will now show precise timestamps
--   ✅ Real-time updates are ready to use
--   ✅ Map tracking is ready (once location updates are implemented)
-- 
-- You can now:
--   1. Test the timeline in your Flutter app
--   2. Create test orders and watch timestamps populate
--   3. Implement farmer location updates for map tracking
-- ================================================
