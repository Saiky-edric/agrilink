# Premium Features Testing Guide 🧪

**Purpose:** Step-by-step guide to test all premium features and verify they work correctly

---

## 🔧 Pre-Testing Setup

### **Step 1: Prepare Test Accounts**

You'll need **TWO test accounts**:
1. **Free Tier Farmer** (subscription_tier = 'free')
2. **Premium Tier Farmer** (subscription_tier = 'premium')

### **Step 2: Set Up Database**

Run these SQL commands in Supabase SQL Editor:

```sql
-- Create or update a FREE tier test farmer
UPDATE users 
SET subscription_tier = 'free',
    subscription_expires_at = NULL,
    subscription_started_at = NULL
WHERE email = 'free-farmer@test.com'; -- Replace with your test email

-- Create or update a PREMIUM tier test farmer
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NULL, -- NULL = lifetime premium
    subscription_started_at = NOW()
WHERE email = 'premium-farmer@test.com'; -- Replace with your test email

-- Or set expiry date for time-limited premium
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NOW() + INTERVAL '30 days',
    subscription_started_at = NOW()
WHERE email = 'premium-farmer@test.com';
```

### **Step 3: Add Test Products**

Make sure both farmers have at least 2-3 products each:
- Free farmer: Can only add 3 products max
- Premium farmer: Can add unlimited products

---

## ✅ Testing Checklist

---

## 1️⃣ **Exclusive Featured Carousel Placement**

### **What to Test:**
Homepage carousel shows ONLY premium farmers' products

### **Test Steps:**

**As a Buyer:**
1. ✅ Open the app and go to Home screen
2. ✅ Look at the top carousel with "PREMIUM FEATURED" badge
3. ✅ Verify carousel has gold gradient badge
4. ✅ Swipe through carousel products
5. ✅ Click on any product in carousel
6. ✅ Check if the farmer is premium (should have premium badge)

**Expected Results:**
- ✅ Carousel displays at top of homepage
- ✅ Badge says "PREMIUM FEATURED" with star icon
- ✅ Gold gradient theme (gold to orange)
- ✅ All products in carousel are from premium farmers
- ✅ Products show premium badge overlay

**If No Products Show:**
- Check if any premium farmers exist in database
- Check if premium farmers have products with stock > 0
- Check if products are not hidden (is_hidden = false)

**SQL to Verify:**
```sql
-- Check premium farmers with products
SELECT 
    u.id,
    u.full_name,
    u.subscription_tier,
    u.subscription_expires_at,
    COUNT(p.id) as product_count
FROM users u
LEFT JOIN products p ON p.farmer_id = u.id AND p.is_hidden = false AND p.stock > 0
WHERE u.subscription_tier = 'premium'
GROUP BY u.id, u.full_name, u.subscription_tier, u.subscription_expires_at;
```

---

## 2️⃣ **Premium Badge on All Products**

### **What to Test:**
Premium badge appears on products from premium farmers

### **Test Steps:**

**As a Buyer:**
1. ✅ Browse products on homepage
2. ✅ Go to search/category screens
3. ✅ Look for products from premium farmers
4. ✅ Verify small gold star badge with "Premium" text appears

**As Premium Farmer:**
1. ✅ Login as premium farmer
2. ✅ Go to your profile
3. ✅ Check if premium badge shows next to your name
4. ✅ View your products
5. ✅ Verify premium badge on product cards

**Expected Results:**
- ✅ Gold star badge appears on product cards from premium farmers
- ✅ Badge shows on homepage, search, categories
- ✅ Badge appears on farmer profile
- ✅ No badge on free farmer products

**Locations to Check:**
- Homepage carousel
- Product cards on homepage
- Search results
- Category browsing
- Product details page
- Farmer public profile
- Farmer private profile

**Test Code (if needed):**
```dart
// In your test file or debug mode
final product = /* get any product */;
print('Product farmer isPremium: ${product.farmerIsPremium}');
```

---

## 3️⃣ **First Position in Search Results**

### **What to Test:**
Premium farmers' products appear first in search and category results

### **Test Steps:**

**Search Test:**
1. ✅ Go to search screen
2. ✅ Search for a common term (e.g., "tomato", "rice")
3. ✅ Look at the order of results
4. ✅ Verify premium farmers' products appear FIRST

**Category Test:**
1. ✅ Go to a category (e.g., Vegetables)
2. ✅ Look at product list
3. ✅ Verify premium products are at the top

