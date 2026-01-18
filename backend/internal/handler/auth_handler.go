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

	user, err := h.Queries.GetUserByPhone(context.Background(), req.Phone)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// Verify Role
	if user.Role != db.UserRoleRESELLER {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	// Check password (simple check for now)
	if user.PasswordHash != req.Password {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	token, err := utils.GenerateToken(user.ID.String(), string(user.Role))
	if err != nil {
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	return response.Success(c, http.StatusOK, "LOGIN_SUCCESS", map[string]interface{}{
		"token": token,
		"role":  string(user.Role),
		"user":  user,
	})
}
