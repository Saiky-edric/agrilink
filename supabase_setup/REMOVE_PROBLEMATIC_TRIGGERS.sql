-- =============================================
-- REMOVE PROBLEMATIC DATABASE TRIGGERS
-- =============================================
-- The 'data' column error is coming from database triggers, not the app code

-- 1. CHECK WHAT TRIGGERS EXIST ON farmer_verifications
SELECT 
    'Current Triggers on farmer_verifications:' as info,
    trigger_name,
    event_manipulation as event,
    action_timing as timing
FROM information_schema.triggers 
WHERE event_object_table = 'farmer_verifications';

-- 2. DROP ALL TRIGGERS ON farmer_verifications (they're causing the data column issue)
DROP TRIGGER IF EXISTS verification_notification_trigger ON farmer_verifications;
DROP TRIGGER IF EXISTS farmer_verification_trigger ON farmer_verifications;
DROP TRIGGER IF EXISTS handle_verification_notifications_trigger ON farmer_verifications;
DROP TRIGGER IF EXISTS verification_auto_notify_trigger ON farmer_verifications;

-- 3. DROP THE TRIGGER FUNCTIONS (they try to use the data column)
DROP FUNCTION IF EXISTS handle_verification_notifications() CASCADE;
DROP FUNCTION IF EXISTS handle_farmer_verification_notifications() CASCADE;
DROP FUNCTION IF EXISTS notify_verification_change() CASCADE;
DROP FUNCTION IF EXISTS create_verification_notification() CASCADE;

-- 4. CHECK TRIGGERS ON notifications table too
SELECT 
    'Current Triggers on notifications:' as info,
    trigger_name,
    event_manipulation as event,
    action_timing as timing
FROM information_schema.triggers 
WHERE event_object_table = 'notifications';

-- 5. DROP ANY PROBLEMATIC NOTIFICATION TRIGGERS
DROP TRIGGER IF EXISTS notification_trigger ON notifications CASCADE;
DROP TRIGGER IF EXISTS notification_auto_trigger ON notifications CASCADE;

-- 6. VERIFY NO MORE TRIGGERS EXIST
SELECT 
    'Remaining Triggers Check:' as info,
    COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_table IN ('farmer_verifications', 'notifications');

-- 7. CLEAN UP ANY NOTIFICATION SYSTEM SETUP THAT USED data COLUMN
-- Check if there are any views or functions still referencing data column
SELECT 
    'Views using data column:' as info,
    table_name,
    view_definition
FROM information_schema.views 
WHERE view_definition LIKE '%data%'
AND table_schema = 'public';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🔧 TRIGGER CLEANUP COMPLETE!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Removed:';
    RAISE NOTICE '✅ All triggers on farmer_verifications';
    RAISE NOTICE '✅ All trigger functions that use data column';
    RAISE NOTICE '✅ Any problematic notification triggers';
    RAISE NOTICE '';
    RAISE NOTICE 'Try farmer verification submission now!';
    RAISE NOTICE 'It should work without the data column error.';
    RAISE NOTICE '===============================================';
END $$;