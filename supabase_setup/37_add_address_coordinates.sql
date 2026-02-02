-- Add GPS coordinates to user_addresses table for location-based features
-- This migration adds latitude, longitude, and accuracy columns

-- Add columns to user_addresses table
ALTER TABLE user_addresses 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS accuracy DOUBLE PRECISION;

-- Create index on coordinates for faster distance queries
CREATE INDEX IF NOT EXISTS idx_user_addresses_coordinates ON user_addresses(latitude, longitude);

-- Add comment to explain the columns
COMMENT ON COLUMN user_addresses.latitude IS 'GPS latitude coordinate of the address';
COMMENT ON COLUMN user_addresses.longitude IS 'GPS longitude coordinate of the address';
COMMENT ON COLUMN user_addresses.accuracy IS 'GPS accuracy in meters';

-- Add helper function to calculate distance between two points (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
  earth_radius CONSTANT DOUBLE PRECISION := 6371; -- Earth radius in kilometers
  dlat DOUBLE PRECISION;
  dlon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  a := sin(dlat/2) * sin(dlat/2) + 
       cos(radians(lat1)) * cos(radians(lat2)) * 
       sin(dlon/2) * sin(dlon/2);
  
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  
  RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_distance IS 'Calculate distance in kilometers between two GPS coordinates using Haversine formula';
