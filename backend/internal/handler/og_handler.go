package handler

import (
	"fmt"
	"html/template"
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/database/db"
)

// OGHandler handles Open Graph meta tags for social media sharing
type OGHandler struct {
	queries *db.Queries
}

// NewOGHandler creates a new Open Graph handler
func NewOGHandler(queries *db.Queries) *OGHandler {
	return &OGHandler{
		queries: queries,
	}
}

// GetProductOG serves HTML with Open Graph meta tags for a product
// @Summary Get Product Open Graph HTML
// @Description Serves HTML page with Open Graph meta tags for social media crawler bots (WhatsApp, Facebook, Twitter)
// @Tags OpenGraph
// @Produce html
// @Param id path string true "Product ID"
// @Success 200 {string} string "HTML with meta tags"
// @Failure 404 {object} map[string]interface{} "Product not found"
// @Router /og/product/{id} [get]
func (h *OGHandler) GetProductOG(c echo.Context) error {
	productIDStr := c.Param("id")

	// Parse UUID from string
	productID, err := uuid.Parse(productIDStr)
	if err != nil {
		return c.String(http.StatusNotFound, "Invalid product ID")
	}

	// Get product details
	product, err := h.queries.GetProduct(c.Request().Context(), productID)
	if err != nil {
		return c.String(http.StatusNotFound, "Product not found")
	}

	// Get product assets (images)
	assets, _ := h.queries.GetProductAssets(c.Request().Context(), productID)

	// Get first image URL
	var imageURL string
	if len(assets) > 0 {
		// Construct full MinIO URL
		minioEndpoint := "https://gostar-mart.online/minio"
		bucketName := "marketplace"
		imageURL = fmt.Sprintf("%s/%s/%s", minioEndpoint, bucketName, assets[0].ObjectKey)
	} else {
		// Fallback to logo
		imageURL = "https://gostar-mart.online/logo.jpg"
	}

	// Product URL
	productURL := fmt.Sprintf("https://gostar-mart.online/products/%s", productIDStr)

	// Prepare description
	description := product.Description
	if len(description) > 160 {
		description = description[:157] + "..."
	}

	// HTML template with Open Graph meta tags
	htmlTemplate := `<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- SEO Meta Tags -->
    <title>{{.Title}} - Gostar Mart</title>
    <meta name="description" content="{{.Description}}">
    
    <!-- Open Graph / Facebook / WhatsApp -->
    <meta property="og:type" content="product">
    <meta property="og:site_name" content="Gostar Mart">
    <meta property="og:title" content="{{.Title}}">
    <meta property="og:description" content="{{.Description}}">
    <meta property="og:image" content="{{.ImageURL}}">
    <meta property="og:image:secure_url" content="{{.ImageURL}}">
    <meta property="og:image:type" content="image/jpeg">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:url" content="{{.ProductURL}}">
    <meta property="product:price:amount" content="{{.Price}}">
    <meta property="product:price:currency" content="IDR">
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{.Title}}">
    <meta name="twitter:description" content="{{.Description}}">
    <meta name="twitter:image" content="{{.ImageURL}}">
    
    <!-- Redirect to actual product page after 0.1 seconds (for human visitors) -->
    <meta http-equiv="refresh" content="0.1;url={{.ProductURL}}">
    
    <style>
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 5px solid rgba(255,255,255,0.3);
            border-top-color: white;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 1rem;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        h1 {
            font-size: 1.5rem;
            margin-bottom: 0.5rem;
        }
        p {
            opacity: 0.9;
            margin: 0;
        }
        a {
            color: white;
            text-decoration: underline;
            margin-top: 1rem;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="spinner"></div>
        <h1>{{.Title}}</h1>
        <p>Mengalihkan ke halaman produk...</p>
        <p style="margin-top: 1rem;">
            <a href="{{.ProductURL}}">Klik di sini jika tidak dialihkan otomatis</a>
        </p>
    </div>
    
    <!-- Fallback JavaScript redirect -->
    <script>
        setTimeout(function() {
            window.location.href = "{{.ProductURL}}";
        }, 100);
    </script>
</body>
</html>`

	// Prepare template data
	data := map[string]interface{}{
		"Title":       product.Title,
		"Description": description,
		"ImageURL":    imageURL,
		"ProductURL":  productURL,
		"Price":       product.Price,
	}

	// Parse and execute template
	tmpl, err := template.New("og").Parse(htmlTemplate)
	if err != nil {
		return c.String(http.StatusInternalServerError, "Template error")
	}

	// Set content type to HTML
	c.Response().Header().Set("Content-Type", "text/html; charset=utf-8")
	c.Response().WriteHeader(http.StatusOK)

	// Execute template
	return tmpl.Execute(c.Response().Writer, data)
}
