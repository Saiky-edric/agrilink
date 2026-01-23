-- Agrilink Digital Marketplace - Storage Buckets Setup
-- Execute these SQL commands in your Supabase SQL editor

-- =============================================
-- CREATE STORAGE BUCKETS
-- =============================================

-- Create bucket for farmer verification documents
INSERT INTO storage.buckets (id, name, public) VALUES 
('verification-documents', 'verification-documents', true);

-- Create bucket for product images
INSERT INTO storage.buckets (id, name, public) VALUES 
('product-images', 'product-images', true);

-- Create bucket for report images
INSERT INTO storage.buckets (id, name, public) VALUES 
('report-images', 'report-images', true);

-- Create bucket for user avatars
INSERT INTO storage.buckets (id, name, public) VALUES 
('user-avatars', 'user-avatars', true);

-- Create bucket for store banners  
INSERT INTO storage.buckets (id, name, public) VALUES 
('store-banners', 'store-banners', true);

-- Create bucket for store logos
INSERT INTO storage.buckets (id, name, public) VALUES 
('store-logos', 'store-logos', true);

-- =============================================
-- STORAGE POLICIES
-- =============================================

-- Verification Documents Policies
-- Farmers can upload their own verification documents
CREATE POLICY "Farmers can upload verification documents" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'verification-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Farmers can view their own verification documents
CREATE POLICY "Farmers can view own verification documents" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'verification-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all verification documents
CREATE POLICY "Admins can view all verification documents" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'verification-documents' AND
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Product Images Policies
-- Farmers can upload images for their products
CREATE POLICY "Farmers can upload product images" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'product-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view product images (public)
CREATE POLICY "Anyone can view product images" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'product-images'
);

-- Farmers can delete their own product images
CREATE POLICY "Farmers can delete own product images" 
ON storage.objects FOR DELETE USING (
    bucket_id = 'product-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Report Images Policies
-- Users can upload images for reports
CREATE POLICY "Users can upload report images" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'report-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own report images
CREATE POLICY "Users can view own report images" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'report-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all report images
CREATE POLICY "Admins can view all report images" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'report-images' AND
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- User Avatars Policies
-- Users can upload their own avatars
CREATE POLICY "Users can upload own avatars" 
ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'user-avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view user avatars (public)
CREATE POLICY "Anyone can view user avatars" 
ON storage.objects FOR SELECT USING (
    bucket_id = 'user-avatars'
);

-- Users can update their own avatars
CREATE POLICY "Users can update own avatars" 
ON storage.objects FOR UPDATE USING (
    bucket_id = 'user-avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatars" 
ON storage.objects FOR DELETE USING (
    bucket_id = 'user-avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

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