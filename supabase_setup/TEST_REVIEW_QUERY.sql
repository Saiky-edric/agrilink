-- Test the exact query used by the app
SELECT product_id, rating 
FROM product_reviews 
WHERE product_id = 'fd7de843-52ba-417a-bf5c-4ccd636fcb23';

-- Also check the full review data
SELECT * FROM product_reviews WHERE product_id = 'fd7de843-52ba-417a-bf5c-4ccd636fcb23';
