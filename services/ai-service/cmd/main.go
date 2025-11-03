package main

import (
	"log"
	"os"

	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/database"
	"github.com/bisosad1501/DATN/services/ai-service/internal/handlers"
	"github.com/bisosad1501/DATN/services/ai-service/internal/middleware"
	"github.com/bisosad1501/DATN/services/ai-service/internal/repository"
	"github.com/bisosad1501/DATN/services/ai-service/internal/routes"
	"github.com/bisosad1501/DATN/services/ai-service/internal/service"
)

func main() {
	log.SetOutput(os.Stdout)
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	log.Println("🤖 Starting AI Service...")

	// Load configuration
	cfg := config.LoadConfig()

	// Initialize database
	db, err := database.NewDatabase(cfg)
	if err != nil {
		log.Fatalf("❌ Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize repository
	aiRepo := repository.NewAIRepository(db, cfg)

	// Initialize service
	aiService := service.NewAIService(aiRepo, cfg)

	// Initialize middleware
	authMiddleware := middleware.NewAuthMiddleware(cfg)
	rateLimitMiddleware := middleware.NewRateLimitMiddleware()

	// Initialize handlers
	aiHandler := handlers.NewAIHandler(aiService)

	// Setup routes
	router := routes.SetupRoutes(aiHandler, authMiddleware, rateLimitMiddleware)

	// Start server
	port := ":" + cfg.ServerPort
	log.Printf("✅ AI Service started successfully on port %s", cfg.ServerPort)
	log.Printf("📖 Documentation: http://localhost%s/health", port)
	
	if err := router.Run(port); err != nil {
		log.Fatalf("❌ Failed to start server: %v", err)
	}
}

