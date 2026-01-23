# QUICK FIX - Profile Data Not Loading

## What You Need to Do RIGHT NOW

### Step 1: Run Diagnostic Query
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Paste and run this:

```sql
-- Check if users table has data
SELECT COUNT(*) as total_users FROM users;
SELECT id, email, full_name, role FROM users LIMIT 3;
```

**Result to expect:** You should see your user data

---

### Step 2: Check RLS Policies
```sql
-- Verify RLS policies exist
SELECT policyname, tablename FROM pg_policies WHERE tablename = 'users';
```

**Result to expect:** 
- "Users can view own profile"
- "Users can update own profile"

If policies are missing, the fix is simple - run the SQL from `supabase_setup/01_database_schema.sql` lines 249-250

---

### Step 3: Test the App
1. Run the app: `flutter run`
2. Open profile screen
3. Check Flutter console for messages

**Look for:**
- ✅ `DEBUG: Fetching user profile for ID: ...` → GOOD
- ✅ `DEBUG: User profile response: {...}` → GOOD  
- ❌ `ERROR: Failed to get user profile: ...` → BAD - See solution below

---

## Solutions by Error

### Error: "Failed to get user profile: 404"
**Meaning:** User doesn't exist in database

**Fix:**
- Your auth user ID doesn't match a record in users table
- Sign up again with email/password (not social login)
- Or run this migration if you have profiles table:
  - See `supabase_setup/MIGRATION_profiles_to_users.sql`

---

### Error: "Failed to get user profile: permission denied"  
**Meaning:** RLS policy is blocking access

**Fix:**
1. Go to Supabase → SQL Editor
2. Run this:
```sql
CREATE POLICY "Users can view own profile" ON users 
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users 
FOR UPDATE USING (auth.uid() = id);
```

---

### Error: "Failed to get user profile: column 'full_name' does not exist"
**Meaning:** Users table schema is wrong

**Fix:**
1. Check your users table columns (run diagnostic)
2. If columns are missing, add them:
```sql
ALTER TABLE users ADD COLUMN full_name TEXT;
ALTER TABLE users ADD COLUMN phone_number TEXT;
-- etc
```

---

### No Error, But Profile Shows "User" and Empty Fields
**Meaning:** Data loaded but is empty/NULL

**Fix:**
1. Update your profile with real data:
   - Click edit profile in app
   - Fill in name, phone, address
   - Save
2. Or run directly in SQL:
```sql
UPDATE users 
SET full_name = 'Your Name', 
    phone_number = '09123456789'
WHERE id = 'YOUR_USER_ID';
```

---

## Three Table Setup (Reference Only)

Your schema uses **users table** - which is correct for multi-role:

```
┌─────────────────┐
│  Auth (Firebase)│ ← Handles login/password
└────────┬────────┘
         │
         ↓
    ┌────────────┐
    │   users    │ ← Stores profile + roles
    │            │   id, email, name, 
    │            │   role, phone, address
    └────┬───────┘
         │
    ┌────┴──────────┬─────────────┐
    ↓               ↓             ↓
┌────────┐   ┌──────────┐   ┌────────────┐
│products│   │  orders  │   │   payment_ │
│(farmer)│   │(reference)   │  methods   │
└────────┘   └──────────┘   └────────────┘
```

NOT using:
- ❌ Separate profiles table (one table is enough)
- ❌ Profile metadata table (all in users)

---

## Files Created for You

1. **USER_TABLE_GUIDE.md** - Complete reference
2. **VERIFY_USER_DATA.md** - Diagnostic guide  
3. **supabase_setup/VERIFY_QUERIES.sql** - Copy/paste queries
4. **supabase_setup/MIGRATION_profiles_to_users.sql** - If you need to migrate

---

## The Issue Summary

**You said:** "I use users table instead of profile because of user roles"

**That's CORRECT! ✅**
- `users` table is designed to handle multiple roles
- Each user has: id, email, name, phone, role (buyer/farmer/admin), address fields
- This is the intended design

**The problem is likely:**
1. ❌ Data doesn't exist in users table → User record not created properly
2. ❌ RLS policies not enabled → Can't read own data
3. ❌ Column name mismatch → App expects different field names
4. ❌ Auth ID mismatch → Login ID doesn't match users.id

---

## Immediate Actions

Do this now:

1. [ ] Run diagnostic query from Step 1 above
2. [ ] Check if user data exists
3. [ ] Check if RLS policies exist
4. [ ] Run app and check console for ERROR messages
5. [ ] Share any ERROR messages from console
6. [ ] Then apply the solution for that specific error

---

## Video Summary

Flow diagram of how data flows:

```
User signs up with email:john@example.com
              ↓
Firebase creates Auth user (ID: a1b2c3d4)
              ↓
App calls _createUserProfile() with ID: a1b2c3d4
              ↓
INSERT INTO users VALUES (
  id: a1b2c3d4,
  email: john@example.com,
  full_name: John Doe,
  role: buyer
)
              ↓
User opens profile screen
              ↓  
App queries: SELECT * FROM users WHERE id = a1b2c3d4
              ↓
RLS checks: Is auth.uid() (a1b2c3d4) == users.id (a1b2c3d4)? → YES ✓
              ↓
Returns user data → Profile shows John Doe, john@example.com, etc.
```

If ANY step fails, you see the error in console.

