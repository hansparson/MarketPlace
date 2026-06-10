-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS mart_client_favorites (
    client_id UUID NOT NULL REFERENCES mart_clients(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (client_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_mart_client_favorites_client_id ON mart_client_favorites(client_id);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS mart_client_favorites;
-- +goose StatementEnd
