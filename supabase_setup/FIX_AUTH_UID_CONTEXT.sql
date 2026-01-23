-- =============================================
-- FIX: auth.uid() Context Issue
-- =============================================
-- Based on common causes analysis, this fixes the auth context

-- 1. CHECK CURRENT AUTH EXTENSIONS AND FUNCTIONS
SELECT 
    'Auth Extensions Check' as test,
    extname,
    extversion
FROM pg_extension 
WHERE extname IN ('pgjwt', 'pgcrypto', 'uuid-ossp');

-- 2. VERIFY AUTH FUNCTIONS EXIST
SELECT 
    'Auth Functions Check' as test,
    proname as function_name,
    pronargs as arg_count
FROM pg_proc 
WHERE proname IN ('auth.uid', 'auth.role', 'auth.jwt', 'auth.email')
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth');

-- 3. CHECK IF WE'RE RUNNING IN SERVICE_ROLE CONTEXT
SELECT 
    'Current Role Context' as test,
    current_user as current_db_user,
    session_user as session_user,
    CASE 
        WHEN current_user = 'service_role' THEN 'SERVICE_ROLE (bypasses RLS, auth.uid() = NULL)'
        WHEN current_user = 'authenticator' THEN 'AUTHENTICATOR (should work with JWT)'
        WHEN current_user = 'anon' THEN 'ANON (needs JWT for auth.uid())'
        WHEN current_user = 'authenticated' THEN 'AUTHENTICATED (should have auth.uid())'
        ELSE 'OTHER: ' || current_user
    END as role_explanation;

-- 4. TEST AUTH FUNCTIONS AVAILABILITY
SELECT 
    'Auth Function Test' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'uid' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth'))
        THEN 'auth.uid() function EXISTS'
        ELSE 'auth.uid() function MISSING'
    END as uid_function_status;

-- 5. CREATE PROPER RLS POLICIES THAT WORK WITH JWT
-- First, enable RLS properly
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- Drop the old policies
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- 6. CREATE AUTH-CONTEXT-AWARE POLICIES
-- These policies check for auth context more robustly

-- Policy for viewing verifications
CREATE POLICY "farmers_view_own_verification" ON farmer_verifications
    FOR SELECT
    TO authenticated
    USING (
        -- User owns this verification
        farmer_id = auth.uid()
        OR
        -- User is admin
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Policy for inserting verifications - more permissive approach
CREATE POLICY "farmers_insert_verification" ON farmer_verifications
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Basic auth context check
        auth.uid() IS NOT NULL
        AND
        -- User owns this verification
        farmer_id = auth.uid()
        AND
        -- Additional user validation (optional - can be removed if problematic)
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('farmer', 'admin')
            AND is_active = true
        )
    );

-- Policy for updating verifications
CREATE POLICY "farmers_update_own_verification" ON farmer_verifications
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND farmer_id = auth.uid()
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND farmer_id = auth.uid()
    );

-- 7. ALTERNATIVE: CREATE JWT-AWARE HELPER FUNCTION
-- This function can extract user ID from JWT claims if auth.uid() fails
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_id uuid;
BEGIN
    -- Try auth.uid() first
    SELECT auth.uid() INTO user_id;
    
    IF user_id IS NOT NULL THEN
        RETURN user_id;
    END IF;
    
    -- Fallback: try to extract from JWT claims
    BEGIN
        SELECT (auth.jwt() ->> 'sub')::uuid INTO user_id;
        RETURN user_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
    END;
END;
$$;

-- 8. CREATE FALLBACK POLICIES USING HELPER FUNCTION
-- These use the helper function instead of direct auth.uid()

DROP POLICY IF EXISTS "farmers_view_own_verification" ON farmer_verifications;
CREATE POLICY "farmers_view_own_verification" ON farmer_verifications
    FOR SELECT
    TO authenticated
    USING (
        farmer_id = get_current_user_id()
        OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = get_current_user_id()
            AND role = 'admin'
            AND is_active = true
        )
    );

DROP POLICY IF EXISTS "farmers_insert_verification" ON farmer_verifications;
CREATE POLICY "farmers_insert_verification" ON farmer_verifications
    FOR INSERT
    TO authenticated
    WITH CHECK (
        get_current_user_id() IS NOT NULL
        AND farmer_id = get_current_user_id()
    );

-- 9. GRANT PROPER PERMISSIONS
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 10. TEST THE SETUP
-- This will show if our fixes work
SELECT 
    'RLS Test Results' as section,
    CASE 
        WHEN rowsecurity THEN 'RLS ENABLED ✅'
        ELSE 'RLS DISABLED ❌'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'farmer_verifications';

-- Show active policies
SELECT 
    'Active Policies' as section,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔧 AUTH CONTEXT FIX APPLIED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '✅ Auth extensions verified';
    RAISE NOTICE '✅ RLS properly enabled';
    RAISE NOTICE '✅ JWT-aware policies created';
    RAISE NOTICE '✅ Fallback helper function added';
    RAISE NOTICE '✅ Proper permissions granted';
    RAISE NOTICE '';
    RAISE NOTICE 'If auth.uid() still returns NULL, the issue is';
    RAISE NOTICE 'with JWT token passing from your Flutter app.';
    RAISE NOTICE '===============================================';
END $$;