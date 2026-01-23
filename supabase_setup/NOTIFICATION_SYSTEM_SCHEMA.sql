-- =============================================
-- NOTIFICATION SYSTEM DATABASE SETUP
-- =============================================

-- =============================================
-- 1. CREATE NOTIFICATION FUNCTIONS
-- =============================================

-- Function to create a notification
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
    -- Insert notification
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

-- =============================================
-- 2. ORDER NOTIFICATION TRIGGERS
-- =============================================

-- Function to handle order notifications
CREATE OR REPLACE FUNCTION handle_order_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    buyer_name TEXT;
    farmer_name TEXT;
    order_total NUMERIC;
BEGIN
    -- Get user names
    SELECT full_name INTO buyer_name FROM users WHERE id = NEW.buyer_id;
    SELECT full_name INTO farmer_name FROM users WHERE id = NEW.farmer_id;
    SELECT total_amount INTO order_total FROM orders WHERE id = NEW.id;
    
    -- Handle INSERT (new order)
    IF TG_OP = 'INSERT' THEN
        -- Notify farmer about new order
        PERFORM create_notification(
            NEW.farmer_id,
            'New Order Received',
            'You have a new order from ' || buyer_name || ' worth ₱' || order_total::TEXT,
            'orderUpdate',
            NEW.id,
            jsonb_build_object(
                'order_id', NEW.id,
                'buyer_name', buyer_name,
                'amount', order_total,
                'action', 'new_order'
            )
        );
        
        -- Notify buyer about order placement
        PERFORM create_notification(
            NEW.buyer_id,
            'Order Placed Successfully',
            'Your order has been sent to ' || farmer_name || '. Waiting for confirmation.',
            'orderUpdate',
            NEW.id,
            jsonb_build_object(
                'order_id', NEW.id,
                'farmer_name', farmer_name,
                'amount', order_total,
                'action', 'order_placed'
            )
        );
        
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE (order status change)
    IF TG_OP = 'UPDATE' THEN
        -- Farmer status changes
        IF OLD.farmer_status != NEW.farmer_status THEN
            CASE NEW.farmer_status
                WHEN 'accepted' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Confirmed',
                        farmer_name || ' has accepted your order. It will be prepared soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'accepted', 'farmer_name', farmer_name)
                    );
                WHEN 'rejected' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Declined',
                        'Unfortunately, ' || farmer_name || ' cannot fulfill your order at this time.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'rejected', 'farmer_name', farmer_name)
                    );
                WHEN 'preparing' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Being Prepared',
                        farmer_name || ' is preparing your order. It will be ready soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'preparing', 'farmer_name', farmer_name)
                    );
                WHEN 'ready' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Ready',
                        'Your order from ' || farmer_name || ' is ready for pickup/delivery!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'ready', 'farmer_name', farmer_name)
                    );
                WHEN 'completed' THEN
                    -- Notify both buyer and farmer
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Delivered',
                        'Your order from ' || farmer_name || ' has been delivered. Thank you for your purchase!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'completed', 'farmer_name', farmer_name)
                    );
                    PERFORM create_notification(
                        NEW.farmer_id,
                        'Order Completed',
                        'Order for ' || buyer_name || ' has been successfully delivered.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'completed', 'buyer_name', buyer_name)
                    );
                ELSE
                    -- Handle other status changes
            END CASE;
        END IF;
        
        -- Buyer status changes
        IF OLD.buyer_status != NEW.buyer_status THEN
            CASE NEW.buyer_status
                WHEN 'cancelled' THEN
                    PERFORM create_notification(
                        NEW.farmer_id,
                        'Order Cancelled',
                        buyer_name || ' has cancelled their order.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'cancelled', 'buyer_name', buyer_name)
                    );
                ELSE
                    -- Handle other buyer status changes
            END CASE;
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create trigger for order notifications
DROP TRIGGER IF EXISTS order_notification_trigger ON orders;
CREATE TRIGGER order_notification_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_order_notifications();

-- =============================================
-- 3. FARMER VERIFICATION TRIGGERS
-- =============================================

-- Function to handle verification notifications
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
            NEW.id,
            jsonb_build_object(
                'verification_id', NEW.id,
                'status', 'pending',
                'farm_name', NEW.farm_name
            )
        );
        
        -- Notify all admins about new verification request
        INSERT INTO notifications (user_id, title, message, type, related_id, data, is_read, created_at)
        SELECT 
            u.id,
            'New Verification Request',
            farmer_name || ' has submitted farmer verification documents for review.',
            'verificationStatus',
            NEW.id,
            jsonb_build_object(
                'verification_id', NEW.id,
                'farmer_name', farmer_name,
                'farm_name', NEW.farm_name,
                'action', 'review_required'
            ),
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
                    NEW.id,
                    jsonb_build_object(
                        'verification_id', NEW.id,
                        'status', 'approved',
                        'farm_name', NEW.farm_name,
                        'reviewed_by', admin_name
                    )
                );
            WHEN 'rejected' THEN
                PERFORM create_notification(
                    NEW.farmer_id,
                    'Verification Requires Attention',
                    'Your verification needs additional information. Please check the details and resubmit.',
                    'verificationStatus',
                    NEW.id,
                    jsonb_build_object(
                        'verification_id', NEW.id,
                        'status', 'rejected',
                        'rejection_reason', NEW.rejection_reason,
                        'farm_name', NEW.farm_name,
                        'reviewed_by', admin_name
                    )
                );
            ELSE
                -- Handle other status changes
        END CASE;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create trigger for verification notifications
