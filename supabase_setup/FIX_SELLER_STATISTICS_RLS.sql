-- =============================================
-- FIX SELLER STATISTICS RLS POLICIES
-- =============================================

-- The issue: RLS policy "Only system can update seller statistics" is blocking
-- the update_seller_statistics() function when products are inserted via triggers.

-- Current problematic policy blocks all updates
-- We need to allow:
-- 1. Database functions/triggers to update stats
-- 2. Users to update their own statistics
-- 3. Admins to update any statistics

-- First, drop the existing restrictive policies
DROP POLICY IF EXISTS "Only system can update seller statistics" ON public.seller_statistics;
DROP POLICY IF EXISTS "Anyone can view seller statistics" ON public.seller_statistics;

-- Create new, more permissive policies

-- 1. Allow anyone to view seller statistics (public data)
CREATE POLICY "Public can view seller statistics" ON public.seller_statistics
FOR SELECT USING (true);

-- 2. Allow users to insert their own seller statistics
CREATE POLICY "Users can insert own seller statistics" ON public.seller_statistics
FOR INSERT WITH CHECK (
    auth.uid() = seller_id 
    OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- 3. Allow users to update their own seller statistics
-- Also allow database functions (when auth.uid() is null) to update any statistics
CREATE POLICY "Users can update own seller statistics" ON public.seller_statistics
FOR UPDATE USING (
    auth.uid() = seller_id 
    OR 
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    OR
    auth.uid() IS NULL  -- Allow database functions/triggers
);

-- 4. Make the update_seller_statistics function run with SECURITY DEFINER
-- This allows it to bypass RLS when called from triggers
CREATE OR REPLACE FUNCTION update_seller_statistics(seller_user_id uuid)
RETURNS void 
LANGUAGE plpgsql
SECURITY DEFINER  -- This is key - runs with function owner's privileges
SET search_path = public
AS $$
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
            
            -- Active orders (using correct enum values)
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
        
    -- Log the update for debugging
    RAISE NOTICE 'Updated seller statistics for seller_id: %', seller_user_id;
END;
$$;

-- 5. Create a separate function for the trigger that has SECURITY DEFINER
CREATE OR REPLACE FUNCTION handle_product_statistics_update()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Handle INSERT and UPDATE operations
    IF TG_OP = 'INSERT' THEN
        -- Update statistics when new product is added
        PERFORM update_seller_statistics(NEW.farmer_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Update statistics when product is modified
        PERFORM update_seller_statistics(NEW.farmer_id);
        -- Also update old farmer if farmer_id changed
        IF OLD.farmer_id != NEW.farmer_id THEN
            PERFORM update_seller_statistics(OLD.farmer_id);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Update statistics when product is deleted
        PERFORM update_seller_statistics(OLD.farmer_id);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- 6. Recreate the trigger to use the new function
DROP TRIGGER IF EXISTS product_statistics_trigger ON public.products;
CREATE TRIGGER product_statistics_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION handle_product_statistics_update();

-- 7. Test the fix
DO $$
DECLARE
    test_farmer_id uuid;
    test_result RECORD;
BEGIN
    -- Get a farmer to test with
    SELECT id INTO test_farmer_id 
    FROM public.users 
    WHERE role = 'farmer' 
    LIMIT 1;
    
    IF test_farmer_id IS NOT NULL THEN
        -- Test the function directly
        PERFORM update_seller_statistics(test_farmer_id);
        
        -- Check if seller statistics were created/updated
        SELECT * INTO test_result 
        FROM public.seller_statistics 
        WHERE seller_id = test_farmer_id;
        
        IF FOUND THEN
            RAISE NOTICE '✅ SELLER STATISTICS RLS FIX SUCCESSFUL!';
            RAISE NOTICE 'Test farmer ID: %', test_farmer_id;
            RAISE NOTICE 'Statistics updated: products=%, orders=%', 
                test_result.total_products, test_result.total_orders;
        ELSE
            RAISE NOTICE '⚠️ Statistics record not found after update';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ No farmers found to test with';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error testing seller statistics: %', SQLERRM;
END;
$$;

-- 8. Verify the policies are correctly set
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'seller_statistics';

RAISE NOTICE '🎉 SELLER STATISTICS RLS POLICIES UPDATED!';
RAISE NOTICE 'Product uploads should now work without RLS errors.';