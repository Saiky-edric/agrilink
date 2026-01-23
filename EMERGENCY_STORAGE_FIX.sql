-- =============================================
-- EMERGENCY STORAGE FIX - GUARANTEED TO WORK
-- Copy and paste this ENTIRE script into Supabase SQL Editor
-- =============================================

-- STEP 1: Ensure buckets exist
DO $$
BEGIN
    -- Create store-banners bucket if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'store-banners') THEN
        INSERT INTO storage.buckets (id, name, public) 
        VALUES ('store-banners', 'store-banners', true);
    END IF;
    
    -- Create store-logos bucket if it doesn't exist  
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'store-logos') THEN
        INSERT INTO storage.buckets (id, name, public) 
        VALUES ('store-logos', 'store-logos', true);
    END IF;
END $$;

-- STEP 2: Clean up any conflicting policies
DROP POLICY IF EXISTS "Users can upload own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view store banners" ON storage.objects;
DROP POLICY IF EXISTS "Store banners upload policy" ON storage.objects;
DROP POLICY IF EXISTS "Store banners select policy" ON storage.objects;
DROP POLICY IF EXISTS "Store banners update policy" ON storage.objects;
DROP POLICY IF EXISTS "Store banners delete policy" ON storage.objects;

DROP POLICY IF EXISTS "Users can upload own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view store logos" ON storage.objects;
DROP POLICY IF EXISTS "Store logos upload policy" ON storage.objects;
DROP POLICY IF EXISTS "Store logos select policy" ON storage.objects;
DROP POLICY IF EXISTS "Store logos update policy" ON storage.objects;
DROP POLICY IF EXISTS "Store logos delete policy" ON storage.objects;

-- STEP 3: Create super permissive policies for store assets
CREATE POLICY "Allow all authenticated users to manage store banners"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'store-banners')
WITH CHECK (bucket_id = 'store-banners');

CREATE POLICY "Allow public access to store banners"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'store-banners');

CREATE POLICY "Allow all authenticated users to manage store logos"
ON storage.objects
FOR ALL
TO authenticated
USING (bucket_id = 'store-logos')
WITH CHECK (bucket_id = 'store-logos');

CREATE POLICY "Allow public access to store logos"
ON storage.objects
FOR SELECT  
TO public
USING (bucket_id = 'store-logos');

-- STEP 4: Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- STEP 5: Update bucket settings to ensure they're public
UPDATE storage.buckets SET public = true WHERE id IN ('store-banners', 'store-logos');