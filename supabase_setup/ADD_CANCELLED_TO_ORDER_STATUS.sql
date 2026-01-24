-- =============================================
-- ADD CANCELLED STATUS TO ORDER ENUMS
-- =============================================
-- Problem: Code uses 'cancelled' status but database enums don't have it
-- Error: "invalid input value for enum farmer_order_status: cancelled"
-- =============================================

BEGIN;

-- Add 'cancelled' to farmer_order_status enum if not exists
DO $$ 
BEGIN
    -- Check if cancelled already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'cancelled' 
        AND enumtypid = (
            SELECT oid FROM pg_type WHERE typname = 'farmer_order_status'
        )
    ) THEN
        -- Add cancelled to farmer_order_status
        ALTER TYPE farmer_order_status ADD VALUE 'cancelled';
        RAISE NOTICE '✅ Added cancelled to farmer_order_status enum';
    ELSE
        RAISE NOTICE 'ℹ️ cancelled already exists in farmer_order_status';
    END IF;
END $$;

-- Add 'cancelled' to buyer_order_status enum if not exists
DO $$ 
BEGIN
    -- Check if cancelled already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'cancelled' 
        AND enumtypid = (
            SELECT oid FROM pg_type WHERE typname = 'buyer_order_status'
        )
    ) THEN
        -- Add cancelled to buyer_order_status
        ALTER TYPE buyer_order_status ADD VALUE 'cancelled';
        RAISE NOTICE '✅ Added cancelled to buyer_order_status enum';
    ELSE
        RAISE NOTICE 'ℹ️ cancelled already exists in buyer_order_status';
    END IF;
END $$;

COMMIT;

-- =============================================
-- VERIFICATION
-- =============================================

-- Show all farmer_order_status enum values
SELECT 
    'farmer_order_status' as enum_type,
    enumlabel as value,
    enumsortorder as sort_order
FROM pg_enum
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'farmer_order_status')
ORDER BY enumsortorder;

-- Show all buyer_order_status enum values
SELECT 
    'buyer_order_status' as enum_type,
    enumlabel as value,
    enumsortorder as sort_order
FROM pg_enum
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'buyer_order_status')
ORDER BY enumsortorder;

-- Test that cancelled is now valid
DO $$
BEGIN
    RAISE NOTICE '✅ Order status enums updated successfully!';
    RAISE NOTICE '📋 farmer_order_status now includes: cancelled';
    RAISE NOTICE '📋 buyer_order_status now includes: cancelled';
    RAISE NOTICE '✅ Order cancellation should now work!';
END $$;
