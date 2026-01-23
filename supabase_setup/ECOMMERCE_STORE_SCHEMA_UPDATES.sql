-- E-commerce Store Schema Updates for Agrilink
-- This script adds new tables and columns to support the modern seller store features

-- =============================================
-- 1. SELLER STORE ENHANCEMENTS
-- =============================================

-- Add store-specific columns to users table for seller branding
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS store_name text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS store_description text DEFAULT 'Fresh agricultural products from our farm.';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS store_banner_url text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS store_logo_url text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS store_message text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS business_hours text DEFAULT 'Mon-Sun 6:00 AM - 6:00 PM';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_store_open boolean DEFAULT true;

-- =============================================
-- 2. SELLER FOLLOWERS SYSTEM
-- =============================================

-- Create seller followers table (reuse user_favorites with seller_id)
-- Update existing user_favorites to support seller following
ALTER TABLE public.user_favorites ADD COLUMN IF NOT EXISTS seller_id uuid REFERENCES public.users(id);
ALTER TABLE public.user_favorites ADD COLUMN IF NOT EXISTS followed_at timestamp with time zone DEFAULT now();

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_favorites_seller_id ON public.user_favorites(seller_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_seller ON public.user_favorites(user_id, seller_id);

-- =============================================
-- 3. SELLER RATINGS & REVIEWS SYSTEM
-- =============================================

-- Create seller reviews table (separate from product reviews)
CREATE TABLE IF NOT EXISTS public.seller_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    buyer_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text text,
    review_type text DEFAULT 'general' CHECK (review_type IN ('general', 'communication', 'shipping', 'quality')),
    is_verified_purchase boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(seller_id, buyer_id, order_id) -- One review per buyer per order
);

-- =============================================
-- 4. SELLER STATISTICS TABLE
-- =============================================

-- Create seller statistics table for performance metrics
CREATE TABLE IF NOT EXISTS public.seller_statistics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    total_products integer DEFAULT 0,
    total_sales integer DEFAULT 0,
    total_orders integer DEFAULT 0,
    active_orders integer DEFAULT 0,
    total_followers integer DEFAULT 0,
    total_reviews integer DEFAULT 0,
    average_rating numeric(3,2) DEFAULT 0.00,
    response_rate numeric(3,2) DEFAULT 0.95,
    average_response_hours integer DEFAULT 2,
    shipping_rating numeric(3,2) DEFAULT 4.8,
    last_active_at timestamp with time zone DEFAULT now(),
    stats_updated_at timestamp with time zone DEFAULT now(),
    
    CONSTRAINT valid_response_rate CHECK (response_rate >= 0 AND response_rate <= 1),
    CONSTRAINT valid_average_rating CHECK (average_rating >= 0 AND average_rating <= 5),
    CONSTRAINT valid_shipping_rating CHECK (shipping_rating >= 0 AND shipping_rating <= 5)
);


-- =============================================
-- 5. STORE SETTINGS TABLE
-- =============================================

-- Create store settings table for seller preferences
CREATE TABLE IF NOT EXISTS public.store_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    shipping_methods jsonb DEFAULT '["Standard Delivery", "Express Delivery", "Pickup Available"]',
    payment_methods jsonb DEFAULT '{"Cash on Delivery": true, "GCash": true, "Bank Transfer": false, "Credit Card": false}',
    auto_accept_orders boolean DEFAULT false,
    vacation_mode boolean DEFAULT false,
    vacation_message text,
    min_order_amount numeric DEFAULT 0.00,
    free_shipping_threshold numeric DEFAULT 500.00,
    processing_time_days integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create index for store settings
CREATE INDEX IF NOT EXISTS idx_store_settings_seller_id ON public.store_settings(seller_id);

-- =============================================
-- CREATE INDEXES FOR ALL NEW TABLES
-- =============================================

-- Indexes for seller reviews (now that table exists)
CREATE INDEX IF NOT EXISTS idx_seller_reviews_seller_id ON public.seller_reviews(seller_id);
CREATE INDEX IF NOT EXISTS idx_seller_reviews_rating ON public.seller_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_seller_reviews_created_at ON public.seller_reviews(created_at DESC);

-- Index for seller statistics
CREATE INDEX IF NOT EXISTS idx_seller_statistics_seller_id ON public.seller_statistics(seller_id);

-- =============================================
-- 6. PRODUCT CATEGORIES ENHANCEMENT
-- =============================================

-- Add more product category fields
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory text;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS featured_until timestamp with time zone;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS view_count integer DEFAULT 0;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS popularity_score numeric DEFAULT 0.00;

-- Create indexes for better product discovery
CREATE INDEX IF NOT EXISTS idx_products_category_featured ON public.products(category, is_featured);
CREATE INDEX IF NOT EXISTS idx_products_farmer_featured ON public.products(farmer_id, is_featured);
CREATE INDEX IF NOT EXISTS idx_products_popularity ON public.products(popularity_score DESC);

-- =============================================
-- 7. ORDER ENHANCEMENTS FOR REVIEWS
-- =============================================

