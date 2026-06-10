package handler

import (
	"context"
	"database/sql"
	"log"
	"net/http"

	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
	"github.com/user/marketplace-backend/pkg/utils"

	"github.com/labstack/echo/v4"
)

type AuthHandler struct {
	Queries db.Querier
	DB      *sql.DB
}

func NewAuthHandler(q db.Querier, d *sql.DB) *AuthHandler {
	return &AuthHandler{Queries: q, DB: d}
}

type LoginRequest struct {
	Email    string `json:"email" example:"admin@marketplace.com"`
	Password string `json:"password" example:"admin123"`
}

// AdminLogin godoc
// @Summary Admin login
// @Description Login untuk admin dan super admin
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body LoginRequest true "Login credentials"
// @Success 200 {object} map[string]interface{} "Login successful"
// @Failure 400 {object} map[string]interface{} "Bad request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /auth/login/admin [post]
func (h *AuthHandler) AdminLogin(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	admin, err := h.Queries.GetAdminByEmail(context.Background(), req.Email)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// In production, use bcrypt.CompareHashAndPassword
	// For now, simple check
	if admin.PasswordHash != req.Password {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	token, err := utils.GenerateToken(admin.ID.String(), string(admin.Role))
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	log.Printf("[AdminLogin] Login successful - Admin ID: %s, Role: %s", admin.ID.String(), admin.Role)

	return response.Success(c, http.StatusOK, "LOGIN_SUCCESS", map[string]interface{}{
		"token": token,
		"role":  string(admin.Role),
		"user":  admin,
	})
}

type ResellerLoginRequest struct {
	Phone    string `json:"phone" example:"081234567890"`
	Password string `json:"password" example:"reseller123"`
}

// ResellerLogin godoc
// @Summary Reseller login
// @Description Login untuk reseller
// @Tags Auth
// @Accept json
// @Produce json
// @Param request body ResellerLoginRequest true "Login credentials"
// @Success 200 {object} map[string]interface{} "Login successful"
// @Failure 400 {object} map[string]interface{} "Bad request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /auth/login/reseller [post]
func (h *AuthHandler) ResellerLogin(c echo.Context) error {
	var req struct {
		Phone    string `json:"phone"`
		Password string `json:"password"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	reseller, err := h.Queries.GetResellerByPhone(context.Background(), req.Phone)
	if err != nil {
		// Try by username if phone not found
		resellerByUsername, err2 := h.Queries.GetResellerByUsername(context.Background(), sql.NullString{String: req.Phone, Valid: true})
		if err2 != nil {
			return response.Error(c, apperrors.ErrUnauthorized)
		}
		// Convert GetResellerByUsernameRow/Reseller to Reseller if needed
		// Reseller is the base struct
		reseller = resellerByUsername
	}

	// Check status
	if reseller.Status == "BLOCKED" {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// Check password (simple check for now)
	if reseller.PasswordHash != req.Password {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	token, err := utils.GenerateToken(reseller.ID.String(), "RESELLER")
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	var paymentURL, invoiceNumber string
	if reseller.Status == "PENDING" {
		payment, err := h.Queries.GetRegistrationPaymentByUserID(context.Background(), reseller.ID)
		if err == nil {
			paymentURL = payment.PaymentUrl.String
			invoiceNumber = payment.InvoiceNumber
		}
	}

	return response.Success(c, http.StatusOK, "LOGIN_SUCCESS", map[string]interface{}{
		"token":          token,
		"role":           "RESELLER",
		"user":           reseller,
		"payment_url":    paymentURL,
		"invoice_number": invoiceNumber,
	})
}

// MemberLogin
func (h *AuthHandler) MemberLogin(c echo.Context) error {
	var req struct {
		Phone    string `json:"phone"`
		Password string `json:"password"`
	}

	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	member, err := h.Queries.GetMemberByPhone(context.Background(), req.Phone)
	if err != nil {
		// Try by username if phone not found
		memberByUsername, err2 := h.Queries.GetMemberByUsername(context.Background(), sql.NullString{String: req.Phone, Valid: true})
		if err2 != nil {
			return response.Error(c, apperrors.ErrUnauthorized)
		}
		member = memberByUsername
	}

	// Check status
	if member.Status == "BLOCKED" {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// Check password (simple check for now)
	if member.PasswordHash != req.Password {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	token, err := utils.GenerateToken(member.ID.String(), "MEMBER")
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	var paymentURL, invoiceNumber string
	if member.Status == "PENDING" {
		payment, err := h.Queries.GetRegistrationPaymentByUserID(context.Background(), member.ID)
		if err == nil {
			paymentURL = payment.PaymentUrl.String
			invoiceNumber = payment.InvoiceNumber
		}
	}

	return response.Success(c, http.StatusOK, "LOGIN_SUCCESS", map[string]interface{}{
		"token":          token,
		"role":           "MEMBER",
		"user":           member,
		"payment_url":    paymentURL,
		"invoice_number": invoiceNumber,
	})
}
