-- +goose Up
-- +goose StatementBegin
ALTER TABLE commissions ALTER COLUMN product_id DROP NOT NULL;

INSERT INTO system_configs (key, value, description) VALUES
('reseller_referral_commission', '10000', 'Komisi untuk Member/Leader ketika Reseller mendaftar (dalam Rupiah)')
ON CONFLICT (key) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM system_configs WHERE key = 'reseller_referral_commission';
ALTER TABLE commissions ALTER COLUMN product_id SET NOT NULL;
-- +goose StatementEnd
