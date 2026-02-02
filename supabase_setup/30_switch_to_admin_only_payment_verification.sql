-- =====================================================
-- 30_switch_to_admin_only_payment_verification.sql
-- Switch Payment Verification to Admin-Only
-- =====================================================
-- This updates the payment verification system to only
-- allow admins to verify payments, not farmers
-- =====================================================

-- Step 1: Drop the farmer verification policy
DROP POLICY IF EXISTS "Farmers can verify payments for their orders" ON payment_verification_logs;

-- Step 2: Update the verify_order_payment function to only allow admins
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
  -- Check if user is admin ONLY (removed farmer check)
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id = p_verified_by
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can verify payments';
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

-- Step 3: Update RLS policy - farmers can view their orders' payment logs but NOT create verification logs
DROP POLICY IF EXISTS "Farmers can view payment logs for their orders" ON payment_verification_logs;

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

-- Step 4: Ensure only admins can create verification logs
CREATE POLICY "Only admins can create verification logs"
ON payment_verification_logs
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
  AND action IN ('verified', 'rejected')
);

-- Step 5: Add helpful view for admins to see pending verifications with buyer info
CREATE OR REPLACE VIEW admin_pending_payment_verifications AS
SELECT 
  o.id as order_id,
  o.created_at as order_date,
  o.updated_at as proof_uploaded_at,
  o.total_amount,
  o.payment_reference,
  o.payment_screenshot_url,
  o.payment_notes,
  -- Buyer info
  b.id as buyer_id,
  b.full_name as buyer_name,
  b.email as buyer_email,
  b.phone_number as buyer_phone,
  -- Farmer info
  f.id as farmer_id,
  f.full_name as farmer_name,
  f.store_name as store_name,
  f.email as farmer_email,
  f.phone_number as farmer_phone
FROM orders o
JOIN users b ON o.buyer_id = b.id
JOIN users f ON o.farmer_id = f.id
WHERE o.payment_method = 'gcash'
  AND o.payment_screenshot_url IS NOT NULL
  AND o.payment_verified = false
  AND o.payment_verified_at IS NULL
ORDER BY o.updated_at DESC;

-- Grant access to admins
GRANT SELECT ON admin_pending_payment_verifications TO authenticated;

-- Step 6: Add comment for clarity
COMMENT ON VIEW admin_pending_payment_verifications IS 'Admin-only view of pending GCash payment verifications with buyer and farmer details';

-- Step 7: Create notification trigger for farmers when payment is verified by admin
CREATE OR REPLACE FUNCTION notify_farmer_payment_verified()
RETURNS TRIGGER AS $$
BEGIN
  -- Only send notification if payment was just verified (changed from false to true)
  IF NEW.payment_verified = true AND (OLD.payment_verified IS NULL OR OLD.payment_verified = false) THEN
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      related_id,
      data,
      created_at
    )
    VALUES (
      NEW.farmer_id,
      'Payment Verified',
      'Payment for order #' || SUBSTRING(NEW.id::text, 1, 8) || ' has been verified by admin. You can now process this order.',
      'order',
      NEW.id,
      jsonb_build_object(
        'order_id', NEW.id,
        'amount', NEW.total_amount,
        'verified_at', NEW.payment_verified_at
      ),
      now()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_farmer_payment_verified ON orders;

-- Create trigger
CREATE TRIGGER trigger_notify_farmer_payment_verified
  AFTER UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.payment_verified = true AND (OLD.payment_verified IS NULL OR OLD.payment_verified = false))
  EXECUTE FUNCTION notify_farmer_payment_verified();

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Changes made:
-- 1. Only admins can verify payments now
-- 2. Farmers can view payment status but cannot verify
-- 3. Farmers receive notification when admin verifies
-- 4. Admin view created for easy verification
-- =====================================================
