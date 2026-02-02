-- ================================================
-- ORDER STATUS TIMESTAMPS MIGRATION
-- ================================================
-- This migration adds individual timestamp columns for each order status
-- to enable precise timeline tracking and analytics
-- ================================================

-- Add individual timestamp columns for each status transition
ALTER TABLE orders 
  ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS to_pack_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS to_deliver_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ready_for_pickup_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Add columns for estimated delivery tracking
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS estimated_delivery_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS estimated_pickup_at TIMESTAMPTZ;

-- Add columns for delivery tracking (map functionality)
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS delivery_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS delivery_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS delivery_longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS delivery_last_updated_at TIMESTAMPTZ;

-- Add farmer location for distance calculation
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS farmer_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS farmer_longitude DOUBLE PRECISION;

-- Add buyer location (from delivery address)
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS buyer_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS buyer_longitude DOUBLE PRECISION;

-- Create index for realtime queries
CREATE INDEX IF NOT EXISTS idx_orders_realtime_tracking 
  ON orders(id, farmer_status, delivery_latitude, delivery_longitude) 
  WHERE farmer_status = 'toDeliver';

-- Add comments for documentation
COMMENT ON COLUMN orders.accepted_at IS 'Timestamp when farmer accepted the order';
COMMENT ON COLUMN orders.to_pack_at IS 'Timestamp when order status changed to toPack';
COMMENT ON COLUMN orders.to_deliver_at IS 'Timestamp when order status changed to toDeliver';
COMMENT ON COLUMN orders.ready_for_pickup_at IS 'Timestamp when order became ready for pickup';
COMMENT ON COLUMN orders.cancelled_at IS 'Timestamp when order was cancelled';
COMMENT ON COLUMN orders.estimated_delivery_at IS 'Estimated delivery completion time';
COMMENT ON COLUMN orders.estimated_pickup_at IS 'Estimated pickup availability time';
COMMENT ON COLUMN orders.delivery_started_at IS 'Timestamp when delivery actually started';
COMMENT ON COLUMN orders.delivery_latitude IS 'Current latitude of delivery driver/farmer';
COMMENT ON COLUMN orders.delivery_longitude IS 'Current longitude of delivery driver/farmer';
COMMENT ON COLUMN orders.delivery_last_updated_at IS 'Last time delivery location was updated';
COMMENT ON COLUMN orders.farmer_latitude IS 'Farmer store/farm latitude';
COMMENT ON COLUMN orders.farmer_longitude IS 'Farmer store/farm longitude';
COMMENT ON COLUMN orders.buyer_latitude IS 'Buyer delivery address latitude';
COMMENT ON COLUMN orders.buyer_longitude IS 'Buyer delivery address longitude';

-- ================================================
-- CREATE ORDER STATUS HISTORY TABLE
-- ================================================
-- Comprehensive audit trail for all status changes
-- ================================================

CREATE TABLE IF NOT EXISTS order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  
  -- Status information
  old_status TEXT,
  new_status TEXT NOT NULL,
  
  -- Who made the change
  changed_by UUID REFERENCES auth.users(id),
  changed_by_role TEXT, -- 'buyer', 'farmer', 'admin', 'system'
  
  -- Additional context
  notes TEXT,
  reason TEXT, -- For cancellations, rejections, etc.
  
  -- Location tracking (if applicable)
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_status CHECK (
    new_status IN (
      'newOrder', 'accepted', 'toPack', 'toDeliver', 
      'readyForPickup', 'completed', 'cancelled'
    )
  )
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id 
  ON order_status_history(order_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_status_history_changed_by 
  ON order_status_history(changed_by);

CREATE INDEX IF NOT EXISTS idx_order_status_history_new_status 
  ON order_status_history(new_status, created_at DESC);

-- Enable RLS
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for order_status_history

-- Buyers can view history of their orders
CREATE POLICY "Buyers can view their order history"
  ON order_status_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_status_history.order_id
      AND orders.buyer_id = auth.uid()
    )
  );

