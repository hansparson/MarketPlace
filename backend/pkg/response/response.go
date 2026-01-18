package response

import (
	"github.com/user/marketplace-backend/pkg/apperrors"

	"github.com/labstack/echo/v4"
)

type Response struct {
	APICallID     string      `json:"api_call_id"`
	MessageAction string      `json:"message_action"`
	MessageData   interface{} `json:"message_data"`
}

func getRequestID(c echo.Context) string {
	// Try to get Request ID from header (set by middleware.RequestID)
	reqID := c.Response().Header().Get(echo.HeaderXRequestID)
	if reqID == "" {
		return "N/A"
	}
	return reqID
}

func Success(c echo.Context, status int, action string, data interface{}) error {
	return c.JSON(status, Response{
		APICallID:     getRequestID(c),
		MessageAction: action,
		MessageData:   data,
	})
}

func JSON(c echo.Context, status int, action string, data interface{}) error {
	return c.JSON(status, Response{
		APICallID:     getRequestID(c),
		MessageAction: action,
		MessageData:   data,
	})
}

func Error(c echo.Context, err error) error {
	appErr := apperrors.FromError(err)
	return c.JSON(appErr.Code, Response{
		APICallID:     getRequestID(c),
		MessageAction: appErr.Action,
		MessageData:   appErr.Message,
	})
}
