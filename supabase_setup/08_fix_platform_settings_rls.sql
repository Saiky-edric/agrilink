-- Fix RLS Policies for Platform Settings Table
-- This allows admins to manage platform settings

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can view platform settings" ON platform_settings;
DROP POLICY IF EXISTS "Admins can update platform settings" ON platform_settings;

-- Create new policies that work with the updated schema
-- Allow admins to view platform settings
CREATE POLICY "Admins can view platform settings" ON platform_settings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Allow admins to update platform settings
CREATE POLICY "Admins can update platform settings" ON platform_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Allow admins to insert platform settings (upsert operations)
CREATE POLICY "Admins can insert platform settings" ON platform_settings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Allow admins to delete platform settings
CREATE POLICY "Admins can delete platform settings" ON platform_settings
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Also allow public read access for non-sensitive settings
-- This way the app can read settings without authentication
CREATE POLICY "Anyone can view platform settings" ON platform_settings
  FOR SELECT USING (true);
