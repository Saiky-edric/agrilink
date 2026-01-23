-- ============================================================================
-- Migration: Add Pick-up Payment Option
-- Version: 16
-- Date: 2025-01-15
-- Description: Adds pick-up as a delivery method option alongside home delivery
-- ============================================================================

-- ============================================================================
-- 1. ADD DELIVERY METHOD TO ORDERS TABLE
-- ============================================================================

-- Add delivery_method column (default to 'delivery' for backward compatibility)
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS delivery_method VARCHAR(20) DEFAULT 'delivery' 
CHECK (delivery_method IN ('delivery', 'pickup'));

-- Add pickup location reference (for future Phase 2 - multiple locations)
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS pickup_location_id UUID;

-- Add index for filtering by delivery method
CREATE INDEX IF NOT EXISTS idx_orders_delivery_method ON orders(delivery_method);

-- Add comment for documentation
COMMENT ON COLUMN orders.delivery_method IS 'Delivery method: delivery (home delivery with fee) or pickup (customer picks up, no fee)';
COMMENT ON COLUMN orders.pickup_location_id IS 'Reference to pickup location if delivery_method is pickup (NULL for delivery orders)';

-- ============================================================================
-- 2. ADD PICKUP SETTINGS TO USERS TABLE (FARMER PROFILES)
-- ============================================================================

-- Enable/disable pickup for farmer's store
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pickup_enabled BOOLEAN DEFAULT false;

-- Pickup address (farm location, market stall, etc.)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pickup_address TEXT;

-- Pickup instructions (directions, what to bring, etc.)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pickup_instructions TEXT;

-- Pickup hours in JSON format: {"monday":"9AM-5PM", "tuesday":"CLOSED", ...}
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS pickup_hours JSONB;

-- Add index for filtering farmers with pickup enabled
CREATE INDEX IF NOT EXISTS idx_users_pickup_enabled ON users(pickup_enabled) WHERE pickup_enabled = true;

-- Add comments for documentation
COMMENT ON COLUMN users.pickup_enabled IS 'Whether this farmer allows pickup orders (true) or delivery only (false)';
COMMENT ON COLUMN users.pickup_address IS 'Physical address where customers can pick up orders';
COMMENT ON COLUMN users.pickup_instructions IS 'Special instructions for customers picking up orders (directions, parking, entry points, etc.)';
COMMENT ON COLUMN users.pickup_hours IS 'Available pickup hours per day in JSON format: {"monday":"9:00 AM - 5:00 PM", "tuesday":"CLOSED", ...}';

-- ============================================================================
-- 3. UPDATE RLS POLICIES (if needed)
-- ============================================================================

-- Orders table policies already allow buyers/farmers to view their own orders
-- No changes needed - existing policies cover pickup orders

-- ============================================================================
-- 4. CREATE HELPER FUNCTIONS
-- ============================================================================

-- Function to check if farmer has pickup enabled
CREATE OR REPLACE FUNCTION is_pickup_available(farmer_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = farmer_uuid 
    AND role = 'farmer' 
    AND pickup_enabled = true
    AND pickup_address IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get farmer's pickup info
CREATE OR REPLACE FUNCTION get_farmer_pickup_info(farmer_uuid UUID)
RETURNS TABLE (
  pickup_enabled BOOLEAN,
  pickup_address TEXT,
  pickup_instructions TEXT,
  pickup_hours JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.pickup_enabled,
    u.pickup_address,
    u.pickup_instructions,
    u.pickup_hours
  FROM users u
  WHERE u.id = farmer_uuid
  AND u.role = 'farmer';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. SAMPLE DATA (for testing)
-- ============================================================================

-- Uncomment to enable pickup for a test farmer
/*
UPDATE users 
SET 
  pickup_enabled = true,
  pickup_address = 'Main Farm, Brgy. Tagubay, Bayugan City, Agusan del Sur',
  pickup_instructions = 'Enter through the main gate. Farm office is on the right side. Ring the bell if the door is closed. Parking available on the left.',
  pickup_hours = '{"monday":"9:00 AM - 5:00 PM","tuesday":"9:00 AM - 5:00 PM","wednesday":"9:00 AM - 5:00 PM","thursday":"9:00 AM - 5:00 PM","friday":"9:00 AM - 5:00 PM","saturday":"9:00 AM - 3:00 PM","sunday":"CLOSED"}'::jsonb
WHERE role = 'farmer'
AND email = 'test.farmer@agrilink.com'; -- Replace with actual test farmer email
*/

-- ============================================================================
-- 6. VERIFICATION QUERIES
-- ============================================================================

-- Verify orders table has new columns
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' 
    AND column_name = 'delivery_method'
  ) THEN
    RAISE NOTICE '✓ orders.delivery_method column added successfully';
  ELSE
    RAISE EXCEPTION '✗ orders.delivery_method column NOT found!';
  END IF;
END $$;

-- Verify users table has pickup settings
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' 
    AND column_name = 'pickup_enabled'
  ) THEN
    RAISE NOTICE '✓ users.pickup_enabled column added successfully';
  ELSE
    RAISE EXCEPTION '✗ users.pickup_enabled column NOT found!';
  END IF;
END $$;

-- Check indexes created
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_orders_delivery_method'
  ) THEN
    RAISE NOTICE '✓ idx_orders_delivery_method index created successfully';
  ELSE
    RAISE WARNING '⚠ idx_orders_delivery_method index NOT found';
  END IF;
END $$;

-- Count existing orders (all should default to 'delivery')
DO $$ 
DECLARE
  order_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO order_count FROM orders WHERE delivery_method = 'delivery';
  RAISE NOTICE '✓ % existing orders defaulted to delivery method', order_count;
END $$;

-- ============================================================================
-- 7. ROLLBACK SCRIPT (if needed)
-- ============================================================================

/*
-- ROLLBACK: Remove pickup option columns
-- WARNING: This will delete all pickup-related data!

-- Drop functions
DROP FUNCTION IF EXISTS is_pickup_available(UUID);
DROP FUNCTION IF EXISTS get_farmer_pickup_info(UUID);

-- Drop indexes
DROP INDEX IF EXISTS idx_orders_delivery_method;
DROP INDEX IF EXISTS idx_users_pickup_enabled;

-- Remove columns from orders
ALTER TABLE orders DROP COLUMN IF EXISTS delivery_method;
ALTER TABLE orders DROP COLUMN IF EXISTS pickup_location_id;

-- Remove columns from users
ALTER TABLE users DROP COLUMN IF EXISTS pickup_enabled;
ALTER TABLE users DROP COLUMN IF EXISTS pickup_address;
ALTER TABLE users DROP COLUMN IF EXISTS pickup_instructions;
ALTER TABLE users DROP COLUMN IF EXISTS pickup_hours;
*/

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

RAISE NOTICE '';
RAISE NOTICE '================================================';
RAISE NOTICE '✓ Pickup Option Migration Complete!';
RAISE NOTICE '================================================';
RAISE NOTICE 'Next Steps:';
RAISE NOTICE '1. Update Flutter OrderModel to include delivery_method';
RAISE NOTICE '2. Add delivery method selector to checkout screen';
RAISE NOTICE '3. Create farmer pickup settings screen';
RAISE NOTICE '4. Update order details screens';
RAISE NOTICE '5. Test pickup flow end-to-end';
RAISE NOTICE '================================================';
