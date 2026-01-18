package apperrors

import (
	"errors"
	"net/http"
)

type AppError struct {
	Code    int    `json:"-"`
	Action  string `json:"action"`
	Message string `json:"message"`
}

func (e *AppError) Error() string {
	return e.Message
}

func NewAppError(code int, action string, message string) *AppError {
	return &AppError{
		Code:    code,
		Action:  action,
		Message: message,
	}
}

var (
	ErrBadRequest          = NewAppError(http.StatusBadRequest, "INVALID_PAYLOAD", "Bad request")
	ErrUnauthorized        = NewAppError(http.StatusUnauthorized, "UNAUTHORIZED", "Unauthorized access")
	ErrForbidden           = NewAppError(http.StatusForbidden, "FORBIDDEN", "Forbidden access")
	ErrNotFound            = NewAppError(http.StatusNotFound, "NOT_FOUND", "Resource not found")
	ErrInternalServerError = NewAppError(http.StatusInternalServerError, "INTERNAL_SERVER_ERROR", "Internal server error")
	ErrConflict            = NewAppError(http.StatusConflict, "CONFLICT", "Resource already exists")
	ErrInsufficientBalance = NewAppError(http.StatusUnprocessableEntity, "INSUFFICIENT_BALANCE", "Insufficient balance")
)

// Helper to convert standard error to AppError
func FromError(err error) *AppError {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return &AppError{
		Code:    http.StatusInternalServerError,
		Action:  "INTERNAL_SERVER_ERROR",
		Message: err.Error(),
	}
}
