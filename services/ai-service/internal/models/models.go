package models

import (
	"time"

	"github.com/google/uuid"
)

// Writing Submission
type WritingSubmission struct {
	ID             uuid.UUID  `json:"id" db:"id"`
	UserID         uuid.UUID  `json:"user_id" db:"user_id"`
	TaskType       string     `json:"task_type" db:"task_type"` // task1, task2
	TaskPromptID   *uuid.UUID `json:"task_prompt_id" db:"task_prompt_id"`
	TaskPromptText string     `json:"task_prompt_text" db:"task_prompt_text"`
	EssayText      string     `json:"essay_text" db:"essay_text"`
	WordCount      int        `json:"word_count" db:"word_count"`
	TimeSpentSeconds *int       `json:"time_spent_seconds" db:"time_spent_seconds"`
	SubmittedFrom  string     `json:"submitted_from" db:"submitted_from"` // web, android, ios
	Status         string     `json:"status" db:"status"`                 // pending, processing, completed, failed
	ExerciseID     *uuid.UUID `json:"exercise_id" db:"exercise_id"`
	CourseID       *uuid.UUID `json:"course_id" db:"course_id"`
	LessonID       *uuid.UUID `json:"lesson_id" db:"lesson_id"`
	SubmittedAt    time.Time  `json:"submitted_at" db:"submitted_at"`
	EvaluatedAt    *time.Time `json:"evaluated_at" db:"evaluated_at"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at" db:"updated_at"`
}

// Writing Evaluation
type WritingEvaluation struct {
	ID                      uuid.UUID              `json:"id" db:"id"`
	SubmissionID            uuid.UUID              `json:"submission_id" db:"submission_id"`
	OverallBandScore        float64                `json:"overall_band_score" db:"overall_band_score"`
	TaskAchievementScore    float64                `json:"task_achievement_score" db:"task_achievement_score"`
	CoherenceCohesionScore  float64                `json:"coherence_cohesion_score" db:"coherence_cohesion_score"`
	LexicalResourceScore    float64                `json:"lexical_resource_score" db:"lexical_resource_score"`
	GrammarAccuracyScore    float64                `json:"grammar_accuracy_score" db:"grammar_accuracy_score"`
	Strengths               []string               `json:"strengths" db:"strengths"`
	Weaknesses              []string               `json:"weaknesses" db:"weaknesses"`
	GrammarErrors           map[string]interface{} `json:"grammar_errors" db:"grammar_errors"` // JSONB
	GrammarErrorCount       int                    `json:"grammar_error_count" db:"grammar_error_count"`
	VocabularyLevel         string                 `json:"vocabulary_level" db:"vocabulary_level"`
	VocabularyRangeScore    *float64               `json:"vocabulary_range_score" db:"vocabulary_range_score"`
	VocabularySuggestions   map[string]interface{} `json:"vocabulary_suggestions" db:"vocabulary_suggestions"` // JSONB
	ParagraphCount          *int                   `json:"paragraph_count" db:"paragraph_count"`
	HasIntroduction         bool                   `json:"has_introduction" db:"has_introduction"`
	HasConclusion           bool                   `json:"has_conclusion" db:"has_conclusion"`
	StructureFeedback       *string                `json:"structure_feedback" db:"structure_feedback"`
	LinkingWordsUsed        []string               `json:"linking_words_used" db:"linking_words_used"`
	CoherenceFeedback       *string                `json:"coherence_feedback" db:"coherence_feedback"`
	AddressesAllParts       bool                   `json:"addresses_all_parts" db:"addresses_all_parts"`
	TaskResponseFeedback    *string                `json:"task_response_feedback" db:"task_response_feedback"`
	DetailedFeedback        string                 `json:"detailed_feedback" db:"detailed_feedback"`
	ImprovementSuggestions   []string               `json:"improvement_suggestions" db:"improvement_suggestions"`
	AIModelName             *string                `json:"ai_model_name" db:"ai_model_name"`
	AIModelVersion          *string                `json:"ai_model_version" db:"ai_model_version"`
	ConfidenceScore         *float64               `json:"confidence_score" db:"confidence_score"`
	ProcessingTimeMs       *int                   `json:"processing_time_ms" db:"processing_time_ms"`
	CreatedAt               time.Time              `json:"created_at" db:"created_at"`
}

