package handler

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/google/uuid"
)

type MartClientHandler struct {
	Queries *db.Queries
}

func NewMartClientHandler(q *db.Queries) *MartClientHandler {
	return &MartClientHandler{Queries: q}
}

// Request payloads
type MartLoginRequest struct {
	GoogleID string `json:"google_id"`
	Email    string `json:"email"`
}

type MartCompleteProfileRequest struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Phone        string `json:"phone"`
	ReferralCode string `json:"referral_code"`
}

func (h *MartClientHandler) LoginGoogle(c echo.Context) error {
	var req MartLoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request format"})
	}

	if req.Email == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Email is required"})
	}

	// Upsert the mart client
	client, err := h.Queries.UpsertMartClientFromGoogle(context.Background(), db.UpsertMartClientFromGoogleParams{
		GoogleID: sql.NullString{String: req.GoogleID, Valid: req.GoogleID != ""},
		Email:    req.Email,
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to sync user: " + err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"message": "Login synced successfully",
		"data":    client,
	})
}

func (h *MartClientHandler) CompleteProfile(c echo.Context) error {
	var req MartCompleteProfileRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request format"})
	}

	// Check referral code if provided
	if req.ReferralCode != "" {
		referralCheck, err := h.Queries.CheckReferralCodeExists(context.Background(), strings.ToUpper(req.ReferralCode))
		if err != nil || !referralCheck.IsExists {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid Referral Code"})
		}
	}

	// Parse ID
	id, err := uuid.Parse(req.ID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid client ID"})
	}

	// Update profile
	client, err := h.Queries.UpdateMartClientProfile(context.Background(), db.UpdateMartClientProfileParams{
		ID:               id,
		Name:             sql.NullString{String: req.Name, Valid: req.Name != ""},
		Phone:            sql.NullString{String: req.Phone, Valid: req.Phone != ""},
		ReferralCodeUsed: sql.NullString{String: req.ReferralCode, Valid: req.ReferralCode != ""},
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update profile: " + err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"message": "Profile updated successfully",
		"data":    client,
	})
}

type MartToggleFavoriteRequest struct {
	ClientID  string `json:"client_id"`
	ProductID string `json:"product_id"`
}

func (h *MartClientHandler) ToggleFavorite(c echo.Context) error {
	var req MartToggleFavoriteRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request format"})
	}

	cID, err := uuid.Parse(req.ClientID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid client ID"})
	}

	pID, err := uuid.Parse(req.ProductID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid product ID"})
	}

	// Check if already favorited
	isFav, err := h.Queries.GetMartClientFavoriteExists(context.Background(), db.GetMartClientFavoriteExistsParams{
		ClientID:  cID,
		ProductID: pID,
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Database error: " + err.Error()})
	}

	if isFav {
		// Remove it
		err = h.Queries.RemoveMartClientFavorite(context.Background(), db.RemoveMartClientFavoriteParams{
			ClientID:  cID,
			ProductID: pID,
		})
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to remove favorite: " + err.Error()})
		}
		return c.JSON(http.StatusOK, map[string]interface{}{
			"message":     "Favorite removed successfully",
			"is_favorite": false,
		})
	} else {
		// Add it
		err = h.Queries.AddMartClientFavorite(context.Background(), db.AddMartClientFavoriteParams{
			ClientID:  cID,
			ProductID: pID,
		})
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to add favorite: " + err.Error()})
		}
		return c.JSON(http.StatusOK, map[string]interface{}{
			"message":     "Favorite added successfully",
			"is_favorite": true,
		})
	}
}

func (h *MartClientHandler) ListFavorites(c echo.Context) error {
	clientIDStr := c.QueryParam("client_id")
	if clientIDStr == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "client_id is required"})
	}

	cID, err := uuid.Parse(clientIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid client ID"})
	}

	favorites, err := h.Queries.ListMartClientFavorites(context.Background(), cID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to load favorites: " + err.Error()})
	}

	// Convert database row to JSON-friendly map
	result := make([]map[string]interface{}, len(favorites))
	for i, f := range favorites {
		result[i] = map[string]interface{}{
			"id":                         f.ID,
			"category_id":                f.CategoryID,
			"title":                      f.Title,
			"description":                f.Description,
			"price":                      f.Price,
			"stock":                      f.Stock,
			"status":                     f.Status,
			"created_by":                 f.CreatedBy,
			"created_at":                 f.CreatedAt,
			"updated_at":                 f.UpdatedAt,
			"location_name":              f.LocationName.String,
			"latitude":                   f.Latitude.String,
			"longitude":                  f.Longitude.String,
			"province":                   f.Province.String,
			"regency":                    f.Regency.String,
			"district":                   f.District.String,
			"village":                    f.Village.String,
			"thumbnail_url":              f.ThumbnailUrl,
			"commission_amount":          f.CommissionAmount,
			"member_commission_amount":   f.MemberCommissionAmount,
			"reseller_commission_amount": f.ResellerCommissionAmount,
		}
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"message":      "Favorites fetched successfully",
		"message_data": result,
	})
}

