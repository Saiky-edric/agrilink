-- =============================================
-- FIX: Payout Calculation to Exclude COD/COP Orders
-- =============================================
-- CRITICAL: Only count orders where payment was received by platform
-- Exclude: COD (Cash on Delivery) and COP (Cash on Pickup)
-- Include: gcash, bank_transfer, credit_card, debit_card, etc.
-- =============================================

-- Step 1: Update calculate_farmer_available_balance function
-- =============================================

CREATE OR REPLACE FUNCTION calculate_farmer_available_balance(farmer_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_amount DECIMAL := 0;
  platform_commission DECIMAL := 0.10; -- 10% commission
BEGIN
  -- Sum all completed orders that:
  -- 1. Haven't been paid out yet
  -- 2. Payment was received by platform (NOT cod or cop)
  SELECT COALESCE(SUM(total_amount * (1 - platform_commission)), 0)
  INTO total_amount
  FROM orders
  WHERE farmer_id = farmer_uuid
    AND farmer_status = 'completed'
    AND (farmer_payout_status = 'pending' OR farmer_payout_status = 'available')
    AND paid_out_at IS NULL
    AND payment_method IS NOT NULL
    AND payment_method NOT IN ('cod', 'cop'); -- CRITICAL: Exclude cash payments
  
  RETURN total_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_farmer_available_balance IS 
'Calculate available balance for farmer after 10% commission - ONLY from orders paid via platform (excludes COD/COP)';

-- Step 2: Update calculate_farmer_pending_earnings function
-- =============================================

CREATE OR REPLACE FUNCTION calculate_farmer_pending_earnings(farmer_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
  total_amount DECIMAL := 0;
  platform_commission DECIMAL := 0.10; -- 10% commission
BEGIN
  -- Sum all orders that are in progress
  -- AND payment will be received by platform (NOT cod or cop)
  SELECT COALESCE(SUM(total_amount * (1 - platform_commission)), 0)
  INTO total_amount
  FROM orders
  WHERE farmer_id = farmer_uuid
    AND farmer_status IN ('newOrder', 'accepted', 'toPack', 'toDeliver', 'readyForPickup')
    AND paid_out_at IS NULL
    AND payment_method IS NOT NULL
    AND payment_method NOT IN ('cod', 'cop'); -- CRITICAL: Exclude cash payments
  
  RETURN total_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_farmer_pending_earnings IS 
'Calculate pending earnings from orders in progress - ONLY from orders paid via platform (excludes COD/COP)';

-- Step 3: Add helper view for clarity
-- =============================================

CREATE OR REPLACE VIEW farmer_payout_eligible_orders AS
SELECT 
  o.id,
  o.farmer_id,
  o.buyer_id,
  o.total_amount,
  o.total_amount * 0.90 as farmer_earnings, -- After 10% commission
  o.payment_method,
  o.farmer_status,
  o.farmer_payout_status,
  o.paid_out_at,
  o.created_at,
  o.completed_at,
  CASE 
    WHEN o.payment_method IN ('cod', 'cop') THEN 'Cash - Not eligible for platform payout'
    WHEN o.farmer_payout_status = 'paid_out' THEN 'Already paid out'
    WHEN o.farmer_status = 'completed' THEN 'Eligible for payout'
    ELSE 'Pending completion'
  END as payout_eligibility_reason
FROM orders o
WHERE o.payment_method IS NOT NULL
  AND o.payment_method NOT IN ('cod', 'cop'); -- Only platform-paid orders

COMMENT ON VIEW farmer_payout_eligible_orders IS 
'Shows all orders eligible for farmer payouts (excludes COD/COP which are paid directly by buyer)';

-- Step 4: Create informational view for COD/COP orders
-- =============================================

CREATE OR REPLACE VIEW farmer_cash_orders AS
SELECT 
  o.id,
  o.farmer_id,
  o.buyer_id,
  o.total_amount,
  o.payment_method,
  o.farmer_status,
  o.created_at,
  o.completed_at,
  CASE 
    WHEN o.payment_method = 'cod' THEN 'Cash on Delivery - Buyer pays farmer directly'
    WHEN o.payment_method = 'cop' THEN 'Cash on Pickup - Buyer pays farmer directly'
    ELSE o.payment_method
  END as payment_note
FROM orders o
WHERE o.payment_method IN ('cod', 'cop');

COMMENT ON VIEW farmer_cash_orders IS 
'Shows orders where farmer receives cash directly from buyer (not through platform)';

-- Step 5: Add explanation to documentation
-- =============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '==============================================================';
  RAISE NOTICE 'PAYOUT CALCULATION UPDATE COMPLETE';
  RAISE NOTICE '==============================================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Payment Method Logic:';
  RAISE NOTICE '   - COD (Cash on Delivery): Buyer pays farmer directly → NOT in payout';
  RAISE NOTICE '   - COP (Cash on Pickup): Buyer pays farmer directly → NOT in payout';
  RAISE NOTICE '   - GCash/Bank/Card: Platform receives payment → INCLUDED in payout';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Updated Functions:';
  RAISE NOTICE '   - calculate_farmer_available_balance() - Now excludes COD/COP';
  RAISE NOTICE '   - calculate_farmer_pending_earnings() - Now excludes COD/COP';
  RAISE NOTICE '';
  RAISE NOTICE '✅ New Views:';
  RAISE NOTICE '   - farmer_payout_eligible_orders - Shows platform-paid orders';
  RAISE NOTICE '   - farmer_cash_orders - Shows cash orders (COD/COP)';
  RAISE NOTICE '';
  RAISE NOTICE '💡 Example:';
  RAISE NOTICE '   Order 1: ₱1000 via GCash → Farmer gets ₱900 via payout';
  RAISE NOTICE '   Order 2: ₱500 via COD → Farmer already got ₱500 cash from buyer';
  RAISE NOTICE '   Order 3: ₱300 via COP → Farmer already got ₱300 cash from buyer';
  RAISE NOTICE '   Total available for payout: ₱900 (only Order 1)';
  RAISE NOTICE '';
  RAISE NOTICE '==============================================================';
END $$;

-- Step 6: Verification queries (for testing)
-- =============================================

-- Uncomment to test:
/*
-- Check payout eligible orders for a farmer
SELECT * FROM farmer_payout_eligible_orders 
WHERE farmer_id = 'YOUR_FARMER_ID_HERE'
ORDER BY created_at DESC;

-- Check cash orders for a farmer
SELECT * FROM farmer_cash_orders 
WHERE farmer_id = 'YOUR_FARMER_ID_HERE'
ORDER BY created_at DESC;

-- Test balance calculation
SELECT calculate_farmer_available_balance('YOUR_FARMER_ID_HERE') as available_balance;
SELECT calculate_farmer_pending_earnings('YOUR_FARMER_ID_HERE') as pending_earnings;
*/

-- =============================================
-- Migration Complete!
-- =============================================

SELECT 
  'Payout calculation fixed!' as status,
  'COD and COP orders are now excluded from payout calculations' as change,
  'Farmers receive cash directly from buyers for those orders' as explanation;
