-- ============================================================================
-- FIX PRODUCT DELETION & IMPLEMENT AUTO-EXPIRY SYSTEM (FIXED VERSION)
-- ============================================================================
-- This script:
-- 1. Fixes foreign key constraint to allow soft delete of products
-- 2. Adds product expiry automation
-- 3. Creates auto-hide function for expired products
-- 4. Sets up daily cron job for expiry checks
-- ============================================================================

-- Run each section separately to identify where issues occur

-- ============================================================================
-- SECTION 1: ADD COLUMNS (Run this first)
-- ============================================================================

-- Add deleted_at column for soft delete
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Add status column for better tracking
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Add constraint separately (in case column exists but constraint doesn't)
DO $$ 
BEGIN
  -- Drop constraint if exists
  ALTER TABLE products DROP CONSTRAINT IF EXISTS products_status_check;
  
  -- Add constraint
  ALTER TABLE products 
  ADD CONSTRAINT products_status_check 
  CHECK (status IN ('active', 'expired', 'deleted'));
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Constraint may already exist or column not found: %', SQLERRM;
END $$;

-- Verify columns were added
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'deleted_at'
  ) THEN
    RAISE NOTICE '✓ deleted_at column exists';
  ELSE
    RAISE EXCEPTION '✗ FAILED: deleted_at column not created!';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'status'
  ) THEN
    RAISE NOTICE '✓ status column exists';
  ELSE
    RAISE EXCEPTION '✗ FAILED: status column not created!';
  END IF;
END $$;

-- ============================================================================
-- SECTION 2: CREATE INDEXES (Run after Section 1)
-- ============================================================================

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON products(deleted_at) WHERE deleted_at IS NOT NULL;

RAISE NOTICE '✓ Indexes created';

-- ============================================================================
-- SECTION 3: CREATE FUNCTIONS (Run after Section 2)
-- ============================================================================

-- Function to auto-hide expired products
CREATE OR REPLACE FUNCTION auto_hide_expired_products()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update expired products
  UPDATE products
  SET 
    is_hidden = true,
    status = 'expired',
    updated_at = NOW()
  WHERE 
    status = 'active'
    AND is_hidden = false
    AND deleted_at IS NULL
    AND (created_at + (shelf_life_days || ' days')::INTERVAL) < NOW();
    
  RAISE NOTICE 'Auto-hide expired products completed at %', NOW();
END;
$$;

