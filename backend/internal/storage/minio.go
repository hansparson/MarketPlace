package storage

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinioStorage struct {
	client     *minio.Client
	bucketName string
}

func NewMinioStorage() (*MinioStorage, error) {
	endpoint := os.Getenv("MINIO_ENDPOINT")
	accessKey := os.Getenv("MINIO_ACCESS_KEY")
	secretKey := os.Getenv("MINIO_SECRET_KEY")
	useSSL := os.Getenv("MINIO_USE_SSL") == "true"
	bucketName := os.Getenv("MINIO_BUCKET_NAME")

	if endpoint == "" {
		endpoint = "minio:9000" // Default
	}
	if bucketName == "" {
		bucketName = "marketplace" // Default
	}
	if accessKey == "" {
		accessKey = "minioadmin" // Default
	}
	if secretKey == "" {
		secretKey = "minioadmin123" // Default
	}

	log.Printf("[MinIO] Connecting to %s with bucket %s", endpoint, bucketName)

	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		log.Printf("[MinIO] Failed to create client: %v", err)
		return nil, err
	}

	// Check if bucket exists with retry
	ctx := context.Background()
	maxRetries := 5
	var exists bool

	for i := 0; i < maxRetries; i++ {
		exists, err = client.BucketExists(ctx, bucketName)
		if err == nil {
			break
		}
		log.Printf("[MinIO] Retry %d/%d: Failed to check bucket: %v", i+1, maxRetries, err)
		time.Sleep(time.Second * 2)
	}

	if err != nil {
		log.Printf("[MinIO] Failed to check bucket existence after %d retries: %v", maxRetries, err)
		return nil, err
	}

	if !exists {
		log.Printf("[MinIO] Bucket %s does not exist!", bucketName)
		return nil, fmt.Errorf("bucket %s does not exist", bucketName)
	}

	log.Printf("[MinIO] Successfully connected to bucket %s", bucketName)

	return &MinioStorage{
		client:     client,
		bucketName: bucketName,
	}, nil
}

func (s *MinioStorage) UploadFile(ctx context.Context, file *multipart.FileHeader, folder string) (string, error) {
	src, err := file.Open()
	if err != nil {
		log.Printf("[MinIO] Failed to open file: %v", err)
		return "", err
	}
	defer src.Close()

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	uniqueID := uuid.New().String()
	timestamp := time.Now().Unix()
	fileName := fmt.Sprintf("%s/%d_%s%s", folder, timestamp, uniqueID, ext)

	log.Printf("[MinIO] Uploading file: %s (size: %d bytes)", fileName, file.Size)

	_, err = s.client.PutObject(ctx, s.bucketName, fileName, src, file.Size, minio.PutObjectOptions{
		ContentType: file.Header.Get("Content-Type"),
	})
	if err != nil {
		log.Printf("[MinIO] Failed to upload file: %v", err)
		return "", err
	}

	log.Printf("[MinIO] Successfully uploaded: %s", fileName)
	return fileName, nil
}

func (s *MinioStorage) UploadStream(ctx context.Context, reader io.Reader, size int64, contentType, filename, folder string) (string, error) {
	// Generate unique filename
	ext := filepath.Ext(filename)
	if ext == "" && contentType == "image/jpeg" {
		ext = ".jpg"
	}

	uniqueID := uuid.New().String()
	timestamp := time.Now().Unix()
	finalName := fmt.Sprintf("%s/%d_%s%s", folder, timestamp, uniqueID, ext)

	log.Printf("[MinIO] Uploading stream: %s (size: %d bytes)", finalName, size)

	_, err := s.client.PutObject(ctx, s.bucketName, finalName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		log.Printf("[MinIO] Failed to upload stream: %v", err)
		return "", err
	}

	log.Printf("[MinIO] Successfully uploaded stream: %s", finalName)
	return finalName, nil
}

func (s *MinioStorage) GetFileURL(objectKey string) string {
	// For public bucket, return direct URL
	endpoint := os.Getenv("MINIO_ENDPOINT")
	bucketName := os.Getenv("MINIO_BUCKET_NAME")
	return fmt.Sprintf("http://%s/%s/%s", endpoint, bucketName, objectKey)
}

// GetPresignedURL generates a time-limited presigned URL (valid 24 hours)
func (s *MinioStorage) GetPresignedURL(ctx context.Context, objectKey string) string {
	if objectKey == "" {
		return ""
	}
	expiry := 24 * time.Hour
	u, err := s.client.PresignedGetObject(ctx, s.bucketName, objectKey, expiry, nil)
	if err != nil {
		log.Printf("[MinIO] Failed to generate presigned URL for %s: %v", objectKey, err)
		return ""
	}

	// When accessed from an Android emulator or mobile device, the internal
	// Docker hostname (minio:9000) is unreachable. We replace it with the
	// public endpoint configured in MINIO_PUBLIC_HOST env var, falling back
	// to the raw endpoint so callers always get a usable URL.
	rawURL := u.String()
	publicHost := os.Getenv("MINIO_PUBLIC_HOST") // e.g. "192.168.1.10:9000"
	if publicHost != "" {
		internalHost := os.Getenv("MINIO_ENDPOINT")
		if internalHost == "" {
			internalHost = "minio:9000"
		}
		rawURL = strings.ReplaceAll(rawURL, internalHost, publicHost)
	}
	return rawURL
}


func (s *MinioStorage) DeleteFile(ctx context.Context, objectKey string) error {
	log.Printf("[MinIO] Deleting file: %s", objectKey)
	err := s.client.RemoveObject(ctx, s.bucketName, objectKey, minio.RemoveObjectOptions{})
	if err != nil {
		log.Printf("[MinIO] Failed to delete file: %v", err)
		return err
	}
	log.Printf("[MinIO] Successfully deleted: %s", objectKey)
	return nil
}
