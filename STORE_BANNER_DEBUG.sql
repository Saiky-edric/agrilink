-- Check if store banner URL is saved in database
-- Replace 'YOUR_FARMER_ID' with the actual farmer's user ID

-- Check current store banner URL for your farmer
SELECT id, full_name, store_banner_url, store_logo_url, updated_at 
FROM users 
WHERE role = 'farmer' 
ORDER BY updated_at DESC 
LIMIT 5;

-- If you know your farmer ID, check specifically:
-- SELECT id, full_name, store_banner_url, store_logo_url, updated_at 
-- FROM users 
-- WHERE id = 'YOUR_FARMER_ID';