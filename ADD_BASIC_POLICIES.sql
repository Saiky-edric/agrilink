-- =============================================
-- ADD BASIC POLICIES FOR STORE BUCKETS
-- This will fix the 403 error by allowing uploads
-- =============================================

-- Create basic policies for store-banners bucket
CREATE POLICY "Enable insert for authenticated users on store banners"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'store-banners');

CREATE POLICY "Enable select for everyone on store banners"
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'store-banners');

CREATE POLICY "Enable update for authenticated users on store banners"
ON storage.objects FOR UPDATE 
TO authenticated 
USING (bucket_id = 'store-banners');

CREATE POLICY "Enable delete for authenticated users on store banners"
ON storage.objects FOR DELETE 
TO authenticated 
USING (bucket_id = 'store-banners');

-- Create basic policies for store-logos bucket
CREATE POLICY "Enable insert for authenticated users on store logos"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'store-logos');

CREATE POLICY "Enable select for everyone on store logos"
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'store-logos');

CREATE POLICY "Enable update for authenticated users on store logos"
ON storage.objects FOR UPDATE 
TO authenticated 
USING (bucket_id = 'store-logos');

CREATE POLICY "Enable delete for authenticated users on store logos"
ON storage.objects FOR DELETE 
TO authenticated 
USING (bucket_id = 'store-logos');