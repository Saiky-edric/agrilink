# 🚨 URGENT: Wrong Migration Script Detected!

## ❌ **Problem Identified**

You ran: `MIGRATION_profiles_to_users.sql` 
**This script moves data FROM profiles TO users (backwards!)**

You should run: `10_fix_foreign_key_inconsistencies.sql`
**This script moves data FROM users TO profiles (correct direction!)**

## 🔍 **The Error Explained**

```sql
-- This line in the wrong script:
INSERT INTO users (id, email, full_name, ...)
SELECT id, email, full_name, ...
FROM profiles
WHERE id NOT IN (SELECT id FROM users);
```

**Problem**: 
- `profiles` table has `user_id` column (not `id`)
- Script tries to SELECT `id` from `profiles` 
- Column `id` doesn't exist in `profiles` table
- **Result**: ERROR 42703: column "id" does not exist

## ✅ **Correct Action Required**

### **STOP the current script immediately**

### **Run the CORRECT script instead:**

```sql
-- Use this script (from our previous conversation):
supabase_setup/10_fix_foreign_key_inconsistencies.sql
```

## 🎯 **Key Differences**

| Wrong Script | Correct Script |
|-------------|----------------|
| `MIGRATION_profiles_to_users.sql` | `10_fix_foreign_key_inconsistencies.sql` |
| Moves profiles → users | Moves users → profiles |
| Uses wrong column names | Uses correct column mappings |
| Goes backward | Goes forward (correct) |
| Breaks the architecture | Fixes the architecture |

## 🔧 **What To Do Now**

### **Step 1: Verify Current State**
```sql
-- Check if the wrong migration caused any damage:
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE table_name IN ('users', 'profiles') 
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;
```

### **Step 2: Run Correct Migration**

**Copy this ENTIRE script content and run it:**

```sql
-- ============================================================
-- CORRECT MIGRATION: Fix Foreign Key Inconsistencies  
-- This moves data FROM users TO profiles (correct direction)
-- ============================================================

-- First, ensure profiles table exists with correct structure
CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL DEFAULT 'User',
    phone_number TEXT DEFAULT '',
    role user_role NOT NULL DEFAULT 'buyer',
    municipality TEXT,
    barangay TEXT,
    street TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrate data FROM users TO profiles (correct direction)
INSERT INTO profiles (
    user_id, email, full_name, phone_number, role,
    municipality, barangay, street, is_active, created_at, updated_at
)
SELECT 
    u.id,                                    -- users.id becomes profiles.user_id
    COALESCE(u.email, ''),
    COALESCE(u.full_name, 'User'),
    COALESCE(u.phone_number, ''),
    COALESCE(u.role, 'buyer'::user_role),
    u.municipality,
    u.barangay,
    u.street,
    COALESCE(u.is_active, true),
    COALESCE(u.created_at, NOW()),
    COALESCE(u.updated_at, NOW())
FROM users u
WHERE u.id NOT IN (SELECT user_id FROM profiles)  -- Avoid duplicates
ON CONFLICT (user_id) DO NOTHING;

-- Then run the complete foreign key fix script
-- (The rest of 10_fix_foreign_key_inconsistencies.sql)
```

## 📋 **Files You Should Be Using**

✅ **CORRECT files from our conversation:**
- `supabase_setup/10_fix_foreign_key_inconsistencies.sql` ← **Use this one**
- `EXECUTION_GUIDE_PATH_A.md`
- `PRE_MIGRATION_CHECKLIST.md`

❌ **WRONG files (ignore these):**
- `MIGRATION_profiles_to_users.sql` ← **Don't use this**

## 🚨 **Why This Happened**

The wrong script (`MIGRATION_profiles_to_users.sql`) appears to be an old/reverse migration that moves data in the wrong direction. It's trying to populate the `users` table from `profiles`, but:

1. `profiles.user_id` should become `users.id`
2. But the script tries to SELECT `id` FROM `profiles`
3. `profiles` table has `user_id`, not `id`
4. Hence the error

## 🎯 **Next Steps**

1. **❌ STOP using `MIGRATION_profiles_to_users.sql`**
2. **✅ USE the correct script: `10_fix_foreign_key_inconsistencies.sql`**
3. **📋 Follow `EXECUTION_GUIDE_PATH_A.md`**

The correct script handles the proper data flow:
```
users.id → profiles.user_id (correct mapping)
```

Not:
```
profiles.id → users.id (wrong mapping - causes the error)
```