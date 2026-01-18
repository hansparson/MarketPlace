# MinIO Setup Script for Windows
# This script creates the required bucket for the marketplace application

Write-Host "Setting up MinIO..." -ForegroundColor Cyan
Write-Host ""

# Wait for MinIO to be ready
Write-Host "Waiting for MinIO to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Configure MinIO alias
Write-Host "Configuring MinIO client..." -ForegroundColor Yellow
docker exec minio mc alias set myminio http://localhost:9000 minioadmin minioadmin123

# Create bucket if it doesn't exist
Write-Host "Creating marketplace bucket..." -ForegroundColor Yellow
docker exec minio mc mb myminio/marketplace --ignore-existing

# Set public read policy for the bucket (for product images)
Write-Host "Setting bucket policy..." -ForegroundColor Yellow
docker exec minio mc anonymous set download myminio/marketplace

Write-Host ""
Write-Host "MinIO setup completed!" -ForegroundColor Green
Write-Host "Bucket 'marketplace' is ready" -ForegroundColor Green
Write-Host ""
Write-Host "MinIO Console: http://localhost:9001" -ForegroundColor Cyan
Write-Host "Username: minioadmin" -ForegroundColor Cyan
Write-Host "Password: minioadmin123" -ForegroundColor Cyan
