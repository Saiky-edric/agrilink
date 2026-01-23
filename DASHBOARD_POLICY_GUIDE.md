# 🔧 Dashboard Method to Add Policies (No SQL Permissions Needed)

Since you don't have SQL table permissions, use the Supabase Dashboard:

## Method 1: Dashboard Policy Creation

### For store-banners bucket:

1. **Go to Supabase Dashboard** → **Storage**
2. **Click on `store-banners` bucket**
3. **Click "Policies" tab**
4. **Click "New Policy"**
5. **Click "Get started quickly"**
6. **Select "Enable access to all users"**
7. **Click "Save Policy"**

### For store-logos bucket:

1. **Click on `store-logos` bucket**
2. **Click "Policies" tab** 
3. **Click "New Policy"**
4. **Click "Get started quickly"**
5. **Select "Enable access to all users"**
6. **Click "Save Policy"**

## Method 2: Custom Policy Creation

If "Get started quickly" doesn't work:

1. **Click "New Policy"**
2. **Select "For full customization"**
3. **Policy Name:** `Allow uploads for authenticated users`
4. **Allowed Operation:** `INSERT`
5. **Target Roles:** `authenticated`
6. **USING Expression:** Leave blank
7. **WITH CHECK Expression:** `bucket_id = 'store-banners'`
8. **Click "Save"**

Repeat for `store-logos` bucket.

## Method 3: Disable RLS (Temporary Fix)

**ONLY as last resort:**

1. Go to **Database** → **Tables** 
2. Find **storage.objects** table
3. **Disable RLS** temporarily
4. Test uploads
5. **Re-enable RLS** after testing

⚠️ **Security Warning:** Only use Method 3 for testing!

## ✅ Expected Result

After adding policies, you should see:
- **Policies tab** shows 1-4 policies for each bucket
- **Upload attempts** return success instead of 403
- **Images** appear in your app after upload

## 🧪 Quick Test

1. Try uploading through your Flutter app
2. If still 403, check bucket policies in dashboard
3. Ensure policies show as "Enabled"