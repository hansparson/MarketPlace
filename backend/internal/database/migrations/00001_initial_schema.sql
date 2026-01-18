-- +goose Up
-- +goose StatementBegin
CREATE TYPE user_role AS ENUM ('RESELLER', 'CLIENT');
CREATE TYPE admin_role AS ENUM ('SUPER_ADMIN', 'ADMIN');
CREATE TYPE product_status AS ENUM ('DRAFT', 'ACTIVE', 'SOLD', 'INACTIVE');
CREATE TYPE asset_type AS ENUM ('IMAGE', 'VIDEO');
CREATE TYPE lead_status AS ENUM ('NEW', 'CONTACTED', 'DEAL', 'CANCEL');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) NULL,
    password_hash TEXT NOT NULL DEFAULT 'password123', -- Default for dev
    role user_role NOT NULL DEFAULT 'CLIENT',
    referral_code VARCHAR(20) UNIQUE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role admin_role NOT NULL DEFAULT 'ADMIN',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    parent_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(id),
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price BIGINT NOT NULL,
    status product_status NOT NULL DEFAULT 'DRAFT',
    created_by UUID NOT NULL REFERENCES admins(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    asset_type asset_type NOT NULL,
    object_key TEXT NOT NULL, -- path MinIO
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_resellers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    reseller_id UUID NOT NULL REFERENCES users(id),
    referral_code VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, reseller_id)
);

CREATE TABLE product_clicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    reseller_id UUID NOT NULL REFERENCES users(id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    clicked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    reseller_id UUID NOT NULL REFERENCES users(id),
    client_id UUID NOT NULL REFERENCES users(id),
    phone VARCHAR(20) NOT NULL,
    verified_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expired_at TIMESTAMP NULL
);

CREATE TABLE product_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    reseller_id UUID NOT NULL REFERENCES users(id),
    client_id UUID NOT NULL REFERENCES users(id),
    status lead_status NOT NULL DEFAULT 'NEW',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Seed Data (Development)
INSERT INTO admins (name, email, password_hash, role) 
VALUES ('Super Admin', 'admin@example.com', 'admin123', 'SUPER_ADMIN')
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (name, phone, email, password_hash, role)
VALUES ('Reseller Demo', '081234567890', 'reseller@example.com', 'password123', 'RESELLER')
ON CONFLICT (phone) DO NOTHING;

-- Seed Categories
INSERT INTO categories (name, parent_id) VALUES
('Properti', NULL),
('Kendaraan', NULL),
('Elektronik', NULL),
('Hobi & Olahraga', NULL),
('Perlengkapan Rumah', NULL),
('Fashion', NULL),
('Jasa', NULL)
ON CONFLICT DO NOTHING;

-- Sub-categories for Properti
INSERT INTO categories (name, parent_id) VALUES
('Rumah', (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1)),
('Tanah', (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1)),
('Apartemen', (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1)),
('Ruko', (SELECT id FROM categories WHERE name = 'Properti' LIMIT 1))
ON CONFLICT DO NOTHING;

-- Sub-categories for Kendaraan
INSERT INTO categories (name, parent_id) VALUES
('Mobil', (SELECT id FROM categories WHERE name = 'Kendaraan' LIMIT 1)),
('Motor', (SELECT id FROM categories WHERE name = 'Kendaraan' LIMIT 1)),
('Truk & Kendaraan Komersial', (SELECT id FROM categories WHERE name = 'Kendaraan' LIMIT 1)),
('Spare Parts', (SELECT id FROM categories WHERE name = 'Kendaraan' LIMIT 1))
ON CONFLICT DO NOTHING;

-- Sub-categories for Elektronik
INSERT INTO categories (name, parent_id) VALUES
('Handphone', (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1)),
('Laptop & Komputer', (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1)),
('TV & Audio', (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1)),
('Kamera', (SELECT id FROM categories WHERE name = 'Elektronik' LIMIT 1))
ON CONFLICT DO NOTHING;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS product_leads;
DROP TABLE IF EXISTS product_verifications;
DROP TABLE IF EXISTS product_clicks;
DROP TABLE IF EXISTS product_resellers;
DROP TABLE IF EXISTS product_assets;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS lead_status;
DROP TYPE IF EXISTS asset_type;
DROP TYPE IF EXISTS product_status;
DROP TYPE IF EXISTS admin_role;
DROP TYPE IF EXISTS user_role;
-- +goose StatementEnd
