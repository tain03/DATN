package handlers

import (
	"fmt"
	"io"
	"mime"
	"net/http"
	"strconv"
	"strings"

	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
	"github.com/bisosad1501/DATN/services/ai-service/internal/service"
	"github.com/bisosad1501/DATN/services/ai-service/internal/validation"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AIHandler struct {
	service *service.AIService
}

func NewAIHandler(service *service.AIService) *AIHandler {
	return &AIHandler{service: service}
}

func (h *AIHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "ai-service",
	})
}

// POST /api/v1/ai/writing/submit
func (h *AIHandler) SubmitWriting(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	userIDStrVal, ok := userIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	userID, err := uuid.Parse(userIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	var req models.WritingSubmissionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate writing submission
	if err := validation.ValidateWritingSubmission(req.TaskType, req.EssayText); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.SubmitWriting(userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GET /api/v1/ai/writing/submissions/:id
func (h *AIHandler) GetWritingSubmission(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid submission id"})
		return
	}

	result, err := h.service.GetWritingSubmission(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "submission not found"})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GET /api/v1/ai/writing/submissions
func (h *AIHandler) GetWritingSubmissions(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	userIDStrVal, ok := userIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	userID, err := uuid.Parse(userIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	submissions, err := h.service.GetUserWritingSubmissions(userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"submissions": submissions})
}

// POST /api/v1/ai/speaking/submit
// Supports both JSON (with audio_url) and multipart/form-data (with audio file)
func (h *AIHandler) SubmitSpeaking(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	userIDStrVal, ok := userIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	userID, err := uuid.Parse(userIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	// Check if multipart form (file upload) or JSON (URL)
	var req models.SpeakingSubmissionRequest
	
	contentType := c.GetHeader("Content-Type")
	
	// IMPORTANT: Parse multipart form FIRST if it's multipart
	// This prevents Gin from trying to parse it as JSON
	if strings.HasPrefix(contentType, "multipart/form-data") {
		// CRITICAL: Prevent Gin from auto-parsing body by reading it manually
		// We must parse multipart BEFORE any JSON parsing happens
		
		// Set max memory for multipart
		if c.Request.MultipartForm == nil {
			err := c.Request.ParseMultipartForm(32 << 20) // 32 MB
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse multipart form: " + err.Error()})
				return
			}
		}
		
		// Get file from parsed form
		fileHeader := c.Request.MultipartForm.File["audio"]
		if len(fileHeader) == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "audio file required in multipart form"})
			return
		}
		
		file := fileHeader[0]
		
		// Validate file size before reading
		if file.Size > validation.MaxAudioFileSizeBytes {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("audio file size (%.2f MB) exceeds maximum allowed size (%d MB)", 
					float64(file.Size)/(1024*1024), validation.MaxAudioFileSizeMB),
			})
			return
		}

		// Handle multipart form with audio file

		// Read audio file
		src, err := file.Open()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to open audio file: " + err.Error()})
			return
		}
		defer src.Close()

		// Use io.ReadAll to handle variable file sizes
		audioData, err := io.ReadAll(src)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read audio file: " + err.Error()})
			return
		}

		// Validate actual read size
		if int64(len(audioData)) > validation.MaxAudioFileSizeBytes {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("audio file size (%.2f MB) exceeds maximum allowed size (%d MB)", 
					float64(len(audioData))/(1024*1024), validation.MaxAudioFileSizeMB),
			})
			return
		}

		// Save to temp location and create URL
		tempURL := fmt.Sprintf("temp://%s", uuid.New().String())

		// Get form fields from parsed multipart form
		form := c.Request.MultipartForm.Value
		
		partNumStr := ""
		if parts, ok := form["part_number"]; ok && len(parts) > 0 {
			partNumStr = strings.TrimSpace(parts[0])
		}
		if partNumStr == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "part_number is required"})
			return
		}
		partNum, err := strconv.Atoi(partNumStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("invalid part_number '%s': %v", partNumStr, err)})
			return
		}
		req.PartNumber = partNum

		if prompts, ok := form["task_prompt_text"]; ok && len(prompts) > 0 {
			req.TaskPromptText = strings.TrimSpace(prompts[0])
		}
		if req.TaskPromptText == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "task_prompt_text is required"})
			return
		}
		
		req.AudioURL = tempURL
		
		durationStr := ""
		if durations, ok := form["audio_duration_seconds"]; ok && len(durations) > 0 {
			durationStr = strings.TrimSpace(durations[0])
		}
		if durationStr == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "audio_duration_seconds is required"})
			return
		}
		duration, err := strconv.Atoi(durationStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("invalid audio_duration_seconds '%s': %v", durationStr, err)})
			return
		}
		req.AudioDurationSeconds = duration
		
		if formats, ok := form["audio_format"]; ok && len(formats) > 0 && formats[0] != "" {
			format := formats[0]
			req.AudioFormat = &format
		}
		
		fileSize := int64(len(audioData))
		req.AudioFileSizeBytes = &fileSize

		// Validate audio file
		mimeType := ""
		if file != nil {
			mimeType = file.Header.Get("Content-Type")
			if mimeType == "" {
				// Try to detect from extension
				ext := ""
				if idx := strings.LastIndex(file.Filename, "."); idx >= 0 {
					ext = file.Filename[idx:]
				}
				if detectedType := mime.TypeByExtension(ext); detectedType != "" {
					mimeType = detectedType
				}
			}
		}

		if err := validation.ValidateAudioFile(fileSize, duration, file.Filename, mimeType); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Pass audio data directly to service
		result, err := h.service.SubmitSpeakingWithAudio(userID, &req, audioData)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, result)
		return
	}
	
	// If we get here, it was multipart but file parsing failed - already handled above
	// This should not be reached, but just in case:
	if strings.HasPrefix(contentType, "multipart/form-data") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to process multipart form"})
		return
	}

	// Handle JSON request - only if Content-Type is JSON or not set (for backward compatibility)
	if contentType != "" && !strings.Contains(contentType, "application/json") {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("unsupported content type: %s. Use multipart/form-data for file upload or application/json for URL", contentType)})
		return
	}

	// Parse JSON body
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid JSON request: " + err.Error()})
		return
	}

	result, err := h.service.SubmitSpeaking(userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GET /api/v1/ai/speaking/submissions
func (h *AIHandler) GetSpeakingSubmissions(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	userIDStrVal, ok := userIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	userID, err := uuid.Parse(userIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	submissions, err := h.service.GetUserSpeakingSubmissions(userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"submissions": submissions})
}

// GET /api/v1/ai/speaking/submissions/:id
func (h *AIHandler) GetSpeakingSubmission(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid submission id"})
		return
	}

	result, err := h.service.GetSpeakingSubmission(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "submission not found"})
		return
	}

	c.JSON(http.StatusOK, result)
}


