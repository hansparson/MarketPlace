-- name: CreateRegistrationPayment :one
INSERT INTO registration_payments (
    user_id, user_type, invoice_number, amount, status, payment_url, external_id
) VALUES (
    $1, $2, $3, $4, $5, $6, $7
)
RETURNING *;

-- name: GetRegistrationPaymentByInvoice :one
SELECT * FROM registration_payments
WHERE invoice_number = $1 LIMIT 1;

-- name: GetRegistrationPaymentByUserID :one
SELECT * FROM registration_payments
WHERE user_id = $1
ORDER BY created_at DESC LIMIT 1;

-- name: UpdateRegistrationPaymentStatus :one
UPDATE registration_payments
SET status = $2, external_id = $3, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: UpdateMemberStatus :one
UPDATE members
SET status = $2, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: UpdateResellerStatus :one
UPDATE resellers
SET status = $2, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: UpdateMemberDanaPhone :one
UPDATE members
SET dana_phone = $2, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: UpdateResellerDanaPhone :one
UPDATE resellers
SET dana_phone = $2, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING *;

-- name: UpdatePayoutDanaStatus :one
UPDATE payouts
SET status = $2, dana_transaction_id = $3, merchant_trans_id = $4, failed_reason = $5
WHERE id = $1
RETURNING *;
