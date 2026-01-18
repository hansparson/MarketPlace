# Marketplace Project

Sistem Marketplace dengan fitur Reseller, Tracking Komisi, dan Manajemen Produk.

## 📁 Struktur Proyek

Proyek ini telah dirapikan ke dalam struktur berikut:

- **`/backend`**: Source code GOLANG (Echo Framework)
  - `/cmd/server`: Entry point aplikasi
  - `/internal/handler`: Logika API Handlers (sudah dipisah per kategori)
  - `/internal/database`: Migrasi SQL dan Query (sqlc)
- **`/frontend`**: Source code React (Vite + TypeScript)
  - `/src/pages/admin`: Halaman khusus Admin
  - `/src/pages/reseller`: Halaman khusus Reseller
  - `/src/pages/public`: Halaman publik (Home, Detail, Login)
- **`/docs`**: Dokumentasi fitur dan panduan sistem
  - `/api`: Postman Collection dan dokumentasi Swagger
  - `/features`: Detail implementasi fitur (Stock, Sorting, dll)
  - `/guides`: Panduan setup dan troubleshooting
- **`/scripts`**: Script bantuan (database migration, minio setup, dll)

## 🚀 Cara Menjalankan

### Backend
1. Masuk ke folder `backend`
2. Jalankan `go run cmd/server/main.go` atau gunakan `make run`

### Frontend
1. Masuk ke folder `frontend`
2. Jalankan `npm install` (jika pertama kali)
3. Jalankan `npm run dev`

### Docker (Full Stack)
Jalankan `docker-compose up -d` di folder root.

## 🛠️ Tech Stack
- **Backend**: Go, Echo, PostgreSQL, Redis, MinIO (S3)
- **Frontend**: React, Tailwind CSS, Lucide React
- **Logging**: Zerolog
- **API Docs**: Swagger (Swaggo)
