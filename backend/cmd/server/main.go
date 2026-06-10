// @title Marketplace API
// @version 1.0
// @description API untuk sistem marketplace dengan fitur reseller, tracking, dan komisi
// @description
// @description ## Fitur Utama:
// @description - Manajemen produk (CRUD)
// @description - Sistem reseller dengan kode referral
// @description - Tracking click dan leads
// @description - Perhitungan komisi otomatis
// @description - Manajemen payout
// @description - Upload file ke MinIO
// @description
// @description ## Authentication:
// @description Login sebagai Admin atau Reseller untuk mendapatkan JWT token, kemudian gunakan token tersebut di header `Authorization: Bearer <token>`

// @contact.name API Support
// @contact.email support@marketplace.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"time"

	"github.com/rs/zerolog"
	echoSwagger "github.com/swaggo/echo-swagger"

	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	_ "github.com/lib/pq"
	"github.com/user/marketplace-backend/internal/cache"
	"github.com/user/marketplace-backend/internal/config"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/handler"
	appMiddleware "github.com/user/marketplace-backend/internal/middleware"
	"github.com/user/marketplace-backend/internal/notification"
	"github.com/user/marketplace-backend/internal/storage"
	"github.com/user/marketplace-backend/pkg/apperrors"
	"github.com/user/marketplace-backend/pkg/dana"

	_ "github.com/user/marketplace-backend/docs" // Import generated docs
)

