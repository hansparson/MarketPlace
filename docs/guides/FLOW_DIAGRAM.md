# Flow Diagram: WhatsApp Sharing dengan Open Graph

## Scenario 1: User Normal (Manusia) Mengakses Link

```
┌─────────────────────────────────────────────────────────────────┐
│  User membuka link:                                             │
│  https://gostar-mart.online/products/abc-123                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  NGINX                                                           │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ Check User-Agent: "Mozilla/5.0 ... Chrome ..."         │     │
│  │ Is it a crawler? ❌ NO                                 │     │
│  │ Decision: Serve React SPA                             │     │
│  └────────────────────────────────────────────────────────┘     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  React Frontend (Vite)                                           │
│  • Serve index.html                                              │
│  • Load React app                                                │
│  • ProductDetail.tsx renders                                     │
│  • Helmet sets meta tags (client-side only)                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  User sees: Beautiful Product Detail Page ✨                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scenario 2: WhatsApp Bot Crawls Link (MAGIC HAPPENS HERE!)

```
┌─────────────────────────────────────────────────────────────────┐
│  WhatsApp Bot crawls:                                            │
│  https://gostar-mart.online/products/abc-123                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  NGINX                                                           │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ Check User-Agent: "WhatsApp/2.x.x"                     │     │
│  │ Is it a crawler? ✅ YES                                │     │
│  │ Decision: Redirect to OG endpoint                      │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Location Match: /products/([a-fA-F0-9-]+)                       │
│  Extract ID: abc-123                                             │
│  Redirect (307): /api/og/product/abc-123                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Go Backend (Echo)                                               │
│  Endpoint: GET /api/og/product/:id                               │
│                                                                   │
│  OGHandler.GetProductOG() executes:                              │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ 1. Parse UUID from "abc-123"                           │     │
│  │ 2. Query database: GetProduct(uuid)                    │     │
│  │ 3. Query database: GetProductAssets(uuid)              │     │
│  │ 4. Build imageURL from MinIO                           │     │
│  │ 5. Prepare HTML template with meta tags                │     │
│  │ 6. Return HTML response                                │     │
│  └────────────────────────────────────────────────────────┘     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  HTML Response with Open Graph Tags:                             │
│                                                                   │
│  <!DOCTYPE html>                                                 │
│  <html>                                                           │
│  <head>                                                           │
│    <meta property="og:title" content="Honda Civic 2020" />       │
│    <meta property="og:description" content="..." />              │
│    <meta property="og:image" content="https://..." />  ⭐       │
│    <meta property="og:url" content="https://..." />              │
│    <meta property="product:price:amount" content="250000000" />  │
│                                                                   │
│    <!-- Auto redirect for humans -->                             │
│    <meta http-equiv="refresh" content="0.1;url=..." />           │
│  </head>                                                          │
│  <body>Loading...</body>                                          │
│  </html>                                                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  WhatsApp Bot reads HTML:                                        │
│  • Extracts og:image → Product Image URL                        │
│  • Extracts og:title → "Honda Civic 2020"                       │
│  • Extracts og:description → Product description                │
│  • Extracts og:price → Rp 250,000,000                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  WhatsApp creates rich preview:                                  │
│  ┌───────────────────────────────────────────────────────┐      │
│  │  ┌──────────────────────────────┐                     │      │
│  │  │                              │                     │      │
│  │  │   [Product Image Preview]    │  ⭐⭐⭐           │      │
│  │  │                              │                     │      │
│  │  └──────────────────────────────┘                     │      │
│  │                                                        │      │
│  │  Gostar Mart                                           │      │
│  │  gostar-mart.online                                    │      │
│  │                                                        │      │
│  │  Honda Civic 2020                                      │      │
│  │  Mobil bekas Honda Civic tahun 2020...                │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                   │
│  User sees product image! ✅                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scenario 3: User Klik Link di WhatsApp

