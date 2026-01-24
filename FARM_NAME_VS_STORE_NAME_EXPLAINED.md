# 🏪 Farm Name vs Store Name - Complete Explanation

## 📋 **Quick Answer**

| Field | Table | Purpose | When Set | Can Change? |
|-------|-------|---------|----------|-------------|
| **`farm_name`** | `farmer_verifications` | Official farm name used during verification | During verification process | ❌ No (verification record) |
| **`store_name`** | `users` | Custom display name for the online store | Can be customized anytime | ✅ Yes (editable) |

---

## 🔍 **Detailed Explanation**

### **1. `farm_name` (farmer_verifications table)**

**Location**: `farmer_verifications.farm_name`

**Purpose**: 
- This is the **official, legal farm name** provided during the verification process
- Used for **verification documentation** and **admin review**
- Part of the permanent verification record

**When it's set**:
```
Farmer Signup → Verification Upload Screen → Enter "Green Valley Farm" → Submit for Review
```

**Characteristics**:
- ✅ **Required** during verification
- ❌ **Cannot be changed** after verification (it's a historical record)
- 📝 **Used for**: Admin verification, legal records, initial store setup
- 🔒 **Stored permanently** in verification history

**Example**:
```sql
farmer_verifications:
  farm_name: "Green Valley Organic Farm"  ← Official name from documents
```

---

### **2. `store_name` (users table)**

**Location**: `users.store_name`

**Purpose**:
- This is the **customizable display name** for the online store
- What **buyers see** when browsing products
- Can be **changed anytime** for branding/marketing

**When it's set**:
```
Option 1: Auto-filled from farm_name after verification approval
Option 2: Farmer customizes it later in "Store Customization" screen
```

**Characteristics**:
- ✅ **Optional** (has fallback logic)
- ✅ **Can be customized** anytime via Store Customization screen
- 📝 **Used for**: Product listings, store front, buyer-facing displays
- 🎨 **Marketing tool** - farmers can rebrand for better appeal

**Example**:
```sql
users:
  store_name: "Green Valley Fresh Produce"  ← Custom marketing name
```

---

## 🔄 **The Relationship**

### **Initial Setup Flow:**

```
1. Farmer submits verification with farm_name: "Juan's Farm"
   ↓
2. Admin approves verification
   ↓
3. System auto-fills users.store_name from farmer_verifications.farm_name
   ↓
4. users.store_name = "Juan's Farm" (initial value)
   ↓
5. Farmer can customize store_name to anything (e.g., "Fresh Harvest by Juan")
```

### **Fallback Logic in Code:**

When displaying store name, the system uses this priority:

```dart
// Priority order:
1. users.store_name (if set and not empty)
2. farmer_verifications.farm_name (from verification)
3. "{full_name}'s Farm" (final fallback)
```

**Example Code:**
```dart
String storeName = 'Farm Store';
if (customStoreName != null && customStoreName.isNotEmpty) {
  storeName = customStoreName;  // ← Uses store_name if available
} else if (farmName != null && farmName.isNotEmpty) {
  storeName = farmName;  // ← Falls back to farm_name
} else {
  storeName = "${fullName}'s Farm";  // ← Final fallback
}
```

---

## 📊 **Real-World Examples**

### **Example 1: Farmer keeps original name**

| Field | Value |
|-------|-------|
| `farm_name` (verification) | "Rodriguez Family Farm" |
| `store_name` (customizable) | "Rodriguez Family Farm" |
| **What buyers see** | "Rodriguez Family Farm" |

### **Example 2: Farmer rebrands for marketing**

| Field | Value |
|-------|-------|
| `farm_name` (verification) | "Rodriguez Family Farm" |
| `store_name` (customizable) | "Fresh Greens by Rodriguez" |
| **What buyers see** | "Fresh Greens by Rodriguez" |

### **Example 3: Farmer hasn't customized yet**

| Field | Value |
|-------|-------|
| `farm_name` (verification) | "Santos Farm" |
| `store_name` (customizable) | `null` (not set) |
| **What buyers see** | "Santos Farm" (fallback) |

### **Example 4: New farmer, no verification**

| Field | Value |
|-------|-------|
| `farm_name` (verification) | `null` (not verified yet) |
| `store_name` (customizable) | `null` (not set) |
| **What buyers see** | "Maria Santos's Farm" (from full_name) |

---

## 🎨 **Where Each is Used**

### **`farm_name` is used in:**
- ✅ Admin verification review screen
- ✅ Verification documents display
- ✅ Historical records
- ✅ Initial store setup (auto-fill)
- ✅ Fallback when store_name is empty

### **`store_name` is used in:**
- ✅ Product listings (buyer view)
- ✅ Search results
- ✅ Store front header
- ✅ Public farmer profile
- ✅ Notifications to buyers
- ✅ Order confirmations

---

## 🛠️ **How to Customize Store Name**

### **Farmer Can Change Via:**

**Path**: `Farmer Dashboard → Menu (⋮) → Store Customization`

**What happens:**
1. Farmer enters new store name: "Fresh Harvest Store"
2. System updates `users.store_name = "Fresh Harvest Store"`
3. All buyer-facing displays update immediately
4. `farmer_verifications.farm_name` remains unchanged (original record preserved)

---

## 💡 **Why Two Separate Fields?**

### **Design Rationale:**

1. **Legal/Verification Integrity**
   - `farm_name` = permanent record for verification/legal purposes
   - Can't be changed to maintain audit trail

2. **Marketing Flexibility**
   - `store_name` = flexible branding tool
   - Farmers can rebrand without re-verification

3. **Data Consistency**
   - Verification records stay intact
   - Store displays stay current

4. **Business Evolution**
   - Farm's legal name: "Juan Dela Cruz Farm" (farm_name)
   - Market brand: "Organic Paradise by Juan" (store_name)

---

## 🔒 **Database Structure**

### **farmer_verifications table:**
```sql
CREATE TABLE farmer_verifications (
    id UUID PRIMARY KEY,
    farmer_id UUID REFERENCES users(id),
    farm_name TEXT NOT NULL,  ← Official name (immutable)
    farm_address TEXT,
    status verification_status,
    ...
);
```

### **users table:**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    full_name TEXT NOT NULL,
    store_name TEXT,  ← Custom display name (editable)
    store_description TEXT,
    store_banner_url TEXT,
    ...
);
```

---

## 📝 **Summary**

| Aspect | `farm_name` | `store_name` |
|--------|-------------|--------------|
| **Purpose** | Legal/verification record | Marketing/display name |
| **Table** | `farmer_verifications` | `users` |
| **Editable** | ❌ No (permanent record) | ✅ Yes (customizable) |
| **Required** | ✅ Yes (for verification) | ❌ No (has fallbacks) |
| **Set during** | Verification process | Store customization |
| **Used for** | Admin review, fallback | Buyer-facing displays |
| **Can be different** | - | ✅ Yes, independent values |

---

## 🎯 **Best Practices**

### **For Farmers:**
- Use `farm_name` for official/legal farm name during verification
- Use `store_name` for creative branding that appeals to buyers
- Keep `store_name` clear, memorable, and searchable

### **For System Design:**
- Always check `store_name` first (preferred display)
- Fall back to `farm_name` if `store_name` is empty
- Never modify `farm_name` after verification approval
- Allow `store_name` updates without re-verification

---

## ✅ **Conclusion**

**`farm_name`** = Official farm identity (permanent, verification)  
**`store_name`** = Marketing identity (flexible, customizable)

Both serve important but different purposes:
- `farm_name` ensures **legal compliance and verification integrity**
- `store_name` enables **marketing flexibility and brand evolution**

This two-field approach gives farmers the best of both worlds: **regulatory compliance** with **creative freedom**! 🌾✨
