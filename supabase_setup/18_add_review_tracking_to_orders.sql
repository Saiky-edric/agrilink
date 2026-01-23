-- ============================================================================
-- ADD REVIEW TRACKING TO ORDERS TABLE
-- ============================================================================
-- This script adds fields to track if buyer has reviewed products after delivery
-- ============================================================================

BEGIN;

-- Add review tracking columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS buyer_reviewed BOOLEAN DEFAULT false;

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS review_reminder_sent BOOLEAN DEFAULT false;

-- Create index for finding orders needing review
CREATE INDEX IF NOT EXISTS idx_orders_buyer_reviewed 
ON orders(buyer_reviewed, buyer_status) 
WHERE buyer_reviewed = false AND buyer_status = 'completed';

-- Create index for review reminders
CREATE INDEX IF NOT EXISTS idx_orders_review_reminder 
ON orders(review_reminder_sent, completed_at) 
WHERE review_reminder_sent = false AND completed_at IS NOT NULL;

-- Function to get orders eligible for review (completed but not reviewed)
CREATE OR REPLACE FUNCTION get_orders_eligible_for_review(buyer_id_param UUID)
RETURNS TABLE (
  order_id UUID,
  farmer_id UUID,
  farmer_name TEXT,
  completed_at TIMESTAMP WITH TIME ZONE,
  days_since_completed INTEGER,
  total_amount NUMERIC,
  item_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id as order_id,
    o.farmer_id,
    u.full_name as farmer_name,
    o.completed_at,
    EXTRACT(DAY FROM (NOW() - o.completed_at))::INTEGER as days_since_completed,
    o.total_amount,
    COUNT(oi.id) as item_count
  FROM orders o
  INNER JOIN users u ON o.farmer_id = u.id
  LEFT JOIN order_items oi ON o.id = oi.order_id
  WHERE 
    o.buyer_id = buyer_id_param
    AND o.buyer_status = 'completed'
    AND o.buyer_reviewed = false
    AND o.completed_at IS NOT NULL
    AND o.completed_at >= NOW() - INTERVAL '30 days' -- Only show orders from last 30 days
  GROUP BY o.id, o.farmer_id, u.full_name, o.completed_at, o.total_amount
  ORDER BY o.completed_at DESC;
END;
$$;

-- Function to mark order as reviewed
CREATE OR REPLACE FUNCTION mark_order_as_reviewed(order_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE orders
  SET 
    buyer_reviewed = true,
    updated_at = NOW()
  WHERE id = order_id_param;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found: %', order_id_param;
  END IF;
END;
$$;

-- Function to send review reminders (can be called by cron job or cloud function)
CREATE OR REPLACE FUNCTION send_review_reminders()
RETURNS TABLE (
  order_id UUID,
  buyer_id UUID,
  buyer_email TEXT,
  farmer_name TEXT,
  days_since_completed INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Get orders completed 2-7 days ago that haven't been reviewed or reminded
  RETURN QUERY
  SELECT 
    o.id as order_id,
    o.buyer_id,
    ub.email as buyer_email,
    uf.full_name as farmer_name,
    EXTRACT(DAY FROM (NOW() - o.completed_at))::INTEGER as days_since_completed
  FROM orders o
  INNER JOIN users ub ON o.buyer_id = ub.id
  INNER JOIN users uf ON o.farmer_id = uf.id
  WHERE 
    o.buyer_status = 'completed'
    AND o.buyer_reviewed = false
    AND o.review_reminder_sent = false
    AND o.completed_at IS NOT NULL
    AND o.completed_at BETWEEN (NOW() - INTERVAL '7 days') AND (NOW() - INTERVAL '2 days')
  ORDER BY o.completed_at DESC;
  
  -- Mark reminders as sent
  UPDATE orders
  SET review_reminder_sent = true
  WHERE id IN (
    SELECT o.id
    FROM orders o
    WHERE 
      o.buyer_status = 'completed'
      AND o.buyer_reviewed = false
      AND o.review_reminder_sent = false
      AND o.completed_at IS NOT NULL
      AND o.completed_at BETWEEN (NOW() - INTERVAL '7 days') AND (NOW() - INTERVAL '2 days')
  );
END;
$$;

-- Update RLS policies (orders already have proper RLS, just verify)
-- Buyers can see their review status
-- Farmers can see if their orders have been reviewed

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== REVIEW TRACKING SETUP COMPLETE ===';
  RAISE NOTICE 'Added columns:';
  RAISE NOTICE '  • buyer_reviewed (BOOLEAN)';
  RAISE NOTICE '  • review_reminder_sent (BOOLEAN)';
  RAISE NOTICE '';
  RAISE NOTICE 'Created functions:';
  RAISE NOTICE '  • get_orders_eligible_for_review(buyer_id)';
  RAISE NOTICE '  • mark_order_as_reviewed(order_id)';
  RAISE NOTICE '  • send_review_reminders()';
  RAISE NOTICE '';
  RAISE NOTICE 'Created indexes for performance';
END $$;

-- ============================================================================
-- TEST QUERIES
-- ============================================================================

-- Check orders eligible for review (replace with actual buyer ID)
-- SELECT * FROM get_orders_eligible_for_review('YOUR-BUYER-ID');

-- Check orders needing reminders
-- SELECT * FROM send_review_reminders();

-- Mark order as reviewed (replace with actual order ID)
-- SELECT mark_order_as_reviewed('YOUR-ORDER-ID');

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

/*
BEGIN;

DROP FUNCTION IF EXISTS get_orders_eligible_for_review(UUID);
DROP FUNCTION IF EXISTS mark_order_as_reviewed(UUID);
DROP FUNCTION IF EXISTS send_review_reminders();

DROP INDEX IF EXISTS idx_orders_buyer_reviewed;
DROP INDEX IF EXISTS idx_orders_review_reminder;

ALTER TABLE orders DROP COLUMN IF EXISTS buyer_reviewed;
ALTER TABLE orders DROP COLUMN IF EXISTS review_reminder_sent;

COMMIT;
*/
