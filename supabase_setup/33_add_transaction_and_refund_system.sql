-- =====================================================
-- Transaction and Refund System for GCash Payments
-- CORRECTED VERSION for your schema (uses 'users' table)
-- =====================================================
-- This migration adds comprehensive transaction logging
-- and refund management system for transparency and
-- easy refund processing
-- =====================================================

-- 1. Create transactions table for payment logging
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  order_number TEXT, -- Denormalized for easy display
  type TEXT NOT NULL CHECK (type IN ('payment', 'refund', 'cancellation')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'processing', 'failed', 'cancelled')),
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL, -- 'gcash', 'cod', 'cop'
  payment_screenshot_url TEXT,
  payment_reference TEXT,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  refunded_by UUID REFERENCES users(id), -- Admin who processed refund
  refund_reason TEXT,
  refund_notes TEXT,
  
  -- Add indexes for better query performance
  CONSTRAINT transactions_amount_positive CHECK (amount > 0)
);

-- Create indexes for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON transactions(payment_method);

-- 2. Create refund_requests table
CREATE TABLE IF NOT EXISTS refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  amount DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  additional_details TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processing')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  processed_at TIMESTAMP WITH TIME ZONE,
  processed_by UUID REFERENCES users(id), -- Admin who processed
  admin_notes TEXT,
  
  CONSTRAINT refund_amount_positive CHECK (amount > 0)
);

-- Create indexes for refund_requests
CREATE INDEX IF NOT EXISTS idx_refund_requests_order_id ON refund_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_user_id ON refund_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_status ON refund_requests(status);
CREATE INDEX IF NOT EXISTS idx_refund_requests_created_at ON refund_requests(created_at DESC);

-- 3. Add refund-related columns to orders table
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS refund_requested BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS refund_status TEXT CHECK (refund_status IN ('none', 'pending', 'approved', 'rejected', 'completed')),
ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS refunded_amount DECIMAL(10,2);

-- Create index for refund status
CREATE INDEX IF NOT EXISTS idx_orders_refund_status ON orders(refund_status);

-- 4. Function to create transaction when order is placed with GCash
CREATE OR REPLACE FUNCTION create_transaction_on_gcash_order()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create transaction for GCash payments
  IF NEW.payment_method = 'gcash' AND OLD.payment_method IS NULL THEN
    INSERT INTO transactions (
      user_id,
      order_id,
      order_number,
      type,
      status,
      amount,
      payment_method,
      payment_screenshot_url,
      payment_reference,
      description
    ) VALUES (
      NEW.buyer_id,
      NEW.id,
      NEW.id::TEXT, -- Use order ID as order number for now
      'payment',
      'pending', -- Payment is pending verification
      NEW.total_amount,
      NEW.payment_method,
      NEW.payment_screenshot_url,
      NEW.payment_reference,
      'Payment for Order #' || NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to update transaction when payment is verified
CREATE OR REPLACE FUNCTION update_transaction_on_payment_verification()
RETURNS TRIGGER AS $$
BEGIN
  -- Update transaction status when payment is verified
  IF NEW.payment_verified = true AND (OLD.payment_verified IS NULL OR OLD.payment_verified = false) THEN
    UPDATE transactions
    SET 
      status = 'completed',
      completed_at = NEW.payment_verified_at
    WHERE order_id = NEW.id 
      AND type = 'payment'
      AND status = 'pending';
  END IF;
  
  -- Update transaction status when payment is rejected
  IF NEW.payment_verified = false AND OLD.payment_verified IS NULL THEN
    UPDATE transactions
    SET 
      status = 'failed',
      completed_at = NEW.payment_verified_at,
      refund_notes = 'Payment verification rejected: ' || COALESCE(NEW.payment_notes, 'No reason provided')
    WHERE order_id = NEW.id 
      AND type = 'payment'
      AND status = 'pending';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Function to process refund request
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
  SELECT * INTO v_order
  FROM orders
  WHERE id = v_refund_request.order_id;
  
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
      'Refund for Order #' || v_order.id,
      now(),
      p_admin_id,
      v_refund_request.reason,
      p_admin_notes
    ) RETURNING id INTO v_transaction_id;
    
    -- Update refund request
    UPDATE refund_requests
    SET 
      status = 'approved',
      processed_at = now(),
      processed_by = p_admin_id,
      admin_notes = p_admin_notes,
      transaction_id = v_transaction_id
    WHERE id = p_refund_request_id;
    
    -- Update order
    UPDATE orders
    SET 
      refund_status = 'completed',
      refunded_at = now(),
      refunded_amount = v_refund_request.amount
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
      'Your refund request of ₱' || v_refund_request.amount || ' has been approved. The amount will be refunded to your GCash account within 3-5 business days.',
      json_build_object(
        'order_id', v_refund_request.order_id,
        'refund_request_id', p_refund_request_id,
        'amount', v_refund_request.amount,
        'transaction_id', v_transaction_id
      )
    );
    
    RETURN json_build_object('success', true, 'message', 'Refund approved successfully', 'transaction_id', v_transaction_id);
    
  ELSIF p_action = 'reject' THEN
    -- Update refund request
    UPDATE refund_requests
    SET 
      status = 'rejected',
      processed_at = now(),
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
    
    RETURN json_build_object('success', true, 'message', 'Refund rejected successfully');
  ELSE
    RETURN json_build_object('success', false, 'message', 'Invalid action. Use "approve" or "reject"');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_create_transaction_on_gcash_order ON orders;
