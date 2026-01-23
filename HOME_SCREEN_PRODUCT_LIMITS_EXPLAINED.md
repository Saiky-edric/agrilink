# Home Screen Product Limits & Selection Logic

**Date:** January 22, 2026

---

## 📊 Current Configuration

### **1. Premium Featured Carousel**

#### **Maximum Products: 10**
```dart
setState(() {
  _featuredProducts = premiumProducts.take(10).toList(); // Limit to 10 for carousel
});
```

#### **Selection Logic: NEWEST FIRST (Not Random)**
```dart
final response = await supabase.client
    .from('products')
    .select(...)
    .eq('is_hidden', false)
    .gt('stock', 0)
    .order('created_at', ascending: false) // ← Newest products first
    .limit(20); // Get 20 products, then filter for premium

// Then filter for premium only
for (final item in response) {
  final isPremium = tier == 'premium' && 
      (expiresAt == null || DateTime.parse(expiresAt).isAfter(DateTime.now()));
  
  if (isPremium) {
    premiumProducts.add(ProductModel.fromJson(item));
  }
}

// Take first 10 premium products
_featuredProducts = premiumProducts.take(10).toList();
```

**How Products Are Selected:**
1. Query gets 20 newest products (all farmers)
2. Filters for only premium farmers
3. Takes the first 10 premium products
4. Result: **10 newest products from premium farmers**

**Selection Criteria:**
- ✅ Must be from premium farmer
- ✅ Must have stock > 0
- ✅ Must not be hidden
- ✅ Sorted by creation date (newest first)
- ❌ **NOT random** - Always shows newest

---

### **2. Product Grid (All Products)**

#### **Maximum Products: 20**
```dart
final products = await _productService.getAvailableProducts(limit: 20);
```

#### **Selection Logic: PREMIUM FIRST, THEN NEWEST**

The `getAvailableProducts()` method in `product_service.dart` already implements smart ordering:

**Default Behavior:**
1. Gets products from database (limited to 20)
2. Premium priority sorting happens in search/category methods
3. Shows newest products first within each tier

**Ordering in Grid:**
1. **Premium products** (sorted by newest first)
2. **Free products** (sorted by newest first)

---

## 🎯 Summary Table

| Section | Max Products | Selection Logic | Randomization |
|---------|--------------|-----------------|---------------|
| **Premium Carousel** | **10** | Newest premium products | ❌ No (deterministic) |
| **Product Grid** | **20** | Premium first, then free (all newest) | ❌ No (priority-based) |

---

## 💡 Current Behavior Examples

### **Scenario 1: Few Premium Farmers**
- 3 premium farmers each with 2 products = 6 premium products
- Carousel shows: **6 products** (all premium products)
- Grid shows: **14 free + 6 premium = 20 total**

### **Scenario 2: Many Premium Farmers**
- 15 premium farmers each with 5 products = 75 premium products
- Carousel shows: **10 newest premium products**
- Grid shows: **20 products** (likely all premium since they appear first)

### **Scenario 3: No Premium Farmers**
- 0 premium farmers
- Carousel shows: **Empty state** ("No Premium Products Available")
- Grid shows: **20 newest free farmer products**

---

## 🔄 How Selection Works Over Time

### **Day 1:**
- Farmer A (Premium) adds Product X at 9:00 AM
- Farmer B (Premium) adds Product Y at 10:00 AM
- Farmer C (Free) adds Product Z at 11:00 AM

**Carousel:** Shows Product Y, then Product X (newest premium first)  
**Grid:** Shows Product Y, Product X, then Product Z (premium first, then free)

### **Day 2:**
- Farmer D (Premium) adds Product W at 8:00 AM

**Carousel:** Shows Product W first (newest), then Product Y, then Product X  
**Grid:** Shows Product W, Y, X (premium), then Product Z (free)

---

## 🎲 Alternative: Random Selection

If you want random selection instead of newest-first, here's what needs to change:

### **For Carousel (Random Premium Products):**

**Current:**
```dart
.order('created_at', ascending: false) // Newest first
```

**Change to:**
```dart
// Option 1: Pure random
// (Note: Supabase doesn't have built-in random, need to implement)

// Option 2: Shuffle in code
final shuffled = List<ProductModel>.from(premiumProducts);
shuffled.shuffle(); // Random shuffle
_featuredProducts = shuffled.take(10).toList();
```

### **For Grid (Random All Products):**

**Current:**
```dart
final products = await _productService.getAvailableProducts(limit: 20);
```

**Change to:**
```dart
final products = await _productService.getAvailableProducts(limit: 50); // Get more
products.shuffle(); // Random shuffle
final randomProducts = products.take(20).toList(); // Take 20 random
```

---

## 📈 Recommendations

### **Current System (Newest First) - RECOMMENDED ✅**

