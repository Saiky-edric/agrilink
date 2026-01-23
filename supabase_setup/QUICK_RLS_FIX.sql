-- =============================================
-- QUICK FIX: Farmer Verification RLS Policy
-- =============================================
-- This fixes the 403 Unauthorized error when submitting farmer verification
-- Run this in your Supabase SQL Editor

-- 1. Drop existing problematic policies
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- 2. Ensure RLS is enabled
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- 3. Create new working policies

-- Policy for farmers to view their own verifications
CREATE POLICY "Farmers can view own verification" ON farmer_verifications
    FOR SELECT
    USING (auth.uid() = farmer_id);

-- Policy for farmers to insert their own verifications (THIS IS THE KEY FIX)
CREATE POLICY "Farmers can insert own verification" ON farmer_verifications
    FOR INSERT
    WITH CHECK (
        auth.uid() = farmer_id
        AND auth.uid() IS NOT NULL
    );

-- Policy for farmers to update their own verifications
CREATE POLICY "Farmers can update own verification" ON farmer_verifications
    FOR UPDATE
    USING (auth.uid() = farmer_id)
    WITH CHECK (auth.uid() = farmer_id);

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

-- 4. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 5. Verify the fix
SELECT 
    policyname,
    cmd as command,
    permissive
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✅ FARMER VERIFICATION RLS FIX COMPLETED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'You can now submit farmer verifications!';
    RAISE NOTICE 'Go back to your app and try the verification again.';
    RAISE NOTICE '===============================================';
END $$;