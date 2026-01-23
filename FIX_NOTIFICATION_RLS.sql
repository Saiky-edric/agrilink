-- ============================================================
-- FIX: Notification RLS Policy Issue
-- Error: "new row violates row-level security policy for table notifications"
-- This prevents admins from sending notifications to farmers
-- ============================================================

-- STEP 1: Check current RLS policies on notifications table
SELECT 
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'notifications'
ORDER BY cmd, policyname;

-- STEP 2: Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'notifications';

-- ============================================================
-- SOLUTION: Add INSERT policy for notifications
-- ============================================================

-- Drop existing restrictive policies if they exist (optional)
-- Uncomment if you want to start fresh
/*
DROP POLICY IF EXISTS "Users can insert notifications to themselves" ON public.notifications;
DROP POLICY IF EXISTS "Users can only insert own notifications" ON public.notifications;
*/

-- POLICY 1: Allow authenticated users to insert notifications to ANY user
-- This is needed for admin -> farmer notifications
CREATE POLICY "Authenticated users can send notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Allow any authenticated user to send notifications

-- POLICY 2: Allow users to view their own notifications
CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- POLICY 3: Allow users to update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- POLICY 4: Allow users to delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON public.notifications
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- ALTERNATIVE SOLUTION: Service Role Function (More Secure)
-- ============================================================

-- If you want more control, create a function to send notifications
-- This function runs with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION public.send_notification(
    target_user_id UUID,
    notification_title VARCHAR,
    notification_message TEXT,
    notification_type VARCHAR,
    notification_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Bypasses RLS
SET search_path = public
AS $$
DECLARE
    new_notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        title,
        message,
        type,
        data,
        is_read,
        created_at
    ) VALUES (
        target_user_id,
        notification_title,
        notification_message,
        notification_type,
        notification_data,
        false,
        NOW()
    )
    RETURNING id INTO new_notification_id;
    
    RETURN new_notification_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.send_notification(UUID, VARCHAR, TEXT, VARCHAR, JSONB) TO authenticated;

COMMENT ON FUNCTION public.send_notification IS 
'Send notification to any user. Bypasses RLS policies. Used by NotificationService.';

-- ============================================================
-- STEP 3: Test the fix
-- ============================================================

-- Test 1: Try inserting a notification (replace UUIDs with actual values)
/*
INSERT INTO public.notifications (user_id, title, message, type)
VALUES (
    'farmer-user-id-here'::UUID,
    'Test Notification',
    'This is a test',
    'test'
);
-- Should succeed now
*/

-- Test 2: Use the function
/*
SELECT public.send_notification(
    'farmer-user-id-here'::UUID,
    'Test via Function',
    'This uses the bypass function',
    'test',
    NULL
);
-- Should return notification ID
*/

-- ============================================================
-- STEP 4: Verify notifications are working
-- ============================================================

-- Check recent notifications
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 10;
