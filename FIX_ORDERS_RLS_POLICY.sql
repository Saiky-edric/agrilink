-- Fix RLS Policies for Orders Table
-- This fixes the PostgrestException: new row violates row-level security policy for table "orders"

-- Add INSERT policy for orders table so buyers can create orders
CREATE POLICY "Buyers can create orders" ON orders 
FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Add INSERT policy for order_items table so order items can be created
CREATE POLICY "System can create order items" ON order_items 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM orders 
        WHERE id = order_id AND buyer_id = auth.uid()
    )
);

-- Optional: If you need to allow updates to order_items (for order modifications)
CREATE POLICY "Users can update own order items" ON order_items 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM orders 
        WHERE id = order_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid())
    )
);

-- Refresh the policies
NOTIFY pgrst, 'reload schema';