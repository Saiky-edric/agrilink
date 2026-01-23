-- Fix: Review rating stored as string instead of integer

-- Check current data type
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product_reviews' 
AND column_name = 'rating';

-- This should show: integer
-- If it shows: text or varchar, that's the problem!

-- Check existing reviews with string ratings
SELECT id, product_id, rating, pg_typeof(rating) as rating_type
FROM product_reviews;

-- Fix: Convert existing string ratings to integers (if needed)
-- Only run if ratings are stored as strings
UPDATE product_reviews
SET rating = CAST(rating AS INTEGER)
WHERE pg_typeof(rating) = 'text'::regtype;

-- If the column type itself is wrong, fix it:
-- ALTER TABLE product_reviews 
-- ALTER COLUMN rating TYPE INTEGER USING rating::integer;

-- Verify the fix
SELECT id, product_id, rating, pg_typeof(rating) as rating_type
FROM product_reviews;
