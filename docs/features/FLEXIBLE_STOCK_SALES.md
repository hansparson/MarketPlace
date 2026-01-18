# 📦 FLEXIBLE STOCK SALES - MARK AS SOLD WITH UNITS

## ✨ Overview

Fitur **Mark as Sold** sekarang **fleksibel**! Admin bisa menentukan **berapa unit yang terjual**, bukan otomatis mark seluruh stock sebagai sold.

---

## 🔄 How It Works

### Flow Baru:

```
Admin klik "Mark as Sold"
    ↓
Modal muncul: "Berapa unit yang terjual?"
    ↓
Admin input: 2 unit (dari 5 total)
    ↓
System process:
  - Stock: 5 → 3
  - Status: ACTIVE (masih ada stock)
    ↓
Success! Product masih aktif dengan 3 unit tersedia
```

### Smart Status Logic:

```
IF remaining_stock > 0:
  → Status: ACTIVE
  → Product tetap tampil di marketplace

IF remaining_stock <= 0:
  → Status: SOLD
  → Stock: 0
  → Product marked as sold
```

---

## 🎯 Use Cases

### Case 1: Partial Sale (Ada Sisa Stock)
```
Current:
  Stock: 10 unit
  Status: ACTIVE

Admin sells 3 units:
  units_sold: 3

Result:
  Stock: 7 unit  ← Masih ada!
  Status: ACTIVE ← Tetap aktif
  Message: "Successfully sold 3 unit(s). Remaining stock: 7"
```

### Case 2: Complete Sale (Stock Habis)
```
Current:
  Stock: 5 unit
  Status: ACTIVE

Admin sells 5 units:
  units_sold: 5

Result:
  Stock: 0 unit
  Status: SOLD  ← Auto change!
  Message: "Successfully sold 5 unit(s). Remaining stock: 0. Product marked as SOLD."
```

### Case 3: Over-sell Protection
```
Current:
  Stock: 3 unit
  Status: ACTIVE

Admin tries to sell 5 units:
  units_sold: 5

Result:
  ❌ ERROR: "Not enough stock. Available: 3, Requested: 5"
  Stock: 3 unit  ← Unchanged
  Status: ACTIVE ← Unchanged
```

---

## 🔧 API Changes

### Endpoint: POST /api/admin/products/:id/sold

**Request Body (NEW):**
```json
{
  "units_sold": 2,              // ← NEW! Required
  "lead_id": "uuid-of-lead"     // Optional
}
```

**Success Response:**
```json
{
  "api_call_id": "API_CALL_xxx",
  "message_action": "PRODUCT_UPDATED",
  "message_data": {
    "message": "Successfully sold 2 unit(s). Remaining stock: 3",
    "units_sold": 2,
    "remaining_stock": 3,
    "status": "ACTIVE"
  }
}
```

**Error Response (Not Enough Stock):**
```json
{
  "error": "Not enough stock. Available: 1, Requested: 5"
}
```

**Error Response (Invalid Units):**
```json
{
  "error": "units_sold must be greater than 0"
}
```

---

## 📊 Database Updates

### Example Scenario:

**Initial State:**
```sql
SELECT title, stock, status FROM products WHERE id = 'xxx';

title        | stock | status
-------------|-------|-------
Honda Civic  | 10    | ACTIVE
```

**Admin sells 3 units:**
```json
POST /products/xxx/sold
{ "units_sold": 3 }
```

**Result:**
```sql
title        | stock | status
-------------|-------|-------
Honda Civic  | 7     | ACTIVE  ← Still active!
```

**Admin sells 7 more units:**
```json
POST /products/xxx/sold
{ "units_sold": 7 }
```

**Result:**
```sql
title        | stock | status
-------------|-------|-------
Honda Civic  | 0     | SOLD    ← Auto marked sold!
```

---

## 🎨 Frontend UI (Recommended)

### Modal Design:

```
┌─────────────────────────────────────────┐
│ Mark Product as Sold                    │
├─────────────────────────────────────────┤
│                                         │
│ Product: Honda Civic 2020               │
│ Current Stock: 10 unit                  │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ How many units sold?              │   │
│ │ ┌───────────────────────────────┐ │   │
│ │ │ 2                             │ │   │
│ │ └───────────────────────────────┘ │   │
│ │ Remaining: 8 unit                 │   │
│ └───────────────────────────────────┘   │
│                                         │
│ Select Lead (Optional):                 │
│ ┌───────────────────────────────────┐   │
│ │ John Doe - 081234567890       ▼  │   │
│ └───────────────────────────────────┘   │
│                                         │
│ [Cancel]              [Confirm Sale]    │
└─────────────────────────────────────────┘
```

### Live Calculation:
```javascript
const [unitsSold, setUnitsSold] = useState(1);
const remainingStock = product.stock - unitsSold;

// Show warning if stock will be 0
{remainingStock === 0 && (
  <div className="warning">
    ⚠️ This will mark the product as SOLD
  </div>
)}

// Show remaining stock
<p>Remaining: {remainingStock} unit(s)</p>
```

