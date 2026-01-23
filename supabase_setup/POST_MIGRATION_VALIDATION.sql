-- ============================================================
-- POST-MIGRATION VALIDATION SCRIPT
-- Run this AFTER completing the foreign key migration
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'POST-MIGRATION VALIDATION STARTING...';
    RAISE NOTICE '============================================================';
END $$;

-- ============================================================
-- TEST 1: Verify Foreign Key Constraints
-- ============================================================

DO $$
DECLARE
    profiles_fk_count INTEGER;
    users_fk_count INTEGER;
BEGIN
    RAISE NOTICE 'TEST 1: Checking Foreign Key Constraints...';
    
    -- Count foreign keys pointing to profiles
    SELECT COUNT(*) INTO profiles_fk_count
    FROM information_schema.table_constraints AS tc 
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'profiles'
        AND tc.table_schema = 'public';
    
    -- Count foreign keys pointing to users table (should be 0)
    SELECT COUNT(*) INTO users_fk_count
    FROM information_schema.table_constraints AS tc 
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'users'
        AND tc.table_schema = 'public';
    
    RAISE NOTICE 'Foreign keys pointing to profiles: %', profiles_fk_count;
    RAISE NOTICE 'Foreign keys pointing to users: %', users_fk_count;
    
    IF profiles_fk_count >= 14 AND users_fk_count = 0 THEN
        RAISE NOTICE '✅ PASS: Foreign key constraints correctly updated';
    ELSE
        RAISE NOTICE '❌ FAIL: Foreign key constraints not properly migrated';
        RAISE NOTICE 'Expected: 14+ pointing to profiles, 0 pointing to users';
        RAISE NOTICE 'Actual: % pointing to profiles, % pointing to users', profiles_fk_count, users_fk_count;
    END IF;
END $$;

-- ============================================================
-- TEST 2: Data Integrity Check
-- ============================================================

DO $$
DECLARE
    profiles_count INTEGER;
    auth_users_count INTEGER;
    orphaned_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2: Checking Data Integrity...';
    
    -- Count profiles and auth users
    SELECT COUNT(*) INTO profiles_count FROM profiles;
    SELECT COUNT(*) INTO auth_users_count FROM auth.users;
    
    RAISE NOTICE 'Profiles records: %', profiles_count;
    RAISE NOTICE 'Auth users records: %', auth_users_count;
    
    -- Check for orphaned profiles (profiles without auth users)
    SELECT COUNT(*) INTO orphaned_count
    FROM profiles p
    WHERE NOT EXISTS (SELECT 1 FROM auth.users au WHERE au.id = p.user_id);
    
    IF orphaned_count = 0 THEN
        RAISE NOTICE '✅ PASS: No orphaned profile records found';
    ELSE
        RAISE NOTICE '⚠️  WARNING: % orphaned profile records found', orphaned_count;
    END IF;
END $$;

-- ============================================================
-- TEST 3: Sample Data Relationships
-- ============================================================

DO $$
DECLARE
    test_result RECORD;
    relationship_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3: Testing Data Relationships...';
    
    -- Test cart relationships
    BEGIN
        SELECT COUNT(*) INTO relationship_count
        FROM profiles p
        INNER JOIN cart c ON c.user_id = p.user_id
        LIMIT 5;
        
        RAISE NOTICE '✅ PASS: Cart-Profile relationships working (%)', relationship_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAIL: Cart-Profile relationship error: %', SQLERRM;
    END;
    
    -- Test order relationships
    BEGIN
        SELECT COUNT(*) INTO relationship_count
        FROM profiles p
        INNER JOIN orders o ON o.buyer_id = p.user_id
        LIMIT 5;
        
        RAISE NOTICE '✅ PASS: Orders-Profile relationships working (%)', relationship_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAIL: Orders-Profile relationship error: %', SQLERRM;
    END;
    
    -- Test product relationships
    BEGIN
        SELECT COUNT(*) INTO relationship_count
        FROM profiles p
        INNER JOIN products pr ON pr.farmer_id = p.user_id
        LIMIT 5;
        
        RAISE NOTICE '✅ PASS: Products-Profile relationships working (%)', relationship_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAIL: Products-Profile relationship error: %', SQLERRM;
    END;
END $$;

-- ============================================================
-- TEST 4: Application Query Simulation
-- ============================================================

