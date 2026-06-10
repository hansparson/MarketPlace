package dana

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	danasdk "github.com/dana-id/dana-go/v2"
	danaconfig "github.com/dana-id/dana-go/v2/config"
	danadisbursement "github.com/dana-id/dana-go/v2/disbursement/v1"
	danapg "github.com/dana-id/dana-go/v2/payment_gateway/v1"
	danawebhook "github.com/dana-id/dana-go/v2/webhook"
	"github.com/user/marketplace-backend/internal/config"
)

type Client struct {
	sdkClient     *danasdk.APIClient
	webhookParser *danawebhook.WebhookParser
	merchantID    string
}

func NewClient(cfg *config.Config) (*Client, error) {
	sdkConfig := danaconfig.NewConfiguration()

	env := danaconfig.ENV_SANDBOX
	if cfg.DanaEnv == "PRODUCTION" {
		env = danaconfig.ENV_PRODUCTION
	}

	privateKey := strings.ReplaceAll(cfg.DanaPrivateKey, "\\n", "\n")
	publicKey := strings.ReplaceAll(cfg.DanaPublicKey, "\\n", "\n")

	sdkConfig.APIKey = &danaconfig.APIKey{
		ENV:           env,
		X_PARTNER_ID:  cfg.DanaXPartnerID,
		CHANNEL_ID:    cfg.DanaChannelID,
		PRIVATE_KEY:   privateKey,
		ORIGIN:        cfg.DanaOrigin,
		CLIENT_ID:     cfg.DanaClientID,
		CLIENT_SECRET: cfg.DanaClientSecret,
	}

	sdkClient := danasdk.NewAPIClient(sdkConfig)

	var parser *danawebhook.WebhookParser
	if publicKey != "" {
		p, err := danawebhook.NewWebhookParser(&publicKey, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to create webhook parser: %w", err)
		}
		parser = p
	}

	return &Client{
		sdkClient:     sdkClient,
		webhookParser: parser,
		merchantID:    cfg.DanaMerchantID,
	}, nil
}

// CreatePaymentOrder initiates a DANA SNAP CreateOrder request
func (c *Client) CreatePaymentOrder(ctx context.Context, invoiceNo string, amount int64, title string, notifyURL string) (string, error) {
	amtStr := fmt.Sprintf("%.2f", float64(amount))

	// Generate expiration time: default to 15 minutes from now in local WIB/GMT+7
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*60*60)
	}
	validUpTo := time.Now().In(loc).Add(15 * time.Minute).Format("2006-01-02T15:04:05+07:00")

	// Prepare CreateOrderRequest
	createOrderByApiRequest := &danapg.CreateOrderByApiRequest{
		PartnerReferenceNo: invoiceNo,
		MerchantId:         c.merchantID,
		Amount: danapg.Money{
			Value:    amtStr,
			Currency: "IDR",
		},
		UrlParams: []danapg.UrlParam{
			{
				Url:        notifyURL,
				Type:       "NOTIFICATION",
				IsDeeplink: "Y",
			},
			{
				Url:        c.sdkClient.GetConfig().APIKey.ORIGIN + "/payment/status?invoice=" + invoiceNo,
				Type:       "PAY_RETURN",
				IsDeeplink: "Y",
			},
		},
		ValidUpTo: validUpTo,
		AdditionalInfo: &danapg.CreateOrderByApiAdditionalInfo{
			Mcc: "5732",
			EnvInfo: danapg.EnvInfo{
				SourcePlatform: "IPG",
				TerminalType:   "SYSTEM",
			},
			Order: &danapg.OrderApiObject{
				OrderTitle: title,
			},
		},
		PayOptionDetails: []danapg.PayOptionDetail{
			{
				PayMethod: "BALANCE",
				PayOption: "",
				TransAmount: danapg.Money{
					Value:    amtStr,
					Currency: "IDR",
				},
			},
		},
	}

	req := danapg.CreateOrderRequest{
		CreateOrderByApiRequest: createOrderByApiRequest,
	}

	apiResponse, httpResponse, err := c.sdkClient.PaymentGatewayAPI.CreateOrder(ctx).CreateOrderRequest(req).Execute()
	if err != nil {
		bodyStr := ""
		if httpResponse != nil && httpResponse.Body != nil {
			if b, readErr := io.ReadAll(httpResponse.Body); readErr == nil {
				bodyStr = string(b)
			}
		}
		return "", fmt.Errorf("DANA pg API error: %v, body: %s", err, bodyStr)
	}
	defer httpResponse.Body.Close()

	// Parse webRedirectUrl directly from HTTP response body
	var respMap map[string]interface{}
	bodyBytes, err := io.ReadAll(httpResponse.Body)
	if err == nil {
		_ = json.Unmarshal(bodyBytes, &respMap)
		if url, ok := respMap["webRedirectUrl"].(string); ok {
			return url, nil
		}
	}

	// Fallback to marshalled SDK response if parsing raw body fails
	respBytes, err := apiResponse.MarshalJSON()
	if err == nil {
		var sdkMap map[string]interface{}
		_ = json.Unmarshal(respBytes, &sdkMap)
		if url, ok := sdkMap["webRedirectUrl"].(string); ok {
			return url, nil
		}
	}

	return "", fmt.Errorf("webRedirectUrl not found in DANA response")
}

