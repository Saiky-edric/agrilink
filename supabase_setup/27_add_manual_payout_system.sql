-- =============================================
-- Manual Payout System for AgriLink MVP
-- =============================================
-- This allows farmers to request payouts manually
-- and admins to process them via GCash/Bank transfer
-- =============================================

-- Step 1: Add wallet and payment fields to users table
-- =============================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS wallet_balance DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_earnings DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS pending_earnings DECIMAL(10, 2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS gcash_number TEXT,
ADD COLUMN IF NOT EXISTS gcash_name TEXT,
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS bank_account_number TEXT,
ADD COLUMN IF NOT EXISTS bank_account_name TEXT;

COMMENT ON COLUMN users.wallet_balance IS 'Available balance that can be withdrawn';
COMMENT ON COLUMN users.total_earnings IS 'Total earnings from all completed orders';
COMMENT ON COLUMN users.pending_earnings IS 'Earnings from orders in progress';
COMMENT ON COLUMN users.gcash_number IS 'GCash mobile number for payouts';
COMMENT ON COLUMN users.gcash_name IS 'Account name for GCash verification';

-- Step 2: Add payout tracking to orders table
-- =============================================

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS farmer_payout_amount DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS farmer_payout_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS paid_out_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN orders.farmer_payout_amount IS 'Amount to be paid to farmer (after commission)';
COMMENT ON COLUMN orders.farmer_payout_status IS 'pending, available, paid_out';
COMMENT ON COLUMN orders.paid_out_at IS 'When the farmer was paid for this order';

-- Create enum for payout status if not exists
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'farmer_payout_status') THEN
    CREATE TYPE farmer_payout_status AS ENUM ('pending', 'available', 'paid_out');
  END IF;
END $$;

-- Step 3: Create payout_requests table
-- =============================================

CREATE TABLE IF NOT EXISTS payout_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending',
  payment_method TEXT NOT NULL, -- 'gcash' or 'bank_transfer'
  payment_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  request_notes TEXT,
  admin_notes TEXT,
  rejection_reason TEXT,
  processed_by UUID REFERENCES users(id),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
  CONSTRAINT valid_payment_method CHECK (payment_method IN ('gcash', 'bank_transfer'))
);