**Expected Results:**
- ✅ All premium farmers' products listed first
- ✅ Free farmers' products appear after premium
- ✅ Within each tier, products sorted by date (newest first)

**SQL to Verify Search Priority:**
```sql
-- This simulates the search query
SELECT 
    p.name,
    p.created_at,
    u.full_name as farmer_name,
    u.subscription_tier,
    u.subscription_expires_at,
    CASE 
        WHEN u.subscription_tier = 'premium' AND 
             (u.subscription_expires_at IS NULL OR u.subscription_expires_at > NOW())
        THEN 1 
        ELSE 2 
    END as priority_order
FROM products p
JOIN users u ON p.farmer_id = u.id
WHERE p.is_hidden = false 
  AND p.stock > 0
  AND p.name ILIKE '%tomato%' -- Replace with your search term
ORDER BY priority_order ASC, p.created_at DESC;
```

---

## 4️⃣ **Unlimited Product Listings**

### **What to Test:**
- Free farmers: Limited to 3 products
- Premium farmers: Unlimited products

### **Test Steps:**

**As Free Farmer:**
1. ✅ Login as free farmer
2. ✅ Go to "My Products" or product list
3. ✅ Count existing products
4. ✅ If < 3 products, try to add a new product
5. ✅ If already 3 products, try to add a 4th product
6. ✅ Should see error/limit message

**As Premium Farmer:**
1. ✅ Login as premium farmer
2. ✅ Try to add multiple products (4, 5, 6+)
3. ✅ Should succeed without limit

**Expected Results:**
- ✅ Free farmer: Cannot add more than 3 products total
- ✅ Free farmer: Gets clear error message about limit
- ✅ Premium farmer: Can add unlimited products
- ✅ Error message suggests upgrading to premium

**SQL to Check Product Count:**
```sql
-- Check product count per farmer
SELECT 
    u.id,
    u.full_name,
    u.subscription_tier,
    COUNT(p.id) as total_products,
    COUNT(CASE WHEN p.is_hidden = false THEN 1 END) as visible_products
FROM users u
LEFT JOIN products p ON p.farmer_id = u.id
WHERE u.role = 'farmer'
GROUP BY u.id, u.full_name, u.subscription_tier
ORDER BY u.subscription_tier DESC, total_products DESC;
```

**Backend Check:**
The limit is enforced in `product_service.dart` or during product creation. Check the error handling.

---

## 5️⃣ **5 Photos Per Product (vs 4 for Free)**

### **What to Test:**
- Free farmers: 4 total photos (1 cover + 3 additional)
- Premium farmers: 5 total photos (1 cover + 4 additional)

### **Test Steps:**

**As Free Farmer:**
1. ✅ Login as free farmer
2. ✅ Go to "Add Product" screen
3. ✅ Add cover image (1st photo)
4. ✅ Try to add additional images
5. ✅ Verify counter shows "0/3", "1/3", "2/3", "3/3"
6. ✅ After 3 additional images, should show upgrade prompt
7. ✅ Cannot add 4th additional image

**As Premium Farmer:**
1. ✅ Login as premium farmer
2. ✅ Go to "Add Product" screen
3. ✅ Add cover image (1st photo)
4. ✅ Try to add additional images
5. ✅ Verify counter shows "0/4", "1/4", "2/4", "3/4", "4/4"
6. ✅ Can add up to 4 additional images
7. ✅ See gold-themed success message
8. ✅ Hint text says "Add up to 4 more photos (Premium benefit!)"

**Expected Results:**
- ✅ Free: Counter shows "/3", max 3 additional
- ✅ Premium: Counter shows "/4", max 4 additional
- ✅ Free: Upgrade button appears when limit reached
- ✅ Premium: Gold success message when limit reached
- ✅ Image picker disabled after reaching limit

**Visual Checks:**
- Image counter updates dynamically
- Upgrade dialog appears for free users
- Premium benefit message for premium users

---

## 6️⃣ **Advanced Analytics + CSV Export**

### **What to Test:**
- Free farmers: Basic analytics, locked CSV export
- Premium farmers: Full analytics, functional CSV export

### **Test Steps:**

**As Free Farmer:**
1. ✅ Login as free farmer
2. ✅ Go to "Sales Analytics" screen
3. ✅ Check if gold upsell banner appears at top
4. ✅ See basic analytics (revenue, orders, products)
5. ✅ Look at app bar - should see lock icon for export
6. ✅ Click the lock icon
7. ✅ Should see upgrade dialog
8. ✅ See "Advanced Analytics Teaser" section at bottom
9. ✅ Lists locked premium features

