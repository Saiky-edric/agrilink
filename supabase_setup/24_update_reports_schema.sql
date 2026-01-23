-- Update reports table with additional fields
-- Run this in Supabase SQL Editor

-- First, drop existing table if you want to recreate it completely
-- WARNING: This will delete all existing reports
-- DROP TABLE IF EXISTS reports CASCADE;

-- Add new columns if table already exists
ALTER TABLE reports 
ADD COLUMN IF NOT EXISTS reporter_name TEXT,
ADD COLUMN IF NOT EXISTS reporter_email TEXT,
ADD COLUMN IF NOT EXISTS target_type TEXT,
ADD COLUMN IF NOT EXISTS target_name TEXT,
ADD COLUMN IF NOT EXISTS reason TEXT,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS resolution TEXT,
ADD COLUMN IF NOT EXISTS attachments TEXT[] DEFAULT '{}';

-- Update existing columns
ALTER TABLE reports 
ALTER COLUMN description DROP NOT NULL,
ALTER COLUMN description SET DEFAULT '';

-- If type column exists as enum, we need to handle it
DO $$ 
BEGIN
    -- Drop the old type column if it's an enum
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'reports' AND column_name = 'type' 
        AND udt_name = 'report_type'
    ) THEN
        ALTER TABLE reports DROP COLUMN type;
    END IF;
END $$;

-- Rename columns if needed
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'reports' AND column_name = 'is_resolved'
    ) THEN
        ALTER TABLE reports DROP COLUMN is_resolved;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'reports' AND column_name = 'image_url'
    ) THEN
        ALTER TABLE reports DROP COLUMN image_url;
    END IF;
END $$;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_target_id ON reports(target_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);

-- Update RLS policies
DROP POLICY IF EXISTS "Users can submit reports" ON reports;
DROP POLICY IF EXISTS "Users can view own reports" ON reports;
DROP POLICY IF EXISTS "Admins can manage reports" ON reports;

-- Recreate policies
CREATE POLICY "Users can submit reports" ON reports 
FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports" ON reports 
FOR SELECT USING (auth.uid() = reporter_id);

CREATE POLICY "Admins can view all reports" ON reports 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Admins can update reports" ON reports 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Users can delete own pending reports" ON reports 
FOR DELETE USING (
    auth.uid() = reporter_id AND status = 'pending'
);

-- Grant necessary permissions
GRANT SELECT, INSERT ON reports TO authenticated;
GRANT UPDATE, DELETE ON reports TO authenticated;

COMMENT ON TABLE reports IS 'Content moderation reports for products, users, and orders';
COMMENT ON COLUMN reports.status IS 'pending, resolved, dismissed';
COMMENT ON COLUMN reports.target_type IS 'product, user, or order';
