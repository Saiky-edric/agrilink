-- ============================================================
-- CRITICAL FIX: Database Foreign Key Inconsistencies
-- This script fixes ALL foreign key references to use profiles table
-- ============================================================

-- ⚠️ BACKUP YOUR DATABASE BEFORE RUNNING THIS SCRIPT ⚠️
-- This script makes significant structural changes

-- ============================================================
-- PART 1: ANALYSIS - Check current foreign key constraints
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'ANALYZING CURRENT FOREIGN KEY CONSTRAINTS';
    RAISE NOTICE '============================================================';
END $$;

-- List all foreign keys referencing users table
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (ccu.table_name = 'users' OR ccu.table_name = 'profiles')
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ============================================================
-- PART 2: DATA MIGRATION - Ensure profiles table has all data
-- ============================================================

DO $$
DECLARE
    users_count INTEGER;
    profiles_count INTEGER;
    migrated_count INTEGER;
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'MIGRATING DATA FROM USERS TO PROFILES';
    RAISE NOTICE '============================================================';
    
    -- Get current counts
    SELECT COUNT(*) INTO users_count FROM users;
    SELECT COUNT(*) INTO profiles_count FROM profiles;
    
    RAISE NOTICE 'Current users table records: %', users_count;
    RAISE NOTICE 'Current profiles table records: %', profiles_count;
    
    -- Migrate missing users to profiles
    INSERT INTO profiles (
        user_id, email, full_name, role, municipality, barangay, street, 
        is_active, created_at, updated_at
    )
    SELECT 
        u.id,
        u.email,
        u.full_name,
        u.role,
        u.municipality,
        u.barangay,
        u.street,
        u.is_active,
        u.created_at,
        u.updated_at
    FROM users u
    WHERE u.id NOT IN (SELECT user_id FROM profiles)
    ON CONFLICT (user_id) DO NOTHING;
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    RAISE NOTICE 'Migrated % additional records to profiles', migrated_count;
    
    -- Verify migration
    SELECT COUNT(*) INTO profiles_count FROM profiles;
    RAISE NOTICE 'Profiles table now has % records', profiles_count;
END $$;

-- ============================================================
-- PART 3: CREATE TEMPORARY UPDATE MAPPING
-- ============================================================

-- Create temporary table to map users.id to profiles.user_id
CREATE TEMP TABLE user_id_mapping AS
SELECT 
    u.id as old_user_id,
    p.user_id as new_user_id
FROM users u
JOIN profiles p ON u.id = p.user_id;

-- ============================================================
-- PART 4: DROP EXISTING FOREIGN KEY CONSTRAINTS
-- ============================================================

DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'DROPPING FOREIGN KEY CONSTRAINTS REFERENCING USERS TABLE';
    RAISE NOTICE '============================================================';
    
    -- Drop all foreign key constraints that reference users table
    FOR constraint_record IN
        SELECT 
            tc.table_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc 
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_name = 'users'
            AND tc.table_schema = 'public'
    LOOP
        RAISE NOTICE 'Dropping constraint: %.%', constraint_record.table_name, constraint_record.constraint_name;
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', 
                      constraint_record.table_name, 
                      constraint_record.constraint_name);
    END LOOP;
END $$;

-- ============================================================
-- PART 5: UPDATE FOREIGN KEY COLUMNS TO REFERENCE PROFILES
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'UPDATING FOREIGN KEY COLUMNS TO REFERENCE PROFILES';
    RAISE NOTICE '============================================================';
END $$;

-- Update cart table
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE 'Updating cart table...';
    UPDATE cart 
    SET user_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE cart.user_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % cart records', updated_count;
END $$;

-- Update conversations table
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE 'Updating conversations table...';
    
    -- Update buyer_id
    UPDATE conversations 
    SET buyer_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE conversations.buyer_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % conversation buyer records', updated_count;
    
    -- Update farmer_id
    UPDATE conversations 
    SET farmer_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE conversations.farmer_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % conversation farmer records', updated_count;
END $$;

-- Update farmer_verifications table
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE 'Updating farmer_verifications table...';
    
    -- Update farmer_id
    UPDATE farmer_verifications 
    SET farmer_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE farmer_verifications.farmer_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % farmer_verifications farmer records', updated_count;
    
    -- Update reviewed_by_admin_id
    UPDATE farmer_verifications 
    SET reviewed_by_admin_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE farmer_verifications.reviewed_by_admin_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % farmer_verifications admin records', updated_count;
END $$;

-- Update all other tables that reference users
DO $$
DECLARE
    table_name TEXT;
    column_name TEXT;
    updated_count INTEGER;
    tables_to_update TEXT[][] := ARRAY[
        ['feedback', 'user_id'],
        ['messages', 'sender_id'],
        ['notifications', 'user_id'],
        ['payment_methods', 'user_id'],
        ['product_reviews', 'user_id'],
        ['products', 'farmer_id'],
        ['reports', 'reporter_id'],
        ['user_addresses', 'user_id'],
        ['user_favorites', 'user_id'],
        ['user_settings', 'user_id']
    ];
    table_info TEXT[];
