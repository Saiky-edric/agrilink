# 📋 Pre-Migration Safety Checklist

## ⚠️ CRITICAL SAFETY STEPS - DO NOT SKIP

### 1. 📁 Database Backup (MANDATORY)

**Supabase Dashboard Method:**
1. Go to your Supabase project dashboard
2. Navigate to Settings → Database
3. Click "Database Backups" or "Export"
4. Download a full backup
5. **Verify backup file downloaded successfully**

**SQL Dump Method (Alternative):**
```sql
-- If dashboard backup not available, run this to export key tables:
COPY (SELECT * FROM users) TO STDOUT WITH CSV HEADER;
COPY (SELECT * FROM profiles) TO STDOUT WITH CSV HEADER;
COPY (SELECT * FROM products) TO STDOUT WITH CSV HEADER;
COPY (SELECT * FROM orders) TO STDOUT WITH CSV HEADER;
-- Save these outputs
```

### 2. 🔍 Environment Verification

**Check Current Environment:**
```sql
-- Verify you're on the correct database
SELECT current_database(), current_user, inet_server_addr();

-- Check table existence
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('users', 'profiles', 'products', 'orders');
```

**Expected Results:**
- Database name matches your project
- All expected tables exist
- You have admin privileges

### 3. 📊 Data Assessment

**Get baseline numbers:**
```sql
-- Record these numbers for comparison after migration
SELECT 
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    (SELECT COUNT(*) FROM users) as users_count,
    (SELECT COUNT(*) FROM profiles) as profiles_count,
    (SELECT COUNT(*) FROM products) as products_count,
    (SELECT COUNT(*) FROM orders) as orders_count,
    (SELECT COUNT(*) FROM cart) as cart_count;
```

**Record these numbers:**
- auth.users: _____ records
- users: _____ records  
- profiles: _____ records
- products: _____ records
- orders: _____ records
- cart: _____ records

### 4. 🔐 Access Verification

**Confirm permissions:**
```sql
-- Check if you can create/drop constraints
SELECT has_table_privilege('public', 'users', 'REFERENCES');
SELECT has_table_privilege('public', 'profiles', 'REFERENCES');

-- Test constraint creation (will rollback)
BEGIN;
ALTER TABLE cart ADD CONSTRAINT test_constraint_temp FOREIGN KEY (user_id) REFERENCES profiles(user_id);
ROLLBACK;
```

### 5. ⏰ Timing Considerations

**Best Time to Run Migration:**
- [ ] Low traffic period identified
- [ ] Users notified (if in production)
- [ ] Team available for monitoring
- [ ] 60-90 minutes blocked for the process

### 6. 🚨 Rollback Preparation

**Emergency Contacts Ready:**
- [ ] Database admin contact available
- [ ] Supabase support access confirmed
- [ ] Team leads notified

**Rollback Tools Ready:**
- [ ] Database backup downloaded and verified
- [ ] Previous app version code available
- [ ] Rollback scripts prepared

### 7. 📱 Application State

**Pre-migration app testing:**
```bash
# Test current app state
flutter clean
flutter pub get
flutter run

# Verify current issues:
# - Can users authenticate? (should work)
# - Can users add to cart? (likely fails)
# - Can users place orders? (likely fails)
# - Can farmers add products? (likely fails)
```

**Document current behavior:**
- Authentication: ✅ Working / ❌ Broken
- Profile loading: ✅ Working / ❌ Broken  
- Cart functionality: ✅ Working / ❌ Broken
- Order creation: ✅ Working / ❌ Broken
- Product management: ✅ Working / ❌ Broken

---

## ✅ FINAL GO/NO-GO DECISION

### Requirements for GO:
- [ ] ✅ Database backup completed and verified
- [ ] ✅ Baseline data counts recorded
- [ ] ✅ Admin access confirmed
- [ ] ✅ Migration window scheduled
- [ ] ✅ Rollback plan ready
- [ ] ✅ Team available for support

### Reasons for NO-GO:
- [ ] ❌ Cannot create database backup
- [ ] ❌ No admin access to database
- [ ] ❌ Production traffic too high
- [ ] ❌ No rollback plan
- [ ] ❌ Insufficient time allocated

---

## 🎯 FINAL CHECKLIST SIGN-OFF

**Technical Lead:** _________________ Date: _______

**Database Admin:** _________________ Date: _______

**Product Owner:** _________________ Date: _______

### Declaration:
"I confirm that all safety measures are in place, backups are verified, and the team is ready to proceed with the database migration."

**MIGRATION APPROVED TO PROCEED:** ✅ YES / ❌ NO

---

## 📋 QUICK REFERENCE

**If something goes wrong:**
1. **STOP immediately**
2. **Do NOT continue the migration**
3. **Contact team lead**
4. **Prepare for rollback**

**Emergency rollback command:**
```sql
-- Stop all operations and restore from backup
-- (Specific commands depend on your backup method)
```

**Migration success indicators:**
- All NOTICE messages appear in correct order
- No ERROR messages in SQL output
- Foreign key constraints created successfully
- Sample queries return expected results

**Ready to proceed?** → Go to `EXECUTION_GUIDE_PATH_A.md`