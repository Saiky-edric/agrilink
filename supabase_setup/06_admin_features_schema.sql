-- Agrilink Admin Features - Schema Updates
-- This file adds the missing tables and columns needed for the admin dashboard features

-- =============================================
-- ADMIN ACTIVITIES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS admin_activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'general',
  timestamp TIMESTAMPTZ DEFAULT now(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_name TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Admin activities indexes
CREATE INDEX idx_admin_activities_timestamp ON admin_activities(timestamp DESC);
CREATE INDEX idx_admin_activities_type ON admin_activities(type);
CREATE INDEX idx_admin_activities_user ON admin_activities(user_id);

-- =============================================
-- REPORTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  is_resolved BOOLEAN DEFAULT FALSE,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
  target_type TEXT DEFAULT 'user',
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Reports indexes
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target_id ON reports(target_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(type);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_is_resolved ON reports(is_resolved);
CREATE INDEX IF NOT EXISTS idx_reports_resolved_by ON reports(resolved_by);

-- =============================================
-- PLATFORM SETTINGS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS platform_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  app_name TEXT DEFAULT 'AgriLink',
  maintenance_mode BOOLEAN DEFAULT false,
  new_user_registration BOOLEAN DEFAULT true,
  max_product_images INTEGER DEFAULT 5,
  commission_rate DECIMAL(3,2) DEFAULT 0.05,
  min_order_amount DECIMAL(10,2) DEFAULT 0.00,
  max_order_amount DECIMAL(10,2) DEFAULT 10000.00,
  featured_categories TEXT[] DEFAULT '{}',
  notification_settings JSONB DEFAULT '{}',
  payment_methods JSONB DEFAULT '{}',
  shipping_zones JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Insert default platform settings
INSERT INTO platform_settings (app_name, maintenance_mode, new_user_registration, max_product_images, commission_rate)
VALUES ('AgriLink', false, true, 5, 0.05)
ON CONFLICT DO NOTHING;

-- =============================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- =============================================

-- Add is_active column to profiles if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add status tracking to farmer_verifications if missing
ALTER TABLE farmer_verifications
ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS review_notes TEXT;

-- Ensure farmer_verifications has all required columns
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='user_name') THEN
        ALTER TABLE farmer_verifications ADD COLUMN user_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='user_email') THEN
        ALTER TABLE farmer_verifications ADD COLUMN user_email TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='verification_type') THEN
        ALTER TABLE farmer_verifications ADD COLUMN verification_type TEXT DEFAULT 'farmer';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='submitted_at') THEN
        ALTER TABLE farmer_verifications ADD COLUMN submitted_at TIMESTAMPTZ DEFAULT now();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='reviewed_at') THEN
        ALTER TABLE farmer_verifications ADD COLUMN reviewed_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='farmer_verifications' AND column_name='farm_details') THEN
        ALTER TABLE farmer_verifications ADD COLUMN farm_details JSONB;
    END IF;
END $$;

-- =============================================
-- ANALYTICS VIEWS
-- =============================================

-- User statistics view
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE is_active = true) as active_users,
    COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE) as new_users_today,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as new_users_this_week,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as new_users_this_month,
    COUNT(*) FILTER (WHERE role = 'buyer') as buyer_count,
    COUNT(*) FILTER (WHERE role = 'farmer') as farmer_count,
    COUNT(*) FILTER (WHERE role = 'admin') as admin_count,
    COALESCE((
        SELECT COUNT(*) 
        FROM farmer_verifications 
        WHERE "status" = 'approved'
    ), 0) as verified_users,
    COALESCE((
        SELECT COUNT(*) 
        FROM farmer_verifications 
        WHERE "status" = 'pending'
    ), 0) as pending_verifications
FROM profiles;

-- Order analytics view (using buyer_status as primary order status)
CREATE OR REPLACE VIEW order_analytics AS
SELECT 
    COUNT(*) as total_orders,
    COUNT(*) FILTER (WHERE buyer_status = 'pending') as pending_orders,
    COUNT(*) FILTER (WHERE buyer_status = 'toShip') as processing_orders,
    COUNT(*) FILTER (WHERE buyer_status = 'toReceive') as shipped_orders,
    COUNT(*) FILTER (WHERE buyer_status = 'completed') as delivered_orders,
    COUNT(*) FILTER (WHERE buyer_status = 'cancelled') as cancelled_orders,
    COALESCE(AVG(total_amount), 0) as average_order_value
