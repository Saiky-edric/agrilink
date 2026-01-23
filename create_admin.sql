-- ============================================
-- Agrilink Admin Account Creation Script
-- ============================================
-- Run this script in your Supabase SQL Editor
-- IMPORTANT: Create the auth user first through Supabase Dashboard!

-- Step 1: Create auth user through Supabase Dashboard first
-- Go to Authentication > Users > Add User
-- Email: admin@agrilink.ph
-- Password: [Your secure password]
-- Confirm Email: YES

-- Step 2: Run this SQL script
-- Replace the email below with your admin email

DO $$
DECLARE
    admin_auth_id UUID;
    admin_email TEXT := 'admin@agrilink.ph'; -- Change this to your admin email
BEGIN
    -- Get the auth user ID
    SELECT id INTO admin_auth_id 
    FROM auth.users 
    WHERE email = admin_email;
    
    -- Check if auth user exists
    IF admin_auth_id IS NULL THEN
        RAISE EXCEPTION 'Auth user with email % not found. Please create the auth user first in Supabase Dashboard.', admin_email;
    END IF;
    
    -- Confirm the auth user email
    UPDATE auth.users 
    SET email_confirmed_at = NOW() 
    WHERE id = admin_auth_id;
    
    -- Insert or update the user profile with admin role
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone_number,
        role,
        municipality,
        barangay,
        street,
        created_at,
        updated_at
    ) VALUES (
        admin_auth_id,
        admin_email,
        'System Administrator',
        '+63917123456789',
        'admin',
        'Prosperidad',
        'Poblacion', 
        'Admin Office Building',
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'admin',
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        municipality = EXCLUDED.municipality,
        barangay = EXCLUDED.barangay,
        street = EXCLUDED.street,
        updated_at = NOW();
    
    -- Output success message
    RAISE NOTICE 'Admin account created successfully for %', admin_email;
    RAISE NOTICE 'User ID: %', admin_auth_id;
    RAISE NOTICE 'Role: admin';
    RAISE NOTICE 'You can now login with admin credentials!';
    
END $$;

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify the admin account was created correctly

SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.municipality,
    u.created_at,
    au.email_confirmed_at IS NOT NULL as email_confirmed
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE u.role = 'admin'
ORDER BY u.created_at DESC;

-- ============================================
-- Additional Admin Functions
-- ============================================

-- Function to promote a user to admin
CREATE OR REPLACE FUNCTION promote_to_admin(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Find the user
    SELECT id INTO target_user_id 
    FROM public.users 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN 'User not found';
    END IF;
    
    -- Update role to admin
    UPDATE public.users 
    SET 
        role = 'admin',
        updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN 'User promoted to admin successfully';
END;
$$ LANGUAGE plpgsql;

-- Function to create multiple admins
CREATE OR REPLACE FUNCTION create_admin_accounts()
RETURNS TEXT AS $$
BEGIN
    -- Main admin
    PERFORM promote_to_admin('admin@agrilink.ph');
    
    -- Regional admin (create auth user first)
    -- PERFORM promote_to_admin('admin.region@agrilink.ph');
    
    -- Support admin (create auth user first)  
    -- PERFORM promote_to_admin('support@agrilink.ph');
    
    RETURN 'Admin accounts setup completed';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Usage Examples
-- ============================================

-- Promote existing user to admin
-- SELECT promote_to_admin('existing.user@example.com');

-- Check all admin users
-- SELECT email, full_name, role, created_at 
-- FROM users 
-- WHERE role = 'admin';

-- ============================================
-- Security Notes
-- ============================================
-- 1. Always use strong passwords for admin accounts
-- 2. Enable 2FA if available in your Supabase setup
-- 3. Regularly audit admin accounts
-- 4. Use unique admin emails (not personal emails)
-- 5. Monitor admin activities through logs