package handler

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/response"
)

func normalizeIndonesianPhone(phone string) string {
	phone = strings.TrimSpace(phone)
	if strings.HasPrefix(phone, "+") {
		phone = phone[1:]
	}
	if strings.HasPrefix(phone, "0") {
		phone = "62" + phone[1:]
	}
	return phone
}

// RegisterMember handles member registration
func (h *PublicHandler) RegisterMember(c echo.Context) error {
	// Parse form data
	name := c.FormValue("name")
	nik := c.FormValue("nik")
	email := c.FormValue("email")
	phone := c.FormValue("phone")
	username := c.FormValue("username")
	password := c.FormValue("password")

	if name == "" || phone == "" || password == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	// Handle File Uploads (Optional for now, but usually required)
	var profileImageURL, ktpImageURL string

	if h.Storage != nil {
		profileFile, err := c.FormFile("profile_image")
		if err == nil {
			src, _ := profileFile.Open()
			defer src.Close()
			objName := fmt.Sprintf("profiles/%s_%s", uuid.New().String(), profileFile.Filename)
			profileImageURL, _ = h.Storage.UploadFile(context.Background(), profileFile, objName)
		}

		ktpFile, err := c.FormFile("ktp_image")
		if err == nil {
			objName := fmt.Sprintf("ktp/%s_%s", uuid.New().String(), ktpFile.Filename)
			ktpImageURL, _ = h.Storage.UploadFile(context.Background(), ktpFile, objName)
		}
	}

	// Generate Referral Code for the new member
	referralCode := "MBR-" + strings.ToUpper(uuid.New().String()[:8])
	status := "PENDING" // Needs DANA payment to activate

	// Save to DB
	member, err := h.Queries.CreateMember(context.Background(), db.CreateMemberParams{
		Name:         name,
		Phone:        phone,
		Email:        sql.NullString{String: email, Valid: email != ""},
		PasswordHash: password, // Note: In production, hash this with bcrypt!
		ReferralCode: referralCode,
		Status:       db.UserStatus(status),
		Username:     sql.NullString{String: username, Valid: username != ""},
		Nik:          sql.NullString{String: nik, Valid: nik != ""},
		ProfileImage: sql.NullString{String: profileImageURL, Valid: profileImageURL != ""},
		KtpImage:     sql.NullString{String: ktpImageURL, Valid: ktpImageURL != ""},
	})

	if err != nil {
		if strings.Contains(err.Error(), "unique constraint") {
			return response.Error(c, apperrors.ErrConflict)
		}
		fmt.Printf("ERROR Creating Member: %v\n", err)
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	// Update DANA phone
	danaPhone := c.FormValue("dana_phone")
	if danaPhone == "" {
		danaPhone = phone
	}
	danaPhone = normalizeIndonesianPhone(danaPhone)
	member, _ = h.Queries.UpdateMemberDanaPhone(context.Background(), db.UpdateMemberDanaPhoneParams{
		ID:        member.ID,
		DanaPhone: sql.NullString{String: danaPhone, Valid: danaPhone != ""},
	})

	// DANA Pay-In Integration
	memberFee := int64(10000)
	if cfg, err := h.Queries.GetSystemConfigByKey(c.Request().Context(), "member_registration_fee"); err == nil {
		if val, err := strconv.ParseInt(cfg.Value, 10, 64); err == nil && val >= 0 {
			memberFee = val
		}
	}

	var paymentURL, invoiceNumber string
	if h.DanaClient != nil {
		invoiceNumber = fmt.Sprintf("INV-MBR-%s", uuid.New().String()[:8])
		notifyURL := "https://gostar-mart.online/api/public/dana/payment-callback"
		
		pUrl, err := h.DanaClient.CreatePaymentOrder(c.Request().Context(), invoiceNumber, memberFee, "Biaya Registrasi Member", notifyURL)
		if err != nil {
			fmt.Printf("ERROR Creating DANA Payment: %v\n", err)
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		paymentURL = pUrl

		_, err = h.Queries.CreateRegistrationPayment(context.Background(), db.CreateRegistrationPaymentParams{
			UserID:        member.ID,
			UserType:      "MEMBER",
			InvoiceNumber: invoiceNumber,
			Amount:        memberFee,
			Status:        "PENDING",
			PaymentUrl:    sql.NullString{String: paymentURL, Valid: paymentURL != ""},
		})
		if err != nil {
			fmt.Printf("ERROR Creating Registration Payment DB Record: %v\n", err)
			return response.Error(c, apperrors.ErrInternalServerError)
		}
	} else {
		// Mock/Sandbox testing fallback when keys are not configured yet
		invoiceNumber = fmt.Sprintf("MOCK-INV-MBR-%s", uuid.New().String()[:8])
		paymentURL = fmt.Sprintf("https://gostar-mart.online/mock-dana-pay?invoice=%s", invoiceNumber)
		_, _ = h.Queries.CreateRegistrationPayment(context.Background(), db.CreateRegistrationPaymentParams{
			UserID:        member.ID,
			UserType:      "MEMBER",
			InvoiceNumber: invoiceNumber,
			Amount:        memberFee,
			Status:        "PENDING",
			PaymentUrl:    sql.NullString{String: paymentURL, Valid: true},
		})
	}

	return response.Success(c, http.StatusCreated, "MEMBER_REGISTERED", map[string]interface{}{
		"member":         member,
		"payment_url":    paymentURL,
		"invoice_number": invoiceNumber,
	})
}

// RegisterReseller handles reseller registration
func (h *PublicHandler) RegisterReseller(c echo.Context) error {
	// Parse form data
	name := c.FormValue("name")
	nik := c.FormValue("nik")
	email := c.FormValue("email")
	phone := c.FormValue("phone")
	username := c.FormValue("username")
	password := c.FormValue("password")
	leaderReferralCode := c.FormValue("referral_code") // This is the member's referral code

	if name == "" || phone == "" || password == "" || leaderReferralCode == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	// Verify the leader referral code exists
	member, err := h.Queries.GetMemberByReferralCode(context.Background(), leaderReferralCode)
	if err != nil {
		// Referral code not found
		return response.Error(c, apperrors.ErrNotFound) // Or a specific invalid referral error
	}

	if member.Status != "ACTIVE" {
		return response.Error(c, apperrors.ErrForbidden) // Member not active yet
	}

	// Handle File Uploads
	var profileImageURL, ktpImageURL string

	if h.Storage != nil {
		profileFile, err := c.FormFile("profile_image")
		if err == nil {
			objName := fmt.Sprintf("profiles/%s_%s", uuid.New().String(), profileFile.Filename)
			profileImageURL, _ = h.Storage.UploadFile(context.Background(), profileFile, objName)
		}

		ktpFile, err := c.FormFile("ktp_image")
		if err == nil {
			objName := fmt.Sprintf("ktp/%s_%s", uuid.New().String(), ktpFile.Filename)
			ktpImageURL, _ = h.Storage.UploadFile(context.Background(), ktpFile, objName)
		}
	}

	// Generate Referral Code for the new reseller (so they can sell)
	resellerRefCode := "RSL-" + strings.ToUpper(uuid.New().String()[:8])
	status := "PENDING" // Needs DANA payment to activate

	// Save to DB
	reseller, err := h.Queries.CreateReseller(context.Background(), db.CreateResellerParams{
		MemberID:     uuid.NullUUID{UUID: member.ID, Valid: true},
		Name:         name,
		Phone:        phone,
		Email:        sql.NullString{String: email, Valid: email != ""},
		PasswordHash: password, // Note: In production, hash this with bcrypt!
		ReferralCode: resellerRefCode,
		Status:       db.UserStatus(status),
		Username:     sql.NullString{String: username, Valid: username != ""},
		Nik:          sql.NullString{String: nik, Valid: nik != ""},
		ProfileImage: sql.NullString{String: profileImageURL, Valid: profileImageURL != ""},
		KtpImage:     sql.NullString{String: ktpImageURL, Valid: ktpImageURL != ""},
	})

	if err != nil {
		if strings.Contains(err.Error(), "unique constraint") {
			return response.Error(c, apperrors.ErrConflict)
		}
		fmt.Printf("ERROR Creating Reseller: %v\n", err)
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	// Notify member that reseller registered using their referral code
	if h.Notification != nil {
		h.Notification.NotifyUser(context.Background(), member.ID, "MEMBER",
			"Reseller Baru Terdaftar!",
			fmt.Sprintf("Reseller %s telah mendaftar menggunakan kode referral Anda. Status pendaftaran sedang ditinjau/menunggu pembayaran.", name),
			map[string]string{"type": "referral_signup", "reseller_name": name})
	}

	// Update DANA phone
	danaPhone := c.FormValue("dana_phone")
	if danaPhone == "" {
		danaPhone = phone
	}
	danaPhone = normalizeIndonesianPhone(danaPhone)
	reseller, _ = h.Queries.UpdateResellerDanaPhone(context.Background(), db.UpdateResellerDanaPhoneParams{
		ID:        reseller.ID,
		DanaPhone: sql.NullString{String: danaPhone, Valid: danaPhone != ""},
	})

	// DANA Pay-In Integration
	resellerFee := int64(50000)
	if cfg, err := h.Queries.GetSystemConfigByKey(c.Request().Context(), "reseller_registration_fee"); err == nil {
		if val, err := strconv.ParseInt(cfg.Value, 10, 64); err == nil && val >= 0 {
			resellerFee = val
		}
	}

	var paymentURL, invoiceNumber string
	if h.DanaClient != nil {
		invoiceNumber = fmt.Sprintf("INV-RSL-%s", uuid.New().String()[:8])
		notifyURL := "https://gostar-mart.online/api/public/dana/payment-callback"

		pUrl, err := h.DanaClient.CreatePaymentOrder(c.Request().Context(), invoiceNumber, resellerFee, "Biaya Registrasi Reseller", notifyURL)
		if err != nil {
			fmt.Printf("ERROR Creating DANA Payment for Reseller: %v\n", err)
			return response.Error(c, apperrors.ErrInternalServerError)
		}
		paymentURL = pUrl

		_, err = h.Queries.CreateRegistrationPayment(context.Background(), db.CreateRegistrationPaymentParams{
			UserID:        reseller.ID,
			UserType:      "RESELLER",
			InvoiceNumber: invoiceNumber,
			Amount:        resellerFee,
			Status:        "PENDING",
			PaymentUrl:    sql.NullString{String: paymentURL, Valid: paymentURL != ""},
		})
		if err != nil {
			fmt.Printf("ERROR Creating Registration Payment DB Record for Reseller: %v\n", err)
			return response.Error(c, apperrors.ErrInternalServerError)
		}
	} else {
		// Mock/Sandbox testing fallback when keys are not configured yet
		invoiceNumber = fmt.Sprintf("MOCK-INV-RSL-%s", uuid.New().String()[:8])
		paymentURL = fmt.Sprintf("https://gostar-mart.online/mock-dana-pay?invoice=%s", invoiceNumber)
		_, _ = h.Queries.CreateRegistrationPayment(context.Background(), db.CreateRegistrationPaymentParams{
			UserID:        reseller.ID,
			UserType:      "RESELLER",
			InvoiceNumber: invoiceNumber,
			Amount:        resellerFee,
			Status:        "PENDING",
			PaymentUrl:    sql.NullString{String: paymentURL, Valid: true},
		})
	}

	return response.Success(c, http.StatusCreated, "RESELLER_REGISTERED", map[string]interface{}{
		"reseller":       reseller,
		"payment_url":    paymentURL,
		"invoice_number": invoiceNumber,
	})
}

// VerifyReferralCode checks if a member referral code is valid and returns member info
func (h *PublicHandler) VerifyReferralCode(c echo.Context) error {
	code := c.Param("code")
	if code == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	member, err := h.Queries.GetMemberByReferralCode(context.Background(), code)
	if err != nil {
		return response.Error(c, apperrors.ErrNotFound)
	}

	if member.Status != "ACTIVE" {
		return c.JSON(http.StatusForbidden, map[string]interface{}{
			"message_action": "MEMBER_NOT_ACTIVE",
			"message_data":   "Member yang merujuk Anda belum aktif.",
		})
	}

	return response.Success(c, http.StatusOK, "REFERRAL_VALID", map[string]interface{}{
		"name":          member.Name,
		"referral_code": member.ReferralCode,
	})
}

// VerifyDanaPhone checks if a phone number is registered and active on DANA
func (h *PublicHandler) VerifyDanaPhone(c echo.Context) error {
	phone := c.Param("phone")
	if phone == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	phone = normalizeIndonesianPhone(phone)

	// 1. If DanaClient is initialized, use the real SDK call
	if h.DanaClient != nil {
		isValid, status, err := h.DanaClient.DanaAccountInquiry(c.Request().Context(), phone)
		if err != nil {
			fmt.Printf("[VerifyDanaPhone] Error checking phone %s: %v\n", phone, err)
			return c.JSON(http.StatusOK, map[string]interface{}{
				"message_action": "DANA_PHONE_UNVERIFIED",
				"message_data": map[string]interface{}{
					"phone":    phone,
					"status":   "ERROR",
					"is_valid": false,
					"error":    err.Error(),
				},
			})
		}

		return response.Success(c, http.StatusOK, "DANA_PHONE_VERIFIED", map[string]interface{}{
			"phone":    phone,
			"status":   status,
			"is_valid": isValid,
		})
	}

	// 2. Mock mode for local testing if DanaClient is not configured
	// Simulate unregistered error for phone numbers ending in 666
	isValid := true
	status := "ACTIVE"
	if strings.HasSuffix(phone, "666") {
		isValid = false
		status = "UNREGISTERED"
	} else if strings.HasSuffix(phone, "777") {
		isValid = false
		status = "FROZEN"
	}

	return response.Success(c, http.StatusOK, "DANA_PHONE_VERIFIED", map[string]interface{}{
		"phone":    phone,
		"status":   status,
		"is_valid": isValid,
	})
}

// GetRegistrationStatus checks the status of registration payment for a user ID
func (h *PublicHandler) GetRegistrationStatus(c echo.Context) error {
	userIDStr := c.Param("userId")
	if userIDStr == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	payment, err := h.Queries.GetRegistrationPaymentByUserID(c.Request().Context(), userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return response.Error(c, apperrors.ErrNotFound)
		}
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	// Active Inquiry: if local status is PENDING and DANA Client is configured, check live status directly
	if payment.Status == "PENDING" && h.DanaClient != nil {
		status, extRefNo, err := h.DanaClient.QueryPaymentStatus(c.Request().Context(), payment.InvoiceNumber)
		if err != nil {
			// Log error but don't fail the request, fallback to returning database status
			fmt.Printf("[Active Inquiry] Failed to query DANA payment status for invoice %s: %v\n", payment.InvoiceNumber, err)
		} else if status == "00" { // DANA success status
			// Update local DB status to PAID
			_, err = h.Queries.UpdateRegistrationPaymentStatus(c.Request().Context(), db.UpdateRegistrationPaymentStatusParams{
				ID:         payment.ID,
				Status:     "PAID",
				ExternalID: sql.NullString{String: extRefNo, Valid: extRefNo != ""},
			})
			if err != nil {
				fmt.Printf("[Active Inquiry] Failed to update payment status in DB: %v\n", err)
			} else {
				payment.Status = "PAID"
				payment.ExternalID = sql.NullString{String: extRefNo, Valid: extRefNo != ""}

				// Activate the corresponding User
				if payment.UserType == "MEMBER" {
					_, err = h.Queries.UpdateMemberStatus(c.Request().Context(), db.UpdateMemberStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
					if err != nil {
						fmt.Printf("[Active Inquiry] Failed to activate member %s: %v\n", payment.UserID, err)
					} else {
						fmt.Printf("[Active Inquiry] Activated member %s successfully\n", payment.UserID)
					}
				} else if payment.UserType == "RESELLER" {
					_, err = h.Queries.UpdateResellerStatus(c.Request().Context(), db.UpdateResellerStatusParams{
						ID:     payment.UserID,
						Status: db.UserStatusACTIVE,
					})
					if err != nil {
						fmt.Printf("[Active Inquiry] Failed to activate reseller %s: %v\n", payment.UserID, err)
					} else {
						fmt.Printf("[Active Inquiry] Activated reseller %s successfully\n", payment.UserID)
						h.rewardResellerReferralCommission(c.Request().Context(), payment.UserID)
					}
				}
			}
		}
	}

	return response.Success(c, http.StatusOK, "REGISTRATION_STATUS_RETRIEVED", map[string]interface{}{
		"user_id":        payment.UserID,
		"user_type":      payment.UserType,
		"invoice_number": payment.InvoiceNumber,
		"amount":         payment.Amount,
		"status":         payment.Status,
		"payment_url":    payment.PaymentUrl.String,
	})
}

// SimulatePayment allows simulation of payment success in local/UAT environments
func (h *PublicHandler) SimulatePayment(c echo.Context) error {
	invoiceNumber := c.Param("invoiceNumber")
	if invoiceNumber == "" {
		return response.Error(c, apperrors.ErrBadRequest)
	}

	payment, err := h.Queries.GetRegistrationPaymentByInvoice(c.Request().Context(), invoiceNumber)
	if err != nil {
		if err == sql.ErrNoRows {
			return response.Error(c, apperrors.ErrNotFound)
		}
		return response.Error(c, apperrors.ErrInternalServerError)
	}

	if payment.Status != "PAID" {
		_, err = h.Queries.UpdateRegistrationPaymentStatus(c.Request().Context(), db.UpdateRegistrationPaymentStatusParams{
			ID:         payment.ID,
			Status:     "PAID",
			ExternalID: sql.NullString{String: "MOCK-VA-PAYMENT-SIMULATOR", Valid: true},
		})
		if err != nil {
			return response.Error(c, apperrors.ErrInternalServerError)
		}

		if payment.UserType == "MEMBER" {
			_, err = h.Queries.UpdateMemberStatus(c.Request().Context(), db.UpdateMemberStatusParams{
				ID:     payment.UserID,
				Status: db.UserStatusACTIVE,
			})
			if err != nil {
				fmt.Printf("[SimulatePayment] Failed to activate member: %v\n", err)
			}
		} else if payment.UserType == "RESELLER" {
			_, err = h.Queries.UpdateResellerStatus(c.Request().Context(), db.UpdateResellerStatusParams{
				ID:     payment.UserID,
				Status: db.UserStatusACTIVE,
			})
			if err != nil {
				fmt.Printf("[SimulatePayment] Failed to activate reseller: %v\n", err)
			} else {
				h.rewardResellerReferralCommission(c.Request().Context(), payment.UserID)
			}
		}
	}

	return response.Success(c, http.StatusOK, "PAYMENT_SIMULATED", map[string]interface{}{
		"invoice_number": invoiceNumber,
		"status":         "PAID",
	})
}

// rewardResellerReferralCommission rewards the leader (member) of a reseller when they activate
func (h *PublicHandler) rewardResellerReferralCommission(ctx context.Context, resellerID uuid.UUID) {
	// 1. Fetch Reseller
	reseller, err := h.Queries.GetReseller(ctx, resellerID)
	if err != nil {
		log.Printf("[ReferralCommission] Failed to fetch reseller %s: %v", resellerID, err)
		return
	}

	// 2. Check if reseller has a leader (member_id)
	if !reseller.MemberID.Valid {
		log.Printf("[ReferralCommission] Reseller %s has no leader, skipping commission.", reseller.Name)
		return
	}

	memberID := reseller.MemberID.UUID

	// 3. Fetch Member
	member, err := h.Queries.GetMember(ctx, memberID)
	if err != nil {
		log.Printf("[ReferralCommission] Failed to fetch member %s: %v", memberID, err)
		return
	}

	// 4. Fetch commission amount from system config
	commissionAmount := int64(10000) // Default Rp 10.000
	if cfg, err := h.Queries.GetSystemConfigByKey(ctx, "reseller_referral_commission"); err == nil {
		if val, err := strconv.ParseInt(cfg.Value, 10, 64); err == nil && val >= 0 {
			commissionAmount = val
		}
	}

	if commissionAmount <= 0 {
		log.Printf("[ReferralCommission] Commission amount is 0 or negative, skipping.")
		return
	}

	// 5. Check if commission already exists for this reseller to prevent double-crediting
	exists, err := h.Queries.CheckReferralCommissionExists(ctx, db.CheckReferralCommissionExistsParams{
		UserID:       uuid.NullUUID{UUID: memberID, Valid: true},
		ReferralCode: sql.NullString{String: reseller.ReferralCode, Valid: true},
	})
	if err != nil {
		log.Printf("[ReferralCommission] Failed to check if commission exists: %v", err)
		return
	}

	if exists {
		log.Printf("[ReferralCommission] Commission already credited to member %s for reseller %s (%s).", member.Name, reseller.Name, reseller.ReferralCode)
		return
	}

	// 6. Create Commission (using reseller's referral code as the tracking key)
	comm, err := h.Queries.CreateCommission(ctx, db.CreateCommissionParams{
		UserID:       uuid.NullUUID{UUID: memberID, Valid: true},
		ProductID:    uuid.NullUUID{Valid: false}, // Null because it's a registration referral
		Amount:       commissionAmount,
		Status:       "PENDING",
		UserType:     "MEMBER",
		ReferralCode: sql.NullString{String: reseller.ReferralCode, Valid: true},
	})
	if err != nil {
		log.Printf("[ReferralCommission] Failed to create commission: %v", err)
		return
	}

	log.Printf("[ReferralCommission] Successfully credited Rp %d commission to member %s for referring reseller %s", commissionAmount, member.Name, reseller.Name)

	// 7. Send notification to member/leader
	if h.Notification != nil {
		h.Notification.NotifyUser(ctx, memberID, "MEMBER",
			"Komisi Referral Baru!",
			fmt.Sprintf("Reseller %s telah aktif! Anda mendapatkan komisi pendaftaran sebesar Rp %d.", reseller.Name, comm.Amount),
			map[string]string{
				"type":          "commission",
				"amount":        fmt.Sprintf("%d", comm.Amount),
				"referral_type": "reseller_signup",
				"reseller_name": reseller.Name,
			})
	}
}
