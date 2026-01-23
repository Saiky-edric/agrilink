-- =============================================
-- RESTORE ORIGINAL SECURITY SETTINGS
-- =============================================
-- This restores the farmer_verifications table to its original,
-- secure configuration before any RLS modifications

-- 1. START FRESH - Remove everything added by previous fixes
DROP FUNCTION IF EXISTS insert_farmer_verification CASCADE;
DROP FUNCTION IF EXISTS can_farmer_insert_verification CASCADE;

-- 2. DROP ALL EXISTING POLICIES (clean slate)
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;
DROP POLICY IF EXISTS "Allow authenticated users to select" ON farmer_verifications;
DROP POLICY IF EXISTS "Allow authenticated farmers to insert" ON farmer_verifications;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON farmer_verifications;

-- 3. REVOKE ALL EXCESSIVE PERMISSIONS
REVOKE ALL ON farmer_verifications FROM public CASCADE;
REVOKE ALL ON farmer_verifications FROM anon CASCADE;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM public CASCADE;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon CASCADE;

-- 4. ENABLE ROW LEVEL SECURITY (proper security)
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- 5. CREATE MINIMAL, SECURE POLICIES

-- Allow users to view their own verifications + admins to view all
CREATE POLICY "view_own_verification" ON farmer_verifications
    FOR SELECT
    USING (
        -- User can see their own verification
        farmer_id = auth.uid()
        OR
        -- Admins can see all verifications
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Allow authenticated farmers to insert their own verifications
CREATE POLICY "insert_own_verification" ON farmer_verifications
    FOR INSERT
    WITH CHECK (
        -- Must be authenticated
        auth.uid() IS NOT NULL
        AND
        -- Must be inserting for their own user ID
        farmer_id = auth.uid()
        AND
        -- Must be an active farmer
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer'
            AND is_active = true
        )
    );

-- Allow users to update their own verifications (for resubmissions)
CREATE POLICY "update_own_verification" ON farmer_verifications
    FOR UPDATE
    USING (
        farmer_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role IN ('farmer', 'admin')
            AND is_active = true
        )
    )
    WITH CHECK (
        farmer_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- 6. GRANT ONLY NECESSARY PERMISSIONS
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 7. VERIFICATION AND REPORTING

-- Check RLS status
SELECT 
    'Table Security Status' as info,
    CASE 
        WHEN rowsecurity THEN 'Row Level Security: ENABLED ✅'
        ELSE 'Row Level Security: DISABLED ❌'
    END as status
FROM pg_tables 
WHERE tablename = 'farmer_verifications';

-- List active policies
SELECT 
    'Active Policies:' as info,
    policyname as policy_name,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Check permissions
SELECT 
    'Permissions:' as info,
    grantee as role,
    string_agg(privilege_type, ', ') as privileges
FROM information_schema.table_privileges 
WHERE table_name = 'farmer_verifications'
GROUP BY grantee
ORDER BY grantee;

-- Final message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🛡️  ORIGINAL SECURITY SETTINGS RESTORED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '✅ All bypass functions removed';
    RAISE NOTICE '✅ Excessive permissions revoked';
    RAISE NOTICE '✅ RLS properly enabled';
    RAISE NOTICE '✅ Secure policies implemented';
    RAISE NOTICE '✅ Minimal necessary permissions granted';
    RAISE NOTICE '';
    RAISE NOTICE 'Your database is now secure and follows best practices!';
    RAISE NOTICE 'If verification still fails, the issue is not RLS-related.';
    RAISE NOTICE '===============================================';
END $$;