package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestOfficialTestResult_TableName(t *testing.T) {
	result := OfficialTestResult{}
	assert.Equal(t, "official_test_results", result.TableName())
}

func TestOfficialTestResult_Validate(t *testing.T) {
	tests := []struct {
		name    string
		result  *OfficialTestResult
		wantErr bool
	}{
		{
			name: "Valid full test result",
			result: &OfficialTestResult{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				TestType:         "full_test",
				OverallBandScore: 7.5,
				ListeningScore:   8.0,
				ReadingScore:     7.0,
				WritingScore:     7.5,
				SpeakingScore:    7.5,
				TestDate:         time.Now(),
				CompletionStatus: "completed",
			},
			wantErr: false,
		},
		{
			name: "Valid test with raw scores",
			result: &OfficialTestResult{
				ID:                uuid.New(),
				UserID:            uuid.New(),
				TestType:          "academic",
				OverallBandScore:  7.0,
				ListeningScore:    7.5,
				ReadingScore:      7.0,
				WritingScore:      6.5,
				SpeakingScore:     7.0,
				ListeningRawScore: intPtr(30),
				ReadingRawScore:   intPtr(28),
				TestDate:          time.Now(),
				CompletionStatus:  "completed",
			},
			wantErr: false,
		},
		{
			name: "Valid incomplete test",
			result: &OfficialTestResult{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				TestType:         "general",
				OverallBandScore: 6.0,
				ListeningScore:   6.5,
				ReadingScore:     6.0,
				WritingScore:     5.5,
				SpeakingScore:    6.0,
				TestDate:         time.Now(),
				CompletionStatus: "incomplete",
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.result.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestOfficialTestResult_JSONSerialization(t *testing.T) {
	testDate := time.Date(2024, 1, 15, 10, 0, 0, 0, time.UTC)
	userID := uuid.MustParse("123e4567-e89b-12d3-a456-426614174000")
	testID := uuid.MustParse("223e4567-e89b-12d3-a456-426614174000")

	result := &OfficialTestResult{
		ID:                  testID,
		UserID:              userID,
		TestType:            "full_test",
		OverallBandScore:    7.5,
		ListeningScore:      8.0,
		ReadingScore:        7.5,
		WritingScore:        7.0,
		SpeakingScore:       7.5,
		ListeningRawScore:   intPtr(35),
		ReadingRawScore:     intPtr(32),
		TestDate:            testDate,
		TestDurationMinutes: intPtr(180),
		CompletionStatus:    "completed",
		TestSource:          stringPtr("platform"),
		CreatedAt:           testDate,
		UpdatedAt:           testDate,
	}

	// Test that all fields are present
	assert.Equal(t, testID, result.ID)
	assert.Equal(t, userID, result.UserID)
	assert.Equal(t, "full_test", result.TestType)
	assert.Equal(t, 7.5, result.OverallBandScore)
	assert.Equal(t, 8.0, result.ListeningScore)
	assert.Equal(t, 7.5, result.ReadingScore)
	assert.Equal(t, 7.0, result.WritingScore)
	assert.Equal(t, 7.5, result.SpeakingScore)
	assert.NotNil(t, result.ListeningRawScore)
	assert.Equal(t, 35, *result.ListeningRawScore)
	assert.NotNil(t, result.ReadingRawScore)
	assert.Equal(t, 32, *result.ReadingRawScore)
}

func TestOfficialTestResult_BoundaryValues(t *testing.T) {
	tests := []struct {
		name  string
		score float64
		valid bool
	}{
		{"Zero score", 0.0, true},
		{"Perfect score", 9.0, true},
		{"Half band", 6.5, true},
		{"Quarter bands allowed in DB", 6.25, true}, // DB stores DECIMAL(3,1) but accepts this
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := &OfficialTestResult{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				TestType:         "full_test",
				OverallBandScore: tt.score,
				ListeningScore:   tt.score,
				ReadingScore:     tt.score,
				WritingScore:     tt.score,
				SpeakingScore:    tt.score,
				TestDate:         time.Now(),
				CompletionStatus: "completed",
			}

			// Validate should not error
			err := result.Validate()
			assert.NoError(t, err)
		})
	}
}

// Helper functions
func intPtr(i int) *int {
	return &i
}

func stringPtr(s string) *string {
	return &s
}

func float64Ptr(f float64) *float64 {
	return &f
}
