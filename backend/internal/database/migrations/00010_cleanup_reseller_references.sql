-- +goose Up
-- +goose StatementBegin

-- 1. product_clicks
ALTER TABLE product_clicks DROP CONSTRAINT IF EXISTS product_clicks_reseller_id_fkey;
ALTER TABLE product_clicks ADD CONSTRAINT product_clicks_reseller_id_fkey FOREIGN KEY (reseller_id) REFERENCES resellers(id) ON DELETE CASCADE;

-- 2. product_verifications
ALTER TABLE product_verifications DROP CONSTRAINT IF EXISTS product_verifications_reseller_id_fkey;
ALTER TABLE product_verifications ADD CONSTRAINT product_verifications_reseller_id_fkey FOREIGN KEY (reseller_id) REFERENCES resellers(id) ON DELETE CASCADE;

-- 3. product_leads
ALTER TABLE product_leads DROP CONSTRAINT IF EXISTS product_leads_reseller_id_fkey;
ALTER TABLE product_leads ADD CONSTRAINT product_leads_reseller_id_fkey FOREIGN KEY (reseller_id) REFERENCES resellers(id) ON DELETE CASCADE;

-- 4. product_resellers
ALTER TABLE product_resellers DROP CONSTRAINT IF EXISTS product_resellers_reseller_id_fkey;
ALTER TABLE product_resellers ADD CONSTRAINT product_resellers_reseller_id_fkey FOREIGN KEY (reseller_id) REFERENCES resellers(id) ON DELETE CASCADE;

-- 5. payouts
ALTER TABLE payouts DROP CONSTRAINT IF EXISTS payouts_reseller_id_fkey;
ALTER TABLE payouts ADD CONSTRAINT payouts_reseller_id_fkey FOREIGN KEY (reseller_id) REFERENCES resellers(id) ON DELETE CASCADE;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Revert is complex, but basically point back to users(id) if needed
-- +goose StatementEnd
