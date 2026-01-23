-- Agrilink App Modernization - Schema Improvements
-- Execute these SQL commands to support new app features

-- =============================================
-- USER ADDRESSES TABLE
-- =============================================
-- Support for multiple delivery addresses per user
CREATE TABLE user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- 'Home', 'Work', etc.
    street_address TEXT NOT NULL,
    municipality VARCHAR(100) NOT NULL,
    barangay VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for user addresses
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own addresses" ON user_addresses
FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- USER PAYMENT METHODS TABLE
-- =============================================
-- Support for multiple payment methods per user
CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_type VARCHAR(50) NOT NULL, -- 'Visa', 'MasterCard', etc.
    last_four_digits VARCHAR(4) NOT NULL,
    expiry_month INTEGER NOT NULL CHECK (expiry_month >= 1 AND expiry_month <= 12),
    expiry_year INTEGER NOT NULL,
    cardholder_name VARCHAR(255) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for payment methods
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own payment methods" ON payment_methods
FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- USER FAVORITES TABLE
-- =============================================
-- Support for favorite products
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate favorites
    UNIQUE(user_id, product_id)
);

-- RLS for favorites
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own favorites" ON user_favorites
FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- PRODUCT REVIEWS TABLE
-- =============================================
-- Support for product ratings and reviews
CREATE TABLE product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- One review per user per product
    UNIQUE(product_id, user_id)
);

-- RLS for reviews
ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read reviews" ON product_reviews
FOR SELECT USING (true);

CREATE POLICY "Users can manage their own reviews" ON product_reviews
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON product_reviews
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON product_reviews
FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- NOTIFICATIONS TABLE
-- =============================================
-- Support for in-app notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'order', 'message', 'product', 'system'
    related_id UUID, -- ID of related order, product, etc.
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own notifications" ON notifications
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- USER SETTINGS TABLE
-- =============================================
-- Support for user preferences and settings
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    push_notifications BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    dark_mode BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- One settings record per user
    UNIQUE(user_id)
);

-- RLS for user settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own settings" ON user_settings
FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- IMPROVEMENTS TO EXISTING TABLES
-- =============================================

-- Add missing fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(10);

-- Add missing fields to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_percentage DECIMAL(5,2) DEFAULT 0.00;
ALTER TABLE products ADD COLUMN IF NOT EXISTS tags TEXT[]; -- Array of tags like 'organic', 'fresh', etc.
ALTER TABLE products ADD COLUMN IF NOT EXISTS harvest_date DATE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_urls TEXT[]; -- Array of additional image URLs

-- Add order tracking fields
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(100);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_date DATE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_notes TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES payment_methods(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_id UUID REFERENCES user_addresses(id);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- User addresses indexes
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = true;

-- Payment methods indexes
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_default ON payment_methods(user_id, is_default) WHERE is_default = true;

-- Favorites indexes
CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_product_id ON user_favorites(product_id);

-- Reviews indexes
CREATE INDEX idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX idx_product_reviews_rating ON product_reviews(rating);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Enhanced product indexes
CREATE INDEX idx_products_featured ON products(is_featured) WHERE is_featured = true;
CREATE INDEX idx_products_discount ON products(discount_percentage) WHERE discount_percentage > 0;
CREATE INDEX idx_products_category_featured ON products(category, is_featured);

-- =============================================
-- TRIGGERS FOR NEW TABLES
-- =============================================

-- Update triggers for updated_at columns
CREATE TRIGGER update_user_addresses_updated_at 
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at 
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_reviews_updated_at 
    BEFORE UPDATE ON product_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at 
    BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- FUNCTIONS FOR APP FEATURES
-- =============================================

-- Function to get user's default address
CREATE OR REPLACE FUNCTION get_user_default_address(user_uuid UUID)
RETURNS user_addresses AS $$
DECLARE
    result user_addresses;
BEGIN
    SELECT * INTO result
    FROM user_addresses
    WHERE user_id = user_uuid AND is_default = true
    LIMIT 1;
    
    -- If no default address, get the first one
    IF result IS NULL THEN
        SELECT * INTO result
        FROM user_addresses
        WHERE user_id = user_uuid
        ORDER BY created_at
        LIMIT 1;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to set default address (ensures only one default per user)
CREATE OR REPLACE FUNCTION set_default_address(user_uuid UUID, address_uuid UUID)
RETURNS VOID AS $$
BEGIN
    -- Remove default from all user addresses
    UPDATE user_addresses 
    SET is_default = false 
    WHERE user_id = user_uuid;
    
    -- Set the specified address as default
    UPDATE user_addresses 
    SET is_default = true 
    WHERE id = address_uuid AND user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to set default payment method
CREATE OR REPLACE FUNCTION set_default_payment_method(user_uuid UUID, payment_method_uuid UUID)
RETURNS VOID AS $$
BEGIN
    -- Remove default from all user payment methods
    UPDATE payment_methods 
    SET is_default = false 
    WHERE user_id = user_uuid;
    
    -- Set the specified payment method as default
    UPDATE payment_methods 
    SET is_default = true 
    WHERE id = payment_method_uuid AND user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate product average rating
CREATE OR REPLACE FUNCTION get_product_rating(product_uuid UUID)
RETURNS DECIMAL(3,2) AS $$
DECLARE
    avg_rating DECIMAL(3,2);
BEGIN
    SELECT ROUND(AVG(rating), 2) INTO avg_rating
    FROM product_reviews
    WHERE product_id = product_uuid;
    
    RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ENABLE REALTIME FOR NEW TABLES
-- =============================================

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Enable realtime for favorites (for real-time favorite updates)
ALTER PUBLICATION supabase_realtime ADD TABLE user_favorites;

-- Enable realtime for reviews
ALTER PUBLICATION supabase_realtime ADD TABLE product_reviews;

-- =============================================
-- DATA MIGRATION FROM EXISTING USER PROFILES
-- =============================================

-- Migrate existing user profile addresses to new user_addresses table
INSERT INTO user_addresses (user_id, name, street_address, barangay, municipality, province, postal_code, is_default, created_at)
SELECT 
    id as user_id,
    'Home' as name,
    COALESCE(street, 'Address not specified') as street_address,
    barangay,
    municipality,
    'Philippines' as province,
    '' as postal_code,
    true as is_default,
    created_at
FROM users 
WHERE municipality IS NOT NULL 
  AND barangay IS NOT NULL
  AND municipality != ''
  AND barangay != '';

-- Create default user settings for existing users
INSERT INTO user_settings (user_id, created_at)
SELECT id, created_at
FROM users
WHERE id NOT IN (SELECT user_id FROM user_settings);

-- =============================================
-- POST-MIGRATION CLEANUP (OPTIONAL)
-- =============================================

-- You can optionally remove address fields from users table after confirming migration worked:
-- ALTER TABLE users DROP COLUMN IF EXISTS street;
-- ALTER TABLE users DROP COLUMN IF EXISTS barangay;
-- ALTER TABLE users DROP COLUMN IF EXISTS municipality;

-- Note: Keep these fields for now to maintain backward compatibility