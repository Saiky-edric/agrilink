# 🚀 Agrilink Digital Marketplace - Supabase Setup Guide

## 📋 Prerequisites
1. Create a Supabase account at [supabase.com](https://supabase.com)
2. Create a new Supabase project

## 🛠️ Setup Instructions

### Step 1: Database Schema Setup
1. Go to your Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `01_database_schema.sql`
3. Click "Run" to execute the SQL commands
4. Wait for all tables, policies, and indexes to be created

### Step 2: Storage Buckets Setup
1. Copy and paste the contents of `02_storage_buckets.sql`
2. Click "Run" to create storage buckets and policies
3. Verify buckets are created in the Storage section

### Step 3: Realtime Setup
1. Copy and paste the contents of `03_realtime_setup.sql`
2. Click "Run" to enable realtime features
3. This enables live chat and real-time order updates

### Step 4: Sample Data (Optional)
1. Copy and paste the contents of `04_sample_data.sql`
2. Click "Run" to add sample users and products for testing
3. **Note:** You'll need to create actual auth users first, then update the UUIDs

## 🔑 Get Your Project Credentials

### From Supabase Dashboard:
1. Go to **Settings** → **API**
2. Copy these values for your Flutter app:

```
Project URL: https://your-project-id.supabase.co
anon (public) key: eyJ0eXAiOiJKV1QiLCJhbGc...
service_role key: eyJ0eXAiOiJKV1QiLCJhbGc... (Keep this secret!)
```

## 📱 Configure Flutter App

### Update Supabase Credentials:
Edit `lib/core/services/supabase_service.dart`:

```dart
await Supabase.initialize(
  url: 'https://your-project-id.supabase.co',
  anonKey: 'your-anon-key-here',
);
```

## 🗂️ Database Tables Created

| Table | Purpose |
|-------|---------|
| `users` | User profiles and authentication |
| `farmer_verifications` | Farmer verification workflow |
| `products` | Product catalog with images |
| `cart` | Shopping cart items |
| `orders` | Order management |
| `order_items` | Order line items |
| `conversations` | Chat conversations |
| `messages` | Chat messages |
| `feedback` | User feedback |
| `reports` | User reports |

## 📦 Storage Buckets Created

| Bucket | Purpose |
|--------|---------|
| `verification-documents` | Farmer verification files |
| `product-images` | Product photos |
| `report-images` | Report attachments |
| `user-avatars` | User profile pictures |

## 🔄 Realtime Features Enabled

- **Messages**: Live chat between buyers and farmers
- **Conversations**: Real-time conversation updates
- **Orders**: Live order status updates
- **Products**: Real-time stock updates
- **Farmer Verifications**: Live verification status

## 🛡️ Security Features

### Row Level Security (RLS):
- Users can only access their own data
- Farmers can only manage their own products
- Buyers can only see their own orders
- Admins have full access to manage the platform

### Storage Security:
- Users can only upload to their own folders
- Public access for product images
- Private access for verification documents

## 🧪 Testing Your Setup

### 1. Test Authentication:
- Create a user account through your Flutter app
- Verify the user appears in the `users` table

### 2. Test Farmer Verification:
- Create a farmer account
- Upload verification documents
- Check if files appear in the storage bucket

### 3. Test Products:
- Add a product as a verified farmer
- Verify it appears in the `products` table

### 4. Test Orders:
- Place an order as a buyer
- Check if order appears in `orders` and `order_items` tables

### 5. Test Chat:
- Send a message between buyer and farmer
- Verify real-time delivery works

## 🚨 Important Notes

1. **API Keys**: Keep your `service_role` key secret - never expose it in client code
2. **RLS Policies**: All tables have Row Level Security enabled for data protection
3. **Realtime**: Chat and order updates work in real-time through websockets
4. **Storage**: Images are publicly accessible once uploaded
5. **Backup**: Regularly backup your database as you add real data

## 🐛 Troubleshooting

### Common Issues:

1. **RLS Errors**: Make sure auth.uid() returns a valid user ID
2. **Storage Upload Fails**: Check if bucket policies are correctly set
3. **Realtime Not Working**: Verify tables are added to the publication
4. **Query Errors**: Check if all ENUM types are created correctly

### Helpful SQL Queries:

```sql
-- Check if user exists in users table
SELECT * FROM users WHERE id = auth.uid();

-- View all products
SELECT * FROM products WHERE NOT is_hidden;

-- Check storage buckets
SELECT * FROM storage.buckets;

-- View realtime publications
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

## ✅ Setup Complete!

Your Supabase project is now ready for the Agrilink Digital Marketplace! 

The database has:
- ✅ All required tables with proper relationships
- ✅ Row Level Security for data protection
- ✅ Storage buckets for file uploads
- ✅ Realtime features for live updates
- ✅ Indexes for optimal performance

You can now run your Flutter app and start using all the marketplace features! 🎉