-- =============================================
-- COMPREHENSIVE RLS DEBUGGING
-- =============================================
-- This will help us identify exactly what's causing the RLS violation

-- 1. CHECK CURRENT AUTHENTICATION CONTEXT
SELECT 
    '=== AUTHENTICATION DEBUG ===' as debug_section,
    auth.uid() as current_user_id,
    auth.role() as current_role,
    auth.email() as current_email,
    CASE 
        WHEN auth.uid() IS NULL THEN '❌ NO AUTHENTICATION CONTEXT'
        ELSE '✅ AUTHENTICATED'
    END as auth_status;

-- 2. CHECK USER TABLE DATA FOR YOUR SPECIFIC USER
-- Replace 'YOUR_USER_ID' with your actual user ID from the Flutter logs
SELECT 
    '=== USER DATA DEBUG ===' as debug_section,
    id,
    email,
    full_name,
    role,
    is_active,
    created_at
FROM users 
WHERE id = '25a3e497-6b2f-4740-878d-17379d9e1644';  -- Your user ID from logs

-- 3. CHECK TABLE STRUCTURE AND RLS STATUS
SELECT 
    '=== TABLE STRUCTURE DEBUG ===' as debug_section,
    tablename,
    tableowner,
    rowsecurity as rls_enabled,
    hasindexes,
    hastriggers
FROM pg_tables 
WHERE tablename = 'farmer_verifications';

-- 4. CHECK ALL CURRENT POLICIES
SELECT 
    '=== RLS POLICIES DEBUG ===' as debug_section,
    policyname,
    cmd as command,
    permissive,
    roles,
    qual as using_condition,
    with_check as with_check_condition
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- 5. CHECK PERMISSIONS
SELECT 
    '=== PERMISSIONS DEBUG ===' as debug_section,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'farmer_verifications'
ORDER BY grantee, privilege_type;

-- 6. TEST POLICY CONDITIONS MANUALLY
-- This tests if the policy conditions would work for your user
SELECT 
    '=== POLICY CONDITION TEST ===' as debug_section,
    '25a3e497-6b2f-4740-878d-17379d9e1644' as your_user_id,
    auth.uid() as db_auth_uid,
    CASE 
        WHEN auth.uid() = '25a3e497-6b2f-4740-878d-17379d9e1644'::uuid THEN '✅ User ID matches'
        ELSE '❌ User ID mismatch'
    END as user_id_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE id = '25a3e497-6b2f-4740-878d-17379d9e1644'::uuid
            AND role = 'farmer'
            AND is_active = true
        ) THEN '✅ User is active farmer'
        ELSE '❌ User is not active farmer'
    END as farmer_check;

-- 7. TEST MINIMAL INSERT CAPABILITY
-- First, let's see if we can even select from the table
SELECT 
    '=== TABLE ACCESS TEST ===' as debug_section,
    COUNT(*) as total_records
FROM farmer_verifications;

-- 8. SIMULATE THE EXACT INSERT
-- This will show us what happens when we try the exact insert your app is doing
-- DO NOT RUN THIS - it's just for testing the policy
/*
DO $$
BEGIN
    BEGIN
        -- Try to insert with your exact user ID
        INSERT INTO farmer_verifications (
            farmer_id,
            farm_name,
            farm_address,
            farmer_id_image_url,
            barangay_cert_image_url,
            selfie_image_url,
            status,
            user_name,
            user_email,
            verification_type,
            submitted_at,
            created_at
        ) VALUES (
            '25a3e497-6b2f-4740-878d-17379d9e1644',
            'Test Farm',
            'Test Address',
            'test-url-1',
            'test-url-2',
            'test-url-3',
            'pending',
            'Test User',
            'test@email.com',
            'farmer',
            now(),
            now()
        );
        
        RAISE NOTICE '✅ INSERT SUCCESSFUL - RLS is not the issue!';
        
        -- Clean up the test record
        DELETE FROM farmer_verifications 
        WHERE farmer_id = '25a3e497-6b2f-4740-878d-17379d9e1644'
        AND farm_name = 'Test Farm';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ INSERT FAILED: %', SQLERRM;
    END;
END $$;
*/

-- 9. CHECK FOR TRIGGERS OR OTHER RESTRICTIONS
SELECT 
    '=== TRIGGERS DEBUG ===' as debug_section,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'farmer_verifications';

-- 10. CHECK FOREIGN KEY CONSTRAINTS
SELECT 
    '=== FOREIGN KEYS DEBUG ===' as debug_section,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'farmer_verifications';

-- 11. FINAL RECOMMENDATIONS
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔍 RLS DEBUGGING COMPLETE!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Review the results above to identify:';
    RAISE NOTICE '1. Is auth.uid() returning your user ID?';
    RAISE NOTICE '2. Are RLS policies properly configured?';
    RAISE NOTICE '3. Does your user exist with farmer role?';
    RAISE NOTICE '4. Are there any foreign key violations?';
    RAISE NOTICE '5. Are there triggers interfering?';
    RAISE NOTICE '';
    RAISE NOTICE 'If auth.uid() is NULL, that''s the root cause.';
    RAISE NOTICE 'If all checks pass, the issue might be elsewhere.';
    RAISE NOTICE '===============================================';
END $$;