-- Farmers can view history of their orders
CREATE POLICY "Farmers can view their order history"
  ON order_status_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_status_history.order_id
      AND orders.farmer_id = auth.uid()
    )
  );

-- Admins can view all history
CREATE POLICY "Admins can view all order history"
  ON order_status_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- System can insert history records
CREATE POLICY "System can insert order history"
  ON order_status_history
  FOR INSERT
  WITH CHECK (true);

-- ================================================
-- TRIGGER TO AUTO-UPDATE TIMESTAMP COLUMNS
-- ================================================
-- Automatically set timestamp columns when farmer_status changes
-- ================================================

CREATE OR REPLACE FUNCTION update_order_status_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  -- Update corresponding timestamp based on new status
  CASE NEW.farmer_status
    WHEN 'accepted' THEN
      NEW.accepted_at = COALESCE(NEW.accepted_at, NOW());
    WHEN 'toPack' THEN
      NEW.to_pack_at = COALESCE(NEW.to_pack_at, NOW());
    WHEN 'toDeliver' THEN
      NEW.to_deliver_at = COALESCE(NEW.to_deliver_at, NOW());
      NEW.delivery_started_at = COALESCE(NEW.delivery_started_at, NOW());
    WHEN 'readyForPickup' THEN
      NEW.ready_for_pickup_at = COALESCE(NEW.ready_for_pickup_at, NOW());
    WHEN 'cancelled' THEN
      NEW.cancelled_at = COALESCE(NEW.cancelled_at, NOW());
    ELSE
      -- No specific timestamp for other statuses
  END CASE;

  -- Insert into status history
  INSERT INTO order_status_history (
    order_id,
    old_status,
    new_status,
    changed_by,
    changed_by_role,
    notes,
    latitude,
    longitude
  ) VALUES (
    NEW.id,
    OLD.farmer_status,
    NEW.farmer_status,
    auth.uid(),
    (SELECT role FROM users WHERE id = auth.uid()),
    NULL,
    NEW.delivery_latitude,
    NEW.delivery_longitude
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_update_order_status_timestamps ON orders;

CREATE TRIGGER trigger_update_order_status_timestamps
  BEFORE UPDATE OF farmer_status ON orders
  FOR EACH ROW
  WHEN (OLD.farmer_status IS DISTINCT FROM NEW.farmer_status)
  EXECUTE FUNCTION update_order_status_timestamps();

-- ================================================
-- FUNCTION TO CALCULATE ESTIMATED DELIVERY TIME
-- ================================================
-- Based on historical data and current order load
-- ================================================

CREATE OR REPLACE FUNCTION calculate_estimated_delivery_time(
  p_order_id UUID,
  p_delivery_method TEXT DEFAULT 'delivery'
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_farmer_id UUID;
  v_avg_processing_hours NUMERIC;
  v_estimated_time TIMESTAMPTZ;
  v_current_pending_orders INT;
BEGIN
  -- Get farmer ID
  SELECT farmer_id INTO v_farmer_id
  FROM orders WHERE id = p_order_id;

  -- Calculate average processing time from completed orders
  SELECT 
    EXTRACT(EPOCH FROM AVG(completed_at - created_at)) / 3600
  INTO v_avg_processing_hours
  FROM orders
  WHERE farmer_id = v_farmer_id
    AND farmer_status = 'completed'
    AND completed_at IS NOT NULL
    AND created_at > NOW() - INTERVAL '90 days';

  -- Default to 24 hours if no history
  v_avg_processing_hours = COALESCE(v_avg_processing_hours, 24);

  -- Count current pending orders for this farmer
  SELECT COUNT(*) INTO v_current_pending_orders
  FROM orders
  WHERE farmer_id = v_farmer_id
    AND farmer_status IN ('newOrder', 'accepted', 'toPack');

  -- Add buffer based on current load
  v_avg_processing_hours = v_avg_processing_hours + (v_current_pending_orders * 0.5);

  -- Calculate estimated time
  v_estimated_time = NOW() + (v_avg_processing_hours || ' hours')::INTERVAL;

  -- Round to nearest hour
  v_estimated_time = DATE_TRUNC('hour', v_estimated_time) + 
                     INTERVAL '1 hour' * ROUND(EXTRACT(MINUTE FROM v_estimated_time) / 60.0);

  RETURN v_estimated_time;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- FUNCTION TO UPDATE DELIVERY LOCATION
-- ================================================
-- For real-time map tracking
-- ================================================

CREATE OR REPLACE FUNCTION update_delivery_location(
  p_order_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS BOOLEAN AS $$
DECLARE
  v_farmer_id UUID;
BEGIN
  -- Get farmer ID and verify permission
  SELECT farmer_id INTO v_farmer_id
  FROM orders WHERE id = p_order_id;

  -- Only farmer can update their delivery location
  IF v_farmer_id != auth.uid() THEN
    RAISE EXCEPTION 'Only the farmer can update delivery location';
  END IF;

  -- Update location
  UPDATE orders
  SET 
    delivery_latitude = p_latitude,
    delivery_longitude = p_longitude,
    delivery_last_updated_at = NOW()
  WHERE id = p_order_id
    AND farmer_status = 'toDeliver';

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- BACKFILL EXISTING ORDERS
-- ================================================
-- Set timestamps for existing orders based on updated_at
-- ================================================

-- For completed orders, use completed_at
UPDATE orders
SET accepted_at = created_at + INTERVAL '30 minutes',
    to_pack_at = created_at + INTERVAL '2 hours',
    to_deliver_at = created_at + INTERVAL '4 hours'
WHERE farmer_status = 'completed'
  AND accepted_at IS NULL
  AND completed_at IS NOT NULL;

-- For in-progress orders, estimate based on current status
UPDATE orders
SET accepted_at = created_at + INTERVAL '30 minutes'
WHERE farmer_status IN ('accepted', 'toPack', 'toDeliver', 'readyForPickup')
  AND accepted_at IS NULL;

UPDATE orders
SET to_pack_at = created_at + INTERVAL '2 hours'
WHERE farmer_status IN ('toPack', 'toDeliver', 'readyForPickup')
  AND to_pack_at IS NULL;

UPDATE orders
SET to_deliver_at = created_at + INTERVAL '4 hours'
WHERE farmer_status = 'toDeliver'
  AND to_deliver_at IS NULL
  AND delivery_method = 'delivery';

UPDATE orders
SET ready_for_pickup_at = created_at + INTERVAL '4 hours'
WHERE farmer_status = 'readyForPickup'
  AND ready_for_pickup_at IS NULL
  AND delivery_method = 'pickup';

-- For cancelled orders
UPDATE orders
SET cancelled_at = updated_at
WHERE farmer_status = 'cancelled'
  AND cancelled_at IS NULL
  AND updated_at IS NOT NULL;

-- ================================================
-- GRANT PERMISSIONS
-- ================================================

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION calculate_estimated_delivery_time(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_delivery_location(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- ================================================
-- VERIFICATION QUERIES
-- ================================================
-- Run these to verify the migration worked
-- ================================================

-- Check if columns were added
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'orders' 
-- AND column_name LIKE '%_at'
-- ORDER BY column_name;

-- Check if history table was created
-- SELECT COUNT(*) FROM order_status_history;

-- Test estimated delivery calculation
-- SELECT calculate_estimated_delivery_time('YOUR_ORDER_ID_HERE', 'delivery');

COMMENT ON TABLE order_status_history IS 'Audit trail of all order status changes';
COMMENT ON FUNCTION calculate_estimated_delivery_time IS 'Calculates estimated delivery time based on farmer performance';
COMMENT ON FUNCTION update_delivery_location IS 'Updates real-time delivery location for map tracking';