// Speaking Submission
type SpeakingSubmission struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	UserID               uuid.UUID  `json:"user_id" db:"user_id"`
	PartNumber           int        `json:"part_number" db:"part_number"` // 1, 2, 3
	TaskPromptID         *uuid.UUID `json:"task_prompt_id" db:"task_prompt_id"`
	TaskPromptText       string     `json:"task_prompt_text" db:"task_prompt_text"`
	AudioURL             string     `json:"audio_url" db:"audio_url"`
	AudioDurationSeconds int        `json:"audio_duration_seconds" db:"audio_duration_seconds"`
	AudioFormat          *string    `json:"audio_format" db:"audio_format"`
	AudioFileSizeBytes   *int64     `json:"audio_file_size_bytes" db:"audio_file_size_bytes"`
	TranscriptText       *string    `json:"transcript_text" db:"transcript_text"`
	TranscriptWordCount  *int       `json:"transcript_word_count" db:"transcript_word_count"`
	RecordedFrom         string     `json:"recorded_from" db:"recorded_from"` // web, android, ios
	Status               string     `json:"status" db:"status"`                 // pending, transcribing, processing, completed, failed
	ExerciseID           *uuid.UUID `json:"exercise_id" db:"exercise_id"`
	CourseID             *uuid.UUID `json:"course_id" db:"course_id"`
	LessonID             *uuid.UUID `json:"lesson_id" db:"lesson_id"`
	SubmittedAt          time.Time  `json:"submitted_at" db:"submitted_at"`
	TranscribedAt        *time.Time `json:"transcribed_at" db:"transcribed_at"`
	EvaluatedAt          *time.Time `json:"evaluated_at" db:"evaluated_at"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// Speaking Evaluation
type SpeakingEvaluation struct {
	ID                        uuid.UUID              `json:"id" db:"id"`
	SubmissionID              uuid.UUID              `json:"submission_id" db:"submission_id"`
	OverallBandScore          float64                `json:"overall_band_score" db:"overall_band_score"`
	FluencyCoherenceScore    float64                `json:"fluency_coherence_score" db:"fluency_coherence_score"`
	LexicalResourceScore      float64                `json:"lexical_resource_score" db:"lexical_resource_score"`
	GrammarAccuracyScore      float64                `json:"grammar_accuracy_score" db:"grammar_accuracy_score"`
	PronunciationScore        float64                `json:"pronunciation_score" db:"pronunciation_score"`
	PronunciationAccuracy     *float64               `json:"pronunciation_accuracy" db:"pronunciation_accuracy"`
	ProblematicSounds         map[string]interface{} `json:"problematic_sounds" db:"problematic_sounds"` // JSONB
	IntonationScore           *float64               `json:"intonation_score" db:"intonation_score"`
	StressAccuracy            *float64               `json:"stress_accuracy" db:"stress_accuracy"`
	SpeechRateWpm             *int                   `json:"speech_rate_wpm" db:"speech_rate_wpm"`
	PauseFrequency            *float64               `json:"pause_frequency" db:"pause_frequency"`
	FillerWordsCount          *int                   `json:"filler_words_count" db:"filler_words_count"`
	FillerWordsUsed           []string               `json:"filler_words_used" db:"filler_words_used"`
	HesitationCount           *int                   `json:"hesitation_count" db:"hesitation_count"`
	VocabularyLevel           *string                `json:"vocabulary_level" db:"vocabulary_level"`
	UniqueWordsCount          *int                   `json:"unique_words_count" db:"unique_words_count"`
	AdvancedWordsUsed         []string               `json:"advanced_words_used" db:"advanced_words_used"`
	VocabularySuggestions     map[string]interface{} `json:"vocabulary_suggestions" db:"vocabulary_suggestions"` // JSONB
	GrammarErrors             map[string]interface{} `json:"grammar_errors" db:"grammar_errors"` // JSONB
	GrammarErrorCount         int                    `json:"grammar_error_count" db:"grammar_error_count"`
	SentenceComplexity        *string                `json:"sentence_complexity" db:"sentence_complexity"`
	AnswersQuestionDirectly   bool                   `json:"answers_question_directly" db:"answers_question_directly"`
	UsesLinkingDevices         bool                   `json:"uses_linking_devices" db:"uses_linking_devices"`
	CoherenceFeedback          *string                `json:"coherence_feedback" db:"coherence_feedback"`
	ContentRelevanceScore     *float64               `json:"content_relevance_score" db:"content_relevance_score"`
	IdeaDevelopmentScore       *float64               `json:"idea_development_score" db:"idea_development_score"`
	ContentFeedback            *string                `json:"content_feedback" db:"content_feedback"`
	Strengths                  []string               `json:"strengths" db:"strengths"`
	Weaknesses                 []string               `json:"weaknesses" db:"weaknesses"`
	DetailedFeedback           string                 `json:"detailed_feedback" db:"detailed_feedback"`
	ImprovementSuggestions     []string               `json:"improvement_suggestions" db:"improvement_suggestions"`
	TranscriptionModel         *string                `json:"transcription_model" db:"transcription_model"`
	EvaluationModel           *string                `json:"evaluation_model" db:"evaluation_model"`
	ModelVersion               *string                `json:"model_version" db:"model_version"`
	ConfidenceScore            *float64               `json:"confidence_score" db:"confidence_score"`
	TranscriptionTimeMs        *int                   `json:"transcription_time_ms" db:"transcription_time_ms"`
	EvaluationTimeMs          *int                   `json:"evaluation_time_ms" db:"evaluation_time_ms"`
	CreatedAt                  time.Time              `json:"created_at" db:"created_at"`
}

// Writing Prompt
type WritingPrompt struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	TaskType         string     `json:"task_type" db:"task_type"` // task1, task2
	PromptText       string     `json:"prompt_text" db:"prompt_text"`
	VisualType       *string    `json:"visual_type" db:"visual_type"` // bar_chart, line_graph, pie_chart, table, diagram, map, process
	VisualURL        *string    `json:"visual_url" db:"visual_url"`
	Topic            *string    `json:"topic" db:"topic"`
	Difficulty       *string    `json:"difficulty" db:"difficulty"` // easy, medium, hard
	HasSampleAnswer  bool       `json:"has_sample_answer" db:"has_sample_answer"`
	SampleAnswerText *string     `json:"sample_answer_text" db:"sample_answer_text"`
	SampleAnswerBandScore *float64 `json:"sample_answer_band_score" db:"sample_answer_band_score"`
	TimesUsed        int        `json:"times_used" db:"times_used"`
	AverageScore     *float64   `json:"average_score" db:"average_score"`
	IsPublished      bool       `json:"is_published" db:"is_published"`
	CreatedBy        *uuid.UUID `json:"created_by" db:"created_by"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}

