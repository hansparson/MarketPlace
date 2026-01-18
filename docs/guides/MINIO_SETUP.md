# MinIO Setup Guide

## Overview
MinIO is used for storing product images and other assets in the marketplace application.

## Configuration

### Docker Compose Settings
```yaml
minio:
  image: minio/minio:latest
  container_name: minio
  command: server /data --console-address ":9001"
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: minioadmin123
  ports:
    - "9000:9000"  # API
    - "9001:9001"  # Console
```

### Environment Variables (.env)
```env
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_USE_SSL=false
MINIO_BUCKET_NAME=marketplace
```

## Setup Instructions

### 1. Initial Setup (One-time)
Run the setup script to create the bucket:

**Windows (PowerShell):**
```powershell
.\setup-minio.ps1
```

**Linux/Mac:**
```bash
chmod +x setup-minio.sh
./setup-minio.sh
```

This script will:
- Configure MinIO client (mc)
- Create 'marketplace' bucket
- Set public read policy for product images

### 2. Access MinIO Console
- URL: http://localhost:9001
- Username: `minioadmin`
- Password: `minioadmin123`

## Usage in Application

### Upload Product Image
When creating a product:
1. Product is created first (returns product ID)
2. Image is uploaded to MinIO with path: `products/{product_id}/{filename}`
3. Asset record is created in database with object_key

### Image URL Format
```
http://localhost:9000/marketplace/products/{product_id}/{filename}
```

## Troubleshooting

### Bucket Not Found Error
Run the setup script again:
```powershell
.\setup-minio.ps1
```

### Connection Refused
1. Check if MinIO container is running:
   ```powershell
   docker ps | findstr minio
   ```

2. Restart MinIO:
   ```powershell
   docker-compose restart minio
   ```

### Images Not Displaying
1. Verify bucket policy is set to public:
   ```powershell
   docker exec minio mc anonymous get myminio/marketplace
   ```

2. Should return: `Access permission for 'myminio/marketplace' is 'download'`

## Manual Bucket Management

### Create Bucket
```powershell
docker exec minio mc mb myminio/marketplace
```

### List Buckets
```powershell
docker exec minio mc ls myminio
```

### List Files in Bucket
```powershell
docker exec minio mc ls myminio/marketplace
```

### Set Public Policy
```powershell
docker exec minio mc anonymous set download myminio/marketplace
```

## Production Considerations

1. **Change Credentials**: Update `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
2. **Enable SSL**: Set `MINIO_USE_SSL=true` and configure certificates
3. **Backup**: Configure regular backups of MinIO data volume
4. **Access Control**: Implement more granular bucket policies
5. **CDN**: Consider using a CDN for serving images in production

## File Structure in Bucket

```
marketplace/
├── products/
│   ├── {product_id_1}/
│   │   ├── image1.jpg
│   │   └── image2.jpg
│   └── {product_id_2}/
│       └── image1.jpg
```

## Integration with Backend

The backend uses the MinIO Go SDK:
- File: `backend/internal/storage/minio.go`
- Method: `UploadFile(ctx, file, folder)`
- Returns: object key (path) for database storage
