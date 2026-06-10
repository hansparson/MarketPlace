package handler

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"

	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/notification"
	"github.com/user/marketplace-backend/internal/storage"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/dana"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

type AdminHandler struct {
	Queries      db.Querier
	Storage      *storage.MinioStorage
	DB           *sql.DB
	DanaClient   *dana.Client
	Notification *notification.Service
}

func NewAdminHandler(q db.Querier, s *storage.MinioStorage, dbConn *sql.DB, danaClient *dana.Client, fcmService *notification.Service) *AdminHandler {
	return &AdminHandler{Queries: q, Storage: s, DB: dbConn, DanaClient: danaClient, Notification: fcmService}
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
			"type":          "LEAD",
			"visitor_name":  r.VisitorName.String,
			"visitor_phone": r.VisitorPhone.String,
			"product_title": r.ProductTitle,
			"product_id":    r.ProductID,
			"reseller_name": r.ResellerName,
			"referral_code": r.ReferralCode,
			"created_at":    r.CreatedAt,
		})
	}

	// Add pending member registrations
	pending, _ := h.Queries.ListPendingMembers(context.Background())
	for _, p := range pending {
		recentResponse = append(recentResponse, map[string]interface{}{
			"type":          "MEMBER_REGISTRATION",
			"member_id":     p.ID,
			"visitor_name":  p.Name,
			"visitor_phone": p.Phone,
			"product_title": "Member Registration",
			"created_at":    p.CreatedAt,
			"status":        p.Status,
		})
	}


	return response.Success(c, http.StatusOK, "DASHBOARD_STATS", map[string]interface{}{
		"total_products":      stats.TotalProducts,
		"total_resellers":     stats.TotalResellers,
		"total_members":       stats.TotalMembers,
		"total_clicks":        stats.TotalClicks,
		"total_verifications": stats.TotalVerifications,
		"recent_activities":   recentResponse,
	})
}

// ListSystemConfigs lists all configurations
func (h *AdminHandler) ListSystemConfigs(c echo.Context) error {
	configs, err := h.Queries.ListSystemConfigs(c.Request().Context())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "SYSTEM_CONFIGS_RETRIEVED", configs)
}

// UpdateSystemConfigs updates or inserts multiple system configs
func (h *AdminHandler) UpdateSystemConfigs(c echo.Context) error {
	var req struct {
		Configs []struct {
			Key         string `json:"key"`
			Value       string `json:"value"`
			Description string `json:"description"`
		} `json:"configs"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	ctx := c.Request().Context()
	updatedConfigs := make([]db.SystemConfig, 0)

	for _, item := range req.Configs {
		if item.Key == "" {
			continue
		}

		// Validation
		if item.Key == "member_registration_fee" || item.Key == "reseller_registration_fee" || item.Key == "minimum_withdrawal_amount" || item.Key == "max_withdrawals_per_day" || item.Key == "reseller_referral_commission" {
			var feeVal int
			if _, err := fmt.Sscanf(item.Value, "%d", &feeVal); err != nil || feeVal < 0 {
				return response.Error(c, apperrors.NewAppError(http.StatusBadRequest, "INVALID_VALUE", fmt.Sprintf("Nilai untuk %s harus berupa angka non-negatif", item.Key)))
			}
		}

		if item.Key == "admin_whatsapp_number" {
			for _, char := range item.Value {
				if char < '0' || char > '9' {
					return response.Error(c, apperrors.NewAppError(http.StatusBadRequest, "INVALID_VALUE", "Nomor WhatsApp hanya boleh berisi angka (contoh: 628123456789)"))
				}
			}
		}

		cfg, err := h.Queries.UpsertSystemConfig(ctx, db.UpsertSystemConfigParams{
			Key:         item.Key,
			Value:       item.Value,
			Description: sql.NullString{String: item.Description, Valid: item.Description != ""},
		})
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		updatedConfigs = append(updatedConfigs, cfg)
	}

	return response.Success(c, http.StatusOK, "SYSTEM_CONFIGS_UPDATED", updatedConfigs)
}
