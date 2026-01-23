-- =============================================
-- STORAGE RLS POLICY FIX FOR STORE CUSTOMIZATION
-- Execute this in Supabase SQL Editor to fix upload permissions
-- =============================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store banners" ON storage.objects;  
DROP POLICY IF EXISTS "Users can delete own store banners" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view store banners" ON storage.objects;

DROP POLICY IF EXISTS "Users can upload own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own store logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own store logos" ON storage.objects;  
DROP POLICY IF EXISTS "Anyone can view store logos" ON storage.objects;

-- =============================================
-- FIXED STORE BANNERS POLICIES
-- =============================================

-- Users can upload store banners to their own folder
CREATE POLICY "Users can upload own store banners" 
ON storage.objects 
FOR INSERT 
WITH CHECK (
    bucket_id = 'store-banners' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own store banners
CREATE POLICY "Users can update own store banners" 
ON storage.objects 
FOR UPDATE 
USING (
    bucket_id = 'store-banners' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own store banners  
CREATE POLICY "Users can delete own store banners" 
ON storage.objects 
FOR DELETE 
USING (
    bucket_id = 'store-banners' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Anyone can view store banners (public)
CREATE POLICY "Anyone can view store banners" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'store-banners');

-- =============================================
-- FIXED STORE LOGOS POLICIES  
-- =============================================

-- Users can upload store logos to their own folder
CREATE POLICY "Users can upload own store logos" 
ON storage.objects 
FOR INSERT 
WITH CHECK (
    bucket_id = 'store-logos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own store logos
CREATE POLICY "Users can update own store logos" 
ON storage.objects 
FOR UPDATE 
USING (
    bucket_id = 'store-logos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own store logos
CREATE POLICY "Users can delete own store logos" 
ON storage.objects 
FOR DELETE 
USING (
    bucket_id = 'store-logos' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Anyone can view store logos (public)
CREATE POLICY "Anyone can view store logos" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'store-logos');