-- Add columns to support seller review system
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS seller_reviewed boolean DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_reviewed boolean DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS review_reminder_sent boolean DEFAULT false;

-- =============================================
-- 8. FUNCTIONS FOR SELLER STATISTICS
-- =============================================

-- Function to update seller statistics
CREATE OR REPLACE FUNCTION update_seller_statistics(seller_user_id uuid)
RETURNS void AS $$
BEGIN
    INSERT INTO public.seller_statistics (
        seller_id,
        total_products,
        total_sales,
        total_orders,
        active_orders,
        total_followers,
        total_reviews,
        average_rating,
        stats_updated_at
    )
    SELECT 
        seller_user_id,
        COALESCE(products_count, 0),
        COALESCE(sales_count, 0),
        COALESCE(orders_count, 0),
        COALESCE(active_orders_count, 0),
        COALESCE(followers_count, 0),
        COALESCE(reviews_count, 0),
        COALESCE(avg_rating, 0.00),
        now()
    FROM (
        SELECT 
            -- Product count
            (SELECT COUNT(*) FROM public.products WHERE farmer_id = seller_user_id AND is_hidden = false) as products_count,
            
            -- Sales count (total quantity sold)
            (SELECT COALESCE(SUM(oi.quantity), 0) 
             FROM public.order_items oi 
             JOIN public.orders o ON oi.order_id = o.id 
             WHERE o.farmer_id = seller_user_id AND o.farmer_status = 'completed') as sales_count,
            
            -- Total orders
            (SELECT COUNT(*) FROM public.orders WHERE farmer_id = seller_user_id) as orders_count,
            
            -- Active orders
            (SELECT COUNT(*) FROM public.orders 
             WHERE farmer_id = seller_user_id 
             AND farmer_status IN ('newOrder', 'processing', 'ready')) as active_orders_count,
            
            -- Followers count
            (SELECT COUNT(*) FROM public.user_favorites WHERE seller_id = seller_user_id) as followers_count,
            
            -- Reviews count and average rating
            (SELECT COUNT(*) FROM public.seller_reviews WHERE seller_id = seller_user_id) as reviews_count,
            (SELECT COALESCE(AVG(rating), 0.00) FROM public.seller_reviews WHERE seller_id = seller_user_id) as avg_rating
    ) stats_data
    
    ON CONFLICT (seller_id) DO UPDATE SET
        total_products = EXCLUDED.total_products,
        total_sales = EXCLUDED.total_sales,
        total_orders = EXCLUDED.total_orders,
        active_orders = EXCLUDED.active_orders,
        total_followers = EXCLUDED.total_followers,
        total_reviews = EXCLUDED.total_reviews,
        average_rating = EXCLUDED.average_rating,
        stats_updated_at = now();
END;
$$ LANGUAGE plpgsql;

-- Function to get seller store data
CREATE OR REPLACE FUNCTION get_seller_store_data(seller_user_id uuid)
RETURNS json AS $$
DECLARE
    store_data json;
BEGIN
    SELECT json_build_object(
        'id', u.id,
        'full_name', u.full_name,
        'store_name', COALESCE(u.store_name, u.full_name || ' Farm'),
        'store_description', u.store_description,
        'store_banner_url', u.store_banner_url,
        'store_logo_url', COALESCE(u.store_logo_url, u.avatar_url),
        'avatar_url', u.avatar_url,
        'municipality', u.municipality,
        'barangay', u.barangay,
        'created_at', u.created_at,
        'is_store_open', u.is_store_open,
        'business_hours', u.business_hours,
        'store_message', u.store_message,
        'verification_status', COALESCE(fv.status, 'not_verified'),
        'statistics', (
            SELECT json_build_object(
                'total_products', ss.total_products,
                'total_sales', ss.total_sales,
                'total_orders', ss.total_orders,
                'active_orders', ss.active_orders,
                'total_followers', ss.total_followers,
                'total_reviews', ss.total_reviews,
                'average_rating', ss.average_rating,
                'response_rate', ss.response_rate,
                'average_response_hours', ss.average_response_hours,
                'shipping_rating', ss.shipping_rating
            )
            FROM public.seller_statistics ss 
            WHERE ss.seller_id = seller_user_id
        ),
        'store_settings', (
            SELECT json_build_object(
                'shipping_methods', st.shipping_methods,
                'payment_methods', st.payment_methods,
                'auto_accept_orders', st.auto_accept_orders,
                'vacation_mode', st.vacation_mode,
                'vacation_message', st.vacation_message,
                'min_order_amount', st.min_order_amount,
                'free_shipping_threshold', st.free_shipping_threshold,
                'processing_time_days', st.processing_time_days
            )
            FROM public.store_settings st 
            WHERE st.seller_id = seller_user_id
        )
    ) INTO store_data
    FROM public.users u
    LEFT JOIN public.farmer_verifications fv ON u.id = fv.farmer_id
    WHERE u.id = seller_user_id AND u.role = 'farmer' AND u.is_active = true;
    
    RETURN store_data;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 9. TRIGGERS FOR AUTOMATIC STATISTICS UPDATES
