-- =============================================
-- TEST PRODUCT VISIBILITY AFTER ALL FIXES
-- =============================================
-- Run this to test all the fixes we've applied

-- 1. Test what buyers should see (simulates ProductService.getAvailableProducts())
SELECT 
    'BUYER VIEW TEST' as test_name,
    COUNT(*) as visible_products,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Buyers can see products'
        ELSE '❌ No products visible to buyers'
    END as result
FROM public.products 
WHERE is_hidden = false AND stock > 0;

-- 2. Test category distribution (simulates Categories screen)
SELECT 
    category,
    COUNT(*) as product_count
FROM public.products 
WHERE is_hidden = false AND stock > 0
GROUP BY category
ORDER BY product_count DESC;

-- 3. Test search functionality (simulates Search screen)
SELECT 
    'SEARCH TEST' as test_name,
    COUNT(*) as searchable_products,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Products are searchable'
        ELSE '❌ No searchable products'
    END as result
FROM public.products 
WHERE is_hidden = false 
AND stock > 0 
AND (
    name ILIKE '%tomato%' 
    OR description ILIKE '%tomato%' 
    OR category::text ILIKE '%tomato%'
);

-- 4. Show sample products that should be visible
SELECT 
    name,
    category,
    price,
    stock,
    farm_name,
    farm_location,
    is_hidden,
    created_at
FROM public.products 
WHERE is_hidden = false AND stock > 0
ORDER BY created_at DESC
LIMIT 5;

-- 5. Check if any products are being hidden unnecessarily
SELECT 
    'HIDDEN PRODUCTS CHECK' as test_name,
    COUNT(*) as hidden_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ No unnecessarily hidden products'
        ELSE '⚠️ Some products are hidden - check if intentional'
    END as result
FROM public.products 
WHERE is_hidden = true;

-- 6. Check if any products are out of stock
SELECT 
    'STOCK CHECK' as test_name,
    COUNT(*) as out_of_stock_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ All products have stock'
        ELSE '⚠️ Some products are out of stock'
    END as result
FROM public.products 
WHERE stock = 0;

-- 7. Final verification - what the app will actually query
SELECT 
    'FINAL APP SIMULATION' as test_name,
    products.name,
    products.price,
    products.stock,
    products.category,
    users.full_name as farmer_name,
    users.municipality as farmer_location
FROM public.products
LEFT JOIN public.users ON products.farmer_id = users.id
WHERE products.is_hidden = false 
AND products.stock > 0
ORDER BY products.created_at DESC
LIMIT 3;