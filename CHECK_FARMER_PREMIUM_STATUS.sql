-- ========================================
-- STEP-BY-STEP: Check Farmer Premium Status
-- ========================================
-- Farmer User ID: 539c835a-2529-4e05-bd30-52bfc1849598

-- STEP 1: Check subscription_history table
-- This should show status='active', tier='premium'
-- ========================================
SELECT 
    'subscription_history' as table_name,
    id,
    user_id,
    tier,
    status,
    started_at,
    expires_at,
    verified_by,
    verified_at,
    created_at,
    updated_at
FROM subscription_history
WHERE user_id = '539c835a-2529-4e05-bd30-52bfc1849598'
ORDER BY created_at DESC
LIMIT 1;

-- EXPECTED: tier='premium', status='active'
-- IF NOT ACTIVE: The admin approval didn't work correctly


-- STEP 2: Check users table for subscription_tier
-- THIS IS THE MOST IMPORTANT CHECK!
-- ========================================
SELECT 
    'users' as table_name,
    id,
    full_name,
    email,
    role,
    subscription_tier,           -- ← THIS MUST BE 'premium'
    subscription_started_at,     -- ← Should have a date
    subscription_expires_at,     -- ← Should be ~30 days in future
    created_at,
    updated_at
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- EXPECTED: subscription_tier='premium', expires_at in future
-- IF subscription_tier IS NULL OR 'free': THIS IS THE PROBLEM!


-- STEP 3: Check if subscription columns exist in users table
-- ========================================
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
AND column_name LIKE '%subscription%'
ORDER BY ordinal_position;

-- EXPECTED: Should show 3 columns:
-- - subscription_tier (text)
-- - subscription_started_at (timestamp)
-- - subscription_expires_at (timestamp)


-- STEP 4: Check if there are any RLS policies blocking updates
-- ========================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users'
AND schemaname = 'public';

-- Look for policies that might prevent UPDATE on subscription_tier


-- ========================================
-- DIAGNOSIS SUMMARY
-- ========================================

-- ✅ HEALTHY SYSTEM:
-- subscription_history: status='active', tier='premium'
-- users: subscription_tier='premium', expires_at='2026-02-19...'
-- Result: Farmer should see premium banner

-- ❌ PROBLEM SCENARIO 1: subscription_tier not updated
-- subscription_history: status='active' ✓
-- users: subscription_tier='free' or NULL ✗
-- FIX: Run the UPDATE statement below

-- ❌ PROBLEM SCENARIO 2: Columns don't exist
-- information_schema: No subscription columns found
-- FIX: Run the migration SQL (21_add_subscription_system.sql)

-- ❌ PROBLEM SCENARIO 3: RLS Policy blocking
-- pg_policies: Policy prevents admin from updating subscription_tier
-- FIX: Update RLS policy to allow admin updates


-- ========================================
-- MANUAL FIX: If subscription_tier is NULL or 'free'
-- ========================================

-- Uncomment and run this ONLY if STEP 2 shows subscription_tier != 'premium':
/*
UPDATE users
SET 
    subscription_tier = 'premium',
    subscription_started_at = '2026-01-20 20:05:29.580163+00',
    subscription_expires_at = '2026-02-19 20:05:29.580163+00',
    updated_at = NOW()
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- Verify the update worked:
SELECT subscription_tier, subscription_expires_at 
FROM users 
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- Should now show: subscription_tier = 'premium'
*/


-- ========================================
-- TEST QUERY: What the app sees
-- ========================================

-- This is exactly what the Flutter app queries when loading user profile:
SELECT 
    id,
    email,
    full_name,
    phone_number,
    role,
    municipality,
    barangay,
    street,
    subscription_tier,        -- ← App checks this
    subscription_started_at,
    subscription_expires_at,  -- ← And this to check if expired
    is_active,
    created_at,
    updated_at
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- The app then calculates:
-- isPremium = (subscription_tier == 'premium' && subscription_expires_at > NOW())


-- ========================================
-- FINAL VERIFICATION
-- ========================================

-- Run this to see what the farmer SHOULD see:
SELECT 
    CASE 
        WHEN subscription_tier = 'premium' 
             AND subscription_expires_at > NOW() 
        THEN '✅ FARMER IS PREMIUM - Should see green banner'
        WHEN subscription_tier = 'premium' 
             AND subscription_expires_at <= NOW()
        THEN '⚠️ PREMIUM EXPIRED - Should see upgrade prompt'
        ELSE '❌ NOT PREMIUM - Should see basic/free tier'
    END as status_check,
    subscription_tier as current_tier,
    subscription_expires_at as expires_on,
    CASE 
        WHEN subscription_expires_at > NOW()
        THEN EXTRACT(DAY FROM (subscription_expires_at - NOW()))::int
        ELSE 0
    END as days_remaining
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- ========================================
-- NEXT STEPS BASED ON RESULTS
-- ========================================

-- If STEP 2 shows subscription_tier = 'premium':
--   → Database is correct
--   → Issue is in the Flutter app (cache, API, etc.)
--   → Run: flutter clean && flutter run
--   → Check app logs for isPremium value

-- If STEP 2 shows subscription_tier = NULL or 'free':
--   → Database was NOT updated by admin approval
--   → Run the UPDATE statement in "MANUAL FIX" section
--   → Then restart Flutter app

-- If STEP 3 shows no subscription columns:
--   → Migration never ran
--   → Run: supabase_setup/21_add_subscription_system.sql
--   → Then run the UPDATE statement

-- If STEP 4 shows RLS policy blocking updates:
--   → Check if admin user has permission
--   → May need to update RLS policies for subscription_tier column
