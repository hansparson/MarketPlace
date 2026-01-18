# Kategori Produk Gostar Mart

Database sudah diisi dengan kategori-kategori berikut:

## Kategori Utama (Parent Categories)

1. **Properti**
2. **Kendaraan**
3. **Elektronik**
4. **Hobi & Olahraga**
5. **Perlengkapan Rumah**
6. **Fashion**
7. **Jasa**

## Sub-Kategori

### Properti
- Rumah
- Tanah
- Apartemen
- Ruko

### Kendaraan
- Mobil
- Motor
- Truk & Kendaraan Komersial
- Spare Parts

### Elektronik
- Handphone
- Laptop & Komputer
- TV & Audio
- Kamera

## Cara Menambah Kategori Baru

### Via SQL (Manual)
```sql
-- Tambah kategori utama
INSERT INTO categories (name, parent_id) 
VALUES ('Nama Kategori', NULL);

-- Tambah sub-kategori
INSERT INTO categories (name, parent_id) 
VALUES ('Nama Sub-Kategori', 'UUID_PARENT_CATEGORY');
```

### Via API (Coming Soon)
Endpoint untuk CRUD kategori akan ditambahkan di update berikutnya.

## Menggunakan Kategori

Saat membuat produk baru di dashboard admin:
1. Pilih kategori dari dropdown
2. Kategori akan otomatis ter-load dari database
3. Baik parent maupun sub-kategori bisa dipilih

## Struktur Database

```
categories
├── id (UUID)
├── name (VARCHAR)
├── parent_id (UUID, nullable) → references categories(id)
└── created_at (TIMESTAMP)
```

Jika `parent_id` adalah NULL, maka itu adalah kategori utama.
Jika `parent_id` berisi UUID, maka itu adalah sub-kategori.
