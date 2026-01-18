-- +goose Up
-- +goose StatementBegin
ALTER TABLE products ADD COLUMN location_name VARCHAR(150) DEFAULT 'Jakarta';
ALTER TABLE products ADD COLUMN latitude DECIMAL(9,6);
ALTER TABLE products ADD COLUMN longitude DECIMAL(9,6);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE products DROP COLUMN IF EXISTS location_name;
ALTER TABLE products DROP COLUMN IF EXISTS latitude;
ALTER TABLE products DROP COLUMN IF EXISTS longitude;
-- +goose StatementEnd
