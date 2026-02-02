-- =====================================================
-- Handle Cancelled Transactions for Unverified Payments
-- =====================================================
-- This migration ensures transaction records are properly
-- updated when orders are cancelled, preventing orphaned
-- transaction records
-- =====================================================

-- 1. Function to update transaction when order is cancelled
CREATE OR REPLACE FUNCTION update_transaction_on_order_cancel()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if order status changed to cancelled
  IF NEW.farmer_status = 'cancelled' AND 
     OLD.farmer_status != 'cancelled' THEN
    
    -- For GCash orders, update the transaction status
    IF NEW.payment_method = 'gcash' THEN
      
      -- Case 1: Payment was never verified (pending or null)
      IF NEW.payment_verified IS NULL OR NEW.payment_verified = false THEN
        UPDATE transactions
        SET 
          status = 'cancelled',
          completed_at = now(),
          refund_notes = CASE
            WHEN NEW.payment_verified = false THEN 'Order cancelled - Payment was rejected'
            ELSE 'Order cancelled before payment verification'
          END
        WHERE order_id = NEW.id 
          AND type = 'payment'
          AND status = 'pending';
      END IF;
      
      -- Case 2: Payment was verified but order cancelled
      -- (This shouldn't happen with Option B, but handle it anyway)
      IF NEW.payment_verified = true THEN
        -- Log a warning - this should go through refund process
        RAISE NOTICE 'Warning: Verified payment order cancelled without refund process. Order ID: %', NEW.id;
      END IF;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_update_transaction_on_order_cancel ON orders;

-- 3. Create the trigger
CREATE TRIGGER trigger_update_transaction_on_order_cancel
  AFTER UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.farmer_status IS DISTINCT FROM OLD.farmer_status)
  EXECUTE FUNCTION update_transaction_on_order_cancel();

-- 4. Clean up any existing orphaned transactions (one-time cleanup)
-- This updates transactions that were left in 'pending' status for cancelled orders
UPDATE transactions t
SET 
  status = 'cancelled',
  completed_at = now(),
  refund_notes = 'Transaction cancelled - Order was cancelled before payment verification (cleanup)'
FROM orders o
WHERE t.order_id = o.id
  AND t.type = 'payment'
  AND t.status = 'pending'
  AND o.farmer_status = 'cancelled'
  AND o.payment_method = 'gcash'
  AND (o.payment_verified IS NULL OR o.payment_verified = false);

-- 5. Add helpful comment
COMMENT ON FUNCTION update_transaction_on_order_cancel IS 
'Automatically updates transaction status when an order is cancelled. Prevents orphaned transaction records for cancelled unverified payments.';

-- Success message
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  -- Count how many transactions were cleaned up
  SELECT COUNT(*) INTO updated_count
  FROM transactions t
  JOIN orders o ON t.order_id = o.id
  WHERE t.status = 'cancelled'
    AND t.refund_notes LIKE '%cleanup%';
    
  RAISE NOTICE '✅ Transaction cancellation handler created successfully!';
  RAISE NOTICE '📊 Cleaned up % orphaned transaction(s)', updated_count;
  RAISE NOTICE '🔧 Trigger: trigger_update_transaction_on_order_cancel';
  RAISE NOTICE '🛡️  Protection: Transactions now auto-update on order cancellation';
END $$;
