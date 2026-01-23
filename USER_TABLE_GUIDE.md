# User Profile Data - Complete Guide

## Overview

Your app uses a **single `users` table** to store all user information, including role-based data (buyer, farmer, admin). This is the **correct approach** for a multi-role system.

**NOT using**: ❌ Separate `profiles` table
**USING**: ✅ Single `users` table with `role` column

## Table Structure

The `users` table has these columns:

```
id              UUID            - Unique identifier, synced with Auth
email           TEXT            - User's email (UNIQUE)
full_name       TEXT            - User's full name
phone_number    TEXT            - User's phone number
role            user_role ENUM  - One of: buyer, farmer, admin
municipality    TEXT (optional) - Delivery location
barangay        TEXT (optional) - Delivery location
street          TEXT (optional) - Delivery location
is_active       BOOLEAN         - Account suspension flag
created_at      TIMESTAMP       - When user was created
updated_at      TIMESTAMP       - Last update
```

## How It Works

### 1. User Registration
```
User signs up → AuthService.signUp()
  → Creates auth user (Firebase)
  → Creates user record in users table
  → Stores role (buyer/farmer/admin)
```

### 2. Data Loading
```
Profile Screen opens → _loadUserData()
  → AuthService.getCurrentUserProfile()
  → Queries: SELECT * FROM users WHERE id = auth.uid()
  → RLS Policy checks: Can user read their own row?
  → Returns UserModel with all profile info
```

### 3. Data Updating
```
User edits profile → _showEditProfileDialog()
  → AuthService.updateUserProfile()
  → Updates: name, phone, address fields
  → RLS Policy checks: Can user update their own row?
  → Saves to users table
```

## RLS (Row Level Security) Policies

The database enforces these policies:

```sql
-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON users 
FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users 
FOR UPDATE USING (auth.uid() = id);
```

**What this means:**
- ✅ User can read their own data
- ❌ User cannot read other users' data
- ✅ User can update their own data
- ❌ User cannot update other users' data

## Troubleshooting

### Problem: Profile info not showing
**Possible causes:**
1. RLS policy not applied correctly
2. User data not created in users table
3. Auth user ID doesn't match users.id

**Solution:**
- See `VERIFY_USER_DATA.md` for diagnostic queries
- See `supabase_setup/VERIFY_QUERIES.sql` for detailed checks

### Problem: Getting "permission denied" errors
**Cause:** RLS policy blocking access

**Solution:**
1. Run verification queries to check policies exist
2. If policies don't exist, re-run `01_database_schema.sql`
3. Make sure you're authenticated when testing

### Problem: Data in `profiles` table instead of `users`
**Situation:** You have old data in a different table

**Solution:**
- See `supabase_setup/MIGRATION_profiles_to_users.sql`
- Follow the migration steps to copy data to users table

## Code Changes Made

### 1. Added Debug Logging in AuthService
```dart
// Now logs:
// - User ID being fetched
// - Full response from database
// - Any errors with stack trace
```

### 2. Better Error Display in ProfileScreen
```dart
// Now shows error messages to user instead of silently failing
// - "Warning: Could not load user profile..."
// - "Error loading profile: [error details]"
```

## Files to Review

1. **Schema Definition**
   - `supabase_setup/01_database_schema.sql` - Main table definition

2. **Admin Features** 
   - `supabase_setup/06_admin_features_schema.sql` - Suspension feature

3. **Verification**
   - `supabase_setup/VERIFY_QUERIES.sql` - Diagnostic queries
   - `VERIFY_USER_DATA.md` - Step-by-step guide

4. **Migration**
   - `supabase_setup/MIGRATION_profiles_to_users.sql` - If you need to merge tables

## Quick Reference

**Users table is the source of truth for:**
- ✅ Authentication matching (auth.uid = users.id)
- ✅ User roles (buyer, farmer, admin)
- ✅ Profile information (name, email, phone, address)
- ✅ Account status (active/suspended)

**NOT stored in users table:**
- ❌ Products (products table)
- ❌ Orders (orders table)
- ❌ Farmer verifications (farmer_verifications table)
- ❌ Chat messages (messages table)

These link back to users via `user_id` or `farmer_id` foreign keys.

## Testing Checklist

- [ ] Run `VERIFY_QUERIES.sql` in Supabase SQL editor
- [ ] Confirm users table has data
- [ ] Confirm RLS policies exist
- [ ] Run app and check console for DEBUG logs
- [ ] Open profile screen and check for errors
- [ ] Edit profile and save - verify update works

## Next Steps

1. **Diagnose current issue:**
   - Run queries in `supabase_setup/VERIFY_QUERIES.sql`
   - Check console output from app (look for DEBUG messages)

2. **Fix data if needed:**
   - If using profiles table: Run migration SQL
   - If missing data: Add user records manually or re-signup

3. **Test thoroughly:**
   - Sign up new user
   - Verify profile loads correctly
   - Edit profile fields
   - Check all data saves properly

