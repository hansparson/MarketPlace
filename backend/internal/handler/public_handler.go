package handler

import (
	"context"
	"database/sql"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/cache"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/storage"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
)

type PublicHandler struct {
	Queries *db.Queries
	Storage *storage.MinioStorage
	Cache   *cache.Cache
}

func NewPublicHandler(queries *db.Queries, storage *storage.MinioStorage, cache *cache.Cache) *PublicHandler {
	return &PublicHandler{
		Queries: queries,
		Storage: storage,
		Cache:   cache,
	}
}

// Helper to convert ListProductsRow to JSON-friendly map
func convertListProductRow(p db.ListProductsRow) map[string]interface{} {
	return map[string]interface{}{
		"id":                p.ID,
		"category_id":       p.CategoryID,
		"title":             p.Title,
		"description":       p.Description,
		"price":             p.Price,
		"status":            p.Status,
		"created_by":        p.CreatedBy,
		"created_at":        p.CreatedAt,
		"updated_at":        p.UpdatedAt,
		"commission_amount": p.CommissionAmount,
		"location_name":     p.LocationName.String,
		"latitude":          p.Latitude.String,
		"longitude":         p.Longitude.String,
		"province":          p.Province.String,
		"regency":           p.Regency.String,
		"district":          p.District.String,
		"village":           p.Village.String,
		"thumbnail_url":     p.ThumbnailUrl,
	}
}

// Helper to convert SearchProductsRow to JSON-friendly map
func convertSearchProductRow(p db.SearchProductsRow) map[string]interface{} {
	return map[string]interface{}{
		"id":                p.ID,
		"category_id":       p.CategoryID,
		"title":             p.Title,
		"description":       p.Description,
		"price":             p.Price,
		"status":            p.Status,
		"created_by":        p.CreatedBy,
		"created_at":        p.CreatedAt,
		"updated_at":        p.UpdatedAt,
		"commission_amount": p.CommissionAmount,
		"location_name":     p.LocationName.String,
		"latitude":          p.Latitude.String,
		"longitude":         p.Longitude.String,
		"province":          p.Province.String,
		"regency":           p.Regency.String,
		"district":          p.District.String,
		"village":           p.Village.String,
		"thumbnail_url":     p.ThumbnailUrl,
	}
}

// Helper to convert ListProductsByCategoryRow to JSON-friendly map
func convertCategoryProductRow(p db.ListProductsByCategoryRow) map[string]interface{} {
	return map[string]interface{}{
		"id":                p.ID,
		"category_id":       p.CategoryID,
		"title":             p.Title,
		"description":       p.Description,
		"price":             p.Price,
		"status":            p.Status,
		"created_by":        p.CreatedBy,
		"created_at":        p.CreatedAt,
		"updated_at":        p.UpdatedAt,
		"commission_amount": p.CommissionAmount,
		"location_name":     p.LocationName.String,
		"latitude":          p.Latitude.String,
		"longitude":         p.Longitude.String,
		"province":          p.Province.String,
		"regency":           p.Regency.String,
		"district":          p.District.String,
		"village":           p.Village.String,
		"thumbnail_url":     p.ThumbnailUrl,
	}
}

// List Products
func (h *PublicHandler) ListProducts(c echo.Context) error {
	queryP := c.QueryParam("q")
	catIDStr := c.QueryParam("cat")
	loc := c.QueryParam("loc")
	limitStr := c.QueryParam("limit")
	offsetStr := c.QueryParam("offset")

	limit := int32(20)
	offset := int32(0)

	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
		limit = int32(l)
	}
	if o, err := strconv.Atoi(offsetStr); err == nil && o >= 0 {
		offset = int32(o)
	}

	if queryP != "" {
		// Search Mode
		products, err := h.Queries.SearchProducts(context.Background(), db.SearchProductsParams{
			Column1: sql.NullString{String: queryP, Valid: true},
			Limit:   limit,
			Offset:  offset,
			Column4: loc,
		})
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}

		// Convert to JSON-friendly format
		result := make([]map[string]interface{}, len(products))
		for i, p := range products {
			result[i] = convertSearchProductRow(p)
		}
		return response.Success(c, http.StatusOK, "PRODUCTS_SEARCHED", result)
	}

	if catIDStr != "" {
		catID, err := uuid.Parse(catIDStr)
		if err == nil {
			products, err := h.Queries.ListProductsByCategory(context.Background(), db.ListProductsByCategoryParams{
				CategoryID: catID,
				Limit:      limit,
				Offset:     offset,
				Column4:    loc,
			})
			if err != nil {
				return response.Error(c, apperrors.ErrInternalServerError)
			}

			// Convert to JSON-friendly format
			result := make([]map[string]interface{}, len(products))
			for i, p := range products {
				result[i] = convertCategoryProductRow(p)
			}
			return response.Success(c, http.StatusOK, "PRODUCTS_LISTED_BY_CATEGORY", result)
		}
	}

	// List Mode
	products, err := h.Queries.ListProducts(context.Background(), db.ListProductsParams{
		Limit:   limit,
		Offset:  offset,
		Column3: loc,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	// Convert to JSON-friendly format
	result := make([]map[string]interface{}, len(products))
	for i, p := range products {
		result[i] = convertListProductRow(p)
	}

	return response.Success(c, http.StatusOK, "PRODUCTS_LISTED", result)
}

// Get Product Detail
func (h *PublicHandler) GetProduct(c echo.Context) error {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	product, err := h.Queries.GetProductWithSeller(context.Background(), id)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	assets, err := h.Queries.GetProductAssets(context.Background(), id)
	if err != nil {
		// Assets might be empty, not critical error, but checking err
	}

	// Convert sql.NullString to regular string for JSON response
	productMap := map[string]interface{}{
		"id":                product.ID,
		"category_id":       product.CategoryID,
		"title":             product.Title,
		"description":       product.Description,
		"price":             product.Price,
		"stock":             product.Stock, // Add stock field
		"status":            product.Status,
		"created_by":        product.CreatedBy,
		"created_at":        product.CreatedAt,
		"updated_at":        product.UpdatedAt,
		"commission_amount": product.CommissionAmount,
		"location_name":     product.LocationName.String,
		"latitude":          product.Latitude.String,
		"longitude":         product.Longitude.String,
		"province":          product.Province.String,
		"regency":           product.Regency.String,
		"district":          product.District.String,
		"village":           product.Village.String,
		"seller_phone":      product.SellerPhone,
		"seller_name":       product.SellerName,
	}

	// Combine result
	result := map[string]interface{}{
		"product": productMap,
		"assets":  assets,
	}

	return response.Success(c, http.StatusOK, "PRODUCT_FETCHED", result)
}

// List Categories
func (h *PublicHandler) ListCategories(c echo.Context) error {
	categories, err := h.Queries.ListCategories(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "CATEGORIES_LISTED", categories)
}