FROM orders;

-- Product analytics view (using is_hidden and stock columns from actual schema)
CREATE OR REPLACE VIEW product_analytics AS
SELECT 
    COUNT(*) as total_products,
    COUNT(*) FILTER (WHERE is_hidden = false) as active_products,
    COUNT(*) FILTER (WHERE stock <= 10 AND stock > 0) as low_stock_products,
    COUNT(*) FILTER (WHERE stock = 0) as out_of_stock_products
FROM products;

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Enable RLS on new tables
ALTER TABLE admin_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Admin activities policies
CREATE POLICY "Admins can view all admin activities" ON admin_activities
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert admin activities" ON admin_activities
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Reports policies
CREATE POLICY "Users can view their own reports" ON reports
  FOR SELECT USING (
    auth.uid() = reporter_id
    OR EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can create reports" ON reports
  FOR INSERT WITH CHECK (
    auth.uid() = reporter_id
  );

CREATE POLICY "Admins can update reports" ON reports
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Platform settings policies
CREATE POLICY "Admins can view platform settings" ON platform_settings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update platform settings" ON platform_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- =============================================
-- FUNCTIONS FOR ADMIN DASHBOARD
-- =============================================

-- Function to get comprehensive analytics
CREATE OR REPLACE FUNCTION get_platform_analytics()
RETURNS JSONB AS $$
DECLARE
    analytics JSONB;
BEGIN
    SELECT jsonb_build_object(
        'user_stats', (SELECT row_to_json(user_statistics.*) FROM user_statistics LIMIT 1),
        'order_stats', (SELECT row_to_json(order_analytics.*) FROM order_analytics LIMIT 1),
        'product_stats', (SELECT row_to_json(product_analytics.*) FROM product_analytics LIMIT 1),
        'revenue_stats', jsonb_build_object(
            'total_revenue', COALESCE((SELECT SUM(total_amount) FROM orders WHERE buyer_status = 'completed'), 0),
            'monthly_revenue', COALESCE((
                SELECT SUM(total_amount) 
                FROM orders 
                WHERE buyer_status = 'completed'
                AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
            ), 0),
            'daily_revenue', COALESCE((
                SELECT SUM(total_amount) 
                FROM orders 
                WHERE buyer_status = 'completed'
                AND DATE(created_at) = CURRENT_DATE
            ), 0)
        )
    ) INTO analytics;
    
    RETURN analytics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to toggle user active status
CREATE OR REPLACE FUNCTION toggle_user_status(target_user_id UUID, suspend BOOLEAN)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if caller is admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    -- Update user status
    UPDATE profiles 
    SET is_active = NOT suspend,
        updated_at = now()
    WHERE user_id = target_user_id;
    
    -- Log the activity
    INSERT INTO admin_activities (title, description, type, user_id, metadata)
    VALUES (
        CASE WHEN suspend THEN 'User Suspended' ELSE 'User Activated' END,
        'User status changed by admin',
        'user_management',
        target_user_id,
        jsonb_build_object('suspended', suspend, 'admin_id', auth.uid())
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- REALTIME SUBSCRIPTIONS
-- =============================================

-- Enable realtime for admin features
ALTER PUBLICATION supabase_realtime ADD TABLE admin_activities;
ALTER PUBLICATION supabase_realtime ADD TABLE reports;
ALTER PUBLICATION supabase_realtime ADD TABLE platform_settings;

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert sample admin activity
INSERT INTO admin_activities (title, description, type, metadata)
VALUES 
('System Initialization', 'Admin dashboard features initialized', 'system', '{"version": "1.0"}'),
('Schema Update', 'Admin features schema applied', 'system', '{"tables_created": ["admin_activities", "reports", "platform_settings"]}}')
ON CONFLICT DO NOTHING;

COMMIT;