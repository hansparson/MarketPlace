package handler

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/notification"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/dana"
	"github.com/user/marketplace-backend/pkg/response"

	"github.com/labstack/echo/v4"
)

type ClientHandler struct {
	Queries      db.Querier
	DanaClient   *dana.Client
	Notification *notification.Service
}

func NewClientHandler(q db.Querier, danaClient *dana.Client, fcmService *notification.Service) *ClientHandler {
	return &ClientHandler{Queries: q, DanaClient: danaClient, Notification: fcmService}
}

// Get Product Share URL
func (h *ClientHandler) GetShareURL(c echo.Context) error {
	productID := c.Param("id")
	userIDStr := c.Get("user_id").(string)
	role, _ := c.Get("role").(string)
	userID, _ := uuid.Parse(userIDStr)

	var ref string = userIDStr
	if role == "MEMBER" {
		member, err := h.Queries.GetMember(context.Background(), userID)
		if err == nil {
			ref = member.ReferralCode
		}
	} else {
		reseller, err := h.Queries.GetReseller(context.Background(), userID)
		if err == nil {
			ref = reseller.ReferralCode
		}
	}

	shareURL := fmt.Sprintf("https://marketplace.com/p/%s?ref=%s", productID, ref)

	return response.Success(c, http.StatusOK, "SHARE_URL_GENERATED", map[string]string{
		"share_url": shareURL,
	})
}

