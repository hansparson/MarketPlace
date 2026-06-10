package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"github.com/user/marketplace-backend/internal/database/db"
	"github.com/user/marketplace-backend/internal/notification"
)

func main() {
	log.Println("Starting notification test script...")

	// 1. Load environment variables
	appEnv := os.Getenv("APP_ENV")
	if appEnv == "" {
		appEnv = "development"
	}

	// Look for .env file in parent directories
	cwd, _ := os.Getwd()
	envPath := filepath.Join(cwd, fmt.Sprintf(".env.%s", appEnv))
	if _, err := os.Stat(envPath); os.IsNotExist(err) {
		envPath = filepath.Join(cwd, "..", fmt.Sprintf(".env.%s", appEnv))
		if _, err := os.Stat(envPath); os.IsNotExist(err) {
			envPath = filepath.Join(cwd, "..", "..", fmt.Sprintf(".env.%s", appEnv))
		}
	}

	if err := godotenv.Load(envPath); err == nil {
		log.Printf("Loaded environment from: %s", envPath)
	} else {
		log.Println("No .env file found, using system environment variables")
	}

	// 2. Connect to database
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
	if dbHost == "" || dbHost == "postgres" {
		// When running from host machine, database is mapped on localhost
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPass, dbName)

	log.Printf("Connecting to database at %s:%s...", dbHost, dbPort)
	database, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer database.Close()

	if err := database.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("Successfully connected to database!")

	// 3. Initialize Queries
	queries := db.New(database)

	// 4. Resolve Firebase credentials paths
	// When running from backend/ folder or project root
	idCredPath := "configs/firebase-gostar-id.json"
	martCredPath := "configs/firebase-gostar-mart.json"

	if _, err := os.Stat(idCredPath); os.IsNotExist(err) {
		idCredPath = filepath.Join(cwd, "backend", "configs", "firebase-gostar-id.json")
		martCredPath = filepath.Join(cwd, "backend", "configs", "firebase-gostar-mart.json")
	}

	log.Printf("Using credentials: ID: %q | Mart: %q", idCredPath, martCredPath)

	// 5. Initialize Notification Service
	notifService, err := notification.NewService(queries, idCredPath, martCredPath)
	if err != nil {
		log.Fatalf("Failed to initialize notification service: %v", err)
	}

	// 6. Send Test Notifications for "New Product"
	ctx := context.Background()
	testProductTitle := "Sepatu Sneakers Premium X"
	dummyProductID := "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"

	log.Println("Dispatching push notifications to GostarID apps (MEMBER, RESELLER)...")
	notifService.BroadcastToRoles(ctx, []string{"MEMBER", "RESELLER"},
		"Produk Baru Ditambahkan!",
		fmt.Sprintf("Katalog baru '%s' telah tersedia. Yuk bagikan sekarang dan dapatkan komisinya!", testProductTitle),
		map[string]string{
			"type":       "new_product",
			"product_id": dummyProductID,
		},
	)

	log.Println("Dispatching push notifications to Gostar-Mart apps (CLIENT)...")
	notifService.BroadcastToRoles(ctx, []string{"CLIENT"},
		"Produk Baru untuk Anda!",
		fmt.Sprintf("'%s' kini tersedia di toko. Lihat sekarang!", testProductTitle),
		map[string]string{
			"type":       "new_product",
			"product_id": dummyProductID,
		},
	)

	log.Println("Notification dispatch complete!")
}
