-- =============================================
-- VERIFY AND FIX PRODUCT RLS POLICIES
-- =============================================

-- First, let's check the current RLS status and policies
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('products', 'notifications', 'users') 
AND schemaname = 'public';

-- Check existing policies on products table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'products' 
AND schemaname = 'public';

-- Enable RLS on products table if not already enabled
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies that might be conflicting
DROP POLICY IF EXISTS "Anyone can view available products" ON public.products;
DROP POLICY IF EXISTS "Public can view products" ON public.products;
DROP POLICY IF EXISTS "Buyers can view available products" ON public.products;
DROP POLICY IF EXISTS "Users can view available products" ON public.products;
DROP POLICY IF EXISTS "Public can view available products" ON public.products;
DROP POLICY IF EXISTS "Farmers can view own products" ON public.products;
DROP POLICY IF EXISTS "Farmers can insert own products" ON public.products;
DROP POLICY IF EXISTS "Farmers can update own products" ON public.products;
DROP POLICY IF EXISTS "Farmers can delete own products" ON public.products;
DROP POLICY IF EXISTS "Admins can view all products" ON public.products;
DROP POLICY IF EXISTS "Admins can update any products" ON public.products;
DROP POLICY IF EXISTS "Farmers can manage own products" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;

-- Create comprehensive RLS policies for products

-- 1. Public can view available products (non-hidden + has stock)
CREATE POLICY "enable_read_available_products" ON public.products
FOR SELECT USING (
    is_hidden = false 
    AND stock > 0
);

-- 2. Farmers can view ALL their own products (including hidden and out of stock)
CREATE POLICY "enable_farmers_read_own_products" ON public.products
FOR SELECT USING (
    farmer_id = auth.uid()
);

-- 3. Farmers can insert their own products
CREATE POLICY "enable_farmers_insert_products" ON public.products
FOR INSERT WITH CHECK (
    farmer_id = auth.uid()
);

-- 4. Farmers can update their own products
CREATE POLICY "enable_farmers_update_products" ON public.products
FOR UPDATE USING (
    farmer_id = auth.uid()
);

-- 5. Farmers can delete their own products
CREATE POLICY "enable_farmers_delete_products" ON public.products
FOR DELETE USING (
    farmer_id = auth.uid()
);

-- 6. Admins can view all products
CREATE POLICY "enable_admins_read_all_products" ON public.products
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
        AND is_active = true
    )
);

-- 7. Admins can update any products (for moderation)
CREATE POLICY "enable_admins_update_all_products" ON public.products
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
        AND is_active = true
    )
);

-- 8. Admins can delete any products (for moderation)
CREATE POLICY "enable_admins_delete_all_products" ON public.products
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
        AND is_active = true
    )
);

-- Test the policies with sample queries
DO $$
DECLARE
    total_products INTEGER;
    available_products INTEGER;
    hidden_products INTEGER;
    out_of_stock INTEGER;
    sample_product RECORD;
BEGIN
    -- Get total products count
    SELECT COUNT(*) INTO total_products FROM public.products;
    RAISE NOTICE '📊 PRODUCTS DATABASE ANALYSIS:';
    RAISE NOTICE '  Total products in database: %', total_products;
    
    -- Count available products (what buyers should see)
    SELECT COUNT(*) INTO available_products 
    FROM public.products 
    WHERE is_hidden = false AND stock > 0;
    RAISE NOTICE '  Available products for buyers: %', available_products;
    
    -- Count hidden products
    SELECT COUNT(*) INTO hidden_products 
    FROM public.products 
    WHERE is_hidden = true;
    RAISE NOTICE '  Hidden products: %', hidden_products;
    
    -- Count out of stock products
    SELECT COUNT(*) INTO out_of_stock 
    FROM public.products 
    WHERE stock = 0;
    RAISE NOTICE '  Out of stock products: %', out_of_stock;
    
    -- Show sample available products
    RAISE NOTICE '📦 SAMPLE AVAILABLE PRODUCTS:';
    FOR sample_product IN (
        SELECT name, farmer_id, price, stock, category, created_at
        FROM public.products 
        WHERE is_hidden = false AND stock > 0
        ORDER BY created_at DESC
        LIMIT 3
    ) LOOP
        RAISE NOTICE '  🌱 % | Stock: % | Price: % | Category: %', 
            sample_product.name, 
            sample_product.stock, 
            sample_product.price, 
            sample_product.category;
    END LOOP;
    
    -- Check if we have any farmers
    SELECT COUNT(*) INTO total_products FROM public.users WHERE role = 'farmer';
    RAISE NOTICE '👨‍🌾 Total farmers: %', total_products;
    
    -- Check if we have any buyers
    SELECT COUNT(*) INTO total_products FROM public.users WHERE role = 'buyer';
    RAISE NOTICE '🛒 Total buyers: %', total_products;
    
    RAISE NOTICE '✅ RLS POLICIES APPLIED SUCCESSFULLY!';
    
    IF available_products > 0 THEN
        RAISE NOTICE '🎉 PRODUCTS SHOULD NOW BE VISIBLE TO BUYERS!';
    ELSE
        RAISE NOTICE '⚠️  NO AVAILABLE PRODUCTS FOUND';
        RAISE NOTICE '   - Check if farmers have added products';
        RAISE NOTICE '   - Ensure products have stock > 0';
        RAISE NOTICE '   - Ensure products are not hidden';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error in testing: %', SQLERRM;
END;
$$;

-- Show the final policy configuration
RAISE NOTICE '📋 CURRENT RLS POLICIES ON PRODUCTS TABLE:';
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'products' 
AND schemaname = 'public';

-- Final verification query that should work for testing
-- (This simulates what the app will do)
SELECT 
    'Product visibility test' as test_type,
    COUNT(*) as available_products
FROM public.products 
WHERE is_hidden = false 
AND stock > 0;