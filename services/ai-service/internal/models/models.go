package models

// This file previously contained database models (WritingEvaluation, SpeakingEvaluation, etc.)
// Those models have been removed because AI Service is now a stateless evaluation engine.
// All evaluation results are returned directly via API responses (see dto.go)
// Database persistence is handled by Exercise Service.