```
┌─────────────────────────────────────────────────────────────────┐
│  User clicks preview in WhatsApp                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Browser opens: https://gostar-mart.online/products/abc-123     │
│  User-Agent: "Mozilla ... Mobile Safari ..."                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  NGINX                                                           │
│  • User-Agent is human browser ❌ NOT a crawler                 │
│  • Serve React SPA normally                                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  User sees full product detail page in browser 🎉               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Architecture Diagram

```
                    Internet/WhatsApp
                            │
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │         Cloudflare Tunnel              │
        │    (gostar-mart.online)                │
        └───────────────┬───────────────────────┘
                        │
                        │
                        ▼
        ┌───────────────────────────────────────┐
        │          NGINX Proxy                   │
        │                                        │
        │  ┌──────────────────────────────────┐ │
        │  │  User Agent Detection            │ │
        │  │  • WhatsApp? → /api/og/*         │ │
        │  │  • Browser? → React SPA          │ │
        │  └──────────────────────────────────┘ │
        └────────┬──────────────────┬───────────┘
                 │                  │
          Crawler│                  │Human
                 │                  │
                 ▼                  ▼
    ┌─────────────────────┐   ┌──────────────────┐
    │  Go Backend         │   │  React Frontend  │
    │  (Echo)             │   │  (Vite)          │
    │                     │   │                  │
    │  /api/og/product/:id│   │  ProductDetail   │
    │       ↓             │   │  + Helmet tags   │
    │  OGHandler          │   └──────────────────┘
    │       ↓             │
    │  PostgreSQL         │
    │  (Products + Assets)│
    │       ↓             │
    │  HTML + OG Tags     │
    └─────────────────────┘
             │
             └─→ Returns HTML with:
                 • og:image → MinIO URL
                 • og:title
                 • og:description
                 • og:price
```

---

## Data Flow for Image URL

```
1. Product created with image uploaded to MinIO
   ↓
2. MinIO stores: marketplace/products/abc-123-image.jpg
   ↓
3. Database stores: object_key = "products/abc-123-image.jpg"
   ↓
4. OG Handler queries database
   ↓
5. Builds full URL: 
   https://gostar-mart.online/minio/marketplace/products/abc-123-image.jpg
   ↓
6. Puts in og:image meta tag
   ↓
7. WhatsApp fetches image from MinIO
   ↓
8. WhatsApp displays in preview ✅
```

---

## Modified Files Summary

```
MarketPlaceProject/
│
├── frontend/
│   ├── index.html                    ← Added default OG tags
│   ├── package.json                  ← Added react-helmet-async
│   └── src/
│       ├── main.tsx                  ← Added HelmetProvider
│       └── pages/
│           └── ProductDetail.tsx     ← Added dynamic Helmet tags
│
├── backend/
│   ├── cmd/server/main.go           ← Added OG route
│   └── internal/handler/
│       └── og_handler.go            ← ⭐ NEW FILE (Main logic)
│
├── nginx/
│   └── nginx.conf                    ← Added crawler detection
│
└── Documentation/
    ├── SOCIAL_SHARING_GUIDE.md
    ├── OG_IMPLEMENTATION_COMPLETE.md
    └── update-og-domain.ps1
```

---

## Testing Sequence

```
Step 1: Test Backend Endpoint
   curl https://gostar-mart.online/api/og/product/[ID]
   ✅ Should return HTML with OG tags

Step 2: Test Nginx Routing
   curl -A "WhatsApp" -L https://gostar-mart.online/products/[ID]
   ✅ Should redirect to /api/og/product/[ID]

Step 3: Test Facebook Debugger
   https://developers.facebook.com/tools/debug/
   ✅ Should show product image in preview

Step 4: Test Real WhatsApp
   Send link to WhatsApp chat
   ✅ Should show product image preview after a few seconds

Step 5: Test User Click
   Click the WhatsApp preview
   ✅ Should open full React product page
```

---

**This diagram explains the complete flow of how WhatsApp now shows product images instead of the website logo! 🎊**
