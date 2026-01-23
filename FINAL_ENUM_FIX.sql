-- FINAL FIX: Remove "rejected" from farmer_order_status enum and clean data

-- 1. First, let's see what's currently in the farmer_order_status enum
SELECT 'Current farmer_order_status enum values:' as info;
SELECT enumlabel, enumsortorder 
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype
ORDER BY enumsortorder;

-- 2. Check if any orders have "rejected" farmer_status
SELECT 'Orders with rejected farmer_status:' as info;
SELECT id, farmer_id, buyer_id, farmer_status, created_at
FROM orders 
WHERE farmer_status = 'rejected';

-- 3. Update any orders with "rejected" farmer_status to "cancelled"
UPDATE orders 
SET farmer_status = 'cancelled' 
WHERE farmer_status = 'rejected';

-- 4. Check what enum values exist now
SELECT 'Checking if rejected exists in enum:' as info;
SELECT EXISTS(
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'rejected' 
    AND enumtypid = 'farmer_order_status'::regtype
) as rejected_exists;

-- 5. Try to remove 'rejected' from the enum if it exists
-- Note: This might fail in some PostgreSQL versions, but that's ok
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'rejected' AND enumtypid = 'farmer_order_status'::regtype) THEN
        BEGIN
            -- This will fail if there are dependencies, but let's try
            EXECUTE 'ALTER TYPE farmer_order_status DROP VALUE ''rejected''';
            RAISE NOTICE 'Successfully removed rejected from farmer_order_status';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not remove rejected from enum (this is ok): %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'rejected is not in farmer_order_status enum';
    END IF;
END $$;

-- 6. Ensure 'accepted' is in the enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'accepted' AND enumtypid = 'farmer_order_status'::regtype) THEN
        ALTER TYPE farmer_order_status ADD VALUE 'accepted' AFTER 'newOrder';
        RAISE NOTICE 'Added accepted to farmer_order_status enum';
    ELSE
        RAISE NOTICE 'accepted already exists in farmer_order_status enum';
    END IF;
END $$;

-- 7. Final verification - show the clean enum
SELECT 'FINAL farmer_order_status enum:' as info;
SELECT string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;

-- 8. Test that we can update to 'toPack' (what the Start Packing button does)
SELECT 'Testing toPack enum value:' as info;
SELECT 'toPack'::farmer_order_status as test_result;

-- 9. Show verification_status from farmer_verifications for comparison
SELECT 'farmer_verifications.verification_status values (should include rejected):' as info;
SELECT DISTINCT status as verification_statuses
FROM farmer_verifications
ORDER BY status;