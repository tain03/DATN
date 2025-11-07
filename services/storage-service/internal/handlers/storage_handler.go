package handlers

import (
	"fmt"
	"log"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/bisosad1501/DATN/services/storage-service/internal/config"
	"github.com/bisosad1501/DATN/services/storage-service/internal/minio"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type StorageHandler struct {
	minioClient *minio.MinIOClient
	config      *config.Config
}

func NewStorageHandler(minioClient *minio.MinIOClient, cfg *config.Config) *StorageHandler {
	return &StorageHandler{
		minioClient: minioClient,
		config:      cfg,
	}
}

// HealthCheck endpoint
func (h *StorageHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "storage-service",
		"bucket":  h.minioClient.GetBucketName(),
	})
}

// UploadAudio handles direct audio file upload (proxy to MinIO)
// POST /api/v1/storage/audio/upload
func (h *StorageHandler) UploadAudio(c *gin.Context) {
	// Get user_id from form or query
	userID := c.PostForm("user_id")
	if userID == "" {
		userID = c.Query("user_id")
	}
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "user_id is required",
		})
		return
	}

	// Get uploaded file
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   fmt.Sprintf("failed to get file: %v", err),
		})
		return
	}
	defer file.Close()

	// Validate file extension
	ext := filepath.Ext(header.Filename)
	validExtensions := []string{".mp3", ".wav", ".m4a", ".ogg", ".webm"}
	isValid := false
	for _, validExt := range validExtensions {
		if strings.ToLower(ext) == validExt {
			isValid = true
			break
		}
	}

	if !isValid {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   fmt.Sprintf("invalid file extension. Allowed: %v", validExtensions),
		})
		return
	}

	// Generate unique object name
	objectID := uuid.New().String()
	objectName := fmt.Sprintf("audio/%s/%s%s", userID, objectID, ext)

	// Get content type
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = getContentType(ext)
	}

	// Upload to MinIO
	err = h.minioClient.UploadObject(objectName, file, header.Size, contentType)
	if err != nil {
		log.Printf("❌ Failed to upload %s to MinIO: %v", objectName, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "failed to upload file",
		})
		return
	}

	// Generate internal access URL (for AI service/backend)
	internalURL := fmt.Sprintf("http://%s/%s/%s",
		h.config.MinIO.Endpoint,
		h.minioClient.GetBucketName(),
		objectName,
	)

	// Generate presigned URL (for frontend - expires in 7 days)
	presignedURL, err := h.minioClient.GetPresignedURL(objectName, 7*24*time.Hour)
	if err != nil {
		log.Printf("⚠️ Failed to generate presigned URL: %v", err)
		// Continue without presigned URL - frontend can use API gateway proxy
		presignedURL = ""
	}

	log.Printf("✅ Uploaded audio: %s (size: %d bytes)", objectName, header.Size)
	log.Printf("📎 Internal URL: %s", internalURL)
	if presignedURL != "" {
		log.Printf("📎 Presigned URL: %s", presignedURL)
	}

	responseData := gin.H{
		"audio_url":       internalURL, // For backend services
		"public_audio_url": presignedURL, // For frontend (presigned URL)
		"object_name":     objectName,
		"content_type":    contentType,
		"size":            header.Size,
	}

	// For backward compatibility, if presigned URL exists, use it as primary audio_url for frontend
	// But keep internal URL for backend
	if presignedURL != "" {
		responseData["audio_url"] = presignedURL
		responseData["internal_audio_url"] = internalURL
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    responseData,
	})
}

// DeleteAudio deletes audio file
// DELETE /api/v1/storage/audio/*object_name
func (h *StorageHandler) DeleteAudio(c *gin.Context) {
	objectName := c.Param("object_name")
	// Strip leading slash (Gin adds it when using *param)
	objectName = strings.TrimPrefix(objectName, "/")
	
	if objectName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "object_name is required",
		})
		return
	}

	// Delete object
	if err := h.minioClient.DeleteObject(objectName); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "failed to delete audio file",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "audio file deleted successfully",
	})
}

