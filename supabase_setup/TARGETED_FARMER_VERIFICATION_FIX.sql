-- TARGETED FIX: Farmer Verification RLS Based on Actual Schema
-- This fix is specifically designed for your current database structure

-- =============================================
-- 1. ANALYZE CURRENT STATE
-- =============================================

-- Check current RLS policies
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Check current user authentication function
SELECT auth.uid() as current_user_id;

-- =============================================
-- 2. FIX RLS POLICIES FOR FARMER_VERIFICATIONS
-- =============================================

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- Ensure RLS is enabled
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 3. CREATE NEW COMPREHENSIVE POLICIES
-- =============================================

-- Policy 1: Allow farmers to view their own verifications
CREATE POLICY "Farmers can view own verification" ON farmer_verifications
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL 
        AND farmer_id = auth.uid()
    );

-- Policy 2: Allow farmers to insert their own verifications
CREATE POLICY "Farmers can insert own verification" ON farmer_verifications
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND farmer_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer'
            AND is_active = true
        )
    );

-- Policy 3: Allow farmers to update their own verifications (for resubmissions)
CREATE POLICY "Farmers can update own verification" ON farmer_verifications
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL 
        AND farmer_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer'
            AND is_active = true
        )
    )
    WITH CHECK (
        farmer_id = auth.uid()
    );

-- Policy 4: Allow admins to manage all verifications
CREATE POLICY "Admins can manage verifications" ON farmer_verifications
    FOR ALL
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- =============================================
-- 4. GRANT NECESSARY PERMISSIONS
-- =============================================

-- Grant table permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =============================================
-- 5. VERIFY THE FOREIGN KEY CONSTRAINT
-- =============================================

-- Check existing foreign key constraint
SELECT 
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
    AND tc.table_name = 'farmer_verifications'
    AND kcu.column_name = 'farmer_id';

-- The constraint should reference users(id), which matches your schema

-- =============================================
-- 6. CREATE HELPFUL DEBUGGING VIEWS
-- =============================================

-- Create a view to help debug verification issues
CREATE OR REPLACE VIEW verification_debug AS
SELECT 
    fv.id,
    fv.farmer_id,
    u.full_name,
    u.email,
    u.role,
    u.is_active,
    fv.status,
    fv.created_at,
    CASE 
        WHEN auth.uid() = fv.farmer_id THEN 'Can access own verification'
        WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN 'Admin access'
        ELSE 'No access'
    END as access_level
FROM farmer_verifications fv
LEFT JOIN users u ON u.id = fv.farmer_id;

-- =============================================
-- 7. TEST THE POLICIES
-- =============================================

-- Test function to validate RLS policies work correctly
CREATE OR REPLACE FUNCTION test_farmer_verification_rls()
RETURNS TABLE (
    test_name text,
    result text,
    details text
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Test 1: Check if authenticated user can be identified
    RETURN QUERY
    SELECT 
        'Authentication Check'::text,
        CASE 
            WHEN auth.uid() IS NOT NULL THEN 'PASS'::text
            ELSE 'FAIL'::text
        END,
        'Current user ID: ' || COALESCE(auth.uid()::text, 'NULL');

    -- Test 2: Check if current user exists in users table
    RETURN QUERY
    SELECT 
        'User Exists Check'::text,
        CASE 
            WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid()) THEN 'PASS'::text
            ELSE 'FAIL'::text
        END,
        'User found in users table: ' || 
        CASE 
            WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid()) THEN 'YES'
            ELSE 'NO'
        END;

    -- Test 3: Check user role
    RETURN QUERY
    SELECT 
        'User Role Check'::text,
        CASE 
            WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'farmer') THEN 'FARMER'::text
            WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN 'ADMIN'::text
            WHEN EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'buyer') THEN 'BUYER'::text
            ELSE 'UNKNOWN'::text
        END,
        'Current user role';

    -- Test 4: Check if user can insert verification
    RETURN QUERY
    SELECT 
        'Insert Permission Check'::text,
        CASE 
            WHEN auth.uid() IS NOT NULL 
                AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'farmer' AND is_active = true)
                THEN 'PASS'::text
            ELSE 'FAIL'::text
        END,
        'Can insert verification record';
END;
$$;

-- =============================================
-- 8. FINAL VERIFICATION
-- =============================================

-- Display final policy state
SELECT 
    'Policy Name: ' || policyname as policy_info,
    'Command: ' || cmd as command_type,
    'Permissive: ' || permissive::text as permissive_flag
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FARMER VERIFICATION RLS FIX COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test with: SELECT * FROM test_farmer_verification_rls();';
    RAISE NOTICE '2. Ensure user is logged in as farmer role';
    RAISE NOTICE '3. Try verification submission again';
    RAISE NOTICE '========================================';
END $$;