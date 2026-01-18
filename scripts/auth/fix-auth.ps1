Write-Host "Fixing authentication issue..." -ForegroundColor Cyan
Write-Host ""

# Get current admin ID
$adminId = docker exec postgres psql -U app_user -d app_db -t -c "SELECT id FROM admins LIMIT 1;" 2>$null | ForEach-Object { $_.Trim() }

if ($adminId) {
    Write-Host "✓ Database is ready" -ForegroundColor Green
    Write-Host "✓ Current Admin ID in database: $adminId" -ForegroundColor Green
}
else {
    Write-Host "✗ No admin found in database!" -ForegroundColor Red
    Write-Host "Running migration..." -ForegroundColor Yellow
    cd backend
    .\migrate.ps1 up
    cd ..
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PLEASE FOLLOW THESE STEPS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open your browser (where you're logged in)" -ForegroundColor Yellow
Write-Host "2. Press F12 to open DevTools" -ForegroundColor Yellow
Write-Host "3. Go to 'Console' tab" -ForegroundColor Yellow
Write-Host "4. Type this command and press Enter:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   localStorage.clear()" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "5. Close DevTools" -ForegroundColor Yellow
Write-Host "6. Go to: http://localhost:3000/auth/login/admin" -ForegroundColor Yellow
Write-Host "7. Login with:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Email:    admin@example.com" -ForegroundColor White
Write-Host "   Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "8. Try creating a product again" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will clear the old JWT token and get a new one with the correct Admin ID." -ForegroundColor Gray
