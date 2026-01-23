# Premium Benefits Implementation Plan

**Date:** January 21, 2026  
**Goal:** Implement and enforce all premium tier benefits with proper free tier limitations  
**Status:** 📋 Planning Phase

---

## 🎯 Implementation Overview

### **Current Status:**
- ✅ Product limit: 3 for free, unlimited for premium (IMPLEMENTED)
- ✅ Image limit: 4 for free, 5 for premium (IMPLEMENTED)
- ✅ Store customization: Available for all (IMPLEMENTED)
- ❌ Priority search placement: NOT IMPLEMENTED
- ❌ Homepage featuring: NOT IMPLEMENTED
- ❌ Premium badge display: NOT IMPLEMENTED
- ❌ Priority support: NOT IMPLEMENTED
- ❌ Advanced analytics: PARTIALLY IMPLEMENTED

---

## 📋 Step-by-Step Implementation Plan

### **Phase 1: Core Infrastructure** 🏗️

#### **Step 1.1: Verify Premium Status Helper**
**File:** Create/update helper service
- [ ] Create `lib/core/services/premium_service.dart`
- [ ] Add method `isPremiumUser(userId)` 
- [ ] Add method `getPremiumExpiryDate(userId)`
- [ ] Add method `getPremiumDaysRemaining(userId)`
- [ ] Add method `showUpgradeDialog(context)`

**Estimated Time:** 30 minutes

---

#### **Step 1.2: Premium Badge Widget**
**File:** `lib/shared/widgets/premium_badge.dart`
- [ ] Verify widget exists and is properly styled
- [ ] Ensure it shows star icon + "Premium" text
- [ ] Add small and large variants
- [ ] Add tooltip with premium info

**Estimated Time:** 15 minutes

---

### **Phase 2: Premium Badge Display** ⭐

#### **Step 2.1: Show Premium Badge on Farmer Profiles**
**Files to Update:**
- [ ] `lib/features/farmer/screens/public_farmer_profile_screen.dart`
- [ ] `lib/features/farmer/screens/farmer_profile_screen.dart`

**Changes:**
```dart
// Add premium badge next to farmer name
if (farmerProfile.isPremium) {
  PremiumBadge(size: BadgeSize.medium)
}
```

**Estimated Time:** 20 minutes

---

#### **Step 2.2: Show Premium Badge on Product Cards**
**Files to Update:**
- [ ] `lib/shared/widgets/product_card.dart`
- [ ] `lib/features/buyer/screens/home_screen.dart` (product grid)

**Changes:**
```dart
// Add premium badge overlay on product images
if (product.farmerProfile?.isPremium ?? false) {
  Positioned(
    top: 8, right: 8,
    child: PremiumBadge(size: BadgeSize.small),
  )
}
```

**Estimated Time:** 30 minutes

---

#### **Step 2.3: Show Premium Badge in Search Results**
**Files to Update:**
- [ ] `lib/features/buyer/screens/search_screen.dart`
- [ ] `lib/features/buyer/screens/modern_search_screen.dart`

**Changes:**
```dart
// Add badge next to seller name in search results
if (seller.isPremium) {
  PremiumBadge(size: BadgeSize.small)
}
```

**Estimated Time:** 20 minutes

---

### **Phase 3: Priority Search Placement** 🔍

#### **Step 3.1: Update Product Search Query**
**File:** `lib/core/services/product_service.dart`

**Current Query:**
```sql
SELECT * FROM products 
WHERE name ILIKE '%search%' 
ORDER BY created_at DESC
```

**Updated Query:**
```sql
SELECT p.*, u.subscription_tier
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.name ILIKE '%search%'
  AND p.is_hidden = false
  AND p.deleted_at IS NULL
ORDER BY 
  CASE WHEN u.subscription_tier = 'premium' THEN 0 ELSE 1 END,
  p.created_at DESC
```

**Tasks:**
- [ ] Update `searchProducts()` method
- [ ] Add premium sorting logic
- [ ] Test search results order

**Estimated Time:** 45 minutes

---

#### **Step 3.2: Update Category Browse Query**
**File:** `lib/core/services/product_service.dart`

**Tasks:**
- [ ] Update `getProductsByCategory()` method
- [ ] Add same premium sorting as search
- [ ] Ensure premium products show first

**Estimated Time:** 30 minutes

---

### **Phase 4: Homepage Featuring** 🏠

#### **Step 4.1: Create Featured Products Section**
**File:** `lib/features/buyer/screens/home_screen.dart`

**Tasks:**
- [ ] Add "Featured Premium Sellers" section
- [ ] Create query to fetch premium farmers' products
- [ ] Add horizontal scrollable list
- [ ] Show premium badge on cards

