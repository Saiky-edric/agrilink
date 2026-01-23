# 🔐 Admin Account Setup Guide - Agrilink Platform

## Overview
This guide shows you how to create and configure admin accounts for the Agrilink Digital Marketplace platform.

## 🎯 Admin Account Setup Methods

### Method 1: Database Direct Insert (Recommended for First Admin)

#### Step 1: Create Admin User in Supabase Auth
1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication > Users**
3. Click **"Add User"**
4. Fill in the admin details:
   ```
   Email: admin@agrilink.ph
   Password: [Your secure password]
   Email Confirm: Yes (check this box)
   ```

#### Step 2: Update User Role in Database
1. Go to **Supabase Dashboard > Table Editor**
2. Open the **`users`** table
3. Find the user you just created
4. Update the **`role`** column from `buyer` to `admin`
5. Update other fields as needed:
   ```sql
   UPDATE users 
   SET 
     role = 'admin',
     full_name = 'System Administrator',
     phone_number = '+63917123456',
     updated_at = NOW()
   WHERE email = 'admin@agrilink.ph';
   ```

### Method 2: SQL Script Setup (For Multiple Admins)

Create and run this SQL script in your Supabase SQL Editor:

```sql
-- Create admin user (you'll need to create the auth user first)
INSERT INTO users (
  id, 
  email, 
  full_name, 
  phone_number, 
  role, 
  municipality,
  barangay,
  created_at
) VALUES (
  'REPLACE_WITH_AUTH_USER_ID',  -- Get this from Supabase Auth after creating user
  'admin@agrilink.ph',
  'System Administrator', 
  '+63917123456',
  'admin',
  'Prosperidad', 
  'Poblacion',
  NOW()
);
```

### Method 3: App-Based Admin Registration (Development)

For development purposes, you can temporarily modify the signup process:

1. **Temporarily modify signup role screen** to include admin option
2. **Create admin account through the app**
3. **Remove admin option** from signup after creation

### Method 4: Programmatic Creation (Advanced)

Create a one-time admin setup script:

```sql
-- One-time admin setup function
CREATE OR REPLACE FUNCTION create_admin_user(
  admin_email TEXT,
  admin_name TEXT,
  admin_phone TEXT
) RETURNS TEXT AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Check if admin already exists
  IF EXISTS (SELECT 1 FROM users WHERE email = admin_email) THEN
    RETURN 'Admin user already exists';
  END IF;
  
  -- Note: You still need to create the auth user manually first
  -- This function only creates the profile record
  
  INSERT INTO users (
    email,
    full_name,
    phone_number,
    role,
    municipality,
    barangay,
    created_at
  ) VALUES (
    admin_email,
    admin_name,
    admin_phone,
    'admin',
    'Prosperidad',
    'Poblacion',
    NOW()
  );
  
  RETURN 'Admin user created successfully';
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT create_admin_user('admin@agrilink.ph', 'Admin User', '+63917123456');
```

## 🚀 Quick Setup (Recommended)

Here's the fastest way to get your first admin account:

### Step 1: Supabase Auth User
1. **Supabase Dashboard** → **Authentication** → **Users** → **Add User**
2. **Email**: `admin@agrilink.ph`
3. **Password**: `Admin123!@#` (change this!)
4. **Confirm Email**: ✅ Checked

### Step 2: Update Database Record
Run this SQL in **Supabase SQL Editor**:

```sql
-- Update the user record to admin role
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'admin@agrilink.ph';

-- Insert or update the profile record
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone_number,
  role,
  municipality,
  barangay,
  street,
  created_at
) VALUES (
  (SELECT id FROM auth.users WHERE email = 'admin@agrilink.ph'),
  'admin@agrilink.ph',
  'System Administrator',
  '+63917123456789',
  'admin',
  'Prosperidad',
  'Poblacion',
  'Admin Office',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  full_name = EXCLUDED.full_name,
  phone_number = EXCLUDED.phone_number,
  municipality = EXCLUDED.municipality,
  barangay = EXCLUDED.barangay,
  street = EXCLUDED.street,
  updated_at = NOW();
```

## 🔒 Admin Account Security

### Password Requirements
- **Minimum 12 characters**
- **Include**: Uppercase, lowercase, numbers, symbols
- **Example**: `AdminAgri2024!@#`

### Security Best Practices
1. **Enable 2FA** (if supported by Supabase)
2. **Use unique admin email** (not personal email)
3. **Regular password rotation** (every 90 days)
4. **Monitor admin activities** through logs

## 🛡️ Admin Permissions

Admins have access to:

### ✅ User Management
- View all users (buyers, farmers, admins)
- Suspend/activate accounts
- View user activity logs
- Manage user roles

### ✅ Farmer Verification
- Review farmer applications
- Approve/reject verifications
- View verification documents
- Manage verification requirements

### ✅ Content Moderation
- Review reported content
- Handle user reports
- Remove inappropriate content
- Moderate chat messages

### ✅ Platform Analytics
- View sales statistics
- Monitor user engagement
- Generate platform reports
- Export data for analysis

### ✅ System Configuration
- Manage platform settings
- Update terms and policies
- Configure notification templates
- Manage featured content

## 🧪 Testing Admin Access

After creating an admin account, test these features:

1. **Login with admin credentials**
2. **Navigate to admin dashboard** (`/admin/dashboard`)
3. **Check user management** (`/admin/users`)
4. **Test verification review** (`/admin/verifications`)
5. **Verify reports access** (`/admin/reports`)

## 🚨 Troubleshooting

### Common Issues

#### "Access Denied" Error
- **Check**: User role is set to 'admin' in database
- **Verify**: Route permissions in app_router.dart
- **Confirm**: Admin routes are accessible

#### "User Not Found"
- **Check**: Auth user exists in Supabase Auth
- **Verify**: Profile record exists in users table
- **Match**: Auth user ID matches profile user ID

#### Cannot Access Admin Features
- **Check**: Role-based navigation is working
- **Verify**: Admin screens are implemented
- **Test**: Route guards are functioning

## 🔄 Managing Multiple Admins

### Creating Additional Admins

1. **Super Admin creates new admin**:
   ```sql
   -- Create additional admin
   INSERT INTO users (
     id,
     email, 
     full_name,
     phone_number,
     role,
     created_at
   ) VALUES (
     'NEW_AUTH_USER_ID',
     'admin2@agrilink.ph',
     'Regional Administrator',
     '+63918123456',
     'admin',
     NOW()
   );
   ```

2. **Admin role hierarchy** (if needed):
   - `super_admin` - Full platform control
   - `admin` - Standard admin functions  
   - `moderator` - Content moderation only

## 📞 Support

If you encounter issues setting up admin accounts:

1. **Check Supabase logs** for authentication errors
2. **Verify database constraints** are met
3. **Test with simple SQL queries** first
4. **Contact support** if issues persist

---

**Security Note**: Always use secure passwords and limit admin access to authorized personnel only. Regularly audit admin accounts and remove unused ones.