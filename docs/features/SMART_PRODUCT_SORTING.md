# 📊 SMART PRODUCT SORTING - AVAILABILITY FIRST

## ✨ Overview

Product Management di Admin Dashboard sekarang menggunakan **smart sorting** yang memprioritaskan produk berdasarkan availability, lalu waktu.

---

## 🎯 Sorting Logic

### Priority Order:

```
1. Stock Availability
   ├─ Stock > 0  (Products Available) ← Prioritas Tertinggi
   └─ Stock = 0  (Out of Stock/Sold)

2. Creation Time
   └─ Newest First (created_at DESC)
```

### SQL Query:
```sql
ORDER BY 
    CASE WHEN stock > 0 THEN 0 ELSE 1 END ASC,  -- Available products first
    created_at DESC                              -- Then newest first
```

---

## 📋 Display Order Examples

### Before (Old Sorting):
```
Sorting: created_at DESC only

1. test         - SOLD     - Added 4 hours ago
2. motor        - SOLD     - Added 4 hours ago  
3. Jam Tangan   - SOLD     - Added 3 hours ago
4. Terios       - SOLD     - Added 3 hours ago
5. Honda        - ACTIVE   - Added 3 hours ago  ← Available, but at bottom!
```

### After (New Smart Sorting):
```
Sorting: Stock availability → created_at DESC

1. Honda        - ACTIVE   - Stock: 5  - Added 3 hours ago  ← Available first!
2. Terios       - SOLD     - Stock: 0  - Added 3 hours ago
3. Jam Tangan   - SOLD     - Stock: 0  - Added 3 hours ago
4. motor        - SOLD     - Stock: 0  - Added 4 hours ago
5. test         - SOLD     - Stock: 0  - Added 4 hours ago
```

---

## 💡 Benefits

### 1. **Better Visibility**
- ✅ Available products always on top
- ✅ Admin langsung lihat produk yang ready
- ✅ Easier inventory management

### 2. **Improved Workflow**
- ✅ Quick access to active products
- ✅ Less scrolling untuk cari produk available
- ✅ Focus on what matters (stock available)

### 3. **Logical Grouping**
- ✅ Available products grouped together
- ✅ Sold/Out of stock grouped separately
- ✅ Within each group: newest first

---

## 🔄 Sorting Behavior

### Scenario 1: All Products Have Stock
```
Honda       - Stock: 10 - Added 2024-01-15 10:00
Civic       - Stock: 5  - Added 2024-01-15 09:00
Jazz        - Stock: 3  - Added 2024-01-15 08:00

Result: Sorted by time (newest first)
1. Honda (newest)
2. Civic
3. Jazz
```

### Scenario 2: Mixed Stock Levels
```
Honda       - Stock: 10 - Added 2024-01-15 08:00
Civic       - Stock: 0  - Added 2024-01-15 10:00 (newest, but no stock)
Jazz        - Stock: 5  - Added 2024-01-15 09:00

Result: Available first, then by time
1. Honda    (stock > 0, oldest among available)
2. Jazz     (stock > 0, newer among available)
3. Civic    (stock = 0, newest but no stock)
```

### Scenario 3: After Partial Sale
```
Initial:
Honda - Stock: 5 - Position: #1

Admin sells 2 units:
Honda - Stock: 3 - Position: Still #1 (stock > 0)

Admin sells 3 more units:
Honda - Stock: 0 - Position: Moves down (no stock)
```

---

## 🎨 Visual Representation

```
┌─────────────────────────────────────────┐
│ AVAILABLE PRODUCTS                      │ ← Priority Section
├─────────────────────────────────────────┤
│ ✓ Honda      | Stock: 5  | 3 hrs ago   │
│ ✓ Civic      | Stock: 2  | 4 hrs ago   │
│ ✓ Jazz       | Stock: 10 | 1 day ago   │
├─────────────────────────────────────────┤
│ OUT OF STOCK / SOLD                     │ ← Secondary Section
├─────────────────────────────────────────┤
│ ✗ Terios     | Stock: 0  | 3 hrs ago   │
│ ✗ Motor      | Stock: 0  | 4 hrs ago   │
│ ✗ Test       | Stock: 0  | 4 hrs ago   │
└─────────────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Backend Query Update:
```sql
-- File: backend/internal/database/queries/products.sql

-- name: AdminListProducts :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a 
              WHERE a.product_id = p.id 
              AND a.asset_type::text ILIKE 'image' 
              LIMIT 1), '')::text as thumbnail_url
FROM products p
ORDER BY 
    CASE WHEN p.stock > 0 THEN 0 ELSE 1 END ASC,  -- Stock priority
    p.created_at DESC                              -- Time priority
LIMIT $1 OFFSET $2;
```

### How It Works:
```
CASE WHEN stock > 0 THEN 0 ELSE 1 END ASC

If stock > 0:  value = 0  ← Sorted first (ASC)
If stock = 0:  value = 1  ← Sorted last

Then within each group: created_at DESC (newest first)
```

---

## 📊 Pagination Support

Sorting works seamlessly with pagination:

```
Page 1:
1. Available products (newest first)
2. ...

Page 2:
1. More available products (older)
2. Sold products (if available section ended)
3. ...
```

---

## ✅ Testing

### Test Case 1: Create New Product with Stock
```
Action: Create product with stock = 5
Expected: Product appears at top of list
Result: ✅ Product shown first
```

### Test Case 2: Sell Product Partially
```
Initial: Product at position #1 (stock = 5)
Action: Sell 2 units
Result: ✅ Still at position #1 (stock = 3 > 0)
```

### Test Case 3: Sell Product Completely
```
Initial: Product at position #1 (stock = 3)
Action: Sell 3 units (all remaining)
Result: ✅ Moves down to "sold" section (stock = 0)
```

### Test Case 4: Edit Stock Back to Available
```
Initial: Product in sold section (stock = 0)
Action: Edit stock to 10
Result: ✅ Moves back to top section (stock > 0)
```

---

## 💭 Use Case Scenarios

### Admin Morning Routine:
```
1. Opens Admin Dashboard
2. Sees all available products immediately
3. Can quickly:
   - Check inventory
   - Update prices on active products
   - Add new stock
4. Sold products don't clutter the view
```

### Inventory Check:
```
Admin wants to know "What's available right now?"
→ Just look at the top section!
→ All available products are there
→ No need to scroll through sold items
```

---

## 🚀 Future Enhancements (Optional)

### 1. **Low Stock Warning**
```
Highlight products with stock < 5:
⚠️ Honda - Stock: 2 (Low Stock!)
```

### 2. **Stock Filters**
```
[All] [In Stock] [Low Stock] [Out of Stock]
```

### 3. **Custom Sort Options**
```
Sort by:
- Availability & Time (default) ✓
- Price (high to low)
- Stock level (high to low)
- Category
```

### 4. **Stock Level Indicator**
```
Visual bars:
Honda     ████████░░ 80% (8/10)
Civic     ███░░░░░░░ 30% (3/10)
Terios    ░░░░░░░░░░  0% (0/10)
```

---

## 📝 Summary

### What Changed:
**Before:**
- Sorted by `created_at DESC` only
- Available products mixed with sold items
- Hard to find what's in stock

**After:**
- Sorted by `stock availability` first
- Then by `created_at DESC`
- Available products always on top
- Clear separation

### Benefits:
- ✅ Better visibility
- ✅ Faster workflow
- ✅ Logical grouping
- ✅ Improved UX

---

**Status**: ✅ Implemented & Deployed  
**Impact**: High - Significantly improves admin workflow  
**Version**: 1.0  
**Date**: 2026-01-15
