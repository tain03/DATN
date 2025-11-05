package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/database"
	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type AIRepository struct {
	db     *database.Database
	config *config.Config
}

func NewAIRepository(db *database.Database, cfg *config.Config) *AIRepository {
	return &AIRepository{db: db, config: cfg}
}

// Writing Submission
func (r *AIRepository) CreateWritingSubmission(submission *models.WritingSubmission) error {
	query := `
		INSERT INTO writing_submissions (
			id, user_id, task_type, task_prompt_id, task_prompt_text,
			essay_text, word_count, time_spent_seconds, submitted_from,
			status, exercise_id, course_id, lesson_id, submitted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`
	_, err := r.db.DB.Exec(query,
		submission.ID, submission.UserID, submission.TaskType,
		submission.TaskPromptID, submission.TaskPromptText,
		submission.EssayText, submission.WordCount, submission.TimeSpentSeconds,
		submission.SubmittedFrom, submission.Status,
		submission.ExerciseID, submission.CourseID, submission.LessonID,
		submission.SubmittedAt,
	)
	return err
}

func (r *AIRepository) GetWritingSubmission(id uuid.UUID) (*models.WritingSubmission, error) {
	var s models.WritingSubmission
	query := `SELECT * FROM writing_submissions WHERE id = $1`
	err := r.db.DB.QueryRow(query, id).Scan(
		&s.ID, &s.UserID, &s.TaskType, &s.TaskPromptID, &s.TaskPromptText,
		&s.EssayText, &s.WordCount, &s.TimeSpentSeconds, &s.SubmittedFrom,
		&s.Status, &s.ExerciseID, &s.CourseID, &s.LessonID,
		&s.SubmittedAt, &s.EvaluatedAt, &s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *AIRepository) UpdateWritingSubmissionStatus(id uuid.UUID, status string) error {
	query := `UPDATE writing_submissions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	_, err := r.db.DB.Exec(query, status, id)
	return err
}

func (r *AIRepository) CreateWritingEvaluation(eval *models.WritingEvaluation) error {
	// Convert slices to PostgreSQL arrays for TEXT[] columns
	strengthsArray := pq.Array(eval.Strengths)
	weaknessesArray := pq.Array(eval.Weaknesses)
	linkingWordsArray := pq.Array(eval.LinkingWordsUsed)
	improvementsArray := pq.Array(eval.ImprovementSuggestions)

	// Keep JSON for JSONB columns
	grammarErrorsJSON, _ := json.Marshal(eval.GrammarErrors)
	vocabSuggestionsJSON, _ := json.Marshal(eval.VocabularySuggestions)
	var detailedFeedbackJSONBytes []byte
	if eval.DetailedFeedbackJSON != nil {
		detailedFeedbackJSONBytes, _ = json.Marshal(eval.DetailedFeedbackJSON)
	}

	query := `
		INSERT INTO writing_evaluations (
			id, submission_id, overall_band_score,
			task_achievement_score, coherence_cohesion_score,
			lexical_resource_score, grammar_accuracy_score,
			strengths, weaknesses, grammar_errors, grammar_error_count,
			vocabulary_level, vocabulary_range_score, vocabulary_suggestions,
			paragraph_count, has_introduction, has_conclusion,
			structure_feedback, linking_words_used, coherence_feedback,
			addresses_all_parts, task_response_feedback,
			detailed_feedback, detailed_feedback_json, improvement_suggestions,
			ai_model_name, ai_model_version, confidence_score, processing_time_ms
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
			$15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29
		)
	`
	_, err := r.db.DB.Exec(query,
		eval.ID, eval.SubmissionID, eval.OverallBandScore,
		eval.TaskAchievementScore, eval.CoherenceCohesionScore,
		eval.LexicalResourceScore, eval.GrammarAccuracyScore,
		strengthsArray, weaknessesArray, grammarErrorsJSON, eval.GrammarErrorCount,
		eval.VocabularyLevel, eval.VocabularyRangeScore, vocabSuggestionsJSON,
		eval.ParagraphCount, eval.HasIntroduction, eval.HasConclusion,
		eval.StructureFeedback, linkingWordsArray, eval.CoherenceFeedback,
		eval.AddressesAllParts, eval.TaskResponseFeedback,
		eval.DetailedFeedback, detailedFeedbackJSONBytes, improvementsArray,
		eval.AIModelName, eval.AIModelVersion, eval.ConfidenceScore, eval.ProcessingTimeMs,
	)
	return err
}

func (r *AIRepository) GetWritingEvaluation(submissionID uuid.UUID) (*models.WritingEvaluation, error) {
	var eval models.WritingEvaluation
	var strengthsJSON, weaknessesJSON, grammarErrorsJSON, vocabSuggestionsJSON sql.NullString
	var linkingWordsJSON, improvementsJSON, detailedFeedbackJSON sql.NullString

	query := `SELECT 
		id, submission_id, overall_band_score,
		task_achievement_score, coherence_cohesion_score,
		lexical_resource_score, grammar_accuracy_score,
		strengths, weaknesses, grammar_errors, grammar_error_count,
		vocabulary_level, vocabulary_range_score, vocabulary_suggestions,
		paragraph_count, has_introduction, has_conclusion,
		structure_feedback, linking_words_used, coherence_feedback,
		addresses_all_parts, task_response_feedback,
		detailed_feedback, detailed_feedback_json, improvement_suggestions,
		ai_model_name, ai_model_version, confidence_score,
		processing_time_ms, created_at
		FROM writing_evaluations WHERE submission_id = $1`
	err := r.db.DB.QueryRow(query, submissionID).Scan(
		&eval.ID, &eval.SubmissionID, &eval.OverallBandScore,
		&eval.TaskAchievementScore, &eval.CoherenceCohesionScore,
		&eval.LexicalResourceScore, &eval.GrammarAccuracyScore,
		&strengthsJSON, &weaknessesJSON, &grammarErrorsJSON, &eval.GrammarErrorCount,
		&eval.VocabularyLevel, &eval.VocabularyRangeScore, &vocabSuggestionsJSON,
		&eval.ParagraphCount, &eval.HasIntroduction, &eval.HasConclusion,
		&eval.StructureFeedback, &linkingWordsJSON, &eval.CoherenceFeedback,
		&eval.AddressesAllParts, &eval.TaskResponseFeedback,
		&eval.DetailedFeedback, &detailedFeedbackJSON, &improvementsJSON,
		&eval.AIModelName, &eval.AIModelVersion, &eval.ConfidenceScore,
		&eval.ProcessingTimeMs, &eval.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Parse JSON fields
	if strengthsJSON.Valid {
		json.Unmarshal([]byte(strengthsJSON.String), &eval.Strengths)
	}
	if weaknessesJSON.Valid {
		json.Unmarshal([]byte(weaknessesJSON.String), &eval.Weaknesses)
	}
	if grammarErrorsJSON.Valid {
		json.Unmarshal([]byte(grammarErrorsJSON.String), &eval.GrammarErrors)
	}
	if vocabSuggestionsJSON.Valid {
		json.Unmarshal([]byte(vocabSuggestionsJSON.String), &eval.VocabularySuggestions)
	}
	if linkingWordsJSON.Valid {
		json.Unmarshal([]byte(linkingWordsJSON.String), &eval.LinkingWordsUsed)
	}
	if improvementsJSON.Valid {
		json.Unmarshal([]byte(improvementsJSON.String), &eval.ImprovementSuggestions)
	}
	if detailedFeedbackJSON.Valid {
		json.Unmarshal([]byte(detailedFeedbackJSON.String), &eval.DetailedFeedbackJSON)
	}

	return &eval, nil
}

// Speaking Submission
func (r *AIRepository) CreateSpeakingSubmission(submission *models.SpeakingSubmission) error {
	query := `
		INSERT INTO speaking_submissions (
			id, user_id, part_number, task_prompt_id, task_prompt_text,
			audio_url, audio_duration_seconds, audio_format, audio_file_size_bytes,
			transcript_text, transcript_word_count, recorded_from,
			status, exercise_id, course_id, lesson_id, submitted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
	`
	_, err := r.db.DB.Exec(query,
		submission.ID, submission.UserID, submission.PartNumber,
		submission.TaskPromptID, submission.TaskPromptText,
		submission.AudioURL, submission.AudioDurationSeconds,
		submission.AudioFormat, submission.AudioFileSizeBytes,
		submission.TranscriptText, submission.TranscriptWordCount,
		submission.RecordedFrom, submission.Status,
		submission.ExerciseID, submission.CourseID, submission.LessonID,
		submission.SubmittedAt,
	)
	return err
}

func (r *AIRepository) GetSpeakingSubmission(id uuid.UUID) (*models.SpeakingSubmission, error) {
	var s models.SpeakingSubmission
	query := `SELECT * FROM speaking_submissions WHERE id = $1`
	err := r.db.DB.QueryRow(query, id).Scan(
		&s.ID, &s.UserID, &s.PartNumber, &s.TaskPromptID, &s.TaskPromptText,
		&s.AudioURL, &s.AudioDurationSeconds, &s.AudioFormat, &s.AudioFileSizeBytes,
		&s.TranscriptText, &s.TranscriptWordCount, &s.RecordedFrom,
		&s.Status, &s.ExerciseID, &s.CourseID, &s.LessonID,
		&s.SubmittedAt, &s.TranscribedAt, &s.EvaluatedAt,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *AIRepository) UpdateSpeakingSubmissionStatus(id uuid.UUID, status string) error {
	query := `UPDATE speaking_submissions SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	_, err := r.db.DB.Exec(query, status, id)
	return err
}

func (r *AIRepository) UpdateSpeakingSubmissionTranscript(id uuid.UUID, transcript string, wordCount int) error {
	query := `UPDATE speaking_submissions 
		SET transcript_text = $1, transcript_word_count = $2, 
		    transcribed_at = CURRENT_TIMESTAMP, status = 'processing',
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $3`
	_, err := r.db.DB.Exec(query, transcript, wordCount, id)
	return err
}

func (r *AIRepository) CreateSpeakingEvaluation(eval *models.SpeakingEvaluation) error {
	// Convert slices to PostgreSQL arrays for TEXT[] columns
	strengthsArray := pq.Array(eval.Strengths)
	weaknessesArray := pq.Array(eval.Weaknesses)
	fillerWordsArray := pq.Array(eval.FillerWordsUsed)
	advancedWordsArray := pq.Array(eval.AdvancedWordsUsed)
	improvementsArray := pq.Array(eval.ImprovementSuggestions)

	// Keep JSON for JSONB columns
	grammarErrorsJSON, _ := json.Marshal(eval.GrammarErrors)
	vocabSuggestionsJSON, _ := json.Marshal(eval.VocabularySuggestions)
	problematicSoundsJSON, _ := json.Marshal(eval.ProblematicSounds)

	query := `
		INSERT INTO speaking_evaluations (
			id, submission_id, overall_band_score,
			fluency_coherence_score, lexical_resource_score,
			grammar_accuracy_score, pronunciation_score,
			pronunciation_accuracy, problematic_sounds, intonation_score, stress_accuracy,
			speech_rate_wpm, pause_frequency, filler_words_count, filler_words_used, hesitation_count,
			vocabulary_level, unique_words_count, advanced_words_used, vocabulary_suggestions,
			grammar_errors, grammar_error_count, sentence_complexity,
			answers_question_directly, uses_linking_devices, coherence_feedback,
			content_relevance_score, idea_development_score, content_feedback,
			strengths, weaknesses, detailed_feedback, improvement_suggestions,
			transcription_model, evaluation_model, model_version, confidence_score,
			transcription_time_ms, evaluation_time_ms
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16,
			$17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29,
			$30, $31, $32, $33, $34, $35, $36, $37, $38, $39
		)
	`
	_, err := r.db.DB.Exec(query,
		eval.ID, eval.SubmissionID, eval.OverallBandScore,
		eval.FluencyCoherenceScore, eval.LexicalResourceScore,
		eval.GrammarAccuracyScore, eval.PronunciationScore,
		eval.PronunciationAccuracy, problematicSoundsJSON, eval.IntonationScore, eval.StressAccuracy,
		eval.SpeechRateWpm, eval.PauseFrequency, eval.FillerWordsCount, fillerWordsArray, eval.HesitationCount,
		eval.VocabularyLevel, eval.UniqueWordsCount, advancedWordsArray, vocabSuggestionsJSON,
		grammarErrorsJSON, eval.GrammarErrorCount, eval.SentenceComplexity,
		eval.AnswersQuestionDirectly, eval.UsesLinkingDevices, eval.CoherenceFeedback,
		eval.ContentRelevanceScore, eval.IdeaDevelopmentScore, eval.ContentFeedback,
		strengthsArray, weaknessesArray, eval.DetailedFeedback, improvementsArray,
		eval.TranscriptionModel, eval.EvaluationModel, eval.ModelVersion, eval.ConfidenceScore,
		eval.TranscriptionTimeMs, eval.EvaluationTimeMs,
	)
	return err
}

func (r *AIRepository) GetSpeakingEvaluation(submissionID uuid.UUID) (*models.SpeakingEvaluation, error) {
	var eval models.SpeakingEvaluation
	var strengthsJSON, weaknessesJSON, grammarErrorsJSON, vocabSuggestionsJSON sql.NullString
	var problematicSoundsJSON, fillerWordsJSON, advancedWordsJSON, improvementsJSON sql.NullString

	query := `SELECT * FROM speaking_evaluations WHERE submission_id = $1`
	err := r.db.DB.QueryRow(query, submissionID).Scan(
		&eval.ID, &eval.SubmissionID, &eval.OverallBandScore,
		&eval.FluencyCoherenceScore, &eval.LexicalResourceScore,
		&eval.GrammarAccuracyScore, &eval.PronunciationScore,
		&eval.PronunciationAccuracy, &problematicSoundsJSON, &eval.IntonationScore, &eval.StressAccuracy,
		&eval.SpeechRateWpm, &eval.PauseFrequency, &eval.FillerWordsCount, &fillerWordsJSON, &eval.HesitationCount,
		&eval.VocabularyLevel, &eval.UniqueWordsCount, &advancedWordsJSON, &vocabSuggestionsJSON,
		&grammarErrorsJSON, &eval.GrammarErrorCount, &eval.SentenceComplexity,
		&eval.AnswersQuestionDirectly, &eval.UsesLinkingDevices, &eval.CoherenceFeedback,
		&eval.ContentRelevanceScore, &eval.IdeaDevelopmentScore, &eval.ContentFeedback,
		&strengthsJSON, &weaknessesJSON, &eval.DetailedFeedback, &improvementsJSON,
		&eval.TranscriptionModel, &eval.EvaluationModel, &eval.ModelVersion, &eval.ConfidenceScore,
		&eval.TranscriptionTimeMs, &eval.EvaluationTimeMs, &eval.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Parse JSON fields
	if strengthsJSON.Valid {
		json.Unmarshal([]byte(strengthsJSON.String), &eval.Strengths)
	}
	if weaknessesJSON.Valid {
		json.Unmarshal([]byte(weaknessesJSON.String), &eval.Weaknesses)
	}
	if grammarErrorsJSON.Valid {
		json.Unmarshal([]byte(grammarErrorsJSON.String), &eval.GrammarErrors)
	}
	if vocabSuggestionsJSON.Valid {
		json.Unmarshal([]byte(vocabSuggestionsJSON.String), &eval.VocabularySuggestions)
	}
	if problematicSoundsJSON.Valid {
		json.Unmarshal([]byte(problematicSoundsJSON.String), &eval.ProblematicSounds)
	}
	if fillerWordsJSON.Valid {
		json.Unmarshal([]byte(fillerWordsJSON.String), &eval.FillerWordsUsed)
	}
	if advancedWordsJSON.Valid {
		json.Unmarshal([]byte(advancedWordsJSON.String), &eval.AdvancedWordsUsed)
	}
	if improvementsJSON.Valid {
		json.Unmarshal([]byte(improvementsJSON.String), &eval.ImprovementSuggestions)
	}

	return &eval, nil
}

// Get user submissions
func (r *AIRepository) GetUserWritingSubmissions(userID uuid.UUID, limit, offset int) ([]*models.WritingSubmission, error) {
	query := `SELECT * FROM writing_submissions 
		WHERE user_id = $1 ORDER BY submitted_at DESC LIMIT $2 OFFSET $3`
	rows, err := r.db.DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var submissions []*models.WritingSubmission
	for rows.Next() {
		var s models.WritingSubmission
		err := rows.Scan(
			&s.ID, &s.UserID, &s.TaskType, &s.TaskPromptID, &s.TaskPromptText,
			&s.EssayText, &s.WordCount, &s.TimeSpentSeconds, &s.SubmittedFrom,
			&s.Status, &s.ExerciseID, &s.CourseID, &s.LessonID,
			&s.SubmittedAt, &s.EvaluatedAt, &s.CreatedAt, &s.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		submissions = append(submissions, &s)
	}
	return submissions, nil
}

func (r *AIRepository) GetUserSpeakingSubmissions(userID uuid.UUID, limit, offset int) ([]*models.SpeakingSubmission, error) {
	query := `SELECT * FROM speaking_submissions 
		WHERE user_id = $1 ORDER BY submitted_at DESC LIMIT $2 OFFSET $3`
	rows, err := r.db.DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var submissions []*models.SpeakingSubmission
	for rows.Next() {
		var s models.SpeakingSubmission
		err := rows.Scan(
			&s.ID, &s.UserID, &s.PartNumber, &s.TaskPromptID, &s.TaskPromptText,
			&s.AudioURL, &s.AudioDurationSeconds, &s.AudioFormat, &s.AudioFileSizeBytes,
			&s.TranscriptText, &s.TranscriptWordCount, &s.RecordedFrom,
			&s.Status, &s.ExerciseID, &s.CourseID, &s.LessonID,
			&s.SubmittedAt, &s.TranscribedAt, &s.EvaluatedAt,
			&s.CreatedAt, &s.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		submissions = append(submissions, &s)
	}
	return submissions, nil
}

// Writing Prompts
func (r *AIRepository) CreateWritingPrompt(prompt *models.WritingPrompt) error {
	query := `
		INSERT INTO writing_prompts (
			id, task_type, prompt_text, visual_type, visual_url,
			topic, difficulty, has_sample_answer, sample_answer_text,
			sample_answer_band_score, is_published, created_by, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`
	_, err := r.db.DB.Exec(query,
		prompt.ID, prompt.TaskType, prompt.PromptText, prompt.VisualType, prompt.VisualURL,
		prompt.Topic, prompt.Difficulty, prompt.HasSampleAnswer, prompt.SampleAnswerText,
		prompt.SampleAnswerBandScore, prompt.IsPublished, prompt.CreatedBy,
		prompt.CreatedAt, prompt.UpdatedAt,
	)
	return err
}

func (r *AIRepository) GetWritingPrompt(id uuid.UUID) (*models.WritingPrompt, error) {
	var p models.WritingPrompt
	var averageScore sql.NullFloat64
	query := `SELECT * FROM writing_prompts WHERE id = $1`
	err := r.db.DB.QueryRow(query, id).Scan(
		&p.ID, &p.TaskType, &p.PromptText, &p.VisualType, &p.VisualURL,
		&p.Topic, &p.Difficulty, &p.HasSampleAnswer, &p.SampleAnswerText,
		&p.SampleAnswerBandScore, &p.TimesUsed, &averageScore,
		&p.IsPublished, &p.CreatedBy, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	if averageScore.Valid {
		p.AverageScore = &averageScore.Float64
	}
	return &p, nil
}

func (r *AIRepository) GetWritingPrompts(taskType *string, difficulty *string, isPublished *bool, limit, offset int) ([]*models.WritingPrompt, error) {
	query := `SELECT * FROM writing_prompts WHERE 1=1`
	args := []interface{}{}
	argIdx := 1

	if taskType != nil {
		args = append(args, *taskType)
		query += fmt.Sprintf(" AND task_type = $%d", argIdx)
		argIdx++
	}
	if difficulty != nil {
		args = append(args, *difficulty)
		query += fmt.Sprintf(" AND difficulty = $%d", argIdx)
		argIdx++
	}
	if isPublished != nil {
		args = append(args, *isPublished)
		query += fmt.Sprintf(" AND is_published = $%d", argIdx)
		argIdx++
	}

	args = append(args, limit, offset)
	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)

	rows, err := r.db.DB.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var prompts []*models.WritingPrompt
	for rows.Next() {
		var p models.WritingPrompt
		var averageScore sql.NullFloat64
		err := rows.Scan(
			&p.ID, &p.TaskType, &p.PromptText, &p.VisualType, &p.VisualURL,
			&p.Topic, &p.Difficulty, &p.HasSampleAnswer, &p.SampleAnswerText,
			&p.SampleAnswerBandScore, &p.TimesUsed, &averageScore,
			&p.IsPublished, &p.CreatedBy, &p.CreatedAt, &p.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan writing prompt: %w", err)
		}
		if averageScore.Valid {
			p.AverageScore = &averageScore.Float64
		}
		prompts = append(prompts, &p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}
	return prompts, nil
}

func (r *AIRepository) UpdateWritingPrompt(id uuid.UUID, prompt *models.WritingPrompt) error {
	query := `
		UPDATE writing_prompts SET
			task_type = COALESCE($1, task_type),
			prompt_text = COALESCE($2, prompt_text),
			visual_type = $3,
			visual_url = $4,
			topic = $5,
			difficulty = $6,
			has_sample_answer = COALESCE($7, has_sample_answer),
			sample_answer_text = $8,
			sample_answer_band_score = $9,
			is_published = COALESCE($10, is_published),
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $11
	`
	_, err := r.db.DB.Exec(query,
		prompt.TaskType, prompt.PromptText, prompt.VisualType, prompt.VisualURL,
		prompt.Topic, prompt.Difficulty, prompt.HasSampleAnswer, prompt.SampleAnswerText,
		prompt.SampleAnswerBandScore, prompt.IsPublished, id,
	)
	return err
}

func (r *AIRepository) DeleteWritingPrompt(id uuid.UUID) error {
	query := `DELETE FROM writing_prompts WHERE id = $1`
	_, err := r.db.DB.Exec(query, id)
	return err
}

// Speaking Prompts
func (r *AIRepository) CreateSpeakingPrompt(prompt *models.SpeakingPrompt) error {
	cueCardPointsArray := pq.Array(prompt.CueCardPoints)
	followUpQuestionsArray := pq.Array(prompt.FollowUpQuestions)

	query := `
		INSERT INTO speaking_prompts (
			id, part_number, prompt_text, cue_card_topic, cue_card_points,
			preparation_time_seconds, speaking_time_seconds, follow_up_questions,
			topic_category, difficulty, has_sample_answer, sample_answer_text,
			sample_answer_audio_url, sample_answer_band_score, is_published,
			created_by, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
	`
	_, err := r.db.DB.Exec(query,
		prompt.ID, prompt.PartNumber, prompt.PromptText, prompt.CueCardTopic, cueCardPointsArray,
		prompt.PreparationTimeSeconds, prompt.SpeakingTimeSeconds, followUpQuestionsArray,
		prompt.TopicCategory, prompt.Difficulty, prompt.HasSampleAnswer, prompt.SampleAnswerText,
		prompt.SampleAnswerAudioURL, prompt.SampleAnswerBandScore, prompt.IsPublished,
		prompt.CreatedBy, prompt.CreatedAt, prompt.UpdatedAt,
	)
	return err
}

func (r *AIRepository) GetSpeakingPrompt(id uuid.UUID) (*models.SpeakingPrompt, error) {
	var p models.SpeakingPrompt
	var cueCardPointsArray pq.StringArray
	var followUpQuestionsArray pq.StringArray
	var averageScore sql.NullFloat64

	query := `SELECT * FROM speaking_prompts WHERE id = $1`
	err := r.db.DB.QueryRow(query, id).Scan(
		&p.ID, &p.PartNumber, &p.PromptText, &p.CueCardTopic, &cueCardPointsArray,
		&p.PreparationTimeSeconds, &p.SpeakingTimeSeconds, &followUpQuestionsArray,
		&p.TopicCategory, &p.Difficulty, &p.HasSampleAnswer, &p.SampleAnswerText,
		&p.SampleAnswerAudioURL, &p.SampleAnswerBandScore, &p.TimesUsed, &averageScore,
		&p.IsPublished, &p.CreatedBy, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	if averageScore.Valid {
		p.AverageScore = &averageScore.Float64
	}
	p.CueCardPoints = []string(cueCardPointsArray)
	p.FollowUpQuestions = []string(followUpQuestionsArray)
	return &p, nil
}

func (r *AIRepository) GetSpeakingPrompts(partNumber *int, difficulty *string, isPublished *bool, limit, offset int) ([]*models.SpeakingPrompt, error) {
	query := `SELECT * FROM speaking_prompts WHERE 1=1`
	args := []interface{}{}
	argIdx := 1

	if partNumber != nil {
		args = append(args, *partNumber)
		query += fmt.Sprintf(" AND part_number = $%d", argIdx)
		argIdx++
	}
	if difficulty != nil {
		args = append(args, *difficulty)
		query += fmt.Sprintf(" AND difficulty = $%d", argIdx)
		argIdx++
	}
	if isPublished != nil {
		args = append(args, *isPublished)
		query += fmt.Sprintf(" AND is_published = $%d", argIdx)
		argIdx++
	}

	args = append(args, limit, offset)
	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)

	rows, err := r.db.DB.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var prompts []*models.SpeakingPrompt
	for rows.Next() {
		var p models.SpeakingPrompt
		var cueCardPointsArray pq.StringArray
		var followUpQuestionsArray pq.StringArray
		var averageScore sql.NullFloat64

		err := rows.Scan(
			&p.ID, &p.PartNumber, &p.PromptText, &p.CueCardTopic, &cueCardPointsArray,
			&p.PreparationTimeSeconds, &p.SpeakingTimeSeconds, &followUpQuestionsArray,
			&p.TopicCategory, &p.Difficulty, &p.HasSampleAnswer, &p.SampleAnswerText,
			&p.SampleAnswerAudioURL, &p.SampleAnswerBandScore, &p.TimesUsed, &averageScore,
			&p.IsPublished, &p.CreatedBy, &p.CreatedAt, &p.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan speaking prompt: %w", err)
		}

		if averageScore.Valid {
			p.AverageScore = &averageScore.Float64
		}
		p.CueCardPoints = []string(cueCardPointsArray)
		p.FollowUpQuestions = []string(followUpQuestionsArray)
		prompts = append(prompts, &p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}
	return prompts, nil
}

func (r *AIRepository) UpdateSpeakingPrompt(id uuid.UUID, prompt *models.SpeakingPrompt) error {
	cueCardPointsArray := pq.Array(prompt.CueCardPoints)
	followUpQuestionsArray := pq.Array(prompt.FollowUpQuestions)

	query := `
		UPDATE speaking_prompts SET
			part_number = COALESCE($1, part_number),
			prompt_text = COALESCE($2, prompt_text),
			cue_card_topic = $3,
			cue_card_points = $4,
			preparation_time_seconds = $5,
			speaking_time_seconds = $6,
			follow_up_questions = $7,
			topic_category = $8,
			difficulty = $9,
			has_sample_answer = COALESCE($10, has_sample_answer),
			sample_answer_text = $11,
			sample_answer_audio_url = $12,
			sample_answer_band_score = $13,
			is_published = COALESCE($14, is_published),
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $15
	`
	_, err := r.db.DB.Exec(query,
		prompt.PartNumber, prompt.PromptText, prompt.CueCardTopic, cueCardPointsArray,
		prompt.PreparationTimeSeconds, prompt.SpeakingTimeSeconds, followUpQuestionsArray,
		prompt.TopicCategory, prompt.Difficulty, prompt.HasSampleAnswer,
		prompt.SampleAnswerText, prompt.SampleAnswerAudioURL, prompt.SampleAnswerBandScore,
		prompt.IsPublished, id,
	)
	return err
}

func (r *AIRepository) DeleteSpeakingPrompt(id uuid.UUID) error {
	query := `DELETE FROM speaking_prompts WHERE id = $1`
	_, err := r.db.DB.Exec(query, id)
	return err
}

// ========== CACHE METHODS (Phase 5.3) ==========

// CacheEntry for storing evaluation results
type CacheEntry struct {
	Hash      string // Using content_hash from ai_evaluation_cache
	Content   string // Serialized JSON from detailed_scores + feedback
	ExpiresAt sql.NullTime
}

// GetCachedEvaluation retrieves cached evaluation by content_hash
func (r *AIRepository) GetCachedEvaluation(hash string) (*CacheEntry, error) {
	query := `
		SELECT 
			content_hash,
			COALESCE(
				jsonb_build_object(
					'overall_band', overall_band_score,
					'criteria_scores', detailed_scores,
					'detailed_feedback', feedback,
					'examiner_feedback', feedback->>'examiner_feedback',
					'strengths', feedback->'strengths',
					'areas_for_improvement', feedback->'areas_for_improvement'
				)::text,
				'{}'
			) as content,
			expires_at
		FROM ai_evaluation_cache 
		WHERE content_hash = $1 AND (expires_at IS NULL OR expires_at > NOW())
		LIMIT 1
	`

	var entry CacheEntry
	err := r.db.DB.QueryRow(query, hash).Scan(&entry.Hash, &entry.Content, &entry.ExpiresAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	// Update hit_count and last_hit_at
	go func() {
		updateQuery := `UPDATE ai_evaluation_cache SET hit_count = hit_count + 1, last_hit_at = NOW() WHERE content_hash = $1`
		r.db.DB.Exec(updateQuery, hash)
	}()

	return &entry, nil
}

// SaveCachedEvaluation saves evaluation result to cache
func (r *AIRepository) SaveCachedEvaluation(hash, content string, expiresAt interface{}) error {
	// Parse content to extract fields for ai_evaluation_cache schema
	var evalData map[string]interface{}
	if err := json.Unmarshal([]byte(content), &evalData); err != nil {
		return fmt.Errorf("failed to parse evaluation content: %w", err)
	}

	// Extract fields
	overallBand, _ := evalData["overall_band"].(float64)
	criteriaScores, _ := json.Marshal(evalData["criteria_scores"])
	feedback, _ := json.Marshal(evalData)

	// Determine skill_type from criteria_scores structure
	skillType := "writing"
	if criteriaScoresMap, ok := evalData["criteria_scores"].(map[string]interface{}); ok {
		if _, hasTC := criteriaScoresMap["task_achievement"]; hasTC {
			skillType = "writing"
		} else if _, hasFC := criteriaScoresMap["fluency_coherence"]; hasFC {
			skillType = "speaking"
		}
	}

	query := `
		INSERT INTO ai_evaluation_cache (
			content_hash, skill_type, task_type, overall_band_score,
			detailed_scores, feedback, expires_at, created_at
		)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, $7, NOW())
		ON CONFLICT (content_hash) 
		DO UPDATE SET 
			overall_band_score = $4,
			detailed_scores = $5::jsonb,
			feedback = $6::jsonb,
			expires_at = $7,
			hit_count = ai_evaluation_cache.hit_count + 1,
			last_hit_at = NOW()
	`
	_, err := r.db.DB.Exec(query, hash, skillType, "task2", overallBand, string(criteriaScores), string(feedback), expiresAt)
	return err
}

// DeleteCachedEvaluation removes cached entry
func (r *AIRepository) DeleteCachedEvaluation(hash string) error {
	query := `DELETE FROM ai_evaluation_cache WHERE content_hash = $1`
	_, err := r.db.DB.Exec(query, hash)
	return err
}

// GetCacheStatistics returns cache statistics
func (r *AIRepository) GetCacheStatistics() (map[string]interface{}, error) {
	query := `
		SELECT 
			COUNT(*) as total_entries,
			COUNT(*) FILTER (WHERE expires_at < NOW()) as expired_entries,
			COUNT(*) FILTER (WHERE expires_at >= NOW() OR expires_at IS NULL) as valid_entries,
			SUM(hit_count) as total_hits,
			AVG(hit_count) as avg_hits_per_entry,
			COUNT(*) FILTER (WHERE skill_type = 'writing') as writing_entries,
			COUNT(*) FILTER (WHERE skill_type = 'speaking') as speaking_entries,
			ROUND(pg_total_relation_size('ai_evaluation_cache')::numeric / 1024 / 1024, 2) as cache_size_mb
		FROM ai_evaluation_cache
	`

	var total, expired, valid, totalHits, writingEntries, speakingEntries int
	var avgHits, sizeMB float64
	err := r.db.DB.QueryRow(query).Scan(&total, &expired, &valid, &totalHits, &avgHits, &writingEntries, &speakingEntries, &sizeMB)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"total_entries":      total,
		"expired_entries":    expired,
		"valid_entries":      valid,
		"total_hits":         totalHits,
		"avg_hits_per_entry": avgHits,
		"writing_entries":    writingEntries,
		"speaking_entries":   speakingEntries,
		"cache_size_mb":      sizeMB,
	}, nil
}
