-- ========================================
-- FIX: Subscription column issue found!
-- ========================================
-- Your schema shows: subscription_tier, subscription_expires_at, subscription_started_at
-- But the query result shows: subscription: null
-- This means either the column doesn't exist or has wrong name

-- STEP 1: Check what columns actually exist
-- ========================================
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
AND column_name LIKE '%subscription%'
ORDER BY ordinal_position;

-- Expected output should show:
-- subscription_tier | text | 'free'::text
-- subscription_expires_at | timestamp with time zone | NULL
-- subscription_started_at | timestamp with time zone | NULL


-- STEP 2: Check the actual data for your farmer
-- ========================================
SELECT 
    id,
    full_name,
    email,
    role,
    subscription_tier,
    subscription_expires_at,
    subscription_started_at,
    created_at,
    updated_at
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- If this query FAILS with "column does not exist", then the columns are missing!
-- If it WORKS, check what the values are.


-- ========================================
-- SCENARIO A: Columns exist but are NULL/free
-- ========================================
-- If STEP 2 works and shows subscription_tier = 'free' or NULL:

UPDATE users
SET 
    subscription_tier = 'premium',
    subscription_started_at = '2026-01-20 20:05:29.580163+00',
    subscription_expires_at = '2026-02-19 20:05:29.580163+00',
    updated_at = NOW()
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';

-- Verify:
SELECT subscription_tier, subscription_expires_at 
FROM users 
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- ========================================
-- SCENARIO B: Columns don't exist at all
-- ========================================
-- If STEP 2 fails with "column subscription_tier does not exist":
-- This means the migration never ran!

-- Add the columns:
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium'));

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_started_at timestamp with time zone;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_expires_at timestamp with time zone;

-- Then update the farmer:
UPDATE users
SET 
    subscription_tier = 'premium',
    subscription_started_at = '2026-01-20 20:05:29.580163+00',
    subscription_expires_at = '2026-02-19 20:05:29.580163+00',
    updated_at = NOW()
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- ========================================
-- SCENARIO C: Check if you're querying wrong table
-- ========================================
-- Maybe there's a profiles table being used instead?

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%user%' OR table_name LIKE '%profile%';

-- If there's a 'profiles' table, check if subscription data is there:
-- SELECT * FROM profiles WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- ========================================
-- FINAL VERIFICATION
-- ========================================
-- After running the appropriate fix above, verify everything:

SELECT 
    id,
    full_name,
    email,
    subscription_tier,
    subscription_started_at,
    subscription_expires_at,
    CASE 
        WHEN subscription_tier = 'premium' AND subscription_expires_at > NOW() 
        THEN '✅ IS PREMIUM - App should show banner'
        WHEN subscription_tier = 'premium' AND subscription_expires_at <= NOW()
        THEN '⚠️ PREMIUM EXPIRED'
        ELSE '❌ NOT PREMIUM'
    END as status
FROM users
WHERE id = '539c835a-2529-4e05-bd30-52bfc1849598';


-- ========================================
-- EXPLANATION
-- ========================================
/*
Your schema definition shows these columns exist:
  subscription_tier text DEFAULT 'free'::text CHECK (subscription_tier = ANY (ARRAY['free'::text, 'premium'::text]))
  subscription_expires_at timestamp with time zone
  subscription_started_at timestamp with time zone

But your query result shows "subscription: null"

This could mean:
1. The columns exist but all have NULL values
2. The migration file (21_add_subscription_system.sql) never ran
3. The columns were added after the user was created, so they're NULL
4. There's a typo in column names

The fix is simple:
- Run STEP 1 to confirm columns exist
- Run the UPDATE statement to set the values
- App should then see premium status
*/
