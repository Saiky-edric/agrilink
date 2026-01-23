-- ========================================
-- SIMPLE FIX: Update farmer to premium NOW
-- ========================================
-- Farmer ID: 539c835a-2529-4e05-bd30-52bfc1849598

-- Step 1: Check current status
SELECT 
    full_name,
    email,
    subscription_tier,
    subscription_expires_at,
    'Current status: NOT premium' as note
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- Step 2: Update to premium
UPDATE users
SET 
    subscription_tier = 'premium',
    subscription_started_at = '2026-01-20 20:05:29.580163+00',
    subscription_expires_at = '2026-02-19 20:05:29.580163+00',
    updated_at = NOW()
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- Step 3: Verify the fix worked
SELECT 
    full_name,
    email,
    subscription_tier,
    subscription_started_at,
    subscription_expires_at,
    CASE 
        WHEN subscription_tier = 'premium' AND subscription_expires_at > NOW() 
        THEN '✅ IS NOW PREMIUM - App will show banner!'
        ELSE '❌ STILL NOT PREMIUM - Something went wrong'
    END as result,
    EXTRACT(DAY FROM (subscription_expires_at - NOW()))::int as days_remaining
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- Expected result:
-- ✅ IS NOW PREMIUM - App will show banner!
-- days_remaining: 29 or 30

-- After running this, restart your Flutter app:
-- flutter clean && flutter run