BEGIN
    FOREACH table_info SLICE 1 IN ARRAY tables_to_update
    LOOP
        table_name := table_info[1];
        column_name := table_info[2];
        
        RAISE NOTICE 'Updating %.%...', table_name, column_name;
        
        EXECUTE format('
            UPDATE %I 
            SET %I = m.new_user_id 
            FROM user_id_mapping m 
            WHERE %I.%I = m.old_user_id', 
            table_name, column_name, table_name, column_name);
        
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE 'Updated % % records', updated_count, table_name;
    END LOOP;
END $$;

-- Update orders table (has multiple user columns)
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE 'Updating orders table...';
    
    -- Update buyer_id
    UPDATE orders 
    SET buyer_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE orders.buyer_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % orders buyer records', updated_count;
    
    -- Update farmer_id
    UPDATE orders 
    SET farmer_id = m.new_user_id 
    FROM user_id_mapping m 
    WHERE orders.farmer_id = m.old_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % orders farmer records', updated_count;
END $$;

-- ============================================================
-- PART 6: RECREATE FOREIGN KEY CONSTRAINTS TO PROFILES
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'CREATING NEW FOREIGN KEY CONSTRAINTS TO PROFILES TABLE';
    RAISE NOTICE '============================================================';
END $$;

-- Recreate foreign key constraints pointing to profiles.user_id
ALTER TABLE cart ADD CONSTRAINT cart_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE conversations ADD CONSTRAINT conversations_buyer_id_fkey 
    FOREIGN KEY (buyer_id) REFERENCES profiles(user_id);
ALTER TABLE conversations ADD CONSTRAINT conversations_farmer_id_fkey 
    FOREIGN KEY (farmer_id) REFERENCES profiles(user_id);

ALTER TABLE farmer_verifications ADD CONSTRAINT farmer_verifications_farmer_id_fkey 
    FOREIGN KEY (farmer_id) REFERENCES profiles(user_id);
ALTER TABLE farmer_verifications ADD CONSTRAINT farmer_verifications_reviewed_by_admin_id_fkey 
    FOREIGN KEY (reviewed_by_admin_id) REFERENCES profiles(user_id);

ALTER TABLE feedback ADD CONSTRAINT feedback_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE messages ADD CONSTRAINT messages_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES profiles(user_id);

ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE orders ADD CONSTRAINT orders_buyer_id_fkey 
    FOREIGN KEY (buyer_id) REFERENCES profiles(user_id);
ALTER TABLE orders ADD CONSTRAINT orders_farmer_id_fkey 
    FOREIGN KEY (farmer_id) REFERENCES profiles(user_id);

ALTER TABLE payment_methods ADD CONSTRAINT payment_methods_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE product_reviews ADD CONSTRAINT product_reviews_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE products ADD CONSTRAINT products_farmer_id_fkey 
    FOREIGN KEY (farmer_id) REFERENCES profiles(user_id);

ALTER TABLE reports ADD CONSTRAINT reports_reporter_id_fkey 
    FOREIGN KEY (reporter_id) REFERENCES profiles(user_id);

ALTER TABLE user_addresses ADD CONSTRAINT user_addresses_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE user_favorites ADD CONSTRAINT user_favorites_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

ALTER TABLE user_settings ADD CONSTRAINT user_settings_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES profiles(user_id);

-- ============================================================
-- PART 7: VERIFICATION AND CLEANUP
-- ============================================================

DO $$
DECLARE
    constraint_count INTEGER;
    users_count INTEGER;
    profiles_count INTEGER;
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'VERIFICATION AND CLEANUP';
    RAISE NOTICE '============================================================';
    
    -- Count new foreign key constraints
    SELECT COUNT(*) INTO constraint_count
    FROM information_schema.table_constraints AS tc 
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND ccu.table_name = 'profiles'
        AND tc.table_schema = 'public';
    
    RAISE NOTICE 'Created % foreign key constraints pointing to profiles', constraint_count;
    
    -- Final record counts
    SELECT COUNT(*) INTO users_count FROM users;
    SELECT COUNT(*) INTO profiles_count FROM profiles;
    
    RAISE NOTICE 'Users table records: %', users_count;
    RAISE NOTICE 'Profiles table records: %', profiles_count;
    
    IF users_count = profiles_count THEN
        RAISE NOTICE '✅ Data migration successful - record counts match';
    ELSE
        RAISE NOTICE '⚠️  Warning - record counts do not match';
    END IF;
END $$;

-- ============================================================
-- PART 8: OPTIONAL - DROP USERS TABLE (UNCOMMENT WHEN READY)
-- ============================================================

/*
-- WARNING: This will permanently delete the users table
-- Only uncomment after thorough testing confirms everything works

-- Drop the users table
DROP TABLE IF EXISTS users CASCADE;

-- Verify users table is dropped
SELECT 'users table dropped successfully' as status
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'users'
);
*/

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'FOREIGN KEY MIGRATION COMPLETED SUCCESSFULLY';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'All foreign key references now point to profiles.user_id';
    RAISE NOTICE 'Database schema is now consistent with application code';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test application thoroughly';
    RAISE NOTICE '2. Verify all features work correctly';
    RAISE NOTICE '3. Monitor for any data integrity issues';
    RAISE NOTICE '4. After testing, uncomment Part 8 to drop users table';
    RAISE NOTICE '============================================================';
END $$;