-- name: CreateCommission :one
INSERT INTO commissions (
    user_id, product_id, amount, status, user_type, referral_code
) VALUES (
    $1, $2, $3, $4, $5, $6
)
RETURNING *;

-- name: GetUserCommissions :many
SELECT 
    c.*, 
    p.title as product_title,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM commissions c
JOIN products p ON c.product_id = p.id
WHERE c.user_id = $1 AND c.user_type = $2
ORDER BY c.created_at DESC;


-- name: GetTotalCommission :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE user_id = $1 AND user_type = $2 AND status = 'PAID';

-- name: GetTotalCommissionAll :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE user_id = $1 AND user_type = $2;

-- name: GetPendingCommission :one
SELECT COALESCE(SUM(amount), 0)::bigint FROM commissions WHERE user_id = $1 AND user_type = $2 AND status = 'PENDING';

-- name: GetCommissionsByUser :many
SELECT * FROM commissions
WHERE user_id = $1 AND user_type = $2
ORDER BY created_at DESC;

-- name: GetCommissionLeaderboard :many
SELECT 
    c.user_id,
    c.user_type,
    COALESCE(m.name, r.name, 'User')::text as user_name,
    SUM(c.amount)::bigint as total_amount
FROM commissions c
LEFT JOIN members m ON c.user_id = m.id AND c.user_type = 'MEMBER'
LEFT JOIN resellers r ON c.user_id = r.id AND c.user_type = 'RESELLER'
GROUP BY c.user_id, c.user_type, m.name, r.name
ORDER BY total_amount DESC
LIMIT 10;

-- name: CheckReferralCommissionExists :one
SELECT EXISTS(
    SELECT 1 FROM commissions
    WHERE user_id = $1 AND user_type = 'MEMBER' AND product_id IS NULL AND referral_code = $2
)::boolean;


