-- Quick check of current order statuses to find the "rejected" issue

-- 1. Check all distinct farmer_status values currently in orders table
SELECT 'All farmer_status values in orders:' as info;
SELECT DISTINCT farmer_status, COUNT(*) as count
FROM orders 
GROUP BY farmer_status
ORDER BY count DESC;

-- 2. Recent orders with their statuses
SELECT 'Recent orders:' as info;
SELECT id, farmer_id, buyer_id, farmer_status, buyer_status, created_at, 
       COALESCE(updated_at, created_at) as last_modified
FROM orders 
ORDER BY COALESCE(updated_at, created_at) DESC 
LIMIT 5;

-- 3. Look for any orders that might have problematic status
SELECT 'Problematic orders:' as info;
SELECT id, farmer_status, buyer_status, created_at
FROM orders 
WHERE farmer_status NOT IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled');

-- 4. Check the specific order you're trying to update (most recent one)
SELECT 'Most recent order details:' as info;
SELECT id, farmer_status, buyer_status, total_amount, delivery_address, created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 1;