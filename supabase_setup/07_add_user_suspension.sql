-- Add is_active column to users table for user suspension feature
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- Create index on is_active for faster queries
CREATE INDEX idx_users_is_active ON users(is_active);

-- Add comment for clarity
COMMENT ON COLUMN users.is_active IS 'Whether the user account is active (true) or suspended (false)';
