# SQLC Code Generation Script for Windows PowerShell
# Usage: .\generate.ps1

Write-Host "SQLC Code Generator" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

$GOPATH = if ($env:GOPATH) { $env:GOPATH } else { "$env:USERPROFILE\go" }
$SQLC = "$GOPATH\bin\sqlc.exe"

# Check if sqlc is installed
if (-not (Test-Path $SQLC)) {
    Write-Host "SQLC not found. Installing..." -ForegroundColor Yellow
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install sqlc!" -ForegroundColor Red
        exit 1
    }
    Write-Host "SQLC installed successfully!" -ForegroundColor Green
    Write-Host ""
}

# Generate code
Write-Host "Generating Go code from SQL queries..." -ForegroundColor Yellow
& $SQLC generate

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Code generation completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Code generation failed!" -ForegroundColor Red
    exit 1
}
