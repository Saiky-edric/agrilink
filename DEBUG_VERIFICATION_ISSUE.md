# 🔍 Debug: Farmer Verification RLS Issue

## 🎯 **Issue Analysis**

Your code looks correct, but you're still getting the RLS error. Let's debug this step by step.

## 🔧 **Debug Steps**

### **Step 1: Check Current RLS Policies**

Run this in your Supabase SQL Editor to see what policies exist:

```sql
-- Check current policies
SELECT 
    policyname,
    cmd as command,
    permissive,
    roles,
    qual as using_condition,
    with_check as with_check_condition
FROM pg_policies 
WHERE tablename = 'farmer_verifications'
ORDER BY policyname;

-- Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'farmer_verifications';
```

### **Step 2: Test Auth Context**

Run this to see if authentication context is working:

```sql
-- Test current authentication
SELECT 
    auth.uid() as current_user_id,
    (SELECT role FROM users WHERE id = auth.uid()) as user_role,
    (SELECT is_active FROM users WHERE id = auth.uid()) as user_active;
```

### **Step 3: Test Policy Conditions**

Run this to test if the policy conditions would pass:

```sql
-- Test policy condition for your specific user
SELECT 
    'User ID: ' || auth.uid()::text as debug_info,
    'Can insert?' as question,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'YES - User authenticated'
        ELSE 'NO - User not authenticated'
    END as auth_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'farmer' 
            AND is_active = true
        ) THEN 'YES - User is active farmer'
        ELSE 'NO - User is not active farmer'
    END as farmer_check;
```

## 🛠 **Alternative Fix: Temporary Policy Override**

If the policies are still problematic, try this temporary fix:

```sql
-- Temporarily disable RLS for testing
ALTER TABLE farmer_verifications DISABLE ROW LEVEL SECURITY;

-- Test your verification submission now
-- Then re-enable RLS after testing:
-- ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;
```

## 🔍 **Check Storage Bucket Policies**

The error might also be related to storage bucket permissions:

```sql
-- Check storage bucket policies
SELECT 
    bucket_id,
    name as policy_name,
    definition
FROM storage.policies 
WHERE bucket_id = 'verification-documents';
```

## 💡 **Most Likely Issues**

1. **RLS policies not applied correctly**
2. **Auth context not being passed properly**
3. **Storage bucket permissions**
4. **Column mismatch in the verification data**

## 🧪 **Test with Simplified Data**

Try this in your app - modify the verification data to be minimal:

```dart
// In farmer_verification_service.dart, replace the verificationData with:
final verificationData = {
  'farmer_id': farmerId,
  'farm_name': farmName,
  'farm_address': farmAddress,
  'farmer_id_image_url': uploadResults['farmer_id_url']!,
  'barangay_cert_image_url': uploadResults['barangay_cert_url']!,
  'selfie_image_url': uploadResults['selfie_url']!,
  'status': 'pending',
  // Remove all the extra fields temporarily
};
```

## 🎯 **Expected Debug Results**

After running the SQL queries, you should see:
- ✅ RLS enabled on farmer_verifications table
- ✅ Policies exist for INSERT operations
- ✅ auth.uid() returns your user ID
- ✅ User role is 'farmer' and is_active is true

If any of these fail, we'll know exactly what to fix!