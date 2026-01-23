-- ============================================================
-- CREATE RLS BYPASS FUNCTION
-- This creates a function that admins can use to activate premium
-- It runs with SECURITY DEFINER which bypasses RLS policies
-- ============================================================

-- Create the function
CREATE OR REPLACE FUNCTION public.admin_activate_premium(
    target_user_id UUID,
    start_date TIMESTAMPTZ,
    expire_date TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- This makes it run with creator's permissions, bypassing RLS
SET search_path = public
AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    -- Update users table with subscription info
    UPDATE public.users
    SET 
        subscription_tier = 'premium',
        subscription_started_at = start_date,
        subscription_expires_at = expire_date,
        updated_at = NOW()
    WHERE id = target_user_id;
    
    -- Check if update succeeded
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows = 0 THEN
        RAISE EXCEPTION 'User % not found or update failed', target_user_id;
    END IF;
    
    RAISE NOTICE 'Successfully activated premium for user %', target_user_id;
    RETURN TRUE;
END;
$$;

-- Grant permission to authenticated users (so admins can call it)
GRANT EXECUTE ON FUNCTION public.admin_activate_premium(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION public.admin_activate_premium IS 
'Admin function to activate premium subscription for a user. Bypasses RLS policies. Used as fallback when direct updates fail.';

-- Test the function (uncomment and replace UUID to test)
-- SELECT public.admin_activate_premium(
--     'your-user-uuid-here'::UUID,
--     NOW(),
--     NOW() + INTERVAL '30 days'
-- );

-- Verify it worked
-- SELECT id, email, subscription_tier, subscription_expires_at 
-- FROM public.users 
-- WHERE id = 'your-user-uuid-here';
