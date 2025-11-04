package models

import "github.com/google/uuid"

// ExerciseListQuery for filtering exercises
type ExerciseListQuery struct {
	Page         int        `form:"page"`
	Limit        int        `form:"limit"`
	SkillType    string     `form:"skill_type"`    // listening, reading
	Difficulty   string     `form:"difficulty"`    // easy, medium, hard
	ExerciseType string     `form:"exercise_type"` // practice, mock_test, full_test
	IsFree       *bool      `form:"is_free"`
	CourseID     *uuid.UUID `form:"course_id"`
	ModuleID     *uuid.UUID `form:"module_id"`
	Search       string     `form:"search"`
	SortBy       string     `form:"sort_by"`       // newest, popular, difficulty, title
	SortOrder    string     `form:"sort_order"`    // asc, desc
}

// ExerciseDetailResponse includes exercise with sections and questions
type ExerciseDetailResponse struct {
	Exercise *Exercise              `json:"exercise"`
	Sections []SectionWithQuestions `json:"sections"`
}

// SectionWithQuestions includes section with its questions
type SectionWithQuestions struct {
	Section   *ExerciseSection      `json:"section"`
	Questions []QuestionWithOptions `json:"questions"`
}

// QuestionWithOptions includes question with its options
type QuestionWithOptions struct {
	Question *Question        `json:"question"`
	Options  []QuestionOption `json:"options,omitempty"`
}

// SubmitAnswersRequest for submitting exercise answers
type SubmitAnswersRequest struct {
	Answers []SubmitAnswerItem `json:"answers" binding:"required"`
}

// SubmitAnswerItem represents a single answer
type SubmitAnswerItem struct {
	QuestionID       uuid.UUID  `json:"question_id" binding:"required"`
	SelectedOptionID *uuid.UUID `json:"selected_option_id,omitempty"`
	TextAnswer       *string    `json:"text_answer,omitempty"`
	TimeSpentSeconds *int       `json:"time_spent_seconds,omitempty"`
}

// SubmissionResultResponse includes detailed results
type SubmissionResultResponse struct {
	Submission  *Submission                    `json:"submission"`
	Exercise    *Exercise                      `json:"exercise"`
	Answers     []SubmissionAnswerWithQuestion `json:"answers"`
	Performance *PerformanceStats              `json:"performance"`
}

// SubmissionAnswerWithQuestion includes answer with question details
type SubmissionAnswerWithQuestion struct {
	Answer        *SubmissionAnswer `json:"answer"`
	Question      *Question         `json:"question"`
	CorrectAnswer interface{}       `json:"correct_answer,omitempty"`
}

// PerformanceStats for submission analysis
type PerformanceStats struct {
	TotalQuestions   int      `json:"total_questions"`
	CorrectAnswers   int      `json:"correct_answers"`
	IncorrectAnswers int      `json:"incorrect_answers"`
	SkippedAnswers   int      `json:"skipped_answers"`
	Accuracy         float64  `json:"accuracy"`
	Score            float64  `json:"score"`
	Percentage       float64  `json:"percentage"`
	BandScore        *float64 `json:"band_score,omitempty"` // IELTS band score
	IsPassed         bool     `json:"is_passed"`
	TimeSpentSeconds int      `json:"time_spent_seconds"`
	AverageTimePerQ  float64  `json:"average_time_per_question"`
}

// CreateExerciseRequest for creating new exercise
type CreateExerciseRequest struct {
	Title                string     `json:"title" binding:"required"`
	Slug                 string     `json:"slug" binding:"required"`
	Description          *string    `json:"description"`
	ExerciseType         string     `json:"exercise_type" binding:"required"`
	SkillType            string     `json:"skill_type" binding:"required"`
	Difficulty           string     `json:"difficulty" binding:"required"`
	IELTSLevel           *string    `json:"ielts_level"`
	TimeLimitMinutes     *int       `json:"time_limit_minutes"`
	ThumbnailURL         *string    `json:"thumbnail_url"`
	AudioURL             *string    `json:"audio_url"`
	AudioDurationSeconds *int       `json:"audio_duration_seconds"`
	PassageCount         *int       `json:"passage_count"`
	CourseID             *uuid.UUID `json:"course_id"`
	ModuleID             *uuid.UUID `json:"module_id"`
	PassingScore         *float64   `json:"passing_score"`
	IsFree               *bool      `json:"is_free"`
}

// UpdateExerciseRequest for updating exercise
type UpdateExerciseRequest struct {
	Title            *string  `json:"title"`
	Description      *string  `json:"description"`
	Difficulty       *string  `json:"difficulty"`
	TimeLimitMinutes *int     `json:"time_limit_minutes"`
	ThumbnailURL     *string  `json:"thumbnail_url"`
	PassingScore     *float64 `json:"passing_score"`
	IsFree           *bool    `json:"is_free"`
	IsPublished      *bool    `json:"is_published"`
}

// CreateSectionRequest for creating exercise sections
type CreateSectionRequest struct {
	Title            string  `json:"title" binding:"required"`
	Description      *string `json:"description"`
	SectionNumber    int     `json:"section_number" binding:"required"`
	AudioURL         *string `json:"audio_url"`
	AudioStartTime   *int    `json:"audio_start_time"`
	AudioEndTime     *int    `json:"audio_end_time"`
	Transcript       *string `json:"transcript"`
	PassageTitle     *string `json:"passage_title"`
	PassageContent   *string `json:"passage_content"`
	PassageWordCount *int    `json:"passage_word_count"`
	Instructions     *string `json:"instructions"`
	TimeLimitMinutes *int    `json:"time_limit_minutes"`
	DisplayOrder     int     `json:"display_order"`
}

// CreateQuestionRequest for adding questions to exercise
type CreateQuestionRequest struct {
	ExerciseID     uuid.UUID  `json:"exercise_id" binding:"required"`
	SectionID      *uuid.UUID `json:"section_id"`
	QuestionNumber int        `json:"question_number" binding:"required"`
	QuestionText   string     `json:"question_text" binding:"required"`
	QuestionType   string     `json:"question_type" binding:"required"`
	AudioURL       *string    `json:"audio_url"`
	ImageURL       *string    `json:"image_url"`
	ContextText    *string    `json:"context_text"`
	Points         *float64   `json:"points"`
	Difficulty     *string    `json:"difficulty"`
	Explanation    *string    `json:"explanation"`
	Tips           *string    `json:"tips"`
	DisplayOrder   int        `json:"display_order"`
}

// CreateQuestionOptionRequest for adding options to multiple choice questions
type CreateQuestionOptionRequest struct {
	OptionLabel    string  `json:"option_label" binding:"required"` // A, B, C, D
	OptionText     string  `json:"option_text" binding:"required"`
	OptionImageURL *string `json:"option_image_url"`
	IsCorrect      bool    `json:"is_correct"`
	DisplayOrder   int     `json:"display_order"`
}

// CreateQuestionAnswerRequest for text-based questions
type CreateQuestionAnswerRequest struct {
	AnswerText         string   `json:"answer_text" binding:"required"`
	AlternativeAnswers []string `json:"alternative_answers"`
	IsCaseSensitive    bool     `json:"is_case_sensitive"`
	MatchingOrder      *int     `json:"matching_order"`
}

// MySubmissionsResponse for user's submission history
type MySubmissionsResponse struct {
	Submissions []SubmissionWithExercise `json:"submissions"`
	Total       int                      `json:"total"`
}

// SubmissionWithExercise includes submission with exercise details
type SubmissionWithExercise struct {
	Submission *Submission `json:"submission"`
	Exercise   *Exercise   `json:"exercise"`
}
