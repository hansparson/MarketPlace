-- name: CreateLead :one
INSERT INTO product_leads (
    product_id, reseller_id, visitor_phone, visitor_name, client_id 
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetResellerStats :one
SELECT COUNT(*) as total_leads, COUNT(DISTINCT product_id) as active_products FROM product_leads WHERE reseller_id = $1;

-- name: GetRecentLeads :many
SELECT l.id, l.visitor_name, l.visitor_phone, p.id as product_id, p.title as product_title, u.referral_code, u.name as reseller_name, l.created_at 
FROM product_leads l 
JOIN products p ON l.product_id = p.id 
JOIN users u ON l.reseller_id = u.id 
ORDER BY l.created_at DESC 
LIMIT $1;

-- name: GetResellerRecentLeads :many
SELECT l.id, l.visitor_name, l.visitor_phone, p.id as product_id, p.title as product_title, l.created_at 
FROM product_leads l 
JOIN products p ON l.product_id = p.id 
WHERE l.reseller_id = $1 
ORDER BY l.created_at DESC 
LIMIT $2;

-- name: GetLeadsByProduct :many
SELECT l.*, u.referral_code, u.name as reseller_name 
FROM product_leads l
JOIN users u ON l.reseller_id = u.id
WHERE l.product_id = $1
ORDER BY l.created_at DESC;

-- name: GetResellerRecentActivities :many
SELECT 
    'LEAD' as activity_type,
    l.id, 
    l.visitor_name as visitor_name, 
    l.visitor_phone as visitor_phone, 
    p.id as product_id, 
    p.title as product_title, 
    0::bigint as commission_amount,
    l.created_at 
FROM product_leads l 
JOIN products p ON l.product_id = p.id 
WHERE l.reseller_id = $1
UNION ALL
SELECT 
    'SALE' as activity_type,
    c.id,
    '' as visitor_name,
    '' as visitor_phone,
    p.id as product_id,
    p.title as product_title,
    c.amount as commission_amount,
    c.created_at
FROM commissions c
JOIN products p ON c.product_id = p.id
WHERE c.reseller_id = $1
ORDER BY created_at DESC
LIMIT $2;

-- name: GetLeadsByReseller :many
SELECT * FROM product_leads
WHERE reseller_id = $1
ORDER BY created_at DESC;

