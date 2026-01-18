# 📚 Swagger Documentation dengan Swaggo

## ✅ Setup Berhasil!

Swagger documentation sudah berhasil disetup menggunakan **Swaggo** untuk Golang!

## 🚀 Cara Melihat Dokumentasi

### 1. Start Backend Server

```bash
go run cmd/server/main.go
```

### 2. Buka Swagger UI di Browser

```
http://localhost:8080/swagger/index.html
```

🎉 **Selesai!** Anda akan melihat dokumentasi API yang interaktif!

## 📝 Cara Menambahkan Dokumentasi

Swagger documentation di-generate otomatis dari **comment annotations** di code Golang Anda.

### Contoh: Dokumentasi untuk Endpoint

```go
// AdminLogin godoc
// @Summary Admin login
// @Description Login untuk admin dan super admin
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body LoginRequest true "Login credentials"
// @Success 200 {object} map[string]interface{} "Login successful"
// @Failure 400 {object} map[string]interface{} "Bad request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /auth/login/admin [post]
func (h *AuthHandler) AdminLogin(c echo.Context) error {
    // ... implementation
}
```

### Contoh: Dokumentasi dengan Security (JWT Required)

```go
// GetDashboard godoc
// @Summary Get dashboard statistics
// @Description Mendapatkan statistik dashboard untuk admin
// @Tags Admin
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Dashboard data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /admin/dashboard [get]
func (h *AdminHandler) GetDashboard(c echo.Context) error {
    // ... implementation
}
```

### Annotations yang Tersedia

| Annotation | Deskripsi | Contoh |
|------------|-----------|---------|
| `@Summary` | Ringkasan singkat endpoint | `@Summary Get all products` |
| `@Description` | Deskripsi detail | `@Description Mendapatkan semua produk...` |
| `@Tags` | Kategori endpoint | `@Tags Admin` |
| `@Accept` | Content-Type yang diterima | `@Accept json` |
| `@Produce` | Content-Type yang dihasilkan | `@Produce json` |
| `@Param` | Parameter request | `@Param id path string true "Product ID"` |
| `@Success` | Response sukses | `@Success 200 {object} Product` |
| `@Failure` | Response error | `@Failure 404 {object} Error` |
| `@Router` | Path dan HTTP method | `@Router /products/{id} [get]` |
| `@Security` | Authentication required | `@Security BearerAuth` |

### Parameter Types

- **path** - Parameter di URL path (`/products/:id`)
- **query** - Query string (`?limit=10`)
- **body** - Request body (JSON)
- **header** - HTTP header
- **formData** - Form data (multipart/form-data)

## 🔄 Generate Ulang Dokumentasi

Setiap kali Anda **menambah atau mengubah endpoint**, jalankan:

```bash
# Cara 1: Menggunakan script
.\generate-swagger.ps1

# Cara 2: Manual
swag init -g cmd/server/main.go -o docs
```

## 📂 File yang Di-generate

```
backend/
├── docs/
│   ├── docs.go          # Documentation code
│   ├── swagger.json     # JSON format
│   └── swagger.yaml     # YAML format
```

## 🎨 Customize Dokumentasi

Edit metadata di `cmd/server/main.go`:

```go
// @title Marketplace API
// @version 1.0
// @description API untuk sistem marketplace

// @contact.name API Support
// @contact.email support@marketplace.com

// @host localhost:8080
// @BasePath /api

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
```

## 🔐 Testing dengan Authentication

1. **Login** melalui endpoint `/api/auth/login/admin` atau `/api/auth/login/reseller`
2. **Copy JWT token** dari response
3. **Klik tombol "Authorize"** di Swagger UI (pojok kanan atas)
4. **Paste token** dalam format: `Bearer <token>`
5. **Klik "Authorize"**
6. Sekarang Anda bisa test endpoint yang memerlukan authentication!

## 📚 Referensi

- [Swaggo Documentation](https://github.com/swaggo/swag)
- [Echo Swagger](https://github.com/swaggo/echo-swagger)
- [Swagger Spec](https://swagger.io/specification/)

## 🛠️ Troubleshooting

### Error: "swag: command not found"

```bash
# Install swag CLI
go install github.com/swaggo/swag/cmd/swag@latest

# Atau run generate script
.\generate-swagger.ps1
```

### Error: "undefined: docs"

Pastikan Anda sudah run `swag init`:
```bash
swag init -g cmd/server/main.go -o docs
```

### Dokumentasi tidak update

1. Generate ulang: `.\generate-swagger.ps1`
2. Restart server

---

**Happy Documenting! 🚀**
