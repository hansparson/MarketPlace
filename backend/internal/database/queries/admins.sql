-- name: GetAdminByEmail :one
SELECT * FROM admins
WHERE email = $1 LIMIT 1;

-- name: CreateAdmin :one
INSERT INTO admins (
    name, email, password_hash, role
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: ListAdmins :many
SELECT * FROM admins
ORDER BY created_at DESC;
