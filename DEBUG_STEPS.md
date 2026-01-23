# 🐛 **FIX SIGNUP & REDIRECT ISSUES**

## 🔧 **Step 1: Fix Database Permissions**

**In Supabase SQL Editor, run:**
```sql
-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- Create new policies that allow user creation
CREATE POLICY "Users can view own profile" ON users 
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users 
FOR UPDATE USING (auth.uid() = id);

-- IMPORTANT: Allow users to insert their own profile during signup
CREATE POLICY "Users can create own profile" ON users 
FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow public read for basic user info (needed for chat, etc.)
CREATE POLICY "Public can view user names" ON users 
FOR SELECT USING (true);
```

## 🔧 **Step 2: Test Signup Flow**

**After running the SQL:**
1. **Restart your app** (`flutter run`)
2. **Try signing up** as a buyer or farmer
3. **Check if user appears** in Supabase users table

## 🔧 **Step 3: Debug Redirect Issues**

**If signup works but redirect fails:**

### **Check Supabase Dashboard:**
- Go to **Authentication → Users**
- Verify your new user exists
- Copy the user ID

### **Check Users Table:**
- Go to **Database → Tables → users**
- Verify profile was created with correct role
- Make sure `id` matches the auth user ID

## 🚨 **Common Issues:**

### **Issue 1: RLS Still Blocking**
```
Error: "new row violates row-level security policy"
```
**Solution:** Make sure you ran the SQL policy fix above

### **Issue 2: User Created But No Redirect**
```
User appears in auth.users but not public.users
```
**Solution:** Check the Flutter debug console for profile creation errors

### **Issue 3: Wrong Role Assignment**
```
User redirects to wrong dashboard
```
**Solution:** Verify role in users table matches intended role

## ✅ **Expected Flow:**

1. **User signs up** → Creates auth.users entry
2. **App creates profile** → Creates public.users entry  
3. **App gets user role** → Reads from public.users
4. **App redirects** → Based on role (buyer/farmer/admin)

## 🎯 **Test Cases:**

**Test Buyer Signup:**
- Should redirect to `/buyer/home`

**Test Farmer Signup:**
- Should redirect to `/address-setup` first
- Then to `/farmer/dashboard`

**Debug Commands:**
```sql
-- Check if user was created in auth
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Check if profile was created
SELECT id, email, role FROM public.users ORDER BY created_at DESC LIMIT 5;

-- Check if IDs match
SELECT 
  a.id as auth_id, 
  a.email, 
  u.id as profile_id, 
  u.role 
FROM auth.users a 
LEFT JOIN public.users u ON a.id = u.id 
ORDER BY a.created_at DESC LIMIT 5;
```