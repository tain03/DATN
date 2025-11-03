package service

import (
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
	"github.com/bisosad1501/DATN/services/ai-service/internal/repository"
	"github.com/google/uuid"
)

type AIService struct {
	repo                 *repository.AIRepository
	config               *config.Config
	openAIClient         *OpenAIClient
	integrationHandler   *IntegrationHandler
}

func NewAIService(repo *repository.AIRepository, cfg *config.Config) *AIService {
	return &AIService{
		repo:               repo,
		config:             cfg,
		openAIClient:       NewOpenAIClient(cfg.OpenAIAPIKey),
		integrationHandler: NewIntegrationHandler(cfg),
	}
}

// SubmitWriting creates a writing submission and evaluates it
func (s *AIService) SubmitWriting(userID uuid.UUID, req *models.WritingSubmissionRequest) (*models.WritingSubmissionResponse, error) {
	// Create submission
	submission := &models.WritingSubmission{
		ID:              uuid.New(),
		UserID:          userID,
		TaskType:        req.TaskType,
		TaskPromptID:    req.TaskPromptID,
		TaskPromptText:  req.TaskPromptText,
		EssayText:       req.EssayText,
		WordCount:       len(strings.Fields(req.EssayText)),
		TimeSpentSeconds: req.TimeSpentSeconds,
		SubmittedFrom:   "web",
		Status:          "pending",
		ExerciseID:      req.ExerciseID,
		CourseID:        req.CourseID,
		LessonID:        req.LessonID,
		SubmittedAt:     time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	if err := s.repo.CreateWritingSubmission(submission); err != nil {
		return nil, fmt.Errorf("failed to create submission: %w", err)
	}

	// Update status to processing
	s.repo.UpdateWritingSubmissionStatus(submission.ID, "processing")

	// Evaluate with OpenAI
	timeSpent := 0
	if req.TimeSpentSeconds != nil {
		timeSpent = *req.TimeSpentSeconds
	}

	evalResult, err := s.openAIClient.EvaluateWriting(
		req.TaskPromptText,
		req.EssayText,
		submission.WordCount,
		timeSpent,
	)
	if err != nil {
		s.repo.UpdateWritingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Save evaluation
	// Build detailed feedback from structured response (if detailed_feedback is string map)
	detailedFeedbackText := fmt.Sprintf(`Task Achievement: %s

Coherence & Cohesion: %s

Lexical Resource: %s

Grammatical Range: %s`,
		evalResult.DetailedFeedback.TaskAchievement,
		evalResult.DetailedFeedback.CoherenceCohesion,
		evalResult.DetailedFeedback.LexicalResource,
		evalResult.DetailedFeedback.GrammaticalRange,
	)

	evaluation := &models.WritingEvaluation{
		ID:                      uuid.New(),
		SubmissionID:            submission.ID,
		OverallBandScore:        evalResult.OverallBand,
		TaskAchievementScore:    evalResult.CriteriaScores.TaskAchievement,
		CoherenceCohesionScore:   evalResult.CriteriaScores.CoherenceCohesion,
		LexicalResourceScore:    evalResult.CriteriaScores.LexicalResource,
		GrammarAccuracyScore:    evalResult.CriteriaScores.GrammaticalRange,
		Strengths:               evalResult.Strengths,
		Weaknesses:              evalResult.AreasForImprovement,
		DetailedFeedback:        detailedFeedbackText + "\n\n" + evalResult.ExaminerFeedback,
		ImprovementSuggestions:   evalResult.AreasForImprovement,
		AIModelName:             stringPtr("gpt-4o"),
		CreatedAt:               time.Now(),
	}

	if err := s.repo.CreateWritingEvaluation(evaluation); err != nil {
		return nil, fmt.Errorf("failed to save evaluation: %w", err)
	}

	// Update submission status
	now := time.Now()
	submission.Status = "completed"
	submission.EvaluatedAt = &now
	s.repo.UpdateWritingSubmissionStatus(submission.ID, "completed")

	// Trigger service integration (non-blocking)
	s.integrationHandler.HandleWritingEvaluationCompletion(submission, evaluation)

	return &models.WritingSubmissionResponse{
		Submission: submission,
		Evaluation: evaluation,
	}, nil
}

// SubmitSpeaking creates a speaking submission, transcribes, and evaluates it
func (s *AIService) SubmitSpeaking(userID uuid.UUID, req *models.SpeakingSubmissionRequest) (*models.SpeakingSubmissionResponse, error) {
	// Create submission
	submission := &models.SpeakingSubmission{
		ID:                  uuid.New(),
		UserID:              userID,
		PartNumber:          req.PartNumber,
		TaskPromptID:        req.TaskPromptID,
		TaskPromptText:      req.TaskPromptText,
		AudioURL:            req.AudioURL,
		AudioDurationSeconds: req.AudioDurationSeconds,
		AudioFormat:         req.AudioFormat,
		AudioFileSizeBytes:  req.AudioFileSizeBytes,
		RecordedFrom:        "web",
		Status:              "pending",
		ExerciseID:          req.ExerciseID,
		CourseID:            req.CourseID,
		LessonID:            req.LessonID,
		SubmittedAt:         time.Now(),
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}

	if err := s.repo.CreateSpeakingSubmission(submission); err != nil {
		return nil, fmt.Errorf("failed to create submission: %w", err)
	}

	// Update status
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "transcribing"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}
	
	// Download and transcribe audio
	audioData, err := downloadAudio(req.AudioURL)
	if err != nil {
		s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("failed to download audio: %w", err)
	}

	transcript, err := s.openAIClient.TranscribeAudio(req.AudioURL, audioData)
	if err != nil {
		s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("transcription failed: %w", err)
	}

	wordCount := len(strings.Fields(transcript.Text))
	if err := s.repo.UpdateSpeakingSubmissionTranscript(submission.ID, transcript.Text, wordCount); err != nil {
		return nil, fmt.Errorf("failed to update transcript: %w", err)
	}

	// Evaluate with OpenAI
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "processing"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}
	
	partName := fmt.Sprintf("part%d", req.PartNumber)
	evalResult, err := s.openAIClient.EvaluateSpeaking(
		partName,
		req.TaskPromptText,
		transcript.Text,
		wordCount,
		transcript.Duration,
	)
	if err != nil {
		s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Save evaluation
	// Build detailed feedback from structured response
	detailedFeedbackText := fmt.Sprintf(`Fluency & Coherence: %s

Lexical Resource: %s

Grammatical Range: %s

Pronunciation: %s`,
		evalResult.DetailedFeedback.FluencyCoherence.Analysis,
		evalResult.DetailedFeedback.LexicalResource.Analysis,
		evalResult.DetailedFeedback.GrammaticalRange.Analysis,
		evalResult.DetailedFeedback.Pronunciation.Analysis,
	)

	evaluation := &models.SpeakingEvaluation{
		ID:                      uuid.New(),
		SubmissionID:            submission.ID,
		OverallBandScore:        evalResult.OverallBand,
		FluencyCoherenceScore:   evalResult.CriteriaScores.FluencyCoherence,
		LexicalResourceScore:    evalResult.CriteriaScores.LexicalResource,
		GrammarAccuracyScore:    evalResult.CriteriaScores.GrammaticalRange,
		PronunciationScore:      evalResult.CriteriaScores.Pronunciation,
		Strengths:               evalResult.Strengths,
		Weaknesses:              evalResult.AreasForImprovement,
		DetailedFeedback:        detailedFeedbackText + "\n\n" + evalResult.ExaminerFeedback,
		ImprovementSuggestions:   evalResult.AreasForImprovement,
		TranscriptionModel:      stringPtr("whisper-1"),
		EvaluationModel:         stringPtr("gpt-4o"),
		CreatedAt:               time.Now(),
	}

	if err := s.repo.CreateSpeakingEvaluation(evaluation); err != nil {
		return nil, fmt.Errorf("failed to save evaluation: %w", err)
	}

	// Update submission status
	now := time.Now()
	submission.Status = "completed"
	submission.EvaluatedAt = &now
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "completed"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}

	// Trigger service integration (non-blocking)
	s.integrationHandler.HandleSpeakingEvaluationCompletion(submission, evaluation)

	return &models.SpeakingSubmissionResponse{
		Submission: submission,
		Evaluation: evaluation,
	}, nil
}

