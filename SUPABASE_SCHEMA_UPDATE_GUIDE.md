# Supabase Schema Updates for Admin Features

## Overview
This guide explains the SQL schema changes needed to support the new admin dashboard features in your Flutter app.

## 🔧 Required Schema Updates

### New File Created:
- `supabase_setup/06_admin_features_schema.sql` - Contains all the admin feature schema updates

### What's Added:

1. **New Tables:**
   - `admin_activities` - Tracks admin actions and system events
   - `reports` - Handles user reports and content moderation
   - `platform_settings` - Stores app configuration settings

2. **New Columns:**
   - `profiles.is_active` - Track user active/suspended status
   - `farmer_verifications.*` - Additional fields for verification workflow

3. **Analytics Views:**
   - `user_statistics` - User count and role statistics
   - `order_analytics` - Order status and metrics
   - `product_analytics` - Product inventory statistics

4. **Admin Functions:**
   - `get_platform_analytics()` - Comprehensive platform metrics
   - `toggle_user_status()` - Admin function to suspend/activate users

## 🚀 How to Apply the Updates

### Option 1: Supabase Dashboard (Recommended)

1. **Open your Supabase project dashboard**
2. **Go to SQL Editor**
3. **Copy and paste the content from `supabase_setup/06_admin_features_schema.sql`**
4. **Click "Run" to execute the SQL**

### Option 2: Supabase CLI

```bash
# Make sure you're logged in to Supabase CLI
supabase login

# Link to your project (if not already linked)
supabase link --project-ref YOUR_PROJECT_REF

# Apply the migration
supabase db push
```

### Option 3: psql Command Line

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"

# Run the migration file
\i supabase_setup/06_admin_features_schema.sql
```

## 🔒 Security & Permissions

The schema includes proper Row Level Security (RLS) policies:

- **Admin Activities**: Only admins can view/create
- **Reports**: Users can view their own reports, admins can view all
- **Platform Settings**: Only admins can view/modify
- **User Management**: New functions require admin permissions

## 📊 New Admin Capabilities

After applying these updates, your admin users will be able to:

1. **User Management:**
   - View all users with filtering
   - Suspend/activate user accounts
   - Delete user accounts
   - View user statistics

2. **Content Moderation:**
   - View and manage user reports
   - Resolve content issues
   - Track moderation activities

3. **Verification Management:**
   - Approve/reject farmer verifications
   - View verification documents
   - Track verification status

4. **Platform Analytics:**
   - View comprehensive dashboard metrics
   - Monitor user growth
   - Track order and product statistics
   - Revenue analytics

5. **System Administration:**
   - Configure platform settings
   - Monitor admin activities
   - System maintenance controls

## 🧪 Testing the Updates

After applying the schema, you can test by:

1. **Creating an admin user:**
```sql
UPDATE profiles SET role = 'admin' WHERE email = 'your-admin@email.com';
```

2. **Testing analytics function:**
```sql
SELECT get_platform_analytics();
```

3. **Checking new tables:**
```sql
SELECT * FROM admin_activities;
SELECT * FROM reports;
SELECT * FROM platform_settings;
```

## 📱 App Configuration

After applying the schema updates:

1. **Update your app's environment configuration**
2. **Test admin login and dashboard access**
3. **Verify all admin features work correctly**

## 🔄 Rollback (if needed)

If you need to rollback these changes:

```sql
-- Drop new tables
DROP TABLE IF EXISTS admin_activities CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS platform_settings CASCADE;

-- Drop new columns (be careful with this)
-- ALTER TABLE profiles DROP COLUMN IF EXISTS is_active;

-- Drop views
DROP VIEW IF EXISTS user_statistics;
DROP VIEW IF EXISTS order_analytics;
DROP VIEW IF EXISTS product_analytics;

-- Drop functions
DROP FUNCTION IF EXISTS get_platform_analytics();
DROP FUNCTION IF EXISTS toggle_user_status(UUID, BOOLEAN);
```

## 📝 Notes

- The migration is designed to be safe and non-destructive
- Existing data will not be affected
- All new features are backward compatible
- Default admin settings are automatically created

## 🆘 Support

If you encounter any issues:

1. Check the Supabase logs for detailed error messages
2. Ensure your database user has sufficient permissions
3. Verify that all required base tables exist from previous migrations

The schema updates should resolve all the compilation errors and provide full admin functionality for your Flutter app!