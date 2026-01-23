# Product Units System - Complete Explanation ✅

**Date:** January 22, 2026  
**Topic:** How Product Units Work in Agrilink  
**Status:** ✅ EXPLAINED & IMPROVED

---

## 🎯 How the Unit System Works

### **Two Different Fields:**

1. **Unit** (displayed to users) - e.g., "bundle", "dozen", "kg"
2. **Weight Per Unit (kg)** - always in kilograms for logistics

---

## 📊 Example: Selling Tomatoes by Bundle

### **Farmer Sets Up:**
```
Product: Tomatoes
Unit: bundle
Price: ₱50.00
Weight per Unit: 2.5 kg
Stock: 20 bundles
```

### **What Buyers See:**

**Product Card:**
```
┌─────────────────┐
│  [Tomato Image] │
│  Tomatoes       │
│  ₱50.00/bundle  │  ← Shows the unit clearly
│  ⭐ 4.5         │
└─────────────────┘
```

**Product Details:**
```
Price: ₱50.00 /bundle
Stock: 20 bundle available
Unit: bundle
```

### **Behind the Scenes:**
- System knows: 1 bundle = 2.5 kg
- Used for:
  - Shipping calculations
  - Delivery fees (based on weight)
  - Inventory management
  - Logistics planning

---

## 📋 Available Units (Updated)

### **Weight-Based Units:**
- `kg` - Kilogram (standard)
- `g` - Gram
- `sack 25 kg` - 25kg sack
- `sack 50 kg` - 50kg sack
- `bag 25 kg` - 25kg bag

### **Count-Based Units:**
- `pc` - Piece
- `dozen` - 12 pieces
- `tray` - Tray (eggs, seedlings)
- `bundle` - Bundle of items
- `bunch` - Bunch (bananas, vegetables)

### **Container-Based Units:**
- `box` - Box
- `crate` - Crate
- `basket` - Basket
- `can` - Can
- `bottle` - Bottle
- `jar` - Jar

**Total: 17 units available**

---

## 💡 Examples of Different Units

### **Example 1: Eggs**
```
Unit: tray
Price: ₱180.00 /tray
Weight per Unit: 0.66 kg (30 eggs × 22g each)
Stock: 50 trays

Buyers see: ₱180.00/tray
System knows: 1 tray = 0.66 kg
```

### **Example 2: Bananas**
```
Unit: bunch
Price: ₱80.00 /bunch
Weight per Unit: 1.5 kg
Stock: 30 bunches

Buyers see: ₱80.00/bunch
System knows: 1 bunch = 1.5 kg
```

### **Example 3: Garlic**
```
Unit: dozen
Price: ₱60.00 /dozen
Weight per Unit: 0.5 kg
Stock: 100 dozen

Buyers see: ₱60.00/dozen
System knows: 1 dozen = 0.5 kg
```

### **Example 4: Rice**
```
Unit: sack 25 kg
Price: ₱1,200.00 /sack 25 kg
Weight per Unit: 25 kg
Stock: 15 sacks

Buyers see: ₱1,200.00/sack 25 kg
System knows: 1 sack = 25 kg
```

### **Example 5: Tomatoes (by piece)**
```
Unit: pc
Price: ₱15.00 /pc
Weight per Unit: 0.15 kg (150g average)
Stock: 200 pcs

Buyers see: ₱15.00/pc
System knows: 1 pc = 0.15 kg
```

---

## 🎨 Display Improvements

### **Product Card (NEW):**

**Before:**
```
₱50.00        ← No unit shown
⭐ 4.5
```

**After:**
```
₱50.00/bundle ← Unit clearly shown
⭐ 4.5
```

### **Product Details:**

**Always shows:**
```
Price: ₱50.00 /bundle
Stock: 20 bundle available
Unit: bundle
Weight per Unit: 2.5 kg
```

---

## ❓ Your Questions Answered

### **Q1: "If I select per bundle or piece, will it show per bundle or per piece on the product details screen or kg?"**

**A:** It will show **the exact unit you selected** (bundle, piece, dozen, etc.)

Examples:
- Selected "bundle" → Shows "₱50.00/bundle"
- Selected "dozen" → Shows "₱60.00/dozen"
- Selected "pc" → Shows "₱15.00/pc"
- Selected "kg" → Shows "₱100.00/kg"

### **Q2: "What is the weight per unit field for?"**