// SubmitSpeakingWithAudio creates a speaking submission with audio data directly (from multipart upload)
func (s *AIService) SubmitSpeakingWithAudio(userID uuid.UUID, req *models.SpeakingSubmissionRequest, audioData []byte) (*models.SpeakingSubmissionResponse, error) {
	// Create submission
	submission := &models.SpeakingSubmission{
		ID:                  uuid.New(),
		UserID:              userID,
		PartNumber:          req.PartNumber,
		TaskPromptID:        req.TaskPromptID,
		TaskPromptText:      req.TaskPromptText,
		AudioURL:            req.AudioURL,
		AudioDurationSeconds: req.AudioDurationSeconds,
		AudioFormat:         req.AudioFormat,
		AudioFileSizeBytes:  req.AudioFileSizeBytes,
		RecordedFrom:        "web",
		Status:              "pending",
		ExerciseID:          req.ExerciseID,
		CourseID:            req.CourseID,
		LessonID:            req.LessonID,
		SubmittedAt:         time.Now(),
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}

	if err := s.repo.CreateSpeakingSubmission(submission); err != nil {
		return nil, fmt.Errorf("failed to create submission: %w", err)
	}

	// Update status
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "transcribing"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}

	// Transcribe audio directly (no download needed)
	transcript, err := s.openAIClient.TranscribeAudio(req.AudioURL, audioData)
	if err != nil {
		s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("transcription failed: %w", err)
	}

	wordCount := len(strings.Fields(transcript.Text))
	if err := s.repo.UpdateSpeakingSubmissionTranscript(submission.ID, transcript.Text, wordCount); err != nil {
		return nil, fmt.Errorf("failed to update transcript: %w", err)
	}

	// Evaluate with OpenAI
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "processing"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}

	partName := fmt.Sprintf("part%d", req.PartNumber)
	evalResult, err := s.openAIClient.EvaluateSpeaking(
		partName,
		req.TaskPromptText,
		transcript.Text,
		wordCount,
		transcript.Duration,
	)
	if err != nil {
		s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "failed")
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Save evaluation
	detailedFeedbackText := fmt.Sprintf(`Fluency & Coherence: %s

Lexical Resource: %s

Grammatical Range: %s

Pronunciation: %s`,
		evalResult.DetailedFeedback.FluencyCoherence.Analysis,
		evalResult.DetailedFeedback.LexicalResource.Analysis,
		evalResult.DetailedFeedback.GrammaticalRange.Analysis,
		evalResult.DetailedFeedback.Pronunciation.Analysis,
	)

	evaluation := &models.SpeakingEvaluation{
		ID:                      uuid.New(),
		SubmissionID:            submission.ID,
		OverallBandScore:        evalResult.OverallBand,
		FluencyCoherenceScore:   evalResult.CriteriaScores.FluencyCoherence,
		LexicalResourceScore:    evalResult.CriteriaScores.LexicalResource,
		GrammarAccuracyScore:    evalResult.CriteriaScores.GrammaticalRange,
		PronunciationScore:      evalResult.CriteriaScores.Pronunciation,
		Strengths:               evalResult.Strengths,
		Weaknesses:              evalResult.AreasForImprovement,
		DetailedFeedback:        detailedFeedbackText + "\n\n" + evalResult.ExaminerFeedback,
		ImprovementSuggestions:   evalResult.AreasForImprovement,
		TranscriptionModel:      stringPtr("whisper-1"),
		EvaluationModel:         stringPtr("gpt-4o"),
		CreatedAt:               time.Now(),
	}

	if err := s.repo.CreateSpeakingEvaluation(evaluation); err != nil {
		return nil, fmt.Errorf("failed to save evaluation: %w", err)
	}

	// Update submission status
	now := time.Now()
	submission.Status = "completed"
	submission.EvaluatedAt = &now
	if err := s.repo.UpdateSpeakingSubmissionStatus(submission.ID, "completed"); err != nil {
		return nil, fmt.Errorf("failed to update status: %w", err)
	}

	// Trigger service integration (non-blocking)
	s.integrationHandler.HandleSpeakingEvaluationCompletion(submission, evaluation)

	return &models.SpeakingSubmissionResponse{
		Submission: submission,
		Evaluation: evaluation,
	}, nil
}

