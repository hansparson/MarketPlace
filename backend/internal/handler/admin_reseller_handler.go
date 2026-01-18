package handler

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

// Create Reseller
func (h *AdminHandler) CreateReseller(c echo.Context) error {
	var req struct {
		Name     string `json:"name"`
		Phone    string `json:"phone"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	// Generate Referral Code
	currentNum := 0
	lastCode, err := h.Queries.GetLastResellerReferralCode(context.Background())
	if err == nil && lastCode.Valid {
		parts := strings.Split(lastCode.String, "-")
		if len(parts) == 2 {
			if num, err := strconv.Atoi(parts[1]); err == nil {
				currentNum = num
			}
		}
	}

	nextCode := fmt.Sprintf("REF-%08d", currentNum+1)

	user, err := h.Queries.CreateUser(context.Background(), db.CreateUserParams{
		Name:         req.Name,
		Phone:        req.Phone,
		Email:        sql.NullString{String: req.Email, Valid: req.Email != ""},
		PasswordHash: req.Password,
		Role:         db.UserRoleRESELLER,
		ReferralCode: sql.NullString{String: nextCode, Valid: true},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "RESELLER_CREATED", user)
}

// List All Resellers
func (h *AdminHandler) ListResellers(c echo.Context) error {
	resellers, err := h.Queries.ListResellers(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "RESELLERS_LISTED", resellers)
}

// Get Single Reseller with Stats
func (h *AdminHandler) GetReseller(c echo.Context) error {
	id := c.Param("id")
	resellerID, _ := uuid.Parse(id)

	reseller, err := h.Queries.GetUser(context.Background(), resellerID)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	type ResellerStats struct {
		TotalCommission  int64 `json:"total_commission"`
		TotalPaid        int64 `json:"total_paid"`
		AvailableBalance int64 `json:"available_balance"`
		TotalClicks      int64 `json:"total_clicks"`
		TotalLeads       int64 `json:"total_leads"`
	}

	stats := ResellerStats{}
	totalComm, _ := h.Queries.GetTotalCommissionAll(context.Background(), resellerID)
	stats.TotalCommission = totalComm

	totalPaid, _ := h.Queries.GetTotalPayoutByReseller(context.Background(), resellerID)
	stats.TotalPaid = totalPaid
	stats.AvailableBalance = totalComm - totalPaid

	leads, _ := h.Queries.GetLeadsByReseller(context.Background(), resellerID)
	stats.TotalLeads = int64(len(leads))
	stats.TotalClicks = int64(len(leads))

	return response.Success(c, http.StatusOK, "RESELLER_FOUND", map[string]interface{}{
		"reseller": reseller,
		"stats":    stats,
	})
}

// Update Reseller
func (h *AdminHandler) UpdateReseller(c echo.Context) error {
	id := c.Param("id")
	resellerID, _ := uuid.Parse(id)

	var req struct {
		Name     string `json:"name"`
		Phone    string `json:"phone"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	c.Bind(&req)

	user, err := h.Queries.UpdateUser(context.Background(), db.UpdateUserParams{
		ID:           resellerID,
		Name:         req.Name,
		Phone:        req.Phone,
		Email:        req.Email,
		PasswordHash: req.Password,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "RESELLER_UPDATED", user)
}

// Create Payout (Rembers)
func (h *AdminHandler) CreatePayout(c echo.Context) error {
	if h.Storage == nil {
		return c.JSON(http.StatusServiceUnavailable, map[string]string{"error": "Storage unavailable"})
	}

	resellerIDStr := c.FormValue("reseller_id")
	amountStr := c.FormValue("amount")
	notes := c.FormValue("notes")

	resellerID, _ := uuid.Parse(resellerIDStr)
	amount, _ := strconv.ParseInt(amountStr, 10, 64)

	// File upload for proof
	file, _ := c.FormFile("proof")
	var proofKey string
	if file != nil {
		proofKey, _ = h.Storage.UploadFile(context.Background(), file, "payouts/"+resellerIDStr)
	}

	payout, err := h.Queries.CreatePayout(context.Background(), db.CreatePayoutParams{
		ResellerID:     resellerID,
		Amount:         amount,
		ProofObjectKey: proofKey,
		Notes:          sql.NullString{String: notes, Valid: notes != ""},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "PAYOUT_CREATED", payout)
}

// List All Payouts (Admin)
func (h *AdminHandler) ListPayouts(c echo.Context) error {
	payouts, err := h.Queries.ListAllPayouts(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "PAYOUTS_LISTED", payouts)
}
