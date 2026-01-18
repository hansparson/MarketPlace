.PHONY: help migrate-up migrate-down migrate-reset sqlc-generate dev-setup docker-db-shell

help:
	@echo "Available commands:"
	@echo "  make migrate-up       - Run database migrations (up)"
	@echo "  make migrate-down     - Rollback last migration"
	@echo "  make migrate-reset    - Reset database (down then up)"
	@echo "  make sqlc-generate    - Generate Go code from SQL queries"
	@echo "  make dev-setup        - Install goose and sqlc tools"
	@echo "  make docker-db-shell  - Open psql shell in postgres container"

# Database connection string
DB_URL := "postgres://app_user:app_password@localhost:5432/app_db?sslmode=disable"

# Install development tools
dev-setup:
	@echo "Installing goose..."
	go install github.com/pressly/goose/v3/cmd/goose@latest
	@echo "Installing sqlc..."
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
	@echo "Tools installed successfully!"

# Run migrations up
migrate-up:
	@echo "Running migrations..."
	cd internal/database/migrations && goose postgres $(DB_URL) up
	@echo "Migrations completed!"

# Rollback migrations
migrate-down:
	@echo "Rolling back last migration..."
	cd internal/database/migrations && goose postgres $(DB_URL) down
	@echo "Rollback completed!"

# Reset database (down all, then up)
migrate-reset:
	@echo "Resetting database..."
	cd internal/database/migrations && goose postgres $(DB_URL) reset
	cd internal/database/migrations && goose postgres $(DB_URL) up
	@echo "Database reset completed!"

# Generate Go code from SQL
sqlc-generate:
	@echo "Generating code with sqlc..."
	sqlc generate
	@echo "Code generation completed!"

# Open PostgreSQL shell in docker container
docker-db-shell:
	docker exec -it postgres psql -U app_user -d app_db

# Quick rebuild - generate sqlc and restart backend
quick-rebuild: sqlc-generate
	@echo "Rebuilding backend container..."
	docker-compose up -d --build backend
	@echo "Backend rebuilt!"
