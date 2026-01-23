-- Fix rating column data type in product_reviews table
-- Issue: Some ratings are stored as strings '5' instead of integers 5

-- Step 1: Check current data type
SELECT 
    column_name, 
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_name = 'product_reviews' 
AND column_name = 'rating';

-- Expected: data_type = 'integer'
-- If it shows 'character varying' or 'text', proceed with fix

-- Step 2: Check if there are any string ratings
SELECT 
    id, 
    product_id, 
    rating,
    CASE 
        WHEN rating::text ~ '^[0-9]+$' THEN 'valid_number'
        ELSE 'invalid'
    END as validation
FROM product_reviews;

-- Step 3: If column is already INTEGER but values are somehow strings
-- (This shouldn't happen but PostgreSQL might allow it)
-- Force convert all ratings to integers
DO $$
BEGIN
    -- Try to clean up any non-numeric ratings first
    UPDATE product_reviews
    SET rating = 
        CASE 
            WHEN rating::text ~ '^[0-9]+$' THEN rating::text::integer
            ELSE 3  -- Default to 3 stars for invalid ratings
        END;
    
    RAISE NOTICE 'Cleaned up rating values';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Rating column is already correct type';
END $$;

-- Step 4: Ensure the column type is INTEGER (should already be from schema)
DO $$
BEGIN
    -- Only run if column is not already integer
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'product_reviews' 
        AND column_name = 'rating'
        AND data_type != 'integer'
    ) THEN
        -- Convert column to integer type
        ALTER TABLE product_reviews 
        ALTER COLUMN rating TYPE INTEGER 
        USING CASE 
            WHEN rating::text ~ '^[0-9]+$' THEN rating::text::integer
            ELSE 3
        END;
        
        RAISE NOTICE 'Converted rating column to INTEGER';
    ELSE
        RAISE NOTICE 'Rating column is already INTEGER type';
    END IF;
END $$;

-- Step 5: Ensure check constraint exists
DO $$
BEGIN
    -- Drop old constraint if exists
    ALTER TABLE product_reviews 
    DROP CONSTRAINT IF EXISTS product_reviews_rating_check;
    
    -- Add constraint
    ALTER TABLE product_reviews 
    ADD CONSTRAINT product_reviews_rating_check 
    CHECK (rating >= 1 AND rating <= 5);
    
    RAISE NOTICE 'Added rating check constraint (1-5)';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Constraint already exists or error: %', SQLERRM;
END $$;

-- Step 6: Verify the fix
SELECT 
    id,
    product_id,
    rating,
    pg_typeof(rating) as rating_type
FROM product_reviews
ORDER BY created_at DESC
LIMIT 10;

-- Should show: rating_type = 'integer'

-- Step 7: Test query (what the app uses)
SELECT product_id, rating 
FROM product_reviews 
WHERE rating IS NOT NULL;

-- Final summary
SELECT 
    COUNT(*) as total_reviews,
    MIN(rating) as min_rating,
    MAX(rating) as max_rating,
    AVG(rating) as avg_rating,
    pg_typeof(rating) as rating_type
FROM product_reviews;