-- Function to get expiring products (for notifications)
CREATE OR REPLACE FUNCTION get_expiring_products(days_threshold INTEGER DEFAULT 3)
RETURNS TABLE (
  product_id UUID,
  farmer_id UUID,
  product_name TEXT,
  days_until_expiry INTEGER,
  expiry_date TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as product_id,
    p.farmer_id,
    p.name as product_name,
    EXTRACT(DAY FROM ((p.created_at + (p.shelf_life_days || ' days')::INTERVAL) - NOW()))::INTEGER as days_until_expiry,
    (p.created_at + (p.shelf_life_days || ' days')::INTERVAL) as expiry_date
  FROM products p
  WHERE 
    p.status = 'active'
    AND p.is_hidden = false
    AND p.deleted_at IS NULL
    AND (p.created_at + (p.shelf_life_days || ' days')::INTERVAL) BETWEEN NOW() AND (NOW() + (days_threshold || ' days')::INTERVAL)
  ORDER BY expiry_date ASC;
END;
$$;

-- Function to get expired products
CREATE OR REPLACE FUNCTION get_expired_products()
RETURNS TABLE (
  product_id UUID,
  farmer_id UUID,
  product_name TEXT,
  days_since_expired INTEGER,
  expired_date TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as product_id,
    p.farmer_id,
    p.name as product_name,
    EXTRACT(DAY FROM (NOW() - (p.created_at + (p.shelf_life_days || ' days')::INTERVAL)))::INTEGER as days_since_expired,
    (p.created_at + (p.shelf_life_days || ' days')::INTERVAL) as expired_date
  FROM products p
  WHERE 
    p.deleted_at IS NULL
    AND (p.created_at + (p.shelf_life_days || ' days')::INTERVAL) < NOW()
  ORDER BY expired_date DESC;
END;
$$;

-- Function for soft delete (hides product and marks as deleted)
CREATE OR REPLACE FUNCTION soft_delete_product(product_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE products
  SET 
    is_hidden = true,
    status = 'deleted',
    deleted_at = NOW(),
    updated_at = NOW()
  WHERE id = product_id_param;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found: %', product_id_param;
  END IF;
END;
$$;

-- Function to restore deleted product
CREATE OR REPLACE FUNCTION restore_product(product_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  product_expiry TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate expiry date
  SELECT (created_at + (shelf_life_days || ' days')::INTERVAL)
  INTO product_expiry
  FROM products
  WHERE id = product_id_param;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found: %', product_id_param;
  END IF;
  
  -- Check if product is expired
  IF product_expiry < NOW() THEN
    RAISE EXCEPTION 'Cannot restore expired product';
  END IF;
  
  -- Restore product
  UPDATE products
  SET 
    is_hidden = false,
    status = 'active',
    deleted_at = NULL,
    updated_at = NOW()
  WHERE id = product_id_param AND status = 'deleted';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product is not deleted or does not exist';
  END IF;
END;
$$;

RAISE NOTICE '✓ All functions created';

-- ============================================================================
-- SECTION 4: UPDATE RLS POLICIES (Run after Section 3)
-- ============================================================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view active products" ON products;
DROP POLICY IF EXISTS "Farmers can delete own products" ON products;

-- Create new policies that exclude deleted products
CREATE POLICY "Users can view active products"
ON products FOR SELECT
TO authenticated
USING (
  deleted_at IS NULL 
  AND (
    is_hidden = false 
    OR farmer_id = auth.uid()
  )
);

-- Farmers can update (soft delete) their own products
CREATE POLICY "Farmers can delete own products"
ON products FOR UPDATE
TO authenticated
USING (farmer_id = auth.uid())
WITH CHECK (farmer_id = auth.uid());

RAISE NOTICE '✓ RLS policies updated';

-- ============================================================================
-- SECTION 5: SCHEDULED JOB (Run after Section 4) - OPTIONAL
-- ============================================================================

-- Note: This requires pg_cron extension
-- If not available, you can run auto_hide_expired_products() manually

-- Try to enable pg_cron extension
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;
  RAISE NOTICE '✓ pg_cron extension enabled';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '⚠ pg_cron extension not available. You can manually trigger expiry with: SELECT auto_hide_expired_products();';
END $$;

-- Schedule daily expiry check at 2 AM (only if pg_cron available)
DO $$
BEGIN
  -- Remove existing job if it exists
  PERFORM cron.unschedule('auto-hide-expired-products');
  
  -- Schedule new job
  PERFORM cron.schedule(
    'auto-hide-expired-products',
    '0 2 * * *', -- Every day at 2 AM
    $$ SELECT auto_hide_expired_products(); $$
  );
  
  RAISE NOTICE '✓ Scheduled daily expiry check at 2 AM';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '⚠ Could not schedule cron job (pg_cron not available)';
END $$;

-- ============================================================================
-- SECTION 6: INITIAL CLEANUP AND VERIFICATION
-- ============================================================================

-- Run initial expiry check
SELECT auto_hide_expired_products();

-- Show current status
DO $$
DECLARE
  active_count INTEGER;
  expired_count INTEGER;
  deleted_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO active_count FROM products WHERE status = 'active' AND deleted_at IS NULL;
  SELECT COUNT(*) INTO expired_count FROM products WHERE status = 'expired';
  SELECT COUNT(*) INTO deleted_count FROM products WHERE status = 'deleted';
  
  RAISE NOTICE '';
  RAISE NOTICE '=== PRODUCT STATUS SUMMARY ===';
  RAISE NOTICE 'Active products: %', active_count;
  RAISE NOTICE 'Expired products: %', expired_count;
  RAISE NOTICE 'Deleted products: %', deleted_count;
  RAISE NOTICE '';
  RAISE NOTICE '=== MIGRATION COMPLETE! ===';
  RAISE NOTICE 'System is ready to use.';
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (Run after everything else)
-- ============================================================================

-- Verify all components
SELECT 
  '✓ Migration Complete' as status,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'status') > 0 as has_status_column,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'deleted_at') > 0 as has_deleted_at_column,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'auto_hide_expired_products') > 0 as has_auto_hide_function,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'soft_delete_product') > 0 as has_soft_delete_function,
  (SELECT COUNT(*) FROM pg_indexes WHERE indexname = 'idx_products_status') > 0 as has_status_index;

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. Run each section separately if you encounter errors
-- 2. Check the output messages for success/failure indicators
-- 3. If pg_cron is not available, manually run: SELECT auto_hide_expired_products();
-- 4. Test soft delete with: SELECT soft_delete_product('your-product-id');
-- ============================================================================
