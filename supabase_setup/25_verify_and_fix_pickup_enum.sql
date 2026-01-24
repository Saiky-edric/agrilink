-- ============================================================================
-- Verification and Fix: Check and add 'readyForPickup' to farmer_order_status
-- Date: 2025-01-24
-- Description: Comprehensive check and fix for pickup order status enum
-- ============================================================================

-- ============================================================================
-- STEP 1: Check current enum values
-- ============================================================================

SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '📋 CURRENT ENUM STATUS CHECK' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

-- Check buyer_order_status enum
SELECT '' as blank;
SELECT '🔍 buyer_order_status enum values:' as info;
SELECT enumlabel as status, enumsortorder as order_num
FROM pg_enum
WHERE enumtypid = 'buyer_order_status'::regtype
ORDER BY enumsortorder;

-- Check farmer_order_status enum
SELECT '' as blank;
SELECT '🔍 farmer_order_status enum values:' as info;
SELECT enumlabel as status, enumsortorder as order_num
FROM pg_enum
WHERE enumtypid = 'farmer_order_status'::regtype
ORDER BY enumsortorder;

-- ============================================================================
-- STEP 2: Check if readyForPickup already exists
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '🔍 CHECKING FOR readyForPickup STATUS' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

DO $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'readyForPickup' 
        AND enumtypid = 'farmer_order_status'::regtype
    ) INTO v_exists;
    
    IF v_exists THEN
        RAISE NOTICE '✅ readyForPickup ALREADY EXISTS in farmer_order_status enum';
        RAISE NOTICE 'ℹ️  No action needed - enum is already correct';
    ELSE
        RAISE NOTICE '❌ readyForPickup DOES NOT EXIST in farmer_order_status enum';
        RAISE NOTICE '🔧 Will add it in next step...';
    END IF;
END $$;

-- ============================================================================
-- STEP 3: Add readyForPickup if it doesn't exist
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '🔧 ADDING readyForPickup TO ENUM (if needed)' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

DO $$
BEGIN
    -- Check if 'readyForPickup' already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'readyForPickup' 
        AND enumtypid = 'farmer_order_status'::regtype
    ) THEN
        -- Add 'readyForPickup' between 'toDeliver' and 'completed'
        -- This is a safe operation and doesn't affect existing data
        ALTER TYPE farmer_order_status ADD VALUE 'readyForPickup' AFTER 'toDeliver';
        
        RAISE NOTICE '✅ SUCCESS: Added readyForPickup to farmer_order_status enum';
        RAISE NOTICE '';
        RAISE NOTICE '📋 Status Order:';
        RAISE NOTICE '   1. newOrder';
        RAISE NOTICE '   2. accepted';
        RAISE NOTICE '   3. toPack';
        RAISE NOTICE '   4. toDeliver';
        RAISE NOTICE '   5. readyForPickup ⭐ (NEW - for pickup orders)';
        RAISE NOTICE '   6. completed';
        RAISE NOTICE '   7. cancelled';
    ELSE
        RAISE NOTICE 'ℹ️  SKIPPED: readyForPickup already exists in farmer_order_status enum';
        RAISE NOTICE '✅ No changes needed - enum is correct';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Verify the final state
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '✅ FINAL VERIFICATION' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT '' as blank;
SELECT '🎯 farmer_order_status enum (FINAL):' as info;
SELECT 
    enumlabel as status, 
    enumsortorder as order_num,
    CASE 
        WHEN enumlabel = 'readyForPickup' THEN '⭐ NEW'
        ELSE ''
    END as notes
FROM pg_enum
WHERE enumtypid = 'farmer_order_status'::regtype
ORDER BY enumsortorder;

-- ============================================================================
-- STEP 5: Test that the enum value works
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '🧪 TESTING ENUM VALUE' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

-- This should work without errors now
DO $$
DECLARE
    test_status farmer_order_status;
BEGIN
    -- Test casting
    test_status := 'readyForPickup'::farmer_order_status;
    RAISE NOTICE '✅ TEST PASSED: Can cast ''readyForPickup'' to farmer_order_status';
    RAISE NOTICE '   Result: %', test_status;
END $$;

-- ============================================================================
-- STEP 6: Check existing orders table compatibility
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '📊 ORDERS TABLE COMPATIBILITY CHECK' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT '' as blank;
SELECT '🔍 Checking orders table structure...' as info;

-- Check if orders table has pickup-related columns
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_method') THEN '✅'
        ELSE '❌'
    END || ' delivery_method column' as check_result
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'pickup_address') THEN '✅'
        ELSE '❌'
    END || ' pickup_address column'
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'pickup_instructions') THEN '✅'
        ELSE '❌'
    END || ' pickup_instructions column'
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'pickup_location_id') THEN '✅'
        ELSE '❌'
    END || ' pickup_location_id column'
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'farmer_status') THEN '✅'
        ELSE '❌'
    END || ' farmer_status column';

-- Check current pickup orders
SELECT '' as blank;
SELECT '🔍 Current pickup orders in database:' as info;
SELECT 
    COUNT(*) as total_pickup_orders,
    COUNT(*) FILTER (WHERE farmer_status = 'newOrder') as new_orders,
    COUNT(*) FILTER (WHERE farmer_status = 'accepted') as accepted_orders,
    COUNT(*) FILTER (WHERE farmer_status = 'toPack') as packing_orders,
    COUNT(*) FILTER (WHERE farmer_status = 'toDeliver') as to_deliver,
    COUNT(*) FILTER (WHERE farmer_status = 'completed') as completed_orders
FROM orders 
WHERE delivery_method = 'pickup';

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

SELECT '' as blank;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
SELECT '🎉 MIGRATION COMPLETE!' as info;
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT '' as blank;
RAISE NOTICE '';
RAISE NOTICE '✅ Migration completed successfully!';
RAISE NOTICE '';
RAISE NOTICE '📋 Next Steps:';
RAISE NOTICE '   1. Restart your Flutter app';
RAISE NOTICE '   2. Test creating a pickup order';
RAISE NOTICE '   3. Try marking pickup order as "Ready for Pick-up"';
RAISE NOTICE '   4. Verify no enum errors occur';
RAISE NOTICE '';
RAISE NOTICE '🔄 Order Status Workflows:';
RAISE NOTICE '';
RAISE NOTICE '   Delivery Orders:';
RAISE NOTICE '   newOrder → accepted → toPack → toDeliver → completed';
RAISE NOTICE '';
RAISE NOTICE '   Pickup Orders:';
RAISE NOTICE '   newOrder → accepted → toPack → readyForPickup → completed';
RAISE NOTICE '                                         ↑';
RAISE NOTICE '                                    NOW AVAILABLE';
RAISE NOTICE '';