// GET /api/v1/ai/writing/prompts
func (h *AIHandler) GetWritingPrompts(c *gin.Context) {
	var taskType *string
	var difficulty *string
	var isPublished *bool

	if taskTypeStr := c.Query("task_type"); taskTypeStr != "" {
		taskType = &taskTypeStr
	}
	if difficultyStr := c.Query("difficulty"); difficultyStr != "" {
		difficulty = &difficultyStr
	}
	if isPublishedStr := c.Query("is_published"); isPublishedStr != "" {
		published := isPublishedStr == "true"
		isPublished = &published
	} else {
		published := true
		isPublished = &published
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	prompts, err := h.service.GetWritingPrompts(taskType, difficulty, isPublished, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"prompts": prompts})
}

// GET /api/v1/ai/writing/prompts/:id
func (h *AIHandler) GetWritingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	prompt, err := h.service.GetWritingPrompt(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "prompt not found"})
		return
	}

	c.JSON(http.StatusOK, prompt)
}

// GET /api/v1/ai/speaking/prompts
func (h *AIHandler) GetSpeakingPrompts(c *gin.Context) {
	var partNumber *int
	var difficulty *string
	var isPublished *bool

	if partNumStr := c.Query("part_number"); partNumStr != "" {
		partNum, err := strconv.Atoi(partNumStr)
		if err == nil {
			partNumber = &partNum
		}
	}
	if difficultyStr := c.Query("difficulty"); difficultyStr != "" {
		difficulty = &difficultyStr
	}
	if isPublishedStr := c.Query("is_published"); isPublishedStr != "" {
		published := isPublishedStr == "true"
		isPublished = &published
	} else {
		published := true
		isPublished = &published
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	prompts, err := h.service.GetSpeakingPrompts(partNumber, difficulty, isPublished, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"prompts": prompts})
}

// GET /api/v1/ai/speaking/prompts/:id
func (h *AIHandler) GetSpeakingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	prompt, err := h.service.GetSpeakingPrompt(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "prompt not found"})
		return
	}

	c.JSON(http.StatusOK, prompt)
}

// Admin Endpoints - Writing Prompts
func (h *AIHandler) CreateWritingPrompt(c *gin.Context) {
	adminIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	adminIDStrVal, ok := adminIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	adminID, err := uuid.Parse(adminIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	var req models.WritingPromptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt, err := h.service.CreateWritingPrompt(adminID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, prompt)
}

func (h *AIHandler) UpdateWritingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	var req models.WritingPromptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt, err := h.service.UpdateWritingPrompt(id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, prompt)
}

func (h *AIHandler) DeleteWritingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	if err := h.service.DeleteWritingPrompt(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "prompt deleted successfully"})
}

// Admin Endpoints - Speaking Prompts
func (h *AIHandler) CreateSpeakingPrompt(c *gin.Context) {
	adminIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found"})
		return
	}

	adminIDStrVal, ok := adminIDStr.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid user_id type"})
		return
	}

	adminID, err := uuid.Parse(adminIDStrVal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id format"})
		return
	}

	var req models.SpeakingPromptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt, err := h.service.CreateSpeakingPrompt(adminID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, prompt)
}

func (h *AIHandler) UpdateSpeakingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	var req models.SpeakingPromptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt, err := h.service.UpdateSpeakingPrompt(id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, prompt)
}

func (h *AIHandler) DeleteSpeakingPrompt(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid prompt id"})
		return
	}

	if err := h.service.DeleteSpeakingPrompt(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "prompt deleted successfully"})
}