// GetWritingSubmission retrieves a writing submission with evaluation
func (s *AIService) GetWritingSubmission(id uuid.UUID) (*models.WritingSubmissionResponse, error) {
	submission, err := s.repo.GetWritingSubmission(id)
	if err != nil {
		return nil, err
	}

	evaluation, _ := s.repo.GetWritingEvaluation(id)
	return &models.WritingSubmissionResponse{
		Submission: submission,
		Evaluation: evaluation,
	}, nil
}

// GetSpeakingSubmission retrieves a speaking submission with its evaluation
func (s *AIService) GetSpeakingSubmission(id uuid.UUID) (*models.SpeakingSubmissionResponse, error) {
	submission, err := s.repo.GetSpeakingSubmission(id)
	if err != nil {
		return nil, err
	}

	evaluation, err := s.repo.GetSpeakingEvaluation(submission.ID)
	if err != nil {
		// Evaluation might not exist yet
		return &models.SpeakingSubmissionResponse{
			Submission: submission,
		}, nil
	}

	return &models.SpeakingSubmissionResponse{
		Submission: submission,
		Evaluation: evaluation,
	}, nil
}

// GetUserWritingSubmissions gets user's writing submissions
func (s *AIService) GetUserWritingSubmissions(userID uuid.UUID, limit, offset int) ([]*models.WritingSubmission, error) {
	return s.repo.GetUserWritingSubmissions(userID, limit, offset)
}

