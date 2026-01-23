-- =============================================
-- MISSING STORAGE BUCKETS FIX
-- Execute this to add missing store customization buckets
-- =============================================

-- Create missing storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('store-banners', 'store-banners', true);

INSERT INTO storage.buckets (id, name, public) VALUES 
('store-logos', 'store-logos', true);

-- =============================================
-- STORE BANNERS POLICIES
-- =============================================

-- Users can upload their own store banners
CREATE POLICY "Users can upload own store banners" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'store-banners' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view store banners (public)
CREATE POLICY "Anyone can view store banners" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'store-banners'
);

-- Users can update their own store banners
CREATE POLICY "Users can update own store banners" 
ON storage.objects FOR UPDATE USING (
    bucket_id = 'store-banners' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own store banners
CREATE POLICY "Users can delete own store banners" 
ON storage.objects FOR DELETE USING (
    bucket_id = 'store-banners' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- =============================================
-- STORE LOGOS POLICIES
-- =============================================

-- Users can upload their own store logos
CREATE POLICY "Users can upload own store logos" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'store-logos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view store logos (public)
CREATE POLICY "Anyone can view store logos" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'store-logos'
);

-- Users can update their own store logos
CREATE POLICY "Users can update own store logos" 
ON storage.objects FOR UPDATE USING (
    bucket_id = 'store-logos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own store logos
CREATE POLICY "Users can delete own store logos" 
ON storage.objects FOR DELETE USING (
    bucket_id = 'store-logos' AND
    auth.uid()::text = (storage.foldername(name))[1]
);