-- name: GetProduct :one
SELECT * FROM products
WHERE id = $1 LIMIT 1;

-- name: GetProductWithSeller :one
SELECT p.*, 
       COALESCE(u.phone, '')::text as seller_phone, 
       COALESCE(u.name, 'Unknown')::text as seller_name
FROM products p
LEFT JOIN users u ON p.created_by = u.id
WHERE p.id = $1 LIMIT 1;

-- name: ListProducts :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM products p
WHERE 
    (p.status = 'ACTIVE' OR (p.status = 'SOLD' AND p.updated_at >= CURRENT_TIMESTAMP - INTERVAL '1 month')) AND
    ($3::text = '' OR p.location_name ILIKE '%' || $3 || '%')
ORDER BY 
    CASE WHEN p.status = 'ACTIVE' THEN 0 ELSE 1 END ASC,
    p.created_at DESC
LIMIT $1 OFFSET $2;

-- name: SearchProducts :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM products p
WHERE 
    ((p.status = 'ACTIVE') OR (p.status = 'SOLD' AND p.updated_at >= CURRENT_TIMESTAMP - INTERVAL '1 month')) AND
    (p.title ILIKE '%' || $1 || '%' OR p.description ILIKE '%' || $1 || '%') AND
    ($4::text = '' OR p.location_name ILIKE '%' || $4 || '%')
ORDER BY 
    CASE WHEN p.status = 'ACTIVE' THEN 0 ELSE 1 END ASC,
    p.created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListProductsByCategory :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM products p
WHERE 
    (p.category_id = $1) AND
    ((p.status = 'ACTIVE') OR (p.status = 'SOLD' AND p.updated_at >= CURRENT_TIMESTAMP - INTERVAL '1 month')) AND
    ($4::text = '' OR p.location_name ILIKE '%' || $4 || '%')
ORDER BY 
    CASE WHEN p.status = 'ACTIVE' THEN 0 ELSE 1 END ASC,
    p.created_at DESC
LIMIT $2 OFFSET $3;

-- name: CreateProduct :one
INSERT INTO products (
    category_id, title, description, price, member_commission_amount, reseller_commission_amount, commission_amount, status, created_by, 
    location_name, latitude, longitude, province, regency, district, village, stock, specifications
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
)
RETURNING *;

-- name: ListCategories :many
SELECT * FROM categories
ORDER BY name ASC;

-- name: CreateCategory :one
INSERT INTO categories (
    name, parent_id
) VALUES (
    $1, $2
)
RETURNING *;

-- name: CreateProductAsset :one
INSERT INTO product_assets (
    product_id, asset_type, object_key
) VALUES (
    $1, $2, $3
)
RETURNING *;

-- name: GetProductAssets :many
SELECT * FROM product_assets
WHERE product_id = $1;

-- name: CreateProductClick :one
INSERT INTO product_clicks (
    product_id, reseller_id, ip_address, user_agent
) VALUES (
    $1, $2, $3, $4
)
RETURNING *;

-- name: GetProductClickStats :many
SELECT clicked_at::date as click_date, count(*) as click_count
FROM product_clicks
WHERE product_id = $1
GROUP BY click_date
ORDER BY click_date DESC;

-- name: GetDashboardStats :one
SELECT 
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM resellers) as total_resellers,
    (SELECT COUNT(*) FROM members) as total_members,
    (SELECT COUNT(*) FROM product_clicks) as total_clicks,
    (SELECT COUNT(*) FROM product_verifications) as total_verifications;

-- name: AdminListProducts :many
SELECT 
    p.*,
    COALESCE((SELECT object_key FROM product_assets a WHERE a.product_id = p.id AND a.asset_type::text ILIKE 'image' LIMIT 1), '')::text as thumbnail_url
FROM products p
ORDER BY 
    CASE WHEN p.stock > 0 THEN 0 ELSE 1 END ASC,  -- Products with stock first
    p.created_at DESC                              -- Then by newest first
LIMIT $1 OFFSET $2;

-- name: CountAllProducts :one
SELECT COUNT(*) FROM products;

-- name: UpdateProduct :one
UPDATE products
SET category_id = $2, title = $3, description = $4, price = $5, 
    member_commission_amount = $6, reseller_commission_amount = $7, 
    status = $8, updated_at = CURRENT_TIMESTAMP,
    location_name = $9, latitude = $10, longitude = $11,
    province = $12, regency = $13, district = $14, village = $15, stock = $16,
    commission_amount = $17, specifications = $18
WHERE id = $1
RETURNING *;

-- name: DeleteProduct :exec
DELETE FROM products WHERE id = $1;

-- name: DeleteProductAssets :exec
DELETE FROM product_assets WHERE product_id = $1;

-- name: DeleteProductAsset :exec
DELETE FROM product_assets WHERE id = $1;

-- name: GetProductAsset :one
SELECT * FROM product_assets WHERE id = $1 LIMIT 1;

-- name: GetResellerClickCount :one
SELECT COUNT(*) FROM product_clicks WHERE reseller_id = $1;
