-- =============================================
-- SUBSCRIPTION SYSTEM FOR AGRILINK
-- =============================================
-- Adds subscription tier fields to users table for freemium model

-- Add subscription columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium')),
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS subscription_started_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Create index for faster subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_tier ON public.users(subscription_tier);
CREATE INDEX IF NOT EXISTS idx_users_subscription_expires ON public.users(subscription_expires_at) WHERE subscription_expires_at IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.users.subscription_tier IS 'Subscription tier: free (up to 5 products) or premium (unlimited products)';
COMMENT ON COLUMN public.users.subscription_expires_at IS 'Expiration date for premium subscription. NULL means free tier or never expires.';
COMMENT ON COLUMN public.users.subscription_started_at IS 'Date when current premium subscription started';

-- =============================================
-- SUBSCRIPTION HISTORY TABLE (Optional - for tracking)
-- =============================================
-- Tracks subscription payment history and renewals

CREATE TABLE IF NOT EXISTS public.subscription_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('free', 'premium')),
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    payment_method TEXT DEFAULT 'manual', -- 'manual', 'gcash', 'bank_transfer', etc.
    payment_reference TEXT, -- GCash reference number, bank transaction ID, etc.
    payment_proof_url TEXT, -- URL to screenshot of payment proof
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired', 'cancelled')),
    notes TEXT, -- Admin notes about the payment
    verified_by UUID REFERENCES public.users(id), -- Admin who verified the payment
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.subscription_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for subscription_history
CREATE POLICY "Users can view their own subscription history"
    ON public.subscription_history
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own subscription records"
    ON public.subscription_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all subscription history"
    ON public.subscription_history
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update subscription history"
    ON public.subscription_history
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Indexes for subscription_history
CREATE INDEX IF NOT EXISTS idx_subscription_history_user_id ON public.subscription_history(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_history_status ON public.subscription_history(status);
CREATE INDEX IF NOT EXISTS idx_subscription_history_expires_at ON public.subscription_history(expires_at);

-- =============================================
-- HELPER FUNCTION: Check if user is premium
-- =============================================
CREATE OR REPLACE FUNCTION public.is_user_premium(user_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = user_id_param
        AND subscription_tier = 'premium'
        AND (subscription_expires_at IS NULL OR subscription_expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- HELPER FUNCTION: Get product count for user
-- =============================================
CREATE OR REPLACE FUNCTION public.get_user_product_count(user_id_param UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.products
        WHERE farmer_id = user_id_param
        AND is_hidden = FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- TRIGGER: Auto-expire subscriptions
-- =============================================
-- Function to check and update expired subscriptions
CREATE OR REPLACE FUNCTION public.check_expired_subscriptions()
RETURNS void AS $$
BEGIN
    UPDATE public.users
    SET subscription_tier = 'free'
    WHERE subscription_tier = 'premium'
    AND subscription_expires_at IS NOT NULL
    AND subscription_expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: You can run this function periodically via a cron job or scheduled task
-- For now, we'll check subscription status at runtime in the app

-- =============================================
-- UPDATE: Modify products query for premium priority
-- =============================================
-- This is a reference for how to query products with premium sellers first
-- Use this pattern in your app queries:

/*
SELECT p.*, u.subscription_tier, u.full_name as farmer_name
FROM public.products p
LEFT JOIN public.users u ON p.farmer_id = u.id
WHERE p.is_hidden = FALSE
ORDER BY 
    CASE 
        WHEN u.subscription_tier = 'premium' 
        AND (u.subscription_expires_at IS NULL OR u.subscription_expires_at > NOW())
        THEN 0 
        ELSE 1 
    END,
    p.created_at DESC;
*/

-- =============================================
-- INITIAL DATA: Set all existing users to free tier
-- =============================================
UPDATE public.users
SET subscription_tier = 'free'
WHERE subscription_tier IS NULL;

-- =============================================
-- GRANT PERMISSIONS
-- =============================================
GRANT SELECT ON public.subscription_history TO authenticated, anon;
GRANT INSERT ON public.subscription_history TO authenticated;
GRANT UPDATE ON public.subscription_history TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.is_user_premium(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_user_product_count(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.check_expired_subscriptions() TO authenticated;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================
-- Run these to verify the setup:

-- Check if columns were added
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' 
-- AND column_name IN ('subscription_tier', 'subscription_expires_at', 'subscription_started_at');

-- Check subscription distribution
-- SELECT subscription_tier, COUNT(*) as user_count
-- FROM public.users
-- GROUP BY subscription_tier;

-- List premium users
-- SELECT id, email, full_name, subscription_tier, subscription_expires_at
-- FROM public.users
-- WHERE subscription_tier = 'premium';