func main() {
	// Auto-detect environment and load appropriate .env file
	// Priority: APP_ENV env var → fallback to "development"
	// In Docker production, vars are injected directly (no file needed)
	appEnv := os.Getenv("APP_ENV")
	if appEnv == "" {
		appEnv = "development"
	}

	envFiles := []string{
		fmt.Sprintf("../.env.%s", appEnv),    // dari backend/ → project root ✅
		fmt.Sprintf("../../.env.%s", appEnv), // dari cmd/server/ → project root
		fmt.Sprintf(".env.%s", appEnv),        // current dir fallback
		"../.env",                             // dari backend/ → root .env
		".env",                                // final fallback
	}
	loaded := false
	for _, f := range envFiles {
		if err := godotenv.Load(f); err == nil {
			log.Printf("Loaded environment from: %s (APP_ENV=%s)", f, appEnv)
			loaded = true
			break
		}
	}
	if !loaded {
		log.Printf("No .env file found, relying on system environment variables (APP_ENV=%s)", appEnv)
	}

	// Database connection string
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "app_user"
	}
	dbPass := os.Getenv("DB_PASSWORD")
	if dbPass == "" {
		dbPass = "app_password"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "app_db"
	}
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "postgres"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPass, dbName)

	database, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	defer database.Close()

	if err := database.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("Successfully connected to database")

	// Naive Migration Runner for MVP
	var tableCount int
	err = database.QueryRow("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'users'").Scan(&tableCount)
	if err == nil && tableCount == 0 {
		log.Println("Database appears empty. Running initial migration...")
		migrationSQL, err := os.ReadFile("internal/database/migrations/00001_initial_schema.sql")
		if err == nil {
			database.Exec(string(migrationSQL))
		}
	}

	// Check if location columns exist
	var columnCount int
	err = database.QueryRow("SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'location_name'").Scan(&columnCount)
	if err == nil && columnCount == 0 {
		log.Println("Applying product location migration...")
		migrationSQL, err := os.ReadFile("internal/database/migrations/00004_add_product_location.sql")
		if err == nil {
			database.Exec(string(migrationSQL))
		}
	}

	// Setup Zerolog
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	logger := zerolog.New(os.Stdout).With().
		Timestamp().
		Str("service", "marketplace-api").
		Logger()

	// Echo instance
	e := echo.New()

	// Middleware
	e.Use(middleware.RequestIDWithConfig(middleware.RequestIDConfig{
		Generator: func() string {
			return fmt.Sprintf("API_CALL_%d", time.Now().UTC().UnixMicro())
		},
	}))
	e.Use(appMiddleware.ZerologMiddleware(logger)) // Use custom zerolog middleware
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			fmt.Printf("REQUEST: %s %s\n", c.Request().Method, c.Request().RequestURI)
			return next(c)
		}
	})

	// Custom Error Handler
	e.HTTPErrorHandler = func(err error, c echo.Context) {
		appErr := apperrors.FromError(err)
		c.JSON(appErr.Code, map[string]interface{}{
			"api_call_id":    c.Response().Header().Get(echo.HeaderXRequestID),
			"message_action": appErr.Action,
			"message_data":   appErr.Message,
		})
	}

	// Initialize Storage
	log.Println("Initializing MinIO storage...")
	minioStorage, err := storage.NewMinioStorage()
	if err != nil {
		log.Printf("WARNING: Failed to initialize MinIO storage: %v", err)
		log.Println("Continuing without MinIO - file uploads will not work!")
		minioStorage = nil // Set to nil explicitly
	} else {
		log.Println("MinIO storage initialized successfully")
	}

	// Initialize Queries (assuming sqlc generate has been run)
	queries := db.New(database)

	// Load configuration
	appConfig := config.LoadConfig()

	// Initialize DANA client if credentials are configured
	var danaClient *dana.Client
	if appConfig.DanaMerchantID != "" && appConfig.DanaMerchantID != "YOUR_DANA_MERCHANT_ID" {
		log.Println("Initializing DANA API client...")
		var danaErr error
		danaClient, danaErr = dana.NewClient(appConfig)
		if danaErr != nil {
			log.Printf("WARNING: Failed to initialize DANA Client: %v", danaErr)
		} else {
			log.Println("DANA Client initialized successfully")
		}
	} else {
		log.Println("DANA credentials not found in env or set to placeholder, running DANA integration in mock/test mode.")
	}

	// Initialize Redis Cache
	redisCache := cache.NewCache()

	// Initialize Notification Service
	fcmIDPath := os.Getenv("FIREBASE_CREDENTIALS_PATH_ID")
	if fcmIDPath == "" {
		fcmIDPath = "configs/firebase-gostar-id.json"
	}
	fcmMartPath := os.Getenv("FIREBASE_CREDENTIALS_PATH_MART")
	if fcmMartPath == "" {
		fcmMartPath = "configs/firebase-gostar-mart.json"
	}
	notificationService, err := notification.NewService(queries, fcmIDPath, fcmMartPath)
	if err != nil {
		log.Printf("WARNING: Failed to initialize Notification Service: %v", err)
	}

	// Initialize Handlers
	authHandler := handler.NewAuthHandler(queries, database)
	adminHandler := handler.NewAdminHandler(queries, minioStorage, database, danaClient, notificationService)
	clientHandler := handler.NewClientHandler(queries, danaClient, notificationService)
	publicHandler := handler.NewPublicHandler(queries, minioStorage, redisCache, danaClient, notificationService)
	martClientHandler := handler.NewMartClientHandler(queries)
	ogHandler := handler.NewOGHandler(queries)
	deviceTokenHandler := handler.NewDeviceTokenHandler(queries)

	// Routes
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Welcome to Marketplace API with Echo!")
	})

	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "up"})
	})

	// Swagger documentation
	e.GET("/swagger/*", echoSwagger.WrapHandler)

	// Serve static files from docs folder (for /docs/index.html)
	e.Static("/docs", "docs")

	// API Routes Group
	api := e.Group("/api")

	// Public Routes
	api.GET("/categories", publicHandler.ListCategories)
	api.GET("/public/configs", publicHandler.GetPublicConfigs)
	api.GET("/leaderboard", publicHandler.GetLeaderboard)
	api.GET("/products", publicHandler.ListProducts)
	api.GET("/products/:id", publicHandler.GetProduct)
	api.GET("/track/click", clientHandler.TrackClick)
	api.POST("/leads", clientHandler.SubmitLead)
	api.POST("/public/dana/payment-callback", publicHandler.DanaPaymentCallback)
	api.POST("/public/simulate-payment/:invoiceNumber", publicHandler.SimulatePayment)

	// Open Graph Route (for social media crawlers)
	api.GET("/og/product/:id", ogHandler.GetProductOG)

	// Location API
	api.GET("/provinces", publicHandler.GetProvinces)
	api.GET("/regencies/:code", publicHandler.GetRegencies)
	api.GET("/districts/:code", publicHandler.GetDistricts)
	api.GET("/villages/:code", publicHandler.GetVillages)

	// Mart Client Routes
	api.POST("/mart-client/login/google", martClientHandler.LoginGoogle)
	api.PUT("/mart-client/profile", martClientHandler.CompleteProfile)
	api.POST("/mart-client/favorites/toggle", martClientHandler.ToggleFavorite)
	api.GET("/mart-client/favorites", martClientHandler.ListFavorites)
	api.POST("/mart-client/device-token", deviceTokenHandler.UpsertMartDeviceToken)
	api.DELETE("/mart-client/device-token", deviceTokenHandler.DeleteMartDeviceToken)

	// Auth Routes
	auth := api.Group("/auth")
	auth.POST("/login/admin", authHandler.AdminLogin)
	auth.POST("/login/reseller", authHandler.ResellerLogin)
	auth.POST("/login/member", authHandler.MemberLogin)
	auth.POST("/register/member", publicHandler.RegisterMember)
	auth.POST("/register/reseller", publicHandler.RegisterReseller)
	auth.GET("/verify-referral/:code", publicHandler.VerifyReferralCode)
	auth.GET("/verify-dana-phone/:phone", publicHandler.VerifyDanaPhone)
	auth.GET("/registration-status/:userId", publicHandler.GetRegistrationStatus)

	// Admin Routes (Protected)
	adminGroup := api.Group("/admin")
	adminGroup.Use(appMiddleware.JWTMiddleware)
	adminGroup.Use(appMiddleware.RoleMiddleware("SUPER_ADMIN", "ADMIN"))

	adminGroup.POST("/products", adminHandler.CreateProduct)
	adminGroup.POST("/products/assets", adminHandler.UploadAsset)
	adminGroup.DELETE("/products/assets/:id", adminHandler.DeleteAsset)
	adminGroup.GET("/dashboard", adminHandler.GetDashboard)
	adminGroup.GET("/configs", adminHandler.ListSystemConfigs)
	adminGroup.PUT("/configs", adminHandler.UpdateSystemConfigs)
	adminGroup.POST("/resellers", adminHandler.CreateReseller)
	adminGroup.GET("/resellers", adminHandler.ListResellers)
	adminGroup.GET("/resellers/:id", adminHandler.GetReseller)
	adminGroup.PUT("/resellers/:id", adminHandler.UpdateReseller)
	adminGroup.POST("/members", adminHandler.CreateMember)
	adminGroup.GET("/members", adminHandler.ListMembers)
	adminGroup.GET("/members/:id", adminHandler.GetMember)
	adminGroup.PUT("/members/:id", adminHandler.UpdateMember)
	adminGroup.GET("/members/:id/resellers", adminHandler.ListMemberResellers)
	adminGroup.GET("/products", adminHandler.ListAllProducts)
	adminGroup.GET("/products/:id", adminHandler.GetProduct)
	adminGroup.PUT("/products/:id", adminHandler.UpdateProduct)
	adminGroup.DELETE("/products/:id", adminHandler.DeleteProduct)
	adminGroup.GET("/products/:id/leads", adminHandler.GetProductLeads)
	adminGroup.GET("/mart-clients", adminHandler.ListMartClients)
	adminGroup.POST("/products/:id/sold", adminHandler.MarkProductSold)
	adminGroup.POST("/payouts", adminHandler.CreatePayout)
	adminGroup.GET("/payouts", adminHandler.ListPayouts)

	// Client/Reseller Routes (Protected)
	clientGroup := api.Group("/client")
	clientGroup.Use(appMiddleware.JWTMiddleware)
	clientGroup.Use(appMiddleware.RoleMiddleware("RESELLER", "MEMBER", "CLIENT"))

	clientGroup.GET("/products/:id/share", clientHandler.GetShareURL)
	clientGroup.GET("/products/:id/analytics", clientHandler.GetMyAnalytics)
	clientGroup.GET("/stats", clientHandler.GetStats)
	clientGroup.GET("/payouts", clientHandler.GetMyPayouts)
	clientGroup.GET("/commissions", clientHandler.GetMyCommissions)
	clientGroup.POST("/track-share", clientHandler.TrackShare)
	clientGroup.GET("/profile", clientHandler.GetProfile)
	clientGroup.PUT("/profile", clientHandler.UpdateProfile)
	clientGroup.POST("/verify-phone", clientHandler.VerifyPhone)
	clientGroup.POST("/withdraw", clientHandler.RequestWithdrawal)
	clientGroup.POST("/device-token", deviceTokenHandler.UpsertDeviceToken)
	clientGroup.DELETE("/device-token", deviceTokenHandler.DeleteDeviceToken)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	if err := e.Start(":" + port); err != nil {
		e.Logger.Fatal(err)
	}
}
