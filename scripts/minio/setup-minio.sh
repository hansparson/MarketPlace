#!/bin/bash
# MinIO Setup Script
# This script creates the required bucket for the marketplace application

echo "Setting up MinIO..."

# Wait for MinIO to be ready
sleep 5

# Install mc (MinIO Client) if not already installed
docker exec minio mc alias set myminio http://localhost:9000 minioadmin minioadmin123

# Create bucket if it doesn't exist
docker exec minio mc mb myminio/marketplace --ignore-existing

# Set public read policy for the bucket (for product images)
docker exec minio mc anonymous set download myminio/marketplace

echo "MinIO setup completed!"
echo "Bucket 'marketplace' is ready"
echo "Access MinIO Console at: http://localhost:9001"
echo "Username: minioadmin"
echo "Password: minioadmin123"
