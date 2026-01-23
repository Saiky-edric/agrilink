-- Create stock_deducted flag and RPC to atomically complete orders and deduct stock
BEGIN;

-- Add guard flag to avoid double deduction
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS stock_deducted boolean NOT NULL DEFAULT false;

-- Create function
CREATE OR REPLACE FUNCTION public.complete_order_and_deduct(
  p_order_id uuid,
  p_buyer_status buyer_order_status DEFAULT NULL,
  p_farmer_status farmer_order_status DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cur_buyer buyer_order_status;
  v_cur_farmer farmer_order_status;
  v_will_complete boolean;
  v_already_completed boolean;
  rec RECORD;
BEGIN
  -- Lock order row
  SELECT buyer_status, farmer_status
  INTO v_cur_buyer, v_cur_farmer
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  v_already_completed := (v_cur_buyer = 'completed'::buyer_order_status)
                         OR (v_cur_farmer = 'completed'::farmer_order_status);

  -- Determine new statuses
  IF p_buyer_status IS NOT NULL THEN
    v_cur_buyer := p_buyer_status;
  END IF;
  IF p_farmer_status IS NOT NULL THEN
    v_cur_farmer := p_farmer_status;
  END IF;

  v_will_complete := (v_cur_buyer = 'completed'::buyer_order_status)
                     OR (v_cur_farmer = 'completed'::farmer_order_status);

  -- Update order statuses
  UPDATE public.orders
  SET buyer_status = v_cur_buyer,
      farmer_status = v_cur_farmer,
      updated_at = now()
  WHERE id = p_order_id;

  -- Deduct stock only on first completion
  IF v_will_complete AND NOT v_already_completed THEN
    PERFORM 1 FROM public.orders WHERE id = p_order_id AND stock_deducted = true;
    IF NOT FOUND THEN
      FOR rec IN
        SELECT product_id, quantity::int
        FROM public.order_items
        WHERE order_id = p_order_id
      LOOP
        UPDATE public.products
        SET stock = GREATEST(stock - rec.quantity, 0)
        WHERE id = rec.product_id;
      END LOOP;

      UPDATE public.orders
      SET stock_deducted = true
      WHERE id = p_order_id;
    END IF;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_order_and_deduct(uuid, buyer_order_status, farmer_order_status) TO anon, authenticated;

COMMIT;