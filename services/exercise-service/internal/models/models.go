package models

import (
	"time"

	"github.com/google/uuid"
)

// Exercise represents an exercise/test
type Exercise struct {
	ID                    uuid.UUID  `json:"id"`
	Title                 string     `json:"title"`
	Slug                  string     `json:"slug"`
	Description           *string    `json:"description,omitempty"`
	ExerciseType          string     `json:"exercise_type"` // practice, mock_test, full_test, mini_test
	SkillType             string     `json:"skill_type"`    // listening, reading, writing, speaking
	IELTSTestType         *string    `json:"ielts_test_type,omitempty"` // academic, general_training (only for Reading)
	Difficulty            string     `json:"difficulty"`    // easy, medium, hard
	IELTSLevel            *string    `json:"ielts_level,omitempty"`
	TotalQuestions        int        `json:"total_questions"`
	TotalSections         int        `json:"total_sections"`
	TimeLimitMinutes      *int       `json:"time_limit_minutes,omitempty"`
	ThumbnailURL          *string    `json:"thumbnail_url,omitempty"`
	AudioURL              *string    `json:"audio_url,omitempty"`
	AudioDurationSeconds  *int       `json:"audio_duration_seconds,omitempty"`
	AudioTranscript       *string    `json:"audio_transcript,omitempty"`
	PassageCount          *int       `json:"passage_count,omitempty"`
	CourseID              *uuid.UUID `json:"course_id,omitempty"`
	ModuleID              *uuid.UUID `json:"module_id,omitempty"`
	PassingScore          *float64   `json:"passing_score,omitempty"`
	TotalPoints           *float64   `json:"total_points,omitempty"`
	IsFree                bool       `json:"is_free"`
	IsPublished           bool       `json:"is_published"`
	TotalAttempts         int        `json:"total_attempts"`
	AverageScore          *float64   `json:"average_score,omitempty"` // Average percentage (0-100) of all completed attempts
	AverageCompletionTime *int       `json:"average_completion_time,omitempty"`
	DisplayOrder          int        `json:"display_order"`
	CreatedBy             uuid.UUID  `json:"created_by"`
	PublishedAt           *time.Time `json:"published_at,omitempty"`
	CreatedAt             time.Time  `json:"created_at"`
	UpdatedAt             time.Time  `json:"updated_at"`
}

// IsOfficialTest returns true if this is an official full test
func (e *Exercise) IsOfficialTest() bool {
	return e.ExerciseType == "full_test"
}

// RequiresAIEvaluation returns true if this exercise requires AI evaluation (Writing/Speaking)
func (e *Exercise) RequiresAIEvaluation() bool {
	return e.SkillType == "writing" || e.SkillType == "speaking"
}

