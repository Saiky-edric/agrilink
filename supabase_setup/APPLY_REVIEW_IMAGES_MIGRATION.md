# Apply Review Images Migration

This migration adds image upload capability to product reviews.

## What This Migration Does

1. Adds `image_urls` column to `product_reviews` table (TEXT[] array)
2. Creates performance indexes for:
   - Reviews with images
   - Product review lookups
   - User review lookups
   - Product rating aggregation

## How to Apply

### Option 1: Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `19_add_review_images.sql`
5. Click **Run** or press `Ctrl/Cmd + Enter`
6. You should see: "Successfully added image_urls column to product_reviews table"

### Option 2: Supabase CLI

```bash
supabase db push --file supabase_setup/19_add_review_images.sql
```

### Option 3: Direct PostgreSQL Connection

```bash
psql -h your-db-host -U postgres -d postgres -f supabase_setup/19_add_review_images.sql
```

## Verification

After running the migration, verify it worked:

```sql
-- Check if column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'product_reviews' 
AND column_name = 'image_urls';

-- Expected result:
-- column_name | data_type | column_default
-- image_urls  | ARRAY     | '{}'::text[]
```

## Rollback (if needed)

If you need to remove the image_urls column:

```sql
-- Drop indexes first
DROP INDEX IF EXISTS idx_product_reviews_with_images;
DROP INDEX IF EXISTS idx_product_reviews_product_id;
DROP INDEX IF EXISTS idx_product_reviews_user_id;
DROP INDEX IF EXISTS idx_product_reviews_product_rating;

-- Remove column
ALTER TABLE product_reviews DROP COLUMN IF EXISTS image_urls;
```

## Schema After Migration

```sql
CREATE TABLE product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    image_urls TEXT[] DEFAULT '{}',  -- NEW COLUMN
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(product_id, user_id)
);
```

## Impact

- **Existing reviews**: Will have `image_urls = '{}'` (empty array)
- **New reviews**: Can include up to 5 image URLs
- **Performance**: Indexes ensure fast queries for reviews with images
- **Storage**: Images stored in Supabase Storage under `product-images` bucket

## Next Steps

After applying this migration:

1. ✅ Column is ready to store image URLs
2. ✅ App can now upload images with reviews
3. ✅ Users can view review images in product details
4. ✅ Full-screen image viewer available

## Troubleshooting

**Error: "relation product_reviews does not exist"**
- Run `05_schema_improvements.sql` first to create the product_reviews table

**Error: "column image_urls already exists"**
- Migration was already applied, safe to ignore

**Permission denied**
- Ensure you have database admin privileges
- Check your Supabase project connection string
