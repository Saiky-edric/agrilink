-- Agrilink Digital Marketplace - Realtime Setup
-- Execute these SQL commands in your Supabase SQL editor

-- =============================================
-- ENABLE REALTIME FOR TABLES
-- =============================================

-- Enable realtime for messages table (for chat)
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Enable realtime for conversations table (for chat updates)
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Enable realtime for orders table (for order status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Enable realtime for products table (for stock updates)
ALTER PUBLICATION supabase_realtime ADD TABLE products;

-- Enable realtime for farmer_verifications table (for verification status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE farmer_verifications;

-- =============================================
-- TRIGGER FUNCTIONS FOR REALTIME
-- =============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Function to update conversation last message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET 
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- =============================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================

-- Users table trigger
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Products table trigger
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Orders table trigger
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Farmer verifications table trigger
CREATE TRIGGER update_farmer_verifications_updated_at 
    BEFORE UPDATE ON farmer_verifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Conversations table trigger
CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update conversation when new message is inserted
CREATE TRIGGER update_conversation_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();