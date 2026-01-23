-- Revert handle_order_notifications to use farmer_name instead of store_name
-- This restores the original behavior

CREATE OR REPLACE FUNCTION handle_order_notifications()
RETURNS TRIGGER AS $$
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
        
        -- Notify buyer about order placement (using farmer_name)
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
                        'Order Accepted',
                        farmer_name || ' has accepted your order. It will be prepared soon!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'accepted', 'farmer_name', farmer_name)
                    );
                WHEN 'toPack' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Being Packed',
                        farmer_name || ' is preparing your order for delivery!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'toPack', 'farmer_name', farmer_name)
                    );
                WHEN 'toDeliver' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Out for Delivery',
                        'Your order from ' || farmer_name || ' is on its way to you!',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'toDeliver', 'farmer_name', farmer_name)
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
                WHEN 'cancelled' THEN
                    PERFORM create_notification(
                        NEW.buyer_id,
                        'Order Cancelled',
                        'Unfortunately, ' || farmer_name || ' cannot fulfill your order at this time.',
                        'orderUpdate',
                        NEW.id,
                        jsonb_build_object('order_id', NEW.id, 'status', 'cancelled', 'farmer_name', farmer_name)
                    );
                ELSE
                    -- Handle other status changes or do nothing
            END CASE;
        END IF;
        
        -- Buyer status changes
        IF OLD.buyer_status != NEW.buyer_status THEN
            CASE NEW.buyer_status
                WHEN 'cancelled' THEN
                    PERFORM create_notification(
                        NEW.farmer_id,
                        'Order Cancelled by Buyer',
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
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS order_notification_trigger ON orders;
CREATE TRIGGER order_notification_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION handle_order_notifications();
