-- +goose Up
-- +goose StatementBegin
ALTER TABLE product_leads ALTER COLUMN client_id DROP NOT NULL;
ALTER TABLE product_leads ADD COLUMN visitor_phone VARCHAR(20);
ALTER TABLE product_leads ADD COLUMN visitor_name VARCHAR(100);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE product_leads DROP COLUMN visitor_name;
ALTER TABLE product_leads DROP COLUMN visitor_phone;
-- Note: Reverting client_id to NOT NULL might fail if nulls exist, but for dev it's fine or we delete them
DELETE FROM product_leads WHERE client_id IS NULL;
ALTER TABLE product_leads ALTER COLUMN client_id SET NOT NULL;
-- +goose StatementEnd
