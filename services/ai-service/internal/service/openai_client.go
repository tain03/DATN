package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"time"

	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
)

type OpenAIClient struct {
	APIKey     string
	BaseURL    string
	HTTPClient *http.Client
}

func NewOpenAIClient(apiKey string) *OpenAIClient {
	if apiKey == "" {
		return nil
	}
	return &OpenAIClient{
		APIKey:  apiKey,
		BaseURL: "https://api.openai.com/v1",
		HTTPClient: &http.Client{
			Timeout: 120 * time.Second, // Long timeout for AI processing
		},
	}
}

// TranscribeAudio transcribes audio using Whisper API
func (c *OpenAIClient) TranscribeAudio(audioURL string, audioData []byte) (*models.OpenAITranscription, error) {
	if c == nil {
		return nil, fmt.Errorf("OpenAI client not initialized (missing API key)")
	}

	// Create multipart form
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add audio file
	part, err := writer.CreateFormFile("file", "audio.mp3")
	if err != nil {
		return nil, fmt.Errorf("failed to create form file: %w", err)
	}
	if _, err := part.Write(audioData); err != nil {
		return nil, fmt.Errorf("failed to write audio data: %w", err)
	}

	// Add form fields
	writer.WriteField("model", "whisper-1")
	writer.WriteField("language", "en")
	writer.WriteField("response_format", "verbose_json")
	writer.WriteField("timestamp_granularities[]", "word")

	writer.Close()

	// Create request
	req, err := http.NewRequest("POST", c.BaseURL+"/audio/transcriptions", body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.APIKey)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	// Send request
	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("OpenAI API error: %s - %s", resp.Status, string(bodyBytes))
	}

	// Parse response - OpenAI returns verbose_json format
	var transcriptResponse struct {
		Text     string  `json:"text"`
		Duration float64 `json:"duration"`
		Words    []struct {
			Word  string  `json:"word"`
			Start float64 `json:"start"`
			End   float64 `json:"end"`
		} `json:"words"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&transcriptResponse); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Convert to our model
	transcript := &models.OpenAITranscription{
		Text:     transcriptResponse.Text,
		Duration: transcriptResponse.Duration,
	}

	// Convert words
	transcript.Words = make([]struct {
		Word  string  `json:"word"`
		Start float64 `json:"start"`
		End   float64 `json:"end"`
	}, len(transcriptResponse.Words))
	copy(transcript.Words, transcriptResponse.Words)

	return transcript, nil
}

// EvaluateWriting evaluates writing using GPT-4
func (c *OpenAIClient) EvaluateWriting(taskPromptText, essayText string, wordCount, timeSpent int) (*models.OpenAIWritingEvaluation, error) {
	if c == nil {
		return nil, fmt.Errorf("OpenAI client not initialized (missing API key)")
	}

	// Create evaluation prompt
	evaluationPrompt := fmt.Sprintf(`[Writing Task]
%s

<Student's Essay>
%s

[Word count: %d | Time taken: %ds]`, taskPromptText, essayText, wordCount, timeSpent)

	systemPrompt := `You are an official IELTS Writing examiner.
You will be given a writing task and a student's essay.
Your job is to evaluate the essay exactly as in an IELTS Writing test.

Follow the official IELTS Writing Band Descriptors strictly.
Provide detailed, constructive feedback and a final band score.

Your output must be in this format:

### Evaluation

**1. Task Achievement / Task Response (0–9):**
- [Give score and explain how well the essay addresses the task, supports ideas, and maintains relevance.]

**2. Coherence and Cohesion (0–9):**
- [Give score and analyze organization, logical flow, paragraphing, and use of linking devices.]

**3. Lexical Resource (0–9):**
- [Give score and describe vocabulary range, precision, collocations, and appropriateness.]

**4. Grammatical Range and Accuracy (0–9):**
- [Give score and explain sentence variety, grammatical control, and error frequency.]

### Overall Band: [average rounded to nearest 0.5]

### Examiner Feedback:
[Provide a natural, 3–4 sentence summary of strengths and areas for improvement, written like a real IELTS examiner.]

### Additional Analysis:
**Strengths:**
- [List 2-3 specific strengths in Vietnamese]

**Areas for Improvement:**
- [List 2-3 specific areas with actionable advice in Vietnamese]

IMPORTANT: Return your response in JSON format with this exact structure:
{
    "overall_band": float (average band rounded to nearest 0.5),
    "criteria_scores": {
        "task_achievement": float,
        "coherence_cohesion": float,
        "lexical_resource": float,
        "grammatical_range": float
    },
    "detailed_feedback": {
        "task_achievement": "Detailed analysis covering how well the essay addresses the task, supports ideas, and maintains relevance. Include specific examples from the essay.",
        "coherence_cohesion": "Detailed analysis of organization, logical flow, paragraphing, and use of linking devices. Include specific examples.",
        "lexical_resource": "Detailed analysis of vocabulary range, precision, collocations, and appropriateness. Highlight specific word choices.",
        "grammatical_range": "Detailed analysis of sentence variety, grammatical control, and error frequency. Point out specific structures."
    },
    "examiner_feedback": "A natural, 3-4 sentence summary written like a real IELTS examiner, covering strengths and areas for improvement.",
    "strengths": ["specific strength 1 in Vietnamese", "specific strength 2 in Vietnamese"],
    "areas_for_improvement": ["specific area 1 with actionable advice in Vietnamese", "specific area 2 with actionable advice in Vietnamese"]
}

Guidelines:
- Be specific and reference actual content from the essay
- Scores must reflect official IELTS band descriptors (0-9 scale, use .0 or .5 increments)
- All detailed feedback and lists should be in Vietnamese
- Examiner feedback should be natural and encouraging but honest
- Overall band = average of 4 criteria, rounded to nearest 0.5`

	// Prepare request payload
	payload := map[string]interface{}{
		"model": "gpt-4o",
		"messages": []map[string]interface{}{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": evaluationPrompt,
			},
		},
		"temperature":      0.3,
		"response_format": map[string]string{"type": "json_object"},
	}

	eval := &models.OpenAIWritingEvaluation{}
	_, err := c.callChatAPI(payload, eval)
	if err != nil {
		return nil, err
	}
	return eval, nil
}

// EvaluateSpeaking evaluates speaking using GPT-4
func (c *OpenAIClient) EvaluateSpeaking(part string, promptText, transcriptText string, wordCount int, duration float64) (*models.OpenAISpeakingEvaluation, error) {
	if c == nil {
		return nil, fmt.Errorf("OpenAI client not initialized (missing API key)")
	}

	// Create evaluation prompt (simplified - full version would handle multiple responses like IELTSensei)
	evaluationPrompt := fmt.Sprintf(`=== IELTS SPEAKING %s EVALUATION ===

PROMPT: %s

STUDENT'S ANSWER (transcribed):
%s

[Duration: %.1fs | Word count: %d]

EVALUATION INSTRUCTIONS:
Please evaluate this according to official IELTS Speaking band descriptors.
Provide detailed, specific analysis for each criterion with concrete examples from the student's responses.
The evaluation should be professional, constructive, and actionable.
All detailed feedback should be in Vietnamese, but use English for criterion names and technical terms.`, part, promptText, transcriptText, duration, wordCount)

	partNames := map[string]string{
		"part1": "Part 1 (Introduction and Interview)",
		"part2": "Part 2 (Long Turn)",
		"part3": "Part 3 (Two-way Discussion)",
	}
	partName := partNames[part]
	if partName == "" {
		partName = "a section"
	}

	systemPrompt := `You are an official IELTS Speaking examiner. 
You will receive a student's spoken answers (converted to text) and the questions they were responding to. 
Your task is to evaluate the answers as if they were given in a real IELTS Speaking test.

Follow the IELTS Speaking band descriptors strictly and provide detailed, specific evaluation.

Your output format:

### Evaluation

**1. Fluency and Coherence (0–9):**
- [Give score and explain pace, pauses, coherence, linking devices, and topic development]

**2. Lexical Resource (0–9):**
- [Give score and describe vocabulary range, idiomatic expressions, collocations, and appropriateness]

**3. Grammatical Range and Accuracy (0–9):**
- [Give score and explain sentence variety, tense usage, and error frequency]

**4. Pronunciation (0–9):**
- [Give score based on transcript indicators of clarity and naturalness]

### Overall Band: [average rounded to nearest 0.5]

### Examiner Feedback:
[Provide a natural, 3-4 sentence summary of strengths and areas for improvement]

IMPORTANT: Return your response in JSON format with this exact structure:
{
    "overall_band": float (average band rounded to nearest 0.5),
    "criteria_scores": {
        "fluency_coherence": float,
        "lexical_resource": float,
        "grammatical_range": float,
        "pronunciation": float
    },
    "detailed_feedback": {
        "fluency_coherence": {
            "score": float,
            "analysis": "Detailed analysis in Vietnamese covering: pace of speech, pauses and hesitations, coherence and cohesion, use of linking devices, ability to develop topics. Be specific about what was observed."
        },
        "lexical_resource": {
            "score": float,
            "analysis": "Detailed analysis in Vietnamese covering: vocabulary range, use of less common/idiomatic expressions, collocation, word choice appropriacy, any lexical errors or repetitions. Provide specific examples."
        },
        "grammatical_range": {
            "score": float,
            "analysis": "Detailed analysis in Vietnamese covering: variety of sentence structures (simple, compound, complex), tense usage and accuracy, grammatical errors and their frequency/severity. Highlight specific structures used or missing."
        },
        "pronunciation": {
            "score": float,
            "analysis": "Analysis in Vietnamese based on transcript: assess indicators of word stress patterns, sentence rhythm, clarity of expression. Note: actual pronunciation cannot be fully assessed from transcript alone, so focus on indicators of speech clarity and naturalness evident in the text."
        }
    },
    "examiner_feedback": "A natural, 3-4 sentence summary in Vietnamese written like a real IELTS examiner: What was good, what to improve, and how to reach the next band level. Be encouraging but honest.",
    "strengths": ["specific strength 1 in Vietnamese", "specific strength 2 in Vietnamese"],
    "areas_for_improvement": ["specific area 1 with actionable advice in Vietnamese", "specific area 2 with actionable advice in Vietnamese"]
}

Guidelines:
- Be specific and reference actual content from the responses
- Scores must reflect official IELTS band descriptors (0-9 scale, use .0 or .5 increments)
- All detailed feedback and lists should be in Vietnamese
- Examiner feedback should be natural and encouraging but honest
- Consider the part type (Part 1: short responses, Part 2: long turn, Part 3: abstract discussion)
- Overall band = average of 4 criteria, rounded to nearest 0.5`

	// Prepare request payload
	payload := map[string]interface{}{
		"model": "gpt-4o",
		"messages": []map[string]interface{}{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": evaluationPrompt,
			},
		},
		"temperature":      0.3,
		"response_format": map[string]string{"type": "json_object"},
	}

	eval := &models.OpenAISpeakingEvaluation{}
	_, err := c.callChatAPI(payload, eval)
	if err != nil {
		return nil, err
	}
	return eval, nil
}

// callChatAPI is a helper to call OpenAI Chat API
func (c *OpenAIClient) callChatAPI(payload interface{}, result interface{}) (interface{}, error) {
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", c.BaseURL+"/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.APIKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("OpenAI API error: %s - %s", resp.Status, string(bodyBytes))
	}

	var response struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(response.Choices) == 0 {
		return nil, fmt.Errorf("no choices in response")
	}

	// Parse JSON content to result type
	contentBytes := []byte(response.Choices[0].Message.Content)
	if err := json.Unmarshal(contentBytes, result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal evaluation: %w", err)
	}

	return result, nil
}

