-- name: CreateCommission :one
INSERT INTO commissions (
    reseller_id, product_id, amount, status
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: GetResellerCommissions :many
SELECT c.*, p.title as product_title 
FROM commissions c
JOIN products p ON c.product_id = p.id
WHERE c.reseller_id = $1
ORDER BY c.created_at DESC;

-- name: GetTotalCommission :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE reseller_id = $1 AND status = 'PAID';

-- name: GetTotalCommissionAll :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE reseller_id = $1;

-- name: GetPendingCommission :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE reseller_id = $1 AND status = 'PENDING';

-- name: GetCommissionsByReseller :many
SELECT * FROM commissions
WHERE reseller_id = $1
ORDER BY created_at DESC;

