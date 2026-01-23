-- Check the handle_order_notifications function that might be causing the "rejected" error

-- 1. Get the definition of the handle_order_notifications function
SELECT 'handle_order_notifications function definition:' as info;
SELECT routine_definition
FROM information_schema.routines
WHERE routine_name = 'handle_order_notifications'
  AND routine_schema = 'public';

-- 2. Also check the trigger_update_seller_stats function
SELECT 'trigger_update_seller_stats function definition:' as info;
SELECT routine_definition
FROM information_schema.routines
WHERE routine_name = 'trigger_update_seller_stats'
  AND routine_schema = 'public';

-- 3. Check for any other notification-related functions
SELECT 'All notification-related functions:' as info;
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name ILIKE '%notification%'
  AND routine_schema = 'public';

-- 4. Look for any functions that might use "rejected" in farmer context
SELECT 'Functions with rejected in definition:' as info;
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_definition ILIKE '%rejected%'
  AND routine_schema = 'public'
  AND routine_name NOT LIKE 'pg_%';