DO $$
DECLARE
    sample_user_id UUID;
    profile_data RECORD;
    cart_count INTEGER;
    order_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4: Simulating Application Queries...';
    
    -- Get a sample user ID from profiles
    SELECT user_id INTO sample_user_id FROM profiles LIMIT 1;
    
    IF sample_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with sample user ID: %', sample_user_id;
        
        -- Test profile query (like app does)
        BEGIN
            SELECT * INTO profile_data 
            FROM profiles 
            WHERE user_id = sample_user_id;
            
            IF profile_data.user_id IS NOT NULL THEN
                RAISE NOTICE '✅ PASS: Profile query successful - User: %', profile_data.full_name;
            ELSE
                RAISE NOTICE '❌ FAIL: Profile query returned no data';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ FAIL: Profile query error: %', SQLERRM;
        END;
        
        -- Test cart query
        BEGIN
            SELECT COUNT(*) INTO cart_count
            FROM cart WHERE user_id = sample_user_id;
            
            RAISE NOTICE '✅ PASS: Cart query successful - Items: %', cart_count;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ FAIL: Cart query error: %', SQLERRM;
        END;
        
        -- Test orders query  
        BEGIN
            SELECT COUNT(*) INTO order_count
            FROM orders WHERE buyer_id = sample_user_id;
            
            RAISE NOTICE '✅ PASS: Orders query successful - Orders: %', order_count;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ FAIL: Orders query error: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE '⚠️  WARNING: No sample user found in profiles table';
    END IF;
END $$;

-- ============================================================
-- TEST 5: RLS Policies Check
-- ============================================================

DO $$
DECLARE
    rls_enabled BOOLEAN;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5: Checking RLS Policies...';
    
    -- Check if RLS is enabled on profiles
    SELECT relrowsecurity INTO rls_enabled
    FROM pg_class 
    WHERE relname = 'profiles' AND relnamespace = (
        SELECT oid FROM pg_namespace WHERE nspname = 'public'
    );
    
    IF rls_enabled THEN
        RAISE NOTICE '✅ PASS: RLS enabled on profiles table';
    ELSE
        RAISE NOTICE '⚠️  WARNING: RLS not enabled on profiles table';
    END IF;
    
    -- Count RLS policies on profiles
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public';
    
    RAISE NOTICE 'RLS policies on profiles: %', policy_count;
    
    IF policy_count >= 3 THEN
        RAISE NOTICE '✅ PASS: Sufficient RLS policies found';
    ELSE
        RAISE NOTICE '⚠️  WARNING: May need additional RLS policies';
    END IF;
END $$;

-- ============================================================
-- TEST 6: Performance Check
-- ============================================================

DO $$
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    duration INTERVAL;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6: Performance Check...';
    
    -- Test profile lookup performance
    start_time := clock_timestamp();
    
    PERFORM p.user_id, p.full_name, p.email, p.role
    FROM profiles p
    WHERE p.user_id IN (
        SELECT user_id FROM profiles LIMIT 10
    );
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Profile lookup took: % ms', EXTRACT(MILLISECONDS FROM duration);
    
    IF EXTRACT(MILLISECONDS FROM duration) < 100 THEN
        RAISE NOTICE '✅ PASS: Performance acceptable';
    ELSE
        RAISE NOTICE '⚠️  WARNING: Performance may need optimization';
    END IF;
END $$;

-- ============================================================
-- FINAL VALIDATION SUMMARY
-- ============================================================

DO $$
DECLARE
    validation_summary TEXT := '';
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'VALIDATION SUMMARY';
    RAISE NOTICE '============================================================';
    
    -- Create a summary report
    SELECT string_agg(
        format('%s: %s FK constraints → profiles', 
               tc.table_name,
               COUNT(*)::text
        ), E'\n'
    ) INTO validation_summary
    FROM information_schema.table_constraints AS tc 
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'profiles'
        AND tc.table_schema = 'public'
    GROUP BY tc.table_name
    ORDER BY tc.table_name;
    
    RAISE NOTICE 'Foreign Key Migration Results:';
    RAISE NOTICE '%', COALESCE(validation_summary, 'No foreign keys found');
    
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Test Flutter application thoroughly';
    RAISE NOTICE '2. Verify all user features work correctly';
    RAISE NOTICE '3. Monitor for any runtime errors';
    RAISE NOTICE '4. Consider dropping users table after validation';
    RAISE NOTICE '';
    RAISE NOTICE 'Migration Status: VALIDATION COMPLETE ✅';
    RAISE NOTICE '============================================================';
END $$;

-- ============================================================
-- OPTIONAL: Quick App Testing Queries
-- ============================================================

-- These queries simulate what your Flutter app will do:

-- Simulate user authentication and profile loading
SELECT 
    p.user_id,
    p.full_name,
    p.email,
    p.role,
    p.municipality,
    CASE 
        WHEN p.is_active THEN 'Active'
        ELSE 'Suspended'
    END as status
FROM profiles p
LIMIT 3;

-- Simulate cart loading for a user
SELECT 
    p.full_name as user_name,
    COUNT(c.id) as cart_items,
    STRING_AGG(pr.name, ', ') as products
FROM profiles p
LEFT JOIN cart c ON c.user_id = p.user_id
LEFT JOIN products pr ON pr.id = c.product_id
GROUP BY p.user_id, p.full_name
HAVING COUNT(c.id) > 0
LIMIT 3;

-- Simulate order history for a user
SELECT 
    p.full_name as buyer_name,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_spent
FROM profiles p
LEFT JOIN orders o ON o.buyer_id = p.user_id
GROUP BY p.user_id, p.full_name
HAVING COUNT(o.id) > 0
LIMIT 3;