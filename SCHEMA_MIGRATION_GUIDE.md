# 📊 Database Schema Migration Guide

## 🎯 **Overview**
Your current Agrilink app has been modernized with new features that require database schema updates to support:

- ✅ **User Addresses** - Multiple delivery addresses per user
- ✅ **Payment Methods** - Multiple payment cards per user  
- ✅ **Favorites** - Users can favorite products
- ✅ **Reviews & Ratings** - Product review system
- ✅ **Notifications** - In-app notification system
- ✅ **User Settings** - Personalized app preferences

## 🔄 **Migration Steps**

### 1. **Execute Schema Updates**
Run the new SQL file in your Supabase SQL editor:
```sql
-- Execute: supabase_setup/05_schema_improvements.sql
```

### 2. **Update Storage Buckets** 
Your existing storage buckets are sufficient, but you may want to add:
```sql
-- Optional: Create bucket for notification images
INSERT INTO storage.buckets (id, name, public) VALUES 
('notification-images', 'notification-images', true);
```

## 📋 **New Tables Added**

### **user_addresses**
- Supports multiple delivery addresses per user
- Default address functionality
- Municipality, barangay, street address fields

### **payment_methods**
- Multiple payment cards per user
- Secure storage (only last 4 digits stored)
- Default payment method support

### **user_favorites** 
- Users can favorite/unfavorite products
- Prevents duplicate favorites per user

### **product_reviews**
- 5-star rating system
- Optional review text
- One review per user per product

### **notifications**
- In-app notifications system
- Different types: order, message, product, system
- Read/unread status tracking

### **user_settings**
- Push/email/SMS notification preferences
- Dark mode toggle
- Language preferences

## 🔧 **Enhanced Existing Tables**

### **users table** - Added:
- `phone` - Phone number field
- `avatar_url` - Profile picture URL
- `date_of_birth` - User's birth date
- `gender` - User's gender

### **products table** - Added:
- `is_featured` - Featured products for homepage
- `discount_percentage` - Product discounts
- `tags` - Product tags array
- `harvest_date` - When product was harvested
- `image_urls` - Multiple product images

### **orders table** - Added:
- `tracking_number` - Order tracking
- `delivery_date` - Scheduled delivery
- `delivery_notes` - Special delivery instructions
- `payment_method_id` - Link to payment method used
- `delivery_address_id` - Link to delivery address used

## 📈 **Performance Improvements**

### **New Indexes Added:**
- User addresses and payment methods indexes
- Favorites and reviews performance indexes
- Featured products and discounts indexes
- Notifications unread messages indexes

## 🔐 **Security (RLS Policies)**

All new tables include Row Level Security policies:
- ✅ Users can only access their own data
- ✅ Public read access for reviews
- ✅ Proper authentication checks

## 🚀 **New Functions Added**

### **Helper Functions:**
- `get_user_default_address(user_uuid)` - Get user's default address
- `set_default_address(user_uuid, address_uuid)` - Set default address
- `set_default_payment_method(user_uuid, method_uuid)` - Set default payment
- `get_product_rating(product_uuid)` - Calculate average product rating

## 📱 **App Features Now Supported**

### ✅ **Profile Screen:**
- Edit profile with phone, avatar
- Manage multiple addresses
- Manage payment methods
- View favorite products
- Access help and support

### ✅ **Product Features:**
- Featured products on homepage
- Product discounts and deals
- Multiple product images
- Rating and review system

### ✅ **Enhanced Shopping:**
- Multiple delivery addresses
- Saved payment methods
- Order tracking numbers
- Delivery scheduling

### ✅ **User Experience:**
- In-app notifications
- Personalized settings
- Dark mode support
- Favorite products

## ⚠️ **Migration Notes**

1. **Backup First**: Always backup your database before running migrations
2. **Test Environment**: Run migrations in staging first
3. **App Compatibility**: The app code already supports these features
4. **Sample Data**: Update your sample data to include new fields

## 🔄 **After Migration**

Your app will support:
- ✅ Complete profile management
- ✅ Multiple addresses and payment methods  
- ✅ Product favorites and reviews
- ✅ Rich notifications system
- ✅ Personalized user settings
- ✅ Enhanced product features

## 📞 **Support**

If you encounter any issues during migration:
1. Check Supabase logs for error details
2. Verify RLS policies are working correctly
3. Test new features in the app after migration
4. Ensure all indexes are created properly

Your modern Agrilink app is now ready for production with a complete, scalable database schema! 🎉