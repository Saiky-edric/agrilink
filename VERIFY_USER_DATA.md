# Verify User Data in Supabase

## Problem Diagnosis

You mentioned that profile information is not matching and that you use the `users` table instead of `profile` table. **This is correct** - the app uses the `users` table which supports multiple roles (buyer, farmer, admin).

## How to Debug

### Step 1: Check in Supabase Dashboard

1. Go to Supabase Dashboard → SQL Editor
2. Run this query to verify data exists:

```sql
-- Check if your user exists in users table
SELECT id, email, full_name, phone_number, role, created_at FROM users LIMIT 10;

-- Check specific user (replace with your user ID from auth)
SELECT * FROM users WHERE id = 'YOUR_USER_ID_HERE';
```

### Step 2: Verify RLS Policies

The RLS policies should allow users to read their own profiles:

```sql
-- Check RLS policies on users table
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Output should include:
-- "Users can view own profile" FOR SELECT USING (auth.uid() = id)
-- "Users can update own profile" FOR UPDATE USING (auth.uid() = id)
```

### Step 3: Check Columns Exist

Make sure the users table has all required columns:

```sql
-- Check users table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Should include:
-- id (uuid)
-- email (text)
-- full_name (text)
-- phone_number (text)
-- role (user_role enum: buyer/farmer/admin)
-- municipality (text)
-- barangay (text)
-- street (text)
-- is_active (boolean) - added by admin features
-- created_at (timestamp)
-- updated_at (timestamp)
```

## Common Issues & Solutions

### Issue 1: RLS Policy Missing or Wrong
**Error**: User can't read their own profile
**Solution**: 
```sql
-- Re-run this in Supabase SQL editor:
CREATE POLICY "Users can view own profile" ON users 
FOR SELECT USING (auth.uid() = id);
```

### Issue 2: Table Uses Different Name
**Current**: Code uses `users` table ✓ (CORRECT)
**Wrong**: If Supabase created a `profiles` table instead

**Verify**: Check if data exists in profiles table:
```sql
SELECT * FROM profiles LIMIT 1;
```

If profiles exist but users doesn't:
- Option A: Copy data from profiles to users
- Option B: Change SupabaseService to use profiles table

### Issue 3: is_active Column Missing
**Error**: 'is_active' column doesn't exist
**Solution**: Run admin features schema:
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
```

### Issue 4: Data Type Mismatch
**Error**: Parsing errors when loading user
**Check**: In Supabase, verify role column is enum type:
```sql
-- Check role column type
SELECT data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'role';

-- Should show: user_role (custom enum type)
```

## Debugging in App

The app now logs detailed debug information:

1. **Enable debug output**: Run the app and check the console
2. **Look for**: 
   - `DEBUG: Fetching user profile for ID: ...`
   - `DEBUG: User profile response: ...`
   - `ERROR: Failed to get user profile: ...`

3. **If you see errors**: Copy the error message and check against the solutions above

## The Code Path

1. User logs in → `AuthService.signUp()` or `AuthService.signIn()`
2. User profile created in `users` table → `_createUserProfile()`
3. Profile screen loads → `ProfileScreen._loadUserData()`
4. Calls → `AuthService.getCurrentUserProfile()`
5. Queries → `supabase.users.select().eq('id', currentUser.id).single()`
6. RLS Policy checks: Is `auth.uid() == id`? → YES → Data returned

## Quick Fix Checklist

- [ ] User data exists in `users` table (not `profiles`)
- [ ] RLS policies are enabled and correct
- [ ] `is_active` column exists on users table
- [ ] User role is one of: buyer, farmer, admin
- [ ] All required columns have data (no NULL for required fields)
- [ ] Auth user ID matches user.id in users table

## Need More Help?

Run this in your app console to see detailed debug info:
```
Look at Flutter console output when profile screen loads
Copy any ERROR messages shown in red
```
