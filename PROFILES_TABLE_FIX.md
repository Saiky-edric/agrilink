# Fix: Using Profiles Table Instead of Users Table

## Problem Identified

Your Supabase schema has **TWO user storage tables**:

1. **`profiles` table** - Linked to `auth.users` via `user_id` ✅ CORRECT
   - `user_id` (UUID) → Foreign key to `auth.users(id)`
   - `email`, `full_name`, `role`, `municipality`, `barangay`, `street`
   - This is what Auth creates

2. **`users` table** - Standalone table with its own UUID id ❌ NOT LINKED
   - `id` (UUID) → Independent, not linked to auth
   - `email`, `full_name`, `phone_number`, `role`, etc.
   - This is redundant

**The app was querying the `users` table, but your auth is stored in `auth.users`, mirrored in `profiles`.**

## Solution Applied

### 1. ✅ Updated AuthService (auth_service.dart)
Changed from:
```dart
await _supabase.users.select().eq('id', currentUser!.id)
```

To:
```dart
await _supabase.profiles.select().eq('user_id', currentUser!.id)
```

**Why:** 
- `currentUser!.id` is the auth ID from `auth.users`
- It matches `profiles.user_id`, not `users.id`

### 2. ✅ Updated SupabaseService (supabase_service.dart)
Added profiles table helper:
```dart
SupabaseQueryBuilder get profiles => client.from('profiles');
```

### 3. ✅ Updated UserModel (user_model.dart)
Updated `fromJson` to handle both tables:
```dart
final userId = json['id'] ?? json['user_id'] as String;
```

Handles null values gracefully:
- `email` defaults to ''
- `full_name` defaults to 'User'
- `phone_number` defaults to ''
- All dates are parsed safely

## Next Steps - Run in Supabase

Go to Supabase SQL Editor and run:

```sql
-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create READ policy
CREATE POLICY "Users can view own profile" ON profiles 
FOR SELECT USING (auth.uid() = user_id);

-- Create UPDATE policy  
CREATE POLICY "Users can update own profile" ON profiles 
FOR UPDATE USING (auth.uid() = user_id);

-- Create INSERT policy
CREATE POLICY "Users can insert own profile" ON profiles 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Verify
SELECT policyname FROM pg_policies WHERE tablename = 'profiles';
```

Or run the prepared file: `supabase_setup/08_enable_profiles_rls.sql`

## What Now Works

When user opens Profile Screen:

```
1. User logged in (auth.users.id = a1b2c3d4)
        ↓
2. App calls getCurrentUserProfile()
        ↓
3. Queries: SELECT * FROM profiles WHERE user_id = 'a1b2c3d4'
        ↓
4. RLS Policy: auth.uid() = user_id? 
        ↓ YES ✓
5. Returns profile data → UserModel loads
        ↓
6. Profile shows: Full Name, Email, Role, Address
```

## Table Comparison

| Field | profiles table | users table | App Uses |
|-------|---------------|------------|----------|
| id/user_id | user_id (auth link) | id (UUID) | **profiles.user_id** |
| email | ✓ | ✓ | **profiles.email** |
| full_name | ✓ | ✓ | **profiles.full_name** |
| phone_number | ✗ | ✓ | ❌ Not in profiles |
| role | ✓ (enum) | ✓ (enum) | **profiles.role** |
| municipality | ✓ | ✓ | **profiles.municipality** |
| barangay | ✓ | ✓ | **profiles.barangay** |
| street | ✓ | ✓ | **profiles.street** |
| is_active | ✓ | ✓ | **profiles.is_active** |

## Recommendation

You have two options:

### Option A: Keep Both Tables (Current Setup)
- Use `profiles` for auth-linked user data (for profile screens)
- Use `users` for additional user management (if needed)
- ✅ Already fixed in code

### Option B: Delete users Table & Use profiles Only
```sql
-- Delete the redundant users table
DROP TABLE IF EXISTS users CASCADE;

-- This keeps profiles as the single source of truth
-- Connected to auth via user_id
```

## Testing

1. **Check profiles RLS policies exist:**
   ```sql
   SELECT policyname FROM pg_policies WHERE tablename = 'profiles';
   ```

2. **Run app and open Profile Screen**
   - Check console for: `DEBUG: Fetching user profile for Auth ID:`
   - You should see profile data loading now

3. **If still no data:**
   - Check if profile record exists: 
   ```sql
   SELECT * FROM profiles LIMIT 5;
   ```
   - If empty, need to populate profiles table from auth users

## Files Changed

1. **lib/core/services/auth_service.dart**
   - Changed getCurrentUserProfile() to query profiles table

2. **lib/core/services/supabase_service.dart**
   - Added profiles table helper

3. **lib/core/models/user_model.dart**
   - Updated fromJson to handle profiles table schema

4. **supabase_setup/08_enable_profiles_rls.sql** (NEW)
   - RLS policies setup for profiles table

## Debug Output Expected

When profile loads, console should show:
```
DEBUG: Fetching user profile for Auth ID: a1b2c3d4-xxxx-xxxx-xxxx
DEBUG: User profile response: {user_id: a1b2c3d4..., full_name: John Doe, email: john@example.com...}
DEBUG: User profile loaded successfully: John Doe
```

If error:
```
ERROR: Failed to get user profile: <error details>
```

Check the error message against the troubleshooting guide above.