// DanaAccountInquiry queries the status of a DANA account to check if it exists and is active
func (c *Client) DanaAccountInquiry(ctx context.Context, phone string) (bool, string, error) {
	if phone == "" {
		return false, "INVALID_PHONE", fmt.Errorf("phone number is empty")
	}

	phone = normalizeIndonesianPhone(phone)

	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*60*60)
	}
	nowStr := time.Now().In(loc).Format("2006-01-02T15:04:05+07:00")
	partnerRefNo := fmt.Sprintf("INQ-%d", time.Now().UnixNano())

	req := danadisbursement.DanaAccountInquiryRequest{
		PartnerReferenceNo: &partnerRefNo,
		CustomerNumber:     &phone,
		Amount: danadisbursement.Money{
			Value:    "1.00",
			Currency: "IDR",
		},
		TransactionDate: &nowStr,
		AdditionalInfo: danadisbursement.DanaAccountInquiryRequestAdditionalInfo{
			FundType: "AGENT_TOPUP_FOR_USER_SETTLE",
		},
	}

	apiResponse, httpResponse, err := c.sdkClient.DisbursementAPI.DanaAccountInquiry(ctx).DanaAccountInquiryRequest(req).Execute()

	// If there's an error, DANA may return 400/403 with detailed code/message in body
	if err != nil {
		bodyBytes := []byte{}
		if httpResponse != nil && httpResponse.Body != nil {
			bodyBytes, _ = io.ReadAll(httpResponse.Body)
		}

		// Try parsing resultMsg from additionalInfo
		var errResp struct {
			ResponseCode    string `json:"responseCode"`
			ResponseMessage string `json:"responseMessage"`
			AdditionalInfo  struct {
				ResultMsg string `json:"resultMsg"`
			} `json:"additionalInfo"`
		}

		if len(bodyBytes) > 0 {
			if jsonErr := json.Unmarshal(bodyBytes, &errResp); jsonErr == nil {
				if errResp.AdditionalInfo.ResultMsg == "PAYEE_USER_NOT_EXIST" {
					return false, "UNREGISTERED", nil
				}
				if errResp.AdditionalInfo.ResultMsg == "PAYEE_USER_STATUS_DISABLE" {
					return false, "FROZEN", nil
				}
				return false, fmt.Sprintf("DANA_ERROR_%s_%s", errResp.ResponseCode, errResp.AdditionalInfo.ResultMsg), nil
			}
		}
		return false, "API_ERROR", fmt.Errorf("DANA inquiry call failed: %w (body: %s)", err, string(bodyBytes))
	}
	defer httpResponse.Body.Close()

	if apiResponse.ResponseCode == "2003700" {
		return true, "ACTIVE", nil
	}

	return false, fmt.Sprintf("CODE_%s_%s", apiResponse.ResponseCode, apiResponse.ResponseMessage), nil
}

