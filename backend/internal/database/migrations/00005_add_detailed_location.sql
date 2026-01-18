-- +goose Up
-- +goose StatementBegin
ALTER TABLE products ADD COLUMN province VARCHAR(100);
ALTER TABLE products ADD COLUMN regency VARCHAR(100);
ALTER TABLE products ADD COLUMN district VARCHAR(100);
ALTER TABLE products ADD COLUMN village VARCHAR(100);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE products DROP COLUMN IF EXISTS province;
ALTER TABLE products DROP COLUMN IF EXISTS regency;
ALTER TABLE products DROP COLUMN IF EXISTS district;
ALTER TABLE products DROP COLUMN IF EXISTS village;
-- +goose StatementEnd
