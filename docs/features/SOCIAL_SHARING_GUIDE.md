# Open Graph Meta Tags untuk WhatsApp Sharing

## Apa yang Sudah Diimplementasikan?

Kami telah menambahkan **dynamic Open Graph meta tags** pada halaman produk (`ProductDetail.tsx`) sehingga ketika link produk dibagikan di WhatsApp, Facebook, Twitter, atau platform social media lainnya, akan menampilkan:

- ✅ **Gambar produk** (bukan logo website)
- ✅ **Judul produk**
- ✅ **Deskripsi produk**
- ✅ **Harga produk**

## Teknologi yang Digunakan

- **react-helmet-async**: Library untuk mengubah meta tags secara dinamis di React SPA

## Meta Tags yang Ditambahkan

```html
<!-- Open Graph (WhatsApp, Facebook) -->
<meta property="og:type" content="product" />
<meta property="og:title" content="[Nama Produk]" />
<meta property="og:description" content="[Deskripsi Produk]" />
<meta property="og:image" content="[URL Gambar Produk]" />
<meta property="og:url" content="[URL Produk]" />
<meta property="product:price:amount" content="[Harga]" />
<meta property="product:price:currency" content="IDR" />

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:image" content="[URL Gambar Produk]" />
```

## ⚠️ PENTING - Limitasi untuk Development

### Masalah dengan Single Page Application (SPA)

React adalah SPA (Single Page Application) yang artinya:
- Meta tags dirender oleh JavaScript di browser
- **WhatsApp crawler TIDAK menjalankan JavaScript**
- WhatsApp hanya membaca HTML statis yang dikirim server

### Solusi Development (Saat Ini)

Implementasi saat ini menggunakan `react-helmet-async` yang **HANYA AKAN BEKERJA** di:
- ✅ Browser (user yang membuka link)
- ✅ Facebook debugger (sebagian)
- ❌ **WhatsApp preview (TIDAK BEKERJA)**
- ❌ Telegram preview
- ❌ Discord preview

## 🚀 Solusi untuk Production

Untuk membuat preview bekerja di WhatsApp, Anda memerlukan salah satu dari:

### Option 1: Server-Side Rendering (SSR) - **RECOMMENDED**

Gunakan framework yang support SSR seperti:

**A. Next.js (Paling Populer)**
```bash
npx create-next-app@latest
```

Keuntungan:
- Built-in SSR
- Dynamic meta tags bekerja sempurna
- SEO friendly
- Mendukung React

**B. Remix**
```bash
npx create-remix@latest
```

### Option 2: Prerendering Service

Gunakan service seperti:
- **Prerender.io**: https://prerender.io
- **Rendertron**: Self-hosted Google solution
- **Netlify Prerendering**: Jika deploy di Netlify

### Option 3: Backend API untuk Meta Tags

Buat endpoint khusus di backend Go Anda:
```go
// Serve HTML dengan meta tags untuk crawlers
GET /og/:product_id
```

Kemudian redirect semua social media crawlers ke endpoint ini.

### Option 4: Static Site Generation (SSG)

Jika produk tidak terlalu banyak berubah:
- Generate static HTML untuk setiap produk
- Deploy di CDN

## 📋 Cara Test

### Test di Development (Limited)

1. **Facebook Sharing Debugger**
   - URL: https://developers.facebook.com/tools/debug/
   - Paste URL produk Anda
   - Klik "Scrape Again"

2. **Twitter Card Validator**
   - URL: https://cards-dev.twitter.com/validator
   - Paste URL produk Anda

3. **LinkedIn Post Inspector**
   - URL: https://www.linkedin.com/post-inspector/
   - Paste URL produk Anda

### ⚠️ Untuk WhatsApp

WhatsApp **TIDAK BISA** di-test di localhost atau development.

Untuk test di WhatsApp, Anda harus:
1. Deploy ke server production dengan domain publik
2. Implement salah satu solusi production di atas
3. Pastikan server bisa diakses dari internet
4. Kirim link ke WhatsApp dan tunggu preview muncul

### Clear WhatsApp Cache

Jika preview WhatsApp sudah pernah cache link Anda:
- WhatsApp menyimpan cache preview sampai 7 hari
- Tidak ada cara manual untuk clear cache
- Solusi: Tambahkan query parameter dummy:
  ```
  https://gostar-mart.online/products/123?v=1
  https://gostar-mart.online/products/123?v=2
  ```

## 🔧 Implementasi Mudah dengan Prerender.io

Jika Anda ingin solusi cepat tanpa mengubah arsitektur:

1. **Daftar di Prerender.io**
   - https://prerender.io
   - Free tier: 250 pages/month

2. **Install Middleware di Nginx**

Edit `nginx/nginx.conf`:
```nginx
location / {
    # Detect crawler
    if ($http_user_agent ~* "WhatsApp|facebookexternalhit|Twitterbot|LinkedInBot") {
        proxy_pass https://service.prerender.io/https://$host$request_uri;
        proxy_set_header X-Prerender-Token YOUR_TOKEN;
        break;
    }
    
    # Normal traffic
    try_files $uri $uri/ /index.html;
}
```

3. **Restart Nginx**
```bash
docker-compose restart nginx
```

## 📝 Next Steps

Pilih salah satu:

### Untuk Quick Fix (15 menit)
✅ **Gunakan Prerender.io** dengan Nginx middleware

### Untuk Long Term (1-2 hari)
✅ **Migration ke Next.js** untuk SSR yang proper

### Untuk Custom Solution (3-5 hari)
✅ **Build meta tags endpoint** di backend Go Anda

## 🧪 Verification

Setelah implement solusi production, verify dengan:

1. **WhatsApp Business API** (jika ada akses)
2. **Send test link** ke nomor WhatsApp lain
3. **Check preview** muncul dengan gambar produk

## 📞 Contact

Jika butuh bantuan lebih lanjut untuk implementasi solusi production, silakan tanyakan!

---

**Last Updated**: 2026-01-15
**Status**: ✅ Development Ready, ⚠️ Production Needs Additional Setup
