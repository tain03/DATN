package service

import (
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"strings"
	"time"

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

	log.Printf("🎤 [AI Service] Transcribing audio from URL: %s", audioURL)

	// Download audio
	audioData, err := downloadAudio(audioURL)
	if err != nil {
		log.Printf("❌ [AI Service] Failed to download audio from URL %s: %v", audioURL, err)
		return "", fmt.Errorf("failed to download audio: %w", err)
	}

	log.Printf("✅ [AI Service] Downloaded audio: %d bytes", len(audioData))

	// Transcribe with OpenAI Whisper
	log.Printf("🎤 [AI Service] Calling OpenAI Whisper API to transcribe audio...")
	transcript, err := s.openAIClient.TranscribeAudio("audio.mp3", audioData)
	if err != nil {
		log.Printf("❌ [AI Service] Transcription failed: %v", err)
		return "", fmt.Errorf("transcription failed: %w", err)
	}

	if transcript == nil || transcript.Text == "" {
		log.Printf("⚠️ [AI Service] Transcription returned empty result")
		return "", fmt.Errorf("transcription returned empty result")
	}

	log.Printf("✅ [AI Service] Transcription successful. Transcript length: %d characters", len(transcript.Text))
	if len(transcript.Text) > 200 {
		log.Printf("📝 [AI Service] Transcript preview: %s...", transcript.Text[:200])
	} else {
		log.Printf("📝 [AI Service] Full transcript: %s", transcript.Text)
	}

	return transcript.Text, nil
}

// EvaluateSpeakingPure evaluates speaking without database operations (stateless with cache)
func (s *AIService) EvaluateSpeakingPure(audioURL, transcriptText, promptText string, partNumber int, wordCount int, duration float64) (*models.OpenAISpeakingEvaluation, error) {
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

	// Calculate word count if not provided
	if wordCount == 0 && transcriptText != "" {
		wordCount = len(strings.Fields(transcriptText))
	}

	// Convert part number to part string
	partStr := fmt.Sprintf("part%d", partNumber)

	// Check cache first
	if cached, hit := s.cacheService.CheckSpeakingCache(audioURL, transcriptText, partNumber); hit {
		return cached, nil
	}

	// Evaluate speaking with OpenAI (cache miss)
	// Correct parameter order: part, promptText, transcriptText, wordCount, duration
	evalResult, err := s.openAIClient.EvaluateSpeaking(partStr, promptText, transcriptText, wordCount, duration)
	if err != nil {
		return nil, fmt.Errorf("evaluation failed: %w", err)
	}

	// Post-processing: Validate and adjust scores if necessary
	evalResult = s.validateAndAdjustSpeakingScores(evalResult, transcriptText, wordCount)

	// Save to cache (async, don't block on cache errors)
	go s.cacheService.SaveSpeakingCache(audioURL, transcriptText, partNumber, evalResult)

	return evalResult, nil
}

