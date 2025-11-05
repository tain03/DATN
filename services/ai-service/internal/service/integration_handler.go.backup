package service

import (
	"fmt"
	"log"
	"time"

	"github.com/bisosad1501/DATN/shared/pkg/client"
	"github.com/bisosad1501/DATN/services/ai-service/internal/config"
	"github.com/bisosad1501/DATN/services/ai-service/internal/models"
)

type IntegrationHandler struct {
	userServiceClient        *client.UserServiceClient
	notificationServiceClient *client.NotificationServiceClient
	config                   *config.Config
}

func NewIntegrationHandler(cfg *config.Config) *IntegrationHandler {
	return &IntegrationHandler{
		userServiceClient:        client.NewUserServiceClient(cfg.UserServiceURL, cfg.InternalAPIKey),
		notificationServiceClient: client.NewNotificationServiceClient(cfg.NotificationServiceURL, cfg.InternalAPIKey),
		config:                   cfg,
	}
}

// HandleWritingEvaluationCompletion handles service integration after writing evaluation completes
func (h *IntegrationHandler) HandleWritingEvaluationCompletion(
	submission *models.WritingSubmission,
	evaluation *models.WritingEvaluation,
) {
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("[AI-Service] PANIC in HandleWritingEvaluationCompletion: %v", r)
			}
		}()

		log.Printf("[AI-Service] Handling writing evaluation completion for submission %s", submission.ID)

		// 1. Update User Service - Skill Statistics
		if evaluation.OverallBandScore > 0 {
			h.updateUserSkillStats(submission, evaluation, "writing")
			h.updateUserProgress(submission, evaluation, "writing")
		}

		// 2. Send Notification
		h.sendEvaluationNotification(submission, evaluation, "writing")

		log.Printf("[AI-Service] Completed integration handling for writing submission %s", submission.ID)
	}()
}

// HandleSpeakingEvaluationCompletion handles service integration after speaking evaluation completes
func (h *IntegrationHandler) HandleSpeakingEvaluationCompletion(
	submission *models.SpeakingSubmission,
	evaluation *models.SpeakingEvaluation,
) {
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("[AI-Service] PANIC in HandleSpeakingEvaluationCompletion: %v", r)
			}
		}()

		log.Printf("[AI-Service] Handling speaking evaluation completion for submission %s", submission.ID)

		// 1. Update User Service - Skill Statistics
		if evaluation.OverallBandScore > 0 {
			h.updateUserSkillStatsForSpeaking(submission, evaluation)
			h.updateUserProgressForSpeaking(submission, evaluation)
		}

		// 2. Send Notification
		h.sendSpeakingEvaluationNotification(submission, evaluation)

		log.Printf("[AI-Service] Completed integration handling for speaking submission %s", submission.ID)
	}()
}

