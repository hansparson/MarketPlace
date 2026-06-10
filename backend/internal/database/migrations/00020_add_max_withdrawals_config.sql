-- +goose Up
-- +goose StatementBegin
INSERT INTO system_configs (key, value, description) VALUES
('max_withdrawals_per_day', '1', 'Maksimal jumlah penarikan dana yang diizinkan per hari untuk setiap reseller')
ON CONFLICT (key) DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM system_configs WHERE key = 'max_withdrawals_per_day';
-- +goose StatementEnd
