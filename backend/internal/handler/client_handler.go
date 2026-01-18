package handler

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"

	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

type ClientHandler struct {
	Queries db.Querier
}

func NewClientHandler(q db.Querier) *ClientHandler {
	return &ClientHandler{Queries: q}
}

// Get Product Share URL
func (h *ClientHandler) GetShareURL(c echo.Context) error {
	productID := c.Param("id")
	userIDStr := c.Get("user_id").(string)
	userID, _ := uuid.Parse(userIDStr)

	user, err := h.Queries.GetUser(context.Background(), userID)

	ref := userIDStr // fallback
	if err == nil && user.ReferralCode.Valid {
		ref = user.ReferralCode.String
	}

	shareURL := fmt.Sprintf("https://marketplace.com/p/%s?ref=%s", productID, ref)

	return response.Success(c, http.StatusOK, "SHARE_URL_GENERATED", map[string]string{
		"share_url": shareURL,
	})
}

// Track Click
func (h *ClientHandler) TrackClick(c echo.Context) error {
	productID, _ := uuid.Parse(c.QueryParam("product_id"))
	resellerID, _ := uuid.Parse(c.QueryParam("ref"))

	click, err := h.Queries.CreateProductClick(context.Background(), db.CreateProductClickParams{
		ProductID:  productID,
		ResellerID: resellerID,
		IpAddress:  sql.NullString{String: c.RealIP(), Valid: true},
		UserAgent:  sql.NullString{String: c.Request().UserAgent(), Valid: true},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "CLICK_TRACKED", click)
}

// Get Reseller Analytics (Who clicked my link)
func (h *ClientHandler) GetMyAnalytics(c echo.Context) error {
	productID, _ := uuid.Parse(c.Param("id"))

	stats, err := h.Queries.GetProductClickStats(context.Background(), productID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "ANALYTICS_RETRIEVED", stats)
}

// Submit Lead (Visitor Phone Input)
func (h *ClientHandler) SubmitLead(c echo.Context) error {
	var req struct {
		ProductID string `json:"product_id"`
		RefCode   string `json:"ref_code"`
		Phone     string `json:"phone"`
		Name      string `json:"name"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	productID, err := uuid.Parse(req.ProductID)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	var resellerID uuid.UUID

	// Check if RefCode is UUID (direct ID)
	if id, err := uuid.Parse(req.RefCode); err == nil {
		resellerID = id
	} else {
		// Lookup by code
		reseller, err := h.Queries.GetResellerByCode(context.Background(), sql.NullString{String: req.RefCode, Valid: true})
		if err != nil {
			return response.Error(c, apperrors.ErrNotFound)
		}
		resellerID = reseller.ID
	}

	lead, err := h.Queries.CreateLead(context.Background(), db.CreateLeadParams{
		ProductID:    productID,
		ResellerID:   resellerID,
		VisitorPhone: sql.NullString{String: req.Phone, Valid: req.Phone != ""},
		VisitorName:  sql.NullString{String: req.Name, Valid: req.Name != ""},
		ClientID:     uuid.NullUUID{Valid: false},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "LEAD_SUBMITTED", lead)
}

// Get Reseller Dashboard Stats
func (h *ClientHandler) GetStats(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	resellerID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	stats, err := h.Queries.GetResellerStats(context.Background(), resellerID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	recent, _ := h.Queries.GetResellerRecentActivities(context.Background(), db.GetResellerRecentActivitiesParams{
		ResellerID: resellerID,
		Limit:      5,
	})

	recentResponse := make([]map[string]interface{}, 0)
	for _, r := range recent {
		recentResponse = append(recentResponse, map[string]interface{}{
			"activity_type":     r.ActivityType,
			"visitor_name":      r.VisitorName.String,
			"visitor_phone":     r.VisitorPhone.String,
			"product_title":     r.ProductTitle,
			"product_id":        r.ProductID,
			"commission_amount": r.CommissionAmount,
			"created_at":        r.CreatedAt,
		})
	}

	totalCommission, _ := h.Queries.GetTotalCommissionAll(context.Background(), resellerID)
	totalClicks, _ := h.Queries.GetResellerClickCount(context.Background(), resellerID)

	// Get referral code from user
	user, _ := h.Queries.GetUser(context.Background(), resellerID)
	referralCode := ""
	if user.ReferralCode.Valid {
		referralCode = user.ReferralCode.String
	}

	totalPaid, _ := h.Queries.GetTotalPayoutByReseller(context.Background(), resellerID)

	return response.Success(c, http.StatusOK, "STATS_RETRIEVED", map[string]interface{}{
		"total_leads":       stats.TotalLeads,
		"active_products":   stats.ActiveProducts,
		"total_commission":  totalCommission,
		"total_paid":        totalPaid,
		"available_balance": totalCommission - totalPaid,
		"total_clicks":      totalClicks,
		"referral_code":     referralCode,
		"recent_activities": recentResponse,
	})
}

// Get Payout History (My Rembers)
func (h *ClientHandler) GetMyPayouts(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	resellerID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	payouts, err := h.Queries.ListPayoutsByReseller(context.Background(), resellerID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PAYOUTS_RETRIEVED", payouts)
}
