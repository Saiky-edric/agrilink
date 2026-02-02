-- Add GPS coordinates to users table for farmer farm/profile location
-- This migration adds latitude, longitude, and accuracy columns to users table

-- Add columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS accuracy DOUBLE PRECISION;

-- Create index on coordinates for faster distance queries
CREATE INDEX IF NOT EXISTS idx_users_coordinates ON users(latitude, longitude);

-- Add comment to explain the columns
COMMENT ON COLUMN users.latitude IS 'GPS latitude coordinate of the user/farm location';
COMMENT ON COLUMN users.longitude IS 'GPS longitude coordinate of the user/farm location';
COMMENT ON COLUMN users.accuracy IS 'GPS accuracy in meters';

-- Note: The calculate_distance function already exists from migration 37
