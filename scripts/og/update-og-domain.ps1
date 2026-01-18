# Script untuk Update Domain di OG Handler
# Jalankan script ini setelah deploy atau jika domain berubah

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Update Domain untuk Open Graph" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$currentDomain = "https://gostar-mart.online"
Write-Host "Domain saat ini: $currentDomain" -ForegroundColor Yellow
Write-Host ""

$newDomain = Read-Host "Masukkan domain baru (tekan Enter untuk skip)"

if ($newDomain -ne "") {
    Write-Host ""
    Write-Host "Mengupdate domain..." -ForegroundColor Green
    
    # Update di og_handler.go
    $ogHandlerPath = "backend\internal\handler\og_handler.go"
    if (Test-Path $ogHandlerPath) {
        $content = Get-Content $ogHandlerPath -Raw
        $content = $content -replace 'gostar-mart\.online', $newDomain.Replace('https://', '').Replace('http://', '')
        Set-Content $ogHandlerPath $content
        Write-Host "✓ Updated $ogHandlerPath" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Domain berhasil diupdate ke: $newDomain" -ForegroundColor Green
    Write-Host "Silakan rebuild backend dengan: docker-compose up -d --build backend" -ForegroundColor Yellow
}
else {
    Write-Host "Tidak ada perubahan domain." -ForegroundColor Gray
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Cara Test Open Graph Tags:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Facebook Debugger:" -ForegroundColor Yellow
Write-Host "   https://developers.facebook.com/tools/debug/" -ForegroundColor White
Write-Host ""
Write-Host "2. Twitter Card Validator:" -ForegroundColor Yellow
Write-Host "   https://cards-dev.twitter.com/validator" -ForegroundColor White
Write-Host ""
Write-Host "3. LinkedIn Post Inspector:" -ForegroundColor Yellow
Write-Host "   https://www.linkedin.com/post-inspector/" -ForegroundColor White
Write-Host ""
Write-Host "4. Test URL langsung:" -ForegroundColor Yellow
Write-Host "   $currentDomain/api/og/product/PRODUCT_ID" -ForegroundColor White
Write-Host ""
Write-Host "5. WhatsApp:" -ForegroundColor Yellow
Write-Host "   Kirim link produk ke WhatsApp dan tunggu preview muncul" -ForegroundColor White
Write-Host "   Jika preview lama tidak berubah, tambahkan ?v=1 di akhir URL" -ForegroundColor Gray
Write-Host ""
