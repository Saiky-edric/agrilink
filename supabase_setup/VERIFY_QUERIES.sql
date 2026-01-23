-- ============================================================
-- AGRILINK USER DATA VERIFICATION QUERIES
-- Run these in Supabase SQL Editor to diagnose issues
-- ============================================================

-- 1. CHECK TABLE STRUCTURE
-- Run this to see all columns in the users table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Expected output should include:
-- id, email, full_name, phone_number, role, municipality, barangay, street, is_active, created_at, updated_at

-- ============================================================

-- 2. CHECK RLS POLICIES
-- Run this to verify RLS policies are set up correctly
SELECT 
    schemaname,
    tablename, 
    policyname, 
    permissive, 
    roles, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Expected output:
-- Policy "Users can view own profile" for SELECT
-- Policy "Users can update own profile" for UPDATE

-- ============================================================

-- 3. COUNT USERS
-- See how many users exist
SELECT COUNT(*) as total_users FROM users;

-- ============================================================

-- 4. VIEW ALL USER DATA (First 5)
-- See what data is stored
SELECT 
    id, 
    email, 
    full_name, 
    phone_number, 
    role, 
    municipality,
    barangay,
    street,
    is_active,
    created_at
FROM users 
LIMIT 5;

-- ============================================================

-- 5. VERIFY ENUM TYPE
-- Check if role column uses the correct enum
SELECT data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'role';

-- Expected: user_role (custom type)

-- ============================================================

-- 6. CHECK ENUM VALUES
-- See what values are accepted for role
SELECT enum_range(NULL::user_role);

-- Expected: {buyer,farmer,admin}

-- ============================================================

-- 7. FIND USERS BY ROLE
-- See how many of each role exist
SELECT role, COUNT(*) as count 
FROM users 
GROUP BY role;

-- Expected breakdown like:
-- buyer: 5
-- farmer: 2
-- admin: 1

-- ============================================================

-- 8. CHECK FOR NULL VALUES
-- Find any users with missing required data
SELECT 
    id,
    email,
    full_name,
    phone_number,
    role
FROM users
WHERE 
    email IS NULL 
    OR full_name IS NULL 
    OR phone_number IS NULL 
    OR role IS NULL;

-- Should return empty result (no NULL values in required fields)

-- ============================================================

-- 9. VERIFY is_active COLUMN
-- Check suspension feature
SELECT 
    id,
    email,
    full_name,
    is_active
FROM users
WHERE is_active = FALSE;

-- Should return suspended users (if any)

-- ============================================================

-- 10. TEST RLS POLICY
-- This checks if current user can access their profile
-- (Only works when authenticated as a user)
SELECT 
    id, 
    email, 
    full_name, 
    role 
FROM users 
WHERE id = auth.uid();

-- Expected: Returns current user's data if RLS is working

-- ============================================================
