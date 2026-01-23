-- =====================================================
-- AGRILINK MIGRATION VALIDATION QUERIES
-- =====================================================
-- Run these queries to validate the users/profiles consolidation
-- =====================================================

-- 1. Check table counts
SELECT 
    'Table Counts' as check_type,
    'users' as table_name,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'Table Counts' as check_type,
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Table Counts' as check_type,
    'profiles (should be 0 after migration)' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') 
        THEN (SELECT COUNT(*) FROM public.profiles)
        ELSE 0 
    END as count;

-- 2. Verify all auth users have corresponding user records
SELECT 
    'Missing User Records' as check_type,
    COUNT(*) as auth_users_without_user_records
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL;

-- 3. Check data completeness
SELECT 
    'Data Completeness' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN full_name IS NOT NULL AND full_name != '' THEN 1 END) as with_name,
    COUNT(CASE WHEN email IS NOT NULL AND email != '' THEN 1 END) as with_email,
    COUNT(CASE WHEN role IS NOT NULL THEN 1 END) as with_role,
    COUNT(CASE WHEN municipality IS NOT NULL AND barangay IS NOT NULL AND street IS NOT NULL THEN 1 END) as with_complete_address
FROM public.users;

-- 4. Role distribution
SELECT 
    'Role Distribution' as check_type,
    role,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM public.users)), 2) as percentage
FROM public.users
GROUP BY role
ORDER BY count DESC;

-- 5. Check foreign key integrity
SELECT 
    'Foreign Key Integrity' as check_type,
    'cart' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN u.id IS NOT NULL THEN 1 END) as valid_user_refs
FROM public.cart c
LEFT JOIN public.users u ON c.user_id = u.id
UNION ALL
SELECT 
    'Foreign Key Integrity' as check_type,
    'orders' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN u.id IS NOT NULL THEN 1 END) as valid_buyer_refs
FROM public.orders o
LEFT JOIN public.users u ON o.buyer_id = u.id
UNION ALL
SELECT 
    'Foreign Key Integrity' as check_type,
    'products' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN u.id IS NOT NULL THEN 1 END) as valid_farmer_refs
FROM public.products p
LEFT JOIN public.users u ON p.farmer_id = u.id;

-- 6. Check for duplicate users
SELECT 
    'Duplicate Check' as check_type,
    email,
    COUNT(*) as count
FROM public.users
GROUP BY email
HAVING COUNT(*) > 1;

-- 7. Address completion status
SELECT 
    'Address Status' as check_type,
    CASE 
        WHEN municipality IS NOT NULL AND barangay IS NOT NULL AND street IS NOT NULL THEN 'Complete'
        WHEN municipality IS NOT NULL OR barangay IS NOT NULL OR street IS NOT NULL THEN 'Partial'
        ELSE 'Empty'
    END as address_status,
    COUNT(*) as count
FROM public.users
GROUP BY 
    CASE 
        WHEN municipality IS NOT NULL AND barangay IS NOT NULL AND street IS NOT NULL THEN 'Complete'
        WHEN municipality IS NOT NULL OR barangay IS NOT NULL OR street IS NOT NULL THEN 'Partial'
        ELSE 'Empty'
    END;

-- 8. Recent user activity
SELECT 
    'User Activity' as check_type,
    CASE 
        WHEN created_at > NOW() - INTERVAL '7 days' THEN 'Last 7 days'
        WHEN created_at > NOW() - INTERVAL '30 days' THEN 'Last 30 days'
        WHEN created_at > NOW() - INTERVAL '90 days' THEN 'Last 90 days'
        ELSE 'Older than 90 days'
    END as created_period,
    COUNT(*) as count
FROM public.users
GROUP BY 
    CASE 
        WHEN created_at > NOW() - INTERVAL '7 days' THEN 'Last 7 days'
        WHEN created_at > NOW() - INTERVAL '30 days' THEN 'Last 30 days'
        WHEN created_at > NOW() - INTERVAL '90 days' THEN 'Last 90 days'
        ELSE 'Older than 90 days'
    END
ORDER BY 
    CASE 
        WHEN created_period = 'Last 7 days' THEN 1
        WHEN created_period = 'Last 30 days' THEN 2
        WHEN created_period = 'Last 90 days' THEN 3
        ELSE 4
    END;

-- 9. Identify any problematic records
SELECT 
    'Problematic Records' as check_type,
    id,
    email,
    full_name,
    role,
    CASE 
        WHEN email IS NULL OR email = '' THEN 'Missing email'
        WHEN full_name IS NULL OR full_name = '' THEN 'Missing name'
        WHEN role IS NULL THEN 'Missing role'
        ELSE 'OK'
    END as issue
FROM public.users
WHERE 
    email IS NULL OR email = '' OR
    full_name IS NULL OR full_name = '' OR
    role IS NULL
LIMIT 10;

-- 10. Sample of migrated data
SELECT 
    'Sample Data' as check_type,
    id,
    email,
    full_name,
    role,
    CASE 
        WHEN municipality IS NOT NULL AND barangay IS NOT NULL AND street IS NOT NULL 
        THEN 'Address Complete'
        ELSE 'Address Incomplete'
    END as address_status,
    created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 5;