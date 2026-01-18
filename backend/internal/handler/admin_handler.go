package handler

import (
	"context"
	"net/http"

	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/storage"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

type AdminHandler struct {
	Queries db.Querier
	Storage *storage.MinioStorage
}

func NewAdminHandler(q db.Querier, s *storage.MinioStorage) *AdminHandler {
	return &AdminHandler{Queries: q, Storage: s}
}

// Get Dashboard Stats
func (h *AdminHandler) GetDashboard(c echo.Context) error {
	stats, err := h.Queries.GetDashboardStats(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	recent, _ := h.Queries.GetRecentLeads(context.Background(), 5)

	recentResponse := make([]map[string]interface{}, 0)
	for _, r := range recent {
		recentResponse = append(recentResponse, map[string]interface{}{
			"visitor_name":  r.VisitorName.String,
			"visitor_phone": r.VisitorPhone.String,
			"product_title": r.ProductTitle,
			"product_id":    r.ProductID,
			"reseller_name": r.ResellerName,
			"referral_code": r.ReferralCode.String,
			"created_at":    r.CreatedAt,
		})
	}

	return response.Success(c, http.StatusOK, "DASHBOARD_STATS", map[string]interface{}{
		"total_products":      stats.TotalProducts,
		"total_resellers":     stats.TotalResellers,
		"total_clicks":        stats.TotalClicks,
		"total_verifications": stats.TotalVerifications,
		"recent_activities":   recentResponse,
	})
}
