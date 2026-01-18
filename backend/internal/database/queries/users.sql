-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserByPhone :one
SELECT * FROM users
WHERE phone = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
    name, phone, email, password_hash, role, referral_code
) VALUES (
    $1, $2, $3, $4, $5, $6
)
RETURNING *;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY created_at DESC;

-- name: ListResellers :many
SELECT * FROM users
WHERE role = 'RESELLER'
ORDER BY created_at DESC;

-- name: GetLastResellerReferralCode :one
SELECT referral_code FROM users
WHERE role = 'RESELLER'
  AND referral_code LIKE 'REF-%'
ORDER BY referral_code DESC
LIMIT 1;

-- name: GetResellerByCode :one
SELECT * FROM users WHERE referral_code = $1 LIMIT 1;

-- name: UpdateUser :one
UPDATE users
SET 
    name = @name,
    phone = @phone,
    email = COALESCE(NULLIF(@email::text, ''), email),
    password_hash = COALESCE(NULLIF(@password_hash::text, ''), password_hash),
    updated_at = NOW()
WHERE id = @id
RETURNING *;





