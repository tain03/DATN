package handlers

import (
	"net/http"
	"strings"

	"github.com/bisosad1501/DATN/services/ai-service/internal/service"
	"github.com/gin-gonic/gin"
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

// POST /api/v1/ai/writing/evaluate
func (h *AIHandler) EvaluateWriting(c *gin.Context) {
	var req struct {
		EssayText  string `json:"essay_text" binding:"required"`
		TaskType   string `json:"task_type"`
		PromptText string `json:"prompt_text"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.EvaluateWritingPure(req.EssayText, req.TaskType, req.PromptText)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

// POST /api/v1/ai/speaking/transcribe
func (h *AIHandler) TranscribeSpeaking(c *gin.Context) {
	var req struct {
		AudioURL string `json:"audio_url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	transcript, err := h.service.TranscribeSpeakingPure(req.AudioURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"transcript_text": transcript,
		},
	})
}

// POST /api/v1/ai/speaking/evaluate
func (h *AIHandler) EvaluateSpeaking(c *gin.Context) {
	var req struct {
		AudioURL       string  `json:"audio_url" binding:"required"`
		TranscriptText string  `json:"transcript_text"`
		PromptText     string  `json:"prompt_text"`
		PartNumber     int     `json:"part_number"`
		WordCount      int     `json:"word_count"`
		Duration       float64 `json:"duration"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Calculate word count from transcript if not provided
	wordCount := req.WordCount
	if wordCount == 0 && req.TranscriptText != "" {
		wordCount = len(strings.Fields(req.TranscriptText))
	}

	result, err := h.service.EvaluateSpeakingPure(req.AudioURL, req.TranscriptText, req.PromptText, req.PartNumber, wordCount, req.Duration)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

// GET /api/v1/ai/cache/stats
func (h *AIHandler) GetCacheStatistics(c *gin.Context) {
	stats, err := h.service.GetCacheStatistics()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}
