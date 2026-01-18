-- +goose Up
-- +goose StatementBegin
-- Tambahkan kolom stock ke table products
ALTER TABLE products 
ADD COLUMN stock INTEGER NOT NULL DEFAULT 0;

-- Set stock default untuk produk yang sudah ada
UPDATE products SET stock = 1 WHERE stock = 0;

-- Tambahkan comment
COMMENT ON COLUMN products.stock IS 'Jumlah stok produk yang tersedia. 0 = Habis, >0 = Tersedia';

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE products DROP COLUMN IF EXISTS stock;
-- +goose StatementEnd
