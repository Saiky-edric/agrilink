-- =============================================
-- PRODUCT VISIBILITY DIAGNOSTIC
-- =============================================
-- Run this quick diagnostic to see what's in your database

-- 1. Check if any products exist at all
SELECT 
    'TOTAL PRODUCTS' as metric,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ No products found - farmers need to add products first'
        ELSE '✅ Products exist in database'
    END as status
FROM public.products;

-- 2. Check available products (what buyers should see)
SELECT 
    'AVAILABLE PRODUCTS' as metric,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ No available products - check stock and visibility'
        ELSE '✅ Products available for buyers'
    END as status
FROM public.products 
WHERE is_hidden = false AND stock > 0;

-- 3. Check product visibility issues
SELECT 
    'HIDDEN PRODUCTS' as metric,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️ Some products are hidden from buyers'
        ELSE '✅ No hidden products'
    END as status
FROM public.products 
WHERE is_hidden = true;

-- 4. Check stock issues
SELECT 
    'OUT OF STOCK' as metric,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️ Some products are out of stock'
        ELSE '✅ All products have stock'
    END as status
FROM public.products 
WHERE stock = 0;

-- 5. Check user roles
SELECT 
    role as user_role,
    COUNT(*) as count
FROM public.users 
GROUP BY role
ORDER BY role;

-- 6. Show sample products if any exist
SELECT 
    name,
    farmer_id,
    price,
    stock,
    category,
    is_hidden,
    created_at
FROM public.products 
ORDER BY created_at DESC 
LIMIT 5;