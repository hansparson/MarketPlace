-- +goose Up
-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS idx_commissions_user_search ON commissions(user_id, user_type);
CREATE INDEX IF NOT EXISTS idx_payouts_user_search ON payouts(user_id, user_type);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP INDEX IF EXISTS idx_commissions_user_search;
DROP INDEX IF EXISTS idx_payouts_user_search;
-- +goose StatementEnd
