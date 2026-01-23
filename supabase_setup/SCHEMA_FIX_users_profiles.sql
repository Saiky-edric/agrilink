-- =====================================================
-- AGRILINK SCHEMA FIX: Consolidate Users and Profiles Tables
-- =====================================================
-- This script fixes the dual user table issue by:
-- 1. Migrating all data from profiles table to users table
-- 2. Updating foreign key relationships
-- 3. Removing the redundant profiles table
-- =====================================================

-- Step 1: Check current data state
SELECT 'Current users table count:' as info, COUNT(*) as count FROM public.users
UNION ALL
SELECT 'Current profiles table count:' as info, COUNT(*) as count FROM public.profiles;

-- Step 2: Ensure users table has all needed columns
-- Add any missing columns from profiles table to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS user_id uuid;

-- Step 3: Migrate data from profiles to users table
-- Insert profiles data that doesn't exist in users table
INSERT INTO public.users (
    id, email, full_name, phone_number, role, 
    municipality, barangay, street, 
    created_at, updated_at, is_active
)
SELECT 
    p.user_id,
    COALESCE(p.email, au.email),
    COALESCE(p.full_name, au.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(p.phone_number, ''),
    COALESCE(p.role::text, 'buyer')::user_role,
    p.municipality,
    p.barangay,
    p.street,
    COALESCE(p.created_at, NOW()),
    p.updated_at,
    COALESCE(p.is_active, true)
FROM public.profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
LEFT JOIN public.users u ON p.user_id = u.id
WHERE u.id IS NULL; -- Only insert if not already in users table

-- Step 4: Update existing users with profile data (if profiles has newer info)
UPDATE public.users u
SET 
    email = COALESCE(p.email, u.email),
    full_name = COALESCE(p.full_name, u.full_name),
    municipality = COALESCE(p.municipality, u.municipality),
    barangay = COALESCE(p.barangay, u.barangay),
    street = COALESCE(p.street, u.street),
    updated_at = GREATEST(COALESCE(p.updated_at, u.updated_at), u.updated_at),
    is_active = COALESCE(p.is_active, u.is_active)
FROM public.profiles p
WHERE u.id = p.user_id
  AND (
    p.municipality IS NOT NULL OR 
    p.barangay IS NOT NULL OR 
    p.street IS NOT NULL OR
    p.updated_at > u.updated_at
  );

-- Step 5: Ensure all users have required fields
UPDATE public.users 
SET 
    phone_number = COALESCE(phone_number, ''),
    full_name = COALESCE(full_name, 'User'),
    role = COALESCE(role, 'buyer'::user_role),
    is_active = COALESCE(is_active, true),
    created_at = COALESCE(created_at, NOW())
WHERE phone_number IS NULL OR full_name IS NULL OR role IS NULL;

-- Step 6: Update all foreign keys to reference users table instead of profiles
-- Note: This assumes your foreign keys currently point to users table already
-- If any point to profiles table, they would need to be updated here

-- Step 7: Verify data integrity
SELECT 
    'Users after migration:' as info, 
    COUNT(*) as count,
    COUNT(CASE WHEN municipality IS NOT NULL AND barangay IS NOT NULL AND street IS NOT NULL THEN 1 END) as with_complete_address,
    COUNT(CASE WHEN role = 'farmer' THEN 1 END) as farmers,
    COUNT(CASE WHEN role = 'buyer' THEN 1 END) as buyers,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admins
FROM public.users;

-- Step 8: Check for orphaned auth users (users in auth.users but not in public.users)
SELECT 
    'Auth users without profiles:' as info,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL;

-- Step 9: Create missing user records for auth users without profiles
INSERT INTO public.users (
    id, email, full_name, phone_number, role, 
    created_at, is_active
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(au.raw_user_meta_data->>'phone_number', ''),
    COALESCE((au.raw_user_meta_data->>'role')::user_role, 'buyer'::user_role),
    au.created_at,
    true
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL;

-- Step 10: Remove the profiles table (after confirming migration is successful)
-- UNCOMMENT THESE LINES AFTER VERIFYING THE MIGRATION:

-- DROP TABLE IF EXISTS public.profiles CASCADE;

-- Step 11: Final verification
SELECT 
    'Final verification:' as info,
    (SELECT COUNT(*) FROM public.users) as users_count,
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM public.users) = (SELECT COUNT(*) FROM auth.users) 
        THEN 'SUCCESS: Counts match'
        ELSE 'WARNING: Counts do not match'
    END as status;

-- Display any users missing required data
SELECT 
    'Users missing data:' as issue,
    id,
    email,
    full_name,
    CASE 
        WHEN full_name IS NULL OR full_name = '' THEN 'Missing name'
        WHEN email IS NULL OR email = '' THEN 'Missing email'  
        WHEN role IS NULL THEN 'Missing role'
        ELSE 'OK'
    END as problem
FROM public.users
WHERE full_name IS NULL OR full_name = '' OR email IS NULL OR email = '' OR role IS NULL;

COMMENT ON TABLE public.users IS 'Primary user table - consolidated from users and profiles tables';