DROP TRIGGER IF EXISTS verification_notification_trigger ON farmer_verifications;
CREATE TRIGGER verification_notification_trigger
    AFTER INSERT OR UPDATE ON farmer_verifications
    FOR EACH ROW
    EXECUTE FUNCTION handle_verification_notifications();

-- =============================================
-- 4. MESSAGE NOTIFICATIONS
-- =============================================

-- Function to handle message notifications
CREATE OR REPLACE FUNCTION handle_message_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sender_name TEXT;
    receiver_id UUID;
    conversation_participants RECORD;
BEGIN
    -- Get sender name
    SELECT full_name INTO sender_name FROM users WHERE id = NEW.sender_id;
    
    -- Get conversation participants
    SELECT buyer_id, farmer_id INTO conversation_participants 
    FROM conversations WHERE id = NEW.conversation_id;
    
    -- Determine receiver (the one who didn't send the message)
    IF NEW.sender_id = conversation_participants.buyer_id THEN
        receiver_id := conversation_participants.farmer_id;
    ELSE
        receiver_id := conversation_participants.buyer_id;
    END IF;
    
    -- Create notification for receiver
    PERFORM create_notification(
        receiver_id,
        'New Message from ' || sender_name,
        LEFT(NEW.content, 50) || CASE WHEN LENGTH(NEW.content) > 50 THEN '...' ELSE '' END,
        'newMessage',
        NEW.conversation_id,
        jsonb_build_object(
            'message_id', NEW.id,
            'conversation_id', NEW.conversation_id,
            'sender_id', NEW.sender_id,
            'sender_name', sender_name
        )
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger for message notifications
DROP TRIGGER IF EXISTS message_notification_trigger ON messages;
CREATE TRIGGER message_notification_trigger
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION handle_message_notifications();

-- =============================================
-- 5. PRODUCT NOTIFICATIONS
-- =============================================

-- Function to handle product notifications
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
    SELECT u.full_name, NEW.farm_location 
    INTO farmer_name, farm_location
    FROM users u WHERE u.id = NEW.farmer_id;
    
    -- Handle INSERT (new product)
    IF TG_OP = 'INSERT' THEN
        -- Notify users in the same municipality about new product
        INSERT INTO notifications (user_id, title, message, type, related_id, data, is_read, created_at)
        SELECT 
            u.id,
            'New Product Available',
            farmer_name || ' has added fresh ' || NEW.name || ' in ' || farm_location,
            'productUpdate',
            NEW.id,
            jsonb_build_object(
                'product_id', NEW.id,
                'product_name', NEW.name,
                'farmer_name', farmer_name,
                'price', NEW.price,
                'location', farm_location,
                'action', 'new_product'
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
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Low stock alert for farmer
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
                    'action', 'low_stock'
                )
            );
        END IF;
        
        -- Out of stock alert
        IF OLD.stock > 0 AND NEW.stock = 0 THEN
            PERFORM create_notification(
                NEW.farmer_id,
                'Product Out of Stock',
                'Your ' || NEW.name || ' is now out of stock. Consider restocking soon.',
                'productUpdate',
                NEW.id,
                jsonb_build_object(
                    'product_id', NEW.id,
                    'product_name', NEW.name,
                    'action', 'out_of_stock'
                )
            );
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create trigger for product notifications
DROP TRIGGER IF EXISTS product_notification_trigger ON products;
CREATE TRIGGER product_notification_trigger
    AFTER INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_notifications();

-- =============================================
-- 6. CLEANUP FUNCTIONS
-- =============================================

-- Function to cleanup old notifications (run daily)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete notifications older than 30 days
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Log cleanup action
    RAISE NOTICE 'Cleaned up old notifications older than 30 days';
END;
$$;

-- =============================================
-- 7. UTILITY FUNCTIONS
-- =============================================

-- Function to get unread notification count for a user
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO unread_count
    FROM notifications
    WHERE user_id = p_user_id AND is_read = false;
    
    RETURN unread_count;
END;
$$;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_read = true
    WHERE user_id = p_user_id AND is_read = false;
END;
$$;

-- =============================================
-- 8. GRANT PERMISSIONS
-- =============================================

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read TO authenticated;

-- Grant permissions for cleanup function to service role
GRANT EXECUTE ON FUNCTION cleanup_old_notifications TO service_role;

-- =============================================
-- 9. SETUP COMPLETE CONFIRMATION
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'NOTIFICATION SYSTEM SETUP COMPLETE! ✅';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Features enabled:';
    RAISE NOTICE '- Order lifecycle notifications';
    RAISE NOTICE '- Farmer verification alerts';
    RAISE NOTICE '- Real-time message notifications';
    RAISE NOTICE '- Product availability alerts';
    RAISE NOTICE '- Automatic cleanup (30-day retention)';
    RAISE NOTICE '========================================';
END $$;