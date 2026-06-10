package notification

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"github.com/user/marketplace-backend/internal/database/db"
	"google.golang.org/api/option"
)

type Service struct {
	queries     db.Querier
	idClient    *messaging.Client // GostarID client
	martClient  *messaging.Client // Gostar-Mart client
	idEnabled   bool
	martEnabled bool
}

func NewService(q db.Querier, idCredentialsPath string, martCredentialsPath string) (*Service, error) {
	s := &Service{queries: q}

	// 1. Initialize GostarID FCM client
	if idCredentialsPath == "" {
		log.Println("Firebase GostarID credentials path is empty. GostarID notifications will run in mock mode.")
	} else if _, err := os.Stat(idCredentialsPath); os.IsNotExist(err) {
		log.Printf("Firebase GostarID credentials file %s not found. GostarID notifications will run in mock mode.", idCredentialsPath)
	} else {
		opt := option.WithCredentialsFile(idCredentialsPath)
		app, err := firebase.NewApp(context.Background(), nil, opt)
		if err != nil {
			return nil, fmt.Errorf("error initializing firebase app for GostarID: %v", err)
		}
		client, err := app.Messaging(context.Background())
		if err != nil {
			return nil, fmt.Errorf("error getting firebase messaging client for GostarID: %v", err)
		}
		s.idClient = client
		s.idEnabled = true
		log.Println("Firebase Cloud Messaging (FCM) GostarID client initialized successfully.")
	}

	// 2. Initialize Gostar-Mart FCM client
	if martCredentialsPath == "" {
		log.Println("Firebase Gostar-Mart credentials path is empty. Gostar-Mart notifications will run in mock mode.")
	} else if _, err := os.Stat(martCredentialsPath); os.IsNotExist(err) {
		log.Printf("Firebase Gostar-Mart credentials file %s not found. Gostar-Mart notifications will run in mock mode.", martCredentialsPath)
	} else {
		opt := option.WithCredentialsFile(martCredentialsPath)
		app, err := firebase.NewApp(context.Background(), nil, opt)
		if err != nil {
			return nil, fmt.Errorf("error initializing firebase app for Gostar-Mart: %v", err)
		}
		client, err := app.Messaging(context.Background())
		if err != nil {
			return nil, fmt.Errorf("error getting firebase messaging client for Gostar-Mart: %v", err)
		}
		s.martClient = client
		s.martEnabled = true
		log.Println("Firebase Cloud Messaging (FCM) Gostar-Mart client initialized successfully.")
	}

	return s, nil
}

// NotifyUser sends a targeted notification to all registered device tokens of a specific user with a specific role
func (s *Service) NotifyUser(ctx context.Context, userID uuid.UUID, role string, title, body string, data map[string]string) {
	tokens, err := s.queries.GetDeviceTokensByUserIdAndRole(ctx, db.GetDeviceTokensByUserIdAndRoleParams{
		UserID: userID,
		Role:   role,
	})
	if err != nil {
		log.Printf("[Notification] Failed to get device tokens for user %s (%s): %v", userID, role, err)
		return
	}

	if len(tokens) == 0 {
		log.Printf("[Notification] No registered device tokens found for user %s (%s)", userID, role)
		return
	}

	var tokenStrings []string
	for _, t := range tokens {
		tokenStrings = append(tokenStrings, t.Token)
	}

	s.sendToTokens(ctx, tokenStrings, role, title, body, data)
}

// BroadcastToRoles sends a notification to all active device tokens belonging to any of the specified roles
func (s *Service) BroadcastToRoles(ctx context.Context, roles []string, title, body string, data map[string]string) {
	tokens, err := s.queries.GetDeviceTokensByRoles(ctx, roles)
	if err != nil {
		log.Printf("[Notification] Failed to get device tokens for roles %v: %v", roles, err)
		return
	}

	if len(tokens) == 0 {
		log.Printf("[Notification] No registered device tokens found for roles %v", roles)
		return
	}

	// Partition tokens by project/role
	idTokens := []string{}
	martTokens := []string{}

	for _, t := range tokens {
		if t.Role == "CLIENT" {
			martTokens = append(martTokens, t.Token)
		} else {
			idTokens = append(idTokens, t.Token)
		}
	}

	if len(idTokens) > 0 {
		s.sendToTokens(ctx, idTokens, "RESELLER", title, body, data)
	}
	if len(martTokens) > 0 {
		s.sendToTokens(ctx, martTokens, "CLIENT", title, body, data)
	}
}

// sendToTokens performs the actual multicast dispatch (or logs it in mock mode)
func (s *Service) sendToTokens(ctx context.Context, tokens []string, role string, title, body string, data map[string]string) {
	var client *messaging.Client
	var enabled bool
	projectName := ""

	if role == "CLIENT" {
		client = s.martClient
		enabled = s.martEnabled
		projectName = "Gostar-Mart"
	} else {
		client = s.idClient
		enabled = s.idEnabled
		projectName = "GostarID"
	}

	if !enabled {
		log.Printf("[MOCK NOTIFICATION - %s] Sent to tokens: %v | Title: %q | Body: %q | Data: %v", projectName, tokens, title, body, data)
		return
	}

	multicastMsg := &messaging.MulticastMessage{
		Tokens: tokens,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
	}

	br, err := client.SendEachForMulticast(ctx, multicastMsg)
	if err != nil {
		log.Printf("[Notification - %s] Failed to send multicast notification: %v", projectName, err)
		return
	}

	log.Printf("[Notification - %s] FCM multicast completed: %d success, %d failure", projectName, br.SuccessCount, br.FailureCount)
}