COMMENT ON TABLE payout_requests IS 'Farmer payout requests - processed manually by admin';
COMMENT ON COLUMN payout_requests.payment_details IS 'JSON with account number, name, bank details';
COMMENT ON COLUMN payout_requests.status IS 'pending: awaiting admin review, processing: admin is sending money, completed: money sent, rejected: request denied';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payout_requests_farmer ON payout_requests(farmer_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON payout_requests(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_created ON payout_requests(created_at DESC);

-- Step 4: Create payout_logs table for audit trail
-- =============================================

CREATE TABLE IF NOT EXISTS payout_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payout_request_id UUID NOT NULL REFERENCES payout_requests(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  performed_by UUID REFERENCES users(id),
  notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_action CHECK (action IN ('requested', 'approved', 'rejected', 'completed', 'cancelled'))
);

COMMENT ON TABLE payout_logs IS 'Audit trail for all payout request actions';
COMMENT ON COLUMN payout_logs.action IS 'Type of action performed on the payout request';

-- Create index for logs
CREATE INDEX IF NOT EXISTS idx_payout_logs_request ON payout_logs(payout_request_id);
CREATE INDEX IF NOT EXISTS idx_payout_logs_created ON payout_logs(created_at DESC);

-- Step 5: Create function to update timestamps
-- =============================================

CREATE OR REPLACE FUNCTION update_payout_request_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_payout_request_timestamp ON payout_requests;
CREATE TRIGGER update_payout_request_timestamp
  BEFORE UPDATE ON payout_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_payout_request_timestamp();

-- Step 6: Create function to calculate available balance
-- =============================================

CREATE OR REPLACE FUNCTION calculate_farmer_available_balance(farmer_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_amount DECIMAL := 0;
  platform_commission DECIMAL := 0.10; -- 10% commission
BEGIN
  -- Sum all completed orders that haven't been paid out yet
  SELECT COALESCE(SUM(total_amount * (1 - platform_commission)), 0)
  INTO total_amount
  FROM orders
  WHERE farmer_id = farmer_uuid
    AND farmer_status = 'completed'
    AND (farmer_payout_status = 'pending' OR farmer_payout_status = 'available')
    AND paid_out_at IS NULL;
  
  RETURN total_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_farmer_available_balance IS 'Calculate available balance for farmer after 10% commission';

-- Step 7: Create function to calculate pending earnings
-- =============================================

CREATE OR REPLACE FUNCTION calculate_farmer_pending_earnings(farmer_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_amount DECIMAL := 0;
  platform_commission DECIMAL := 0.10; -- 10% commission
BEGIN
  -- Sum all orders that are in progress (not completed yet)
  SELECT COALESCE(SUM(total_amount * (1 - platform_commission)), 0)
  INTO total_amount
  FROM orders
  WHERE farmer_id = farmer_uuid
    AND farmer_status IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'readyForPickup')
    AND paid_out_at IS NULL;
  
  RETURN total_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_farmer_pending_earnings IS 'Calculate pending earnings from orders in progress';

-- Step 8: Create function to mark orders as paid out
-- =============================================

CREATE OR REPLACE FUNCTION mark_orders_as_paid_out(
  farmer_uuid UUID,
  payout_amount DECIMAL
)
RETURNS INTEGER AS $$
DECLARE
  orders_updated INTEGER := 0;
BEGIN
  -- Mark completed orders as paid out
  WITH updated_orders AS (
    UPDATE orders
    SET 
      farmer_payout_status = 'paid_out',
      paid_out_at = NOW()
    WHERE farmer_id = farmer_uuid
      AND farmer_status = 'completed'
      AND (farmer_payout_status = 'pending' OR farmer_payout_status = 'available')
      AND paid_out_at IS NULL
    RETURNING id
  )
  SELECT COUNT(*) INTO orders_updated FROM updated_orders;
  
  RETURN orders_updated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION mark_orders_as_paid_out IS 'Mark all eligible orders as paid out when payout is completed';

-- Step 9: Set up Row Level Security (RLS)
-- =============================================

-- Enable RLS
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_logs ENABLE ROW LEVEL SECURITY;

-- Farmers can view their own payout requests
CREATE POLICY "Farmers can view own payout requests"
  ON payout_requests FOR SELECT
  USING (auth.uid() = farmer_id);

-- Farmers can create payout requests
CREATE POLICY "Farmers can create payout requests"
  ON payout_requests FOR INSERT
  WITH CHECK (
    auth.uid() = farmer_id
    AND EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'farmer'
    )
  );

-- Farmers can update their pending requests (cancel)
CREATE POLICY "Farmers can cancel pending requests"
  ON payout_requests FOR UPDATE
  USING (
    auth.uid() = farmer_id
    AND status = 'pending'
  )
  WITH CHECK (
    auth.uid() = farmer_id
    AND status = 'pending'
  );

-- Admins can view all payout requests
CREATE POLICY "Admins can view all payout requests"
  ON payout_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admins can update any payout request
CREATE POLICY "Admins can update payout requests"
  ON payout_requests FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Payout logs policies
CREATE POLICY "Users can view logs for their requests"
  ON payout_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM payout_requests
      WHERE payout_requests.id = payout_logs.payout_request_id
      AND (payout_requests.farmer_id = auth.uid() OR payout_requests.processed_by = auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- System can insert logs
CREATE POLICY "Allow insert logs"
  ON payout_logs FOR INSERT
  WITH CHECK (true);

-- Step 10: Create helper views
-- =============================================

-- View for farmer wallet summary
CREATE OR REPLACE VIEW farmer_wallet_summary AS
SELECT 
  u.id as farmer_id,
  u.full_name,
  u.store_name,
  calculate_farmer_available_balance(u.id) as available_balance,
  calculate_farmer_pending_earnings(u.id) as pending_earnings,
  COALESCE(
    (SELECT SUM(amount) 
     FROM payout_requests 
     WHERE farmer_id = u.id 
     AND status = 'completed'
    ), 0
  ) as total_paid_out,
  COALESCE(
    (SELECT COUNT(*) 
     FROM payout_requests 
     WHERE farmer_id = u.id 
     AND status = 'pending'
    ), 0
  ) as pending_requests_count
FROM users u
WHERE u.role = 'farmer';

COMMENT ON VIEW farmer_wallet_summary IS 'Quick summary of farmer wallet balances and payout info';

-- Step 11: Create trigger to log payout request changes
-- =============================================

CREATE OR REPLACE FUNCTION log_payout_request_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Log status changes
  IF TG_OP = 'INSERT' THEN
    INSERT INTO payout_logs (payout_request_id, action, performed_by, notes)
    VALUES (NEW.id, 'requested', NEW.farmer_id, NEW.request_notes);
    
  ELSIF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    IF NEW.status = 'processing' THEN
      INSERT INTO payout_logs (payout_request_id, action, performed_by, notes)
      VALUES (NEW.id, 'approved', NEW.processed_by, NEW.admin_notes);
      
    ELSIF NEW.status = 'completed' THEN
      INSERT INTO payout_logs (payout_request_id, action, performed_by, notes)
      VALUES (NEW.id, 'completed', NEW.processed_by, NEW.admin_notes);
      
      -- Mark orders as paid out
      PERFORM mark_orders_as_paid_out(NEW.farmer_id, NEW.amount);
      
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO payout_logs (payout_request_id, action, performed_by, notes)
      VALUES (NEW.id, 'rejected', NEW.processed_by, NEW.rejection_reason);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_payout_request_changes ON payout_requests;
CREATE TRIGGER log_payout_request_changes
  AFTER INSERT OR UPDATE ON payout_requests
  FOR EACH ROW
  EXECUTE FUNCTION log_payout_request_changes();

-- Step 12: Insert sample data for testing (optional)
-- =============================================

-- This is commented out - uncomment to add test data
/*
-- Add GCash info to a test farmer
UPDATE users 
SET 
  gcash_number = '09171234567',
  gcash_name = 'Juan Dela Cruz'
WHERE role = 'farmer' 
LIMIT 1;
*/

-- =============================================
-- Migration Complete!
-- =============================================

-- Verify tables created
SELECT 
  'payout_requests' as table_name,
  COUNT(*) as row_count
FROM payout_requests
UNION ALL
SELECT 
  'payout_logs' as table_name,
  COUNT(*) as row_count
FROM payout_logs;

-- Show summary
SELECT 
  'Manual Payout System installed successfully!' as status,
  'Tables: payout_requests, payout_logs' as created_tables,
  'Functions: calculate_farmer_available_balance, mark_orders_as_paid_out' as created_functions,
  'RLS policies enabled for security' as security,
  'Ready to use!' as next_step;
