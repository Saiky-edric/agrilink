-- Fix RLS Policies for User Registration and Farmer Verification
-- Run this in Supabase SQL Editor

-- Fix User/Profile table policies first
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can create own profile" ON users;

-- Check if we're using users or profiles table
DO $$
DECLARE
    profiles_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO profiles_exists;
    
    IF profiles_exists THEN
        -- Fix policies for profiles table
        DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
        DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
        DROP POLICY IF EXISTS "Users can create own profile" ON profiles;
        
        CREATE POLICY "Users can view own profile" ON profiles 
        FOR SELECT USING (auth.uid() = user_id);
        
        CREATE POLICY "Users can update own profile" ON profiles 
        FOR UPDATE USING (auth.uid() = user_id);
        
        CREATE POLICY "Users can create own profile" ON profiles 
        FOR INSERT WITH CHECK (auth.uid() = user_id);
        
        RAISE NOTICE 'Fixed RLS policies for profiles table';
    ELSE
        -- Fix policies for users table
        CREATE POLICY "Users can view own profile" ON users 
        FOR SELECT USING (auth.uid() = id);
        
        CREATE POLICY "Users can update own profile" ON users 
        FOR UPDATE USING (auth.uid() = id);
        
        CREATE POLICY "Users can create own profile" ON users 
        FOR INSERT WITH CHECK (auth.uid() = id);
        
        RAISE NOTICE 'Fixed RLS policies for users table';
    END IF;
END $$;

-- Fix Farmer Verification RLS Policies
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- Create comprehensive farmer verification policies
CREATE POLICY "Farmers can view own verification" ON farmer_verifications 
FOR SELECT USING (auth.uid() = farmer_id);

CREATE POLICY "Farmers can insert own verification" ON farmer_verifications 
FOR INSERT WITH CHECK (auth.uid() = farmer_id);

CREATE POLICY "Farmers can update own verification" ON farmer_verifications 
FOR UPDATE USING (auth.uid() = farmer_id);

-- Admin policy that works with either table structure
DO $$
DECLARE
    profiles_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'profiles'
    ) INTO profiles_exists;
    
    IF profiles_exists THEN
        EXECUTE 'CREATE POLICY "Admins can manage verifications" ON farmer_verifications 
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM profiles 
                        WHERE user_id = auth.uid() AND role = ''admin''
                    )
                )';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can manage verifications" ON farmer_verifications 
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM users 
                        WHERE id = auth.uid() AND role = ''admin''
                    )
                )';
    END IF;
END $$;