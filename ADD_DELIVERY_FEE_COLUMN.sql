-- Add missing fee columns to orders table
-- Run this in your Supabase SQL Editor

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS subtotal NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS service_fee NUMERIC DEFAULT 0;

-- Update existing orders to have proper fee structure
UPDATE orders 
SET 
  subtotal = total_amount,
  delivery_fee = 0,
  service_fee = 0
WHERE subtotal IS NULL;