-- +goose Up
-- +goose StatementBegin

-- Add bio and phone_verified_at columns to resellers and members
ALTER TABLE resellers ADD COLUMN IF NOT EXISTS bio TEXT NULL;
ALTER TABLE resellers ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP NULL;

ALTER TABLE members ADD COLUMN IF NOT EXISTS bio TEXT NULL;
ALTER TABLE members ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP NULL;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE resellers DROP COLUMN IF EXISTS bio;
ALTER TABLE resellers DROP COLUMN IF EXISTS phone_verified_at;

ALTER TABLE members DROP COLUMN IF EXISTS bio;
ALTER TABLE members DROP COLUMN IF EXISTS phone_verified_at;
-- +goose StatementEnd
