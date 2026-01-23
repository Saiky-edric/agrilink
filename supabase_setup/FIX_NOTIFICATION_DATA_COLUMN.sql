-- =============================================
-- FIX NOTIFICATION DATA COLUMN ISSUE
-- =============================================

-- The notifications table is missing the 'data' column that the triggers expect
-- Option 1: Add the missing data column
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS data JSONB DEFAULT NULL;

-- Option 2: Alternative - Remove data column references from triggers
-- (Use this if you don't want the data column)

-- Update the create_notification function to handle missing data column
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
    -- Insert notification (without data column if it doesn't exist)
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        related_id,
        is_read,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_type,
        p_related_id,
        false,
        now()
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;

-- Fix the product notification trigger to not use data column
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
    
    -- Handle INSERT (new product)
    IF TG_OP = 'INSERT' THEN
        -- Notify users in the same municipality about new product
        INSERT INTO notifications (user_id, title, message, type, related_id, is_read, created_at)
        SELECT 
            u.id,
            'New Product Available',
            farmer_name || ' has added fresh ' || NEW.name || ' in ' || COALESCE(farm_location, 'your area'),
            'productUpdate',
            NEW.id,
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
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Low stock alert for farmer
        IF OLD.stock > 5 AND NEW.stock <= 5 AND NEW.stock > 0 THEN
            PERFORM create_notification(
                NEW.farmer_id,
                'Low Stock Alert',
                'Your ' || NEW.name || ' is running low (only ' || NEW.stock || ' ' || NEW.unit || ' left)',
                'productUpdate',
                NEW.id
            );
        END IF;
        
        -- Out of stock alert
        IF OLD.stock > 0 AND NEW.stock = 0 THEN
            PERFORM create_notification(
                NEW.farmer_id,
                'Product Out of Stock',
                'Your ' || NEW.name || ' is now out of stock. Consider restocking soon.',
                'productUpdate',
                NEW.id
            );
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Fix verification notifications trigger
CREATE OR REPLACE FUNCTION handle_verification_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    farmer_name TEXT;
    admin_name TEXT;
BEGIN
    -- Get farmer name
    SELECT full_name INTO farmer_name FROM users WHERE id = NEW.farmer_id;
    
    -- Handle INSERT (new verification submission)
    IF TG_OP = 'INSERT' THEN
        -- Notify farmer about submission
        PERFORM create_notification(
            NEW.farmer_id,
            'Verification Submitted',
            'Your farmer verification has been submitted. We will review it within 2-3 business days.',
            'verificationStatus',
            NEW.id
        );
        
        -- Notify all admins about new verification request
        INSERT INTO notifications (user_id, title, message, type, related_id, is_read, created_at)
        SELECT 
            u.id,
            'New Verification Request',
            farmer_name || ' has submitted farmer verification documents for review.',
            'verificationStatus',
            NEW.id,
            false,
            now()
        FROM users u 
        WHERE u.role = 'admin' AND u.is_active = true;
        
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE (status change)
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        -- Get admin name if reviewed
        IF NEW.reviewed_by IS NOT NULL THEN
            SELECT full_name INTO admin_name FROM users WHERE id = NEW.reviewed_by;
        END IF;
        
        CASE NEW.status
            WHEN 'approved' THEN
                PERFORM create_notification(
                    NEW.farmer_id,
                    'Verification Approved! 🎉',
                    'Congratulations! Your farmer verification has been approved. You can now start selling your products.',
                    'verificationStatus',
                    NEW.id
                );
            WHEN 'rejected' THEN
                PERFORM create_notification(
                    NEW.farmer_id,
                    'Verification Requires Attention',
                    'Your verification needs additional information. Please check the details and resubmit.',
                    'verificationStatus',
                    NEW.id
                );
            ELSE
                -- Handle other status changes
        END CASE;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Recreate the triggers to ensure they use the updated functions
DROP TRIGGER IF EXISTS product_notification_trigger ON products;
CREATE TRIGGER product_notification_trigger
    AFTER INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_notifications();

DROP TRIGGER IF EXISTS verification_notification_trigger ON farmer_verifications;
CREATE TRIGGER verification_notification_trigger
    AFTER INSERT OR UPDATE ON farmer_verifications
    FOR EACH ROW
    EXECUTE FUNCTION handle_verification_notifications();

-- Test the fix by trying to create a sample notification
DO $$
BEGIN
    -- Test if the function works without data column
    PERFORM create_notification(
        (SELECT id FROM users LIMIT 1),
        'Test Notification',
        'Testing notification system after fix',
        'general',
        NULL
    );
    RAISE NOTICE 'Notification system fix applied successfully!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error testing notification: %', SQLERRM;
END $$;