**A:** The weight per unit (in kg) is for **backend logistics**, NOT displayed to customers prominently:

**Used for:**
- ✅ Calculating shipping costs
- ✅ Delivery fee calculations
- ✅ Logistics planning
- ✅ Inventory weight tracking

**NOT used for:**
- ❌ Price display (uses the unit you selected)
- ❌ Main product information (uses the unit)

### **Q3: "Will buyers be confused if I sell by bundle but input weight in kg?"**

**A:** No! Buyers will only see "bundle". The kg weight is hidden from the main display.

**Buyers see:**
```
Tomatoes
₱50.00/bundle
20 bundles available
```

**Farmers see (in add product):**
```
Unit: bundle
Weight per Unit (kg): 2.5
```

This lets the system know that 1 bundle = 2.5 kg for shipping calculations.

---

## 📝 Best Practices for Farmers

### **Choosing the Right Unit:**

**For items naturally sold by weight:**
- Rice → `kg` or `sack 25 kg`
- Sugar → `kg` or `bag 25 kg`
- Vegetables (bulk) → `kg`

**For items naturally sold by count:**
- Eggs → `tray` or `dozen`
- Fruits (large) → `pc` (watermelon, pineapple)
- Leafy vegetables → `bundle` or `bunch`

**For packaged items:**
- Bottled products → `bottle`
- Canned goods → `can`
- Jarred items → `jar`

### **Setting Weight Per Unit:**

**Tips:**
1. **Weigh a sample** of your typical unit
2. **Average weight** if items vary
3. **Include packaging** if relevant
4. **Be consistent** across similar products

**Examples:**
- 1 bundle of pechay → weigh it → 0.5 kg
- 1 tray of eggs (30 pcs) → weigh it → 0.66 kg
- 1 watermelon (piece) → average → 3 kg
- 1 dozen garlic bulbs → weigh it → 0.5 kg

---

## 🔧 Technical Implementation

### **Database Fields:**
```sql
products table:
- unit TEXT           -- "bundle", "dozen", "kg", etc.
- price DECIMAL       -- Price per unit
- stock INTEGER       -- Number of units available
- weight_per_unit_kg  -- Weight in kg (for logistics)
```

### **Display Logic:**

**Product Card:**
```dart
'₱${product.price.toStringAsFixed(2)}/${product.unit}'
// Example: ₱50.00/bundle
```

**Stock Display:**
```dart
'${product.stock} ${product.unit} available'
// Example: 20 bundle available
```

**Shipping Calculation:**
```dart
totalWeight = quantity × product.weightPerUnitKg
// Example: 5 bundles × 2.5 kg = 12.5 kg total
```

---

## ✅ Summary

### **What You Need to Know:**

1. **Unit Field** = What buyers see (bundle, dozen, pc, kg, etc.)
2. **Weight Per Unit** = Backend data for logistics (always in kg)
3. **Price** = Price per unit (whatever unit you chose)

### **Examples:**

| Product | Unit | Price | Weight/Unit | Buyer Sees |
|---------|------|-------|-------------|------------|
| Tomatoes | bundle | ₱50 | 2.5 kg | ₱50.00/bundle |
| Eggs | tray | ₱180 | 0.66 kg | ₱180.00/tray |
| Rice | sack 25 kg | ₱1,200 | 25 kg | ₱1,200.00/sack 25 kg |
| Garlic | dozen | ₱60 | 0.5 kg | ₱60.00/dozen |
| Watermelon | pc | ₱120 | 3 kg | ₱120.00/pc |

### **Key Points:**

✅ Unit displays clearly on product cards and details  
✅ Buyers see the unit you selected (not kg)  
✅ Weight in kg is for backend logistics only  
✅ 17 different units available  
✅ System handles both count-based and weight-based products  

---

## 🎉 Improvements Made

1. ✅ Added 9 new units (dozen, tray, box, crate, basket, can, bottle, jar, etc.)
2. ✅ Product cards now show unit clearly (₱50.00/bundle)
3. ✅ Better organized units (weight-based, count-based, container-based)
4. ✅ Clear documentation of how system works

---

**The unit system is flexible, clear, and handles all types of agricultural products!** 📦✨

**Any unit you select will display clearly to buyers, while the kg weight works behind the scenes for logistics.**

---

**Created By:** Rovo Dev AI Assistant  
**Date:** January 22, 2026  
**Status:** ✅ EXPLAINED & IMPROVED
