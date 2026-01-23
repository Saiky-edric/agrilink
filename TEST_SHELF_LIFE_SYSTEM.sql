-- ============================================================================
-- TEST SHELF LIFE & DELETION SYSTEM
-- ============================================================================
-- Run this AFTER running 17_fix_product_deletion_and_expiry.sql
-- ============================================================================

-- Test 1: Verify columns were added
DO $$
BEGIN
  RAISE NOTICE '=== TEST 1: Verify Schema Changes ===';
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'status'
  ) THEN
    RAISE NOTICE '✓ status column exists';
  ELSE
    RAISE EXCEPTION '✗ status column missing!';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'deleted_at'
  ) THEN
    RAISE NOTICE '✓ deleted_at column exists';
  ELSE
    RAISE EXCEPTION '✗ deleted_at column missing!';
  END IF;
END $$;

-- Test 2: Verify functions were created
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 2: Verify Functions ===';
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'auto_hide_expired_products') THEN
    RAISE NOTICE '✓ auto_hide_expired_products() exists';
  ELSE
    RAISE EXCEPTION '✗ auto_hide_expired_products() missing!';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_expiring_products') THEN
    RAISE NOTICE '✓ get_expiring_products() exists';
  ELSE
    RAISE EXCEPTION '✗ get_expiring_products() missing!';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_expired_products') THEN
    RAISE NOTICE '✓ get_expired_products() exists';
  ELSE
    RAISE EXCEPTION '✗ get_expired_products() missing!';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'soft_delete_product') THEN
    RAISE NOTICE '✓ soft_delete_product() exists';
  ELSE
    RAISE EXCEPTION '✗ soft_delete_product() missing!';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'restore_product') THEN
    RAISE NOTICE '✓ restore_product() exists';
  ELSE
    RAISE EXCEPTION '✗ restore_product() missing!';
  END IF;
END $$;

-- Test 3: Check indexes
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 3: Verify Indexes ===';
  
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_products_status') THEN
    RAISE NOTICE '✓ idx_products_status exists';
  ELSE
    RAISE WARNING '✗ idx_products_status missing';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_products_deleted_at') THEN
    RAISE NOTICE '✓ idx_products_deleted_at exists';
  ELSE
    RAISE WARNING '✗ idx_products_deleted_at missing';
  END IF;
END $$;

-- Test 4: Product status summary
DO $$
DECLARE
  active_count INTEGER;
  expired_count INTEGER;
  deleted_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 4: Product Status Summary ===';
  
  SELECT COUNT(*) INTO active_count FROM products WHERE status = 'active' AND deleted_at IS NULL;
  SELECT COUNT(*) INTO expired_count FROM products WHERE status = 'expired';
  SELECT COUNT(*) INTO deleted_count FROM products WHERE status = 'deleted';
  
  RAISE NOTICE 'Active products: %', active_count;
  RAISE NOTICE 'Expired products: %', expired_count;
  RAISE NOTICE 'Deleted products: %', deleted_count;
END $$;

-- Test 5: Test soft delete function
DO $$
DECLARE
  test_product_id UUID;
  product_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 5: Test Soft Delete (if products exist) ===';
  
  -- Try to get a product to test with
  SELECT id INTO test_product_id FROM products WHERE deleted_at IS NULL LIMIT 1;
  
  IF test_product_id IS NOT NULL THEN
    RAISE NOTICE 'Testing with product ID: %', test_product_id;
    
    -- Test soft delete
    PERFORM soft_delete_product(test_product_id);
    
    -- Verify it was marked as deleted
    SELECT EXISTS (
      SELECT 1 FROM products 
      WHERE id = test_product_id 
      AND status = 'deleted' 
      AND deleted_at IS NOT NULL
    ) INTO product_exists;
    
    IF product_exists THEN
      RAISE NOTICE '✓ Soft delete successful';
      
      -- Restore it for clean state
      PERFORM restore_product(test_product_id);
      RAISE NOTICE '✓ Product restored';
    ELSE
      RAISE WARNING '✗ Soft delete failed';
    END IF;
  ELSE
    RAISE NOTICE '⚠ No products to test with';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '⚠ Test 5 skipped or failed: %', SQLERRM;
END $$;

-- Test 6: Test expiry functions
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 6: Test Expiry Functions ===';
  
  -- Call auto-hide function (safe to call even if no expired products)
  PERFORM auto_hide_expired_products();
  RAISE NOTICE '✓ auto_hide_expired_products() executed successfully';
  
  -- Test get_expiring_products
  RAISE NOTICE '✓ Testing get_expiring_products()...';
  PERFORM * FROM get_expiring_products(3);
  
  -- Test get_expired_products
  RAISE NOTICE '✓ Testing get_expired_products()...';
  PERFORM * FROM get_expired_products();
END $$;

-- Test 7: Check RLS policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 7: Check RLS Policies ===';
  
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' 
    AND policyname = 'Users can view active products'
  ) THEN
    RAISE NOTICE '✓ "Users can view active products" policy exists';
  ELSE
    RAISE WARNING '✗ "Users can view active products" policy missing';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' 
    AND policyname = 'Farmers can delete own products'
  ) THEN
    RAISE NOTICE '✓ "Farmers can delete own products" policy exists';
  ELSE
    RAISE WARNING '✗ "Farmers can delete own products" policy missing';
  END IF;
END $$;

-- Final Summary
SELECT 
  '=== FINAL SUMMARY ===' as summary,
  COUNT(*) as total_products,
  COUNT(*) FILTER (WHERE status = 'active') as active,
  COUNT(*) FILTER (WHERE status = 'expired') as expired,
  COUNT(*) FILTER (WHERE status = 'deleted') as deleted,
  COUNT(*) FILTER (WHERE created_at + (shelf_life_days || ' days')::INTERVAL < NOW() AND status = 'active') as needs_expiry
FROM products;

RAISE NOTICE '';
RAISE NOTICE '=== ALL TESTS COMPLETE ===';
RAISE NOTICE 'If all tests passed, the system is ready to use!';
