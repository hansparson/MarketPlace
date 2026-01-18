# 🚀 Quick Start - Swagger Documentation

## ✅ Setup Lengkap!

Swagger documentation sudah berhasil disetup dengan **Swaggo**!

## 📋 Cara Buka Swagger UI

### Step 1: Start Backend Server

```powershell
# Dari folder backend
go run cmd/server/main.go
```

### Step 2: Buka Browser

```
http://localhost:8080/swagger/index.html
```

## 🎯 Yang Sudah Dikonfigurasi

✅ **Swaggo Framework** - Generate docs dari code comments  
✅ **Echo Swagger** - Swagger UI terintegrasi di `/swagger/*`  
✅ **JWT Authentication** - Bearer token support  
✅ **2 Endpoints Documented**:
- `POST /api/auth/login/admin` - Admin login
- `POST /api/auth/login/reseller` - Reseller login

## 📝 Next Steps: Tambahkan Dokumentasi untuk Endpoint Lain

Untuk mendokumentasikan endpoint lain, tambahkan annotations seperti contoh di bawah:

### Contoh 1: Public Endpoint (No Auth)

```go
// ListProducts godoc
// @Summary List all products
// @Description Get list of products with filters
// @Tags Public
// @Accept json
// @Produce json
// @Param category query string false "Filter by category"
// @Param search query string false "Search keyword"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} map[string]interface{} "Products retrieved"
// @Router /products [get]
func (h *PublicHandler) ListProducts(c echo.Context) error {
    // ...
}
```

### Contoh 2: Protected Endpoint (Requires JWT)

```go
// CreateProduct godoc
// @Summary Create new product
// @Description Admin creates a new product
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body CreateProductRequest true "Product data"
// @Success 201 {object} map[string]interface{} "Product created"
// @Failure 400 {object} map[string]interface{} "Bad request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /admin/products [post]
func (h *AdminHandler) CreateProduct(c echo.Context) error {
    // ...
}
```

### Contoh 3: With Path Parameter

```go
// GetProduct godoc
// @Summary Get product detail
// @Description Get detailed information of a product
// @Tags Public
// @Accept json
// @Produce json
// @Param id path string true "Product ID"
// @Success 200 {object} map[string]interface{} "Product detail"
// @Failure 404 {object} map[string]interface{} "Product not found"
// @Router /products/{id} [get]
func (h *PublicHandler) GetProduct(c echo.Context) error {
    // ...
}
```

## 🔄 Regenerate Documentation

Setiap kali menambah/update annotations:

```powershell
# Option 1: Menggunakan script
.\generate-swagger.ps1

# Option 2: Manual
swag init -g cmd/server/main.go -o docs
```

## 🎨 Swagger UI Features

Di Swagger UI, Anda bisa:
- ✅ **Lihat semua endpoints** yang terdokumentasi
- ✅ **Test endpoint** langsung dari browser
- ✅ **Lihat request/response schema**
- ✅ **Authenticate dengan JWT token**
- ✅ **Download OpenAPI spec** (JSON/YAML)

## 🔐 Testing dengan JWT

1. Expand endpoint **POST /api/auth/login/admin**
2. Click **"Try it out"**
3. Edit request body:
   ```json
   {
     "email": "admin@marketplace.com",
     "password": "admin123"
   }
   ```
4. Click **"Execute"**
5. **Copy token** dari response
6. Click tombol **"Authorize"** (🔒 di pojok kanan atas)
7. Masukkan: `Bearer <paste-token-here>`
8. Click **"Authorize"**
9. Sekarang endpoint yang butuh auth bisa di-test!

## 📁 File Structure

```
backend/
├── cmd/
│   └── server/
│       └── main.go          # Main annotations
├── docs/                    # Auto-generated (jangan edit manual!)
│   ├── docs.go
│   ├── swagger.json
│   └── swagger.yaml
├── internal/
│   └── handler/
│       ├── auth_handler.go   # ✅ Sudah ada annotations
│       ├── admin_handler.go  # ⏳ Tambahkan annotations
│       ├── client_handler.go # ⏳ Tambahkan annotations
│       └── public_handler.go # ⏳ Tambahkan annotations
├── generate-swagger.ps1     # Generator script
├── SWAGGO_GUIDE.md          # Full guide
└── SWAGGER_QUICKSTART.md    # This file
```

## 🐛 Troubleshooting

### Server tidak bisa start?
```powershell
# Check dependencies
go mod tidy

# Run server
go run cmd/server/main.go
```

### Swagger UI kosong?
1. Pastikan sudah generate: `.\generate-swagger.ps1`
2. Restart server
3. Hard refresh browser (Ctrl+F5)

### Perubahan tidak muncul?
1. Generate ulang: `.\generate-swagger.ps1`
2. Restart server

---

## 📚 Resources

- **Full Guide**: Baca `SWAGGO_GUIDE.md`
- **Swagger Editor**: Buka file `swagger-ui.html` di browser
- **Postman Collection**: Import `Marketplace-API.postman_collection.json`

---

**Selamat menggunakan Swagger! 🎉**
