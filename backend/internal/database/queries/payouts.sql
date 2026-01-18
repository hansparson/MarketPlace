-- name: CreatePayout :one
INSERT INTO payouts (
    reseller_id, amount, proof_object_key, notes
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: ListPayoutsByReseller :many
SELECT * FROM payouts
WHERE reseller_id = $1
ORDER BY created_at DESC;

-- name: ListAllPayouts :many
SELECT p.*, u.name as reseller_name
FROM payouts p
JOIN users u ON p.reseller_id = u.id
ORDER BY p.created_at DESC;

-- name: GetTotalPayoutByReseller :one
SELECT COALESCE(SUM(amount), 0)::bigint as total_paid
FROM payouts
WHERE reseller_id = $1;
