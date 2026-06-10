-- +goose Up
-- +goose StatementBegin
ALTER TABLE product_leads ADD COLUMN IF NOT EXISTS member_id UUID REFERENCES members(id) ON DELETE CASCADE;

-- Drop foreign key constraint temporarily if needed, but since reseller_id points to resellers, it's fine.
ALTER TABLE product_leads ALTER COLUMN reseller_id DROP NOT NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE product_leads DROP COLUMN IF EXISTS member_id;
-- Note: Reverting reseller_id to NOT NULL might fail if there are nulls.
-- +goose StatementEnd