---

## ✅ Validation Rules

### Backend Validation:

1. **`units_sold` required**
   ```
   ❌ null → Error: "units_sold is required"
   ❌ 0 → Error: "units_sold must be greater than 0"
   ❌ -5 → Error: "units_sold must be greater than 0"
   ✅ 1 → Valid
   ```

2. **Stock availability check**
   ```
   Current stock: 5
   ❌ units_sold: 10 → Error: "Not enough stock"
   ✅ units_sold: 3 → Valid (2 remaining)
   ✅ units_sold: 5 → Valid (0 remaining, mark SOLD)
   ```

3. **Product must exist**
   ```
   ❌ Invalid UUID → Error: Bad Request
   ❌ Product not found → Error: Not Found
   ```

---

## 🧪 Testing Guide

### Test Case 1: Sell Partial Stock
```bash
# Setup: Product with 10 units
curl -X POST http://localhost:8080/api/admin/products/xxx/sold \
  -H "Authorization: Bearer TOKEN" \
  -d '{"units_sold": 3}'

# Verify:
✅ Stock: 7
✅ Status: ACTIVE
✅ Response: "Successfully sold 3 unit(s). Remaining stock: 7"
```

### Test Case 2: Sell All Stock
```bash
# Setup: Product with 5 units
curl -X POST http://localhost:8080/api/admin/products/xxx/sold \
  -H "Authorization: Bearer TOKEN" \
  -d '{"units_sold": 5}'

# Verify:
✅ Stock: 0
✅ Status: SOLD
✅ Response: "...Remaining stock: 0. Product marked as SOLD."
```

### Test Case 3: Over-sell Protection
```bash
# Setup: Product with 2 units
curl -X POST http://localhost:8080/api/admin/products/xxx/sold \
  -H "Authorization: Bearer TOKEN" \
  -d '{"units_sold": 10}'

# Verify:
❌ Error: "Not enough stock. Available: 2, Requested: 10"
✅ Stock: 2 (unchanged)
✅ Status: ACTIVE (unchanged)
```

### Test Case 4: Invalid Units
```bash
curl -X POST http://localhost:8080/api/admin/products/xxx/sold \
  -H "Authorization: Bearer TOKEN" \
  -d '{"units_sold": 0}'

# Verify:
❌ Error: "units_sold must be greater than 0"
```

### Test Case 5: With Lead (Commission)
```bash
curl -X POST http://localhost:8080/api/admin/products/xxx/sold \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "units_sold": 1,
    "lead_id": "lead-uuid-xxx"
  }'

# Verify:
✅ Stock reduced
✅ Commission created for reseller
✅ Lead processed
```

---

## 💡 Benefits

### 1. **Flexibility**
- Admin bisa jual sebagian stock
- Tidak perlu mark langsung SOLD

### 2. **Accurate Tracking**
- Real-time stock updates
- Exact inventory management

### 3. **Auto Status Management**
- Stock habis → Auto SOLD
- Stock masih ada → Tetap ACTIVE

### 4. **Prevent Errors**
- Validation prevents over-selling
- Clear error messages

### 5. **Better UX**
- Admin control berapa unit sold
- Customers lihat stock yang akurat

---

## 🚀 Next Steps (Implementation)

### Backend: ✅ DONE
- [x] Accept `units_sold` parameter
- [x] Calculate new stock
- [x] Smart status logic
- [x] Validation
- [x] Error handling

### Frontend: 🔨 TODO
- [ ] Update modal UI
- [ ] Add units_sold input field
- [ ] Show remaining stock calculation
- [ ] Validation on frontend
- [ ] Update success message display

### Frontend Code Example:
```typescript
// AdminDashboard.tsx - Mark as Sold Modal
const [unitsSold, setUnitsSold] = useState(1);

const handleMarkSold = async () => {
  try {
    const res = await client.post(
      `/admin/products/${product.id}/sold`,
      {
        units_sold: unitsSold,  // Send units sold
        lead_id: selectedLead   // Optional
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    alert(res.data.message_data.message);
    // Refresh product list
  } catch (err) {
    alert(err.response?.data?.error || 'Failed');
  }
};
```

---

## 📋 Summary

### What Changed:

**Before:**
- Mark sold → Stock = 0 (forced)
- Status = SOLD (always)

**After:**
- Mark sold → Input berapa unit
- Stock = current - units_sold
- Status = SOLD (if stock ≤ 0) or ACTIVE (if stock > 0)

### API Request:
```json
{
  "units_sold": 2  // NEW requirement!
}
```

### Response:
```json
{
  "message": "Successfully sold 2 unit(s). Remaining stock: 3",
  "units_sold": 2,
  "remaining_stock": 3,
  "status": "ACTIVE"
}
```

---

**Status**: ✅ Backend Implemented  
**Frontend Update**: Required  
**Test**: Manual testing needed  

**Created**: 2026-01-15  
**Version**: 2.0 - Flexible Stock Sales
