-- +goose Up
-- +goose StatementBegin
-- Add specifications column to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS specifications JSONB NOT NULL DEFAULT '[]';
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE products DROP COLUMN specifications;
-- +goose StatementEnd
