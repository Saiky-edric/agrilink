-- Debug: Check subscription status for farmer
-- User ID: 539c835a-2529-4e05-bd30-52bfc1849598

-- 1. Check subscription_history table
SELECT 
    id,
    user_id,
    tier,
    status,
    started_at,
    expires_at,
    verified_by,
    verified_at,
    created_at
FROM subscription_history
WHERE user_id = '539c835a-2529-4e05-bd30-52bfc1849598'
ORDER BY created_at DESC;

-- 2. Check users table for subscription_tier
SELECT 
    id,
    full_name,
    email,
    role,
    subscription_tier,
    subscription_started_at,
    subscription_expires_at,
    is_active
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- 3. Check if subscription_tier column exists in users table
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name LIKE '%subscription%'
ORDER BY ordinal_position;

-- Expected Results:
-- ==================
-- subscription_history: Should show status='active', tier='premium'
-- users table: Should show subscription_tier='premium'
-- If users.subscription_tier is NULL or 'free', that's the problem!

-- 4. If subscription_tier is not 'premium', manually fix it:
-- UPDATE users
-- SET 
--     subscription_tier = 'premium',
--     subscription_started_at = '2026-01-20 20:05:29.580163+00',
--     subscription_expires_at = '2026-02-19 20:05:29.580163+00'
-- WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';
