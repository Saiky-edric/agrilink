-- Debug script to check for confusion between verification status and order status

-- 1. Check farmer_verifications table verification_status values (should include 'rejected')
SELECT 'farmer_verifications verification_status values:' as info, 
       DISTINCT verification_status as values
FROM farmer_verifications;

-- 2. Check farmer_order_status enum values (should NOT include 'rejected')
SELECT 'farmer_order_status enum values:' as info, 
       string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 3. Check if there are any triggers on orders table that might reference verification status
SELECT 'Triggers on orders table:' as info;
SELECT trigger_name, event_manipulation, action_statement, action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 4. Check for any functions that might be confusing these statuses
SELECT 'Functions mentioning rejected:' as info;
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_definition ILIKE '%rejected%'
AND routine_schema = 'public';

-- 5. Check current orders table schema to see column names
SELECT 'Orders table columns:' as info;
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name LIKE '%status%'
ORDER BY ordinal_position;

-- 6. Check farmer_verifications table schema
SELECT 'farmer_verifications table columns:' as info;
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'farmer_verifications'
ORDER BY ordinal_position;

-- 7. Check if there are any orders with verification_status instead of farmer_status
SELECT 'Check for column confusion:' as info;
SELECT COUNT(*) as total_orders, 
       COUNT(CASE WHEN farmer_status IS NOT NULL THEN 1 END) as orders_with_farmer_status,
       COUNT(CASE WHEN buyer_status IS NOT NULL THEN 1 END) as orders_with_buyer_status
FROM orders;

-- 6. Check if there are any RLS policies that might be causing issues
SELECT 'RLS policies on orders:' as info;
SELECT pol.polname, pol.polcmd, pol.polqual, pol.polwithcheck
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'orders';