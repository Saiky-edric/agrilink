-- =============================================
-- SIMPLE BUCKET CREATION (Safe Method)
-- Run ONLY this if you don't see the buckets in Storage Dashboard
-- =============================================

-- Only create buckets - no RLS policy changes
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES 
('store-banners', 'store-banners', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 52428800;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES 
('store-logos', 'store-logos', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])  
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  file_size_limit = 52428800;