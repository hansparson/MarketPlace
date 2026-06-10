-- +goose Up
-- +goose StatementBegin

-- 1. Tambah kolom nomor DANA di tabel members & resellers untuk disbursement
ALTER TABLE members ADD COLUMN IF NOT EXISTS dana_phone VARCHAR(20) NULL;
ALTER TABLE resellers ADD COLUMN IF NOT EXISTS dana_phone VARCHAR(20) NULL;

-- 2. Ubah default status Reseller baru menjadi 'PENDING' agar membutuhkan aktivasi berbayar
ALTER TABLE resellers ALTER COLUMN status SET DEFAULT 'PENDING';

-- 3. Buat tabel Invoice Pembayaran Registrasi
CREATE TABLE IF NOT EXISTS registration_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_type VARCHAR(10) NOT NULL, -- 'MEMBER' atau 'RESELLER'
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    amount BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'EXPIRED', 'FAILED'
    payment_url TEXT NULL,
    external_id VARCHAR(100) NULL, -- ID Transaksi dari DANA
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Perbarui tabel Payouts untuk melacak status transfer otomatis DANA
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS'; -- 'PENDING', 'SUCCESS', 'FAILED'
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS dana_transaction_id VARCHAR(100) NULL;
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS merchant_trans_id VARCHAR(100) UNIQUE NULL;
ALTER TABLE payouts ADD COLUMN IF NOT EXISTS failed_reason TEXT NULL;
ALTER TABLE payouts ALTER COLUMN proof_object_key DROP NOT NULL; -- Nullable karena transfer DANA tidak memerlukan unggahan bukti manual

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE resellers ALTER COLUMN status SET DEFAULT 'ACTIVE';
DROP TABLE IF EXISTS registration_payments;
ALTER TABLE payouts DROP COLUMN IF EXISTS status;
ALTER TABLE payouts DROP COLUMN IF EXISTS dana_transaction_id;
ALTER TABLE payouts DROP COLUMN IF EXISTS merchant_trans_id;
ALTER TABLE payouts DROP COLUMN IF EXISTS failed_reason;
ALTER TABLE payouts ALTER COLUMN proof_object_key SET NOT NULL;
ALTER TABLE resellers DROP COLUMN IF EXISTS dana_phone;
ALTER TABLE members DROP COLUMN IF EXISTS dana_phone;
-- +goose StatementEnd
