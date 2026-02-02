-- =====================================================
-- ADD PRODUCT HAS ORDERS CHECK FUNCTION
-- =====================================================
-- This function checks if a product has any orders (active or completed)
-- Used to warn farmers before deleting products with existing orders

-- Function to check if product has orders
CREATE OR REPLACE FUNCTION public.check_product_has_orders(product_id_param UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
  active_order_count INT;
  completed_order_count INT;
  total_order_count INT;
BEGIN
  -- Count active orders (not cancelled or completed)
  -- Based on farmer_status enum: 'newOrder', 'accepted', 'toPack', 'toDeliver', 'readyForPickup', 'completed', 'cancelled'
  SELECT COUNT(DISTINCT o.id) INTO active_order_count
  FROM public.orders o
  INNER JOIN public.order_items oi ON o.id = oi.order_id
  WHERE oi.product_id = product_id_param
    AND o.farmer_status NOT IN ('cancelled', 'completed');

  -- Count completed orders
  SELECT COUNT(DISTINCT o.id) INTO completed_order_count
  FROM public.orders o
  INNER JOIN public.order_items oi ON o.id = oi.order_id
  WHERE oi.product_id = product_id_param
    AND o.farmer_status = 'completed';

  -- Total order count
  total_order_count := active_order_count + completed_order_count;

  -- Return JSON result
  result := json_build_object(
    'has_orders', total_order_count > 0,
    'total_orders', total_order_count,
    'active_orders', active_order_count,
    'completed_orders', completed_order_count
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.check_product_has_orders(UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION public.check_product_has_orders IS 'Check if a product has any orders (active or completed) to warn farmer before deletion. Returns JSON with order counts.';

-- Test the function (uncomment to test with an actual product_id)
-- SELECT public.check_product_has_orders('replace-with-actual-product-uuid');
