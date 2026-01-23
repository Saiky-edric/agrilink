-- ============================================================
-- SCHEMA DISCOVERY AND CORRECTED MIGRATION
-- Let's check actual table structures and migrate properly
-- ============================================================

-- STEP 1: Check actual column structure of both tables
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'profiles') 
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- STEP 2: Show profiles table structure specifically
\d profiles

-- STEP 3: Show users table structure specifically  
\d users

-- STEP 4: Get sample data to understand the structure
SELECT 'USERS TABLE SAMPLE:' as info;
SELECT * FROM users LIMIT 2;

SELECT 'PROFILES TABLE SAMPLE:' as info;
SELECT * FROM profiles LIMIT 2;

-- STEP 5: Corrected migration based on ACTUAL schema
-- This will be updated after we see the real schema

DO $$
DECLARE
    users_columns TEXT[];
    profiles_columns TEXT[];
    migration_sql TEXT;
    migrated_count INTEGER;
BEGIN
    -- Get actual column names from users table
    SELECT array_agg(column_name ORDER BY ordinal_position) 
    INTO users_columns
    FROM information_schema.columns 
    WHERE table_name = 'users' AND table_schema = 'public';
    
    -- Get actual column names from profiles table  
    SELECT array_agg(column_name ORDER BY ordinal_position)
    INTO profiles_columns  
    FROM information_schema.columns
    WHERE table_name = 'profiles' AND table_schema = 'public';
    
    RAISE NOTICE 'Users table columns: %', users_columns;
    RAISE NOTICE 'Profiles table columns: %', profiles_columns;
    
    -- Now we'll create the correct INSERT based on actual schema
    -- (This part will be completed after we see the schema)
END $$;