**As Premium Farmer:**
1. ✅ Login as premium farmer
2. ✅ Go to "Sales Analytics" screen
3. ✅ Check if premium badge shows in header
4. ✅ NO upsell banner at top (clean interface)
5. ✅ See all analytics data
6. ✅ Look at app bar - should see download icon (unlocked)
7. ✅ Click download icon
8. ✅ Should show "CSV export feature coming soon!" message
9. ✅ NO "Advanced Analytics Teaser" at bottom

**Expected Results:**

**Free Tier:**
- ✅ Gold upsell banner at top
- ✅ Lock icon for CSV export
- ✅ Upgrade dialog when clicking lock
- ✅ "Advanced Analytics Teaser" section
- ✅ Lists: 30/60/90-day data, forecasting, customer insights, etc.
- ✅ "Upgrade to Premium" button

**Premium Tier:**
- ✅ Premium badge next to "Sales Analytics" title
- ✅ Download icon for CSV export (functional)
- ✅ No upsell banners
- ✅ Clean, professional interface
- ✅ No teaser section at bottom

---

## 7️⃣ **Priority Support Badge**

### **What to Test:**
Premium farmers see priority badge and gold theme in support chat

### **Test Steps:**

**As Free Farmer:**
1. ✅ Login as free farmer
2. ✅ Go to support chat screen
3. ✅ Check app bar title - should say "Support Chat"
4. ✅ No priority badge
5. ✅ Welcome message has blue background
6. ✅ Standard support agent icon
7. ✅ Message: "Welcome to Agrilink Support! Ask me anything..."

**As Premium Farmer:**
1. ✅ Login as premium farmer
2. ✅ Go to support chat screen
3. ✅ Check app bar title - should have gold "Priority" badge
4. ✅ Badge shows star icon + "Priority" text
5. ✅ Welcome container has gold gradient background
6. ✅ Gold/orange themed border
7. ✅ Star icon instead of support agent icon
8. ✅ Title: "Premium Support - Priority Response"
9. ✅ Message mentions priority handling and faster response

**Expected Results:**

**Free:**
- ✅ Blue theme
- ✅ Support agent icon
- ✅ Standard welcome message
- ✅ No priority badge

**Premium:**
- ✅ Gold gradient theme
- ✅ Star icon
- ✅ "Priority" badge in header
- ✅ Premium welcome message
- ✅ Mentions faster response time

---

## 8️⃣ **Gold-Themed UI Throughout**

### **What to Test:**
Premium users see gold/premium theme in various places

### **Test Locations:**

**As Premium Farmer:**
1. ✅ **Profile Screen:**
   - Premium badge next to name
   - Gold star icon

2. ✅ **Add Product Screen:**
   - Image limit hint mentions "Premium benefit!"
   - Gold success message when limit reached
   - Premium-themed upload UI

3. ✅ **Analytics Screen:**
   - Premium badge in header
   - Gold download icon
   - Clean interface (no upsells)

4. ✅ **Support Chat:**
   - Gold priority badge
   - Gold gradient welcome container
   - Premium messaging

5. ✅ **Product Cards (Buyer View):**
   - Gold premium badge overlay
   - Star icon with "Premium" text

6. ✅ **Homepage Carousel:**
   - Gold gradient "PREMIUM FEATURED" badge
   - Premium products only

**Expected Consistency:**
- ✅ Gold color: #FFD700
- ✅ Orange color: #FFA500
- ✅ Star icon used throughout
- ✅ Consistent gradient (gold to orange)
- ✅ Professional, premium feel

---

## 🔍 Advanced Testing

### **Test Premium Status Expiry**

**Setup:**
```sql
-- Set premium to expire in 1 minute for testing
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NOW() + INTERVAL '1 minute'
WHERE email = 'test-premium@test.com';
```

**Test:**
1. ✅ Login as premium user
2. ✅ Verify all premium features work
3. ✅ Wait 2 minutes
4. ✅ Close and reopen app
5. ✅ Verify premium features are now locked
6. ✅ Should see upgrade prompts

**Expected:**
- Premium features work before expiry
- After expiry, user treated as free tier
- No crashes or errors

---

### **Test Premium Badge Display Logic**

**Test Cases:**

**Case 1: Active Premium (No Expiry)**
```sql
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NULL
WHERE id = 'USER_ID';
```
✅ Expected: Premium badge shows, all features unlocked

