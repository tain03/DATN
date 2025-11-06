package models

// FeedbackBilingual contains feedback in both Vietnamese and English
type FeedbackBilingual struct {
	VI string `json:"vi"`
	EN string `json:"en"`
}

// OpenAI Evaluation Response (Writing)
type OpenAIWritingEvaluation struct {
	OverallBand    float64 `json:"overall_band"`
	CriteriaScores struct {
		TaskAchievement   float64 `json:"task_achievement"`
		CoherenceCohesion float64 `json:"coherence_cohesion"`
		LexicalResource   float64 `json:"lexical_resource"`
		GrammaticalRange  float64 `json:"grammatical_range"`
	} `json:"criteria_scores"`
	DetailedFeedback struct {
		TaskAchievement   FeedbackBilingual `json:"task_achievement"`
		CoherenceCohesion FeedbackBilingual `json:"coherence_cohesion"`
		LexicalResource   FeedbackBilingual `json:"lexical_resource"`
		GrammaticalRange  FeedbackBilingual `json:"grammatical_range"`
	} `json:"detailed_feedback"`
	ExaminerFeedback    string   `json:"examiner_feedback"`
	Strengths           []string `json:"strengths"`
	AreasForImprovement []string `json:"areas_for_improvement"`
}

// OpenAI Evaluation Response (Speaking)
type OpenAISpeakingEvaluation struct {
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
}

// OpenAI Transcription Response
type OpenAITranscription struct {
	Text     string  `json:"text"`
	Duration float64 `json:"duration"`
	Words    []struct {
		Word  string  `json:"word"`
		Start float64 `json:"start"`
		End   float64 `json:"end"`
	} `json:"words"`
}
