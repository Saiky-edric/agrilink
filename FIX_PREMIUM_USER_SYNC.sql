-- ============================================================
-- FIX: Sync subscription_history with users table
-- This fixes the mismatch where history says "active" but users table still shows "free"
-- ============================================================

-- STEP 1: Identify the mismatches
-- Run this first to see which users need fixing
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.subscription_tier as current_tier,
    sh.tier as should_be_tier,
    sh.status,
    sh.started_at,
    sh.expires_at,
    '❌ NEEDS FIX' as action
FROM public.users u
INNER JOIN public.subscription_history sh ON u.id = sh.user_id
WHERE sh.status = 'active'
  AND sh.tier = 'premium'
  AND u.subscription_tier != 'premium'
ORDER BY sh.verified_at DESC;

-- STEP 2: Fix the mismatches - Update users table to match subscription_history
-- This will sync all users who should be premium but aren't
UPDATE public.users u
SET 
    subscription_tier = 'premium',
    subscription_started_at = sh.started_at,
    subscription_expires_at = sh.expires_at,
    updated_at = NOW()
FROM public.subscription_history sh
WHERE u.id = sh.user_id
  AND sh.status = 'active'
  AND sh.tier = 'premium'
  AND u.subscription_tier != 'premium';

-- STEP 3: Verify the fix worked
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.subscription_tier,
    u.subscription_expires_at,
    '✅ FIXED' as status
FROM public.users u
WHERE subscription_tier = 'premium'
  AND role = 'farmer'
ORDER BY subscription_started_at DESC;

-- STEP 4: Count premium users (should match dashboard now)
SELECT 
    COUNT(*) as premium_users_count,
    'This should appear in dashboard' as note
FROM public.users
WHERE subscription_tier = 'premium'
  AND role = 'farmer'
  AND (subscription_expires_at IS NULL OR subscription_expires_at > NOW());
