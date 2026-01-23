# 🌾 Farm Information Database Setup Guide

## Problem

You tried to save farm information but it didn't work. This is because the database doesn't have a `farm_information` table yet!

---

## Solution: Create Farm Information Table

### **Step 1: Run SQL Migration**

1. Open your **Supabase Dashboard**
2. Go to **SQL Editor** (left sidebar)
3. Open the file: `supabase_setup/CREATE_FARM_INFORMATION_TABLE.sql`
4. Copy all the SQL code
5. Paste into Supabase SQL Editor
6. Click **RUN**

### **What This Does:**

✅ Creates `farm_information` table  
✅ Sets up proper relationships with `users` table  
✅ Enables Row Level Security (RLS)  
✅ Creates policies so farmers can save their own data  
✅ Adds automatic timestamp updates  
✅ Creates indexes for fast lookups  

---

## Table Structure

```sql
CREATE TABLE public.farm_information (
  id uuid PRIMARY KEY,
  farmer_id uuid UNIQUE NOT NULL,        -- Links to users.id
  location text DEFAULT '',               -- Farm location
  size text DEFAULT '',                   -- Farm size (from dropdown or custom)
  years_experience integer DEFAULT 0,    -- Years farming
  primary_crops text[] DEFAULT [],       -- Array of crops (Rice, Corn, etc.)
  farming_methods text[] DEFAULT [],     -- Array of methods (Organic, etc.)
  description text,                       -- Detailed farm description
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  
  FOREIGN KEY (farmer_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## Security (RLS Policies)

✅ **Anyone can view** - Public profiles need to see farm info  
✅ **Farmers can insert** - Only their own data  
✅ **Farmers can update** - Only their own data  
✅ **Farmers can delete** - Only their own data  

**Security Guarantee**: Farmers can ONLY edit their own farm information, never someone else's.

---

## After Running SQL

### **Test It Works:**

1. **As Farmer**:
   - Go to Farm Information screen
   - Fill in all fields:
     - Farm Location: "Barangay Centro, Bayugan"
     - Farm Size: Select from dropdown or "Custom size"
     - Years Experience: "10"
     - Primary Crops: Select Rice, Corn, Vegetables
     - Farming Methods: Select Organic Farming
     - Description: Write about your farm
   - Click **Save**
   - Should see success message!

2. **Verify in Database**:
   ```sql
   SELECT * FROM farm_information;
   ```
   You should see your data!

3. **Check Public Profile**:
   - Go to your public store (as buyer or another user)
   - Click "About" tab
   - See "About Our Farm" section with all your data!

---

## Troubleshooting

### **Issue: Still can't save**

**Check 1: Table exists**
```sql
SELECT * FROM information_schema.tables 
WHERE table_name = 'farm_information';
```
Should return 1 row.

**Check 2: RLS policies exist**
```sql
SELECT * FROM pg_policies 
WHERE tablename = 'farm_information';
```
Should return 4 rows (select, insert, update, delete).

**Check 3: User is authenticated**
Make sure you're logged in as a farmer.

### **Issue: "Permission denied"**

This means RLS policy issue. Re-run the SQL script, especially the policies section.

### **Issue: "Duplicate key violation"**

This means farm information already exists for this farmer. The app should UPDATE instead of INSERT. Check `farmer_profile_service.dart`.

---

## How It Works in the App

### **Save Flow:**
```
Farmer fills form
     ↓
Clicks Save
     ↓
farmer_profile_service.dart
     ↓
saveFarmInformation()
     ↓
Supabase INSERT/UPDATE
     ↓
farm_information table
     ↓
Success!
```

### **Display Flow:**
```
Buyer visits farmer store
     ↓
public_farmer_profile_screen.dart
     ↓
_loadStoreData()
     ↓
getFarmInformation(farmerId)
     ↓
Fetch from farm_information table
     ↓
Display in "About Our Farm" section
```

---

## Data Examples

### **Sample Farm Information:**

```sql
INSERT INTO farm_information (farmer_id, location, size, years_experience, primary_crops, farming_methods, description)
VALUES (
  'farmer-uuid-here',
  'Barangay Centro, Bayugan',
  '2-5 hectares',
  10,
  ARRAY['Rice', 'Corn', 'Vegetables'],
  ARRAY['Organic Farming', 'Sustainable Agriculture'],
  'We practice sustainable organic farming with natural pest control and crop rotation.'
);
```

### **Sample Query:**

```sql
-- Get farm info for a specific farmer
SELECT * FROM farm_information WHERE farmer_id = 'uuid-here';

-- Get all farms with organic farming
SELECT * FROM farm_information WHERE 'Organic Farming' = ANY(farming_methods);

-- Get all rice farmers
SELECT * FROM farm_information WHERE 'Rice' = ANY(primary_crops);
```

---

## Future Enhancements (Optional)

After basic setup works, you can add:

1. **Certifications**: Add `certifications` jsonb column for uploaded certificates
2. **Farm Photos**: Add `photo_urls` text[] for farm images
3. **Coordinates**: Add `latitude`, `longitude` for map display
4. **Acreage Breakdown**: Add jsonb for crop-specific sizes
5. **Harvest Seasons**: Track when each crop is available

---

## Verification Checklist

After running SQL:

- [ ] Table `farm_information` exists in database
- [ ] 4 RLS policies created and enabled
- [ ] Can save farm information from app
- [ ] Data appears in Supabase table viewer
- [ ] "About Our Farm" section shows on public profile
- [ ] Can update farm information
- [ ] Non-farmers cannot edit others' farm info

---

## Summary

**Before**: Farm information had no database table → couldn't save  
**After**: Table created with RLS → farmers can save and display their farm info

**Action Required**: Run `CREATE_FARM_INFORMATION_TABLE.sql` in Supabase SQL Editor

---

**Status**: ⚠️ **ACTION REQUIRED - Run SQL Script First**

Once you run the SQL script, farm information will save and display properly! 🚀
