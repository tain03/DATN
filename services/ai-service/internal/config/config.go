package config

import (
	"log"
	"os"
)

type Config struct {
	// Server
	ServerPort string

	// Database
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string

	// Auth Service Integration
	AuthServiceURL string
	JWTSecret      string

	// Internal API Authentication
	InternalAPIKey string

	// OpenAI API
	OpenAIAPIKey string

	// Service URLs
	UserServiceURL        string
	ExerciseServiceURL    string
	NotificationServiceURL string
}

func LoadConfig() *Config {
	config := &Config{
		ServerPort: getEnv("SERVER_PORT", "8085"),

		// Database
		DBHost:     getEnv("DB_HOST", "postgres"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "ielts_admin"),
		DBPassword: getEnv("DB_PASSWORD", "ielts_password_2025"),
		DBName:     getEnv("DB_NAME", "ai_db"),

		// Auth Service
		AuthServiceURL: getEnv("AUTH_SERVICE_URL", "http://auth-service:8081"),
		JWTSecret:      getEnv("JWT_SECRET", "your_jwt_secret_key_minimum_32_characters_long"),

		// Internal API Authentication
		InternalAPIKey: getEnv("INTERNAL_API_KEY", "internal_secret_key_ielts_2025_change_in_production"),

		// OpenAI API
		OpenAIAPIKey: getEnv("OPENAI_API_KEY", ""),

		// Service URLs
		UserServiceURL:        getEnv("USER_SERVICE_URL", "http://user-service:8082"),
		ExerciseServiceURL:    getEnv("EXERCISE_SERVICE_URL", "http://exercise-service:8083"),
		NotificationServiceURL: getEnv("NOTIFICATION_SERVICE_URL", "http://notification-service:8086"),
	}

	if config.OpenAIAPIKey == "" {
		log.Printf("⚠️  WARNING: OPENAI_API_KEY not set. AI features will not work.")
	}

	log.Printf("✅ Configuration loaded successfully")
	log.Printf("📍 Server Port: %s", config.ServerPort)
	log.Printf("🗄️  Database: %s@%s:%s/%s", config.DBUser, config.DBHost, config.DBPort, config.DBName)
	log.Printf("🔐 Auth Service: %s", config.AuthServiceURL)
	log.Printf("🤖 OpenAI API: %s", maskAPIKey(config.OpenAIAPIKey))

	return config
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func maskAPIKey(key string) string {
	if len(key) == 0 {
		return "not set"
	}
	if len(key) <= 8 {
		return "***"
	}
	return key[:8] + "..."
}