// validateAndAdjustSpeakingScores ensures scores are reasonable and fair
func (s *AIService) validateAndAdjustSpeakingScores(result *models.OpenAISpeakingEvaluation, transcriptText string, wordCount int) *models.OpenAISpeakingEvaluation {
	if result == nil {
		return result
	}

	// If transcript is empty or too short, scores should be 0.0
	if transcriptText == "" || len(strings.TrimSpace(transcriptText)) < 10 || wordCount < 5 {
		log.Printf("⚠️ Transcript too short or empty (%d words), keeping scores as is", wordCount)
		return result
	}

	// Get scores
	fluencyScore := result.CriteriaScores.FluencyCoherence
	lexicalScore := result.CriteriaScores.LexicalResource
	grammarScore := result.CriteriaScores.GrammaticalRange
	pronunciationScore := result.CriteriaScores.Pronunciation

	// Validate scores are within valid range (0.0-9.0) and clamp if necessary
	fluencyScore = math.Max(0.0, math.Min(9.0, fluencyScore))
	lexicalScore = math.Max(0.0, math.Min(9.0, lexicalScore))
	grammarScore = math.Max(0.0, math.Min(9.0, grammarScore))
	pronunciationScore = math.Max(0.0, math.Min(9.0, pronunciationScore))
	
	result.CriteriaScores.FluencyCoherence = fluencyScore
	result.CriteriaScores.LexicalResource = lexicalScore
	result.CriteriaScores.GrammaticalRange = grammarScore
	result.CriteriaScores.Pronunciation = pronunciationScore

	// Calculate overall band from criteria average (round to nearest 0.5)
	avgScore := (fluencyScore + lexicalScore + grammarScore + pronunciationScore) / 4.0
	roundedBand := math.Round(avgScore*2) / 2.0
	result.OverallBand = roundedBand

	// Log warning if all scores are 0.0 but transcript has meaningful content
	allZero := fluencyScore == 0.0 && lexicalScore == 0.0 && grammarScore == 0.0 && pronunciationScore == 0.0
	if allZero && wordCount >= 10 && len(strings.TrimSpace(transcriptText)) >= 10 {
		transcriptPreview := transcriptText
		if len(transcriptPreview) > 200 {
			transcriptPreview = transcriptPreview[:200] + "..."
		}
		log.Printf("⚠️ WARNING: All scores are 0.0 but transcript has %d words", wordCount)
		log.Printf("⚠️ Transcript preview: %s", transcriptPreview)
		log.Printf("⚠️ Possible reasons: (1) GPT-4 evaluation issue, (2) Transcript is gibberish, or (3) Very poor English")
		log.Printf("⚠️ Scores will remain as evaluated by GPT-4 (trusting AI judgment)")
	}

	// Log evaluation summary for monitoring
	log.Printf("📊 Speaking Evaluation Summary:")
	log.Printf("   Transcript: %d words, %d characters", wordCount, len(transcriptText))
	log.Printf("   Fluency & Coherence: %.1f", fluencyScore)
	log.Printf("   Lexical Resource: %.1f", lexicalScore)
	log.Printf("   Grammatical Range: %.1f", grammarScore)
	log.Printf("   Pronunciation: %.1f", pronunciationScore)
	log.Printf("   Overall Band: %.1f (calculated from average)", result.OverallBand)

	return result
}

// Helper function to get minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// GetCacheStatistics returns cache hit/miss statistics
func (s *AIService) GetCacheStatistics() (map[string]interface{}, error) {
	return s.cacheService.GetCacheStatistics()
}

// Helper function to download audio with retry logic
func downloadAudio(url string) ([]byte, error) {
	// Support both external URLs and internal MinIO URLs
	// Internal: http://minio:9000/ielts-audio/audio/user-id/file.mp3
	// External: https://storage.example.com/audio.mp3

	log.Printf("📥 [AI Service] Downloading audio from URL: %s", url)

	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	var lastErr error
	maxRetries := 3

	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("📥 [AI Service] Download attempt %d/%d", attempt, maxRetries)
		resp, err := client.Get(url)
		if err != nil {
			lastErr = fmt.Errorf("attempt %d: %w", attempt, err)
			log.Printf("⚠️ [AI Service] Download attempt %d failed: %v", attempt, err)
			if attempt < maxRetries {
				time.Sleep(time.Duration(attempt) * time.Second)
				continue
			}
			return nil, lastErr
		}
		defer resp.Body.Close()

		log.Printf("📥 [AI Service] Response status: %d, Content-Type: %s, Content-Length: %s", 
			resp.StatusCode, resp.Header.Get("Content-Type"), resp.Header.Get("Content-Length"))

		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(resp.Body)
			bodyPreview := string(body)
			if len(bodyPreview) > 500 {
				bodyPreview = bodyPreview[:500] + "..."
			}
			lastErr = fmt.Errorf("attempt %d: status %d, body: %s", attempt, resp.StatusCode, bodyPreview)
			log.Printf("❌ [AI Service] Download failed with status %d: %s", resp.StatusCode, bodyPreview)
			if attempt < maxRetries && (resp.StatusCode >= 500 || resp.StatusCode == 429) {
				time.Sleep(time.Duration(attempt) * time.Second)
				continue
			}
			return nil, lastErr
		}

		audioData, err := io.ReadAll(resp.Body)
		if err != nil {
			lastErr = fmt.Errorf("attempt %d: failed to read response: %w", attempt, err)
			log.Printf("❌ [AI Service] Failed to read response body: %v", err)
			if attempt < maxRetries {
				time.Sleep(time.Duration(attempt) * time.Second)
				continue
			}
			return nil, lastErr
		}

		log.Printf("✅ [AI Service] Successfully downloaded audio: %d bytes", len(audioData))
		return audioData, nil
	}

	return nil, fmt.Errorf("failed after %d attempts: %w", maxRetries, lastErr)
}
