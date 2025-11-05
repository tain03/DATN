package models

import (
	"time"

	"github.com/google/uuid"
)

// OfficialTestResult represents an official full IELTS test result
// This is the SOURCE OF TRUTH for user's official band scores
type OfficialTestResult struct {
	ID     uuid.UUID `json:"id" db:"id"`
	UserID uuid.UUID `json:"user_id" db:"user_id" validate:"required"`

	// Test type: full_test, academic, general
	TestType string `json:"test_type" db:"test_type" validate:"required,oneof=full_test academic general"`

	// Overall band score (average of 4 skills)
	OverallBandScore float64 `json:"overall_band_score" db:"overall_band_score" validate:"required,min=0,max=9"`

	// Individual skill scores (IELTS band scores: 0.0 to 9.0)
	ListeningScore float64 `json:"listening_score" db:"listening_score" validate:"required,min=0,max=9"`
	ReadingScore   float64 `json:"reading_score" db:"reading_score" validate:"required,min=0,max=9"`
	WritingScore   float64 `json:"writing_score" db:"writing_score" validate:"required,min=0,max=9"`
	SpeakingScore  float64 `json:"speaking_score" db:"speaking_score" validate:"required,min=0,max=9"`

	// Raw scores for Listening and Reading (for reference)
	ListeningRawScore *int `json:"listening_raw_score,omitempty" db:"listening_raw_score" validate:"omitempty,min=0,max=40"`
	ReadingRawScore   *int `json:"reading_raw_score,omitempty" db:"reading_raw_score" validate:"omitempty,min=0,max=40"`

	// Test metadata
	TestDate            time.Time `json:"test_date" db:"test_date" validate:"required"`
	TestDurationMinutes *int      `json:"test_duration_minutes,omitempty" db:"test_duration_minutes" validate:"omitempty,min=0"`
	CompletionStatus    string    `json:"completion_status" db:"completion_status" validate:"required,oneof=completed incomplete abandoned"`
	TestSource          *string   `json:"test_source,omitempty" db:"test_source"` // platform, imported, manual_entry
	Notes               *string   `json:"notes,omitempty" db:"notes"`

	// Timestamps
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// TableName returns the table name for OfficialTestResult
func (OfficialTestResult) TableName() string {
	return "official_test_results"
}

// Validate performs business logic validation
func (o *OfficialTestResult) Validate() error {
	// Additional business logic validation beyond struct tags
	// This could include checking if overall score matches average of skill scores
	return nil
}
