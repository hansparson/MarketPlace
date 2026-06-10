-- name: GetReseller :one
SELECT r.*, m.name as member_name
FROM resellers r
LEFT JOIN members m ON r.member_id = m.id
WHERE r.id = $1 LIMIT 1;

-- name: GetResellerByPhone :one
SELECT * FROM resellers
WHERE phone = $1 LIMIT 1;

-- name: GetResellerByUsername :one
SELECT * FROM resellers
WHERE username = $1 LIMIT 1;

-- name: GetResellerByReferralCode :one
SELECT * FROM resellers
WHERE referral_code = $1 LIMIT 1;

-- name: CreateReseller :one
INSERT INTO resellers (
    member_id, name, phone, email, password_hash, referral_code, status, username, nik, profile_image, ktp_image
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
)
RETURNING *;

-- name: ListResellersTable :many
SELECT r.*, m.name as member_name
FROM resellers r
LEFT JOIN members m ON r.member_id = m.id
ORDER BY r.created_at DESC;

-- name: UpdateReseller :one
UPDATE resellers
SET member_id = $2, name = $3, phone = $4, email = $5, status = $6, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: DeleteReseller :exec
DELETE FROM resellers WHERE id = $1;

-- name: ListResellersByMember :many
SELECT * FROM resellers
WHERE member_id = $1
ORDER BY created_at DESC;

-- name: TrackResellerShare :exec
INSERT INTO product_resellers (product_id, reseller_id, referral_code)
SELECT $1, $2, referral_code FROM resellers WHERE id = $2
ON CONFLICT (product_id, reseller_id) DO NOTHING;

-- name: UpdateResellerProfile :one
UPDATE resellers
SET name = $2, email = $3, bio = $4, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: MarkResellerPhoneVerified :one
UPDATE resellers
SET phone_verified_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING phone_verified_at;
