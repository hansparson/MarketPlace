-- name: GetSystemConfigByKey :one
SELECT * FROM system_configs
WHERE key = $1 LIMIT 1;

-- name: ListSystemConfigs :many
SELECT * FROM system_configs
ORDER BY key ASC;

-- name: UpsertSystemConfig :one
INSERT INTO system_configs (
    key, value, description, updated_at
) VALUES (
    $1, $2, $3, CURRENT_TIMESTAMP
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, system_configs.description),
    updated_at = CURRENT_TIMESTAMP
RETURNING *;
