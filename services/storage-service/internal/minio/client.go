package minio

import (
	"context"
	"fmt"
	"io"
	"log"
	"strings"
	"time"

	"github.com/bisosad1501/DATN/services/storage-service/internal/config"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOClient struct {
	client         *minio.Client
	bucketName     string
	publicEndpoint string // Public endpoint for presigned URLs (localhost:9000)
	useSSL         bool
}

func NewMinIOClient(cfg *config.Config) (*MinIOClient, error) {
	// Initialize MinIO client with internal endpoint
	client, err := minio.New(cfg.MinIO.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.MinIO.AccessKey, cfg.MinIO.SecretKey, ""),
		Secure: cfg.MinIO.UseSSL,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create MinIO client: %w", err)
	}

	return &MinIOClient{
		client:         client,
		bucketName:     cfg.MinIO.BucketName,
		publicEndpoint: cfg.MinIO.PublicEndpoint,
		useSSL:         cfg.MinIO.UseSSL,
	}, nil
}

// EnsureBucket creates bucket if it doesn't exist
func (m *MinIOClient) EnsureBucket() error {
	ctx := context.Background()

	exists, err := m.client.BucketExists(ctx, m.bucketName)
	if err != nil {
		return fmt.Errorf("error checking bucket: %w", err)
	}

	if !exists {
		err = m.client.MakeBucket(ctx, m.bucketName, minio.MakeBucketOptions{})
		if err != nil {
			return fmt.Errorf("error creating bucket: %w", err)
		}
		log.Printf("✅ Created bucket: %s", m.bucketName)
	}

	return nil
}

// GetObjectInfo gets information about an object
func (m *MinIOClient) GetObjectInfo(objectName string) (minio.ObjectInfo, error) {
	ctx := context.Background()
	return m.client.StatObject(ctx, m.bucketName, objectName, minio.StatObjectOptions{})
}

// GetObject retrieves an object from MinIO
func (m *MinIOClient) GetObject(objectName string) (*minio.Object, error) {
	ctx := context.Background()
	return m.client.GetObject(ctx, m.bucketName, objectName, minio.GetObjectOptions{})
}

// DeleteObject deletes an object from bucket
func (m *MinIOClient) DeleteObject(objectName string) error {
	ctx := context.Background()
	return m.client.RemoveObject(ctx, m.bucketName, objectName, minio.RemoveObjectOptions{})
}

// UploadObject uploads an object to MinIO
func (m *MinIOClient) UploadObject(objectName string, reader io.Reader, objectSize int64, contentType string) error {
	ctx := context.Background()

	_, err := m.client.PutObject(ctx, m.bucketName, objectName, reader, objectSize, minio.PutObjectOptions{
		ContentType: contentType,
	})

	return err
}

// GetBucketName returns the bucket name
func (m *MinIOClient) GetBucketName() string {
	return m.bucketName
}

// GetPresignedURL generates a presigned URL for public access (for frontend)
// Generates URL with internal client and replaces endpoint with public endpoint
// MinIO presigned URLs are host-agnostic in signature, so endpoint replacement works
func (m *MinIOClient) GetPresignedURL(objectName string, expiry time.Duration) (string, error) {
	ctx := context.Background()
	
	// Generate presigned URL with internal client
	url, err := m.client.PresignedGetObject(ctx, m.bucketName, objectName, expiry, nil)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}
	
	urlStr := url.String()
	log.Printf("📎 Generated presigned URL (internal): %s", urlStr)
	
	// Replace internal endpoint with public endpoint
	// MinIO presigned URLs signature doesn't validate host, so this works
	scheme := "http://"
	if m.useSSL {
		scheme = "https://"
	}
	
	// Replace minio:9000 with public endpoint (localhost:9000)
	oldEndpoint := scheme + "minio:9000"
	newEndpoint := scheme + m.publicEndpoint
	urlStr = strings.ReplaceAll(urlStr, oldEndpoint, newEndpoint)
	
	log.Printf("📎 Converted to public presigned URL: %s", urlStr)
	
	return urlStr, nil
}
