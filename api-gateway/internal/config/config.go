package config

import (
	"fmt"
	"os"
)

type Config struct {
	ServerPort string
	JWTSecret  string
	Services   ServiceURLs
	RateLimit  RateLimitConfig
}

type ServiceURLs struct {
	AuthService         string
	UserService         string
	CourseService       string
	ExerciseService     string
	NotificationService string
	AIService          string
}

type RateLimitConfig struct {
	RequestsPerMinute int
	Enabled           bool
}

func LoadConfig() (*Config, error) {
	config := &Config{
		ServerPort: getEnv("SERVER_PORT", "8080"),
		JWTSecret:  getEnv("JWT_SECRET", "your-secret-key"),
		Services: ServiceURLs{
			AuthService:         getEnv("AUTH_SERVICE_URL", "http://auth-service:8081"),
			UserService:         getEnv("USER_SERVICE_URL", "http://user-service:8082"),
			CourseService:       getEnv("COURSE_SERVICE_URL", "http://course-service:8083"),
			ExerciseService:     getEnv("EXERCISE_SERVICE_URL", "http://exercise-service:8084"),
			NotificationService: getEnv("NOTIFICATION_SERVICE_URL", "http://notification-service:8086"),
			AIService:          getEnv("AI_SERVICE_URL", "http://ai-service:8085"),
		},
		RateLimit: RateLimitConfig{
			RequestsPerMinute: getEnvAsInt("RATE_LIMIT_RPM", 100),
			Enabled:           getEnvAsBool("RATE_LIMIT_ENABLED", true),
		},
	}

	if config.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	return config, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	var value int
	fmt.Sscanf(valueStr, "%d", &value)
	return value
}

func getEnvAsBool(key string, defaultValue bool) bool {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	return valueStr == "true" || valueStr == "1"
}
