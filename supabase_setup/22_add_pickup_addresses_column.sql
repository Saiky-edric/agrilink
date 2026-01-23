-- Add pickup_addresses column to users table
-- This allows farmers to have multiple pickup locations

-- Add the column (JSONB array to store multiple addresses)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS pickup_addresses JSONB DEFAULT '[]'::jsonb;

-- Create an index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_pickup_addresses ON public.users USING GIN (pickup_addresses);

-- Update existing data: migrate from single pickup_address to pickup_addresses array
-- Also use farm location (municipality, barangay, street) as default
UPDATE public.users
SET pickup_addresses = jsonb_build_array(
  jsonb_build_object(
    'label', 'Farm Location',
    'municipality', COALESCE(municipality, ''),
    'barangay', COALESCE(barangay, ''),
    'street_address', COALESCE(street, pickup_address, ''),
    'is_default', true
  )
)
WHERE role = 'farmer'
  AND (municipality IS NOT NULL OR pickup_address IS NOT NULL)
  AND (pickup_addresses IS NULL OR pickup_addresses = '[]'::jsonb);

-- Add comment
COMMENT ON COLUMN public.users.pickup_addresses IS 'Array of pickup address objects with municipality, barangay, street_address, label, and is_default fields';

-- Note: We keep the old pickup_address, pickup_instructions, pickup_hours columns for backward compatibility
-- The new pickup_addresses column will be the primary source of pickup location data
