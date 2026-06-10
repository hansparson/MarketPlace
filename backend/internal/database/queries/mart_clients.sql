-- name: UpsertMartClientFromGoogle :one
INSERT INTO mart_clients (google_id, email, status, created_at, updated_at)
VALUES ($1, $2, 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (email) DO UPDATE 
SET 
    google_id = COALESCE(mart_clients.google_id, EXCLUDED.google_id),
    updated_at = CURRENT_TIMESTAMP
RETURNING *;

-- name: UpdateMartClientProfile :one
UPDATE mart_clients
SET 
    name = $2,
    phone = $3,
    referral_code_used = $4,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: GetMartClientByID :one
SELECT * FROM mart_clients WHERE id = $1 LIMIT 1;

-- name: CheckReferralCodeExists :one
-- Check if referral code exists in members OR resellers table
SELECT 
    TRUE::BOOLEAN as is_exists,
    'MEMBER'::TEXT as user_type,
    id as referrer_id
FROM members WHERE referral_code = sqlc.arg('referral_code')::VARCHAR AND status = 'ACTIVE'
UNION ALL
SELECT 
    TRUE::BOOLEAN as is_exists,
    'RESELLER'::TEXT as user_type,
    id as referrer_id
FROM resellers WHERE referral_code = sqlc.arg('referral_code')::VARCHAR AND status = 'ACTIVE'
LIMIT 1;

-- name: ListMartClients :many
SELECT * FROM mart_clients 
WHERE ($1::TEXT = '' OR name ILIKE '%' || $1 || '%' OR email ILIKE '%' || $1 || '%' OR phone ILIKE '%' || $1 || '%')
ORDER BY created_at DESC;

-- name: AddMartClientFavorite :exec
INSERT INTO mart_client_favorites (client_id, product_id)
VALUES ($1, $2)
ON CONFLICT (client_id, product_id) DO NOTHING;

-- name: RemoveMartClientFavorite :exec
DELETE FROM mart_client_favorites
WHERE client_id = $1 AND product_id = $2;

-- name: GetMartClientFavoriteExists :one
SELECT EXISTS (
    SELECT 1 FROM mart_client_favorites
    WHERE client_id = $1 AND product_id = $2
) AS is_favorite;

-- name: ListMartClientFavorites :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM mart_client_favorites mcf
JOIN products p ON mcf.product_id = p.id
WHERE mcf.client_id = $1
ORDER BY mcf.created_at DESC;

