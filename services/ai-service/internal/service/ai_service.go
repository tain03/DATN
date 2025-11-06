package service

import (
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
	"github.com/bisosad1501/DATN/services/ai-service/internal/repository"
)

type AIService struct {
	repo         *repository.AIRepository
	config       *config.Config
	openAIClient *OpenAIClient
	cacheService *CacheService
}

func NewAIService(repo *repository.AIRepository, cfg *config.Config) *AIService {
	return &AIService{
		repo:         repo,
		config:       cfg,
		openAIClient: NewOpenAIClient(cfg.OpenAIAPIKey),
		cacheService: NewCacheService(repo),
	}
}

// ========== PURE STATELESS APIs ==========
// AI Service is now a PURE EVALUATION ENGINE
// All submission/prompt management moved to Exercise Service

// EvaluateWritingPure evaluates writing without database operations (stateless with cache)
func (s *AIService) EvaluateWritingPure(essayText, taskType, promptText string) (*models.OpenAIWritingEvaluation, error) {
	if essayText == "" {
		return nil, fmt.Errorf("essay text is required")
	}

	// Check cache first
	if cached, hit := s.cacheService.CheckWritingCache(essayText, taskType, promptText); hit {
		return cached, nil
	}

	wordCount := len(strings.Fields(essayText))

	// Call OpenAI for evaluation (cache miss)
	evalResult, err := s.openAIClient.EvaluateWriting(promptText, essayText, wordCount, 0)
	if err != nil {
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Save to cache (async, don't block on cache errors)
	go s.cacheService.SaveWritingCache(essayText, taskType, promptText, evalResult)

	return evalResult, nil
}

// TranscribeSpeakingPure transcribes audio without database operations (stateless)
func (s *AIService) TranscribeSpeakingPure(audioURL string) (string, error) {
	if audioURL == "" {
		return "", fmt.Errorf("audio URL is required")
	}

	// Download audio
	audioData, err := downloadAudio(audioURL)
	if err != nil {
		return "", fmt.Errorf("failed to download audio: %w", err)
	}

	// Transcribe with OpenAI Whisper
	transcript, err := s.openAIClient.TranscribeAudio("audio.mp3", audioData)
	if err != nil {
		return "", fmt.Errorf("transcription failed: %w", err)
	}

	return transcript.Text, nil
}

// EvaluateSpeakingPure evaluates speaking without database operations (stateless with cache)
func (s *AIService) EvaluateSpeakingPure(audioURL, transcriptText string, partNumber int) (*models.OpenAISpeakingEvaluation, error) {
	if audioURL == "" {
		return nil, fmt.Errorf("audio URL is required")
	}

	// If transcript not provided, transcribe first
	if transcriptText == "" {
		var err error
		transcriptText, err = s.TranscribeSpeakingPure(audioURL)
		if err != nil {
			return nil, fmt.Errorf("transcription failed: %w", err)
		}
	}

	// Check cache first
	if cached, hit := s.cacheService.CheckSpeakingCache(audioURL, transcriptText, partNumber); hit {
		return cached, nil
	}

	// Evaluate speaking with OpenAI (cache miss)
	evalResult, err := s.openAIClient.EvaluateSpeaking(transcriptText, "", audioURL, partNumber, 0)
	if err != nil {
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Save to cache (async, don't block on cache errors)
	go s.cacheService.SaveSpeakingCache(audioURL, transcriptText, partNumber, evalResult)

	return evalResult, nil
}

// GetCacheStatistics returns cache hit/miss statistics
func (s *AIService) GetCacheStatistics() (map[string]interface{}, error) {
	return s.cacheService.GetCacheStatistics()
}

// Helper function
func downloadAudio(url string) ([]byte, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to download audio: status %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}
