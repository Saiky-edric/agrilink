-- =====================================================
-- Fix Payment Status Auto-Updates
-- =====================================================
-- This migration ensures payment_status is automatically
-- updated based on payment verification and order status
-- =====================================================

-- 1. Function to update payment_status based on payment verification
CREATE OR REPLACE FUNCTION update_payment_status_on_verification()
RETURNS TRIGGER AS $$
BEGIN
  -- Update payment_status when payment_verified changes
  IF NEW.payment_verified IS DISTINCT FROM OLD.payment_verified THEN
    
    -- Case 1: Payment verified
    IF NEW.payment_verified = true THEN
      NEW.payment_status := 'paid';
    
    -- Case 2: Payment rejected
    ELSIF NEW.payment_verified = false THEN
      NEW.payment_status := 'failed';
    
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to update payment_status on order completion (for COD/COP)
CREATE OR REPLACE FUNCTION update_payment_status_on_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Update payment_status when order is completed
  IF NEW.farmer_status = 'completed' AND OLD.farmer_status != 'completed' THEN
    
    -- For COD/COP orders, mark as paid when completed
    IF NEW.payment_method IN ('cod', 'cop') AND NEW.payment_status = 'pending' THEN
      NEW.payment_status := 'paid';
      NEW.paid_at := now();
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to update payment_status on refund
CREATE OR REPLACE FUNCTION update_payment_status_on_refund()
RETURNS TRIGGER AS $$
BEGIN
  -- Update payment_status when refund is completed
  IF NEW.refund_status = 'completed' AND 
     (OLD.refund_status IS NULL OR OLD.refund_status != 'completed') THEN
    NEW.payment_status := 'refunded';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_update_payment_status_on_verification ON orders;
DROP TRIGGER IF EXISTS trigger_update_payment_status_on_completion ON orders;
DROP TRIGGER IF EXISTS trigger_update_payment_status_on_refund ON orders;

-- 5. Create triggers
CREATE TRIGGER trigger_update_payment_status_on_verification
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.payment_verified IS DISTINCT FROM OLD.payment_verified)
  EXECUTE FUNCTION update_payment_status_on_verification();

CREATE TRIGGER trigger_update_payment_status_on_completion
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.farmer_status IS DISTINCT FROM OLD.farmer_status)
  EXECUTE FUNCTION update_payment_status_on_completion();

CREATE TRIGGER trigger_update_payment_status_on_refund
  BEFORE UPDATE ON orders
  FOR EACH ROW
  WHEN (NEW.refund_status IS DISTINCT FROM OLD.refund_status)
  EXECUTE FUNCTION update_payment_status_on_refund();

-- 6. Backfill existing orders with correct payment_status
-- Update GCash orders with verified payment
UPDATE orders
SET payment_status = 'paid'
WHERE payment_method = 'gcash'
  AND payment_verified = true
  AND payment_status = 'pending';

-- Update GCash orders with rejected payment
UPDATE orders
SET payment_status = 'failed'
WHERE payment_method = 'gcash'
  AND payment_verified = false
  AND payment_status = 'pending';

-- Update completed COD/COP orders
UPDATE orders
SET payment_status = 'paid',
    paid_at = completed_at
WHERE payment_method IN ('cod', 'cop')
  AND farmer_status = 'completed'
  AND payment_status = 'pending';

-- Update refunded orders
UPDATE orders
SET payment_status = 'refunded'
WHERE refund_status = 'completed'
  AND payment_status != 'refunded';

-- 7. Add helpful comments
COMMENT ON FUNCTION update_payment_status_on_verification IS 
'Automatically updates payment_status to paid/failed when payment is verified/rejected';

COMMENT ON FUNCTION update_payment_status_on_completion IS 
'Automatically updates payment_status to paid for COD/COP orders when completed';

COMMENT ON FUNCTION update_payment_status_on_refund IS 
'Automatically updates payment_status to refunded when refund is completed';

-- Success message
DO $$
DECLARE
  verified_count INTEGER;
  rejected_count INTEGER;
  cod_count INTEGER;
  refunded_count INTEGER;
BEGIN
  -- Count updates
  SELECT COUNT(*) INTO verified_count
  FROM orders
  WHERE payment_method = 'gcash'
    AND payment_verified = true
    AND payment_status = 'paid';
  
  SELECT COUNT(*) INTO rejected_count
  FROM orders
  WHERE payment_method = 'gcash'
    AND payment_verified = false
    AND payment_status = 'failed';
  
  SELECT COUNT(*) INTO cod_count
  FROM orders
  WHERE payment_method IN ('cod', 'cop')
    AND farmer_status = 'completed'
    AND payment_status = 'paid';
  
  SELECT COUNT(*) INTO refunded_count
  FROM orders
  WHERE payment_status = 'refunded';
  
  RAISE NOTICE '✅ Payment Status Auto-Update System created successfully!';
  RAISE NOTICE '📊 Backfill Results:';
  RAISE NOTICE '   - GCash Verified → Paid: % orders', verified_count;
  RAISE NOTICE '   - GCash Rejected → Failed: % orders', rejected_count;
  RAISE NOTICE '   - COD/COP Completed → Paid: % orders', cod_count;
  RAISE NOTICE '   - Refunded: % orders', refunded_count;
  RAISE NOTICE '🔧 Triggers created: 3 auto-update triggers';
  RAISE NOTICE '🔄 Future orders will auto-update payment_status';
END $$;
