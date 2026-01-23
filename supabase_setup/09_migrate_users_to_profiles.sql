-- ============================================================
-- CRITICAL DATABASE FIX: Migrate from users to profiles table
-- This script fixes the database table inconsistency bug
-- ============================================================

-- ⚠️ BACKUP YOUR DATABASE BEFORE RUNNING THIS SCRIPT ⚠️

-- ============================================================
-- STEP 1: Check current table structure
-- ============================================================

-- Check if both tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('users', 'profiles')
ORDER BY table_name;

-- ============================================================
-- STEP 2: Create profiles table if it doesn't exist
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL DEFAULT 'User',
    phone_number TEXT DEFAULT '',
    role user_role NOT NULL DEFAULT 'buyer',
    municipality TEXT,
    barangay TEXT,
    street TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- STEP 3: Migrate data from users to profiles (if users table exists)
-- ============================================================

-- Check if users table has data
DO $$
DECLARE
    users_count INTEGER;
    profiles_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO users_count FROM information_schema.tables 
    WHERE table_name = 'users' AND table_schema = 'public';
    
    IF users_count > 0 THEN
        -- Get record counts
        EXECUTE 'SELECT COUNT(*) FROM users' INTO users_count;
        SELECT COUNT(*) INTO profiles_count FROM profiles;
        
        RAISE NOTICE 'Found % records in users table, % records in profiles table', users_count, profiles_count;
        
        -- Only migrate if users has data and profiles is empty or smaller
        IF users_count > 0 AND users_count > profiles_count THEN
            RAISE NOTICE 'Starting migration from users to profiles...';
            
            -- Insert users data into profiles (avoiding duplicates)
            INSERT INTO profiles (
                user_id, email, full_name, phone_number, role,
                municipality, barangay, street, is_active, created_at, updated_at
            )
            SELECT 
                u.id,
                COALESCE(u.email, ''),
                COALESCE(u.full_name, 'User'),
                COALESCE(u.phone_number, ''),
                COALESCE(u.role, 'buyer'::user_role),
                u.municipality,
                u.barangay,
                u.street,
                COALESCE(u.is_active, true),
                COALESCE(u.created_at, NOW()),
                COALESCE(u.updated_at, NOW())
            FROM users u
            WHERE u.id NOT IN (SELECT user_id FROM profiles);
            
            GET DIAGNOSTICS users_count = ROW_COUNT;
            RAISE NOTICE 'Migrated % records from users to profiles', users_count;
        END IF;
    END IF;
END $$;

-- ============================================================
-- STEP 4: Set up RLS policies for profiles table
-- ============================================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Create RLS policies
CREATE POLICY "Users can view own profile" 
    ON profiles FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" 
    ON profiles FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" 
    ON profiles FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- STEP 5: Update foreign key references
-- ============================================================

-- Update farmer_verifications table to reference profiles
DO $$
BEGIN
    -- Check if farmer_verifications.farmer_id should reference profiles.user_id
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'farmer_verifications' 
               AND column_name = 'farmer_id') THEN
        
        -- Add comment to clarify the reference
        COMMENT ON COLUMN farmer_verifications.farmer_id IS 'References profiles.user_id (auth user ID)';
        RAISE NOTICE 'Updated farmer_verifications.farmer_id reference';
    END IF;

    -- Update other tables that reference user IDs
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'products' 
               AND column_name = 'farmer_id') THEN
        
        COMMENT ON COLUMN products.farmer_id IS 'References profiles.user_id (auth user ID)';
        RAISE NOTICE 'Updated products.farmer_id reference';
    END IF;

    -- Update orders table
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'orders' 
               AND column_name = 'buyer_id') THEN
        
        COMMENT ON COLUMN orders.buyer_id IS 'References profiles.user_id (auth user ID)';
        RAISE NOTICE 'Updated orders.buyer_id reference';
    END IF;
END $$;

-- ============================================================
-- STEP 6: Create indexes for performance
-- ============================================================

-- Create indexes on profiles table
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_municipality ON profiles(municipality);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);

-- ============================================================
-- STEP 7: Verification queries
-- ============================================================

-- Verify the migration
SELECT 
    'profiles' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN email IS NOT NULL AND email != '' THEN 1 END) as with_email,
    COUNT(CASE WHEN full_name IS NOT NULL AND full_name != '' THEN 1 END) as with_name,
    COUNT(CASE WHEN role IS NOT NULL THEN 1 END) as with_role,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_users
FROM profiles

UNION ALL

SELECT 
    'auth.users' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as with_email,
    COUNT(CASE WHEN raw_user_meta_data->>'full_name' IS NOT NULL THEN 1 END) as with_name,
    COUNT(CASE WHEN raw_user_meta_data->>'role' IS NOT NULL THEN 1 END) as with_role,
    COUNT(*) as active_users  -- All auth users are considered active
FROM auth.users;

-- Check for orphaned records
SELECT 
    'Profiles without auth users' as check_name,
    COUNT(*) as count
FROM profiles p
WHERE NOT EXISTS (SELECT 1 FROM auth.users au WHERE au.id = p.user_id)

UNION ALL

SELECT 
    'Auth users without profiles' as check_name,
    COUNT(*) as count
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.user_id = au.id);

-- ============================================================
-- STEP 8: OPTIONAL - Remove users table after verification
-- ============================================================

-- Uncomment the lines below ONLY after verifying migration is successful
-- and testing the app thoroughly with the profiles table

/*
-- WARNING: This will permanently delete the users table
-- Only run this after confirming everything works correctly

-- Drop foreign key constraints that reference users table
-- (Add specific constraint drops here if needed)

-- Drop the users table
-- DROP TABLE IF EXISTS users CASCADE;

-- Verify users table is dropped
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_name = 'users';
-- Should return no rows

RAISE NOTICE 'Users table has been dropped. Profiles table is now the single source of truth.';
*/

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'MIGRATION COMPLETED SUCCESSFULLY';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test the application thoroughly';
    RAISE NOTICE '2. Verify user authentication and profile loading';
    RAISE NOTICE '3. Check all user-related features work correctly';
    RAISE NOTICE '4. Only after testing, uncomment Step 8 to drop users table';
    RAISE NOTICE '============================================================';
END $$;