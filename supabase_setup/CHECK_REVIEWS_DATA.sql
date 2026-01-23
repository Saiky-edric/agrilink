-- Script to check if reviews exist in the database

-- Check if product_reviews table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'product_reviews'
) AS table_exists;

-- Check if image_urls column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product_reviews' 
AND column_name = 'image_urls';

-- Count total reviews
SELECT COUNT(*) as total_reviews FROM product_reviews;

-- Show sample reviews
SELECT 
    pr.id,
    pr.product_id,
    pr.user_id,
    pr.rating,
    pr.review_text,
    pr.created_at,
    u.full_name as reviewer_name,
    p.name as product_name
FROM product_reviews pr
LEFT JOIN users u ON u.id = pr.user_id
LEFT JOIN products p ON p.id = pr.product_id
ORDER BY pr.created_at DESC
LIMIT 10;

-- Count reviews per product
SELECT 
    p.id,
    p.name as product_name,
    COUNT(pr.id) as review_count,
    AVG(pr.rating) as avg_rating
FROM products p
LEFT JOIN product_reviews pr ON pr.product_id = p.id
WHERE p.is_hidden = false AND p.status = 'active'
GROUP BY p.id, p.name
ORDER BY review_count DESC
LIMIT 20;

-- Check if any orders are completed (for sold count)
SELECT 
    p.id,
    p.name as product_name,
    SUM(oi.quantity) as total_sold
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id
WHERE o.farmer_status = 'completed'
GROUP BY p.id, p.name
ORDER BY total_sold DESC
LIMIT 20;