// GetUserSpeakingSubmissions gets user's speaking submissions
func (s *AIService) GetUserSpeakingSubmissions(userID uuid.UUID, limit, offset int) ([]*models.SpeakingSubmission, error) {
	return s.repo.GetUserSpeakingSubmissions(userID, limit, offset)
}

// Writing Prompts
func (s *AIService) GetWritingPrompt(id uuid.UUID) (*models.WritingPrompt, error) {
	return s.repo.GetWritingPrompt(id)
}

func (s *AIService) GetWritingPrompts(taskType *string, difficulty *string, isPublished *bool, limit, offset int) ([]*models.WritingPrompt, error) {
	return s.repo.GetWritingPrompts(taskType, difficulty, isPublished, limit, offset)
}

func (s *AIService) CreateWritingPrompt(adminID uuid.UUID, req *models.WritingPromptRequest) (*models.WritingPrompt, error) {
	prompt := &models.WritingPrompt{
		ID:                  uuid.New(),
		TaskType:            req.TaskType,
		PromptText:          req.PromptText,
		VisualType:          req.VisualType,
		VisualURL:           req.VisualURL,
		Topic:               req.Topic,
		Difficulty:          req.Difficulty,
		HasSampleAnswer:     req.HasSampleAnswer,
		SampleAnswerText:    req.SampleAnswerText,
		SampleAnswerBandScore: req.SampleAnswerBandScore,
		IsPublished:         req.IsPublished,
		CreatedBy:           &adminID,
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}

	if err := s.repo.CreateWritingPrompt(prompt); err != nil {
		return nil, err
	}
	return prompt, nil
}

