-- Copy and paste this EXACTLY into your Supabase SQL Editor to fix the 403 error

CREATE POLICY "Allow authenticated uploads to store banners"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'store-banners');

CREATE POLICY "Allow public read access to store banners"
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'store-banners');

CREATE POLICY "Allow authenticated uploads to store logos"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'store-logos');

CREATE POLICY "Allow public read access to store logos"
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'store-logos');