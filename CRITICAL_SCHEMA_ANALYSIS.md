# 🚨 CRITICAL: Database Schema Foreign Key Inconsistency Analysis

## ❌ Problem Identified

Your current schema has **BOTH** `users` and `profiles` tables with **inconsistent foreign key references** across the database. This creates a major data integrity issue.

## 📊 Foreign Key Analysis

### Tables Referencing `public.users` (❌ PROBLEMATIC)
1. **`cart`** - `user_id` → `public.users(id)`
2. **`conversations`** - `buyer_id` → `public.users(id)`, `farmer_id` → `public.users(id)`
3. **`farmer_verifications`** - `farmer_id` → `public.users(id)`, `reviewed_by_admin_id` → `public.users(id)`
4. **`feedback`** - `user_id` → `public.users(id)`
5. **`messages`** - `sender_id` → `public.users(id)`
6. **`notifications`** - `user_id` → `public.users(id)`
7. **`orders`** - `buyer_id` → `public.users(id)`, `farmer_id` → `public.users(id)`
8. **`payment_methods`** - `user_id` → `public.users(id)`
9. **`product_reviews`** - `user_id` → `public.users(id)`
10. **`products`** - `farmer_id` → `public.users(id)`
11. **`reports`** - `reporter_id` → `public.users(id)`
12. **`user_addresses`** - `user_id` → `public.users(id)`
13. **`user_favorites`** - `user_id` → `public.users(id)`
14. **`user_settings`** - `user_id` → `public.users(id)`

### Tables Referencing `auth.users` (✅ CORRECT)
1. **`admin_activities`** - `user_id` → `auth.users(id)`
2. **`farmer_verifications`** - `reviewed_by` → `auth.users(id)`
3. **`platform_settings`** - `updated_by` → `auth.users(id)`
4. **`profiles`** - `user_id` → `auth.users(id)` ✅ CORRECT
5. **`reports`** - `resolved_by` → `auth.users(id)`

## 🎯 The Core Issue

**Your app code now uses `profiles` table (linked to `auth.users`), but most foreign keys still reference the standalone `users` table.**

This means:
- User authentication works with `auth.users` + `profiles`
- All other features (orders, cart, products, etc.) reference the disconnected `users` table
- **Result**: Complete data disconnection and app failure

## 🔧 Required Fix Strategy

### Option 1: Migrate Everything to Profiles (RECOMMENDED)
1. Update all foreign keys to reference `profiles.user_id` instead of `users.id`
2. Migrate data from `users` to `profiles` 
3. Drop the `users` table
4. Update all foreign key constraints

### Option 2: Keep Users Table and Fix Code
1. Revert code changes to use `users` table
2. Keep `profiles` as supplementary table
3. Sync data between `auth.users` and `users`

**RECOMMENDATION: Option 1** - Cleaner architecture, single source of truth