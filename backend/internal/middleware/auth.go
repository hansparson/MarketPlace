package middleware

import (
	"strings"

	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
	"github.com/user/marketplace-backend/pkg/utils"

	"github.com/labstack/echo/v4"
)

func JWTMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		authHeader := c.Request().Header.Get("Authorization")
		if authHeader == "" {
			return response.Error(c, apperrors.ErrUnauthorized)
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return response.Error(c, apperrors.ErrUnauthorized)
		}

		tokenString := parts[1]
		claims, err := utils.ValidateToken(tokenString)
		if err != nil {
			return response.Error(c, apperrors.ErrUnauthorized)
		}

		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)
		return next(c)
	}
}

func RoleMiddleware(roles ...string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			userRole := c.Get("role").(string)
			allowed := false
			for _, role := range roles {
				if userRole == role {
					allowed = true
					break
				}
			}

			if !allowed {
				return response.Error(c, apperrors.ErrForbidden)
			}
			return next(c)
		}
	}
}
