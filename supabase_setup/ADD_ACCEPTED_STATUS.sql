-- Add 'accepted' status to farmer_order_status enum
-- Run this in your Supabase SQL Editor

-- Add the 'accepted' value to the farmer_order_status enum
ALTER TYPE farmer_order_status ADD VALUE 'accepted' AFTER 'newOrder';

-- Verify the enum was updated correctly
SELECT 'Updated farmer_order_status enum values:' as info, 
       string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- Optional: Update any existing orders that might have invalid status
-- This will clean up any data inconsistencies
UPDATE orders 
SET farmer_status = 'accepted'
WHERE farmer_status NOT IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled');

-- Show current order status distribution
SELECT 'Current order status distribution:' as info;
SELECT farmer_status, COUNT(*) as count
FROM orders 
GROUP BY farmer_status
ORDER BY count DESC;