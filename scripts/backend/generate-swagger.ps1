# Swagger Documentation Generator Script
# Generates Swagger docs from code comments

Write-Host "Generating Swagger documentation..." -ForegroundColor Green

# Add GOPATH to PATH
$env:Path += ";$env:GOPATH\bin"

# Check if swag is installed
if (!(Get-Command swag -ErrorAction SilentlyContinue)) {
    Write-Host "Swag CLI not found. Installing..." -ForegroundColor Yellow
    go install github.com/swaggo/swag/cmd/swag@latest
}

# Generate swagger docs
Write-Host "Running swag init..." -ForegroundColor Cyan
swag init -g cmd/server/main.go -o docs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Swagger documentation generated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Generated files:" -ForegroundColor Cyan
    Write-Host "  - docs/docs.go" -ForegroundColor White
    Write-Host "  - docs/swagger.json" -ForegroundColor White
    Write-Host "  - docs/swagger.yaml" -ForegroundColor White
    Write-Host ""
    Write-Host "To view the documentation:" -ForegroundColor Cyan
    Write-Host "  1. Start the server: go run cmd/server/main.go" -ForegroundColor White
    Write-Host "  2. Open browser: http://localhost:8080/swagger/index.html" -ForegroundColor White
} else {
    Write-Host "✗ Failed to generate Swagger documentation" -ForegroundColor Red
    exit 1
}
