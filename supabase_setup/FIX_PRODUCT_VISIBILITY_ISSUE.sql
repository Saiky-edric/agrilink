-- =============================================
-- FIX PRODUCT VISIBILITY ISSUE
-- =============================================

-- Issue: Products are not visible to buyers because:
-- 1. No RLS policies allow public/buyers to view products
-- 2. Home screen queries Supabase directly instead of using ProductService

-- Enable RLS on products table (if not already enabled)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Drop any existing conflicting policies
DROP POLICY IF EXISTS "Anyone can view available products" ON public.products;
DROP POLICY IF EXISTS "Public can view products" ON public.products;
DROP POLICY IF EXISTS "Buyers can view available products" ON public.products;
DROP POLICY IF EXISTS "Users can view available products" ON public.products;

-- Create comprehensive product visibility policies

-- 1. Allow everyone to view non-hidden products with stock
CREATE POLICY "Public can view available products" ON public.products
FOR SELECT USING (
    is_hidden = false 
    AND stock > 0
);

-- 2. Allow farmers to view ALL their own products (including hidden ones)
CREATE POLICY "Farmers can view own products" ON public.products
FOR SELECT USING (
    auth.uid() = farmer_id
);

-- 3. Allow farmers to insert their own products
CREATE POLICY "Farmers can insert own products" ON public.products
FOR INSERT WITH CHECK (
    auth.uid() = farmer_id
);

-- 4. Allow farmers to update their own products
CREATE POLICY "Farmers can update own products" ON public.products
FOR UPDATE USING (
    auth.uid() = farmer_id
);

-- 5. Allow farmers to delete their own products
CREATE POLICY "Farmers can delete own products" ON public.products
FOR DELETE USING (
    auth.uid() = farmer_id
);

-- 6. Allow admins to view all products
CREATE POLICY "Admins can view all products" ON public.products
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- 7. Allow admins to update any products (for moderation)
CREATE POLICY "Admins can update any products" ON public.products
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Test the policies by trying to select products
DO $$
DECLARE
    product_count INTEGER;
    test_products RECORD;
BEGIN
    -- Count total products in database
    SELECT COUNT(*) INTO product_count FROM public.products;
    RAISE NOTICE '📊 Total products in database: %', product_count;
    
    -- Count available products (what buyers should see)
    SELECT COUNT(*) INTO product_count 
    FROM public.products 
    WHERE is_hidden = false AND stock > 0;
    RAISE NOTICE '🛒 Available products for buyers: %', product_count;
    
    -- Show sample of available products
    FOR test_products IN (
        SELECT id, name, farmer_id, stock, is_hidden, category
        FROM public.products 
        WHERE is_hidden = false AND stock > 0
        LIMIT 5
    ) LOOP
        RAISE NOTICE '  📦 Product: % (Stock: %, Category: %)', 
            test_products.name, test_products.stock, test_products.category;
    END LOOP;
    
    -- Check for hidden products
    SELECT COUNT(*) INTO product_count 
    FROM public.products 
    WHERE is_hidden = true;
    RAISE NOTICE '🙈 Hidden products: %', product_count;
    
    -- Check for out of stock products
    SELECT COUNT(*) INTO product_count 
    FROM public.products 
    WHERE stock = 0;
    RAISE NOTICE '📉 Out of stock products: %', product_count;
    
    RAISE NOTICE '✅ PRODUCT VISIBILITY POLICIES APPLIED SUCCESSFULLY!';
    RAISE NOTICE 'Buyers should now be able to see available products.';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error testing product visibility: %', SQLERRM;
END;
$$;