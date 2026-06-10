package handler

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
	"github.com/user/marketplace-backend/pkg/utils"

	"github.com/labstack/echo/v4"
)

// Create Reseller
func (h *AdminHandler) CreateReseller(c echo.Context) error {
	var req struct {
		MemberID string `json:"member_id"`
		Name     string `json:"name"`
		Phone    string `json:"phone"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	memberID := uuid.NullUUID{Valid: false}
	if req.MemberID != "" {
		if id, err := uuid.Parse(req.MemberID); err == nil {
			memberID = uuid.NullUUID{UUID: id, Valid: true}
		}
	}

	// Generate Referral Code
	refCode := "REF-R-" + utils.RandomString(8)

	reseller, err := h.Queries.CreateReseller(context.Background(), db.CreateResellerParams{
		MemberID:     memberID,
		Name:         req.Name,
		Phone:        req.Phone,
		Email:        sql.NullString{String: req.Email, Valid: req.Email != ""},
		PasswordHash: req.Password,
		ReferralCode: refCode,
		Status:       db.UserStatus("ACTIVE"),
		Username:     sql.NullString{Valid: false},
		Nik:          sql.NullString{Valid: false},
		ProfileImage: sql.NullString{Valid: false},
		KtpImage:     sql.NullString{Valid: false},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "RESELLER_CREATED", reseller)
}

// Create Member
func (h *AdminHandler) CreateMember(c echo.Context) error {
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
	refCode := "REF-M-" + utils.RandomString(8)

	member, err := h.Queries.CreateMember(context.Background(), db.CreateMemberParams{
		Name:         req.Name,
		Phone:        req.Phone,
		Email:        sql.NullString{String: req.Email, Valid: req.Email != ""},
		PasswordHash: req.Password,
		ReferralCode: refCode,
		Status:       db.UserStatus("ACTIVE"),
		Username:     sql.NullString{Valid: false},
		Nik:          sql.NullString{Valid: false},
		ProfileImage: sql.NullString{Valid: false},
		KtpImage:     sql.NullString{Valid: false},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusCreated, "MEMBER_CREATED", member)
}

// List All Resellers
func (h *AdminHandler) ListResellers(c echo.Context) error {
	resellers, err := h.Queries.ListResellersTable(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "RESELLERS_LISTED", resellers)
}

// List Members
func (h *AdminHandler) ListMembers(c echo.Context) error {
	members, err := h.Queries.ListMembers(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "MEMBERS_LISTED", members)
}

// Get Single Member with Stats
func (h *AdminHandler) GetMember(c echo.Context) error {
	id := c.Param("id")
	memberID, _ := uuid.Parse(id)

	member, err := h.Queries.GetMember(context.Background(), memberID)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	type MemberStats struct {
		TotalCommission  int64 `json:"total_commission"`
		TotalPaid        int64 `json:"total_paid"`
		AvailableBalance int64 `json:"available_balance"`
		TotalResellers   int64 `json:"total_resellers"`
		TotalLeads       int64 `json:"total_leads"`
	}

	stats := MemberStats{}
	totalComm, _ := h.Queries.GetTotalCommissionAll(context.Background(), db.GetTotalCommissionAllParams{
		UserID:   uuid.NullUUID{UUID: memberID, Valid: true},
		UserType: "MEMBER",
	})
	stats.TotalCommission = totalComm

	totalPaid, _ := h.Queries.GetTotalPayoutByUser(context.Background(), db.GetTotalPayoutByUserParams{
		UserID:   memberID,
		UserType: "MEMBER",
	})
	stats.TotalPaid = totalPaid
	stats.AvailableBalance = totalComm - totalPaid

	// Count Resellers under this member
	resellers, _ := h.Queries.ListResellersTable(context.Background())
	count := 0
	for _, r := range resellers {
		if r.MemberID.Valid && r.MemberID.UUID == memberID {
			count++
		}
	}
	stats.TotalResellers = int64(count)

	mStats, _ := h.Queries.GetMemberStats(context.Background(), memberID)
	stats.TotalLeads = mStats.TotalLeads

	sales, _ := h.Queries.GetUserCommissions(context.Background(), db.GetUserCommissionsParams{
		UserID:   uuid.NullUUID{UUID: memberID, Valid: true},
		UserType: "MEMBER",
	})

	return response.Success(c, http.StatusOK, "MEMBER_FOUND", map[string]interface{}{
		"member": member,
		"stats":  stats,
		"sales":  sales,
	})
}

// Update Member
func (h *AdminHandler) UpdateMember(c echo.Context) error {
	id := c.Param("id")
	memberID, _ := uuid.Parse(id)

	var req struct {
		Name     string `json:"name"`
		Phone    string `json:"phone"`
		Email    string `json:"email"`
		Status   string `json:"status"`
		Username string `json:"username"`
		Nik      string `json:"nik"`
	}
	c.Bind(&req)

	member, err := h.Queries.UpdateMember(context.Background(), db.UpdateMemberParams{
		ID:     memberID,
		Name:   req.Name,
		Phone:  req.Phone,
		Email:  sql.NullString{String: req.Email, Valid: req.Email != ""},
		Status: db.UserStatus(req.Status),
		Username: sql.NullString{String: req.Username, Valid: req.Username != ""},
		Nik:      sql.NullString{String: req.Nik, Valid: req.Nik != ""},
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "MEMBER_UPDATED", member)
}

// Get Single Reseller with Stats
func (h *AdminHandler) GetReseller(c echo.Context) error {
	id := c.Param("id")
	resellerID, _ := uuid.Parse(id)

	reseller, err := h.Queries.GetReseller(context.Background(), resellerID)
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
	totalComm, _ := h.Queries.GetTotalCommissionAll(context.Background(), db.GetTotalCommissionAllParams{
		UserID:   uuid.NullUUID{UUID: resellerID, Valid: true},
		UserType: "RESELLER",
	})
	stats.TotalCommission = totalComm

	totalPaid, _ := h.Queries.GetTotalPayoutByUser(context.Background(), db.GetTotalPayoutByUserParams{
		UserID:   resellerID,
		UserType: "RESELLER",
	})
	stats.TotalPaid = totalPaid
	stats.AvailableBalance = totalComm - totalPaid

	leads, _ := h.Queries.GetLeadsByReseller(context.Background(), uuid.NullUUID{UUID: resellerID, Valid: true})
	stats.TotalLeads = int64(len(leads))
	totalClicks, _ := h.Queries.GetResellerClickCount(context.Background(), resellerID)
	stats.TotalClicks = totalClicks

	sales, _ := h.Queries.GetUserCommissions(context.Background(), db.GetUserCommissionsParams{
		UserID:   uuid.NullUUID{UUID: resellerID, Valid: true},
		UserType: "RESELLER",
	})

	return response.Success(c, http.StatusOK, "RESELLER_FOUND", map[string]interface{}{
		"reseller": reseller,
		"stats":    stats,
		"sales":    sales,
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
	payoutType := c.FormValue("payout_type")
	if payoutType == "" {
		payoutType = "MANUAL"
	}

	if payoutType != "DANA" && h.Storage == nil {
		return c.JSON(http.StatusServiceUnavailable, map[string]string{"error": "Storage unavailable"})
	}

	userIDStr := c.FormValue("user_id")
	if userIDStr == "" {
		userIDStr = c.FormValue("reseller_id") // legacy
	}
	userType := c.FormValue("user_type")
	if userType == "" {
		userType = "RESELLER"
	}
	amountStr := c.FormValue("amount")
	notes := c.FormValue("notes")

	userID, _ := uuid.Parse(userIDStr)
	amount, _ := strconv.ParseInt(amountStr, 10, 64)

	// Fetch recipient phone if DANA payout
	var phone string
	if payoutType == "DANA" {
		if userType == "MEMBER" {
			member, err := h.Queries.GetMember(context.Background(), userID)
			if err != nil {
				return response.Error(c, apperrors.ErrNotFound)
			}
			if !member.DanaPhone.Valid || member.DanaPhone.String == "" {
				return c.JSON(http.StatusBadRequest, map[string]string{"error": "Nomor DANA belum diatur untuk member ini"})
			}
			phone = member.DanaPhone.String
		} else {
			reseller, err := h.Queries.GetReseller(context.Background(), userID)
			if err != nil {
				return response.Error(c, apperrors.ErrNotFound)
			}
			if !reseller.DanaPhone.Valid || reseller.DanaPhone.String == "" {
				return c.JSON(http.StatusBadRequest, map[string]string{"error": "Nomor DANA belum diatur untuk reseller ini"})
			}
			phone = reseller.DanaPhone.String
		}
	}

	// File upload for proof (only for manual payouts)
	var proofKey string
	if payoutType != "DANA" && h.Storage != nil {
		file, _ := c.FormFile("proof")
		if file != nil {
			proofKey, _ = h.Storage.UploadFile(context.Background(), file, "payouts/"+userIDStr)
		}
	}

	// Create payout in DB (defaults to SUCCESS or configured status)
	payout, err := h.Queries.CreatePayout(context.Background(), db.CreatePayoutParams{
		UserID:         userID,
		Amount:         amount,
		ProofObjectKey: sql.NullString{String: proofKey, Valid: proofKey != ""},
		Notes:          sql.NullString{String: notes, Valid: notes != ""},
		UserType:       userType,
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	// If DANA payout, trigger automated transfer
	if payoutType == "DANA" {
		merchantTransID := fmt.Sprintf("PAYOUT-%s", payout.ID.String()[:8])

		// Update DB payout status to PENDING
		payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
			ID:                payout.ID,
			Status:            "PENDING",
			DanaTransactionID: sql.NullString{Valid: false},
			MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
			FailedReason:      sql.NullString{Valid: false},
		})

		if h.DanaClient != nil {
			// Trigger DANA transfer
			danaTxID, err := h.DanaClient.TransferToDana(context.Background(), merchantTransID, phone, amount, notes)
			if err != nil {
				// Update status to FAILED
				payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
					ID:                payout.ID,
					Status:            "FAILED",
					DanaTransactionID: sql.NullString{Valid: false},
					MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
					FailedReason:      sql.NullString{String: err.Error(), Valid: true},
				})
				if h.Notification != nil {
					h.Notification.NotifyUser(context.Background(), userID, userType,
						"Penarikan Dana Gagal",
						fmt.Sprintf("Penarikan dana sebesar Rp %d gagal diproses. Alasan: %s", amount, err.Error()),
						map[string]string{"type": "withdrawal_failed", "amount": fmt.Sprintf("%d", amount), "reason": err.Error()})
				}
				return c.JSON(http.StatusInternalServerError, map[string]interface{}{
					"error":  "DANA transfer failed",
					"reason": err.Error(),
					"payout": payout,
				})
			}

			// Update status to SUCCESS
			payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
				ID:                payout.ID,
				Status:            "SUCCESS",
				DanaTransactionID: sql.NullString{String: danaTxID, Valid: true},
				MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
				FailedReason:      sql.NullString{Valid: false},
			})
			if h.Notification != nil {
				h.Notification.NotifyUser(context.Background(), userID, userType,
					"Penarikan Dana Sukses!",
					fmt.Sprintf("Penarikan dana sebesar Rp %d sukses dikirim ke akun DANA Anda.", amount),
					map[string]string{"type": "withdrawal_success", "amount": fmt.Sprintf("%d", amount)})
			}
		} else {
			// Fallback/Mock for local testing when DANA Client is not configured
			mockTxID := fmt.Sprintf("DANA-TX-%s", uuid.New().String()[:8])
			payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
				ID:                payout.ID,
				Status:            "SUCCESS",
				DanaTransactionID: sql.NullString{String: mockTxID, Valid: true},
				MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
				FailedReason:      sql.NullString{Valid: false},
			})
			if h.Notification != nil {
				h.Notification.NotifyUser(context.Background(), userID, userType,
					"Penarikan Dana Sukses!",
					fmt.Sprintf("Penarikan dana sebesar Rp %d sukses dikirim ke akun DANA Anda.", amount),
					map[string]string{"type": "withdrawal_success", "amount": fmt.Sprintf("%d", amount)})
			}
		}
	} else {
		// Manual payout success notification
		if h.Notification != nil {
			h.Notification.NotifyUser(context.Background(), userID, userType,
				"Penarikan Dana Sukses!",
				fmt.Sprintf("Payout manual sebesar Rp %d telah berhasil diproses.", amount),
				map[string]string{"type": "payout_success", "amount": fmt.Sprintf("%d", amount)})
		}
	}

	return response.Success(c, http.StatusCreated, "PAYOUT_CREATED", payout)
}

// List All Payouts (Admin)
func (h *AdminHandler) ListPayouts(c echo.Context) error {
	payouts, err := h.Queries.ListAllPayouts(context.Background())
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "PAYOUT_LIST", payouts)
}

// List resellers managed by a specific member
func (h *AdminHandler) ListMemberResellers(c echo.Context) error {
	id := c.Param("id")
	memberID, err := uuid.Parse(id)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	resellers, err := h.Queries.ListResellersByMember(context.Background(), uuid.NullUUID{UUID: memberID, Valid: true})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "MEMBER_RESELLERS_LIST", resellers)
}