// updateUserSkillStats updates skill statistics in User Service
func (h *IntegrationHandler) updateUserSkillStats(
	submission *models.WritingSubmission,
	evaluation *models.WritingEvaluation,
	skillType string,
) {
	timeMinutes := 0
	if submission.TimeSpentSeconds != nil {
		timeMinutes = *submission.TimeSpentSeconds / 60
		if timeMinutes == 0 {
			timeMinutes = 1 // Minimum 1 minute
		}
	}

	req := client.UpdateSkillStatsRequest{
		UserID:         submission.UserID.String(),
		SkillType:      skillType,
		Score:          float64(evaluation.OverallBandScore),
		TimeMinutes:    timeMinutes,
		IsCompleted:    true,
		TotalPractices: 1,
	}

	maxRetries := 3
	retryDelay := time.Second
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.userServiceClient.UpdateSkillStatistics(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Updated skill statistics (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			log.Printf("[AI-Service] ⚠️  Skill stats update attempt %d failed, retrying in %v...", attempt, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ❌ Failed to update skill statistics after %d attempts: %v", maxRetries, lastErr)
}

// updateUserSkillStatsForSpeaking updates skill statistics for speaking
func (h *IntegrationHandler) updateUserSkillStatsForSpeaking(
	submission *models.SpeakingSubmission,
	evaluation *models.SpeakingEvaluation,
) {
	timeMinutes := 0
	if submission.AudioDurationSeconds > 0 {
		timeMinutes = submission.AudioDurationSeconds / 60
		if timeMinutes == 0 {
			timeMinutes = 1
		}
	}

	req := client.UpdateSkillStatsRequest{
		UserID:         submission.UserID.String(),
		SkillType:      "speaking",
		Score:          float64(evaluation.OverallBandScore),
		TimeMinutes:    timeMinutes,
		IsCompleted:    true,
		TotalPractices: 1,
	}

	maxRetries := 3
	retryDelay := time.Second
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.userServiceClient.UpdateSkillStatistics(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Updated speaking skill statistics (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			log.Printf("[AI-Service] ⚠️  Speaking skill stats update attempt %d failed, retrying in %v...", attempt, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ❌ Failed to update speaking skill statistics after %d attempts: %v", maxRetries, lastErr)
}

// updateUserProgress updates user progress in User Service
func (h *IntegrationHandler) updateUserProgress(
	submission *models.WritingSubmission,
	evaluation *models.WritingEvaluation,
	skillType string,
) {
	timeMinutes := 0
	if submission.TimeSpentSeconds != nil {
		timeMinutes = *submission.TimeSpentSeconds / 60
		if timeMinutes == 0 {
			timeMinutes = 1
		}
	}

	req := client.UpdateProgressRequest{
		UserID:            submission.UserID.String(),
		ExercisesComplete: 1,
		StudyMinutes:      timeMinutes,
		SkillType:         skillType,
		SessionType:       "ai_evaluation",
		ResourceID:        submission.ID.String(),
		ResourceType:      "writing_submission",
		Score:             float64(evaluation.OverallBandScore),
	}

	maxRetries := 3
	retryDelay := time.Second
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.userServiceClient.UpdateProgress(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Updated user progress (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			log.Printf("[AI-Service] ⚠️  Progress update attempt %d failed, retrying in %v...", attempt, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ❌ Failed to update progress after %d attempts: %v", maxRetries, lastErr)
}

// updateUserProgressForSpeaking updates user progress for speaking
func (h *IntegrationHandler) updateUserProgressForSpeaking(
	submission *models.SpeakingSubmission,
	evaluation *models.SpeakingEvaluation,
) {
	timeMinutes := 0
	if submission.AudioDurationSeconds > 0 {
		timeMinutes = submission.AudioDurationSeconds / 60
		if timeMinutes == 0 {
			timeMinutes = 1
		}
	}

	req := client.UpdateProgressRequest{
		UserID:            submission.UserID.String(),
		ExercisesComplete: 1,
		StudyMinutes:      timeMinutes,
		SkillType:         "speaking",
		SessionType:       "ai_evaluation",
		ResourceID:        submission.ID.String(),
		ResourceType:      "speaking_submission",
		Score:             float64(evaluation.OverallBandScore),
	}

	maxRetries := 3
	retryDelay := time.Second
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.userServiceClient.UpdateProgress(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Updated speaking progress (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			log.Printf("[AI-Service] ⚠️  Speaking progress update attempt %d failed, retrying in %v...", attempt, retryDelay)
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ❌ Failed to update speaking progress after %d attempts: %v", maxRetries, lastErr)
}

// sendEvaluationNotification sends notification about completed evaluation
func (h *IntegrationHandler) sendEvaluationNotification(
	submission *models.WritingSubmission,
	evaluation *models.WritingEvaluation,
	skillType string,
) {
	title := "Writing Evaluation Complete"
	if skillType == "speaking" {
		title = "Speaking Evaluation Complete"
	}

	message := fmt.Sprintf("Your %s has been evaluated. Band Score: %.1f", skillType, evaluation.OverallBandScore)

	req := client.SendNotificationRequest{
		UserID:   submission.UserID.String(),
		Title:    title,
		Message:  message,
		Type:     "exercise_graded",
		Category: "success",
		Priority: "normal",
		ActionData: map[string]interface{}{
			"submission_id": submission.ID.String(),
			"band_score":    evaluation.OverallBandScore,
			"type":          skillType,
		},
	}

	maxRetries := 2 // Fewer retries for notifications (non-critical)
	retryDelay := 500 * time.Millisecond
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.notificationServiceClient.SendNotification(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Sent evaluation notification (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ⚠️  Failed to send notification after %d attempts: %v (non-critical)", maxRetries, lastErr)
}

// sendSpeakingEvaluationNotification sends notification for speaking evaluation
func (h *IntegrationHandler) sendSpeakingEvaluationNotification(
	submission *models.SpeakingSubmission,
	evaluation *models.SpeakingEvaluation,
) {
	message := fmt.Sprintf("Your speaking has been evaluated. Band Score: %.1f", evaluation.OverallBandScore)

	req := client.SendNotificationRequest{
		UserID:   submission.UserID.String(),
		Title:    "Speaking Evaluation Complete",
		Message:  message,
		Type:     "exercise_graded",
		Category: "success",
		Priority: "normal",
		ActionData: map[string]interface{}{
			"submission_id": submission.ID.String(),
			"band_score":    evaluation.OverallBandScore,
			"type":          "speaking",
		},
	}

	maxRetries := 2
	retryDelay := 500 * time.Millisecond
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		err := h.notificationServiceClient.SendNotification(req)
		if err == nil {
			log.Printf("[AI-Service] ✅ Sent speaking evaluation notification (attempt %d)", attempt)
			return
		}
		lastErr = err
		if attempt < maxRetries {
			time.Sleep(retryDelay)
			retryDelay *= 2
		}
	}

	log.Printf("[AI-Service] ⚠️  Failed to send speaking notification after %d attempts: %v (non-critical)", maxRetries, lastErr)
}

