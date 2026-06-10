-- +goose Up
-- +goose StatementBegin
-- Migration: Add member_commission_amount and reseller_commission_amount columns to products
-- Keeps backward compat with existing commission_amount column

ALTER TABLE products
    ADD COLUMN IF NOT EXISTS member_commission_amount BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reseller_commission_amount BIGINT NOT NULL DEFAULT 0;

-- Migrate existing data: copy commission_amount to both new columns
UPDATE products
SET member_commission_amount = commission_amount,
    reseller_commission_amount = commission_amount
WHERE member_commission_amount = 0 AND reseller_commission_amount = 0;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE products
    DROP COLUMN IF EXISTS member_commission_amount,
    DROP COLUMN IF EXISTS reseller_commission_amount;
-- +goose StatementEnd
