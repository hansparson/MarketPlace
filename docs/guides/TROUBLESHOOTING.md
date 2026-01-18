# TROUBLESHOOTING: Internal Server Error saat Create Product

## Root Cause
Error: `products_created_by_fkey` constraint violation

**Penyebab**: Admin ID dari JWT token tidak cocok dengan ID di database (kemungkinan karena database di-reset tapi masih menggunakan token lama)

## Solution

### Step 1: Logout dan Clear Token
1. Buka browser DevTools (F12)
2. Go to Console tab
3. Jalankan command:
```javascript
localStorage.clear()
```
4. Refresh halaman

### Step 2: Login Ulang
1. Buka: http://localhost:3000/auth/login/admin
2. Login dengan:
   - Email: `admin@example.com`
   - Password: `admin123`
3. Anda akan di-redirect ke dashboard

### Step 3: Test Create Product
1. Klik "Add Product"
2. Isi form
3. Submit

## Verification

### Cek Admin ID di Database
```powershell
docker exec -it postgres psql -U app_user -d app_db -c "SELECT id, name, email FROM admins;"
```

Output seharusnya:
```
                  id                  |    name     |       email        
--------------------------------------+-------------+--------------------
 2686cf91-4175-43a3-a516-239ec4e4cbee | Super Admin | admin@example.com
```

### Cek Token di Browser
1. Buka DevTools → Application → Local Storage
2. Lihat key `token`
3. Copy token value
4. Decode di https://jwt.io
5. Pastikan `user_id` di payload sama dengan admin ID di database

## Alternative: Reset Everything

Jika masih error, reset semua:

```powershell
# 1. Stop semua container
docker-compose down -v

# 2. Start ulang
docker-compose up -d

# 3. Wait for services
Start-Sleep -Seconds 10

# 4. Run migration
cd backend
.\migrate.ps1 up

# 5. Setup MinIO
cd ..
.\setup-minio.ps1

# 6. Login ulang di browser
```

## Expected Logs (Success)

Saat login:
```
[AdminLogin] Login successful - Admin ID: 2686cf91-4175-43a3-a516-239ec4e4cbee, Role: SUPER_ADMIN
```

Saat create product:
```
[CreateProduct] Request: {category_id:... title:... description:... price:...}
[CreateProduct] User ID from JWT: 2686cf91-4175-43a3-a516-239ec4e4cbee
[CreateProduct] Creating product with catID=..., adminID=2686cf91-4175-43a3-a516-239ec4e4cbee
[CreateProduct] Product created successfully: ...
```

## Quick Fix Script

Save as `fix-auth.ps1`:
```powershell
Write-Host "Fixing authentication issue..." -ForegroundColor Cyan

# Get current admin ID
$adminId = docker exec postgres psql -U app_user -d app_db -t -c "SELECT id FROM admins LIMIT 1;" | ForEach-Object { $_.Trim() }

Write-Host "Current Admin ID in database: $adminId" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please do the following:" -ForegroundColor Green
Write-Host "1. Open browser DevTools (F12)" -ForegroundColor White
Write-Host "2. Go to Console" -ForegroundColor White
Write-Host "3. Run: localStorage.clear()" -ForegroundColor White
Write-Host "4. Login again at http://localhost:3000/auth/login/admin" -ForegroundColor White
Write-Host ""
Write-Host "Credentials:" -ForegroundColor Cyan
Write-Host "Email: admin@example.com" -ForegroundColor White
Write-Host "Password: admin123" -ForegroundColor White
```

Run dengan:
```powershell
.\fix-auth.ps1
```
