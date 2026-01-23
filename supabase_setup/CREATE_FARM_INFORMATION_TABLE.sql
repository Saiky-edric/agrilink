-- CREATE_FARM_INFORMATION_TABLE.sql
-- Purpose: Create table to store farmer's farm information details
-- This enables the "About Our Farm" section on public farmer profiles
-- Location is auto-populated from farmer's profile (municipality + barangay)

BEGIN;

-- Create farm_information table
CREATE TABLE IF NOT EXISTS public.farm_information (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  farmer_id uuid NOT NULL UNIQUE,
  location text NOT NULL DEFAULT '', -- Auto-filled from users table (barangay, municipality)
  size text NOT NULL DEFAULT '',
  years_experience integer NOT NULL DEFAULT 0,
  primary_crops text[] DEFAULT ARRAY[]::text[],
  farming_methods text[] DEFAULT ARRAY[]::text[],
  description text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT farm_information_pkey PRIMARY KEY (id),
  CONSTRAINT farm_information_farmer_id_fkey FOREIGN KEY (farmer_id) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Create index for faster lookups by farmer_id
CREATE INDEX IF NOT EXISTS idx_farm_information_farmer_id ON public.farm_information(farmer_id);

-- Enable Row Level Security
ALTER TABLE public.farm_information ENABLE ROW LEVEL SECURITY;

-- RLS Policies for farm_information

-- 1. Anyone can view farm information (for public profiles)
CREATE POLICY "Anyone can view farm information"
ON public.farm_information
FOR SELECT
USING (true);

-- 2. Farmers can insert their own farm information
CREATE POLICY "Farmers can insert own farm information"
ON public.farm_information
FOR INSERT
WITH CHECK (
  auth.uid() = farmer_id
);

-- 3. Farmers can update their own farm information
CREATE POLICY "Farmers can update own farm information"
ON public.farm_information
FOR UPDATE
USING (auth.uid() = farmer_id)
WITH CHECK (auth.uid() = farmer_id);

-- 4. Farmers can delete their own farm information
CREATE POLICY "Farmers can delete own farm information"
ON public.farm_information
FOR DELETE
USING (auth.uid() = farmer_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_farm_information_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at on every update
DROP TRIGGER IF EXISTS farm_information_updated_at_trigger ON public.farm_information;
CREATE TRIGGER farm_information_updated_at_trigger
  BEFORE UPDATE ON public.farm_information
  FOR EACH ROW
  EXECUTE FUNCTION public.update_farm_information_updated_at();

COMMIT;

-- Verification queries (run these separately to check)
-- SELECT * FROM public.farm_information LIMIT 10;
-- SELECT tablename, policyname, roles, cmd, qual FROM pg_policies WHERE tablename = 'farm_information';

RAISE NOTICE 'Farm information table created successfully!';
RAISE NOTICE 'RLS policies enabled for secure access';
RAISE NOTICE 'Farmers can now save their farm information';
