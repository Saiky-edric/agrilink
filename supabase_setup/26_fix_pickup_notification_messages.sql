-- ============================================================================
-- Fix Pickup Order Notification Messages
-- Date: 2025-01-24
-- Description: Update notification messages to differentiate between delivery 
--              and pickup orders
-- ============================================================================

-- ============================================================================
-- Update handle_order_notifications function with pickup-specific messages
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_order_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    buyer_name TEXT;
    store_display_name TEXT;
    order_total NUMERIC;
    is_pickup BOOLEAN;
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
    
    -- Get order details
    SELECT total_amount INTO order_total FROM orders WHERE id = NEW.id;
    
    -- Check if this is a pickup order
    is_pickup := (NEW.delivery_method = 'pickup');
    
    -- Handle INSERT (new order)
    IF TG_OP = 'INSERT' THEN
        -- Notify farmer about new order
        IF is_pickup THEN
            PERFORM create_notification(
                NEW.farmer_id,
                'New Pick-up Order',
                'You have a new pick-up order from ' || buyer_name || ' worth ₱' || order_total::TEXT,
                'orderUpdate',
                NEW.id,
                jsonb_build_object(
                    'order_id', NEW.id,
                    'buyer_name', buyer_name,
                    'amount', order_total,
                    'delivery_method', 'pickup',
                    'action', 'new_order'
                )
            );
        ELSE
            PERFORM create_notification(
                NEW.farmer_id,
                'New Order Received',
                'You have a new delivery order from ' || buyer_name || ' worth ₱' || order_total::TEXT,
                'orderUpdate',
                NEW.id,
                jsonb_build_object(
                    'order_id', NEW.id,
                    'buyer_name', buyer_name,
                    'amount', order_total,
                    'delivery_method', 'delivery',
                    'action', 'new_order'
                )
            );
        END IF;
        
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
                'delivery_method', NEW.delivery_method,
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
                            'farmer_id', NEW.farmer_id,
                            'delivery_method', NEW.delivery_method
                        )
                    );
                    
                WHEN 'cancelled' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Declined',
                        'Unfortunately, ' || store_display_name || ' cannot fulfill your order at this time.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'cancelled', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                    
                WHEN 'toPack' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Being Prepared',
                        store_display_name || ' is preparing your order. It will be ready soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'toPack', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id,
                            'delivery_method', NEW.delivery_method
                        )
                    );
                    
                WHEN 'toDeliver' THEN
                    -- This is for delivery orders
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Out for Delivery',
                        'Your order from ' || store_display_name || ' is on its way!' || 
                        CASE WHEN NEW.tracking_number IS NOT NULL 
                            THEN ' Tracking: ' || NEW.tracking_number 
                            ELSE '' 
                        END,
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'toDeliver', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id,
                            'tracking_number', NEW.tracking_number,
                            'delivery_method', 'delivery'
                        )
                    );
                    
                WHEN 'readyForPickup' THEN
                    -- NEW: Specific notification for pickup orders
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Ready for Pick-up',
                        'Your order from ' || store_display_name || ' is ready! You can pick it up now at: ' || 
                        COALESCE(NEW.pickup_address, 'the farm location'),
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'readyForPickup', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id,
                            'pickup_address', NEW.pickup_address,
                            'pickup_instructions', NEW.pickup_instructions,
                            'delivery_method', 'pickup'
                        )
                    );
                    
                WHEN 'completed' THEN
                    -- Different messages for delivery vs pickup
                    IF is_pickup THEN
                        -- Pickup order completed
                        PERFORM create_notification(
                            NEW.buyer_id,
                            'Order Picked Up',
                            'Thank you for picking up your order from ' || store_display_name || '! Enjoy your fresh products!',
                            'orderUpdate',
                            NEW.id,
                            jsonb_build_object(
                                'order_id', NEW.id, 
                                'status', 'completed', 
                                'store_name', store_display_name,
                                'farmer_id', NEW.farmer_id,
                                'delivery_method', 'pickup'
                            )
                        );
                    ELSE
                        -- Delivery order completed
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
                                'farmer_id', NEW.farmer_id,
                                'delivery_method', 'delivery'
                            )
                        );
                    END IF;
                    
                    -- Notify farmer
                    IF is_pickup THEN
                        PERFORM create_notification(
                            NEW.farmer_id,
                            'Order Picked Up',
                            buyer_name || ' has picked up their order successfully.',
                            'orderUpdate',
                            NEW.id,
                            jsonb_build_object(
                                'order_id', NEW.id, 
                                'status', 'completed', 
                                'buyer_name', buyer_name,
                                'delivery_method', 'pickup'
                            )
                        );
                    ELSE
                        PERFORM create_notification(
                            NEW.farmer_id,
                            'Order Delivered',
                            'Order for ' || buyer_name || ' has been successfully delivered.',
                            'orderUpdate',
                            NEW.id,
                            jsonb_build_object(
                                'order_id', NEW.id, 
                                'status', 'completed', 
                                'buyer_name', buyer_name,
                                'delivery_method', 'delivery'
                            )
                        );
                    END IF;
                    
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
                            'buyer_name', buyer_name,
                            'delivery_method', NEW.delivery_method
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

-- ============================================================================
-- Recreate the trigger
-- ============================================================================

DROP TRIGGER IF EXISTS order_notification_trigger ON orders;
CREATE TRIGGER order_notification_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_order_notifications();

-- ============================================================================
-- Verification
-- ============================================================================

SELECT '✅ Notification function updated successfully!' as status;
SELECT '' as blank;
SELECT '📋 Notification Messages by Status:' as info;
SELECT '' as blank;
SELECT 'Delivery Orders:' as type, 'toDeliver → "Order Out for Delivery"' as message
UNION ALL SELECT 'Delivery Orders', 'completed → "Order Delivered"'
UNION ALL SELECT 'Pickup Orders', 'readyForPickup → "Order Ready for Pick-up" ⭐'
UNION ALL SELECT 'Pickup Orders', 'completed → "Order Picked Up" ⭐';

RAISE NOTICE '';
RAISE NOTICE '✅ Pickup notification messages fixed!';
RAISE NOTICE '';
RAISE NOTICE '📱 Updated Notification Messages:';
RAISE NOTICE '   Delivery Orders:';
RAISE NOTICE '     - toDeliver: "Order Out for Delivery"';
RAISE NOTICE '     - completed: "Order Delivered"';
RAISE NOTICE '';
RAISE NOTICE '   Pickup Orders:';
RAISE NOTICE '     - readyForPickup: "Order Ready for Pick-up" ⭐';
RAISE NOTICE '     - completed: "Order Picked Up" ⭐';
RAISE NOTICE '';
RAISE NOTICE '🎯 Notifications now show correct message based on delivery method!';
RAISE NOTICE '';
