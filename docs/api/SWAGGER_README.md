# Swagger API Documentation

## 📚 Dokumentasi API

File `swagger.yaml` berisi dokumentasi lengkap untuk semua endpoint API backend marketplace ini.

## 🚀 Cara Melihat Dokumentasi

### Opsi 1: Menggunakan Swagger UI (Online)

1. Buka [Swagger Editor](https://editor.swagger.io/)
2. Copy isi file `swagger.yaml`
3. Paste di Swagger Editor
4. Dokumentasi akan ditampilkan secara interaktif

### Opsi 2: Menggunakan Swagger UI (Local dengan Docker)

```bash
# Jalankan Swagger UI menggunakan Docker
docker run -p 8081:8080 -e SWAGGER_JSON=/swagger/swagger.yaml -v ${PWD}:/swagger swaggerapi/swagger-ui

# Buka browser di http://localhost:8081
```

### Opsi 3: Menggunakan VSCode Extension

1. Install extension **Swagger Viewer** atau **OpenAPI (Swagger) Editor**
2. Buka file `swagger.yaml`
3. Klik kanan → **Preview Swagger**

### Opsi 4: Mengintegrasikan dengan Backend Echo

Tambahkan Swagger UI langsung ke aplikasi Echo Anda:

```bash
# Install dependency
go get -u github.com/swaggo/echo-swagger
go get -u github.com/swaggo/swag/cmd/swag
```

Kemudian update `main.go`:

```go
import (
    echoSwagger "github.com/swaggo/echo-swagger"
)

// Tambahkan route untuk swagger
e.GET("/swagger/*", echoSwagger.WrapHandler)
```

Lalu akses di: `http://localhost:8080/swagger/index.html`

## 📖 Struktur Dokumentasi

### Tags (Kategori Endpoint)

1. **Auth** - Endpoint untuk autentikasi
   - Admin Login (`POST /api/auth/login/admin`)
   - Reseller Login (`POST /api/auth/login/reseller`)

2. **Public** - Endpoint publik (tanpa autentikasi)
   - List Products (`GET /api/products`)
   - Get Product Detail (`GET /api/products/{id}`)
   - List Categories (`GET /api/categories`)
   - Track Click (`GET /api/track/click`)
   - Submit Lead (`POST /api/leads`)
   - Location API (provinces, regencies, districts, villages)

3. **Admin** - Endpoint untuk admin (requires JWT)
   - Dashboard Stats (`GET /api/admin/dashboard`)
   - Product Management (CRUD)
   - Asset Management (Upload/Delete)
   - Reseller Management (CRUD)
   - Payout Management
   - View Product Leads
   - Mark Product as Sold

4. **Client/Reseller** - Endpoint untuk reseller (requires JWT)
   - Get Share URL (`GET /api/client/products/{id}/share`)
   - Get Analytics (`GET /api/client/products/{id}/analytics`)
   - Get Dashboard Stats (`GET /api/client/stats`)
   - Get Payout History (`GET /api/client/payouts`)

## 🔐 Authentication

### Cara Menggunakan JWT Token

1. **Login** terlebih dahulu melalui endpoint:
   - Admin: `POST /api/auth/login/admin`
   - Reseller: `POST /api/auth/login/reseller`

2. **Copy token** dari response

3. **Set Authorization Header** untuk endpoint yang memerlukan autentikasi:
   ```
   Authorization: Bearer <your-jwt-token>
   ```

### Contoh Request dengan cURL

```bash
# Login Admin
curl -X POST http://localhost:8080/api/auth/login/admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@marketplace.com",
    "password": "admin123"
  }'

# Response akan berisi token
# {
#   "message_data": {
#     "token": "eyJhbGciOiJIUzI1NiIs...",
#     "role": "ADMIN",
#     "user": {...}
#   }
# }

# Gunakan token untuk request berikutnya
curl -X GET http://localhost:8080/api/admin/dashboard \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

## 📝 Response Format

Semua response mengikuti format standar:

### Success Response
```json
{
  "api_call_id": "API_CALL_1234567890",
  "message_action": "ACTION_NAME",
  "message_data": {
    // Data response
  }
}
```

### Error Response
```json
{
  "api_call_id": "API_CALL_1234567890",
  "message_action": "PLEASE_TRY_AGAIN",
  "message_data": "Error message description"
}
```

## 🔍 Fitur-Fitur Utama

### 1. Product Management
- ✅ CRUD operations untuk produk
- ✅ Upload multiple assets (images/videos)
- ✅ Filter berdasarkan kategori, lokasi, dan pencarian
- ✅ Pagination support

### 2. Reseller System
- ✅ Sistem referral dengan kode unik
- ✅ Tracking clicks dan leads
- ✅ Perhitungan komisi otomatis
- ✅ Dashboard statistics

### 3. Payout Management
- ✅ Admin create payout untuk reseller
- ✅ Upload bukti transfer
- ✅ Riwayat payout lengkap
- ✅ Tracking available balance

### 4. Location Integration
- ✅ Integrasi dengan API Wilayah Indonesia
- ✅ Provinsi, Kabupaten/Kota, Kecamatan, Kelurahan
- ✅ Caching untuk performa optimal

### 5. File Storage
- ✅ Integrasi MinIO untuk upload file
- ✅ Support image compression
- ✅ Thumbnail generation
- ✅ Multiple file upload

## 🧪 Testing dengan Postman

Anda juga bisa import file `swagger.yaml` ke Postman:

1. Buka Postman
2. Klik **Import**
3. Pilih **Upload Files**
4. Pilih `swagger.yaml`
5. Postman akan generate collection otomatis

## 📊 Database Schema

API ini menggunakan PostgreSQL dengan schema yang mencakup:
- **users** - Admin dan Reseller accounts
- **products** - Product catalog
- **product_assets** - Images/videos untuk products
- **product_clicks** - Click tracking
- **leads** - Customer leads
- **commissions** - Commission records
- **payouts** - Payout history

## 🛠️ Environment Variables

Pastikan environment variables berikut sudah di-set:

```env
# Database
DB_HOST=postgres
DB_PORT=5432
DB_USER=app_user
DB_PASSWORD=app_password
DB_NAME=app_db

# JWT
JWT_SECRET=your-secret-key

# MinIO
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=marketplace

# Server
PORT=8080
```

## 📞 Support

Jika ada pertanyaan atau issue, silakan hubungi:
- Email: support@marketplace.com
- Documentation: Lihat file `swagger.yaml`

---

**Happy Coding! 🚀**
