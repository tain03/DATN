package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

// PracticeActivity represents an individual practice drill or part test
// This tracks practice activities SEPARATELY from official test results
type PracticeActivity struct {
	ID     uuid.UUID `json:"id" db:"id"`
	UserID uuid.UUID `json:"user_id" db:"user_id" validate:"required"`

	// Activity identification
	Skill        string `json:"skill" db:"skill" validate:"required,oneof=listening reading writing speaking"`
	ActivityType string `json:"activity_type" db:"activity_type" validate:"required,oneof=drill part_test section_practice question_set"`

	// Exercise reference (from exercise_db)
	ExerciseID    *uuid.UUID `json:"exercise_id,omitempty" db:"exercise_id"`
	ExerciseTitle *string    `json:"exercise_title,omitempty" db:"exercise_title"`

	// Performance metrics
	Score     *float64 `json:"score,omitempty" db:"score"`         // Raw score (can be percentage, count, etc.)
	MaxScore  *float64 `json:"max_score,omitempty" db:"max_score"` // Maximum possible score
	BandScore *float64 `json:"band_score,omitempty" db:"band_score" validate:"omitempty,min=0,max=9"`

	// Detailed results
	CorrectAnswers     int      `json:"correct_answers" db:"correct_answers"`
	TotalQuestions     *int     `json:"total_questions,omitempty" db:"total_questions"`
	AccuracyPercentage *float64 `json:"accuracy_percentage,omitempty" db:"accuracy_percentage" validate:"omitempty,min=0,max=100"`

	// Time tracking
	TimeSpentSeconds *int       `json:"time_spent_seconds,omitempty" db:"time_spent_seconds" validate:"omitempty,min=0"`
	StartedAt        *time.Time `json:"started_at,omitempty" db:"started_at"`
	CompletedAt      *time.Time `json:"completed_at,omitempty" db:"completed_at"`

	// Status
	CompletionStatus string `json:"completion_status" db:"completion_status" validate:"required,oneof=completed incomplete abandoned in_progress"`

	// AI evaluation (for Writing/Speaking)
	AIEvaluated       bool    `json:"ai_evaluated" db:"ai_evaluated"`
	AIFeedbackSummary *string `json:"ai_feedback_summary,omitempty" db:"ai_feedback_summary"`

	// Additional metadata
	DifficultyLevel *string        `json:"difficulty_level,omitempty" db:"difficulty_level" validate:"omitempty,oneof=beginner intermediate advanced expert"`
	Tags            pq.StringArray `json:"tags,omitempty" db:"tags"` // PostgreSQL TEXT[] array
	Notes           *string        `json:"notes,omitempty" db:"notes"`

	// Timestamps
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// TableName returns the table name for PracticeActivity
func (PracticeActivity) TableName() string {
	return "practice_activities"
}

// Validate performs business logic validation
func (p *PracticeActivity) Validate() error {
	// Additional business logic validation beyond struct tags
	return nil
}

// StringArray is a helper type for PostgreSQL TEXT[] arrays
// Note: We're using pq.StringArray from lib/pq which handles this automatically
type StringArray []string

// Scan implements the sql.Scanner interface
func (a *StringArray) Scan(src interface{}) error {
	if src == nil {
		*a = nil
		return nil
	}

	var arr pq.StringArray
	if err := arr.Scan(src); err != nil {
		return err
	}
	*a = []string(arr)
	return nil
}

// Value implements the driver.Valuer interface
func (a StringArray) Value() (driver.Value, error) {
	if a == nil {
		return nil, nil
	}
	return pq.StringArray(a).Value()
}

// JSONBMap is a helper type for JSONB columns
type JSONBMap map[string]interface{}

// Scan implements the sql.Scanner interface for JSONB
func (j *JSONBMap) Scan(src interface{}) error {
	if src == nil {
		*j = nil
		return nil
	}

	var data []byte
	switch v := src.(type) {
	case []byte:
		data = v
	case string:
		data = []byte(v)
	default:
		return nil
	}

	return json.Unmarshal(data, j)
}

// Value implements the driver.Valuer interface for JSONB
func (j JSONBMap) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	return json.Marshal(j)
}
