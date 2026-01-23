-- Debug script to find where "rejected" status is coming from

-- 1. Check current enum values for farmer_order_status
SELECT 'Current farmer_order_status enum values:' as info, 
       string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 2. Check if there are any orders with 'rejected' status
SELECT 'Orders with rejected status:' as info;
SELECT id, farmer_id, buyer_id, farmer_status, buyer_status, created_at
FROM orders 
WHERE farmer_status = 'rejected' OR buyer_status = 'rejected';

-- 3. Check if there's any trigger or function using 'rejected'
SELECT 'Functions/triggers containing rejected:' as info;
SELECT routine_name, routine_type, routine_definition
FROM information_schema.routines
WHERE routine_definition ILIKE '%rejected%';

-- 4. Remove 'rejected' from enum if it exists (this will fail if it doesn't exist, which is fine)
-- First, let's add the missing 'accepted' value if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'accepted' AND enumtypid = 'farmer_order_status'::regtype) THEN
        ALTER TYPE farmer_order_status ADD VALUE 'accepted' AFTER 'newOrder';
    END IF;
END $$;

-- Then remove 'rejected' if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'rejected' AND enumtypid = 'farmer_order_status'::regtype) THEN
        -- First update any orders with rejected status
        UPDATE orders SET farmer_status = 'cancelled' WHERE farmer_status = 'rejected';
        -- Then remove the enum value (this might fail in some PostgreSQL versions)
        -- ALTER TYPE farmer_order_status DROP VALUE 'rejected';
        -- If the above fails, just leave it and clean the data
    END IF;
END $$;

-- 5. Clean up any orders with invalid status
UPDATE orders 
SET farmer_status = 'cancelled'
WHERE farmer_status NOT IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled');

-- 6. Show final status distribution
SELECT 'Final order status distribution:' as info;
SELECT farmer_status, COUNT(*) as count
FROM orders 
GROUP BY farmer_status
ORDER BY count DESC;