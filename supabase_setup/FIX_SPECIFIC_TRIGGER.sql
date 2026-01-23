-- =============================================
-- FIX: Remove the Problematic Verification Trigger
-- =============================================
-- Target the exact trigger causing the data column error

-- 1. DROP BOTH problematic triggers (INSERT and UPDATE)
DROP TRIGGER IF EXISTS verification_notification_trigger ON farmer_verifications;

-- 2. Also drop any other notification-related triggers
DROP TRIGGER IF EXISTS farmer_verification_notification_trigger ON farmer_verifications;
DROP TRIGGER IF EXISTS handle_verification_notifications_trigger ON farmer_verifications;

-- 3. DROP the trigger function (it's trying to use data column)
DROP FUNCTION IF EXISTS handle_verification_notifications() CASCADE;
DROP FUNCTION IF EXISTS handle_farmer_verification_notifications() CASCADE;

-- 3. Keep the update trigger (it's harmless)
-- update_farmer_verifications_updated_at is fine to keep

-- 4. Verify the problematic trigger is gone
SELECT 
    'Remaining Triggers:' as info,
    trigger_name,
    event_manipulation as event
FROM information_schema.triggers 
WHERE event_object_table = 'farmer_verifications'
ORDER BY trigger_name;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔧 PROBLEMATIC TRIGGER REMOVED!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Removed: ALL verification_notification_trigger(s)';
    RAISE NOTICE 'These triggers were trying to insert into notifications';
    RAISE NOTICE 'with a data column that does not exist.';
    RAISE NOTICE '';
    RAISE NOTICE 'Try farmer verification submission now!';
    RAISE NOTICE '===============================================';
END $$;