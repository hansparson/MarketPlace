-- +goose Up
-- +goose StatementBegin

-- 1. Create Enums for Status and Commission Type
CREATE TYPE user_status AS ENUM ('PENDING', 'ACTIVE', 'BLOCKED');
CREATE TYPE commission_user_type AS ENUM ('MEMBER', 'RESELLER');

-- 2. Create Members Table
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NULL,
    password_hash TEXT NOT NULL,
    referral_code VARCHAR(20) UNIQUE NOT NULL, -- Used to recruit resellers
    status user_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create Resellers Table
CREATE TABLE IF NOT EXISTS resellers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NULL REFERENCES members(id) ON DELETE SET NULL, -- Leader
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NULL,
    password_hash TEXT NOT NULL,
    referral_code VARCHAR(20) UNIQUE NOT NULL, -- Used to share products
    status user_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Update Products Table for Commissions
ALTER TABLE products ADD COLUMN IF NOT EXISTS member_commission_amount BIGINT NOT NULL DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS reseller_commission_amount BIGINT NOT NULL DEFAULT 0;

-- 5. Create Member Products (Curation Table)
CREATE TABLE IF NOT EXISTS member_products (
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (member_id, product_id)
);

-- 6. Update Commissions Table
-- First, remove the old foreign key constraint if it exists
DO $$ BEGIN
    ALTER TABLE commissions DROP CONSTRAINT IF EXISTS commissions_reseller_id_fkey;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

-- Add new columns for generic tracking
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS user_type commission_user_type NOT NULL DEFAULT 'RESELLER';
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS user_id UUID; -- Allow null initially for migration
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS referral_code VARCHAR(20) NULL;

-- Migrate existing data: set user_id from reseller_id
UPDATE commissions SET user_id = reseller_id WHERE user_id IS NULL;

-- Now make user_id NOT NULL and optionally drop reseller_id if preferred, 
ALTER TABLE commissions DROP COLUMN reseller_id;
-- ALTER TABLE product_leads DROP COLUMN IF EXISTS reseller_id;

-- 7. Migrate existing resellers from 'users' table to 'resellers' table (Optional/Cleanup)
-- Note: This assumes 'users' table still exists for 'CLIENTS'
INSERT INTO resellers (id, name, phone, email, password_hash, referral_code, status, created_at, updated_at)
SELECT id, name, phone, email, password_hash, COALESCE(referral_code, 'REF-' || substr(id::text, 1, 8)), 'ACTIVE', created_at, updated_at
FROM users
WHERE role = 'RESELLER'
ON CONFLICT (phone) DO NOTHING;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS member_products;
ALTER TABLE products DROP COLUMN IF EXISTS member_commission_amount;
ALTER TABLE products DROP COLUMN IF EXISTS reseller_commission_amount;
DROP TABLE IF EXISTS resellers;
DROP TABLE IF EXISTS members;
-- Note: We don't drop types in case they are used elsewhere, but for completeness:
-- DROP TYPE IF EXISTS commission_user_type;
-- DROP TYPE IF EXISTS user_status;
-- +goose StatementEnd
