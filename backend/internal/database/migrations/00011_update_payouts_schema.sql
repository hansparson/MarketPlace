-- +goose Up
-- +goose StatementBegin
ALTER TABLE payouts RENAME COLUMN reseller_id TO user_id;
ALTER TABLE payouts ADD COLUMN user_type TEXT NOT NULL DEFAULT 'RESELLER';
-- Since I already linked user_id to resellers(id) in previous migration, I'll leave it for now.
-- But in reality, it should be a polymorphic reference or no hard constraint if it can be either table.
-- For now, let's just drop the constraint and rely on user_type.
ALTER TABLE payouts DROP CONSTRAINT IF EXISTS payouts_reseller_id_fkey;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE payouts RENAME COLUMN user_id TO reseller_id;
ALTER TABLE payouts DROP COLUMN user_type;
-- +goose StatementEnd
