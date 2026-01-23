-- FIX: Enable RLS on profiles table and create policies
-- This ensures users can only read/update their own profile

-- 1. Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 2. Create policy for users to read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles 
FOR SELECT USING (auth.uid() = user_id);

-- 3. Create policy for users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles 
FOR UPDATE USING (auth.uid() = user_id);

-- 4. Create policy for users to insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Verify policies are created
SELECT policyname, tablename FROM pg_policies WHERE tablename = 'profiles';

-- Expected output:
-- "Users can view own profile" on profiles
-- "Users can update own profile" on profiles  
-- "Users can insert own profile" on profiles
