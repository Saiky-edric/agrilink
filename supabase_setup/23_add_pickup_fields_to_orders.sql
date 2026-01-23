-- Add pickup-related columns to orders table
-- These columns support the pickup delivery method

-- Add pickup_address column for storing the pickup location
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS pickup_address TEXT;

-- Add pickup_instructions column for special pickup instructions
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS pickup_instructions TEXT;

-- Add comments
COMMENT ON COLUMN public.orders.pickup_address IS 'Full pickup address when delivery_method is pickup';
COMMENT ON COLUMN public.orders.pickup_instructions IS 'Special instructions for pickup orders';

-- Note: delivery_method and pickup_location_id columns should already exist from previous migrations
-- If not, uncomment these lines:
-- ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_method VARCHAR DEFAULT 'delivery' CHECK (delivery_method IN ('delivery', 'pickup'));
-- ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS pickup_location_id UUID;
