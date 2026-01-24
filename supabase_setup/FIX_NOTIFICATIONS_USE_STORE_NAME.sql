-- =============================================
-- FIX NOTIFICATIONS TO USE STORE_NAME
-- =============================================
-- Purpose: 
--   1. Update product notifications to only notify followers
--   2. Use store_name instead of user full_name in all notifications
-- =============================================

BEGIN;

-- =============================================
-- 1. FIX PRODUCT NOTIFICATIONS (Only followers + use store_name)
-- =============================================

CREATE OR REPLACE FUNCTION handle_product_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    store_display_name TEXT;
    farm_location TEXT;
BEGIN
    -- Get store name (priority: store_name > farm_name > full_name's Farm)
    SELECT 
        COALESCE(
            NULLIF(u.store_name, ''),
            (SELECT fv.farm_name FROM farmer_verifications fv WHERE fv.farmer_id = u.id AND fv.status = 'approved' LIMIT 1),
            u.full_name || '''s Farm'
        ),
        NEW.farm_location
    INTO store_display_name, farm_location
    FROM users u 
    WHERE u.id = NEW.farmer_id;
    
    -- Handle INSERT (new product)
    IF TG_OP = 'INSERT' THEN
        -- ONLY notify users who are following this store
        INSERT INTO notifications (user_id, title, message, type, related_id, data, is_read, created_at)
        SELECT 
            uf.user_id,  -- Only followers
            'New Product Available',
            store_display_name || ' has added fresh ' || NEW.name || ' in ' || farm_location,
            'productUpdate',
            NEW.id,
            jsonb_build_object(
                'product_id', NEW.id,
                'product_name', NEW.name,
                'store_name', store_display_name,
                'farmer_id', NEW.farmer_id,
                'price', NEW.price,
                'location', farm_location,
                'action', 'new_product'
            ),
            false,
            now()
        FROM user_follows uf 
        WHERE uf.seller_id = NEW.farmer_id;  -- Only send to followers
        
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

-- Recreate trigger
DROP TRIGGER IF EXISTS product_notification_trigger ON products;
CREATE TRIGGER product_notification_trigger
    AFTER INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_notifications();

-- =============================================
-- 2. FIX ORDER NOTIFICATIONS (Use store_name)
-- =============================================

CREATE OR REPLACE FUNCTION handle_order_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    buyer_name TEXT;
    store_display_name TEXT;
    order_total NUMERIC;
BEGIN
    -- Get buyer name
    SELECT full_name INTO buyer_name FROM users WHERE id = NEW.buyer_id;
    
    -- Get store name (priority: store_name > farm_name > full_name's Farm)
    SELECT 
        COALESCE(
            NULLIF(u.store_name, ''),
            (SELECT fv.farm_name FROM farmer_verifications fv WHERE fv.farmer_id = u.id AND fv.status = 'approved' LIMIT 1),
            u.full_name || '''s Farm'
        )
    INTO store_display_name
    FROM users u 
    WHERE u.id = NEW.farmer_id;
    
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
        
        -- Notify buyer about order placement (use store_name)
        PERFORM create_notification(
            NEW.buyer_id,
            'Order Placed Successfully',
            'Your order has been sent to ' || store_display_name || '. Waiting for confirmation.',
            'orderUpdate',
            NEW.id,
            jsonb_build_object(
                'order_id', NEW.id,
                'store_name', store_display_name,
                'farmer_id', NEW.farmer_id,
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
                        store_display_name || ' has accepted your order. It will be prepared soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'accepted', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'rejected' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Declined',
                        'Unfortunately, ' || store_display_name || ' cannot fulfill your order at this time.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'rejected', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'preparing' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Being Prepared',
                        store_display_name || ' is preparing your order. It will be ready soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'preparing', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'ready' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Ready',
                        'Your order from ' || store_display_name || ' is ready for pickup/delivery!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'ready', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'completed' THEN
                    -- Notify both buyer and farmer
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Delivered',
                        'Your order from ' || store_display_name || ' has been delivered. Thank you for your purchase!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'completed', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                    PERFORM create_notification(
                        NEW.farmer_id,
                        'Order Completed',
                        'Order for ' || buyer_name || ' has been successfully delivered.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'completed', 
                            'buyer_name', buyer_name
                        )
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
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'cancelled', 
                            'buyer_name', buyer_name
                        )
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

-- Recreate trigger
DROP TRIGGER IF EXISTS order_notification_trigger ON orders;
CREATE TRIGGER order_notification_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_order_notifications();

-- =============================================
-- 3. FIX MESSAGE NOTIFICATIONS (Use store_name)
-- =============================================

CREATE OR REPLACE FUNCTION handle_message_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sender_display_name TEXT;
    receiver_id UUID;
    conversation_participants RECORD;
BEGIN
    -- Get conversation participants
    SELECT buyer_id, farmer_id INTO conversation_participants 
    FROM conversations WHERE id = NEW.conversation_id;
    
    -- Determine receiver (the one who didn't send the message)
    IF NEW.sender_id = conversation_participants.buyer_id THEN
        receiver_id := conversation_participants.farmer_id;
    ELSE
        receiver_id := conversation_participants.buyer_id;
    END IF;
    
    -- Get sender display name
    -- If sender is farmer, use store_name; if buyer, use full_name
    SELECT 
        CASE 
            WHEN u.role = 'farmer' THEN
                COALESCE(
                    NULLIF(u.store_name, ''),
                    (SELECT fv.farm_name FROM farmer_verifications fv WHERE fv.farmer_id = u.id AND fv.status = 'approved' LIMIT 1),
                    u.full_name || '''s Farm'
                )
            ELSE
                u.full_name
        END
    INTO sender_display_name
    FROM users u 
    WHERE u.id = NEW.sender_id;
    
    -- Create notification for receiver
    PERFORM create_notification(
        receiver_id,
        'New Message from ' || sender_display_name,
        LEFT(NEW.content, 50) || CASE WHEN LENGTH(NEW.content) > 50 THEN '...' ELSE '' END,
        'newMessage',
        NEW.conversation_id,
        jsonb_build_object(
            'message_id', NEW.id,
            'conversation_id', NEW.conversation_id,
            'sender_id', NEW.sender_id,
            'sender_name', sender_display_name
        )
    );
    
    RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS message_notification_trigger ON messages;
CREATE TRIGGER message_notification_trigger
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION handle_message_notifications();

COMMIT;

-- =============================================
-- VERIFICATION
-- =============================================

-- Test queries to verify changes:
-- 1. Check that product notifications only go to followers:
-- SELECT n.* FROM notifications n 
-- WHERE n.type = 'productUpdate' 
-- ORDER BY n.created_at DESC LIMIT 10;

-- 2. Check that store_name is used in notification data:
-- SELECT n.message, n.data FROM notifications n 
-- WHERE n.type IN ('orderUpdate', 'productUpdate') 
-- ORDER BY n.created_at DESC LIMIT 10;

RAISE NOTICE '✅ Notification triggers updated successfully!';
RAISE NOTICE '📢 Product notifications now only sent to followers';
RAISE NOTICE '🏪 All notifications now use store_name instead of user full_name';