// Track Click
func (h *ClientHandler) TrackClick(c echo.Context) error {
	productID, _ := uuid.Parse(c.QueryParam("product_id"))
	ref := c.QueryParam("ref")

	var resellerID uuid.UUID
	if id, err := uuid.Parse(ref); err == nil {
		resellerID = id
	} else {
		// Lookup by code
		reseller, err := h.Queries.GetResellerByReferralCode(context.Background(), ref)
		if err == nil {
			resellerID = reseller.ID
		} else {
			// Try member if not reseller
			member, err := h.Queries.GetMemberByReferralCode(context.Background(), ref)
			if err == nil {
				resellerID = member.ID
			}
		}
	}

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

// Track Share (when user taps the share button for a product)
func (h *ClientHandler) TrackShare(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	productIDStr := c.QueryParam("product_id")
	productID, err := uuid.Parse(productIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	if role == "MEMBER" {
		h.Queries.TrackMemberShare(context.Background(), db.TrackMemberShareParams{
			MemberID:  userID,
			ProductID: productID,
		})
	} else {
		h.Queries.TrackResellerShare(context.Background(), db.TrackResellerShareParams{
			ProductID:  productID,
			ResellerID: userID,
		})
	}

	return response.Success(c, http.StatusOK, "SHARE_TRACKED", nil)
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

	var resellerID uuid.NullUUID
	var memberID uuid.NullUUID

	// Check if RefCode is UUID (direct ID)
	if id, err := uuid.Parse(req.RefCode); err == nil {
		// By default assume reseller for direct UUID (legacy support)
		resellerID = uuid.NullUUID{UUID: id, Valid: true}
	} else {
		// Lookup by code
		reseller, err := h.Queries.GetResellerByReferralCode(context.Background(), req.RefCode)
		if err == nil {
			resellerID = uuid.NullUUID{UUID: reseller.ID, Valid: true}
		} else {
			member, err := h.Queries.GetMemberByReferralCode(context.Background(), req.RefCode)
			if err == nil {
				memberID = uuid.NullUUID{UUID: member.ID, Valid: true}
			} else {
				return response.Error(c, apperrors.ErrNotFound)
			}
		}
	}

	lead, err := h.Queries.CreateLead(context.Background(), db.CreateLeadParams{
		ProductID:    productID,
		ResellerID:   resellerID,
		MemberID:     memberID,
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

	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	log.Printf("[GetStats] Debug: userID=%s, role=%s", userID, role)

	var totalLeads, totalShares, totalSales int64

	var totalTeamCommission int64
	var recentResponse = make([]map[string]interface{}, 0)
	var networkResponse = make([]map[string]interface{}, 0)
	var referralCode string
	var name string

	if role == "MEMBER" {
		stats, _ := h.Queries.GetMemberStats(context.Background(), userID)
		totalLeads = stats.TotalLeads
		totalShares = stats.TotalShares


		// Get total sales count and total team commission
		teamStats, _ := h.Queries.GetMemberTeamStats(context.Background(), uuid.NullUUID{UUID: userID, Valid: true})
		totalSales = teamStats.TotalSales
		totalTeamCommission = teamStats.TotalCommission

		recent, _ := h.Queries.GetMemberRecentActivities(context.Background(), db.GetMemberRecentActivitiesParams{
			MemberID: uuid.NullUUID{UUID: userID, Valid: true},
			Limit:    5,
		})
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

		member, _ := h.Queries.GetMember(context.Background(), userID)
		name = member.Name
		referralCode = member.ReferralCode

		// Fetch network (downlines)
		log.Printf("[GetStats] Fetching network for Member ID: %s", userID.String())
		network, err := h.Queries.ListResellersByMember(context.Background(), uuid.NullUUID{UUID: userID, Valid: true})
		if err != nil {
			log.Printf("[GetStats] Error fetching network: %v", err)
		}
		log.Printf("[GetStats] Found %d resellers in network", len(network))

		for _, res := range network {
			networkResponse = append(networkResponse, map[string]interface{}{
				"id":            res.ID,
				"name":          res.Name,
				"phone":         res.Phone,
				"referral_code": res.ReferralCode,
				"status":        res.Status,
				"created_at":    res.CreatedAt,
			})
		}
	} else {
		// Default to Reseller
		stats, _ := h.Queries.GetResellerStats(context.Background(), userID)
		totalLeads = stats.TotalLeads
		totalShares = stats.TotalShares


		recent, _ := h.Queries.GetResellerRecentActivities(context.Background(), db.GetResellerRecentActivitiesParams{
			ResellerID: uuid.NullUUID{UUID: userID, Valid: true},
			Limit:      5,
		})
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

		reseller, _ := h.Queries.GetReseller(context.Background(), userID)
		name = reseller.Name
		referralCode = reseller.ReferralCode
	}

	userType := "RESELLER"
	if role == "MEMBER" {
		userType = "MEMBER"
	}

	totalCommission, _ := h.Queries.GetTotalCommissionAll(context.Background(), db.GetTotalCommissionAllParams{
		UserID:   uuid.NullUUID{UUID: userID, Valid: true},
		UserType: db.CommissionUserType(userType),
	})
	totalPaid, _ := h.Queries.GetTotalPayoutByUser(context.Background(), db.GetTotalPayoutByUserParams{
		UserID:   userID,
		UserType: userType,
	})
	totalClicks, _ := h.Queries.GetResellerClickCount(context.Background(), userID)

	return response.Success(c, http.StatusOK, "STATS_RETRIEVED", map[string]interface{}{
		"total_leads":       totalLeads,
		"total_shares":      totalShares,

		"total_commission":  totalCommission,
		"total_paid":        totalPaid,
		"available_balance": totalCommission - totalPaid,
		"total_clicks":      totalClicks,
		"total_sales":       totalSales,
		"team_commission":   totalTeamCommission,
		"referral_code":     referralCode,
		"name":              name,
		"role":              role,
		"recent_activities": recentResponse,
		"network":           networkResponse,
	})
}

// Get Payout History (My Rembers)
func (h *ClientHandler) GetMyPayouts(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	userType := "RESELLER"
	if role == "MEMBER" {
		userType = "MEMBER"
	}

	payouts, err := h.Queries.ListPayoutsByUser(context.Background(), db.ListPayoutsByUserParams{
		UserID:   userID,
		UserType: userType,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "PAYOUTS_RETRIEVED", payouts)
}


// Get Commission History
func (h *ClientHandler) GetMyCommissions(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	userType := "RESELLER"
	if role == "MEMBER" {
		userType = "MEMBER"
	}

	commissions, err := h.Queries.GetUserCommissions(context.Background(), db.GetUserCommissionsParams{
		UserID:   uuid.NullUUID{UUID: userID, Valid: true},
		UserType: db.CommissionUserType(userType),
	})

	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "COMMISSIONS_RETRIEVED", commissions)
}

// ── Profile Endpoints ──────────────────────────────────────────────────────────

// GET /client/profile — returns full profile data
func (h *ClientHandler) GetProfile(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	if role == "MEMBER" {
		member, err := h.Queries.GetMember(context.Background(), userID)
		if err != nil {
			return response.Error(c, apperrors.ErrNotFound)
		}
		return response.Success(c, http.StatusOK, "PROFILE_RETRIEVED", map[string]interface{}{
			"id":             member.ID,
			"name":           member.Name,
			"username":       nullStrVal(member.Username),
			"email":          nullStrVal(member.Email),
			"phone":          member.Phone,
			"dana_phone":     nullStrVal(member.DanaPhone),
			"bio":            nullStrVal(member.Bio),
			"profile_image":  nullStrVal(member.ProfileImage),
			"phone_verified": member.PhoneVerifiedAt.Valid,
			"referral_code":  member.ReferralCode,
			"status":         member.Status,
			"role":           "MEMBER",
		})
	}

	// Default: RESELLER
	reseller, err := h.Queries.GetReseller(context.Background(), userID)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}
	return response.Success(c, http.StatusOK, "PROFILE_RETRIEVED", map[string]interface{}{
		"id":             reseller.ID,
		"name":           reseller.Name,
		"username":       nullStrVal(reseller.Username),
		"email":          nullStrVal(reseller.Email),
		"phone":          reseller.Phone,
		"dana_phone":     nullStrVal(reseller.DanaPhone),
		"bio":            nullStrVal(reseller.Bio),
		"profile_image":  nullStrVal(reseller.ProfileImage),
		"phone_verified": reseller.PhoneVerifiedAt.Valid,
		"referral_code":  reseller.ReferralCode,
		"status":         reseller.Status,
		"role":           "RESELLER",
	})
}

type UpdateProfileRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
	Bio   string `json:"bio"`
}

// PUT /client/profile — updates name, email, bio only
func (h *ClientHandler) UpdateProfile(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	var req UpdateProfileRequest
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}
	if req.Name == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	emailVal := sql.NullString{String: req.Email, Valid: req.Email != ""}
	bioVal := sql.NullString{String: req.Bio, Valid: req.Bio != ""}

	if role == "MEMBER" {
		updated, err := h.Queries.UpdateMemberProfile(context.Background(), db.UpdateMemberProfileParams{
			ID:    userID,
			Name:  req.Name,
			Email: emailVal,
			Bio:   bioVal,
		})
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		return response.Success(c, http.StatusOK, "PROFILE_UPDATED", map[string]interface{}{
			"name":  updated.Name,
			"email": nullStrVal(updated.Email),
			"bio":   nullStrVal(updated.Bio),
		})
	}

	updated, err := h.Queries.UpdateResellerProfile(context.Background(), db.UpdateResellerProfileParams{
		ID:    userID,
		Name:  req.Name,
		Email: emailVal,
		Bio:   bioVal,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "PROFILE_UPDATED", map[string]interface{}{
		"name":  updated.Name,
		"email": nullStrVal(updated.Email),
		"bio":   nullStrVal(updated.Bio),
	})
}

// POST /client/verify-phone — marks phone as verified (OTP flow placeholder)
func (h *ClientHandler) VerifyPhone(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// TODO: In production, validate OTP code sent via SMS before marking verified
	// var req struct { OTP string `json:"otp"` }
	// c.Bind(&req) → validate OTP

	if role == "MEMBER" {
		result, err := h.Queries.MarkMemberPhoneVerified(context.Background(), userID)
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		return response.Success(c, http.StatusOK, "PHONE_VERIFIED", map[string]interface{}{
			"phone_verified_at": result,
		})
	}

	result, err := h.Queries.MarkResellerPhoneVerified(context.Background(), userID)
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}
	return response.Success(c, http.StatusOK, "PHONE_VERIFIED", map[string]interface{}{
		"phone_verified_at": result,
	})
}

// RequestWithdrawal allows members and resellers to request withdrawal of their commissions to their DANA account
func (h *ClientHandler) RequestWithdrawal(c echo.Context) error {
	type WithdrawalRequest struct {
		Amount int64  `json:"amount"`
		Notes  string `json:"notes"`
	}

	var req WithdrawalRequest
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	var phone string
	if role == "MEMBER" {
		member, err := h.Queries.GetMember(context.Background(), userID)
		if err != nil {
			return response.Error(c, apperrors.ErrNotFound)
		}
		if !member.DanaPhone.Valid || member.DanaPhone.String == "" {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Nomor DANA belum diatur. Silakan atur di profil Anda."})
		}
		phone = member.DanaPhone.String
	} else {
		reseller, err := h.Queries.GetReseller(context.Background(), userID)
		if err != nil {
			return response.Error(c, apperrors.ErrNotFound)
		}
		if !reseller.DanaPhone.Valid || reseller.DanaPhone.String == "" {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Nomor DANA belum diatur. Silakan atur di profil Anda."})
		}
		phone = reseller.DanaPhone.String
	}

	// Calculate balance
	totalCommission, err := h.Queries.GetTotalCommissionAll(context.Background(), db.GetTotalCommissionAllParams{
		UserID:   uuid.NullUUID{UUID: userID, Valid: true},
		UserType: db.CommissionUserType(role),
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	totalPaid, err := h.Queries.GetTotalPayoutByUser(context.Background(), db.GetTotalPayoutByUserParams{
		UserID:   userID,
		UserType: role,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	availableBalance := totalCommission - totalPaid

	if req.Amount <= 0 {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Jumlah penarikan harus lebih besar dari 0"})
	}

	if req.Amount > availableBalance {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Saldo tidak mencukupi"})
	}

	// 1. Check daily withdrawal limit (dynamic from config, default 1)
	loc, locErr := time.LoadLocation("Asia/Jakarta")
	if locErr != nil {
		loc = time.Local
	}
	now := time.Now().In(loc)
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)

	payoutCount, err := h.Queries.GetPayoutCountByUserAndDate(context.Background(), db.GetPayoutCountByUserAndDateParams{
		UserID:    userID,
		UserType:  role,
		CreatedAt: startOfDay,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	maxWithdrawals := int64(1)
	if cfg, err := h.Queries.GetSystemConfigByKey(context.Background(), "max_withdrawals_per_day"); err == nil {
		if val, err := strconv.ParseInt(cfg.Value, 10, 64); err == nil && val >= 1 {
			maxWithdrawals = val
		}
	}

	if payoutCount >= maxWithdrawals {
		if maxWithdrawals == 1 {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Batas penarikan adalah 1 kali sehari. Silakan coba lagi besok."})
		}
		return c.JSON(http.StatusBadRequest, map[string]string{"error": fmt.Sprintf("Batas penarikan adalah %d kali sehari. Silakan coba lagi besok.", maxWithdrawals)})
	}

	// 2. Validate minimum withdrawal amount using config
	minWithdraw := int64(20000)
	if cfg, err := h.Queries.GetSystemConfigByKey(context.Background(), "minimum_withdrawal_amount"); err == nil {
		if val, err := strconv.ParseInt(cfg.Value, 10, 64); err == nil && val >= 0 {
			minWithdraw = val
		}
	}

	if req.Amount < minWithdraw {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": fmt.Sprintf("Jumlah penarikan minimal adalah Rp %s", formatIndonesianAmount(minWithdraw))})
	}

	// Create pending payout in DB
	payout, err := h.Queries.CreatePayout(context.Background(), db.CreatePayoutParams{
		UserID:         userID,
		Amount:         req.Amount,
		ProofObjectKey: sql.NullString{Valid: false},
		Notes:          sql.NullString{String: req.Notes, Valid: req.Notes != ""},
		UserType:       role,
	})
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	merchantTransID := fmt.Sprintf("WDR-%s", payout.ID.String()[:8])
	payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
		ID:                payout.ID,
		Status:            "PENDING",
		DanaTransactionID: sql.NullString{Valid: false},
		MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
		FailedReason:      sql.NullString{Valid: false},
	})

	if h.DanaClient != nil {
		danaTxID, err := h.DanaClient.TransferToDana(context.Background(), merchantTransID, phone, req.Amount, req.Notes)
		if err != nil {
			payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
				ID:                payout.ID,
				Status:            "FAILED",
				DanaTransactionID: sql.NullString{Valid: false},
				MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
				FailedReason:      sql.NullString{String: err.Error(), Valid: true},
			})
			if h.Notification != nil {
				h.Notification.NotifyUser(context.Background(), userID, role,
					"Penarikan Dana Gagal",
					fmt.Sprintf("Penarikan dana sebesar Rp %d gagal diproses. Alasan: %s", req.Amount, err.Error()),
					map[string]string{"type": "withdrawal_failed", "amount": fmt.Sprintf("%d", req.Amount), "reason": err.Error()})
			}
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error":  "DANA transfer failed",
				"reason": err.Error(),
				"payout": payout,
			})
		}

		payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
			ID:                payout.ID,
			Status:            "SUCCESS",
			DanaTransactionID: sql.NullString{String: danaTxID, Valid: true},
			MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
			FailedReason:      sql.NullString{Valid: false},
		})
		if h.Notification != nil {
			h.Notification.NotifyUser(context.Background(), userID, role,
				"Penarikan Dana Sukses!",
				fmt.Sprintf("Penarikan dana sebesar Rp %d sukses dikirim ke akun DANA Anda.", req.Amount),
				map[string]string{"type": "withdrawal_success", "amount": fmt.Sprintf("%d", req.Amount)})
		}
	} else {
		// Mock fallback for local sandbox / dev
		mockTxID := fmt.Sprintf("MOCK-WDR-TX-%s", uuid.New().String()[:8])
		payout, _ = h.Queries.UpdatePayoutDanaStatus(context.Background(), db.UpdatePayoutDanaStatusParams{
			ID:                payout.ID,
			Status:            "SUCCESS",
			DanaTransactionID: sql.NullString{String: mockTxID, Valid: true},
			MerchantTransID:   sql.NullString{String: merchantTransID, Valid: true},
			FailedReason:      sql.NullString{Valid: false},
		})
		if h.Notification != nil {
			h.Notification.NotifyUser(context.Background(), userID, role,
				"Penarikan Dana Sukses!",
				fmt.Sprintf("Penarikan dana sebesar Rp %d sukses dikirim ke akun DANA Anda.", req.Amount),
				map[string]string{"type": "withdrawal_success", "amount": fmt.Sprintf("%d", req.Amount)})
		}
	}

	return response.Success(c, http.StatusCreated, "WITHDRAWAL_SUCCESSFUL", payout)
}

// nullStrVal extracts string value from sql.NullString
func nullStrVal(ns sql.NullString) string {
	if ns.Valid {
		return ns.String
	}
	return ""
}

// formatIndonesianAmount formats 20000 -> "20.000"
func formatIndonesianAmount(amount int64) string {
	s := strconv.FormatInt(amount, 10)
	n := len(s)
	if n <= 3 {
		return s
	}
	var res []string
	for n > 0 {
		start := n - 3
		if start < 0 {
			start = 0
		}
		res = append([]string{s[start:n]}, res...)
		n -= 3
	}
	return strings.Join(res, ".")
}
