-- =============================================
-- ADD PAYMENT_METHOD COLUMN TO ORDERS TABLE
-- =============================================
-- Problem: Code expects 'payment_method' column but table only has 'payment_method_id'
-- Solution: Add payment_method as text column to store method type
-- Context: This column was needed when pickup delivery + COP were added
-- =============================================

BEGIN;

-- Add payment_method column to store the payment method type as text
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT 
CHECK (payment_method IN ('cod', 'cop', 'gcash', 'bank_transfer', 'credit_card'));

-- Set default value for existing rows
UPDATE orders 
SET payment_method = 'cod' 
WHERE payment_method IS NULL;

-- Add comment explaining the difference
COMMENT ON COLUMN orders.payment_method IS 'Payment method type: cod, cop, gcash, etc. (simple string)';
COMMENT ON COLUMN orders.payment_method_id IS 'Foreign key to payment_methods table for saved payment methods (future use)';

COMMIT;

-- =============================================
-- VERIFICATION
-- =============================================

-- Check the column exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('payment_method', 'payment_method_id', 'payment_status');

RAISE NOTICE '✅ payment_method column added to orders table!';
RAISE NOTICE '📝 Can now store: cod, cop, gcash, bank_transfer, credit_card';
