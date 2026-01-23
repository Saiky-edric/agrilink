# 🐛 **Debug Address Setup Issue**

## 🔍 **The Problem:**
Error: `"Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows"`

**This means:** The user profile doesn't exist in the `users` table when trying to update the address.

## 🔧 **Quick Debug Steps:**

### **Step 1: Check if user profile exists**
In **Supabase SQL Editor**, run:
```sql
-- Check if user exists in auth
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Check if profile exists in users table
SELECT id, email, full_name, role FROM public.users ORDER BY created_at DESC LIMIT 5;

-- Check for missing profiles
SELECT 
  a.id, 
  a.email, 
  CASE WHEN u.id IS NULL THEN 'MISSING PROFILE' ELSE 'Profile exists' END as status
FROM auth.users a 
LEFT JOIN public.users u ON a.id = u.id 
ORDER BY a.created_at DESC LIMIT 5;
```

### **Step 2: If profile is missing, create it manually**
```sql
-- Get the auth user ID first
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Create the missing profile (replace values)
INSERT INTO public.users (id, email, full_name, phone_number, role, created_at) 
VALUES (
  'your-auth-user-id-here',  -- Use the ID from above query
  'your-email@example.com',
  'Your Full Name',
  '09123456789',
  'buyer',  -- or 'farmer'
  NOW()
);
```

### **Step 3: Alternative Fix - Update RLS again**
If users still can't be created, run:
```sql
-- Make sure users can insert profiles
DROP POLICY IF EXISTS "Users can create own profile" ON users;
CREATE POLICY "Users can create own profile" ON users 
FOR INSERT WITH CHECK (auth.uid() = id);

-- Make sure users can update profiles  
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users 
FOR UPDATE USING (auth.uid() = id);
```

## 🎯 **Expected Flow:**
1. **User signs up** → Creates `auth.users` entry
2. **App creates profile** → Creates `public.users` entry
3. **User sets address** → Updates `public.users` with location
4. **App redirects** → Based on role

## 🔍 **Debug Output:**
After making the code changes, check the **Flutter debug console** for these messages:
- "Current user ID: [uuid]"
- "Selected municipality: [name]"
- "User profile exists/not found"

This will help identify exactly where the issue is occurring!