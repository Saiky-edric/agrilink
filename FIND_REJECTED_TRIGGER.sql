-- Find what's causing "rejected" to be injected during order updates

-- 1. Check for triggers on the orders table
SELECT 'Triggers on orders table:' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
  AND event_object_schema = 'public';

-- 2. Check for RLS policies on orders that might be causing issues
SELECT 'RLS policies on orders table:' as info;
SELECT 
    pol.polname as policy_name,
    pol.polcmd as command,
    pol.polqual as using_expression,
    pol.polwithcheck as with_check_expression
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'orders'
  AND pc.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 3. Check for any functions that might reference "rejected"
SELECT 'Functions mentioning rejected:' as info;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_definition ILIKE '%rejected%'
  AND routine_schema = 'public'
  AND routine_name NOT LIKE 'pg_%';

-- 4. Test the exact update that's failing
SELECT 'Testing the exact update:' as info;
BEGIN;

-- Try the exact same update
UPDATE orders 
SET farmer_status = 'toPack',
    updated_at = NOW()
WHERE id = '6464dba3-730b-4263-93d7-bd3006cc72e0';

-- Check if it worked
SELECT farmer_status, updated_at 
FROM orders 
WHERE id = '6464dba3-730b-4263-93d7-bd3006cc72e0';

ROLLBACK; -- Don't commit, just test

-- 5. Check if there are any check constraints on farmer_status
SELECT 'Check constraints on orders table:' as info;
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public'
  AND constraint_name IN (
    SELECT constraint_name 
    FROM information_schema.constraint_column_usage 
    WHERE table_name = 'orders' 
    AND column_name = 'farmer_status'
  );

-- 6. Look for any computed columns or generated columns
SELECT 'Orders table column details:' as info;
SELECT 
    column_name,
    data_type,
    column_default,
    is_generated,
    generation_expression
FROM information_schema.columns 
WHERE table_name = 'orders' 
  AND table_schema = 'public'
  AND column_name = 'farmer_status';