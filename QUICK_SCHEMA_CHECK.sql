-- Quick schema discovery - run this first
SELECT 
    'PROFILES TABLE COLUMNS' as table_info,
    string_agg(column_name, ', ' ORDER BY ordinal_position) as columns
FROM information_schema.columns 
WHERE table_name = 'profiles' AND table_schema = 'public'

UNION ALL

SELECT 
    'USERS TABLE COLUMNS' as table_info,
    string_agg(column_name, ', ' ORDER BY ordinal_position) as columns  
FROM information_schema.columns
WHERE table_name = 'users' AND table_schema = 'public';

-- Also check data types
SELECT 
    table_name,
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'profiles') 
    AND table_schema = 'public'
ORDER BY table_name, ordinal_position;