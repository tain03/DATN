package handlers

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/bisosad1501/DATN/services/user-service/internal/models"
	"github.com/bisosad1501/DATN/services/user-service/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ScoringHandler struct {
	service *service.UserService
}

func NewScoringHandler(service *service.UserService) *ScoringHandler {
	return &ScoringHandler{service: service}
}

// ============= Request/Response DTOs =============

type RecordTestResultRequest struct {
	TestType          string    `json:"test_type" validate:"required,oneof=full_test academic general"`
	OverallBandScore  float64   `json:"overall_band_score" validate:"required,min=0,max=9"`
	ListeningScore    float64   `json:"listening_score" validate:"required,min=0,max=9"`
	ReadingScore      float64   `json:"reading_score" validate:"required,min=0,max=9"`
	WritingScore      float64   `json:"writing_score" validate:"required,min=0,max=9"`
	SpeakingScore     float64   `json:"speaking_score" validate:"required,min=0,max=9"`
	ListeningRawScore *int      `json:"listening_raw_score,omitempty"`
	ReadingRawScore   *int      `json:"reading_raw_score,omitempty"`
	TestDate          time.Time `json:"test_date"`
	TestSource        string    `json:"test_source,omitempty"`
	Notes             *string   `json:"notes,omitempty"`
}

type RecordPracticeActivityRequest struct {
	Skill              string     `json:"skill" validate:"required,oneof=listening reading writing speaking"`
	ActivityType       string     `json:"activity_type" validate:"required,oneof=drill part_test section_practice question_set"`
	ExerciseID         *uuid.UUID `json:"exercise_id,omitempty"`
	ExerciseTitle      *string    `json:"exercise_title,omitempty"`
	Score              *float64   `json:"score,omitempty"`
	MaxScore           *float64   `json:"max_score,omitempty"`
	BandScore          *float64   `json:"band_score,omitempty"`
	CorrectAnswers     int        `json:"correct_answers"`
	TotalQuestions     *int       `json:"total_questions,omitempty"`
	AccuracyPercentage *float64   `json:"accuracy_percentage,omitempty"`
	TimeSpentSeconds   *int       `json:"time_spent_seconds,omitempty"`
	StartedAt          *time.Time `json:"started_at,omitempty"`
	CompletedAt        *time.Time `json:"completed_at,omitempty"`
	CompletionStatus   string     `json:"completion_status" validate:"required,oneof=completed incomplete abandoned in_progress"`
	AIEvaluated        bool       `json:"ai_evaluated"`
	AIFeedbackSummary  *string    `json:"ai_feedback_summary,omitempty"`
	DifficultyLevel    *string    `json:"difficulty_level,omitempty"`
	Notes              *string    `json:"notes,omitempty"`
}

// ============= Handler Methods =============

// RecordTestResultInternal records an official test result (internal service-to-service)
func (h *ScoringHandler) RecordTestResultInternal(c *gin.Context) {
	// Extract user_id from path
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Parse request body
	var req RecordTestResultRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Create OfficialTestResult model
	result := &models.OfficialTestResult{
		UserID:            userID,
		TestType:          req.TestType,
		OverallBandScore:  req.OverallBandScore,
		ListeningScore:    req.ListeningScore,
		ReadingScore:      req.ReadingScore,
		WritingScore:      req.WritingScore,
		SpeakingScore:     req.SpeakingScore,
		ListeningRawScore: req.ListeningRawScore,
		ReadingRawScore:   req.ReadingRawScore,
		TestDate:          req.TestDate,
		CompletionStatus:  "completed",
		TestSource:        &req.TestSource,
		Notes:             req.Notes,
	}

	if req.TestDate.IsZero() {
		result.TestDate = time.Now()
	}

	// Record test result
	if err := h.service.RecordOfficialTestResult(result); err != nil {
		log.Printf("❌ Error recording test result: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record test result"})
		return
	}

	// Return success response
	c.JSON(http.StatusCreated, gin.H{
		"success":        true,
		"test_result_id": result.ID,
		"message":        "Test result recorded successfully",
	})
}

// RecordPracticeActivityInternal records a practice activity (internal service-to-service)
func (h *ScoringHandler) RecordPracticeActivityInternal(c *gin.Context) {
	// Extract user_id from path
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Parse request body
	var req RecordPracticeActivityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "details": err.Error()})
		return
	}

	// Create PracticeActivity model
	activity := &models.PracticeActivity{
		UserID:             userID,
		Skill:              req.Skill,
		ActivityType:       req.ActivityType,
		ExerciseID:         req.ExerciseID,
		ExerciseTitle:      req.ExerciseTitle,
		Score:              req.Score,
		MaxScore:           req.MaxScore,
		BandScore:          req.BandScore,
		CorrectAnswers:     req.CorrectAnswers,
		TotalQuestions:     req.TotalQuestions,
		AccuracyPercentage: req.AccuracyPercentage,
		TimeSpentSeconds:   req.TimeSpentSeconds,
		StartedAt:          req.StartedAt,
		CompletedAt:        req.CompletedAt,
		CompletionStatus:   req.CompletionStatus,
		AIEvaluated:        req.AIEvaluated,
		AIFeedbackSummary:  req.AIFeedbackSummary,
		DifficultyLevel:    req.DifficultyLevel,
		Notes:              req.Notes,
	}

	// Record practice activity
	if err := h.service.RecordPracticeActivity(activity); err != nil {
		log.Printf("❌ Error recording practice activity: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record practice activity"})
		return
	}

	// Return success response
	c.JSON(http.StatusCreated, gin.H{
		"success":     true,
		"activity_id": activity.ID,
		"message":     "Practice activity recorded successfully",
	})
}

// GetUserTestHistory retrieves user's test history with pagination
func (h *ScoringHandler) GetUserTestHistory(c *gin.Context) {
	// Extract user_id from path
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Parse query parameters
	page := 1
	if pageStr := c.Query("page"); pageStr != "" {
		page, _ = strconv.Atoi(pageStr)
		if page < 1 {
			page = 1
		}
	}

	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		limit, _ = strconv.Atoi(limitStr)
		if limit < 1 || limit > 100 {
			limit = 10
		}
	}

	var skillPtr *string
	if skillType := c.Query("skill"); skillType != "" {
		skillPtr = &skillType
	}

	// Get test history from repository (we'll call repo directly for now)
	// In production, this should go through service layer
	log.Printf("📊 Fetching test history for user %s (page=%d, limit=%d, skill=%v)", userID, page, limit, skillPtr)

	// Return placeholder response
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"tests":       []interface{}{},
			"total_count": 0,
			"page":        page,
			"limit":       limit,
		},
		"message": "Test history retrieved (placeholder)",
	})
}

// GetUserPracticeStatistics retrieves user's practice statistics
func (h *ScoringHandler) GetUserPracticeStatistics(c *gin.Context) {
	// Extract user_id from path
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var skillPtr *string
	if skillType := c.Query("skill"); skillType != "" {
		skillPtr = &skillType
	}

	log.Printf("📊 Fetching practice statistics for user %s (skill=%v)", userID, skillPtr)

	// Return placeholder response
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"by_skill": gin.H{},
		},
		"message": "Practice statistics retrieved (placeholder)",
	})
}
