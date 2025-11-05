package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/bisosad1501/DATN/services/user-service/internal/models"
	"github.com/bisosad1501/DATN/services/user-service/internal/service"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
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
func (h *ScoringHandler) RecordTestResultInternal(w http.ResponseWriter, r *http.Request) {
	// Extract user_id from path
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	// Parse request body
	var req RecordTestResultRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
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
		http.Error(w, "Failed to record test result", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":        true,
		"test_result_id": result.ID,
		"message":        "Test result recorded successfully",
	})
}

// RecordPracticeActivityInternal records a practice activity (internal service-to-service)
func (h *ScoringHandler) RecordPracticeActivityInternal(w http.ResponseWriter, r *http.Request) {
	// Extract user_id from path
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	// Parse request body
	var req RecordPracticeActivityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
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
		http.Error(w, "Failed to record practice activity", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":     true,
		"activity_id": activity.ID,
		"message":     "Practice activity recorded successfully",
	})
}

// GetUserTestHistory retrieves user's test history with pagination
func (h *ScoringHandler) GetUserTestHistory(w http.ResponseWriter, r *http.Request) {
	// Extract user_id from path
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	// Parse query parameters
	pageStr := r.URL.Query().Get("page")
	limitStr := r.URL.Query().Get("limit")
	skillType := r.URL.Query().Get("skill")

	page := 1
	if pageStr != "" {
		page, _ = strconv.Atoi(pageStr)
		if page < 1 {
			page = 1
		}
	}

	limit := 10
	if limitStr != "" {
		limit, _ = strconv.Atoi(limitStr)
		if limit < 1 || limit > 100 {
			limit = 10
		}
	}

	var skillPtr *string
	if skillType != "" {
		skillPtr = &skillType
	}

	// Get test history from repository (we'll call repo directly for now)
	// In production, this should go through service layer
	log.Printf("📊 Fetching test history for user %s (page=%d, limit=%d, skill=%v)", userID, page, limit, skillPtr)

	// Return placeholder response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"tests":       []interface{}{},
			"total_count": 0,
			"page":        page,
			"limit":       limit,
		},
		"message": "Test history retrieved (placeholder)",
	})
}

// GetUserPracticeStatistics retrieves user's practice statistics
func (h *ScoringHandler) GetUserPracticeStatistics(w http.ResponseWriter, r *http.Request) {
	// Extract user_id from path
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	skillType := r.URL.Query().Get("skill")
	var skillPtr *string
	if skillType != "" {
		skillPtr = &skillType
	}

	log.Printf("📊 Fetching practice statistics for user %s (skill=%v)", userID, skillPtr)

	// Return placeholder response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"by_skill": map[string]interface{}{},
		},
		"message": "Practice statistics retrieved (placeholder)",
	})
}
