-- =============================================
-- ALTERNATIVE RLS FIX: More Permissive Approach
-- =============================================
-- This creates more permissive policies if the previous fix didn't work

-- 1. Start fresh by removing all existing policies
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- 2. Disable RLS temporarily to test if that's the issue
ALTER TABLE farmer_verifications DISABLE ROW LEVEL SECURITY;

-- Test your app now - if it works, the issue was RLS policies
-- Then continue with the rest of this script

-- 3. Re-enable RLS with more permissive policies
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- 4. Create very permissive policies first
CREATE POLICY "Allow authenticated users to select" ON farmer_verifications
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated farmers to insert" ON farmer_verifications
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.role() = 'authenticated'
    );

CREATE POLICY "Allow authenticated users to update" ON farmer_verifications
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = farmer_id)
    WITH CHECK (auth.uid() = farmer_id);

-- 5. Grant all necessary permissions
GRANT ALL ON farmer_verifications TO authenticated;
GRANT ALL ON farmer_verifications TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 6. If the above works, we can tighten the policies later
-- CREATE POLICY "Restrict to farmers only" ON farmer_verifications
--     FOR INSERT
--     TO authenticated
--     WITH CHECK (
--         EXISTS (
--             SELECT 1 FROM users 
--             WHERE id = auth.uid() 
--             AND role = 'farmer'
--         )
--     );

-- 7. Check if policies are working
SELECT 
    'RLS Status: ' || CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as rls_status
FROM pg_tables 
WHERE tablename = 'farmer_verifications';

-- 8. List all policies
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✅ ALTERNATIVE RLS FIX APPLIED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Test your verification submission now.';
    RAISE NOTICE 'If it works, we can tighten security later.';
    RAISE NOTICE '===============================================';
END $$;