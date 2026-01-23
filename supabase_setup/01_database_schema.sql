-- Agrilink Digital Marketplace - Complete Database Schema
-- Execute these SQL commands in your Supabase SQL editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types for better data consistency
CREATE TYPE user_role AS ENUM ('buyer', 'farmer', 'admin');
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected', 'needsResubmit');
CREATE TYPE product_category AS ENUM ('vegetables', 'fruits', 'grains', 'herbs', 'livestock', 'dairy', 'others');
CREATE TYPE buyer_order_status AS ENUM ('pending', 'toShip', 'toReceive', 'completed', 'cancelled');
CREATE TYPE farmer_order_status AS ENUM ('newOrder', 'toPack', 'toDeliver', 'completed', 'cancelled');
CREATE TYPE report_type AS ENUM ('product', 'user', 'order');

-- =============================================
-- USERS TABLE
-- =============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'buyer',
    municipality TEXT,
    barangay TEXT,
    street TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read and update their own profile
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- =============================================
-- FARMER VERIFICATIONS TABLE
-- =============================================
CREATE TABLE farmer_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    farm_name TEXT NOT NULL,
    farm_address TEXT NOT NULL,
    farmer_id_image_url TEXT NOT NULL,
    barangay_cert_image_url TEXT NOT NULL,
    selfie_image_url TEXT NOT NULL,
    status verification_status DEFAULT 'pending',
    rejection_reason TEXT,
    admin_notes TEXT,
    reviewed_by_admin_id UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE farmer_verifications ENABLE ROW LEVEL SECURITY;

-- Farmers can view their own verification
CREATE POLICY "Farmers can view own verification" ON farmer_verifications 
FOR SELECT USING (auth.uid() = farmer_id);

-- Farmers can insert their own verification
CREATE POLICY "Farmers can insert own verification" ON farmer_verifications 
FOR INSERT WITH CHECK (auth.uid() = farmer_id);

-- Admins can view and update all verifications
CREATE POLICY "Admins can manage verifications" ON farmer_verifications 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- PRODUCTS TABLE
-- =============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    unit TEXT NOT NULL,
    shelf_life_days INTEGER NOT NULL CHECK (shelf_life_days > 0),
    category product_category NOT NULL,
    description TEXT NOT NULL,
    cover_image_url TEXT NOT NULL,
    additional_image_urls TEXT[] DEFAULT '{}',
    farm_name TEXT NOT NULL,
    farm_location TEXT NOT NULL,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Anyone can view non-hidden products
CREATE POLICY "Anyone can view available products" ON products 
FOR SELECT USING (NOT is_hidden);

-- Farmers can manage their own products
CREATE POLICY "Farmers can manage own products" ON products 
FOR ALL USING (auth.uid() = farmer_id);

-- Admins can view and hide/unhide products
CREATE POLICY "Admins can manage products" ON products 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- SHOPPING CART TABLE
-- =============================================
CREATE TABLE cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

ALTER TABLE cart ENABLE ROW LEVEL SECURITY;

-- Users can manage their own cart
CREATE POLICY "Users can manage own cart" ON cart 
FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- ORDERS TABLE
-- =============================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount > 0),
    delivery_address TEXT NOT NULL,
    special_instructions TEXT,
    buyer_status buyer_order_status DEFAULT 'pending',
    farmer_status farmer_order_status DEFAULT 'newOrder',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Buyers and farmers can view their own orders
CREATE POLICY "Buyers can view own orders" ON orders 
FOR SELECT USING (auth.uid() = buyer_id);

CREATE POLICY "Farmers can view own orders" ON orders 
FOR SELECT USING (auth.uid() = farmer_id);

-- Buyers can update their order status
CREATE POLICY "Buyers can update own orders" ON orders 
FOR UPDATE USING (auth.uid() = buyer_id);

-- Farmers can update their order status
CREATE POLICY "Farmers can update own orders" ON orders 
FOR UPDATE USING (auth.uid() = farmer_id);

-- =============================================
-- ORDER ITEMS TABLE
-- =============================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit TEXT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal > 0)
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Users can view order items for their orders
CREATE POLICY "Users can view own order items" ON order_items 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM orders 
        WHERE id = order_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid())
    )
);

-- =============================================
-- CONVERSATIONS TABLE (FOR CHAT)
-- =============================================
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(buyer_id, farmer_id)
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Users can view conversations they're part of
CREATE POLICY "Users can view own conversations" ON conversations 
FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = farmer_id);

-- Users can create conversations
CREATE POLICY "Users can create conversations" ON conversations 
FOR INSERT WITH CHECK (auth.uid() = buyer_id OR auth.uid() = farmer_id);

-- Users can update conversations they're part of
CREATE POLICY "Users can update own conversations" ON conversations 
FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = farmer_id);

-- =============================================
-- MESSAGES TABLE (FOR CHAT)
-- =============================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can view messages from their conversations
CREATE POLICY "Users can view conversation messages" ON messages 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversations 
        WHERE id = conversation_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid())
    )
);

-- Users can send messages to their conversations
CREATE POLICY "Users can send messages" ON messages 
FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM conversations 
        WHERE id = conversation_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid())
    )
);

-- Users can mark their messages as read
CREATE POLICY "Users can update message status" ON messages 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM conversations 
        WHERE id = conversation_id AND (buyer_id = auth.uid() OR farmer_id = auth.uid())
    )
);

-- =============================================
-- FEEDBACK TABLE
-- =============================================
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can submit their own feedback
CREATE POLICY "Users can submit feedback" ON feedback 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can view all feedback
CREATE POLICY "Admins can view feedback" ON feedback 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- REPORTS TABLE
-- =============================================
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    target_id UUID NOT NULL,
    type report_type NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can submit reports
CREATE POLICY "Users can submit reports" ON reports 
FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Users can view their own reports
CREATE POLICY "Users can view own reports" ON reports 
FOR SELECT USING (auth.uid() = reporter_id);

-- Admins can view and manage all reports
CREATE POLICY "Admins can manage reports" ON reports 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Products indexes
CREATE INDEX idx_products_farmer_id ON products(farmer_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_created_at ON products(created_at DESC);
CREATE INDEX idx_products_is_hidden ON products(is_hidden);

-- Orders indexes
CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_farmer_id ON orders(farmer_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Messages indexes
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Conversations indexes
CREATE INDEX idx_conversations_buyer_id ON conversations(buyer_id);
CREATE INDEX idx_conversations_farmer_id ON conversations(farmer_id);

-- Farmer verifications indexes
CREATE INDEX idx_farmer_verifications_farmer_id ON farmer_verifications(farmer_id);
CREATE INDEX idx_farmer_verifications_status ON farmer_verifications(status);