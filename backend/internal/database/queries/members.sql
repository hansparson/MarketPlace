-- name: GetMember :one
SELECT * FROM members
WHERE id = $1 LIMIT 1;

-- name: GetMemberByPhone :one
SELECT * FROM members
WHERE phone = $1 LIMIT 1;

-- name: GetMemberByUsername :one
SELECT * FROM members
WHERE username = $1 LIMIT 1;

-- name: GetMemberByReferralCode :one
SELECT * FROM members
WHERE referral_code = $1 LIMIT 1;

-- name: CreateMember :one
INSERT INTO members (
    name, phone, email, password_hash, referral_code, status, username, nik, profile_image, ktp_image
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
)
RETURNING *;

-- name: ListMembers :many
SELECT * FROM members
ORDER BY created_at DESC;

-- name: UpdateMember :one
UPDATE members
SET name = $2, phone = $3, email = $4, status = $5, username = $6, nik = $7, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: DeleteMember :exec
DELETE FROM members WHERE id = $1;

-- name: ListPendingMembers :many
SELECT * FROM members
WHERE status = 'PENDING'
ORDER BY created_at DESC;

-- name: TrackMemberShare :exec
INSERT INTO member_products (member_id, product_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: UpdateMemberProfile :one
UPDATE members
SET name = $2, email = $3, bio = $4, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: MarkMemberPhoneVerified :one
UPDATE members
SET phone_verified_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING phone_verified_at;