// ExerciseSection represents a section within an exercise
type ExerciseSection struct {
	ID               uuid.UUID `json:"id"`
	ExerciseID       uuid.UUID `json:"exercise_id"`
	Title            string    `json:"title"`
	Description      *string   `json:"description,omitempty"`
	SectionNumber    int       `json:"section_number"`
	AudioURL         *string   `json:"audio_url,omitempty"`
	AudioStartTime   *int      `json:"audio_start_time,omitempty"`
	AudioEndTime     *int      `json:"audio_end_time,omitempty"`
	Transcript       *string   `json:"transcript,omitempty"`
	PassageTitle     *string   `json:"passage_title,omitempty"`
	PassageContent   *string   `json:"passage_content,omitempty"`
	PassageWordCount *int      `json:"passage_word_count,omitempty"`
	Instructions     *string   `json:"instructions,omitempty"`
	TotalQuestions   int       `json:"total_questions"`
	TimeLimitMinutes *int      `json:"time_limit_minutes,omitempty"`
	DisplayOrder     int       `json:"display_order"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// Question represents a question in an exercise
type Question struct {
	ID             uuid.UUID  `json:"id"`
	ExerciseID     uuid.UUID  `json:"exercise_id"`
	SectionID      *uuid.UUID `json:"section_id,omitempty"`
	QuestionNumber int        `json:"question_number"`
	QuestionText   string     `json:"question_text"`
	QuestionType   string     `json:"question_type"` // multiple_choice, true_false_not_given, matching, fill_in_blank, etc.
	AudioURL       *string    `json:"audio_url,omitempty"`
	ImageURL       *string    `json:"image_url,omitempty"`
	ContextText    *string    `json:"context_text,omitempty"`
	Points         float64    `json:"points"`
	Difficulty     *string    `json:"difficulty,omitempty"`
	Explanation    *string    `json:"explanation,omitempty"`
	Tips           *string    `json:"tips,omitempty"`
	DisplayOrder   int        `json:"display_order"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

// QuestionOption represents an option for multiple choice questions
type QuestionOption struct {
	ID             uuid.UUID `json:"id"`
	QuestionID     uuid.UUID `json:"question_id"`
	OptionLabel    string    `json:"option_label"` // A, B, C, D
	OptionText     string    `json:"option_text"`
	OptionImageURL *string   `json:"option_image_url,omitempty"`
	IsCorrect      bool      `json:"is_correct"`
	DisplayOrder   int       `json:"display_order"`
	CreatedAt      time.Time `json:"created_at"`
}

// QuestionAnswer represents correct answer for fill-in-blank, matching, etc.
type QuestionAnswer struct {
	ID                 uuid.UUID `json:"id"`
	QuestionID         uuid.UUID `json:"question_id"`
	AnswerText         string    `json:"answer_text"`
	AlternativeAnswers *string   `json:"alternative_answers,omitempty"` // JSON array
	IsCaseSensitive    bool      `json:"is_case_sensitive"`
	MatchingOrder      *int      `json:"matching_order,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

// Submission represents a student's submission (maps to user_exercise_attempts table)
type Submission struct {
	ID                uuid.UUID  `json:"id"`
	UserID            uuid.UUID  `json:"user_id"`
	ExerciseID        uuid.UUID  `json:"exercise_id"`
	AttemptNumber     int        `json:"attempt_number"`
	Status            string     `json:"status"` // in_progress, completed, abandoned
	TotalQuestions    int        `json:"total_questions"`
	QuestionsAnswered int        `json:"questions_answered"`
	CorrectAnswers    int        `json:"correct_answers"`
	Score             *float64   `json:"score,omitempty"`      // Percentage or points
	BandScore         *float64   `json:"band_score,omitempty"` // IELTS band score
	TimeLimitMinutes  *int       `json:"time_limit_minutes,omitempty"`
	TimeSpentSeconds  int        `json:"time_spent_seconds"`
	StartedAt         time.Time  `json:"started_at"`
	CompletedAt       *time.Time `json:"completed_at,omitempty"`
	DeviceType        *string    `json:"device_type,omitempty"` // web, android, ios
	
	// Writing-specific fields (Phase 4)
	EssayText     *string `json:"essay_text,omitempty"`
	WordCount     *int    `json:"word_count,omitempty"`
	TaskType      *string `json:"task_type,omitempty"`       // task1, task2
	PromptText    *string `json:"prompt_text,omitempty"`
	
	// Speaking-specific fields (Phase 4)
	AudioURL              *string `json:"audio_url,omitempty"`
	AudioDurationSeconds  *int    `json:"audio_duration_seconds,omitempty"`
	TranscriptText        *string `json:"transcript_text,omitempty"`
	SpeakingPartNumber    *int    `json:"speaking_part_number,omitempty"` // 1, 2, 3
	
	// AI Evaluation fields (Phase 4)
	EvaluationStatus      *string `json:"evaluation_status,omitempty"`       // pending, processing, completed, failed
	AIEvaluationID        *string `json:"ai_evaluation_id,omitempty"`        // Reference to AI evaluation
	DetailedScores        *string `json:"detailed_scores,omitempty"`         // JSONB with criteria scores
	AIFeedback            *string `json:"ai_feedback,omitempty"`             // AI-generated feedback
	
	// Test/Practice linking (Phase 4)
	OfficialTestResultID  *uuid.UUID `json:"official_test_result_id,omitempty"`  // FK to user_db.official_test_results
	PracticeActivityID    *uuid.UUID `json:"practice_activity_id,omitempty"`     // FK to user_db.practice_activities
	
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// SubmissionAnswer represents an answer in a submission (maps to user_answers table)
type SubmissionAnswer struct {
	ID               uuid.UUID  `json:"id"`
	AttemptID        uuid.UUID  `json:"attempt_id"` // FK to user_exercise_attempts
	QuestionID       uuid.UUID  `json:"question_id"`
	UserID           uuid.UUID  `json:"user_id"`
	AnswerText       *string    `json:"answer_text,omitempty"`
	SelectedOptionID *uuid.UUID `json:"selected_option_id,omitempty"`
	IsCorrect        *bool      `json:"is_correct,omitempty"`
	PointsEarned     *float64   `json:"points_earned,omitempty"`
	TimeSpentSeconds *int       `json:"time_spent_seconds,omitempty"`
	AnsweredAt       time.Time  `json:"answered_at"`
}

// ExerciseTag represents a tag for exercises
type ExerciseTag struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Slug      string    `json:"slug"`
	CreatedAt time.Time `json:"created_at"`
}

// QuestionBank represents reusable question in question bank
type QuestionBank struct {
	ID           uuid.UUID `json:"id"`
	Title        *string   `json:"title,omitempty"`
	SkillType    string    `json:"skill_type"` // listening, reading
	QuestionType string    `json:"question_type"`
	Difficulty   *string   `json:"difficulty,omitempty"`
	Topic        *string   `json:"topic,omitempty"`
	QuestionText string    `json:"question_text"`
	ContextText  *string   `json:"context_text,omitempty"`
	AudioURL     *string   `json:"audio_url,omitempty"`
	ImageURL     *string   `json:"image_url,omitempty"`
	AnswerData   string    `json:"answer_data"` // JSONB stored as string
	Tags         []string  `json:"tags,omitempty"`
	TimesUsed    int       `json:"times_used"`
	CreatedBy    uuid.UUID `json:"created_by"`
	IsVerified   bool      `json:"is_verified"`
	IsPublished  bool      `json:"is_published"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// ExerciseAnalytics represents analytics for an exercise
type ExerciseAnalytics struct {
	ExerciseID            uuid.UUID `json:"exercise_id"`
	TotalAttempts         int       `json:"total_attempts"`
	CompletedAttempts     int       `json:"completed_attempts"`
	AbandonedAttempts     int       `json:"abandoned_attempts"`
	AverageScore          *float64  `json:"average_score,omitempty"`
	MedianScore           *float64  `json:"median_score,omitempty"`
	HighestScore          *float64  `json:"highest_score,omitempty"`
	LowestScore           *float64  `json:"lowest_score,omitempty"`
	AverageCompletionTime *int      `json:"average_completion_time,omitempty"` // seconds
	MedianCompletionTime  *int      `json:"median_completion_time,omitempty"`
	ActualDifficulty      *string   `json:"actual_difficulty,omitempty"`
	QuestionStatistics    *string   `json:"question_statistics,omitempty"` // JSONB
	UpdatedAt             time.Time `json:"updated_at"`
}

// ============================================
// Request/Response Models
// ============================================

// CreateBankQuestionRequest represents request to create a question bank question
type CreateBankQuestionRequest struct {
	Title        *string                `json:"title,omitempty"`
	SkillType    string                 `json:"skill_type" binding:"required"`
	QuestionType string                 `json:"question_type" binding:"required"`
	Difficulty   *string                `json:"difficulty,omitempty"`
	Topic        *string                `json:"topic,omitempty"`
	QuestionText string                 `json:"question_text" binding:"required"`
	ContextText  *string                `json:"context_text,omitempty"`
	AudioURL     *string                `json:"audio_url,omitempty"`
	ImageURL     *string                `json:"image_url,omitempty"`
	AnswerData   map[string]interface{} `json:"answer_data" binding:"required"`
	Tags         []string               `json:"tags,omitempty"`
}

// UpdateBankQuestionRequest represents request to update a question bank question
type UpdateBankQuestionRequest struct {
	Title        *string                `json:"title,omitempty"`
	SkillType    string                 `json:"skill_type" binding:"required"`
	QuestionText string                 `json:"question_text" binding:"required"`
	QuestionType string                 `json:"question_type" binding:"required"`
	Difficulty   *string                `json:"difficulty,omitempty"`
	Topic        *string                `json:"topic,omitempty"`
	ContextText  *string                `json:"context_text,omitempty"`
	AudioURL     *string                `json:"audio_url,omitempty"`
	ImageURL     *string                `json:"image_url,omitempty"`
	AnswerData   map[string]interface{} `json:"answer_data" binding:"required"`
	Tags         []string               `json:"tags,omitempty"`
}

// CreateTagRequest represents request to create a tag
type CreateTagRequest struct {
	Name string `json:"name" binding:"required"`
	Slug string `json:"slug" binding:"required"`
}

// AddTagRequest represents request to add tag to exercise
type AddTagRequest struct {
	TagID int `json:"tag_id" binding:"required"`
}
