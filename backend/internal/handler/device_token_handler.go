package handler

import (
	"context"
	"net/http"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
)

type DeviceTokenHandler struct {
	Queries db.Querier
}

func NewDeviceTokenHandler(q db.Querier) *DeviceTokenHandler {
	return &DeviceTokenHandler{Queries: q}
}

type DeviceTokenRequest struct {
	Token      string `json:"token"`
	DeviceType string `json:"device_type"`
}

// POST /api/client/device-token
func (h *DeviceTokenHandler) UpsertDeviceToken(c echo.Context) error {
	userIDStr, ok := c.Get("user_id").(string)
	if !ok {
		return response.Error(c, apperrors.ErrUnauthorized)
	}
	role, _ := c.Get("role").(string)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrUnauthorized)
	}

	var req DeviceTokenRequest
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	if req.Token == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Token is required"})
	}

	deviceType := req.DeviceType
	if deviceType == "" {
		deviceType = "unknown"
	}

	deviceToken, err := h.Queries.UpsertDeviceToken(context.Background(), db.UpsertDeviceTokenParams{
		UserID:     userID,
		Role:       role,
		Token:      req.Token,
		DeviceType: deviceType,
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save device token: " + err.Error()})
	}

	return response.Success(c, http.StatusOK, "DEVICE_TOKEN_SAVED", deviceToken)
}

// DELETE /api/client/device-token
func (h *DeviceTokenHandler) DeleteDeviceToken(c echo.Context) error {
	var req struct {
		Token string `json:"token"`
	}
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	if req.Token == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Token is required"})
	}

	err := h.Queries.DeleteDeviceToken(context.Background(), req.Token)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete device token: " + err.Error()})
	}

	return response.Success(c, http.StatusOK, "DEVICE_TOKEN_DELETED", nil)
}

type MartDeviceTokenRequest struct {
	ClientID   string `json:"client_id"`
	Token      string `json:"token"`
	DeviceType string `json:"device_type"`
}

// POST /api/mart-client/device-token
func (h *DeviceTokenHandler) UpsertMartDeviceToken(c echo.Context) error {
	var req MartDeviceTokenRequest
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	if req.Token == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Token is required"})
	}

	clientID, err := uuid.Parse(req.ClientID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid client ID"})
	}

	deviceType := req.DeviceType
	if deviceType == "" {
		deviceType = "unknown"
	}

	deviceToken, err := h.Queries.UpsertDeviceToken(context.Background(), db.UpsertDeviceTokenParams{
		UserID:     clientID,
		Role:       "CLIENT",
		Token:      req.Token,
		DeviceType: deviceType,
	})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to save device token: " + err.Error()})
	}

	return response.Success(c, http.StatusOK, "DEVICE_TOKEN_SAVED", deviceToken)
}

// DELETE /api/mart-client/device-token
func (h *DeviceTokenHandler) DeleteMartDeviceToken(c echo.Context) error {
	var req struct {
		Token string `json:"token"`
	}
	if err := c.Bind(&req); err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	if req.Token == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Token is required"})
	}

	err := h.Queries.DeleteDeviceToken(context.Background(), req.Token)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete device token: " + err.Error()})
	}

	return response.Success(c, http.StatusOK, "DEVICE_TOKEN_DELETED", nil)
}
