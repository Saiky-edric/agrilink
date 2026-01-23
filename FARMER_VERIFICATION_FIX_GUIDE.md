# 🔧 Farmer Verification RLS Fix Guide

## 🚨 **Problem Identified**
The error `StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)` occurs because:

1. **Database Migration Issue**: The app migrated from `users` table to `profiles` table, but RLS policies weren't updated
2. **Inconsistent Foreign Key References**: The `farmer_verifications.farmer_id` may reference the wrong table
3. **Missing RLS Policies**: Some required policies for INSERT operations are missing

## ✅ **Solution Steps**

### **Step 1: Run the RLS Fix SQL Script**
Execute this in your Supabase SQL Editor:

```sql
-- Option A: Use the comprehensive fix
\i supabase_setup/FIX_FARMER_VERIFICATION_RLS.sql

-- Option B: Use the updated fix_rls_policies.sql
\i supabase_setup/fix_rls_policies.sql
```

### **Step 2: Verify Your Database Structure**
Run this query to check which table structure you're using:

```sql
-- Check table existence
SELECT 
    'users' as table_name,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'users') as exists
UNION ALL
SELECT 
    'profiles' as table_name,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') as exists;

-- Check farmer_verifications foreign key
SELECT 
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='farmer_verifications'
    AND kcu.column_name='farmer_id';
```

### **Step 3: Test Authentication**
Before submitting verification, ensure:

1. **User is logged in properly**:
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   print('Current user: ${user?.id}'); // Should not be null
   ```

2. **User has farmer role**:
   ```sql
   -- Check user role in Supabase
   SELECT id, role FROM profiles WHERE user_id = 'YOUR_USER_ID';
   -- OR
   SELECT id, role FROM users WHERE id = 'YOUR_USER_ID';
   ```

### **Step 4: Update Service If Needed**
If you're using the `profiles` table, ensure the service uses the correct user ID:

```dart
// In farmer_verification_service.dart
final currentUser = _supabase.client.auth.currentUser;
if (currentUser == null) {
  throw Exception('User not authenticated');
}

// Use currentUser.id as farmer_id (this should match profiles.user_id)
final verificationData = {
  'farmer_id': currentUser.id, // This is the auth.uid()
  // ... rest of data
};
```

## 🔍 **Debugging Steps**

### **1. Check Current RLS Policies**
```sql
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;
```

### **2. Test Policy Manually**
```sql
-- Test if current user can insert
SELECT auth.uid() as current_user_id;

-- Check if policy allows INSERT
SELECT 'Can insert' as test
WHERE auth.uid() IS NOT NULL;
```

### **3. Check User Authentication in App**
```dart
void debugAuth() async {
  final user = Supabase.instance.client.auth.currentUser;
  print('Authenticated: ${user != null}');
  print('User ID: ${user?.id}');
  print('User Email: ${user?.email}');
  
  if (user != null) {
    // Check if user exists in database
    final response = await Supabase.instance.client
        .from('profiles') // or 'users'
        .select('role')
        .eq('user_id', user.id) // or 'id' for users table
        .maybeSingle();
    
    print('User role: ${response?['role']}');
  }
}
```

## 🎯 **Quick Test**

After running the fix:

1. **Login as a farmer**
2. **Try submitting verification**
3. **Check for errors**

If still failing, run:
```sql
-- Enable logging to see what's happening
SET log_statement = 'all';
-- Then try the operation and check Supabase logs
```

## 📱 **Expected Behavior After Fix**

✅ Farmers can submit verification documents  
✅ Verification data is stored in `farmer_verifications` table  
✅ Only the farmer who submitted can view their verification  
✅ Admins can view and approve/reject all verifications  

## 🚨 **Common Issues**

1. **Wrong table reference**: Ensure `farmer_id` references the correct table
2. **Auth state**: User must be logged in before submission
3. **Role mismatch**: User must have 'farmer' role
4. **Storage permissions**: Ensure storage bucket policies allow uploads

---

**Run the SQL fix first, then test the verification submission again!**