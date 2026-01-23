-- Simple fix to resolve the "rejected" enum error for farmer_order_status

-- 1. First, let's see what the current farmer_order_status enum contains
SELECT 'Current farmer_order_status enum:' as info;
SELECT string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 2. Add 'accepted' if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'accepted' AND enumtypid = 'farmer_order_status'::regtype) THEN
        ALTER TYPE farmer_order_status ADD VALUE 'accepted' AFTER 'newOrder';
        RAISE NOTICE 'Added accepted to farmer_order_status enum';
    ELSE
        RAISE NOTICE 'accepted already exists in farmer_order_status enum';
    END IF;
END $$;

-- 3. Check if 'rejected' somehow got into farmer_order_status (it shouldn't be there)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'rejected' AND enumtypid = 'farmer_order_status'::regtype) THEN
        RAISE NOTICE 'ERROR: rejected found in farmer_order_status enum - this should not be there!';
        -- Update any orders using rejected to cancelled
        UPDATE orders SET farmer_status = 'cancelled' WHERE farmer_status = 'rejected';
        RAISE NOTICE 'Updated orders with rejected status to cancelled';
    ELSE
        RAISE NOTICE 'Good: rejected is NOT in farmer_order_status enum';
    END IF;
END $$;

-- 4. Show final farmer_order_status enum
SELECT 'Final farmer_order_status enum:' as info;
SELECT string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 5. Show farmer_verifications status values for comparison
SELECT 'farmer_verifications statuses (should include rejected):' as info;
SELECT DISTINCT verification_status
FROM farmer_verifications
ORDER BY verification_status;

-- 6. Test the enum by trying to insert a valid status
BEGIN;
CREATE TEMP TABLE test_order_status AS 
SELECT 'accepted'::farmer_order_status as test_status;
SELECT 'Test successful: accepted status works' as result;
ROLLBACK;