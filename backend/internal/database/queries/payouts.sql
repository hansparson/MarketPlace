-- name: CreatePayout :one
INSERT INTO payouts (
    user_id, amount, proof_object_key, notes, user_type
) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: ListPayoutsByUser :many
SELECT * FROM payouts
WHERE user_id = $1 AND user_type = $2
ORDER BY created_at DESC;

-- name: ListAllPayouts :many
SELECT p.*, COALESCE(r.name, m.name, 'Unknown') as user_name
FROM payouts p
LEFT JOIN resellers r ON p.user_id = r.id AND p.user_type = 'RESELLER'
LEFT JOIN members m ON p.user_id = m.id AND p.user_type = 'MEMBER'
ORDER BY p.created_at DESC;

-- name: GetTotalPayoutByUser :one
SELECT COALESCE(SUM(amount), 0)::bigint as total_paid
FROM payouts
WHERE user_id = $1 AND user_type = $2 AND status != 'FAILED';

-- name: GetPayoutCountByUserAndDate :one
SELECT COUNT(*) FROM payouts
WHERE user_id = $1 AND user_type = $2 AND status != 'FAILED' AND created_at >= $3;

