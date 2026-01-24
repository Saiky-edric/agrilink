-- =============================================
-- FIX PLATFORM_SETTINGS DUPLICATE ROWS
-- =============================================
-- Problem: platform_settings has multiple rows
-- Expected: Only ONE row should exist
-- =============================================

BEGIN;

-- Check current state
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM platform_settings;
    RAISE NOTICE 'Current platform_settings rows: %', row_count;
END $$;

-- =============================================
-- SOLUTION 1: Keep the most recent row, delete others
-- =============================================

-- Delete all but the most recently updated row
DELETE FROM platform_settings
WHERE id NOT IN (
    SELECT id 
    FROM platform_settings 
    ORDER BY updated_at DESC NULLS LAST 
    LIMIT 1
);

-- Verify only one row remains
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM platform_settings;
    IF row_count = 1 THEN
        RAISE NOTICE '✅ Fixed! Now has exactly 1 row';
    ELSE
        RAISE WARNING '⚠️ Still has % rows', row_count;
    END IF;
END $$;

-- =============================================
-- ADD CONSTRAINT to prevent duplicates in future
-- =============================================

-- Ensure only one row can ever exist
-- (Since there's no natural unique key, we use a check constraint)

-- First, add a dummy boolean column that's always true
ALTER TABLE platform_settings 
ADD COLUMN IF NOT EXISTS singleton_guard BOOLEAN DEFAULT TRUE NOT NULL;

-- Then add a unique constraint on it (only one TRUE value allowed)
DROP INDEX IF EXISTS platform_settings_singleton_idx;
CREATE UNIQUE INDEX platform_settings_singleton_idx 
ON platform_settings(singleton_guard);

COMMIT;

-- =============================================
-- VERIFICATION
-- =============================================

-- Check the final state
SELECT 
    id,
    app_name,
    jt_per2kg_fee,
    commission_rate,
    updated_at,
    singleton_guard
FROM platform_settings;

RAISE NOTICE '✅ Platform settings fixed!';
RAISE NOTICE '📝 Only ONE row now exists';
RAISE NOTICE '🔒 Unique constraint added to prevent duplicates';