**Pros:**
- ✅ Promotes new products
- ✅ Encourages farmers to add fresh inventory
- ✅ Buyers see latest offerings
- ✅ Fair rotation as new products added
- ✅ Predictable and transparent

**Cons:**
- ⚠️ Older products get less visibility
- ⚠️ Farmers with many products dominate if they add frequently

---

### **Random Selection - Alternative**

**Pros:**
- ✅ Equal chance for all products
- ✅ More variety for buyers
- ✅ Fair to farmers with older products

**Cons:**
- ⚠️ No incentive to add new products
- ⚠️ May show stale/old products
- ⚠️ Less predictable for farmers
- ⚠️ Could show same products if seed not changed

---

### **Hybrid Approach - BEST OF BOTH WORLDS 🌟**

**Recommendation:** Weighted random based on recency

```dart
// Give higher weight to newer products
// But still allow older products to appear

// Example logic:
// - Products < 7 days old: 80% chance
// - Products 7-14 days old: 15% chance  
// - Products > 14 days old: 5% chance
```

This balances freshness with fairness!

---

## 🔧 How to Change Limits

### **Change Carousel Limit (Currently 10):**

**File:** `lib/features/buyer/screens/home_screen.dart`

```dart
// Line ~155
setState(() {
  _featuredProducts = premiumProducts.take(10).toList(); // Change 10 to desired number
});
```

**Recommended values:**
- **5-8:** Best for mobile (easy to swipe through)
- **10:** Current (good balance)
- **15+:** Too many (users won't see all)

---

### **Change Grid Limit (Currently 20):**

**File:** `lib/features/buyer/screens/home_screen.dart`

```dart
// Line ~97
final products = await _productService.getAvailableProducts(limit: 20); // Change 20
```

**Recommended values:**
- **20:** Current (good for initial load)
- **30-40:** Show more products upfront
- **10-15:** Faster loading, less scrolling

**Consider:**
- Add "Load More" button for pagination
- Infinite scroll for better UX
- Performance impact with many products

---

## 🎯 Best Practices

### **For Carousel:**
1. ✅ Keep limit between 5-10 products
2. ✅ Show newest products for freshness
3. ✅ Consider rotation strategy (daily/weekly)
4. ✅ Ensure variety (maybe limit per farmer?)

### **For Grid:**
1. ✅ Start with 20-30 products
2. ✅ Implement pagination or infinite scroll
3. ✅ Apply premium priority for fairness
4. ✅ Consider category filtering

---

## 📊 Performance Considerations

### **Current Load:**
- **Carousel:** Fetches 20, filters to ~10 (efficient)
- **Grid:** Fetches exactly 20 (optimal)
- **Total:** 2 queries, parallel loading (fast)

### **If You Increase Limits:**
- **50+ products:** Consider pagination
- **100+ products:** Definitely need infinite scroll
- **Images:** May slow down on slower connections

---

## 🎨 UI/UX Implications

### **Carousel:**
- **5 products:** Quick to browse, may feel limited
- **10 products:** Good balance (current)
- **15+ products:** Users may not browse all

### **Grid:**
- **10-15 products:** Feels limited, quick to browse
- **20-30 products:** Good balance (current)
- **50+ products:** Need "Load More" or infinite scroll

---

## 🔮 Future Enhancements

### **Potential Improvements:**

1. **Smart Rotation:**
   - Track which products shown to each user
   - Rotate daily to show different products
   - Ensure all premium farmers get visibility

2. **Category-Based:**
   - Show products from different categories
   - Ensure variety in carousel

3. **Performance-Based:**
   - Feature best-selling products
   - Show highest-rated products
   - Combine with recency

4. **Personalization:**
   - Show products based on user's location
   - Show products in categories user browses
   - Show products from followed stores

5. **A/B Testing:**
   - Test random vs newest
   - Test different limits (5 vs 10 vs 15)
   - Measure conversion rates

---

## 📝 Quick Reference

```dart
// CURRENT CONFIGURATION

// Premium Featured Carousel
Max: 10 products
Logic: Newest premium products first
Random: No

// Product Grid  
Max: 20 products
Logic: Premium first (newest), then free (newest)
Random: No

// To Change Carousel Limit:
// Line ~155 in home_screen.dart
_featuredProducts = premiumProducts.take(10).toList(); // Change 10

// To Change Grid Limit:
// Line ~97 in home_screen.dart
final products = await _productService.getAvailableProducts(limit: 20); // Change 20
```

---

## ✅ Summary

**Your Questions Answered:**

1. **Max in carousel?** → **10 products**
2. **How selected?** → **Newest premium products first (NOT random)**
3. **Max in grid?** → **20 products**

**Selection is deterministic based on creation date, ensuring:**
- Fresh products get visibility
- Farmers incentivized to add new inventory
- Transparent and predictable system
- Premium farmers get exclusive carousel placement

---

**Want to change to random selection or adjust limits? Let me know!** 🎲

