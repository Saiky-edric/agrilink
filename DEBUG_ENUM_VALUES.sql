-- Debug script to check current enum values and fix any issues

-- 1. Check current farmer_order_status enum values
SELECT 'Current farmer_order_status enum values:' as info, 
       string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 2. Check current buyer_order_status enum values  
SELECT 'Current buyer_order_status enum values:' as info,
       string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'buyer_order_status'::regtype;

-- 3. Check if there are any orders with invalid status values
SELECT DISTINCT farmer_status, COUNT(*) as count
FROM orders 
GROUP BY farmer_status;

SELECT DISTINCT buyer_status, COUNT(*) as count
FROM orders 
GROUP BY buyer_status;

-- 4. If you need to add 'accepted' to the enum (but this should not be necessary)
-- Uncomment only if you want to add it:
-- ALTER TYPE farmer_order_status ADD VALUE 'accepted' AFTER 'newOrder';

-- 5. If there are orders with 'accepted' status, update them to proper values
UPDATE orders 
SET farmer_status = 'toPack'
WHERE farmer_status = 'accepted';

-- 6. Verify the fix
SELECT 'Orders after fix:' as info;
SELECT DISTINCT farmer_status, COUNT(*) as count
FROM orders 
GROUP BY farmer_status;