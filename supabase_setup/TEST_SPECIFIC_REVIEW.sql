-- Quick test query to verify the review data
SELECT 
    pr.id,
    pr.product_id,
    pr.rating,
    pr.rating::text as rating_as_text,
    pg_typeof(pr.rating) as rating_type,
    pr.review_text,
    p.name as product_name
FROM product_reviews pr
JOIN products p ON p.id = pr.product_id
WHERE pr.product_id = 'fd7de843-52ba-417a-bf5c-4ccd636fcb23';
