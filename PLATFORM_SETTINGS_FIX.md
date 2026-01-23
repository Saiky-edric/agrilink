# Platform Settings RLS Issue - Fix

## Problem
When trying to update platform settings from admin dashboard, you get:
```
PostgrestException(message: new row violates row-level security policy for table "platform_settings", code: 42501)
```

## Root Cause
The RLS (Row-Level Security) policies for `platform_settings` table had two issues:

1. **Outdated policy checks**: Policies were checking the `profiles` table for admin role, but the app now uses the `users` table
2. **Missing INSERT policy**: The upsert operation couldn't create new settings because no INSERT policy existed

## Solution
Two files need to be executed in Supabase SQL Editor:

### 1. Run `08_fix_platform_settings_rls.sql`
This file updates the RLS policies to:
- Check admin role from `users` table instead of `profiles`
- Add INSERT policy for creating new settings
- Add DELETE policy for completeness
- Allow public read access (non-authenticated users can read non-sensitive settings)

### 2. Update admin_service.dart
The `updatePlatformSetting()` method was fixed to:
- Check if settings exist before updating
- Create default settings with all required fields if they don't exist
- Update specific fields if settings exist
- Include `updated_by` user ID for audit trails

## Implementation Steps

1. **Supabase Console**:
   - Go to SQL Editor
   - Paste and run contents of `supabase_setup/08_fix_platform_settings_rls.sql`

2. **After SQL execution**:
   - Clear browser cache
   - Log out and log back in
   - Try updating platform settings again

## Affected Features

All platform setting features should now work:
- ✅ Commission rate configuration
- ✅ Delivery fee settings
- ✅ Order value limits
- ✅ Maintenance mode toggle
- ✅ User registration settings
- ✅ Verification requirements
- ✅ Payment methods configuration
- ✅ Shipping zones configuration

## Testing

After applying fixes, verify:
1. Admin can view platform settings
2. Admin can update each setting
3. Changes are saved and persist on reload
4. Activity log records the changes
