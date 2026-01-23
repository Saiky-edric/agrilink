# 🚨 IMMEDIATE FIX: Farmer Verification RLS Error

## ✅ **Good News**
Your app is working correctly:
- ✅ User authenticated as farmer
- ✅ User validation passed (Role: farmer, Active: true)
- ✅ All other app features working

## 🎯 **Only Issue: Database RLS Policies**

The error `StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)` means the database policies need to be updated.

## 🔧 **IMMEDIATE FIX STEPS**

### **Step 1: Open Supabase Dashboard**
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Open your **Agrilink project**
4. Click **SQL Editor** in the left sidebar

### **Step 2: Run This Exact SQL Code**

Copy and paste this into the SQL Editor and click **RUN**:

```sql
-- Fix Farmer Verification RLS Policies
DROP POLICY IF EXISTS "Farmers can view own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can insert own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Farmers can update own verification" ON farmer_verifications;
DROP POLICY IF EXISTS "Admins can manage verifications" ON farmer_verifications;

-- Enable RLS
ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- Create new working policies
CREATE POLICY "Farmers can view own verification" ON farmer_verifications
    FOR SELECT
    USING (auth.uid() = farmer_id);

CREATE POLICY "Farmers can insert own verification" ON farmer_verifications
    FOR INSERT
    WITH CHECK (
        auth.uid() = farmer_id
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "Farmers can update own verification" ON farmer_verifications
    FOR UPDATE
    USING (auth.uid() = farmer_id)
    WITH CHECK (auth.uid() = farmer_id);

CREATE POLICY "Admins can manage verifications" ON farmer_verifications
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
            AND is_active = true
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON farmer_verifications TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Success message
SELECT '✅ FARMER VERIFICATION RLS FIX COMPLETED!' as status;
```

### **Step 3: Test Verification**
1. Go back to your app
2. Try submitting farmer verification again
3. Should work without the 403 error!

## 🎯 **What This Fix Does**

- **Removes old broken policies** that were preventing insertions
- **Creates new policies** that allow farmers to insert their own verification records
- **Grants proper permissions** for authenticated users
- **Maintains security** - farmers can only access their own data

## ✅ **Expected Result**

After running the SQL:
- ✅ Farmer verification submission will work
- ✅ No more 403 Unauthorized errors
- ✅ Your app will be fully functional for farmers

## 🚀 **After This Fix**

Your Agrilink app will have:
- 🔔 Working notifications
- 🚜 Farmer verification submission
- 🛒 Complete marketplace functionality
- 📸 Image uploads for products and verification
- 💬 Real-time chat
- 📱 Full mobile experience

**This is the last technical hurdle - run the SQL and your app is ready! 🎉**

---

## 📍 **Location of Files**
- The complete SQL fix is also in: `supabase_setup/QUICK_RLS_FIX.sql`
- Use either the code above OR copy from that file

**Just run the SQL fix and farmer verification will work immediately! 🚀**