**Query:**
```sql
SELECT p.*, u.store_name, u.subscription_tier
FROM products p
JOIN users u ON p.farmer_id = u.id
WHERE u.subscription_tier = 'premium'
  AND u.subscription_expires_at > NOW()
  AND p.is_hidden = false
  AND p.deleted_at IS NULL
ORDER BY p.created_at DESC
LIMIT 10
```

**Estimated Time:** 1 hour

---

#### **Step 4.2: Add Premium Carousel**
**File:** `lib/features/buyer/screens/home_screen.dart`

**Tasks:**
- [ ] Create "Premium Farmers" carousel widget
- [ ] Show store banners with premium badge
- [ ] Link to farmer profile pages
- [ ] Add "View All Premium Sellers" button

**Estimated Time:** 45 minutes

---

### **Phase 5: Image Limit Enforcement** 📸

#### **Step 5.1: Update Add Product Screen**
**File:** `lib/features/farmer/screens/add_product_screen.dart`

**Current:** Already limited to 3 additional images for all

**Tasks:**
- [ ] Check user's premium status
- [ ] If premium: allow 4 additional images (5 total)
- [ ] If free: keep 3 additional images (4 total)
- [ ] Update UI to show dynamic limit

**Code:**
```dart
final userProfile = await _authService.getCurrentUserProfile();
final maxAdditionalImages = userProfile?.isPremium ?? false ? 4 : 3;

if (_additionalImages.length < maxAdditionalImages) {
  // Show image picker
}
```

**Estimated Time:** 30 minutes

---

#### **Step 5.2: Update Edit Product Screen**
**File:** `lib/features/farmer/screens/edit_product_screen.dart`

**Tasks:**
- [ ] Apply same logic as add product
- [ ] Check premium status
- [ ] Enforce image limits
- [ ] Show upgrade prompt if trying to add more

**Estimated Time:** 30 minutes

---

### **Phase 6: Priority Support** 💬

#### **Step 6.1: Add Priority Badge in Support Chat**
**File:** `lib/features/chat/screens/support_chat_screen.dart`

**Tasks:**
- [ ] Show "Premium Support" badge for premium users
- [ ] Add visual indicator (gold/star icon)
- [ ] Update chat header

**Estimated Time:** 20 minutes

---

#### **Step 6.2: Admin Support Queue**
**File:** `lib/features/admin/screens/admin_support_screen.dart` (if exists)

**Tasks:**
- [ ] Create admin view for support tickets
- [ ] Sort premium users first
- [ ] Add filter to view premium tickets
- [ ] Show premium badge in ticket list

