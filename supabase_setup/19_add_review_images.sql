-- Add image support to product reviews
-- This migration adds the ability for users to upload images with their product reviews

-- Add image_urls column to product_reviews table
ALTER TABLE product_reviews 
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN product_reviews.image_urls IS 'Array of image URLs uploaded by the reviewer (max 5 images per review)';

-- Create index for better query performance when filtering by reviews with images
CREATE INDEX IF NOT EXISTS idx_product_reviews_with_images 
ON product_reviews(product_id) 
WHERE image_urls IS NOT NULL AND array_length(image_urls, 1) > 0;

-- Add index on product_id for faster review lookups
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id 
ON product_reviews(product_id);

-- Add index on user_id for faster user review lookups
CREATE INDEX IF NOT EXISTS idx_product_reviews_user_id 
ON product_reviews(user_id);

-- Add composite index for product review counts
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_rating 
ON product_reviews(product_id, rating);

-- Verify the column was added successfully
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'product_reviews' 
        AND column_name = 'image_urls'
    ) THEN
        RAISE NOTICE 'Successfully added image_urls column to product_reviews table';
    ELSE
        RAISE EXCEPTION 'Failed to add image_urls column to product_reviews table';
    END IF;
END $$;
