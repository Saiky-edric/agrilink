-- =============================================
-- REVERSE NUCLEAR RLS FIX
-- =============================================
-- This reverses all changes made by NUCLEAR_RLS_FIX.sql
-- and restores proper RLS security settings

-- 1. DROP THE BYPASS FUNCTION
DROP FUNCTION IF EXISTS insert_farmer_verification;

-- 2. REVOKE ALL EXCESSIVE PERMISSIONS
REVOKE ALL PRIVILEGES ON farmer_verifications FROM public;
REVOKE ALL PRIVILEGES ON farmer_verifications FROM anon;

-- Revoke sequence permissions
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM public;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;

-- Revoke schema permissions
REVOKE USAGE ON SCHEMA public FROM public;
REVOKE USAGE ON SCHEMA public FROM anon;

-- 3. RE-ENABLE ROW LEVEL SECURITY
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- 4. CREATE PROPER, SECURE RLS POLICIES

-- Policy for farmers to view their own verifications
CREATE POLICY "Farmers can view own verification" ON farmer_verifications
    FOR SELECT
    USING (
        auth.uid() = farmer_id
        OR EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Policy for farmers to insert their own verifications
CREATE POLICY "Farmers can insert own verification" ON farmer_verifications
    FOR INSERT
    WITH CHECK (
        auth.uid() = farmer_id
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer'
            AND is_active = true
        )
    );

-- Policy for farmers to update their own verifications (for resubmissions)
CREATE POLICY "Farmers can update own verification" ON farmer_verifications
    FOR UPDATE
    USING (
        auth.uid() = farmer_id
        AND EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer'
            AND is_active = true
        )
    )
    WITH CHECK (
        auth.uid() = farmer_id
    );

-- Policy for admins to manage all verifications
CREATE POLICY "Admins can manage verifications" ON farmer_verifications
    FOR ALL
    USING (
        EXISTS (
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

-- 5. RESTORE PROPER PERMISSIONS (minimal and secure)
-- Only grant what's actually needed
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 6. VERIFY RLS IS PROPERLY ENABLED
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN 'ENABLED ✅' ELSE 'DISABLED ❌' END as rls_status
FROM pg_tables 
WHERE tablename = 'farmer_verifications';

-- 7. LIST THE RESTORED POLICIES
SELECT 
    policyname as policy_name,
    cmd as command,
    permissive as is_permissive
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- 8. CHECK CURRENT PERMISSIONS
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'farmer_verifications'
AND grantee IN ('authenticated', 'anon', 'public')
ORDER BY grantee, privilege_type;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔒 NUCLEAR RLS FIX SUCCESSFULLY REVERSED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Security settings restored:';
    RAISE NOTICE '✅ Row Level Security re-enabled';
    RAISE NOTICE '✅ Proper RLS policies created';
    RAISE NOTICE '✅ Excessive permissions revoked';
    RAISE NOTICE '✅ Bypass function removed';
    RAISE NOTICE '✅ Security hardened';
    RAISE NOTICE '';
    RAISE NOTICE 'Your database security is now properly configured!';
    RAISE NOTICE '===============================================';
END $$;