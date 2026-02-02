-- =====================================================
-- 32_separate_cod_and_prepaid_earnings.sql
-- Separate COD Earnings from Payable Balance
-- =====================================================
-- This migration separates COD earnings (already paid)
-- from prepaid earnings (available for payout)
-- =====================================================

-- Step 1: Verify columns exist and add comments
-- Note: wallet_balance, total_earnings, pending_earnings already exist in schema
-- We'll add total_lifetime_earnings if it doesn't exist

DO $$ 
BEGIN
  -- Add total_lifetime_earnings if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'total_lifetime_earnings'
  ) THEN
    ALTER TABLE users ADD COLUMN total_lifetime_earnings NUMERIC DEFAULT 0.00;
  END IF;
END $$;

COMMENT ON COLUMN users.total_lifetime_earnings IS 'Total earnings from all orders (COD + prepaid) - for analytics/visualization only';
COMMENT ON COLUMN users.wallet_balance IS 'Available balance from prepaid orders only - can be withdrawn';
COMMENT ON COLUMN users.total_earnings IS 'Total amount paid out to farmer (historical)';

-- Step 2: Drop existing function and recreate with updated logic
DROP FUNCTION IF EXISTS complete_order_and_deduct_stock(UUID);

-- Update complete_order_and_deduct_stock function to handle COD vs Prepaid differently
CREATE OR REPLACE FUNCTION complete_order_and_deduct_stock(order_uuid UUID)
RETURNS void AS $$
DECLARE
  order_record RECORD;
  item_record RECORD;
  order_payment_method TEXT;
  order_delivery_fee NUMERIC;
  farmer_earnings NUMERIC;
BEGIN
  -- Get order details
  SELECT * INTO order_record FROM orders WHERE id = order_uuid;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  -- Get payment method and delivery fee
  order_payment_method := order_record.payment_method;
  order_delivery_fee := COALESCE(order_record.delivery_fee, 0);
  
  -- Deduct stock for each order item
  FOR item_record IN 
    SELECT product_id, quantity 
    FROM order_items 
    WHERE order_id = order_uuid
  LOOP
    UPDATE products 
    SET stock = stock - item_record.quantity
    WHERE id = item_record.product_id
      AND stock >= item_record.quantity;
    
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Insufficient stock for product %', item_record.product_id;
    END IF;
  END LOOP;

  -- Calculate farmer earnings based on payment method
  IF order_payment_method IN ('cod', 'cop') THEN
    -- COD/COP: Farmer gets product amount only (courier already deducted delivery fee)
    farmer_earnings := order_record.total_amount - order_delivery_fee;
    
    -- Update farmer's total lifetime earnings (for stats)
    UPDATE users
    SET total_lifetime_earnings = total_lifetime_earnings + farmer_earnings
    WHERE id = order_record.farmer_id;
    
    -- Mark order as already paid out (farmer received cash from courier)
    UPDATE orders
    SET 
      farmer_payout_status = 'paid',
      farmer_payout_amount = farmer_earnings,
      paid_out_at = now(),
      updated_at = now()
    WHERE id = order_uuid;
    
  ELSE
    -- Prepaid (GCash): Farmer gets full amount, will pay courier later
    farmer_earnings := order_record.total_amount;
    
    -- Update farmer's wallet balance (available for payout)
    UPDATE users
    SET 
      wallet_balance = wallet_balance + farmer_earnings,
      total_lifetime_earnings = total_lifetime_earnings + farmer_earnings
    WHERE id = order_record.farmer_id;
    
    -- Mark as pending payout
    UPDATE orders
    SET 
      farmer_payout_status = 'pending',
      updated_at = now()
    WHERE id = order_uuid;
  END IF;

  -- Update order status to completed
  UPDATE orders
  SET 
    farmer_status = 'completed',
    completed_at = now(),
    updated_at = now()
  WHERE id = order_uuid;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Drop dependent view first, then function
DROP VIEW IF EXISTS farmer_wallet_summary CASCADE;
DROP FUNCTION IF EXISTS calculate_farmer_available_balance(UUID);

