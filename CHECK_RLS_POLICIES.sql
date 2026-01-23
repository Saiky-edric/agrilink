-- ============================================================
-- CHECK RLS POLICIES ON USERS TABLE
-- This helps identify if RLS policies are blocking subscription updates
-- ============================================================

-- Check all RLS policies on users table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users'
ORDER BY cmd, policyname;

-- Check if RLS is enabled on users table
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'users';

-- ============================================================
-- RECOMMENDED RLS POLICIES FOR USERS TABLE
-- ============================================================

-- If you find that admins cannot update users, add this policy:
-- (Uncomment to create)

/*
-- Policy: Allow admins to update any user
CREATE POLICY "Admins can update any user subscription"
ON public.users
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);
*/

/*
-- Policy: Allow users to update their own record
CREATE POLICY "Users can update own subscription"
ON public.users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
*/

-- ============================================================
-- TEST UPDATE PERMISSION
-- ============================================================

-- This query simulates what the app is trying to do
-- If this fails, RLS is blocking the update
/*
UPDATE public.users
SET subscription_tier = 'premium'
WHERE id = 'test-user-uuid'::UUID;
-- If you get "new row violates row-level security policy" - RLS is the problem
*/
