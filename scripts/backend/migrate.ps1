# Database Migration Script for Windows PowerShell
# Usage: .\migrate.ps1 up|down|reset|status

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("up", "down", "reset", "status")]
    [string]$Action
)

$DB_URL = "postgres://app_user:app_password@localhost:5432/app_db?sslmode=disable"
$MIGRATION_DIR = "internal/database/migrations"
$GOPATH = if ($env:GOPATH) { $env:GOPATH } else { "$env:USERPROFILE\go" }
$GOOSE = "$GOPATH\bin\goose.exe"

Write-Host "Database Migration Tool" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# Check if goose is installed
if (-not (Test-Path $GOOSE)) {
    Write-Host "Goose not found. Installing..." -ForegroundColor Yellow
    go install github.com/pressly/goose/v3/cmd/goose@latest
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install goose!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Goose installed successfully!" -ForegroundColor Green
}

# Execute migration
Write-Host "Running: goose $Action" -ForegroundColor Yellow
& $GOOSE -dir $MIGRATION_DIR postgres $DB_URL $Action

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Migration $Action completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Migration $Action failed!" -ForegroundColor Red
    exit 1
}
