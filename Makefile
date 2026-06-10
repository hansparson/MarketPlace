# ╔══════════════════════════════════════════════════════════════════╗
# ║              GostarID Marketplace — Root Makefile               ║
# ║  Development : make dev          (infra Docker + backend lokal) ║
# ║  Production  : make prod-up      (full Docker stack)            ║
# ╚══════════════════════════════════════════════════════════════════╝

.PHONY: help dev infra-up infra-down backend-run frontend-run \
        prod-up prod-down prod-build prod-logs prod-ps \
        migrate-up migrate-down db-shell flutter-dev flutter-prod

# ─── Default ──────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  ╔══════════════════════════════════════════╗"
	@echo "  ║         GostarID Makefile Commands        ║"
	@echo "  ╚══════════════════════════════════════════╝"
	@echo ""
	@echo "  DEVELOPMENT (local):"
	@echo "    make dev           Start infra + backend + frontend locally"
	@echo "    make infra-up      Start only PostgreSQL, Redis, MinIO (Docker)"
	@echo "    make infra-down    Stop infrastructure containers"
	@echo "    make backend-run   Run backend locally (go run)"
	@echo "    make frontend-run  Run frontend locally (npm run dev)"
	@echo ""
	@echo "  PRODUCTION (Docker):"
	@echo "    make prod-up       Build & start full stack in Docker"
	@echo "    make prod-down     Stop all production containers"
	@echo "    make prod-build    Rebuild Docker images without starting"
	@echo "    make prod-logs     Tail logs from all containers"
	@echo "    make prod-ps       Show status of all containers"
	@echo ""
	@echo "  DATABASE:"
	@echo "    make migrate-up    Run database migrations"
	@echo "    make migrate-down  Rollback last migration"
	@echo "    make db-shell      Open psql shell"
	@echo ""
	@echo "  FLUTTER:"
	@echo "    make flutter-dev   Run Flutter app (development)"
	@echo "    make flutter-prod  Run Flutter app (production API)"
	@echo ""

# ─── Development ──────────────────────────────────────────────────────────────

## Start infrastructure (Postgres, Redis, MinIO) only
infra-up:
	@echo "🐳 Starting infrastructure services (dev)..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ Infra ready:"
	@echo "   PostgreSQL → localhost:5432"
	@echo "   Redis      → localhost:6379"
	@echo "   MinIO      → localhost:9000  (Console: localhost:9001)"

## Stop infrastructure
infra-down:
	@echo "🛑 Stopping infrastructure..."
	docker-compose -f docker-compose.dev.yml down

## Run backend locally
backend-run:
	@echo "🚀 Starting backend (development)..."
	cd backend && APP_ENV=development go run cmd/server/main.go

## Run frontend locally
frontend-run:
	@echo "🌐 Starting frontend (development)..."
	cd frontend && npm run dev

## Full local dev: infra up + backend + frontend in parallel
dev: infra-up
	@echo "✅ Infrastructure is up. Now start in separate terminals:"
	@echo "   Terminal 2: make backend-run"
	@echo "   Terminal 3: make frontend-run"

# ─── Production ───────────────────────────────────────────────────────────────

## Build & start full production stack
prod-up:
	@echo "🚀 Starting production stack..."
	@test -f .env.production || (echo "❌ .env.production not found! Copy from .env.example and fill in values." && exit 1)
	docker-compose --env-file .env.production up -d --build
	@echo "✅ Production stack is running!"
	@make prod-ps

## Stop production stack
prod-down:
	docker-compose --env-file .env.production down

## Build images only (no start)
prod-build:
	@echo "🔨 Building Docker images..."
	docker-compose --env-file .env.production build

## Tail logs
prod-logs:
	docker-compose --env-file .env.production logs -f

## Show container status
prod-ps:
	docker-compose --env-file .env.production ps

# ─── Database ─────────────────────────────────────────────────────────────────
DB_URL_DEV := "postgres://app_user:app_password@localhost:5432/app_db?sslmode=disable"

migrate-up:
	@echo "🗄  Running migrations..."
	cd backend && goose -dir internal/database/migrations postgres $(DB_URL_DEV) up
	@echo "✅ Migrations done!"

migrate-down:
	@echo "⏪ Rolling back last migration..."
	cd backend && goose -dir internal/database/migrations postgres $(DB_URL_DEV) down

db-shell:
	docker exec -it gostar_postgres_dev psql -U app_user -d app_db

# ─── Flutter ──────────────────────────────────────────────────────────────────

## Run Flutter app pointing to local backend
flutter-dev:
	@echo "📱 Running Flutter app (DEVELOPMENT)..."
	cd gostar-id && flutter run

## Run Flutter app pointing to production API
flutter-prod:
	@echo "📱 Running Flutter app (PRODUCTION)..."
	cd gostar-id && flutter run --dart-define=PRODUCTION=true

## Build production APK
flutter-build-prod:
	@echo "📦 Building production APK..."
	cd gostar-id && flutter build apk --dart-define=PRODUCTION=true --release
	@echo "✅ APK: gostar-id/build/app/outputs/flutter-apk/app-release.apk"
