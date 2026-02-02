-- =====================================================
-- Auto-Generate Tracking Numbers for Delivery Orders
-- =====================================================
-- This migration automatically generates tracking numbers
-- for delivery orders (not pickup) when farmer accepts
-- or starts processing the order
-- =====================================================

-- 1. Function to auto-generate tracking number for delivery orders
CREATE OR REPLACE FUNCTION generate_tracking_number_for_delivery()
RETURNS TRIGGER AS $$
BEGIN
  -- Only generate for delivery orders (not pickup)
  IF NEW.delivery_method = 'delivery' AND NEW.tracking_number IS NULL THEN
    
    -- Generate when order is accepted, toPack, or toDeliver
    IF NEW.farmer_status IN ('accepted', 'toPack', 'toDeliver') AND 
       OLD.farmer_status IN ('newOrder', 'accepted', 'toPack') THEN
      
      -- Format: AGR-YYYYMMDD-XXXXXXXX
      -- Example: AGR-20260125-A3F2B891
      NEW.tracking_number := 'AGR-' || 
                            TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || 
                            UPPER(SUBSTRING(NEW.id::TEXT, 1, 8));
      
      RAISE NOTICE 'Generated tracking number % for order %', NEW.tracking_number, NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_generate_tracking_number_for_delivery ON orders;

-- 3. Create the trigger
CREATE TRIGGER trigger_generate_tracking_number_for_delivery
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.farmer_status IS DISTINCT FROM OLD.farmer_status)
  EXECUTE FUNCTION generate_tracking_number_for_delivery();

-- 4. Backfill tracking numbers for existing delivery orders without them
UPDATE orders
SET tracking_number = 'AGR-' || 
                     TO_CHAR(created_at, 'YYYYMMDD') || '-' || 
                     UPPER(SUBSTRING(id::TEXT, 1, 8))
WHERE tracking_number IS NULL
  AND delivery_method = 'delivery'
  AND farmer_status NOT IN ('newOrder', 'cancelled');

-- 5. Add helpful comments
COMMENT ON FUNCTION generate_tracking_number_for_delivery IS 
'Automatically generates tracking numbers for delivery orders (not pickup) when farmer accepts or starts processing';

-- 6. Create index for faster tracking number lookups
CREATE INDEX IF NOT EXISTS idx_orders_tracking_number ON orders(tracking_number) 
WHERE tracking_number IS NOT NULL;

-- Success message
DO $$
DECLARE
  backfilled_count INTEGER;
  delivery_orders INTEGER;
  pickup_orders INTEGER;
BEGIN
  -- Count backfilled orders
  SELECT COUNT(*) INTO backfilled_count
  FROM orders
  WHERE tracking_number IS NOT NULL
    AND tracking_number LIKE 'AGR-%';
  
  -- Count delivery vs pickup orders
  SELECT COUNT(*) INTO delivery_orders
  FROM orders
  WHERE delivery_method = 'delivery';
  
  SELECT COUNT(*) INTO pickup_orders
  FROM orders
  WHERE delivery_method = 'pickup';
  
  RAISE NOTICE '✅ Tracking Number Auto-Generation System created successfully!';
  RAISE NOTICE '📊 Statistics:';
  RAISE NOTICE '   - Total orders with tracking: %', backfilled_count;
  RAISE NOTICE '   - Delivery orders (need tracking): %', delivery_orders;
  RAISE NOTICE '   - Pickup orders (no tracking needed): %', pickup_orders;
  RAISE NOTICE '🔧 Trigger: trigger_generate_tracking_number_for_delivery';
  RAISE NOTICE '📦 Format: AGR-YYYYMMDD-XXXXXXXX';
  RAISE NOTICE '🚚 Only delivery orders get tracking numbers';
  RAISE NOTICE '🏪 Pickup orders remain NULL (as intended)';
END $$;
