-- =============================================
-- COMPLETE STORAGE BUCKET AND RLS FIX
-- Execute this step-by-step in Supabase SQL Editor
-- =============================================

-- STEP 1: Check if buckets exist and create them if missing
INSERT INTO storage.buckets (id, name, public) 
VALUES ('store-banners', 'store-banners', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('store-logos', 'store-logos', true)
ON CONFLICT (id) DO NOTHING;

-- STEP 2: Drop all existing storage policies to start fresh
DROP POLICY IF EXISTS "Users can upload own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view store banners" ON storage.objects;

DROP POLICY IF EXISTS "Users can upload own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view store logos" ON storage.objects;

-- STEP 3: Create simple, working RLS policies

-- Store Banners Policies
CREATE POLICY "Store banners upload policy"
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'store-banners' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Store banners select policy" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'store-banners');

CREATE POLICY "Store banners update policy"
ON storage.objects FOR UPDATE 
USING (
    bucket_id = 'store-banners' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Store banners delete policy"
ON storage.objects FOR DELETE 
USING (
    bucket_id = 'store-banners' AND
    auth.role() = 'authenticated'
);

-- Store Logos Policies  
CREATE POLICY "Store logos upload policy"
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'store-logos' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Store logos select policy"
ON storage.objects FOR SELECT 
USING (bucket_id = 'store-logos');

CREATE POLICY "Store logos update policy"
ON storage.objects FOR UPDATE 
USING (
    bucket_id = 'store-logos' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Store logos delete policy"
ON storage.objects FOR DELETE 
USING (
    bucket_id = 'store-logos' AND
    auth.role() = 'authenticated'
);

-- STEP 4: Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- STEP 5: Grant necessary permissions (if needed)
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;