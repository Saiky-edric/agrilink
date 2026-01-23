-- FIX: Farmer Verification RLS Policy Error
-- This fixes the 403 Unauthorized error when submitting farmer verifications

-- 1. First, check the current table structure
DO $$
DECLARE
    users_exists BOOLEAN;
    profiles_exists BOOLEAN;
BEGIN
    -- Check if users table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'users'
    ) INTO users_exists;
    
    -- Check if profiles table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO profiles_exists;
    
    RAISE NOTICE 'users table exists: %', users_exists;
    RAISE NOTICE 'profiles table exists: %', profiles_exists;
END $$;

-- 2. Drop existing RLS policies for farmer_verifications
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- 3. Create new RLS policies that work with the current table structure

-- First, try with profiles table (if it exists)
DO $$
DECLARE
    profiles_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO profiles_exists;
    
    IF profiles_exists THEN
        -- Use profiles table for RLS policies
        EXECUTE 'CREATE POLICY "Farmers can view own verification" ON farmer_verifications 
                FOR SELECT USING (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Farmers can insert own verification" ON farmer_verifications 
                FOR INSERT WITH CHECK (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Farmers can update own verification" ON farmer_verifications 
                FOR UPDATE USING (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Admins can manage verifications" ON farmer_verifications 
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM profiles 
                        WHERE user_id = auth.uid() AND role = ''admin''
                    )
                )';
        
        RAISE NOTICE 'Created RLS policies using profiles table';
    ELSE
        -- Fallback to users table
        EXECUTE 'CREATE POLICY "Farmers can view own verification" ON farmer_verifications 
                FOR SELECT USING (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Farmers can insert own verification" ON farmer_verifications 
                FOR INSERT WITH CHECK (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Farmers can update own verification" ON farmer_verifications 
                FOR UPDATE USING (auth.uid() = farmer_id)';
        
        EXECUTE 'CREATE POLICY "Admins can manage verifications" ON farmer_verifications 
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM users 
                        WHERE id = auth.uid() AND role = ''admin''
                    )
                )';
        
        RAISE NOTICE 'Created RLS policies using users table';
    END IF;
END $$;

-- 4. Ensure RLS is enabled
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- 5. Test the policies by checking current user permissions
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- 6. Also ensure that farmer_id column references the correct table
DO $$
DECLARE
    constraint_name TEXT;
    profiles_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO profiles_exists;
    
    -- Drop existing foreign key constraint
    SELECT constraint_name INTO constraint_name
    FROM information_schema.table_constraints 
    WHERE table_name = 'farmer_verifications' 
    AND constraint_type = 'FOREIGN KEY'
    AND constraint_name LIKE '%farmer_id%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE farmer_verifications DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped existing foreign key constraint: %', constraint_name;
    END IF;
    
    -- Create new foreign key constraint based on available table
    IF profiles_exists THEN
        ALTER TABLE farmer_verifications 
        ADD CONSTRAINT farmer_verifications_farmer_id_fkey 
        FOREIGN KEY (farmer_id) REFERENCES profiles(user_id) ON DELETE CASCADE;
        RAISE NOTICE 'Created foreign key constraint referencing profiles.user_id';
    ELSE
        ALTER TABLE farmer_verifications 
        ADD CONSTRAINT farmer_verifications_farmer_id_fkey 
        FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Created foreign key constraint referencing users.id';
    END IF;
END $$;

-- 7. Grant necessary permissions
GRANT ALL ON farmer_verifications TO authenticated;
GRANT USAGE ON SEQUENCE farmer_verifications_id_seq TO authenticated;

-- 8. Final verification - list all policies
RAISE NOTICE 'Final policy verification:';
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'farmer_verifications';