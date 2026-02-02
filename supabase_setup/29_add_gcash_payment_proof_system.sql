-- =====================================================
-- 29_add_gcash_payment_proof_system.sql
-- Manual GCash Payment Collection System
-- =====================================================
-- This migration adds support for buyers to upload payment proof
-- when paying via GCash to AgriLink's master account
-- =====================================================

-- Step 1: Add payment proof columns to orders table
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS payment_screenshot_url TEXT,
ADD COLUMN IF NOT EXISTS payment_reference TEXT,
ADD COLUMN IF NOT EXISTS payment_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS payment_verified_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS payment_verified_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS payment_notes TEXT;

-- Step 2: Add AgriLink master GCash account to platform_settings
-- Your platform_settings table uses direct columns, so we'll add new columns
ALTER TABLE platform_settings
ADD COLUMN IF NOT EXISTS agrilink_gcash_number text DEFAULT '09171234567',
ADD COLUMN IF NOT EXISTS agrilink_gcash_name text DEFAULT 'AgriLink Marketplace',
ADD COLUMN IF NOT EXISTS gcash_payment_instructions text DEFAULT 'Please send payment to the GCash number above. After payment, upload a screenshot and enter the reference number.';

-- Update the existing row (since you have singleton_guard)
UPDATE platform_settings
SET 
  agrilink_gcash_number = '09171234567',
  agrilink_gcash_name = 'AgriLink Marketplace',
  gcash_payment_instructions = 'Please send payment to the GCash number above. After payment, upload a screenshot and enter the reference number.'
WHERE singleton_guard = true;

-- Step 3: Create payment verification log table
CREATE TABLE IF NOT EXISTS payment_verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('uploaded', 'verified', 'rejected')),
  performed_by UUID NOT NULL REFERENCES users(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Step 4: Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_orders_payment_verified ON orders(payment_verified);
CREATE INDEX IF NOT EXISTS idx_orders_payment_method ON orders(payment_method);
CREATE INDEX IF NOT EXISTS idx_payment_verification_logs_order_id ON payment_verification_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_verification_logs_created_at ON payment_verification_logs(created_at DESC);

-- Step 5: Enable RLS on payment_verification_logs
ALTER TABLE payment_verification_logs ENABLE ROW LEVEL SECURITY;

-- Step 6: RLS Policies for payment_verification_logs

-- Buyers can view their own payment logs
CREATE POLICY "Buyers can view own payment logs"
ON payment_verification_logs
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payment_verification_logs.order_id
    AND orders.buyer_id = auth.uid()
  )
);

-- Farmers can view payment logs for their orders
CREATE POLICY "Farmers can view payment logs for their orders"
ON payment_verification_logs
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payment_verification_logs.order_id
    AND orders.farmer_id = auth.uid()
  )
);

-- Admins can view all payment logs
CREATE POLICY "Admins can view all payment logs"
ON payment_verification_logs
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Buyers can insert logs when uploading payment proof
CREATE POLICY "Buyers can create payment logs"
ON payment_verification_logs
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payment_verification_logs.order_id
    AND orders.buyer_id = auth.uid()
  )
  AND action = 'uploaded'
);

-- Farmers can insert verification logs for their orders
CREATE POLICY "Farmers can verify payments for their orders"
ON payment_verification_logs
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payment_verification_logs.order_id
    AND orders.farmer_id = auth.uid()
  )
  AND action IN ('verified', 'rejected')
);

-- Admins can insert any verification logs
CREATE POLICY "Admins can create verification logs"
ON payment_verification_logs
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Step 7: Update orders RLS to allow payment proof upload
-- Buyers can update payment proof fields for their orders
CREATE POLICY "Buyers can upload payment proof"
ON orders
FOR UPDATE
USING (buyer_id = auth.uid())
WITH CHECK (buyer_id = auth.uid());

-- Step 8: Function to verify payment (for farmers/admins)
CREATE OR REPLACE FUNCTION verify_order_payment(
  p_order_id UUID,
  p_verified_by UUID,
  p_action TEXT, -- 'verified' or 'rejected'
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is farmer or admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id = p_verified_by
    AND (
      role = 'admin'
      OR (
        role = 'farmer'
        AND EXISTS (
          SELECT 1 FROM orders
          WHERE id = p_order_id
          AND farmer_id = p_verified_by
        )
      )
    )
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only farmers or admins can verify payments';
  END IF;

  -- Update order
  IF p_action = 'verified' THEN
    UPDATE orders
    SET 
      payment_verified = true,
      payment_verified_at = now(),
      payment_verified_by = p_verified_by,
      payment_notes = p_notes
    WHERE id = p_order_id;
  ELSE
    UPDATE orders
    SET 
      payment_verified = false,
      payment_verified_at = now(),
      payment_verified_by = p_verified_by,
      payment_notes = p_notes
    WHERE id = p_order_id;
  END IF;

  -- Log the action
  INSERT INTO payment_verification_logs (order_id, action, performed_by, notes)
  VALUES (p_order_id, p_action, p_verified_by, p_notes);
END;
$$;

-- Step 9: Function to get pending payment verifications (for admins)
CREATE OR REPLACE FUNCTION get_pending_payment_verifications()
RETURNS TABLE (
  order_id UUID,
  buyer_name TEXT,
  farmer_name TEXT,
  total_amount NUMERIC,
  payment_reference TEXT,
  payment_screenshot_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  uploaded_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id as order_id,
    b.full_name as buyer_name,
    f.full_name as farmer_name,
    o.total_amount,
    o.payment_reference,
    o.payment_screenshot_url,
    o.created_at,
    o.updated_at as uploaded_at
  FROM orders o
  JOIN users b ON o.buyer_id = b.id
  JOIN users f ON o.farmer_id = f.id
  WHERE o.payment_method = 'gcash'
    AND o.payment_screenshot_url IS NOT NULL
    AND o.payment_verified = false
  ORDER BY o.updated_at DESC;
END;
$$;

-- Step 10: Add comments for documentation
COMMENT ON COLUMN orders.payment_screenshot_url IS 'URL to uploaded payment proof screenshot';
COMMENT ON COLUMN orders.payment_reference IS 'GCash reference number from buyer';
COMMENT ON COLUMN orders.payment_verified IS 'Whether payment has been verified by farmer/admin';
COMMENT ON COLUMN orders.payment_verified_at IS 'Timestamp when payment was verified';
COMMENT ON COLUMN orders.payment_verified_by IS 'User ID who verified the payment';
COMMENT ON COLUMN orders.payment_notes IS 'Notes about payment verification';

COMMENT ON TABLE payment_verification_logs IS 'Audit trail for payment verification actions';

-- Step 11: Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION verify_order_payment TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_payment_verifications TO authenticated;

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Next steps:
-- 1. Update AgriLink GCash number in platform_settings
-- 2. Create payment proof upload UI
-- 3. Create payment verification UI for farmers/admins
-- =====================================================
