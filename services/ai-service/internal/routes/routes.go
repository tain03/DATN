package routes

import (
	"strings"

	"github.com/bisosad1501/DATN/services/ai-service/internal/handlers"
	"github.com/bisosad1501/DATN/services/ai-service/internal/middleware"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(handler *handlers.AIHandler, authMiddleware *middleware.AuthMiddleware, rateLimitMiddleware *middleware.RateLimitMiddleware) *gin.Engine {
	router := gin.Default()
	
	// Increase max memory for multipart forms (for audio file uploads)
	router.MaxMultipartMemory = 32 << 20 // 32 MB
	
	// Disable automatic body parsing for multipart to prevent conflicts
	router.Use(func(c *gin.Context) {
		contentType := c.GetHeader("Content-Type")
		// Skip body binding for multipart requests - we'll parse manually
		if strings.HasPrefix(contentType, "multipart/form-data") {
			// Do nothing - let handler parse manually
		}
		c.Next()
	})

	// Health check
	router.GET("/health", handler.HealthCheck)

	// Apply global rate limiting to all API endpoints
	v1 := router.Group("/api/v1")
	v1.Use(rateLimitMiddleware.GlobalRateLimit())
	{
		// Writing endpoints (protected + submission rate limit)
		writing := v1.Group("/ai/writing")
		writing.Use(authMiddleware.AuthRequired())
		{
			writing.POST("/submit", rateLimitMiddleware.SubmissionRateLimit(), handler.SubmitWriting)
			writing.GET("/submissions/:id", handler.GetWritingSubmission)
			writing.GET("/submissions", handler.GetWritingSubmissions)
			writing.GET("/prompts", handler.GetWritingPrompts)
			writing.GET("/prompts/:id", handler.GetWritingPrompt)
		}

		// Speaking endpoints (protected + submission rate limit)
		speaking := v1.Group("/ai/speaking")
		speaking.Use(authMiddleware.AuthRequired())
		{
			speaking.POST("/submit", rateLimitMiddleware.SubmissionRateLimit(), handler.SubmitSpeaking)
			speaking.GET("/submissions", handler.GetSpeakingSubmissions)
			speaking.GET("/submissions/:id", handler.GetSpeakingSubmission)
			speaking.GET("/prompts", handler.GetSpeakingPrompts)
			speaking.GET("/prompts/:id", handler.GetSpeakingPrompt)
		}

		// Admin endpoints (protected + role check)
		admin := v1.Group("/admin/ai")
		admin.Use(authMiddleware.AuthRequired())
		admin.Use(authMiddleware.RequireRole("admin"))
		{
			// Writing prompts management
			adminWriting := admin.Group("/writing/prompts")
			{
				adminWriting.POST("", handler.CreateWritingPrompt)
				adminWriting.PUT("/:id", handler.UpdateWritingPrompt)
				adminWriting.DELETE("/:id", handler.DeleteWritingPrompt)
			}

			// Speaking prompts management
			adminSpeaking := admin.Group("/speaking/prompts")
			{
				adminSpeaking.POST("", handler.CreateSpeakingPrompt)
				adminSpeaking.PUT("/:id", handler.UpdateSpeakingPrompt)
				adminSpeaking.DELETE("/:id", handler.DeleteSpeakingPrompt)
			}
		}
	}

	return router
}

