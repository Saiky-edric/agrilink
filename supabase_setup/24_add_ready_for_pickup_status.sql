-- ============================================================================
-- Migration: Add 'readyForPickup' status to farmer_order_status enum
-- Date: 2025-01-24
-- Description: Adds the readyForPickup status for pickup orders workflow
-- ============================================================================

-- Check current enum values
SELECT 'Current farmer_order_status enum values:' as info;
SELECT enumlabel as status, enumsortorder as order_num
FROM pg_enum
WHERE enumtypid = 'farmer_order_status'::regtype
ORDER BY enumsortorder;

-- ============================================================================
-- Add 'readyForPickup' to farmer_order_status enum
-- ============================================================================

DO $$
BEGIN
    -- Check if 'readyForPickup' already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'readyForPickup' 
        AND enumtypid = 'farmer_order_status'::regtype
    ) THEN
        -- Add 'readyForPickup' after 'toDeliver' and before 'completed'
        ALTER TYPE farmer_order_status ADD VALUE 'readyForPickup' AFTER 'toDeliver';
        RAISE NOTICE '✅ Added readyForPickup to farmer_order_status enum';
    ELSE
        RAISE NOTICE 'ℹ️ readyForPickup already exists in farmer_order_status enum';
    END IF;
END $$;

-- ============================================================================
-- Verify the update
-- ============================================================================

SELECT 'Updated farmer_order_status enum values:' as info;
SELECT enumlabel as status, enumsortorder as order_num
FROM pg_enum
WHERE enumtypid = 'farmer_order_status'::regtype
ORDER BY enumsortorder;

-- ============================================================================
-- Test the enum value
-- ============================================================================

-- This should work without errors now
SELECT 'readyForPickup'::farmer_order_status as test_status;

RAISE NOTICE '';
RAISE NOTICE '✅ Migration complete: readyForPickup status added';
RAISE NOTICE '';
RAISE NOTICE '📋 Updated farmer_order_status workflow:';
RAISE NOTICE '   1. newOrder → Order received';
RAISE NOTICE '   2. accepted → Farmer accepted order';
RAISE NOTICE '   3. toPack → Farmer is packing order';
RAISE NOTICE '   4. toDeliver → Order ready for delivery (delivery orders)';
RAISE NOTICE '   5. readyForPickup → Order ready for customer pickup (pickup orders) ⭐ NEW';
RAISE NOTICE '   6. completed → Order completed';
RAISE NOTICE '   7. cancelled → Order cancelled';
RAISE NOTICE '';
