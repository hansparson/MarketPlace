package handler

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/database/db"
)

// DanaPaymentCallback handles incoming webhook notifications from DANA
func (h *PublicHandler) DanaPaymentCallback(c echo.Context) error {
	// 1. Read Raw Body
	bodyBytes, err := io.ReadAll(c.Request().Body)
	if err != nil {
		fmt.Printf("[DANA Webhook] Failed to read body: %v\n", err)
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Failed to read request body"})
	}
	// Restore body reader for potential future use in context
	c.Request().Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

	// 2. Extract relative path for signature verification
	relativePath := c.Request().URL.Path

	// 3. Verify Signature if DanaClient is configured
	if h.DanaClient != nil {
		req, err := h.DanaClient.VerifyWebhook(c.Request().Method, relativePath, c.Request().Header, bodyBytes)
		if err != nil {
			fmt.Printf("[DANA Webhook] Signature verification failed: %v\n", err)
			return c.JSON(http.StatusUnauthorized, map[string]string{
				"responseCode":    "4015600",
				"responseMessage": "Unauthorized signature verification failed",
			})
		}

		fmt.Printf("[DANA Webhook] Verification passed. Invoice: %s, Status: %s\n",
			req.OriginalPartnerReferenceNo, req.LatestTransactionStatus)

		// 4. Process Status Update
		if req.LatestTransactionStatus == "00" { // Success
			payment, err := h.Queries.GetRegistrationPaymentByInvoice(context.Background(), req.OriginalPartnerReferenceNo)
			if err != nil {
				fmt.Printf("[DANA Webhook] Registration payment not found for invoice: %s, err: %v\n", req.OriginalPartnerReferenceNo, err)
				return c.JSON(http.StatusNotFound, map[string]string{"error": "Payment record not found"})
			}

			if payment.Status != "PAID" {
				// Update registration payment status to PAID
				_, err = h.Queries.UpdateRegistrationPaymentStatus(context.Background(), db.UpdateRegistrationPaymentStatusParams{
					ID:         payment.ID,
					Status:     "PAID",
					ExternalID: sql.NullString{String: req.OriginalReferenceNo, Valid: req.OriginalReferenceNo != ""},
				})
				if err != nil {
					fmt.Printf("[DANA Webhook] Failed to update payment status: %v\n", err)
					return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update payment status"})
				}

				// Activate the corresponding User
				if payment.UserType == "MEMBER" {
					_, err = h.Queries.UpdateMemberStatus(context.Background(), db.UpdateMemberStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
					if err != nil {
						fmt.Printf("[DANA Webhook] Failed to activate member %s: %v\n", payment.UserID, err)
					} else {
						fmt.Printf("[DANA Webhook] Activated member %s successfully\n", payment.UserID)
					}
				} else if payment.UserType == "RESELLER" {
					_, err = h.Queries.UpdateResellerStatus(context.Background(), db.UpdateResellerStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
					if err != nil {
						fmt.Printf("[DANA Webhook] Failed to activate reseller %s: %v\n", payment.UserID, err)
					} else {
						fmt.Printf("[DANA Webhook] Activated reseller %s successfully\n", payment.UserID)
						h.rewardResellerReferralCommission(context.Background(), payment.UserID)
					}
				}
			}
		}
	} else {
		// Fallback for development/testing if DANA client is not configured: parse raw JSON directly
		var rawNotify struct {
			OriginalPartnerReferenceNo string `json:"originalPartnerReferenceNo"`
			OriginalReferenceNo        string `json:"originalReferenceNo"`
			LatestTransactionStatus    string `json:"latestTransactionStatus"`
		}
		if err := json.Unmarshal(bodyBytes, &rawNotify); err == nil && rawNotify.LatestTransactionStatus == "00" {
			payment, err := h.Queries.GetRegistrationPaymentByInvoice(context.Background(), rawNotify.OriginalPartnerReferenceNo)
			if err == nil && payment.Status != "PAID" {
				_, _ = h.Queries.UpdateRegistrationPaymentStatus(context.Background(), db.UpdateRegistrationPaymentStatusParams{
					ID:         payment.ID,
					Status:     "PAID",
					ExternalID: sql.NullString{String: rawNotify.OriginalReferenceNo, Valid: rawNotify.OriginalReferenceNo != ""},
				})
				if payment.UserType == "MEMBER" {
					_, _ = h.Queries.UpdateMemberStatus(context.Background(), db.UpdateMemberStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
				} else if payment.UserType == "RESELLER" {
					_, err = h.Queries.UpdateResellerStatus(context.Background(), db.UpdateResellerStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
					if err == nil {
						h.rewardResellerReferralCommission(context.Background(), payment.UserID)
					}
				}
			}
		}
	}

	// 5. Standard SNAP Response
	return c.JSON(http.StatusOK, map[string]string{
		"responseCode":    "2005600",
		"responseMessage": "Successful",
	})
}