**Estimated Time:** 1 hour (if screen doesn't exist, skip for now)

---

### **Phase 7: Advanced Analytics** 📊

#### **Step 7.1: Check Current Analytics Access**
**File:** `lib/features/farmer/screens/sales_analytics_screen.dart`

**Current Status:** Need to verify what's available

**Tasks:**
- [ ] Review current analytics screen
- [ ] Identify basic vs advanced features
- [ ] Plan what to restrict for free tier

**Estimated Time:** 30 minutes

---

#### **Step 7.2: Implement Analytics Restrictions**
**File:** `lib/features/farmer/screens/sales_analytics_screen.dart`

**Free Tier (Basic) Analytics:**
- ✅ Total sales this week/month
- ✅ Order count
- ✅ Top 3 products
- ✅ Basic charts (7 days)

**Premium Tier (Advanced) Analytics:**
- ⭐ Historical data (30, 60, 90 days)
- ⭐ Detailed product performance
- ⭐ Customer insights
- ⭐ Revenue forecasting
- ⭐ Export to CSV

**Tasks:**
- [ ] Add premium check to analytics screen
- [ ] Show upgrade prompt for advanced features
- [ ] Blur/lock premium sections for free users
- [ ] Add "Upgrade to Premium" button

**Estimated Time:** 1.5 hours

---

### **Phase 8: Testing & Quality Assurance** ✅

#### **Step 8.1: Free Tier Testing**
**Test Cases:**
- [ ] Free farmer can add only 3 products
- [ ] Free farmer can upload 4 images per product
- [ ] Free farmer doesn't show premium badge
- [ ] Free farmer products appear after premium in search
- [ ] Free farmer has basic analytics only
- [ ] Free farmer can customize store
- [ ] Upgrade prompts appear correctly

**Estimated Time:** 1 hour

---

#### **Step 8.2: Premium Tier Testing**
**Test Cases:**
- [ ] Premium farmer can add unlimited products
- [ ] Premium farmer can upload 5 images per product
- [ ] Premium badge shows on profile
- [ ] Premium badge shows on products
- [ ] Premium products appear first in search
- [ ] Premium products show in featured section
- [ ] Premium farmer has full analytics access
- [ ] Premium support badge shows in chat

**Estimated Time:** 1 hour

---

#### **Step 8.3: Upgrade Flow Testing**
**Test Cases:**
- [ ] Free farmer sees upgrade dialog at 3 products
- [ ] Upgrade dialog shows correct benefits
- [ ] Can navigate to subscription screen
- [ ] After upgrade, benefits activate immediately
- [ ] Premium welcome popup shows
- [ ] Badge appears after upgrade

**Estimated Time:** 30 minutes

---

## 📊 Implementation Summary

### **Total Tasks:** 40+
### **Estimated Total Time:** 12-15 hours

### **Phase Breakdown:**
- Phase 1 (Infrastructure): 45 minutes
- Phase 2 (Badge Display): 1 hour 10 minutes
- Phase 3 (Search Priority): 1 hour 15 minutes
- Phase 4 (Homepage Featuring): 1 hour 45 minutes
- Phase 5 (Image Limits): 1 hour
- Phase 6 (Priority Support): 1 hour 20 minutes
- Phase 7 (Analytics): 2 hours
- Phase 8 (Testing): 2 hours 30 minutes

---

## 🎯 Priority Order

### **High Priority (Must Have):**
1. ✅ Product limit enforcement (DONE)
2. ✅ Image limit enforcement (DONE)
3. 🔴 Premium badge display (Phases 2)
4. 🔴 Priority search placement (Phase 3)
5. 🔴 Homepage featuring (Phase 4)

### **Medium Priority (Should Have):**
6. 🟡 Dynamic image limits (Phase 5)
7. 🟡 Advanced analytics restrictions (Phase 7)

### **Low Priority (Nice to Have):**
8. 🟢 Priority support indicators (Phase 6)

---

## 📝 Implementation Approach

### **Recommended Strategy:**

**Option A: Complete Implementation (12-15 hours)**
- Implement all phases sequentially
- Full feature parity with planned benefits
- Most comprehensive solution

**Option B: MVP Approach (4-6 hours)**
- Focus on high priority items only
- Phases 1, 2, 3, 4
- Get core benefits working, add rest later

**Option C: Gradual Rollout (2-3 hours per phase)**
- Implement one phase at a time
- Test thoroughly before moving to next
- More controlled but slower

---

## 🚀 Getting Started

### **Immediate Next Steps:**

1. **Confirm Approach:** Choose implementation strategy (A, B, or C)
2. **Start Phase 1:** Create premium service helper
3. **Move to Phase 2:** Implement badge display
4. **Progress Through Phases:** Follow plan systematically
5. **Test Each Phase:** Ensure quality before moving forward

---

## 📋 Checklist Format

For tracking progress, use this format:

```
[ ] Phase 1.1: Premium Service Helper
[ ] Phase 1.2: Premium Badge Widget
[ ] Phase 2.1: Badge on Farmer Profiles
[ ] Phase 2.2: Badge on Product Cards
[ ] Phase 2.3: Badge in Search Results
[ ] Phase 3.1: Priority Search Query
[ ] Phase 3.2: Category Browse Priority
[ ] Phase 4.1: Featured Products Section
[ ] Phase 4.2: Premium Carousel
[ ] Phase 5.1: Dynamic Image Limits (Add)
[ ] Phase 5.2: Dynamic Image Limits (Edit)
[ ] Phase 6.1: Priority Support Badge
[ ] Phase 6.2: Admin Support Queue
[ ] Phase 7.1: Analytics Review
[ ] Phase 7.2: Analytics Restrictions
[ ] Phase 8.1: Free Tier Testing
[ ] Phase 8.2: Premium Tier Testing
[ ] Phase 8.3: Upgrade Flow Testing
```

---

## 📞 Decision Points

### **Questions to Answer Before Starting:**

1. **Which implementation approach?** (A, B, or C)
2. **Should we create premium service helper or use existing auth service?**
3. **Do we have admin support screen or skip Phase 6.2?**
4. **What analytics features should be premium-only?**
5. **Should search priority be 100% or weighted (e.g., 80% premium first)?**
6. **Should homepage featuring be auto or admin-curated?**

---

**Ready to Begin?** Please confirm:
1. ✅ Which approach (A, B, or C)?
2. ✅ Which phase to start with?
3. ✅ Any specific requirements or changes to the plan?

---

**Plan Created By:** Rovo Dev AI Assistant  
**Status:** Awaiting Approval to Begin Implementation  
**Document Version:** 1.0
