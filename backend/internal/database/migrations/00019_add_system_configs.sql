-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS system_configs (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_configs (key, value, description) VALUES
('member_registration_fee', '10000', 'Biaya pendaftaran untuk Member (dalam Rupiah)'),
('reseller_registration_fee', '50000', 'Biaya pendaftaran untuk Reseller (dalam Rupiah)'),
('admin_whatsapp_number', '628123456789', 'Nomor WhatsApp Admin untuk bantuan / hubungi penjual'),
('minimum_withdrawal_amount', '20000', 'Batas minimum penarikan dana/saldo komisi (dalam Rupiah)')
ON CONFLICT (key) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS system_configs;
-- +goose StatementEnd