DROP TRIGGER IF EXISTS trigger_update_transaction_on_payment_verification ON orders;

-- 8. Create triggers
CREATE TRIGGER trigger_create_transaction_on_gcash_order
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION create_transaction_on_gcash_order();

CREATE TRIGGER trigger_update_transaction_on_payment_verification
  AFTER UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.payment_verified IS DISTINCT FROM OLD.payment_verified)
  EXECUTE FUNCTION update_transaction_on_payment_verification();

-- 9. Enable RLS for transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can view all transactions" ON transactions;
DROP POLICY IF EXISTS "System can insert transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can update transactions" ON transactions;

-- RLS Policies for transactions
CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions"
  ON transactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert transactions"
  ON transactions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update transactions"
  ON transactions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 10. Enable RLS for refund_requests
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own refund requests" ON refund_requests;
DROP POLICY IF EXISTS "Users can create their own refund requests" ON refund_requests;
DROP POLICY IF EXISTS "Admins can view all refund requests" ON refund_requests;
DROP POLICY IF EXISTS "Admins can update refund requests" ON refund_requests;

-- RLS Policies for refund_requests
CREATE POLICY "Users can view their own refund requests"
  ON refund_requests FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create their own refund requests"
  ON refund_requests FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all refund requests"
  ON refund_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update refund requests"
  ON refund_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 11. Add helpful comments
COMMENT ON TABLE transactions IS 'Logs all payment transactions including payments, refunds, and cancellations for transparency';
COMMENT ON TABLE refund_requests IS 'Manages refund requests from buyers for GCash payments';
COMMENT ON FUNCTION process_refund_request IS 'Processes a refund request by approving or rejecting it';

-- 12. Create view for admin refund dashboard
CREATE OR REPLACE VIEW admin_refund_dashboard AS
SELECT 
  rr.id,
  rr.order_id,
  rr.user_id,
  rr.amount,
  rr.reason,
  rr.additional_details,
  rr.status,
  rr.created_at,
  rr.processed_at,
  o.id::TEXT as order_number,
  o.payment_method,
  o.payment_screenshot_url,
  o.payment_reference,
  u.full_name as buyer_name,
  u.email as buyer_email,
  u.phone_number as buyer_phone,
  fu.full_name as farmer_name
FROM refund_requests rr
JOIN orders o ON rr.order_id = o.id
JOIN users u ON rr.user_id = u.id
JOIN users fu ON o.farmer_id = fu.id
ORDER BY rr.created_at DESC;

-- Grant access to view
GRANT SELECT ON admin_refund_dashboard TO authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Transaction and Refund System created successfully!';
  RAISE NOTICE '📊 Tables created: transactions, refund_requests';
  RAISE NOTICE '🔧 Functions created: create_transaction_on_gcash_order, update_transaction_on_payment_verification, process_refund_request';
  RAISE NOTICE '🔒 RLS policies enabled for both tables';
  RAISE NOTICE '👀 Admin dashboard view created: admin_refund_dashboard';
  RAISE NOTICE '✨ Schema compatible with your existing users table';
END $$;
