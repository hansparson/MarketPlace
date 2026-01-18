package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog"
)

// ZerologMiddleware creates a middleware that logs all requests with detailed information
func ZerologMiddleware(logger zerolog.Logger) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			req := c.Request()
			res := c.Response()

			start := time.Now()

			// Get API Call ID from header
			apiCallID := res.Header().Get(echo.HeaderXRequestID)
			if apiCallID == "" {
				apiCallID = c.Response().Header().Get(echo.HeaderXRequestID)
			}

			// Read request body
			var requestBody []byte
			if req.Body != nil {
				requestBody, _ = io.ReadAll(req.Body)
				req.Body = io.NopCloser(bytes.NewBuffer(requestBody))
			}

			// Parse request body as JSON for logging
			var requestJSON interface{}
			if len(requestBody) > 0 {
				json.Unmarshal(requestBody, &requestJSON)
			}

			// Log request start
			logger.Info().
				Str("api_call_id", apiCallID).
				Str("method", req.Method).
				Str("uri", req.RequestURI).
				Str("remote_ip", c.RealIP()).
				Interface("headers", req.Header).
				Interface("payload", requestJSON).
				Msg("REQUEST_START")

			// Process request
			err := next(c)

			// Calculate latency
			latency := time.Since(start)

			// Determine log level based on status code
			logEvent := logger.Info()
			if res.Status >= 500 {
				logEvent = logger.Error()
			} else if res.Status >= 400 {
				logEvent = logger.Warn()
			}

			// Log request end
			logEvent.
				Str("api_call_id", apiCallID).
				Str("method", req.Method).
				Str("uri", req.RequestURI).
				Int("status", res.Status).
				Dur("latency_ms", latency).
				Int64("bytes_in", req.ContentLength).
				Int64("bytes_out", res.Size).
				Msg("REQUEST_END")

			// Log error if exists
			if err != nil {
				logger.Error().
					Str("api_call_id", apiCallID).
					Err(err).
					Str("method", req.Method).
					Str("uri", req.RequestURI).
					Msg("REQUEST_ERROR")
			}

			return err
		}
	}
}
