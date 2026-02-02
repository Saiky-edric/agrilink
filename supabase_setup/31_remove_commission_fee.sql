-- =====================================================
-- 31_remove_commission_fee.sql
-- Remove 10% Platform Commission - Farmers Get 100%
-- =====================================================
-- This migration removes the 10% commission and ensures
-- farmers receive 100% of their order amounts
-- =====================================================

-- Step 1: Update calculate_farmer_available_balance function (100% instead of 90%)
CREATE OR REPLACE FUNCTION calculate_farmer_available_balance(farmer_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  completed_earnings NUMERIC;
  already_paid_out NUMERIC;
  available_balance NUMERIC;
BEGIN
  -- Calculate total earnings from completed orders (100% instead of 90%)
  SELECT COALESCE(SUM(total_amount), 0)
  INTO completed_earnings
  FROM orders
  WHERE farmer_id = farmer_user_id
    AND farmer_status = 'completed'
    AND (farmer_payout_status IS NULL OR farmer_payout_status = 'pending');

  -- Calculate already paid out amount
  SELECT COALESCE(SUM(amount), 0)
  INTO already_paid_out
  FROM payout_requests
  WHERE farmer_id = farmer_user_id
    AND status = 'completed';

  -- Available = completed earnings - already paid out
  available_balance := completed_earnings - already_paid_out;

  RETURN GREATEST(available_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Update calculate_farmer_pending_earnings function (100% instead of 90%)
CREATE OR REPLACE FUNCTION calculate_farmer_pending_earnings(farmer_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  pending_amount NUMERIC;
BEGIN
  -- Calculate total from orders that are not yet completed (100% instead of 90%)
  SELECT COALESCE(SUM(total_amount), 0)
  INTO pending_amount
  FROM orders
  WHERE farmer_id = farmer_user_id
    AND farmer_status IN ('newOrder', 'accepted', 'preparing', 'ready', 'outForDelivery', 'readyForPickup');

  RETURN GREATEST(pending_amount, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Update mark_orders_as_paid_out function (no commission calculation)
CREATE OR REPLACE FUNCTION mark_orders_as_paid_out(
  farmer_user_id UUID,
  payout_amount NUMERIC
)
RETURNS VOID AS $$
DECLARE
  remaining_amount NUMERIC;
  order_record RECORD;
BEGIN
  remaining_amount := payout_amount;
  
  -- Mark completed orders as paid out until we've accounted for the payout amount
  FOR order_record IN 
    SELECT id, total_amount
    FROM orders
    WHERE farmer_id = farmer_user_id
      AND farmer_status = 'completed'
      AND (farmer_payout_status IS NULL OR farmer_payout_status = 'pending')
    ORDER BY completed_at ASC
  LOOP
    -- Full order amount (100% instead of 90%)
    IF remaining_amount >= order_record.total_amount THEN
      -- This order is fully paid out
      UPDATE orders
      SET 
        farmer_payout_status = 'paid',
        farmer_payout_amount = order_record.total_amount,
        paid_out_at = now()
      WHERE id = order_record.id;
      
      remaining_amount := remaining_amount - order_record.total_amount;
    ELSE
      -- Partial payout for this order
      UPDATE orders
      SET 
        farmer_payout_status = 'paid',
        farmer_payout_amount = remaining_amount,
        paid_out_at = now()
      WHERE id = order_record.id;
      
      remaining_amount := 0;
    END IF;
    
    EXIT WHEN remaining_amount <= 0;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Fix existing farmer balances to reflect 100% earnings
-- This recalculates wallet balances for all farmers based on completed orders

DO $$
DECLARE
  farmer_record RECORD;
  new_balance NUMERIC;
BEGIN
  FOR farmer_record IN 
    SELECT id, wallet_balance 
    FROM users 
    WHERE role = 'farmer'
  LOOP
    -- Recalculate balance using new 100% logic
    new_balance := calculate_farmer_available_balance(farmer_record.id);
    
    -- Update farmer's wallet balance
    UPDATE users
    SET wallet_balance = new_balance
    WHERE id = farmer_record.id;
    
    RAISE NOTICE 'Updated farmer % balance from % to %', 
      farmer_record.id, 
      farmer_record.wallet_balance, 
      new_balance;
  END LOOP;
END $$;

-- Step 5: Update platform_settings to reflect 0% commission
UPDATE platform_settings
SET commission_rate = 0.00
WHERE singleton_guard = true;

-- Step 6: Add comment for documentation
COMMENT ON FUNCTION calculate_farmer_available_balance IS 'Calculates farmer available balance at 100% of order amounts (no commission)';
COMMENT ON FUNCTION calculate_farmer_pending_earnings IS 'Calculates farmer pending earnings at 100% of order amounts (no commission)';
COMMENT ON FUNCTION mark_orders_as_paid_out IS 'Marks orders as paid out using 100% of order amounts (no commission)';

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Changes made:
-- 1. Farmers now receive 100% of order amounts
-- 2. All balance calculations updated
-- 3. Existing balances recalculated
-- 4. Platform commission rate set to 0%
-- =====================================================
