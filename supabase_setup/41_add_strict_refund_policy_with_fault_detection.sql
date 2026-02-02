-- =====================================================
-- Strict Refund Policy with Fault Detection System
-- =====================================================
-- This migration implements:
-- 1. Strict refund policy: Only before toPack status
-- 2. Farmer fault detection for delivery failures
-- 3. Exception handling for farmer-caused delays
-- =====================================================

-- 1. Add fault tracking columns to orders table
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS farmer_fault BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS fault_reason TEXT,
ADD COLUMN IF NOT EXISTS fault_reported_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS fault_reported_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS delivery_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_overdue BOOLEAN DEFAULT false;

-- 2. Add refund eligibility reason to refund_requests
-- First drop the existing constraint if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'refund_requests_eligibility_reason_check'
  ) THEN
    ALTER TABLE refund_requests DROP CONSTRAINT refund_requests_eligibility_reason_check;
  END IF;
END $$;

-- Now add the column and constraint
ALTER TABLE refund_requests
ADD COLUMN IF NOT EXISTS eligibility_reason TEXT;

ALTER TABLE refund_requests
ADD CONSTRAINT refund_requests_eligibility_reason_check
CHECK (eligibility_reason IN (
  'before_packing',           -- Order cancelled before farmer started packing
  'farmer_fault_delay',       -- Farmer failed to deliver on time
  'farmer_fault_no_delivery', -- Farmer never delivered the product
  'farmer_fault_quality',     -- Product quality issues (farmer's fault)
  'farmer_fault_wrong_item',  -- Wrong item delivered
  'admin_override'            -- Admin manually approved exception
));

-- 3. Create index for fault tracking
CREATE INDEX IF NOT EXISTS idx_orders_farmer_fault ON orders(farmer_fault);
CREATE INDEX IF NOT EXISTS idx_orders_is_overdue ON orders(is_overdue);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_deadline ON orders(delivery_deadline);

-- 4. Function to check refund eligibility
CREATE OR REPLACE FUNCTION check_refund_eligibility(p_order_id UUID)
RETURNS JSON AS $$
DECLARE
  v_order orders;
  v_is_eligible BOOLEAN := false;
  v_reason TEXT;
  v_eligibility_type TEXT;
BEGIN
  -- Get order details
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'eligible', false,
      'reason', 'Order not found',
      'eligibility_type', null
    );
  END IF;
  
  -- Check if order is already completed or cancelled
  IF v_order.farmer_status::TEXT IN ('completed', 'cancelled') THEN
    RETURN json_build_object(
      'eligible', false,
      'reason', 'Order is already ' || v_order.farmer_status::TEXT,
      'eligibility_type', null
    );
  END IF;
  
  -- Check if refund already requested
  IF v_order.refund_requested = true THEN
    RETURN json_build_object(
      'eligible', false,
      'reason', 'Refund already requested for this order',
      'eligibility_type', null
    );
  END IF;
  
  -- RULE 1: Allow refund before toPack (farmer hasn't started preparing)
  IF v_order.farmer_status::TEXT IN ('newOrder', 'accepted') THEN
    v_is_eligible := true;
    v_reason := 'Order can be cancelled before farmer starts preparing';
    v_eligibility_type := 'before_packing';
    
  -- RULE 2: Allow refund if farmer is at fault (delivery failures)
  ELSIF v_order.farmer_fault = true THEN
    v_is_eligible := true;
    v_reason := 'Refund allowed due to farmer fault: ' || COALESCE(v_order.fault_reason, 'Delivery failure');
    
    -- Determine specific fault type
    IF v_order.is_overdue = true THEN
      v_eligibility_type := 'farmer_fault_delay';
    ELSE
      v_eligibility_type := 'farmer_fault_no_delivery';
    END IF;
    
  -- RULE 3: Check if delivery is overdue (automatic fault detection)
  ELSIF v_order.delivery_deadline IS NOT NULL 
        AND NOW() > v_order.delivery_deadline 
        AND v_order.farmer_status::TEXT IN ('toPack', 'toDeliver', 'readyForPickup') THEN
    
    -- Automatically mark as overdue and farmer fault
    UPDATE orders 
    SET 
      is_overdue = true,
      farmer_fault = true,
      fault_reason = 'Delivery deadline exceeded. Expected by ' || 
                      TO_CHAR(v_order.delivery_deadline, 'Mon DD, YYYY HH24:MI')
    WHERE id = p_order_id;
    
    v_is_eligible := true;
    v_reason := 'Delivery deadline exceeded. Farmer failed to deliver on time';
    v_eligibility_type := 'farmer_fault_delay';
    
  -- RULE 4: Strict - No refund after toPack unless farmer fault
  ELSE
    v_is_eligible := false;
    v_reason := 'Cannot request refund. Farmer has already started preparing your order. ' ||
                'Refunds are only allowed before packing starts or if there is a delivery failure.';
    v_eligibility_type := null;
  END IF;
  
  RETURN json_build_object(
    'eligible', v_is_eligible,
    'reason', v_reason,
    'eligibility_type', v_eligibility_type,
    'current_status', v_order.farmer_status::TEXT,
    'farmer_fault', COALESCE(v_order.farmer_fault, false),
    'is_overdue', COALESCE(v_order.is_overdue, false)
  );
END;
$$ LANGUAGE plpgsql;

-- 5. Function to report farmer fault (for admin or automatic detection)
CREATE OR REPLACE FUNCTION report_farmer_fault(
  p_order_id UUID,
  p_fault_reason TEXT,
  p_reported_by UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_order orders;
BEGIN
  -- Get order
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Order not found');
  END IF;
  
  -- Cannot mark completed or cancelled orders as faulty
  IF v_order.farmer_status::TEXT IN ('completed', 'cancelled') THEN
    RETURN json_build_object(
      'success', false, 
      'message', 'Cannot report fault on ' || v_order.farmer_status::TEXT || ' order'
    );
  END IF;
  
  -- Update order with fault information
  UPDATE orders
  SET
    farmer_fault = true,
    fault_reason = p_fault_reason,
    fault_reported_at = NOW(),
    fault_reported_by = p_reported_by
  WHERE id = p_order_id;
  
  -- Send notification to buyer that they can now request refund
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    data
  ) VALUES (
    v_order.buyer_id,
    'refund_available',
    'Refund Available',
    'Due to a delivery issue, you are now eligible to request a refund for your order. ' ||
    'Reason: ' || p_fault_reason,
    json_build_object(
      'order_id', p_order_id,
      'fault_reason', p_fault_reason
    )
  );
  
  RETURN json_build_object(
    'success', true, 
    'message', 'Farmer fault reported successfully',
    'order_id', p_order_id
  );
END;
$$ LANGUAGE plpgsql;

-- 6. Update the process_refund_request function to include eligibility checking
CREATE OR REPLACE FUNCTION process_refund_request(
  p_refund_request_id UUID,
  p_admin_id UUID,
  p_action TEXT, -- 'approve' or 'reject'
  p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_refund_request refund_requests;
  v_order orders;
  v_transaction_id UUID;
  v_eligibility JSON;
BEGIN
  -- Get refund request
  SELECT * INTO v_refund_request
  FROM refund_requests
  WHERE id = p_refund_request_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Refund request not found');
  END IF;
  
  -- Check if already processed
  IF v_refund_request.status != 'pending' THEN
    RETURN json_build_object('success', false, 'message', 'Refund request already processed');
  END IF;
  
  -- Get order details
  SELECT * INTO v_order FROM orders WHERE id = v_refund_request.order_id;
  
  -- Check eligibility (for admin reference)
  v_eligibility := check_refund_eligibility(v_refund_request.order_id);
  
  IF p_action = 'approve' THEN
    -- Create refund transaction
    INSERT INTO transactions (
      user_id,
      order_id,
      order_number,
      type,
      status,
      amount,
      payment_method,
      description,
      completed_at,
      refunded_by,
      refund_reason,
      refund_notes
    ) VALUES (
      v_refund_request.user_id,
      v_refund_request.order_id,
      v_order.id::TEXT,
      'refund',
      'completed',
      v_refund_request.amount,
      v_order.payment_method,
      'Refund for order ' || v_order.id::TEXT,
      NOW(),
      p_admin_id,
      v_refund_request.reason,
      p_admin_notes
    ) RETURNING id INTO v_transaction_id;
    
    -- Update refund request
    UPDATE refund_requests
    SET 
      status = 'approved',
      processed_at = NOW(),
      processed_by = p_admin_id,
      admin_notes = p_admin_notes
    WHERE id = p_refund_request_id;
    
    -- Update order status (cast enum values explicitly)
    UPDATE orders
    SET 
      refund_status = 'completed',
      refunded_at = NOW(),
      refunded_amount = v_refund_request.amount,
      farmer_status = 'cancelled'::farmer_order_status,
      buyer_status = 'cancelled'::buyer_order_status,
      cancelled_at = NOW()
    WHERE id = v_refund_request.order_id;
    
    -- Send notification to buyer
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      data
    ) VALUES (
      v_refund_request.user_id,
      'refund_approved',
      'Refund Approved',
      'Your refund request of ₱' || v_refund_request.amount || ' has been approved. ' ||
      'The amount will be refunded to your ' || v_order.payment_method || ' account within 3-5 business days.',
      json_build_object(
        'order_id', v_refund_request.order_id,
        'refund_request_id', p_refund_request_id,
        'amount', v_refund_request.amount,
        'transaction_id', v_transaction_id
      )
    );
    
    RETURN json_build_object(
      'success', true, 
      'message', 'Refund approved successfully', 
      'transaction_id', v_transaction_id,
      'eligibility', v_eligibility
    );
    
  ELSIF p_action = 'reject' THEN
    -- Update refund request
    UPDATE refund_requests
    SET 
      status = 'rejected',
      processed_at = NOW(),
      processed_by = p_admin_id,
      admin_notes = p_admin_notes
    WHERE id = p_refund_request_id;
    
    -- Update order
    UPDATE orders
    SET refund_status = 'rejected'
    WHERE id = v_refund_request.order_id;
    
    -- Send notification to buyer
    INSERT INTO notifications (
      user_id,
      type,
      title,
      message,
      data
    ) VALUES (
      v_refund_request.user_id,
      'refund_rejected',
      'Refund Request Rejected',
      'Your refund request has been rejected. Reason: ' || COALESCE(p_admin_notes, 'No reason provided'),
      json_build_object(
        'order_id', v_refund_request.order_id,
        'refund_request_id', p_refund_request_id,
        'amount', v_refund_request.amount
      )
    );
    
    RETURN json_build_object(
      'success', true, 
      'message', 'Refund rejected successfully',
      'eligibility', v_eligibility
    );
  ELSE
    RETURN json_build_object('success', false, 'message', 'Invalid action. Use "approve" or "reject"');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to automatically set delivery deadlines when order status changes
CREATE OR REPLACE FUNCTION set_delivery_deadline()
RETURNS TRIGGER AS $$
BEGIN
  -- When farmer accepts order, set delivery deadline (e.g., 5 days from acceptance)
  IF NEW.farmer_status::TEXT = 'accepted' AND (OLD.farmer_status IS NULL OR OLD.farmer_status::TEXT = 'newOrder') THEN
    NEW.delivery_deadline := NOW() + INTERVAL '5 days';
    NEW.estimated_delivery_at := NOW() + INTERVAL '5 days';
  END IF;
  
  -- When order moves to toDeliver, update deadline based on delivery date if set
  IF NEW.farmer_status::TEXT = 'toDeliver' AND NEW.delivery_date IS NOT NULL THEN
    NEW.delivery_deadline := NEW.delivery_date::TIMESTAMP + INTERVAL '1 day';
  END IF;
  
  -- Reset fault flags if order is completed successfully
  IF NEW.farmer_status::TEXT = 'completed' THEN
    NEW.farmer_fault := false;
    NEW.is_overdue := false;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger for automatic deadline setting
DROP TRIGGER IF EXISTS trigger_set_delivery_deadline ON orders;
CREATE TRIGGER trigger_set_delivery_deadline
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (OLD.farmer_status IS DISTINCT FROM NEW.farmer_status)
  EXECUTE FUNCTION set_delivery_deadline();

-- 9. Create function to check and mark overdue orders (to be run periodically)
CREATE OR REPLACE FUNCTION mark_overdue_orders()
RETURNS TABLE(order_id UUID, status TEXT) AS $$
BEGIN
  RETURN QUERY
  UPDATE orders
  SET 
    is_overdue = true,
    farmer_fault = true,
    fault_reason = COALESCE(fault_reason, 'Delivery deadline exceeded on ' || TO_CHAR(delivery_deadline, 'Mon DD, YYYY'))
  WHERE 
    delivery_deadline IS NOT NULL
    AND NOW() > delivery_deadline
    AND farmer_status::TEXT IN ('toPack', 'toDeliver', 'readyForPickup')
    AND (is_overdue = false OR is_overdue IS NULL)
  RETURNING id, farmer_status::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 10. Update admin refund dashboard view to include fault information
DROP VIEW IF EXISTS admin_refund_dashboard CASCADE;

CREATE OR REPLACE VIEW admin_refund_dashboard AS
SELECT 
  rr.id,
  rr.order_id,
  rr.user_id,
  rr.amount,
  rr.reason,
  rr.additional_details,
  rr.status,
  rr.eligibility_reason,
  rr.created_at,
  rr.processed_at,
  rr.admin_notes,
  o.id::TEXT as order_number,
  o.payment_method,
  o.payment_screenshot_url,
  o.payment_reference,
  o.farmer_status::TEXT as farmer_status,
  o.farmer_fault,
  o.fault_reason,
  o.is_overdue,
  o.delivery_deadline,
  u.full_name as buyer_name,
  u.email as buyer_email,
  u.phone_number as buyer_phone,
  fu.full_name as farmer_name,
  fu.store_name as farmer_store_name
FROM refund_requests rr
JOIN orders o ON rr.order_id = o.id
JOIN users u ON rr.user_id = u.id
JOIN users fu ON o.farmer_id = fu.id
ORDER BY rr.created_at DESC;

-- Grant access to view
GRANT SELECT ON admin_refund_dashboard TO authenticated;

-- 11. Add helpful comments
COMMENT ON COLUMN orders.farmer_fault IS 'Indicates if the order failure is the farmer''s fault (enables refund after toPack)';
COMMENT ON COLUMN orders.fault_reason IS 'Reason for marking order as farmer fault';
COMMENT ON COLUMN orders.delivery_deadline IS 'Expected delivery completion time. Orders overdue are marked as farmer fault';
COMMENT ON COLUMN orders.is_overdue IS 'Automatically set to true when delivery_deadline is exceeded';
COMMENT ON FUNCTION check_refund_eligibility IS 'Determines if a buyer is eligible for refund based on strict policy rules';
COMMENT ON FUNCTION report_farmer_fault IS 'Marks an order as farmer fault, enabling refund eligibility';
COMMENT ON FUNCTION mark_overdue_orders IS 'Batch function to mark all overdue orders as farmer fault';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Strict Refund Policy with Fault Detection implemented successfully!';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Policy Rules:';
  RAISE NOTICE '   1. ✅ Refunds allowed BEFORE toPack status (farmer hasn''t started)';
  RAISE NOTICE '   2. 🚫 Refunds blocked AFTER toPack (farmer has started preparing)';
  RAISE NOTICE '   3. ⚠️  Exception: Refunds allowed if farmer is at fault';
  RAISE NOTICE '   4. ⏰  Automatic fault detection for overdue deliveries';
  RAISE NOTICE '';
  RAISE NOTICE '🔧 New Functions:';
  RAISE NOTICE '   - check_refund_eligibility(order_id) → Check if refund is allowed';
  RAISE NOTICE '   - report_farmer_fault(order_id, reason, reporter) → Mark farmer fault';
  RAISE NOTICE '   - mark_overdue_orders() → Auto-detect overdue orders';
  RAISE NOTICE '';
  RAISE NOTICE '📊 New Columns:';
  RAISE NOTICE '   - orders.farmer_fault → Tracks if farmer is at fault';
  RAISE NOTICE '   - orders.fault_reason → Reason for fault';
  RAISE NOTICE '   - orders.delivery_deadline → Expected delivery time';
  RAISE NOTICE '   - orders.is_overdue → Auto-set when deadline exceeded';
  RAISE NOTICE '   - refund_requests.eligibility_reason → Why refund was allowed';
  RAISE NOTICE '';
  RAISE NOTICE '⚡ Automatic Features:';
  RAISE NOTICE '   - Delivery deadlines set automatically (5 days after acceptance)';
  RAISE NOTICE '   - Overdue orders marked as farmer fault automatically';
  RAISE NOTICE '   - Buyers notified when refund becomes available';
END $$;
