package config

import (
	"os"
)

type Config struct {
	Server ServerConfig
	MinIO  MinIOConfig
}

type ServerConfig struct {
	Port string
}

type MinIOConfig struct {
	Endpoint      string // Internal endpoint (minio:9000) for backend services
	PublicEndpoint string // Public endpoint (localhost:9000) for frontend presigned URLs
	AccessKey     string
	SecretKey     string
	BucketName    string
	UseSSL        bool
}

func LoadConfig() *Config {
	return &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "8087"),
		},
		MinIO: MinIOConfig{
			Endpoint:       getEnv("MINIO_ENDPOINT", "minio:9000"),
			PublicEndpoint: getEnv("MINIO_PUBLIC_ENDPOINT", "localhost:9000"), // For presigned URLs accessible from browser
			AccessKey:      getEnv("MINIO_ACCESS_KEY", "ielts_admin"),
			SecretKey:      getEnv("MINIO_SECRET_KEY", "ielts_minio_password_2025"),
			BucketName:     getEnv("MINIO_BUCKET_NAME", "ielts-audio"),
			UseSSL:         getEnv("MINIO_USE_SSL", "false") == "true",
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