-- Update calculate_farmer_available_balance to only count prepaid orders
CREATE OR REPLACE FUNCTION calculate_farmer_available_balance(farmer_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  completed_earnings NUMERIC;
  already_paid_out NUMERIC;
  available_balance NUMERIC;
BEGIN
  -- Calculate total earnings from completed PREPAID orders only (exclude COD)
  SELECT COALESCE(SUM(total_amount), 0)
  INTO completed_earnings
  FROM orders
  WHERE farmer_id = farmer_user_id
    AND farmer_status = 'completed'
    AND payment_method NOT IN ('cod', 'cop') -- Exclude COD/COP
    AND (farmer_payout_status IS NULL OR farmer_payout_status = 'pending');

  -- Calculate already paid out amount
  SELECT COALESCE(SUM(amount), 0)
  INTO already_paid_out
  FROM payout_requests
  WHERE farmer_id = farmer_user_id
    AND status = 'completed';

  -- Available = completed prepaid earnings - already paid out
  available_balance := completed_earnings - already_paid_out;

  RETURN GREATEST(available_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Drop function (view already dropped in step 3)
DROP FUNCTION IF EXISTS calculate_farmer_pending_earnings(UUID);

-- Update calculate_farmer_pending_earnings to only count prepaid orders
CREATE OR REPLACE FUNCTION calculate_farmer_pending_earnings(farmer_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  pending_amount NUMERIC;
BEGIN
  -- Calculate total from PREPAID orders that are not yet completed (exclude COD)
  SELECT COALESCE(SUM(total_amount), 0)
  INTO pending_amount
  FROM orders
  WHERE farmer_id = farmer_user_id
    AND farmer_status IN ('newOrder', 'accepted', 'preparing', 'ready', 'outForDelivery', 'readyForPickup')
    AND payment_method NOT IN ('cod', 'cop'); -- Exclude COD/COP

  RETURN GREATEST(pending_amount, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create function to get farmer's COD earnings (for display only)
CREATE OR REPLACE FUNCTION calculate_farmer_cod_earnings(farmer_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  cod_earnings NUMERIC;
BEGIN
  -- Calculate total from COD/COP orders (already paid to farmer via courier)
  SELECT COALESCE(SUM(farmer_payout_amount), 0)
  INTO cod_earnings
  FROM orders
  WHERE farmer_id = farmer_user_id
    AND payment_method IN ('cod', 'cop')
    AND farmer_payout_status = 'paid';

  RETURN GREATEST(cod_earnings, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Backfill existing data
DO $$
DECLARE
  farmer_record RECORD;
  cod_total NUMERIC;
  prepaid_total NUMERIC;
  lifetime_total NUMERIC;
BEGIN
  FOR farmer_record IN 
    SELECT id FROM users WHERE role = 'farmer'
  LOOP
    -- Calculate COD earnings (already paid)
    SELECT COALESCE(SUM(total_amount - COALESCE(delivery_fee, 0)), 0)
    INTO cod_total
    FROM orders
    WHERE farmer_id = farmer_record.id
      AND farmer_status = 'completed'
      AND payment_method IN ('cod', 'cop');
    
    -- Calculate prepaid earnings
    SELECT COALESCE(SUM(total_amount), 0)
    INTO prepaid_total
    FROM orders
    WHERE farmer_id = farmer_record.id
      AND farmer_status = 'completed'
      AND payment_method NOT IN ('cod', 'cop');
    
    -- Total lifetime earnings
    lifetime_total := cod_total + prepaid_total;
    
    -- Update farmer records
    UPDATE users
    SET total_lifetime_earnings = lifetime_total
    WHERE id = farmer_record.id;
    
    -- Mark COD orders as paid
    UPDATE orders
    SET 
      farmer_payout_status = 'paid',
      farmer_payout_amount = total_amount - COALESCE(delivery_fee, 0),
      paid_out_at = completed_at
    WHERE farmer_id = farmer_record.id
      AND payment_method IN ('cod', 'cop')
      AND farmer_status = 'completed'
      AND farmer_payout_status IS NULL;
    
    RAISE NOTICE 'Updated farmer %: COD=%, Prepaid=%, Lifetime=%', 
      farmer_record.id, cod_total, prepaid_total, lifetime_total;
  END LOOP;
END $$;

-- Step 7: Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_farmer_cod_earnings TO authenticated;

-- Step 8: Create view for farmer wallet summary
CREATE OR REPLACE VIEW farmer_wallet_summary AS
SELECT 
  u.id as farmer_id,
  u.full_name as farmer_name,
  u.wallet_balance as available_for_payout,
  calculate_farmer_pending_earnings(u.id) as pending_earnings,
  calculate_farmer_cod_earnings(u.id) as cod_earnings,
  u.total_lifetime_earnings,
  u.total_earnings as total_paid_out
FROM users u
WHERE u.role = 'farmer';

GRANT SELECT ON farmer_wallet_summary TO authenticated;

COMMENT ON VIEW farmer_wallet_summary IS 'Complete farmer wallet overview showing COD (already paid) and prepaid (payable) earnings separately';

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Changes made:
-- 1. Added total_lifetime_earnings for tracking all earnings
-- 2. wallet_balance now only includes prepaid orders
-- 3. COD orders marked as paid immediately
-- 4. Farmer earnings calculation updated
-- 5. Existing data backfilled correctly
-- =====================================================
