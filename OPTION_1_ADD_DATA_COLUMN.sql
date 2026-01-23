-- =============================================
-- OPTION 1: ADD DATA COLUMN FOR RICH NOTIFICATIONS
-- =============================================

-- Add the missing data column to notifications table
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS data JSONB DEFAULT NULL;

-- Add an index for better performance when querying notification data
CREATE INDEX IF NOT EXISTS idx_notifications_data 
ON public.notifications USING GIN (data);

-- Now enable the full notification system with rich data
-- (This restores the original NOTIFICATION_SYSTEM_SCHEMA.sql functionality)

-- Restored create_notification function with data support
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT,
    p_related_id UUID DEFAULT NULL,
    p_data JSONB DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification_id UUID;
BEGIN
    -- Insert notification with data support
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        related_id,
        data,
        is_read,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_type,
        p_related_id,
        p_data,
        false,
        now()
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;

-- Rich product notification function
CREATE OR REPLACE FUNCTION handle_product_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    farmer_name TEXT;
    farm_location TEXT;
BEGIN
    -- Get farmer details
    SELECT u.full_name, COALESCE(NEW.farm_location, u.municipality || ', ' || u.barangay)
    INTO farmer_name, farm_location
    FROM users u WHERE u.id = NEW.farmer_id;
    
    -- Handle INSERT (new product with rich data)
    IF TG_OP = 'INSERT' THEN
        -- Notify users with detailed product information
        INSERT INTO notifications (user_id, title, message, type, related_id, data, is_read, created_at)
        SELECT 
            u.id,
            'New Product Available',
            farmer_name || ' has added fresh ' || NEW.name || ' in ' || COALESCE(farm_location, 'your area'),
            'productUpdate',
            NEW.id,
            jsonb_build_object(
                'product_id', NEW.id,
                'product_name', NEW.name,
                'farmer_name', farmer_name,
                'price', NEW.price,
                'unit', NEW.unit,
                'stock', NEW.stock,
                'category', NEW.category,
                'location', farm_location,
                'image_url', NEW.cover_image_url,
                'action', 'view_product'  -- Enable tap-to-view
            ),
            false,
            now()
        FROM users u 
        WHERE u.role = 'buyer' 
        AND u.is_active = true
        AND u.municipality = (
            SELECT municipality FROM users WHERE id = NEW.farmer_id
        );
        
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE with rich data
    IF TG_OP = 'UPDATE' THEN
        -- Low stock alert with detailed info
        IF OLD.stock > 5 AND NEW.stock <= 5 AND NEW.stock > 0 THEN
            PERFORM create_notification(
                NEW.farmer_id,
                'Low Stock Alert',
                'Your ' || NEW.name || ' is running low (only ' || NEW.stock || ' ' || NEW.unit || ' left)',
                'productUpdate',
                NEW.id,
                jsonb_build_object(
                    'product_id', NEW.id,
                    'product_name', NEW.name,
                    'current_stock', NEW.stock,
                    'unit', NEW.unit,
                    'price', NEW.price,
                    'action', 'restock_product'
                )
            );
        END IF;
        
        -- Price change notification for followers
        IF OLD.price != NEW.price THEN
            INSERT INTO notifications (user_id, title, message, type, related_id, data, is_read, created_at)
            SELECT 
                uf.user_id,
                'Price Update',
                NEW.name || ' price changed from ₱' || OLD.price || ' to ₱' || NEW.price,
                'productUpdate',
                NEW.id,
                jsonb_build_object(
                    'product_id', NEW.id,
                    'product_name', NEW.name,
                    'old_price', OLD.price,
                    'new_price', NEW.price,
                    'farmer_name', farmer_name,
                    'action', 'view_product'
                ),
                false,
                now()
            FROM user_favorites uf
            WHERE uf.product_id = NEW.id;
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Test the rich notification system
DO $$
DECLARE
    test_notification_id UUID;
BEGIN
    -- Test creating a rich notification
    SELECT create_notification(
        (SELECT id FROM users WHERE role = 'buyer' LIMIT 1),
        'Rich Notification Test',
        'Testing the enhanced notification system with data payload',
        'general',
        NULL,
        jsonb_build_object(
            'test', true,
            'features', jsonb_build_array('rich_data', 'tap_actions', 'detailed_info'),
            'timestamp', extract(epoch from now())
        )
    ) INTO test_notification_id;
    
    RAISE NOTICE '🎉 RICH NOTIFICATIONS ENABLED!';
    RAISE NOTICE 'Test notification created with ID: %', test_notification_id;
    RAISE NOTICE 'Features now available:';
    RAISE NOTICE '  - Product details in notifications';
    RAISE NOTICE '  - Price change alerts';
    RAISE NOTICE '  - Tap-to-view actions';
    RAISE NOTICE '  - Rich metadata for UI';
END $$;