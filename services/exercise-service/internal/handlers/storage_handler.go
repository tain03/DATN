package handlers

import (
	"net/http"

	"github.com/bisosad1501/ielts-platform/exercise-service/internal/client"
	"github.com/bisosad1501/ielts-platform/exercise-service/internal/middleware"
	"github.com/gin-gonic/gin"
)

// StorageHandler handles storage-related requests (proxy to Storage Service)
type StorageHandler struct {
	storageClient *client.StorageServiceClient
}

// NewStorageHandler creates a new storage handler
func NewStorageHandler(storageClient *client.StorageServiceClient) *StorageHandler {
	return &StorageHandler{
		storageClient: storageClient,
	}
}

// UploadAudio handles audio file upload (proxy to Storage Service)
// POST /api/v1/storage/audio/upload
func (h *StorageHandler) UploadAudio(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": "User not authenticated",
			},
		})
		return
	}

	// Get uploaded file
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INVALID_REQUEST",
				"message": "Failed to get file",
				"details": err.Error(),
			},
		})
		return
	}
	defer file.Close()

	// Forward to Storage Service
	result, err := h.storageClient.UploadAudio(userID.(string), file, header)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "STORAGE_ERROR",
				"message": "Failed to upload audio",
				"details": err.Error(),
			},
		})
		return
	}

	// Return both URLs: presigned for frontend, internal for backend
	responseData := gin.H{
		"audio_url":    result.Data.AudioURL, // Presigned URL (for frontend)
		"object_name":  result.Data.ObjectName,
		"content_type": result.Data.ContentType,
		"size":         result.Data.Size,
	}

	// Add internal URL if available (for backend services)
	if result.Data.InternalAudioURL != "" {
		responseData["internal_audio_url"] = result.Data.InternalAudioURL
	}

	// Add public URL if available
	if result.Data.PublicAudioURL != "" {
		responseData["public_audio_url"] = result.Data.PublicAudioURL
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    responseData,
	})
}

// GetAudioInfo gets audio file metadata
// GET /api/v1/storage/audio/info/:object_name
func (h *StorageHandler) GetAudioInfo(c *gin.Context) {
	objectName := c.Param("object_name")
	if objectName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INVALID_REQUEST",
				"message": "object_name is required",
			},
		})
		return
	}

	// Call Storage Service
	result, err := h.storageClient.GetAudioInfo(objectName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "NOT_FOUND",
				"message": "Audio file not found",
				"details": err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"object_name":   result.Data.ObjectName,
			"size":          result.Data.Size,
			"content_type":  result.Data.ContentType,
			"last_modified": result.Data.LastModified,
		},
	})
}

// RegisterStorageRoutes registers storage routes
func RegisterStorageRoutes(router *gin.RouterGroup, handler *StorageHandler, authMiddleware *middleware.AuthMiddleware) {
	storage := router.Group("/storage")
	storage.Use(authMiddleware.AuthRequired())
	{
		audio := storage.Group("/audio")
		{
			// Upload audio (authenticated users only)
			audio.POST("/upload", handler.UploadAudio)

			// Get audio info
			audio.GET("/info/:object_name", handler.GetAudioInfo)
		}
	}
}
