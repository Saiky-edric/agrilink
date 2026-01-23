-- Agrilink Digital Marketplace - Sample Data
-- Execute these SQL commands in your Supabase SQL editor (OPTIONAL)
-- This creates sample data for testing the application

-- =============================================
-- SAMPLE ADMIN USER
-- =============================================
-- Note: This user will need to be created through Supabase Auth first
-- Then update the users table with the correct UUID from auth.users

-- Insert sample admin (replace 'ADMIN_UUID_HERE' with actual admin UUID from auth.users)
INSERT INTO users (id, email, full_name, phone_number, role, municipality, barangay, street) VALUES
('00000000-0000-0000-0000-000000000001', 'admin@agrilink.com', 'System Administrator', '09123456789', 'admin', 'Prosperidad', 'Poblacion', '123 Admin Street')
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- SAMPLE BUYERS
-- =============================================
-- Note: These users will need to be created through Supabase Auth first

INSERT INTO users (id, email, full_name, phone_number, role, municipality, barangay, street) VALUES
('00000000-0000-0000-0000-000000000002', 'buyer1@example.com', 'Maria Santos', '09111111111', 'buyer', 'Bayugan', 'Poblacion', '456 Buyer Street'),
('00000000-0000-0000-0000-000000000003', 'buyer2@example.com', 'Juan Dela Cruz', '09222222222', 'buyer', 'Bunawan', 'San Mateo', '789 Customer Ave')
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- SAMPLE FARMERS
-- =============================================

INSERT INTO users (id, email, full_name, phone_number, role, municipality, barangay, street) VALUES
('00000000-0000-0000-0000-000000000004', 'farmer1@example.com', 'Pedro Magbago', '09333333333', 'farmer', 'La Paz', 'New Visayas', '123 Farm Road'),
('00000000-0000-0000-0000-000000000005', 'farmer2@example.com', 'Rosa Magtanim', '09444444444', 'farmer', 'Esperanza', 'Poblacion', '456 Agriculture St')
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- SAMPLE FARMER VERIFICATIONS
-- =============================================

INSERT INTO farmer_verifications (farmer_id, farm_name, farm_address, farmer_id_image_url, barangay_cert_image_url, selfie_image_url, status) VALUES
('00000000-0000-0000-0000-000000000004', 'Magbago Organic Farm', 'Sitio Malaking Lupa, New Visayas, La Paz', 'https://example.com/farmer1-id.jpg', 'https://example.com/farmer1-cert.jpg', 'https://example.com/farmer1-selfie.jpg', 'approved'),
('00000000-0000-0000-0000-000000000005', 'Magtanim Family Farm', 'Purok 3, Poblacion, Esperanza', 'https://example.com/farmer2-id.jpg', 'https://example.com/farmer2-cert.jpg', 'https://example.com/farmer2-selfie.jpg', 'approved')
ON CONFLICT (farmer_id) DO NOTHING;

-- =============================================
-- SAMPLE PRODUCTS
-- =============================================

INSERT INTO products (farmer_id, name, price, stock, unit, shelf_life_days, category, description, cover_image_url, farm_name, farm_location) VALUES
('00000000-0000-0000-0000-000000000004', 'Fresh Tomatoes', 25.00, 50, 'kg', 5, 'vegetables', 'Fresh, organically grown tomatoes from our pesticide-free farm. Perfect for cooking and salads.', 'https://example.com/tomatoes.jpg', 'Magbago Organic Farm', 'La Paz, Agusan del Sur'),
('00000000-0000-0000-0000-000000000004', 'Organic Lettuce', 15.00, 30, 'bundle', 3, 'vegetables', 'Crispy, fresh lettuce grown organically. Great for salads and sandwiches.', 'https://example.com/lettuce.jpg', 'Magbago Organic Farm', 'La Paz, Agusan del Sur'),
('00000000-0000-0000-0000-000000000005', 'Sweet Corn', 20.00, 40, 'pieces', 7, 'vegetables', 'Sweet and juicy corn, freshly harvested. Perfect for boiling or grilling.', 'https://example.com/corn.jpg', 'Magtanim Family Farm', 'Esperanza, Agusan del Sur'),
('00000000-0000-0000-0000-000000000005', 'Fresh Bananas', 30.00, 60, 'kg', 4, 'fruits', 'Naturally sweet bananas, freshly picked from our farm. Rich in potassium and vitamins.', 'https://example.com/bananas.jpg', 'Magtanim Family Farm', 'Esperanza, Agusan del Sur'),
('00000000-0000-0000-0000-000000000004', 'Farm Fresh Eggs', 8.00, 100, 'pieces', 10, 'others', 'Fresh eggs from free-range chickens. Rich in protein and perfect for any meal.', 'https://example.com/eggs.jpg', 'Magbago Organic Farm', 'La Paz, Agusan del Sur');

-- =============================================
-- SAMPLE ORDERS (OPTIONAL)
-- =============================================

INSERT INTO orders (buyer_id, farmer_id, total_amount, delivery_address, buyer_status, farmer_status) VALUES
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', 65.00, '456 Buyer Street, Poblacion, Bayugan', 'toReceive', 'toDeliver'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000005', 50.00, '789 Customer Ave, San Mateo, Bunawan', 'completed', 'completed');

-- Note: You would also need to insert corresponding order_items for these orders