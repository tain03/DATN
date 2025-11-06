package routes

import (
	"github.com/bisosad1501/DATN/services/ai-service/internal/handlers"
	"github.com/bisosad1501/DATN/services/ai-service/internal/middleware"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(handler *handlers.AIHandler, authMiddleware *middleware.AuthMiddleware, rateLimitMiddleware *middleware.RateLimitMiddleware) *gin.Engine {
	router := gin.Default()

	// Health check
	router.GET("/health", handler.HealthCheck)

	// Apply global rate limiting to all API endpoints
	v1 := router.Group("/api/v1")
	v1.Use(rateLimitMiddleware.GlobalRateLimit())
	{
		// Pure Stateless API endpoints (no auth - for internal service-to-service calls)
		// AI Service is now a PURE EVALUATION ENGINE
		// All submission management moved to Exercise Service
		internal := v1.Group("/ai/internal")
		{
			internal.POST("/writing/evaluate", handler.EvaluateWriting)
			internal.POST("/speaking/transcribe", handler.TranscribeSpeaking)
			internal.POST("/speaking/evaluate", handler.EvaluateSpeaking)
		}

		// Admin endpoints (protected + role check)
		admin := v1.Group("/admin/ai")
		admin.Use(authMiddleware.AuthRequired())
		admin.Use(authMiddleware.RequireRole("admin"))
		{
			// Cache management
			admin.GET("/cache/stats", handler.GetCacheStatistics)
		}
	}

	return router
}
