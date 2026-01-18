package handler

import (
	"bytes"
	"context"
	"database/sql"
	"fmt"
	"image/jpeg"
	"math"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

// Add Product
func (h *AdminHandler) CreateProduct(c echo.Context) error {
	var req struct {
		CategoryID       string  `json:"category_id"`
		Title            string  `json:"title"`
		Description      string  `json:"description"`
		Price            int64   `json:"price"`
		CommissionAmount int64   `json:"commission_amount"`
		LocationName     string  `json:"location_name"`
		Latitude         float64 `json:"latitude"`
		Longitude        float64 `json:"longitude"`
		Province         string  `json:"province"`
		Regency          string  `json:"regency"`
		District         string  `json:"district"`
		Village          string  `json:"village"`
		Stock            int32   `json:"stock"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	catID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	userIDStr, ok := c.Get("user_id").(string)
	if !ok || userIDStr == "" {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	adminID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	if req.Stock == 0 {
		req.Stock = 1
	}

	product, err := h.Queries.CreateProduct(context.Background(), db.CreateProductParams{
		CategoryID:       catID,
		Title:            req.Title,
		Description:      req.Description,
		Price:            req.Price,
		CommissionAmount: req.CommissionAmount,
		CreatedBy:        adminID,
		Status:           db.ProductStatusACTIVE,
		LocationName:     sql.NullString{String: req.LocationName, Valid: req.LocationName != ""},
		Latitude:         sql.NullString{String: fmt.Sprintf("%f", req.Latitude), Valid: req.Latitude != 0},
		Longitude:        sql.NullString{String: fmt.Sprintf("%f", req.Longitude), Valid: req.Longitude != 0},
		Province:         sql.NullString{String: req.Province, Valid: req.Province != ""},
		Regency:          sql.NullString{String: req.Regency, Valid: req.Regency != ""},
		District:         sql.NullString{String: req.District, Valid: req.District != ""},
		Village:          sql.NullString{String: req.Village, Valid: req.Village != ""},
		Stock:            req.Stock,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "PRODUCT_CREATED", product)
}

// Upload Asset (supports multiple files)
func (h *AdminHandler) UploadAsset(c echo.Context) error {
	if h.Storage == nil {
		return c.JSON(http.StatusServiceUnavailable, map[string]string{
			"error": "File upload service is currently unavailable.",
		})
	}

	productID := c.FormValue("product_id")
	prodID, err := uuid.Parse(productID)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	form, err := c.MultipartForm()
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	files := form.File["files"]
	if len(files) == 0 {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	var images, videos []*multipart.FileHeader
	for _, file := range files {
		contentType := file.Header.Get("Content-Type")
		ext := filepath.Ext(file.Filename)

		if contentType == "" {
			if ext == ".jpg" || ext == ".png" || ext == ".jpeg" {
				contentType = "image/jpeg"
			} else if ext == ".mp4" || ext == ".mov" {
				contentType = "video/mp4"
			}
		}

		if len(contentType) >= 5 && contentType[:5] == "image" {
			images = append(images, file)
		} else if len(contentType) >= 5 && contentType[:5] == "video" {
			videos = append(videos, file)
		}
	}

	if len(images) < 1 || len(images) > 5 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "1-5 images required"})
	}

	var uploadedAssets []db.ProductAsset

	for _, file := range images {
		buf, newFilename, _ := compressImage(file)
		var path string

		if buf != nil {
			path, err = h.Storage.UploadStream(context.Background(), buf, int64(buf.Len()), "image/jpeg", newFilename, "products/"+productID)
		} else {
			path, err = h.Storage.UploadFile(context.Background(), file, "products/"+productID)
		}

		if err == nil {
			asset, _ := h.Queries.CreateProductAsset(context.Background(), db.CreateProductAssetParams{
				ProductID: prodID,
				AssetType: db.AssetTypeIMAGE,
				ObjectKey: path,
			})
			uploadedAssets = append(uploadedAssets, asset)
		}
	}

	for _, file := range videos {
		path, err := h.Storage.UploadFile(context.Background(), file, "products/"+productID)
		if err == nil {
			asset, _ := h.Queries.CreateProductAsset(context.Background(), db.CreateProductAssetParams{
				ProductID: prodID,
				AssetType: db.AssetTypeVIDEO,
				ObjectKey: path,
			})
			uploadedAssets = append(uploadedAssets, asset)
		}
	}

	return response.Success(c, http.StatusOK, "ASSETS_UPLOADED", map[string]interface{}{
		"assets": uploadedAssets,
	})
}

// Delete Asset
func (h *AdminHandler) DeleteAsset(c echo.Context) error {
	id := c.Param("id")
	assetID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	err = h.Queries.DeleteProductAsset(context.Background(), assetID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "ASSET_DELETED", nil)
}

// List All Products (for admin)
func (h *AdminHandler) ListAllProducts(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	offset := (page - 1) * limit
	ctx := context.Background()

	totalItems, _ := h.Queries.CountAllProducts(ctx)
	products, _ := h.Queries.AdminListProducts(ctx, db.AdminListProductsParams{
		Limit:  int32(limit),
		Offset: int32(offset),
	})

	totalPages := int(math.Ceil(float64(totalItems) / float64(limit)))

	return response.Success(c, http.StatusOK, "PRODUCTS_LISTED", map[string]interface{}{
		"items": products,
		"pagination": map[string]interface{}{
			"current_page": page,
			"total_pages":  totalPages,
			"total_items":  totalItems,
		},
	})
}

// Get Single Product
func (h *AdminHandler) GetProduct(c echo.Context) error {
	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	product, err := h.Queries.GetProduct(context.Background(), productID)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	assets, _ := h.Queries.GetProductAssets(context.Background(), productID)

	return response.Success(c, http.StatusOK, "PRODUCT_FOUND", map[string]interface{}{
		"product": product,
		"assets":  assets,
	})
}

// Update Product
func (h *AdminHandler) UpdateProduct(c echo.Context) error {
	id := c.Param("id")
	productID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	var req struct {
		CategoryID       string  `json:"category_id"`
		Title            string  `json:"title"`
		Description      string  `json:"description"`
		Price            int64   `json:"price"`
		CommissionAmount int64   `json:"commission_amount"`
		Status           string  `json:"status"`
		LocationName     string  `json:"location_name"`
		Latitude         float64 `json:"latitude"`
		Longitude        float64 `json:"longitude"`
		Province         string  `json:"province"`
		Regency          string  `json:"regency"`
		District         string  `json:"district"`
		Village          string  `json:"village"`
		Stock            int32   `json:"stock"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	catID, _ := uuid.Parse(req.CategoryID)
	product, err := h.Queries.UpdateProduct(context.Background(), db.UpdateProductParams{
		ID:               productID,
		CategoryID:       catID,
		Title:            req.Title,
		Description:      req.Description,
		Price:            req.Price,
		CommissionAmount: req.CommissionAmount,
		Status:           db.ProductStatus(req.Status),
		LocationName:     sql.NullString{String: req.LocationName, Valid: req.LocationName != ""},
		Latitude:         sql.NullString{String: fmt.Sprintf("%f", req.Latitude), Valid: req.Latitude != 0},
		Longitude:        sql.NullString{String: fmt.Sprintf("%f", req.Longitude), Valid: req.Longitude != 0},
		Province:         sql.NullString{String: req.Province, Valid: req.Province != ""},
		Regency:          sql.NullString{String: req.Regency, Valid: req.Regency != ""},
		District:         sql.NullString{String: req.District, Valid: req.District != ""},
		Village:          sql.NullString{String: req.Village, Valid: req.Village != ""},
		Stock:            req.Stock,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_UPDATED", product)
}

// Delete Product
func (h *AdminHandler) DeleteProduct(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)
	ctx := context.Background()

	h.Queries.DeleteProductAssets(ctx, productID)
	err := h.Queries.DeleteProduct(ctx, productID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_DELETED", nil)
}

// Get Product Leads
func (h *AdminHandler) GetProductLeads(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)

	leads, err := h.Queries.GetLeadsByProduct(context.Background(), productID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PRODUCT_LEADS_RETRIEVED", leads)
}

// Mark Product as Sold
func (h *AdminHandler) MarkProductSold(c echo.Context) error {
	id := c.Param("id")
	productID, _ := uuid.Parse(id)

	var req struct {
		LeadID    string `json:"lead_id"`
		UnitsSold int32  `json:"units_sold"`
	}
	c.Bind(&req)

	if req.UnitsSold <= 0 {
		return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "units_sold must be > 0"))
	}

	product, _ := h.Queries.GetProduct(context.Background(), productID)
	if product.Stock < req.UnitsSold {
		return response.Error(c, echo.NewHTTPError(http.StatusBadRequest, "Not enough stock"))
	}

	newStock := product.Stock - req.UnitsSold
	newStatus := product.Status
	if newStock <= 0 {
		newStatus = db.ProductStatusSOLD
		newStock = 0
	}

	if req.LeadID != "" {
		leadID, _ := uuid.Parse(req.LeadID)
		leads, _ := h.Queries.GetLeadsByProduct(context.Background(), productID)
		for _, l := range leads {
			if l.ID == leadID && product.CommissionAmount > 0 {
				h.Queries.CreateCommission(context.Background(), db.CreateCommissionParams{
					ResellerID: l.ResellerID,
					ProductID:  productID,
					Amount:     product.CommissionAmount,
					Status:     "PENDING",
				})
				break
			}
		}
	}

	h.Queries.UpdateProduct(context.Background(), db.UpdateProductParams{
		ID:               productID,
		CategoryID:       product.CategoryID,
		Title:            product.Title,
		Description:      product.Description,
		Price:            product.Price,
		CommissionAmount: product.CommissionAmount,
		Status:           newStatus,
		LocationName:     product.LocationName,
		Latitude:         product.Latitude,
		Longitude:        product.Longitude,
		Province:         product.Province,
		Regency:          product.Regency,
		District:         product.District,
		Village:          product.Village,
		Stock:            newStock,
	})

	return response.Success(c, http.StatusOK, "PRODUCT_UPDATED", nil)
}

// Helper to compress image
func compressImage(file *multipart.FileHeader) (*bytes.Buffer, string, error) {
	src, err := file.Open()
	if err != nil {
		return nil, "", err
	}
	defer src.Close()

	img, err := imaging.Decode(src)
	if err != nil {
		return nil, "", err
	}

	if img.Bounds().Dx() > 1000 {
		img = imaging.Resize(img, 1000, 0, imaging.Lanczos)
	}

	buf := new(bytes.Buffer)
	err = jpeg.Encode(buf, img, &jpeg.Options{Quality: 80})
	if err != nil {
		return nil, "", err
	}

	ext := filepath.Ext(file.Filename)
	name := file.Filename[0 : len(file.Filename)-len(ext)]
	newFilename := name + ".jpg"

	return buf, newFilename, nil
}
