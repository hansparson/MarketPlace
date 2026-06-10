-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS mart_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    google_id VARCHAR(255) UNIQUE NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NULL,
    phone VARCHAR(20) UNIQUE NULL,
    referral_code_used VARCHAR(20) NULL,
    status user_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookup by google_id or email
CREATE INDEX IF NOT EXISTS idx_mart_clients_google_id ON mart_clients(google_id);
CREATE INDEX IF NOT EXISTS idx_mart_clients_email ON mart_clients(email);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS mart_clients;
-- +goose StatementEnd
