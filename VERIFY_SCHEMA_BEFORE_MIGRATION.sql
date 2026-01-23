-- ============================================================================
-- SCHEMA VERIFICATION BEFORE MIGRATION
-- ============================================================================
-- Run this script BEFORE running 17_fix_product_deletion_and_expiry.sql
-- to verify your current schema state
-- ============================================================================

-- Check if columns already exist
SELECT 
  'products table' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name IN ('status', 'deleted_at', 'shelf_life_days')
ORDER BY column_name;

-- Check products table structure
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- Check if pg_cron extension is available
SELECT 
  extname as extension_name,
  extversion as version
FROM pg_extension
WHERE extname = 'pg_cron';

-- If pg_cron not found, you'll see no results (that's okay, we'll handle it)

-- Check for existing products
SELECT 
  COUNT(*) as total_products,
  COUNT(*) FILTER (WHERE is_hidden = false) as visible_products,
  COUNT(*) FILTER (WHERE is_hidden = true) as hidden_products,
  COUNT(*) FILTER (WHERE created_at + (shelf_life_days || ' days')::INTERVAL < NOW()) as expired_products
FROM products;

-- Check products with orders (these need soft delete)
SELECT 
  COUNT(DISTINCT p.id) as products_with_orders
FROM products p
INNER JOIN order_items oi ON p.id = oi.product_id;

-- Expected results:
-- ✓ 'status' column should NOT exist yet (we'll add it)
-- ✓ 'deleted_at' column should NOT exist yet (we'll add it)
-- ✓ 'shelf_life_days' column SHOULD exist (already in your schema)
-- ✓ pg_cron extension may or may not exist (we'll try to enable it)
