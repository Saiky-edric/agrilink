# 🔍 Step-by-Step Debug Guide for RLS Issue

## 🎯 **Current Status**
You're getting `StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)` even though user validation shows the farmer is authenticated and active.

## 📋 **Systematic Debugging Approach**

### **Phase 1: Database-Side Debugging**

#### **Step 1: Run Database Debug**
1. **Open Supabase Dashboard** → **SQL Editor**
2. **Run** `supabase_setup/DEBUG_RLS_ISSUE.sql`
3. **Review all results** - look for any ❌ indicators

**Key things to check:**
- Is `auth.uid()` returning your user ID or NULL?
- Are RLS policies showing up correctly?
- Does your user exist with farmer role?

#### **Step 2: Manual Insert Test**
In Supabase SQL Editor, try this manual insert:

```sql
-- Replace with your actual user ID
INSERT INTO farmer_verifications (
    farmer_id,
    farm_name,
    farm_address,
    farmer_id_image_url,
    barangay_cert_image_url,
    selfie_image_url,
    status
) VALUES (
    '25a3e497-6b2f-4740-878d-17379d9e1644',
    'Manual Test Farm',
    'Manual Test Address',
    'manual-test-url-1',
    'manual-test-url-2',
    'manual-test-url-3',
    'pending'
);
```

**Expected Results:**
- ✅ **If successful**: RLS policies work, issue is in app
- ❌ **If fails**: RLS policies are the problem

### **Phase 2: App-Side Debugging**

#### **Step 3: Add Debug Service**
1. **Import the debug service** in your verification screen
2. **Add debug button** to test systematically

```dart
// Add this to your verification screen
import '../../../core/services/farmer_verification_debug.dart';

// Add this button for testing
ElevatedButton(
  onPressed: () async {
    final debugService = FarmerVerificationDebugService();
    final report = await debugService.generateDebugReport();
    print('=== DEBUG REPORT ===');
    print(report);
  },
  child: Text('Run Debug Test'),
)
```

#### **Step 4: Test Different Approaches**
Try these variations in your app:

**Option A: Minimal Data Test**
```dart
final minimalData = {
  'farmer_id': farmerId,
  'farm_name': farmName,
  'farm_address': farmAddress,
  'status': 'pending',
};
```

**Option B: Direct Client Test**
```dart
final directClient = Supabase.instance.client;
final response = await directClient
    .from('farmer_verifications')
    .insert(minimalData);
```

### **Phase 3: Authentication Context Check**

#### **Step 5: Auth Context Verification**
The most likely issue is authentication context not being passed properly.

**Test 1: Session Check**
```dart
void debugAuth() {
  final session = Supabase.instance.client.auth.currentSession;
  print('Session exists: ${session != null}');
  print('Session user: ${session?.user.id}');
  print('Session access token: ${session?.accessToken.substring(0, 20)}...');
  print('Session expires: ${session?.expiresAt}');
}
```

**Test 2: Headers Check**
```dart
// Check if auth headers are being sent
final headers = Supabase.instance.client.rest.headers;
print('Auth headers: $headers');
```

### **Phase 4: Common Issues & Solutions**

#### **Issue 1: Auth Context Not Passed**
**Symptoms**: `auth.uid()` returns NULL in database
**Solution**: 
```sql
-- Temporarily use service role key instead of anon key
-- Or check if JWT token is being sent properly
```

#### **Issue 2: Policy Mismatch**
**Symptoms**: Policies exist but still fail
**Solution**: Check if farmer_id column type matches auth.uid() type

#### **Issue 3: Column Constraints**
**Symptoms**: Passes RLS but fails on constraints
**Solution**: Check for NOT NULL columns or foreign key violations

#### **Issue 4: Storage vs Database**
**Symptoms**: Files upload but database insert fails
**Solution**: The error might be from storage bucket RLS, not table RLS

### **Phase 5: Progressive Testing**

#### **Test Sequence (in order):**

1. **Manual SQL insert** (in Supabase dashboard)
2. **Minimal app insert** (just required fields)
3. **Add fields gradually** until it breaks
4. **Test with different user** (create test farmer)
5. **Test with admin role** (if you have admin access)

### **Phase 6: Alternative Solutions**

If RLS continues to fail, try these approaches:

#### **Option A: Service Role Authentication**
Use service role key for admin operations

#### **Option B: Custom API Function**
Create a Supabase Edge Function that bypasses RLS

#### **Option C: Application-Level Security**
Remove RLS and handle security in app code

## 🎯 **Expected Debug Outcomes**

### **Scenario 1: Auth Context Issue**
```
❌ auth.uid() returns NULL
✅ User exists in app
→ Solution: Fix JWT token passing
```

### **Scenario 2: RLS Policy Issue**
```
✅ auth.uid() returns user ID
❌ Policy condition fails
→ Solution: Adjust RLS policies
```

### **Scenario 3: Column Issue**
```
✅ auth.uid() works
✅ RLS policies pass
❌ Column constraint violation
→ Solution: Fix data structure
```

### **Scenario 4: Different Table/Bucket**
```
✅ Manual insert works
❌ App insert fails
→ Solution: Check storage bucket policies
```

## 🚀 **Quick Action Items**

1. **Run the database debug SQL first** - this will show us exactly what's wrong
2. **Try manual insert in SQL** - confirms if RLS works at all
3. **Use debug service** - systematically test each component
4. **Check auth session** - verify JWT token is valid

## 📊 **Debug Priority Order**

1. **Database debug** (highest priority - shows root cause)
2. **Manual insert test** (confirms RLS functionality)
3. **Auth context check** (most common issue)
4. **App-side debugging** (isolates app-specific issues)
5. **Progressive testing** (finds breaking point)

**Start with Step 1 (database debug) and work through systematically. The debug output will tell us exactly what's wrong! 🔍**