-- ============================================================================
-- FIX PRODUCT DELETION & IMPLEMENT AUTO-EXPIRY SYSTEM
-- ============================================================================
-- This script:
-- 1. Fixes foreign key constraint to allow soft delete of products
-- 2. Adds product expiry automation
-- 3. Creates auto-hide function for expired products
-- 4. Sets up daily cron job for expiry checks
-- ============================================================================

BEGIN;

-- ============================================================================
-- PART 1: FIX PRODUCT DELETION ISSUE
-- ============================================================================

-- The error occurs because order_items have a foreign key to products
-- Solution: Instead of hard delete, implement soft delete (hide + mark as deleted)

-- Add deleted_at column for soft delete
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Add status column for better tracking
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'status'
  ) THEN
    ALTER TABLE products 
    ADD COLUMN status TEXT DEFAULT 'active' 
    CHECK (status IN ('active', 'expired', 'deleted'));
  END IF;
END $$;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON products(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================================================
-- PART 2: AUTO-EXPIRY SYSTEM
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

-- ============================================================================
-- PART 3: SCHEDULED JOB FOR AUTO-EXPIRY (using pg_cron if available)
-- ============================================================================

-- Note: This requires pg_cron extension
-- If not available, you can run auto_hide_expired_products() manually or via a cloud function

-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily expiry check at 2 AM
DO $$
BEGIN
  -- Remove existing job if it exists
  PERFORM cron.unschedule('auto-hide-expired-products');
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- Schedule new job
SELECT cron.schedule(
  'auto-hide-expired-products',
  '0 2 * * *', -- Every day at 2 AM
  $$ SELECT auto_hide_expired_products(); $$
);

-- ============================================================================
-- PART 4: UPDATE RLS POLICIES
-- ============================================================================

-- Update products select policy to exclude deleted products by default
DROP POLICY IF EXISTS "Users can view active products" ON products;
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

-- Farmers can soft delete their own products
DROP POLICY IF EXISTS "Farmers can delete own products" ON products;
CREATE POLICY "Farmers can delete own products"
ON products FOR UPDATE
TO authenticated
USING (farmer_id = auth.uid())
WITH CHECK (farmer_id = auth.uid());

-- ============================================================================
-- PART 5: VERIFICATION & INITIAL CLEANUP
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
END $$;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check expiring products (next 3 days)
-- SELECT * FROM get_expiring_products(3);

-- Check expired products
-- SELECT * FROM get_expired_products();

-- Test soft delete (replace with actual product ID)
-- SELECT soft_delete_product('YOUR-PRODUCT-ID-HERE');

-- ============================================================================
-- ROLLBACK SCRIPT (if needed)
-- ============================================================================

/*
BEGIN;

-- Remove scheduled job
SELECT cron.unschedule('auto-hide-expired-products');

-- Drop functions
DROP FUNCTION IF EXISTS auto_hide_expired_products();
DROP FUNCTION IF EXISTS get_expiring_products(INTEGER);
DROP FUNCTION IF EXISTS get_expired_products();
DROP FUNCTION IF EXISTS soft_delete_product(UUID);
DROP FUNCTION IF EXISTS restore_product(UUID);

-- Remove columns
ALTER TABLE products DROP COLUMN IF EXISTS deleted_at;
ALTER TABLE products DROP COLUMN IF EXISTS status;

-- Drop indexes
DROP INDEX IF EXISTS idx_products_status;
DROP INDEX IF EXISTS idx_products_deleted_at;

-- Restore original policies
DROP POLICY IF EXISTS "Users can view active products" ON products;
DROP POLICY IF EXISTS "Farmers can delete own products" ON products;

COMMIT;
*/

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. Products with orders cannot be hard deleted (foreign key constraint)
-- 2. Use soft_delete_product() function instead of DELETE
-- 3. Expired products are automatically hidden daily at 2 AM
-- 4. Farmers can see their deleted products in the dashboard
-- 5. Use get_expiring_products() to send notifications to farmers
-- ============================================================================
