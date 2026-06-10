-- name: CreateLead :one
INSERT INTO product_leads (
    product_id, reseller_id, member_id, visitor_phone, visitor_name, client_id 
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetResellerStats :one
SELECT 
    COUNT(id) as total_leads, 
    (SELECT COUNT(*) FROM product_resellers pr WHERE pr.reseller_id = $1)::bigint as total_shares 
FROM product_leads 
WHERE reseller_id = $1;



-- name: GetRecentLeads :many
SELECT l.id, l.visitor_name, l.visitor_phone, p.id as product_id, p.title as product_title, 
       COALESCE(r.referral_code, m.referral_code) as referral_code, 
       COALESCE(r.name, m.name) as reseller_name, l.created_at 
FROM product_leads l 
JOIN products p ON l.product_id = p.id 
LEFT JOIN resellers r ON l.reseller_id = r.id 
LEFT JOIN members m ON l.member_id = m.id
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
SELECT l.*, 
       COALESCE(r.referral_code, m.referral_code, '') as referral_code, 
       COALESCE(r.name, m.name, '') as reseller_name 
FROM product_leads l
LEFT JOIN resellers r ON l.reseller_id = r.id
LEFT JOIN members m ON l.member_id = m.id
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
WHERE c.user_id = $1 AND c.user_type = 'RESELLER'
ORDER BY created_at DESC
LIMIT $2;

-- name: GetMemberRecentActivities :many
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
LEFT JOIN resellers r ON l.reseller_id = r.id
WHERE r.member_id = $1 OR l.member_id = $1
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
WHERE c.user_id = $1 AND c.user_type = 'MEMBER'
ORDER BY created_at DESC
LIMIT $2;

-- name: GetMemberStats :one
SELECT 
    COUNT(l.id) as total_leads, 
    (SELECT COUNT(*) FROM member_products mp WHERE mp.member_id = $1)::bigint as total_shares 
FROM product_leads l
LEFT JOIN resellers r ON l.reseller_id = r.id
WHERE r.member_id = $1 OR l.member_id = $1;



-- name: GetMemberTeamStats :one
SELECT 
    COUNT(c.id) as total_sales,
    COALESCE(SUM(c.amount), 0)::bigint as total_commission
FROM commissions c
JOIN resellers r ON c.user_id = r.id
WHERE r.member_id = $1 AND c.user_type = 'RESELLER';

-- name: GetLeadsByReseller :many
SELECT * FROM product_leads
WHERE reseller_id = $1
ORDER BY created_at DESC;

-- name: UpdateLeadStatus :exec
UPDATE product_leads SET status = $2 WHERE id = $1;