**Case 2: Active Premium (Future Expiry)**
```sql
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NOW() + INTERVAL '30 days'
WHERE id = 'USER_ID';
```
✅ Expected: Premium badge shows, all features unlocked

**Case 3: Expired Premium**
```sql
UPDATE users 
SET subscription_tier = 'premium',
    subscription_expires_at = NOW() - INTERVAL '1 day'
WHERE id = 'USER_ID';
```
✅ Expected: No premium badge, free tier restrictions apply

**Case 4: Free Tier**
```sql
UPDATE users 
SET subscription_tier = 'free',
    subscription_expires_at = NULL
WHERE id = 'USER_ID';
```
✅ Expected: No premium badge, free tier restrictions apply

---

## 🐛 Common Issues & Solutions

### **Issue 1: Premium badge not showing**
**Check:**
- User's `subscription_tier` = 'premium'
- If `subscription_expires_at` is set, it's in the future
- App has been restarted to reload user data
- Model fields are correctly populated

### **Issue 2: Products not in featured carousel**
**Check:**
- Farmer is premium
- Products have `is_hidden = false`
- Products have `stock > 0`
- App has been refreshed

### **Issue 3: Image limit not working**
**Check:**
- Add product screen has premium status check
- Counter is updating dynamically
- Upgrade dialog is triggered

### **Issue 4: Search priority not working**
**Check:**
- Product service has premium sorting logic
- Farmer data includes subscription_tier
- Query orders by premium status first

---

## 📊 Testing Checklist Summary

| Feature | Free Tier | Premium Tier | Status |
|---------|-----------|--------------|--------|
| Featured Carousel | ❌ Not included | ✅ Exclusive | [ ] |
| Premium Badge | ❌ No badge | ✅ Shows everywhere | [ ] |
| Search Priority | ❌ Standard order | ✅ First position | [ ] |
| Product Limit | ⚠️ Max 3 products | ✅ Unlimited | [ ] |
| Photo Limit | ⚠️ 4 photos (1+3) | ✅ 5 photos (1+4) | [ ] |
| Analytics | ⚠️ Basic only | ✅ Advanced + CSV | [ ] |
| Support Badge | ❌ Standard | ✅ Priority badge | [ ] |
| UI Theme | 🔵 Standard | 🟡 Gold theme | [ ] |

---

## 🎯 Quick Test Script

Run this in order for a complete test:

1. **Setup** (5 min)
   - Create/update 2 test accounts (free + premium)
   - Add products to both accounts
   
2. **Buyer Experience** (10 min)
   - Check homepage carousel (premium only)
   - Search for products (check order)
   - Browse categories (check order)
   - View product details (check badges)

3. **Free Farmer Experience** (10 min)
   - Login as free farmer
   - Try to add 4th product (should fail)
   - Add product with 4th additional image (should fail)
   - View analytics (see upsells)
   - Open support chat (standard theme)

4. **Premium Farmer Experience** (10 min)
   - Login as premium farmer
   - Add multiple products (should succeed)
   - Add product with 4 additional images (should succeed)
   - View analytics (no upsells, clean UI)
   - Open support chat (gold theme, priority badge)
   - Check profile (premium badge visible)

**Total Time: ~35 minutes for complete testing**

---

## 📝 Test Results Template

Copy this to document your testing:

```
PREMIUM FEATURES TEST RESULTS
Date: [DATE]
Tester: [NAME]
App Version: [VERSION]

✅ = Pass | ❌ = Fail | ⚠️ = Partial/Issue

1. Featured Carousel (Premium Only): [ ]
   Notes: 

2. Premium Badge Display: [ ]
   Notes: 

3. Search/Category Priority: [ ]
   Notes: 

4. Product Limit (3 free, unlimited premium): [ ]
   Notes: 

5. Photo Limit (4 free, 5 premium): [ ]
   Notes: 

6. Analytics + CSV Export: [ ]
   Notes: 

7. Priority Support Badge: [ ]
   Notes: 

8. Gold Theme Consistency: [ ]
   Notes: 

OVERALL STATUS: [ ] All Pass | [ ] Issues Found
READY FOR PRODUCTION: [ ] Yes | [ ] No

Issues/Bugs Found:
1. 
2. 
3. 

Additional Notes:

```

---

**Happy Testing! 🧪✅**

If you find any issues during testing, refer back to the implementation documentation or let me know!
