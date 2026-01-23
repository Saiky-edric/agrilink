-- =============================================
-- FIX FARMER ORDER STATUS ENUM ISSUE
-- =============================================

-- The issue: Line 182 in ECOMMERCE_STORE_SCHEMA_UPDATES.sql references 'processing' 
-- but the farmer_order_status enum only has: 'newOrder', 'toPack', 'toDeliver', 'completed', 'cancelled'

-- Option 1: Add 'processing' to the enum (if you want this status)
-- ALTER TYPE farmer_order_status ADD VALUE 'processing' AFTER 'toPack';

-- Option 2: Fix the function to use existing enum values (RECOMMENDED)
-- Update the seller statistics function to use correct enum values

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
            
            -- Active orders (FIXED: using correct enum values)
            (SELECT COUNT(*) FROM public.orders 
             WHERE farmer_id = seller_user_id 
             AND farmer_status IN ('newOrder', 'toPack', 'toDeliver')) as active_orders_count,
            
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

-- Verify that we can call the function without errors
DO $$
DECLARE
    test_farmer_id uuid;
BEGIN
    -- Get a farmer ID to test with (if any exist)
    SELECT id INTO test_farmer_id 
    FROM public.users 
    WHERE role = 'farmer' 
    LIMIT 1;
    
    IF test_farmer_id IS NOT NULL THEN
        -- Test the function
        PERFORM update_seller_statistics(test_farmer_id);
        RAISE NOTICE '✅ Seller statistics function fixed successfully!';
        RAISE NOTICE 'Test farmer ID: %', test_farmer_id;
    ELSE
        RAISE NOTICE '⚠️ No farmers found to test with, but function is fixed.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error: %', SQLERRM;
        RAISE NOTICE 'Check enum values: %', (SELECT enumtypid::regtype || ': ' || string_agg(enumlabel, ', ') FROM pg_enum WHERE enumtypid = 'farmer_order_status'::regtype);
END;
$$;

-- Also verify the farmer_order_status enum values
SELECT 'farmer_order_status enum values:' as info, string_agg(enumlabel, ', ' ORDER BY enumsortorder) as values
FROM pg_enum 
WHERE enumtypid = 'farmer_order_status'::regtype;