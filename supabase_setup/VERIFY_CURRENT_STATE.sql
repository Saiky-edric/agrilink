-- ============================================================
-- QUICK VERIFICATION: Current Database State
-- Run this first to understand your current situation
-- ============================================================

-- Check if both tables exist and their record counts
SELECT 
    'Table Status' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public')
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as users_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public')
        THEN 'EXISTS'
        ELSE 'MISSING'
    END as profiles_table;

-- Get record counts if tables exist
DO $$
DECLARE
    users_count INTEGER := 0;
    profiles_count INTEGER := 0;
    auth_users_count INTEGER := 0;
BEGIN
    -- Count users table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        EXECUTE 'SELECT COUNT(*) FROM users' INTO users_count;
    END IF;
    
    -- Count profiles table  
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
        SELECT COUNT(*) INTO profiles_count FROM profiles;
    END IF;
    
    -- Count auth.users
    SELECT COUNT(*) INTO auth_users_count FROM auth.users;
    
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'RECORD COUNTS:';
    RAISE NOTICE 'auth.users: % records', auth_users_count;
    RAISE NOTICE 'users: % records', users_count;
    RAISE NOTICE 'profiles: % records', profiles_count;
    RAISE NOTICE '============================================================';
    
    -- Data integrity check
    IF users_count > 0 AND profiles_count = 0 THEN
        RAISE NOTICE '❌ CRITICAL: Users table has data but profiles is empty';
        RAISE NOTICE '   ACTION: Run migration script to move data to profiles';
    ELSIF users_count = 0 AND profiles_count > 0 THEN
        RAISE NOTICE '✅ GOOD: Data is in profiles table (app will work)';
        RAISE NOTICE '   ACTION: Run foreign key fix script';
    ELSIF users_count > 0 AND profiles_count > 0 THEN
        RAISE NOTICE '⚠️  WARNING: Data exists in both tables';
        RAISE NOTICE '   ACTION: Check for data consistency before migration';
    ELSE
        RAISE NOTICE '❌ CRITICAL: No user data found in either table';
    END IF;
END $$;

-- Check foreign key constraints - where do they point?
SELECT 
    'Foreign Key Analysis' as analysis,
    COUNT(CASE WHEN ccu.table_name = 'users' THEN 1 END) as pointing_to_users_table,
    COUNT(CASE WHEN ccu.table_name = 'profiles' THEN 1 END) as pointing_to_profiles_table,
    COUNT(CASE WHEN ccu.table_name = 'users' AND ccu.table_schema = 'auth' THEN 1 END) as pointing_to_auth_users
FROM information_schema.table_constraints AS tc 
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public';

-- Sample data check - do IDs match between users and profiles?
DO $$
DECLARE
    sample_user_id UUID;
    profile_exists BOOLEAN := FALSE;
    users_exists BOOLEAN := FALSE;
BEGIN
    -- Check if tables exist
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') INTO users_exists;
    
    IF users_exists THEN
        -- Get a sample user ID
        SELECT id INTO sample_user_id FROM users LIMIT 1;
        
        IF sample_user_id IS NOT NULL THEN
            -- Check if same ID exists in profiles
            SELECT EXISTS (SELECT 1 FROM profiles WHERE user_id = sample_user_id) INTO profile_exists;
            
            RAISE NOTICE '============================================================';
            RAISE NOTICE 'DATA CONSISTENCY CHECK:';
            RAISE NOTICE 'Sample user ID from users table: %', sample_user_id;
            RAISE NOTICE 'Same ID exists in profiles: %', profile_exists;
            
            IF profile_exists THEN
                RAISE NOTICE '✅ IDs match between tables - migration will work';
            ELSE
                RAISE NOTICE '❌ IDs do not match - need to investigate data relationship';
            END IF;
            RAISE NOTICE '============================================================';
        END IF;
    END IF;
END $$;

-- List tables that will be affected by foreign key changes
SELECT 
    tc.table_name as affected_table,
    kcu.column_name as foreign_key_column,
    ccu.table_name as references_table,
    'NEEDS UPDATE' as action_needed
FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'users'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;