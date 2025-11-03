package models

import (
	"github.com/google/uuid"
)

// Writing Submission Request
type WritingSubmissionRequest struct {
	TaskType       string     `json:"task_type" binding:"required"` // task1, task2
	TaskPromptID   *uuid.UUID `json:"task_prompt_id"`
	TaskPromptText string     `json:"task_prompt_text" binding:"required"`
	EssayText      string     `json:"essay_text" binding:"required"`
	TimeSpentSeconds *int     `json:"time_spent_seconds"`
	ExerciseID     *uuid.UUID `json:"exercise_id"`
	CourseID       *uuid.UUID `json:"course_id"`
	LessonID       *uuid.UUID `json:"lesson_id"`
}

// Writing Submission Response
type WritingSubmissionResponse struct {
	Submission *WritingSubmission `json:"submission"`
	Evaluation *WritingEvaluation `json:"evaluation,omitempty"`
}

// Speaking Submission Request
type SpeakingSubmissionRequest struct {
	PartNumber         int        `json:"part_number" binding:"required"` // 1, 2, 3
	TaskPromptID       *uuid.UUID `json:"task_prompt_id"`
	TaskPromptText     string     `json:"task_prompt_text" binding:"required"`
	AudioURL           string     `json:"audio_url" binding:"required"`
	AudioDurationSeconds int      `json:"audio_duration_seconds" binding:"required"`
	AudioFormat        *string    `json:"audio_format"`
	AudioFileSizeBytes *int64     `json:"audio_file_size_bytes"`
	ExerciseID         *uuid.UUID `json:"exercise_id"`
	CourseID           *uuid.UUID `json:"course_id"`
	LessonID           *uuid.UUID `json:"lesson_id"`
}

// Speaking Submission Response
type SpeakingSubmissionResponse struct {
	Submission *SpeakingSubmission `json:"submission"`
	Evaluation *SpeakingEvaluation `json:"evaluation,omitempty"`
}

// OpenAI Evaluation Response (Writing)
type OpenAIWritingEvaluation struct {
	OverallBand     float64 `json:"overall_band"`
	CriteriaScores struct {
		TaskAchievement   float64 `json:"task_achievement"`
		CoherenceCohesion float64 `json:"coherence_cohesion"`
		LexicalResource   float64 `json:"lexical_resource"`
		GrammaticalRange  float64 `json:"grammatical_range"`
	} `json:"criteria_scores"`
	DetailedFeedback struct {
		TaskAchievement   string `json:"task_achievement"`
		CoherenceCohesion string `json:"coherence_cohesion"`
		LexicalResource   string `json:"lexical_resource"`
		GrammaticalRange  string `json:"grammatical_range"`
	} `json:"detailed_feedback"`
	ExaminerFeedback        string   `json:"examiner_feedback"`
	Strengths               []string `json:"strengths"`
	AreasForImprovement     []string `json:"areas_for_improvement"`
}

// OpenAI Evaluation Response (Speaking)
type OpenAISpeakingEvaluation struct {
	OverallBand     float64 `json:"overall_band"`
	CriteriaScores struct {
		FluencyCoherence   float64 `json:"fluency_coherence"`
		LexicalResource    float64 `json:"lexical_resource"`
		GrammaticalRange   float64 `json:"grammatical_range"`
		Pronunciation      float64 `json:"pronunciation"`
	} `json:"criteria_scores"`
	DetailedFeedback struct {
		FluencyCoherence struct {
			Score    float64 `json:"score"`
			Analysis string  `json:"analysis"`
		} `json:"fluency_coherence"`
		LexicalResource struct {
			Score    float64 `json:"score"`
			Analysis string  `json:"analysis"`
		} `json:"lexical_resource"`
		GrammaticalRange struct {
			Score    float64 `json:"score"`
			Analysis string  `json:"analysis"`
		} `json:"grammatical_range"`
		Pronunciation struct {
			Score    float64 `json:"score"`
			Analysis string  `json:"analysis"`
		} `json:"pronunciation"`
	} `json:"detailed_feedback"`
	ExaminerFeedback        string   `json:"examiner_feedback"`
	Strengths              []string `json:"strengths"`
	AreasForImprovement    []string `json:"areas_for_improvement"`
}

// OpenAI Transcription Response
type OpenAITranscription struct {
	Text     string `json:"text"`
	Duration float64 `json:"duration"`
	Words    []struct {
		Word  string  `json:"word"`
		Start float64 `json:"start"`
		End   float64 `json:"end"`
	} `json:"words"`
}

// Writing Prompt Request (Admin)
type WritingPromptRequest struct {
	TaskType         string     `json:"task_type" binding:"required"`
	PromptText       string     `json:"prompt_text" binding:"required"`
	VisualType       *string    `json:"visual_type"`
	VisualURL        *string    `json:"visual_url"`
	Topic            *string    `json:"topic"`
	Difficulty       *string    `json:"difficulty"`
	HasSampleAnswer  bool       `json:"has_sample_answer"`
	SampleAnswerText *string    `json:"sample_answer_text"`
	SampleAnswerBandScore *float64 `json:"sample_answer_band_score"`
	IsPublished      bool       `json:"is_published"`
}

// Speaking Prompt Request (Admin)
type SpeakingPromptRequest struct {
	PartNumber          int      `json:"part_number" binding:"required"`
	PromptText          string   `json:"prompt_text" binding:"required"`
	CueCardTopic        *string  `json:"cue_card_topic"`
	CueCardPoints       []string `json:"cue_card_points"`
	PreparationTimeSeconds *int  `json:"preparation_time_seconds"`
	SpeakingTimeSeconds *int    `json:"speaking_time_seconds"`
	FollowUpQuestions   []string `json:"follow_up_questions"`
	TopicCategory       *string  `json:"topic_category"`
	Difficulty          *string  `json:"difficulty"`
	HasSampleAnswer     bool     `json:"has_sample_answer"`
	SampleAnswerText    *string  `json:"sample_answer_text"`
	SampleAnswerAudioURL *string `json:"sample_answer_audio_url"`
	SampleAnswerBandScore *float64 `json:"sample_answer_band_score"`
	IsPublished         bool     `json:"is_published"`
}

