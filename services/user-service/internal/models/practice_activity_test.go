package models

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/stretchr/testify/assert"
)

func TestPracticeActivity_TableName(t *testing.T) {
	activity := PracticeActivity{}
	assert.Equal(t, "practice_activities", activity.TableName())
}

func TestPracticeActivity_Validate(t *testing.T) {
	tests := []struct {
		name     string
		activity *PracticeActivity
		wantErr  bool
	}{
		{
			name: "Valid listening drill",
			activity: &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "listening",
				ActivityType:     "drill",
				CorrectAnswers:   8,
				TotalQuestions:   intPtr(10),
				CompletionStatus: "completed",
			},
			wantErr: false,
		},
		{
			name: "Valid reading part test with band score",
			activity: &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "reading",
				ActivityType:     "part_test",
				BandScore:        float64Ptr(7.5),
				CorrectAnswers:   32,
				TotalQuestions:   intPtr(40),
				CompletionStatus: "completed",
			},
			wantErr: false,
		},
		{
			name: "Valid writing practice with AI evaluation",
			activity: &PracticeActivity{
				ID:                uuid.New(),
				UserID:            uuid.New(),
				Skill:             "writing",
				ActivityType:      "drill",
				BandScore:         float64Ptr(6.5),
				AIEvaluated:       true,
				AIFeedbackSummary: stringPtr("Good coherence, improve grammar"),
				CompletionStatus:  "completed",
			},
			wantErr: false,
		},
		{
			name: "Valid speaking practice in progress",
			activity: &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "speaking",
				ActivityType:     "section_practice",
				CompletionStatus: "in_progress",
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.activity.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestPracticeActivity_WithExerciseReference(t *testing.T) {
	exerciseID := uuid.New()
	exerciseTitle := "Listening Section 1 - Form Completion"

	activity := &PracticeActivity{
		ID:               uuid.New(),
		UserID:           uuid.New(),
		Skill:            "listening",
		ActivityType:     "drill",
		ExerciseID:       &exerciseID,
		ExerciseTitle:    &exerciseTitle,
		CorrectAnswers:   7,
		TotalQuestions:   intPtr(10),
		CompletionStatus: "completed",
	}

	assert.NotNil(t, activity.ExerciseID)
	assert.Equal(t, exerciseID, *activity.ExerciseID)
	assert.NotNil(t, activity.ExerciseTitle)
	assert.Equal(t, exerciseTitle, *activity.ExerciseTitle)
}

func TestPracticeActivity_WithTimeTracking(t *testing.T) {
	startTime := time.Now().Add(-30 * time.Minute)
	endTime := time.Now()

	activity := &PracticeActivity{
		ID:               uuid.New(),
		UserID:           uuid.New(),
		Skill:            "reading",
		ActivityType:     "drill",
		TimeSpentSeconds: intPtr(1800), // 30 minutes
		StartedAt:        &startTime,
		CompletedAt:      &endTime,
		CompletionStatus: "completed",
	}

	assert.NotNil(t, activity.TimeSpentSeconds)
	assert.Equal(t, 1800, *activity.TimeSpentSeconds)
	assert.NotNil(t, activity.StartedAt)
	assert.NotNil(t, activity.CompletedAt)
	assert.True(t, activity.CompletedAt.After(*activity.StartedAt))
}

func TestPracticeActivity_WithTags(t *testing.T) {
	tags := pq.StringArray{"vocabulary", "academic", "science"}

	activity := &PracticeActivity{
		ID:               uuid.New(),
		UserID:           uuid.New(),
		Skill:            "reading",
		ActivityType:     "drill",
		Tags:             tags,
		CompletionStatus: "completed",
	}

	assert.Equal(t, 3, len(activity.Tags))
	assert.Contains(t, activity.Tags, "vocabulary")
	assert.Contains(t, activity.Tags, "academic")
	assert.Contains(t, activity.Tags, "science")
}

func TestPracticeActivity_WithDifficulty(t *testing.T) {
	difficulties := []string{"beginner", "intermediate", "advanced", "expert"}

	for _, diff := range difficulties {
		t.Run(diff, func(t *testing.T) {
			activity := &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "listening",
				ActivityType:     "drill",
				DifficultyLevel:  stringPtr(diff),
				CompletionStatus: "completed",
			}

			assert.NotNil(t, activity.DifficultyLevel)
			assert.Equal(t, diff, *activity.DifficultyLevel)
		})
	}
}

func TestPracticeActivity_AccuracyCalculation(t *testing.T) {
	tests := []struct {
		name             string
		correctAnswers   int
		totalQuestions   int
		expectedAccuracy float64
	}{
		{"Perfect score", 10, 10, 100.0},
		{"Half correct", 5, 10, 50.0},
		{"75% correct", 30, 40, 75.0},
		{"Zero correct", 0, 10, 0.0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			accuracy := (float64(tt.correctAnswers) / float64(tt.totalQuestions)) * 100

			activity := &PracticeActivity{
				ID:                 uuid.New(),
				UserID:             uuid.New(),
				Skill:              "reading",
				ActivityType:       "drill",
				CorrectAnswers:     tt.correctAnswers,
				TotalQuestions:     &tt.totalQuestions,
				AccuracyPercentage: &accuracy,
				CompletionStatus:   "completed",
			}

			assert.NotNil(t, activity.AccuracyPercentage)
			assert.InDelta(t, tt.expectedAccuracy, *activity.AccuracyPercentage, 0.01)
		})
	}
}

func TestPracticeActivity_AllSkills(t *testing.T) {
	skills := []string{"listening", "reading", "writing", "speaking"}

	for _, skill := range skills {
		t.Run(skill, func(t *testing.T) {
			activity := &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            skill,
				ActivityType:     "drill",
				CompletionStatus: "completed",
			}

			assert.Equal(t, skill, activity.Skill)
			err := activity.Validate()
			assert.NoError(t, err)
		})
	}
}

func TestPracticeActivity_AllActivityTypes(t *testing.T) {
	activityTypes := []string{"drill", "part_test", "section_practice", "question_set"}

	for _, actType := range activityTypes {
		t.Run(actType, func(t *testing.T) {
			activity := &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "listening",
				ActivityType:     actType,
				CompletionStatus: "completed",
			}

			assert.Equal(t, actType, activity.ActivityType)
			err := activity.Validate()
			assert.NoError(t, err)
		})
	}
}

func TestPracticeActivity_CompletionStatuses(t *testing.T) {
	statuses := []string{"completed", "incomplete", "abandoned", "in_progress"}

	for _, status := range statuses {
		t.Run(status, func(t *testing.T) {
			activity := &PracticeActivity{
				ID:               uuid.New(),
				UserID:           uuid.New(),
				Skill:            "reading",
				ActivityType:     "drill",
				CompletionStatus: status,
			}

			assert.Equal(t, status, activity.CompletionStatus)
			err := activity.Validate()
			assert.NoError(t, err)
		})
	}
}
