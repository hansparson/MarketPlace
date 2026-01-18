# Database Migration & Code Generation Guide

## Prerequisites
- Go 1.19+ installed
- PostgreSQL database running (via Docker or local)
- PowerShell (for Windows) or Make (for Linux/Mac)

## Tools Used
- **Goose**: Database migration tool
- **SQLC**: SQL code generator

## Commands

### Windows (PowerShell)

#### Run Migrations
```powershell
# Run all pending migrations
.\migrate.ps1 up

# Rollback last migration
.\migrate.ps1 down

# Reset database (drop all, then re-apply)
.\migrate.ps1 reset

# Check migration status
.\migrate.ps1 status
```

#### Generate Code from SQL
```powershell
.\generate.ps1
```

### Linux/Mac (Makefile)

#### Install Tools
```bash
make dev-setup
```

#### Run Migrations
```bash
# Run all pending migrations
make migrate-up

# Rollback last migration
make migrate-down

# Reset database
make migrate-reset
```

#### Generate Code
```bash
make sqlc-generate
```

#### Other Commands
```bash
# Open PostgreSQL shell in Docker
make docker-db-shell

# Quick rebuild (generate + rebuild backend)
make quick-rebuild
```

## Database Configuration

Default connection string:
```
postgres://app_user:app_password@localhost:5432/app_db?sslmode=disable
```

To change database credentials, edit:
- **PowerShell scripts**: Update `$DB_URL` variable
- **Makefile**: Update `DB_URL` variable
- **Docker**: Update `.env` file

## Migration Files

Migration files are located in: `internal/database/migrations/`

### Naming Convention
Goose uses the following naming pattern:
```
YYYYMMDDHHMMSS_description.sql
```

Example: `00001_initial_schema.sql`

### Creating New Migration
```bash
goose -dir internal/database/migrations create migration_name sql
```

Or manually create a file with the format above.

## SQL Query Files

Query files are located in: `internal/database/queries/`

After adding or modifying `.sql` files in the queries directory, run:
```powershell
.\generate.ps1
```

This will regenerate Go code in: `internal/database/db/`

## Troubleshooting

### "Goose not found" error
The scripts will automatically install goose. If you see this error, ensure Go is properly installed and `GOPATH/bin` is in your PATH.

### Migration fails
1. Check database connection
2. Verify DATABASE_URL is correct
3. Check migration file syntax
4. View error details in console output

### SQLC generation fails
1. Ensure `sqlc.yaml` is in the backend root directory
2. Check SQL query syntax
3. Verify query file location matches sqlc.yaml config

## Default Credentials (Development)

### Admin Account
- **Email**: admin@example.com
- **Password**: admin123

### Reseller Account
- **Phone**: 081234567890
- **Password**: password123

These are created automatically by the initial migration seed data.
