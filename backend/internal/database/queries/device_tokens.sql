-- name: UpsertDeviceToken :one
INSERT INTO device_tokens (
    user_id, role, token, device_type
) VALUES (
    $1, $2, $3, $4
)
ON CONFLICT (token) DO UPDATE
SET user_id = EXCLUDED.user_id,
    role = EXCLUDED.role,
    device_type = EXCLUDED.device_type,
    updated_at = CURRENT_TIMESTAMP
RETURNING *;

-- name: GetDeviceTokensByUserIdAndRole :many
SELECT * FROM device_tokens
WHERE user_id = $1 AND role = $2;

-- name: GetDeviceTokensByUserIdsAndRole :many
SELECT * FROM device_tokens
WHERE user_id = ANY($1::uuid[]) AND role = $2;

-- name: DeleteDeviceToken :exec
DELETE FROM device_tokens
WHERE token = $1;

-- name: GetDeviceTokensByRoles :many
SELECT * FROM device_tokens
WHERE role = ANY($1::text[]);