// Speaking Prompt
type SpeakingPrompt struct {
	ID                  uuid.UUID  `json:"id" db:"id"`
	PartNumber          int        `json:"part_number" db:"part_number"` // 1, 2, 3
	PromptText          string     `json:"prompt_text" db:"prompt_text"`
	CueCardTopic        *string    `json:"cue_card_topic" db:"cue_card_topic"`
	CueCardPoints       []string   `json:"cue_card_points" db:"cue_card_points"`
	PreparationTimeSeconds *int    `json:"preparation_time_seconds" db:"preparation_time_seconds"`
	SpeakingTimeSeconds *int       `json:"speaking_time_seconds" db:"speaking_time_seconds"`
	FollowUpQuestions   []string   `json:"follow_up_questions" db:"follow_up_questions"`
	TopicCategory       *string    `json:"topic_category" db:"topic_category"`
	Difficulty          *string    `json:"difficulty" db:"difficulty"`
	HasSampleAnswer     bool       `json:"has_sample_answer" db:"has_sample_answer"`
	SampleAnswerText    *string    `json:"sample_answer_text" db:"sample_answer_text"`
	SampleAnswerAudioURL *string   `json:"sample_answer_audio_url" db:"sample_answer_audio_url"`
	SampleAnswerBandScore *float64 `json:"sample_answer_band_score" db:"sample_answer_band_score"`
	TimesUsed           int        `json:"times_used" db:"times_used"`
	AverageScore        *float64   `json:"average_score" db:"average_score"`
	IsPublished         bool       `json:"is_published" db:"is_published"`
	CreatedBy           *uuid.UUID `json:"created_by" db:"created_by"`
	CreatedAt           time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at" db:"updated_at"`
}

