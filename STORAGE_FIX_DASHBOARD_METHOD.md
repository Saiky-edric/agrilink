# 🔧 Storage Fix - Dashboard Method (No SQL Required)

Since you don't have table ownership permissions, let's fix this through the Supabase Dashboard interface.

## Step 1: Create Storage Buckets via Dashboard

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click on **Storage** in the left sidebar

2. **Create store-banners bucket:**
   - Click **"New Bucket"**
   - Name: `store-banners`
   - ✅ Check **"Public bucket"**
   - Click **"Create bucket"**

3. **Create store-logos bucket:**
   - Click **"New Bucket"** 
   - Name: `store-logos`
   - ✅ Check **"Public bucket"**
   - Click **"Create bucket"**

## Step 2: Configure Bucket Policies via Dashboard

### For store-banners bucket:
1. Click on **store-banners** bucket
2. Click **"Policies"** tab
3. Click **"New Policy"**
4. Choose **"Custom"**
5. Add this policy:

```sql
-- Allow authenticated users to upload
CREATE POLICY "Allow upload to store-banners" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'store-banners');
```

6. Click **"Save"**

### For store-logos bucket:
1. Click on **store-logos** bucket  
2. Click **"Policies"** tab
3. Click **"New Policy"**
4. Choose **"Custom"**
5. Add this policy:

```sql
-- Allow authenticated users to upload  
CREATE POLICY "Allow upload to store-logos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'store-logos');
```

6. Click **"Save"**

## Step 3: Alternative - Use Pre-built Policy Templates

If custom policies don't work, try these templates:

1. **In Policies tab, click "New Policy"**
2. **Select "Get started quickly" templates**
3. **Choose "Allow public access"** for both buckets
4. **This will create basic read/write policies**

## Step 4: Verify Bucket Configuration

1. **Check bucket settings:**
   - Both buckets should show as **"Public"**
   - Policies should be **"Enabled"**

2. **Test with simple upload:**
   - Try uploading a test file through the dashboard
   - If this works, your app uploads should work too

## Step 5: Alternative App-Level Fix

If dashboard method still doesn't work, let's modify the app to handle the permission issue:

Update the storage upload method to use a simpler approach without RLS dependency.

## 🚨 Quick Debug Test

Before making changes, let's test current bucket status:

1. Go to **Storage** in Supabase Dashboard
2. Check if you see `store-banners` and `store-logos` buckets
3. If not visible, they need to be created
4. If visible but uploads fail, check the **"Policies"** tab

## Next Steps

After completing the dashboard setup:
1. Restart your Flutter app
2. Test store banner/logo upload
3. Should work without 403 errors

Let me know which buckets you see in your Storage dashboard and I'll provide more specific guidance!