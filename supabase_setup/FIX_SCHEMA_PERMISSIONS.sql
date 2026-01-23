-- =============================================
-- FIX: Schema Permission Issues
-- =============================================
-- The previous fix seems to have caused schema permission issues
-- This restores proper access while maintaining the auth bypass

-- 1. RESTORE BASIC SCHEMA PERMISSIONS
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 2. RESTORE BASIC TABLE PERMISSIONS for essential tables
-- These are needed for the app to function at all
GRANT SELECT ON users TO authenticated;
GRANT SELECT ON users TO anon;

GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO anon;

GRANT SELECT, INSERT, UPDATE ON products TO authenticated;
GRANT SELECT, INSERT, UPDATE ON products TO anon;

GRANT SELECT, INSERT, UPDATE ON orders TO authenticated;
GRANT SELECT, INSERT, UPDATE ON orders TO anon;

GRANT SELECT, INSERT, UPDATE ON messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON messages TO anon;

GRANT SELECT, INSERT, UPDATE ON conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON conversations TO anon;

GRANT SELECT, INSERT, UPDATE ON notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON notifications TO anon;

-- 3. RESTORE SEQUENCE PERMISSIONS
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 4. ENSURE STORAGE PERMISSIONS
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- 5. MAKE SURE THE BYPASS FUNCTION IS ACCESSIBLE
GRANT EXECUTE ON FUNCTION submit_farmer_verification TO authenticated;
GRANT EXECUTE ON FUNCTION submit_farmer_verification TO anon;

-- 6. VERIFY PERMISSIONS ARE RESTORED
SELECT 
    'Schema Access Check' as test,
    CASE 
        WHEN has_schema_privilege('anon', 'public', 'USAGE') THEN '✅ ANON can access schema'
        ELSE '❌ ANON cannot access schema'
    END as anon_access,
    CASE 
        WHEN has_schema_privilege('authenticated', 'public', 'USAGE') THEN '✅ AUTHENTICATED can access schema'
        ELSE '❌ AUTHENTICATED cannot access schema'
    END as auth_access;

-- 7. CHECK TABLE PERMISSIONS
SELECT 
    'Table Access Check' as test,
    CASE 
        WHEN has_table_privilege('anon', 'users', 'SELECT') THEN '✅ Can read users table'
        ELSE '❌ Cannot read users table'
    END as users_access,
    CASE 
        WHEN has_table_privilege('anon', 'farmer_verifications', 'INSERT') THEN '✅ Can insert verifications'
        ELSE '❌ Cannot insert verifications'
    END as verification_access;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔧 SCHEMA PERMISSIONS RESTORED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Fixed:';
    RAISE NOTICE '✅ Schema access permissions restored';
    RAISE NOTICE '✅ Basic table permissions granted';
    RAISE NOTICE '✅ Sequence permissions restored';
    RAISE NOTICE '✅ Storage permissions ensured';
    RAISE NOTICE '✅ Bypass function accessible';
    RAISE NOTICE '';
    RAISE NOTICE 'Your app should now start properly!';
    RAISE NOTICE '===============================================';
END $$;