func (s *AIService) UpdateWritingPrompt(id uuid.UUID, req *models.WritingPromptRequest) (*models.WritingPrompt, error) {
	prompt := &models.WritingPrompt{
		TaskType:            req.TaskType,
		PromptText:          req.PromptText,
		VisualType:          req.VisualType,
		VisualURL:           req.VisualURL,
		Topic:               req.Topic,
		Difficulty:          req.Difficulty,
		HasSampleAnswer:     req.HasSampleAnswer,
		SampleAnswerText:    req.SampleAnswerText,
		SampleAnswerBandScore: req.SampleAnswerBandScore,
		IsPublished:         req.IsPublished,
		UpdatedAt:           time.Now(),
	}

	if err := s.repo.UpdateWritingPrompt(id, prompt); err != nil {
		return nil, err
	}

	return s.repo.GetWritingPrompt(id)
}

func (s *AIService) DeleteWritingPrompt(id uuid.UUID) error {
	return s.repo.DeleteWritingPrompt(id)
}

// Speaking Prompts
func (s *AIService) GetSpeakingPrompt(id uuid.UUID) (*models.SpeakingPrompt, error) {
	return s.repo.GetSpeakingPrompt(id)
}

func (s *AIService) GetSpeakingPrompts(partNumber *int, difficulty *string, isPublished *bool, limit, offset int) ([]*models.SpeakingPrompt, error) {
	return s.repo.GetSpeakingPrompts(partNumber, difficulty, isPublished, limit, offset)
}

func (s *AIService) CreateSpeakingPrompt(adminID uuid.UUID, req *models.SpeakingPromptRequest) (*models.SpeakingPrompt, error) {
	prompt := &models.SpeakingPrompt{
		ID:                     uuid.New(),
		PartNumber:             req.PartNumber,
		PromptText:             req.PromptText,
		CueCardTopic:           req.CueCardTopic,
		CueCardPoints:          req.CueCardPoints,
		PreparationTimeSeconds: req.PreparationTimeSeconds,
		SpeakingTimeSeconds:    req.SpeakingTimeSeconds,
		FollowUpQuestions:      req.FollowUpQuestions,
		TopicCategory:          req.TopicCategory,
		Difficulty:             req.Difficulty,
		HasSampleAnswer:        req.HasSampleAnswer,
		SampleAnswerText:       req.SampleAnswerText,
		SampleAnswerAudioURL:   req.SampleAnswerAudioURL,
		SampleAnswerBandScore:  req.SampleAnswerBandScore,
		IsPublished:            req.IsPublished,
		CreatedBy:              &adminID,
		CreatedAt:              time.Now(),
		UpdatedAt:              time.Now(),
	}

	if err := s.repo.CreateSpeakingPrompt(prompt); err != nil {
		return nil, err
	}
	return prompt, nil
}

func (s *AIService) UpdateSpeakingPrompt(id uuid.UUID, req *models.SpeakingPromptRequest) (*models.SpeakingPrompt, error) {
	prompt := &models.SpeakingPrompt{
		PartNumber:             req.PartNumber,
		PromptText:             req.PromptText,
		CueCardTopic:           req.CueCardTopic,
		CueCardPoints:          req.CueCardPoints,
		PreparationTimeSeconds: req.PreparationTimeSeconds,
		SpeakingTimeSeconds:    req.SpeakingTimeSeconds,
		FollowUpQuestions:      req.FollowUpQuestions,
		TopicCategory:          req.TopicCategory,
		Difficulty:             req.Difficulty,
		HasSampleAnswer:        req.HasSampleAnswer,
		SampleAnswerText:       req.SampleAnswerText,
		SampleAnswerAudioURL:   req.SampleAnswerAudioURL,
		SampleAnswerBandScore:  req.SampleAnswerBandScore,
		IsPublished:            req.IsPublished,
		UpdatedAt:              time.Now(),
	}

	if err := s.repo.UpdateSpeakingPrompt(id, prompt); err != nil {
		return nil, err
	}

	return s.repo.GetSpeakingPrompt(id)
}

func (s *AIService) DeleteSpeakingPrompt(id uuid.UUID) error {
	return s.repo.DeleteSpeakingPrompt(id)
}

// Helper functions
func stringPtr(s string) *string {
	return &s
}

func downloadAudio(url string) ([]byte, error) {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to download audio: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("audio download failed with status: %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read audio data: %w", err)
	}

	return data, nil
}


