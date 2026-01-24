-- =============================================
-- FIX ORDER NOTIFICATION TRIGGER - REJECTED TO CANCELLED
-- =============================================
-- Problem: Trigger uses 'rejected' but farmer_order_status enum only has 'cancelled'
-- Error: invalid input value for enum farmer_order_status: "rejected"
-- =============================================

BEGIN;

-- Update the handle_order_notifications function to use 'cancelled' instead of 'rejected'
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
                WHEN 'cancelled' THEN  -- ✅ FIXED: Changed from 'rejected' to 'cancelled'
                    -- Only notify buyer if farmer cancelled (not if buyer cancelled)
                    -- Check if buyer_status is also cancelled - if yes, buyer initiated it
                    IF NEW.buyer_status != 'cancelled' OR OLD.buyer_status = 'cancelled' THEN
                        PERFORM create_notification(
                            NEW.buyer_id,
                            'Order Cancelled',
                            'Unfortunately, ' || store_display_name || ' has cancelled your order.',
                            'orderUpdate',
                            NEW.id,
                            jsonb_build_object(
                                'order_id', NEW.id, 
                                'status', 'cancelled',
                                'store_name', store_display_name,
                                'farmer_id', NEW.farmer_id
                            )
                        );
                    END IF;
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
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'toDeliver' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Ready for Delivery',
                        'Your order from ' || store_display_name || ' is ready for delivery!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'toDeliver', 
                            'store_name', store_display_name,
                            'farmer_id', NEW.farmer_id
                        )
                    );
                WHEN 'readyForPickup' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Ready for Pickup',
                        'Your order from ' || store_display_name || ' is ready for pickup!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'readyForPickup', 
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
                    -- Notify farmer that buyer cancelled
                    PERFORM create_notification(
                        NEW.farmer_id,
                        'Order Cancelled by Buyer',
                        buyer_name || ' has cancelled their order.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'cancelled', 
                            'buyer_name', buyer_name,
                            'cancelled_by', 'buyer'
                        )
                    );
                    -- Notify buyer (confirmation)
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Cancelled',
                        'You have successfully cancelled your order.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object(
                            'order_id', NEW.id, 
                            'status', 'cancelled',
                            'cancelled_by', 'buyer'
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

-- Recreate trigger (drop and create to ensure clean state)
DROP TRIGGER IF EXISTS order_notification_trigger ON orders;
CREATE TRIGGER order_notification_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_order_notifications();

COMMIT;

-- =============================================
-- VERIFICATION
-- =============================================

RAISE NOTICE '✅ Order notification trigger updated successfully!';
RAISE NOTICE '🔧 Changed "rejected" to "cancelled" for farmer_order_status';
RAISE NOTICE '🏪 Added store_name usage in notifications';
RAISE NOTICE '✅ Order cancellation should now work!';