-- =============================================

-- Trigger to update seller statistics when products change
CREATE OR REPLACE FUNCTION trigger_update_seller_stats()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        PERFORM update_seller_statistics(NEW.farmer_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM update_seller_statistics(OLD.farmer_id);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_products_stats_update ON public.products;
CREATE TRIGGER trigger_products_stats_update
    AFTER INSERT OR UPDATE OR DELETE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_seller_stats();

-- Trigger for orders
DROP TRIGGER IF EXISTS trigger_orders_stats_update ON public.orders;
CREATE TRIGGER trigger_orders_stats_update
    AFTER INSERT OR UPDATE OR DELETE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_seller_stats();

-- Trigger for followers
CREATE OR REPLACE FUNCTION trigger_update_follower_stats()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        IF NEW.seller_id IS NOT NULL THEN
            PERFORM update_seller_statistics(NEW.seller_id);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.seller_id IS NOT NULL THEN
            PERFORM update_seller_statistics(OLD.seller_id);
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_followers_stats_update ON public.user_favorites;
CREATE TRIGGER trigger_followers_stats_update
    AFTER INSERT OR UPDATE OR DELETE ON public.user_favorites
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_follower_stats();

-- =============================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on new tables
ALTER TABLE public.seller_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- Seller reviews policies
CREATE POLICY "Users can view all seller reviews" ON public.seller_reviews
    FOR SELECT USING (true);

CREATE POLICY "Users can insert reviews for purchases" ON public.seller_reviews
    FOR INSERT WITH CHECK (
        auth.uid() = buyer_id AND
        EXISTS (
            SELECT 1 FROM public.orders o 
            WHERE o.buyer_id = auth.uid() 
            AND o.farmer_id = seller_id 
            AND o.buyer_status = 'completed'
        )
    );

CREATE POLICY "Users can update their own reviews" ON public.seller_reviews
    FOR UPDATE USING (auth.uid() = buyer_id);

-- Seller statistics policies
CREATE POLICY "Anyone can view seller statistics" ON public.seller_statistics
    FOR SELECT USING (true);

CREATE POLICY "Only system can update seller statistics" ON public.seller_statistics
    FOR ALL USING (false);

-- Store settings policies  
CREATE POLICY "Sellers can manage their store settings" ON public.store_settings
    FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Anyone can view store settings" ON public.store_settings
    FOR SELECT USING (true);

-- =============================================
-- 11. INITIAL DATA SETUP
-- =============================================

-- Initialize seller statistics for existing farmers
INSERT INTO public.seller_statistics (seller_id)
SELECT id FROM public.users 
WHERE role = 'farmer' AND is_active = true
ON CONFLICT (seller_id) DO NOTHING;

-- Initialize store settings for existing farmers  
INSERT INTO public.store_settings (seller_id)
SELECT id FROM public.users 
WHERE role = 'farmer' AND is_active = true
ON CONFLICT (seller_id) DO NOTHING;

-- Update all seller statistics
DO $$
DECLARE
    farmer_record RECORD;
BEGIN
    FOR farmer_record IN (SELECT id FROM public.users WHERE role = 'farmer' AND is_active = true)
    LOOP
        PERFORM update_seller_statistics(farmer_record.id);
    END LOOP;
END $$;

-- =============================================
-- 12. USEFUL VIEWS FOR STORE DATA
-- =============================================

-- Create view for popular sellers
CREATE OR REPLACE VIEW public.popular_sellers AS
SELECT 
    u.id,
    u.full_name,
    COALESCE(u.store_name, u.full_name || ' Farm') as store_name,
    u.avatar_url,
    u.municipality,
    u.barangay,
    ss.total_products,
    ss.total_followers,
    ss.average_rating,
    ss.total_reviews,
    COALESCE(fv.status, 'not_verified') as verification_status
FROM public.users u
LEFT JOIN public.seller_statistics ss ON u.id = ss.seller_id
LEFT JOIN public.farmer_verifications fv ON u.id = fv.farmer_id
WHERE u.role = 'farmer' 
AND u.is_active = true
AND ss.total_products > 0
ORDER BY ss.average_rating DESC, ss.total_followers DESC, ss.total_products DESC;

-- Create view for featured products across all stores
CREATE OR REPLACE VIEW public.featured_store_products AS
SELECT 
    p.*,
    u.full_name as farmer_name,
    COALESCE(u.store_name, u.full_name || ' Farm') as store_name,
    u.avatar_url as farmer_avatar,
    ss.average_rating as store_rating,
    ss.total_reviews as store_review_count
FROM public.products p
JOIN public.users u ON p.farmer_id = u.id
LEFT JOIN public.seller_statistics ss ON u.id = ss.seller_id
WHERE p.is_featured = true 
AND p.is_hidden = false
AND u.is_active = true
ORDER BY p.featured_until DESC NULLS LAST, p.created_at DESC;