// GetAudioInfo gets audio file metadata
// GET /api/v1/storage/audio/info/*object_name
func (h *StorageHandler) GetAudioInfo(c *gin.Context) {
	objectName := c.Param("object_name")
	// Strip leading slash (Gin adds it when using *param)
	objectName = strings.TrimPrefix(objectName, "/")
	
	if objectName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "object_name is required",
		})
		return
	}

	// Get object info
	info, err := h.minioClient.GetObjectInfo(objectName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "audio file not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"object_name":   info.Key,
			"size":          info.Size,
			"content_type":  info.ContentType,
			"last_modified": info.LastModified.Unix(),
			"etag":          info.ETag,
		},
	})
}

// GetPresignedURL generates a presigned URL for an audio file
// GET /api/v1/storage/audio/presigned-url/*object_name
func (h *StorageHandler) GetPresignedURL(c *gin.Context) {
	objectName := c.Param("object_name")
	// Strip leading slash (Gin adds it when using *param)
	objectName = strings.TrimPrefix(objectName, "/")
	
	if objectName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "object_name is required",
		})
		return
	}

	// Parse expiry from query (default 7 days)
	expiryDays := 7
	if expiryStr := c.Query("expiry_days"); expiryStr != "" {
		if days, err := strconv.Atoi(expiryStr); err == nil && days > 0 && days <= 30 {
			expiryDays = days
		}
	}

	// Generate presigned URL (expires in specified days)
	presignedURL, err := h.minioClient.GetPresignedURL(objectName, time.Duration(expiryDays)*24*time.Hour)
	if err != nil {
		log.Printf("❌ Failed to generate presigned URL for %s: %v", objectName, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "failed to generate presigned URL",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"presigned_url": presignedURL,
			"object_name":   objectName,
			"expires_in":    expiryDays * 24 * 3600, // seconds
		},
	})
}

// ServeAudioFile streams audio file directly from MinIO
// GET /api/v1/storage/audio/file/*object_name
func (h *StorageHandler) ServeAudioFile(c *gin.Context) {
	objectName := c.Param("object_name")
	// Strip leading slash (Gin adds it when using *param)
	objectName = strings.TrimPrefix(objectName, "/")
	
	if objectName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "object_name is required",
		})
		return
	}

	// Get object from MinIO
	obj, err := h.minioClient.GetObject(objectName)
	if err != nil {
		log.Printf("❌ Failed to get audio file %s: %v", objectName, err)
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "audio file not found",
		})
		return
	}
	defer obj.Close()

	// Get object info for content type and size
	info, err := h.minioClient.GetObjectInfo(objectName)
	if err != nil {
		log.Printf("⚠️ Failed to get object info for %s: %v", objectName, err)
		// Continue anyway, use default content type
	}

	// Set content type
	contentType := "audio/mpeg"
	if info.ContentType != "" {
		contentType = info.ContentType
	} else {
		// Fallback: detect from extension
		ext := filepath.Ext(objectName)
		contentType = getContentType(ext)
	}

	// Set headers
	c.Header("Content-Type", contentType)
	c.Header("Accept-Ranges", "bytes")
	c.Header("Content-Length", fmt.Sprintf("%d", info.Size))
	c.Header("Cache-Control", "public, max-age=31536000") // Cache for 1 year
	
	// Stream the file
	c.DataFromReader(http.StatusOK, info.Size, contentType, obj, nil)
	
	log.Printf("✅ Served audio file: %s (%s)", objectName, contentType)
}

// Helper function to get content type from extension
func getContentType(ext string) string {
	contentTypes := map[string]string{
		".mp3":  "audio/mpeg",
		".wav":  "audio/wav",
		".m4a":  "audio/mp4",
		".ogg":  "audio/ogg",
		".webm": "audio/webm",
	}

	if ct, ok := contentTypes[strings.ToLower(ext)]; ok {
		return ct
	}
	return "audio/mpeg" // default
}

// ValidateAudioExtension helper
func ValidateAudioExtension(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	validExtensions := []string{".mp3", ".wav", ".m4a", ".ogg", ".webm"}

	for _, validExt := range validExtensions {
		if ext == validExt {
			return true
		}
	}
	return false
}
