package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// AIServiceClient handles communication with AI Service
type AIServiceClient struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

// NewAIServiceClient creates a new AI service client
func NewAIServiceClient(baseURL, apiKey string) *AIServiceClient {
	return &AIServiceClient{
		baseURL: baseURL,
		apiKey:  apiKey,
		httpClient: &http.Client{
			Timeout: 60 * time.Second, // AI calls can take longer
		},
	}
}

// WritingEvaluationRequest represents request to evaluate writing
type WritingEvaluationRequest struct {
	EssayText  string `json:"essay_text"`
	TaskType   string `json:"task_type"` // task1, task2
	PromptText string `json:"prompt_text"`
}

// WritingEvaluationResponse represents response from writing evaluation
type WritingEvaluationResponse struct {
	Success bool `json:"success"`
	Data    struct {
		OverallBand    float64 `json:"overall_band"`
		CriteriaScores struct {
			TaskAchievement   float64 `json:"task_achievement"`
			CoherenceCohesion float64 `json:"coherence_cohesion"`
			LexicalResource   float64 `json:"lexical_resource"`
			GrammaticalRange  float64 `json:"grammatical_range"`
		} `json:"criteria_scores"`
		DetailedFeedback struct {
			TaskAchievement struct {
				Score    float64 `json:"score"`
				Feedback string  `json:"feedback"`
			} `json:"task_achievement"`
			CoherenceCohesion struct {
				Score    float64 `json:"score"`
				Feedback string  `json:"feedback"`
			} `json:"coherence_cohesion"`
			LexicalResource struct {
				Score    float64 `json:"score"`
				Feedback string  `json:"feedback"`
			} `json:"lexical_resource"`
			GrammaticalRange struct {
				Score    float64 `json:"score"`
				Feedback string  `json:"feedback"`
			} `json:"grammatical_range"`
		} `json:"detailed_feedback"`
		ExaminerFeedback    string   `json:"examiner_feedback"`
		Strengths           []string `json:"strengths"`
		AreasForImprovement []string `json:"areas_for_improvement"`
	} `json:"data"`
	Message string `json:"message,omitempty"`
}

// SpeakingTranscriptionRequest represents request to transcribe speaking
type SpeakingTranscriptionRequest struct {
	AudioURL string `json:"audio_url"`
}

// SpeakingTranscriptionResponse represents response from transcription
type SpeakingTranscriptionResponse struct {
	Success bool `json:"success"`
	Data    struct {
		TranscriptText string `json:"transcript_text"`
		AudioDuration  int    `json:"audio_duration_seconds"`
	} `json:"data"`
	Message string `json:"message,omitempty"`
}

// SpeakingEvaluationRequest represents request to evaluate speaking
type SpeakingEvaluationRequest struct {
	AudioURL       string  `json:"audio_url"`
	TranscriptText string  `json:"transcript_text"`
	PromptText     string  `json:"prompt_text"`
	PartNumber     int     `json:"part_number"` // 1, 2, 3
	WordCount      int     `json:"word_count"`
	Duration       float64 `json:"duration"`
}

// SpeakingEvaluationResponse represents response from speaking evaluation
type SpeakingEvaluationResponse struct {
	Success bool `json:"success"`
	Data    struct {
		OverallBand    float64 `json:"overall_band"`
		CriteriaScores struct {
			FluencyCoherence float64 `json:"fluency_coherence"`
			LexicalResource  float64 `json:"lexical_resource"`
			GrammaticalRange float64 `json:"grammatical_range"`
			Pronunciation    float64 `json:"pronunciation"`
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
		ExaminerFeedback    string   `json:"examiner_feedback"`
		Strengths           []string `json:"strengths"`
		AreasForImprovement []string `json:"areas_for_improvement"`
	} `json:"data"`
	Message string `json:"message,omitempty"`
}

// EvaluateWriting sends writing essay to AI service for evaluation
func (c *AIServiceClient) EvaluateWriting(req WritingEvaluationRequest) (*WritingEvaluationResponse, error) {
	endpoint := fmt.Sprintf("%s/api/v1/ai/internal/writing/evaluate", c.baseURL)

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-API-Key", c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("AI service returned status %d: %s", resp.StatusCode, string(body))
	}

	var result WritingEvaluationResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("unmarshal response: %w", err)
	}

	return &result, nil
}

// TranscribeSpeaking sends audio URL to AI service for transcription
func (c *AIServiceClient) TranscribeSpeaking(req SpeakingTranscriptionRequest) (*SpeakingTranscriptionResponse, error) {
	endpoint := fmt.Sprintf("%s/api/v1/ai/internal/speaking/transcribe", c.baseURL)

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-API-Key", c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("AI service returned status %d: %s", resp.StatusCode, string(body))
	}

	var result SpeakingTranscriptionResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("unmarshal response: %w", err)
	}

	return &result, nil
}

// EvaluateSpeaking sends transcript to AI service for evaluation
func (c *AIServiceClient) EvaluateSpeaking(req SpeakingEvaluationRequest) (*SpeakingEvaluationResponse, error) {
	endpoint := fmt.Sprintf("%s/api/v1/ai/internal/speaking/evaluate", c.baseURL)

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	httpReq, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-API-Key", c.apiKey)

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("AI service returned status %d: %s", resp.StatusCode, string(body))
	}

	var result SpeakingEvaluationResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("unmarshal response: %w", err)
	}

	return &result, nil
}
