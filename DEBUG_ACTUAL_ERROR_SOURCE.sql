-- Debug the actual source of the "rejected" error since the enum is correct

-- 1. Check if there are any orders currently with invalid farmer_status
SELECT 'Orders with invalid farmer_status:' as info;
SELECT id, farmer_id, buyer_id, farmer_status, buyer_status, created_at
FROM orders 
WHERE farmer_status NOT IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled')
LIMIT 10;

-- 2. Check recent order updates (if there's an updated_at column)
SELECT 'Recent orders:' as info;
SELECT id, farmer_id, buyer_id, farmer_status, buyer_status, created_at, 
       COALESCE(updated_at, created_at) as last_modified
FROM orders 
ORDER BY COALESCE(updated_at, created_at) DESC 
LIMIT 5;

-- 3. Check if there are any problematic order_items
SELECT 'Check order_items table:' as info;
SELECT COUNT(*) as total_items
FROM order_items;

-- 4. Look for any views or computed columns that might be causing issues
SELECT 'Views that might reference orders:' as info;
SELECT table_name, view_definition
FROM information_schema.views 
WHERE view_definition ILIKE '%farmer_status%' 
   OR view_definition ILIKE '%rejected%';

-- 5. Check for any recent database activity that might give us clues
SELECT 'Database activity on orders:' as info;
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables 
WHERE tablename IN ('orders', 'order_items', 'farmer_verifications');

-- 6. Test a simple update on orders table to see if it works
BEGIN;
-- Create a test order if none exist
INSERT INTO orders (id, buyer_id, farmer_id, total_amount, delivery_address, farmer_status, buyer_status, created_at)
VALUES 
('test-order-123', 
 (SELECT id FROM profiles WHERE role = 'buyer' LIMIT 1),
 (SELECT id FROM profiles WHERE role = 'farmer' LIMIT 1),
 100.00,
 'Test Address',
 'newOrder',
 'pending',
 NOW())
ON CONFLICT (id) DO NOTHING;

-- Try updating the status
UPDATE orders 
SET farmer_status = 'accepted' 
WHERE id = 'test-order-123';

SELECT 'Test update result:' as info, farmer_status 
FROM orders 
WHERE id = 'test-order-123';

-- Clean up test
DELETE FROM orders WHERE id = 'test-order-123';
ROLLBACK;