// TransferToDana transfers money/commissions to a DANA account
func (c *Client) TransferToDana(ctx context.Context, partnerRefNo string, phone string, amount int64, notes string) (string, error) {
	if phone == "" {
		return "", fmt.Errorf("customer DANA phone number is empty")
	}

	phone = normalizeIndonesianPhone(phone)

	amtStr := fmt.Sprintf("%.2f", float64(amount))
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*60*60)
	}
	nowStr := time.Now().In(loc).Format("2006-01-02T15:04:05+07:00")

	// Set TransferToDanaRequest
	transferToDanaRequest := &danadisbursement.TransferToDanaRequest{
		PartnerReferenceNo: partnerRefNo,
		CustomerNumber:     &phone,
		Amount: danadisbursement.Money{
			Value:    amtStr,
			Currency: "IDR",
		},
		FeeAmount: danadisbursement.Money{
			Value:    "0.00",
			Currency: "IDR",
		},
		TransactionDate: &nowStr,
		Notes:            &notes,
		AdditionalInfo: danadisbursement.TransferToDanaRequestAdditionalInfo{
			FundType: "AGENT_TOPUP_FOR_USER_SETTLE",
		},
	}

	req := danadisbursement.TransferToDanaRequest{
		PartnerReferenceNo: transferToDanaRequest.PartnerReferenceNo,
		CustomerNumber:     transferToDanaRequest.CustomerNumber,
		Amount:             transferToDanaRequest.Amount,
		FeeAmount:          transferToDanaRequest.FeeAmount,
		TransactionDate:    transferToDanaRequest.TransactionDate,
		Notes:              transferToDanaRequest.Notes,
		AdditionalInfo:     transferToDanaRequest.AdditionalInfo,
	}

	apiResponse, httpResponse, err := c.sdkClient.DisbursementAPI.TransferToDana(ctx).TransferToDanaRequest(req).Execute()
	if err != nil {
		bodyStr := ""
		if httpResponse != nil && httpResponse.Body != nil {
			if b, readErr := io.ReadAll(httpResponse.Body); readErr == nil {
				bodyStr = string(b)
			}
		}
		return "", fmt.Errorf("DANA disbursement API error: %v, body: %s", err, bodyStr)
	}
	defer httpResponse.Body.Close()

	if apiResponse.ReferenceNo != nil {
		return *apiResponse.ReferenceNo, nil
	}

	return "", fmt.Errorf("DANA disbursement successful but referenceNo is missing")
}

// VerifyWebhook validates the incoming webhook request and parses it
func (c *Client) VerifyWebhook(method string, relativePath string, headers http.Header, body []byte) (*danawebhook.FinishNotifyRequest, error) {
	if c.webhookParser == nil {
		return nil, fmt.Errorf("webhook parser not initialized (DANA_PUBLIC_KEY missing)")
	}

	return c.webhookParser.ParseWebhook(method, relativePath, headers, string(body))
}

// QueryPaymentStatus checks the status of a payment order directly from DANA API
func (c *Client) QueryPaymentStatus(ctx context.Context, invoiceNo string) (string, string, error) {
	req := danapg.QueryPaymentRequest{
		ServiceCode: "54",
		MerchantId:  c.merchantID,
	}
	_ = req.SetOriginalPartnerReferenceNo(invoiceNo)

	apiResponse, httpResponse, err := c.sdkClient.PaymentGatewayAPI.QueryPayment(ctx).QueryPaymentRequest(req).Execute()
	if err != nil {
		bodyStr := ""
		if httpResponse != nil && httpResponse.Body != nil {
			if b, readErr := io.ReadAll(httpResponse.Body); readErr == nil {
				bodyStr = string(b)
			}
		}
		return "", "", fmt.Errorf("DANA query payment API error: %v, body: %s", err, bodyStr)
	}
	defer httpResponse.Body.Close()

	return apiResponse.GetLatestTransactionStatus(), apiResponse.GetOriginalReferenceNo(), nil
}


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
