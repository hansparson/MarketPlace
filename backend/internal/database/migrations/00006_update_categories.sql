-- +goose Up
-- +goose StatementBegin

-- 1. Move products from categories to be deleted to their parent categories
-- Move Apartemen products to Properti
UPDATE products 
SET category_id = (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1)
WHERE category_id = (SELECT id FROM categories WHERE name = 'Apartemen' LIMIT 1);

-- Move Kamera products to Elektronik
UPDATE products 
SET category_id = (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1)
WHERE category_id = (SELECT id FROM categories WHERE name = 'Kamera' LIMIT 1);

-- 2. Delete the unwanted categories
DELETE FROM categories WHERE name IN ('Apartemen', 'Kamera');

-- 3. Make Rumah, Tanah, Mobil, Motor as top-level categories (so they appear in the main bar)
-- These were sub-categories in the initial seed.
UPDATE categories SET parent_id = NULL WHERE name IN ('Rumah', 'Tanah', 'Mobil', 'Motor');

-- 4. Delete the now redundant parent categories if they are empty and not needed
-- Actually, let's keep Properti and Kendaraan but maybe the user wants them gone?
-- The user said "tambahkan Rumah dan Tanah serta mobil dan motor".
-- He also said "untuk kendaraan buat agar merefer ke mobil dan motor".
-- This suggests "Kendaraan" should stay but maybe act as a filter.

-- Make sure we have the categories we need
INSERT INTO categories (name, parent_id)
SELECT 'Tanah', NULL WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Tanah');

INSERT INTO categories (name, parent_id)
SELECT 'Rumah', NULL WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Rumah');

INSERT INTO categories (name, parent_id)
SELECT 'Mobil', NULL WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Mobil');

INSERT INTO categories (name, parent_id)
SELECT 'Motor', NULL WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Motor');

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Reversing this would be complex as we lost the parent-child relationship for specific items.
-- For now, let's just allow it to stay as is or add them back.
INSERT INTO categories (name, parent_id) VALUES ('Apartemen', (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1));
INSERT INTO categories (name, parent_id) VALUES ('Kamera', (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1));
-- +goose StatementEnd
