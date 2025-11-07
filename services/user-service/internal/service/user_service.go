package service

import (
	"fmt"
	"io"
	"log"
	"time"

	"github.com/bisosad1501/DATN/services/user-service/internal/config"
	"github.com/bisosad1501/DATN/services/user-service/internal/models"
	"github.com/bisosad1501/DATN/services/user-service/internal/repository"
	"github.com/bisosad1501/DATN/shared/pkg/client"
	"github.com/google/uuid"
)

type UserService struct {
	repo               *repository.UserRepository
	notificationClient *client.NotificationServiceClient
}

func NewUserService(repo *repository.UserRepository, cfg *config.Config) *UserService {
	var notificationClient *client.NotificationServiceClient
	if cfg != nil && cfg.NotificationServiceURL != "" {
		notificationClient = client.NewNotificationServiceClient(
			cfg.NotificationServiceURL,
			cfg.InternalAPIKey,
		)
		log.Printf("✅ Notification Service client initialized")
	} else {
		log.Printf("⚠️  Notification Service URL not configured, sync will be disabled")
	}

	return &UserService{
		repo:               repo,
		notificationClient: notificationClient,
	}
}

// GetOrCreateProfile gets existing profile or creates a new one
func (s *UserService) GetOrCreateProfile(userID uuid.UUID) (*models.UserProfile, error) {
	profile, err := s.repo.GetProfileByUserID(userID)
	if err != nil {
		return nil, err
	}

	// If profile doesn't exist, create it
	if profile == nil {
		err = s.repo.CreateProfile(userID)
		if err != nil {
			return nil, err
		}
		profile, err = s.repo.GetProfileByUserID(userID)
		if err != nil {
			return nil, err
		}
	}

	return profile, nil
}

// GetPublicProfile gets another user's profile with visibility check
// Returns profile with profile_visibility included in response
func (s *UserService) GetPublicProfile(targetUserID uuid.UUID, requestingUserID *uuid.UUID) (map[string]interface{}, error) {
	// Get target user's profile
	profile, err := s.repo.GetProfileByUserID(targetUserID)
	if err != nil {
		return nil, err
	}
	if profile == nil {
		return nil, fmt.Errorf("profile not found")
	}

	// Get target user's preferences to check profile_visibility
	prefs, err := s.repo.GetPreferences(targetUserID)
	if err != nil {
		// If preferences not found, default to "public"
		log.Printf("⚠️  Warning: Failed to get preferences for user %s, defaulting to public: %v", targetUserID, err)
		prefs = &models.UserPreferences{
			ProfileVisibility: "public",
		}
	}

	// Check if requesting user is the profile owner
	isOwner := requestingUserID != nil && *requestingUserID == targetUserID

	// Check visibility
	visibility := prefs.ProfileVisibility
	if visibility == "" {
		visibility = "public" // Default to public if not set
	}

	// If profile is private and requester is not the owner, return error
	if visibility == "private" && !isOwner {
		return nil, fmt.Errorf("profile is private")
	}

	// Check "friends" visibility - user can view if target user is following them (one-way friendship)
	if visibility == "friends" && !isOwner {
		if requestingUserID == nil {
			// Not authenticated, cannot view friends-only profile
			return nil, fmt.Errorf("profile is only visible to friends")
		}
		// Check if target user is following the requesting user (one-way check)
		isFriend, err := s.repo.IsFollowing(targetUserID, *requestingUserID)
		if err != nil || !isFriend {
			return nil, fmt.Errorf("profile is only visible to friends")
		}
	}

	// Convert profile to map and add profile_visibility
	result := map[string]interface{}{
		"user_id":            profile.UserID.String(),
		"first_name":         profile.FirstName,
		"last_name":          profile.LastName,
		"full_name":          profile.FullName,
		"avatar_url":         profile.AvatarURL,
		"cover_image_url":    profile.CoverImageURL,
		"bio":                profile.Bio,
		"target_band_score":  profile.TargetBandScore,
		"current_level":      profile.CurrentLevel,
		"profile_visibility": visibility, // ✅ Include profile_visibility in response
		"created_at":         profile.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		"updated_at":         profile.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// Get learning progress for stats
	progress, err := s.repo.GetLearningProgress(targetUserID)
	if err == nil && progress != nil {
		// Map progress fields to frontend expected format
		// Calculate level from overall score (simplified: level = floor(overall_score))
		level := 0
		if progress.OverallScore != nil && *progress.OverallScore > 0 {
			level = int(*progress.OverallScore)
		}
		result["level"] = level

		// Points: calculate from achievements or use a default
		// For now, use a simple calculation based on progress
		points := (progress.TotalLessonsCompleted * 10) + (progress.TotalExercisesCompleted * 5)
		result["points"] = points

		result["coursesCompleted"] = 0 // TODO: Get from enrollments if needed
		result["exercisesCompleted"] = int(progress.TotalExercisesCompleted)

		// Calculate study time in seconds (convert from hours)
		studyTimeSeconds := int(progress.TotalStudyHours * 3600)
		result["studyTime"] = studyTimeSeconds
		result["streak"] = int(progress.CurrentStreakDays)

		// Get follow counts
		followersCount, _ := s.repo.GetFollowersCount(targetUserID)
		followingCount, _ := s.repo.GetFollowingCount(targetUserID)
		result["followersCount"] = followersCount
		result["followingCount"] = followingCount

		// Check if requesting user is following target user
		isFollowing := false
		if requestingUserID != nil {
			isFollowing, _ = s.repo.IsFollowing(*requestingUserID, targetUserID)
		}
		result["isFollowing"] = isFollowing
	}

	return result, nil
}

// UpdateProfile updates user profile
func (s *UserService) UpdateProfile(userID uuid.UUID, req *models.UpdateProfileRequest) (*models.UserProfile, error) {
	// Validate inputs
	if req.TargetBandScore != nil {
		if *req.TargetBandScore < 0 || *req.TargetBandScore > 9 {
			return nil, fmt.Errorf("target band score must be between 0 and 9")
		}
	}

	err := s.repo.UpdateProfile(userID, req)
	if err != nil {
		return nil, err
	}

	// Return updated profile
	return s.repo.GetProfileByUserID(userID)
}

// UpdateAvatar updates user avatar
func (s *UserService) UpdateAvatar(userID uuid.UUID, avatarURL string) error {
	return s.repo.UpdateAvatar(userID, avatarURL)
}

// GetProgressStats gets comprehensive progress statistics
func (s *UserService) GetProgressStats(userID uuid.UUID) (*models.ProgressStatsResponse, error) {
	// Get profile
	profile, err := s.GetOrCreateProfile(userID)
	if err != nil {
		return nil, err
	}

	// Get learning progress
	progress, err := s.repo.GetLearningProgress(userID)
	if err != nil {
		return nil, err
	}

	// Get recent sessions (just 10 most recent for dashboard, page 1)
	recentSessions, _, err := s.repo.GetRecentSessions(userID, 1, 10)
	if err != nil {
		log.Printf("⚠️  Warning: Failed to get recent sessions: %v", err)
		recentSessions = []models.StudySession{}
	}

	// Get achievements
	achievements, err := s.repo.GetUserAchievements(userID)
	if err != nil {
		log.Printf("⚠️  Warning: Failed to get achievements: %v", err)
		achievements = []models.UserAchievement{}
	}

	// Calculate total points from achievements (simplified for now)
	totalPoints := len(achievements) * 10 // Each achievement worth 10 points

	return &models.ProgressStatsResponse{
		Profile:        profile,
		Progress:       progress,
		RecentSessions: recentSessions,
		Achievements:   achievements,
		TotalPoints:    totalPoints,
	}, nil
}

// StartStudySession starts a new study session
func (s *UserService) StartStudySession(req *models.StudySessionRequest, userID uuid.UUID, deviceType *string) (*models.StudySession, error) {
	session := &models.StudySession{
		ID:           uuid.New(),
		UserID:       userID,
		SessionType:  req.SessionType,
		SkillType:    req.SkillType,
		ResourceType: req.ResourceType,
		StartedAt:    time.Now(),
		IsCompleted:  false,
		DeviceType:   deviceType,
	}

	if req.ResourceID != nil {
		resourceID, err := uuid.Parse(*req.ResourceID)
		if err == nil {
			session.ResourceID = &resourceID
		}
	}

	err := s.repo.CreateStudySession(session)
	if err != nil {
		return nil, err
	}

	return session, nil
}

// EndStudySession ends an active study session
func (s *UserService) EndStudySession(sessionID uuid.UUID, req *models.EndSessionRequest) error {
	return s.repo.EndStudySession(sessionID, req.CompletionPercentage, req.Score)
}

// GetStudyHistory gets study history for a user
func (s *UserService) GetStudyHistory(userID uuid.UUID, page, limit int) ([]models.StudySession, int, error) {
	// Validate pagination params
	if page < 1 {
		page = 1
	}
	if limit <= 0 || limit > 200 {
		limit = 20 // Default limit
	}
	return s.repo.GetRecentSessions(userID, page, limit)
}

// ============= Study Goals =============

// CreateGoal creates a new study goal with validation
func (s *UserService) CreateGoal(userID uuid.UUID, req *models.CreateGoalRequest) (*models.StudyGoal, error) {
	// Parse end_date string to time.Time
	endDate, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		return nil, fmt.Errorf("invalid end_date format, expected YYYY-MM-DD: %v", err)
	}

	// Validate end_date is in the future
	if endDate.Before(time.Now()) {
		return nil, fmt.Errorf("end date must be in the future")
	}

	// Validate target value
	if req.TargetValue <= 0 {
		return nil, fmt.Errorf("target value must be greater than 0")
	}

	goal := &models.StudyGoal{
		ID:              uuid.New(),
		UserID:          userID,
		GoalType:        req.GoalType,
		Title:           req.Title,
		Description:     req.Description,
		TargetValue:     req.TargetValue,
		CurrentValue:    0,
		TargetUnit:      req.TargetUnit,
		SkillType:       req.SkillType,
		StartDate:       time.Now(),
		EndDate:         endDate,
		Status:          "active", // Match DB schema: active, completed, cancelled, expired
		ReminderEnabled: false,
		ReminderTime:    nil,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	err = s.repo.CreateGoal(goal)
	if err != nil {
		return nil, err
	}

	return goal, nil
}

// GetUserGoals retrieves all goals for a user with progress percentages
func (s *UserService) GetUserGoals(userID uuid.UUID) ([]*models.GoalResponse, error) {
	goals, err := s.repo.GetUserGoals(userID)
	if err != nil {
		return nil, err
	}

	responses := make([]*models.GoalResponse, len(goals))
	for i, goal := range goals {
		responses[i] = s.enrichGoalResponse(&goal)
	}

	return responses, nil
}

// GetGoalByID retrieves a specific goal with enriched information
func (s *UserService) GetGoalByID(goalID uuid.UUID, userID uuid.UUID) (*models.GoalResponse, error) {
	goal, err := s.repo.GetGoalByID(goalID, userID)
	if err != nil {
		return nil, err
	}

	return s.enrichGoalResponse(goal), nil
}

// enrichGoalResponse adds calculated fields to goal
func (s *UserService) enrichGoalResponse(goal *models.StudyGoal) *models.GoalResponse {
	completionPercentage := float64(0)
	if goal.TargetValue > 0 {
		completionPercentage = (float64(goal.CurrentValue) / float64(goal.TargetValue)) * 100
		if completionPercentage > 100 {
			completionPercentage = 100
		}
	}

	statusMessage := "On track"
	var daysRemaining *int

	days := int(time.Until(goal.EndDate).Hours() / 24)
	daysRemaining = &days

	if goal.Status == "completed" {
		statusMessage = "Completed"
	} else if days < 0 {
		statusMessage = "Overdue"
	} else if completionPercentage < 50 && days < 7 {
		statusMessage = "Behind schedule"
	}

	return &models.GoalResponse{
		StudyGoal:            goal,
		CompletionPercentage: completionPercentage,
		DaysRemaining:        daysRemaining,
		StatusMessage:        statusMessage,
	}
}

// UpdateGoal updates a study goal
func (s *UserService) UpdateGoal(goalID uuid.UUID, userID uuid.UUID, req *models.UpdateGoalRequest) (*models.StudyGoal, error) {
	goal, err := s.repo.GetGoalByID(goalID, userID)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if req.Title != nil {
		goal.Title = *req.Title
	}
	if req.TargetValue != nil {
		if *req.TargetValue <= 0 {
			return nil, fmt.Errorf("target value must be greater than 0")
		}
		goal.TargetValue = *req.TargetValue
	}
	if req.CurrentValue != nil {
		goal.CurrentValue = *req.CurrentValue
	}
	if req.EndDate != nil {
		endDate, err := time.Parse("2006-01-02", *req.EndDate)
		if err != nil {
			return nil, fmt.Errorf("invalid end_date format, expected YYYY-MM-DD: %v", err)
		}
		goal.EndDate = endDate
	}
	if req.Description != nil {
		goal.Description = req.Description
	}
	if req.Status != nil {
		goal.Status = *req.Status
	}

	// Auto-complete if target reached
	if goal.CurrentValue >= goal.TargetValue && goal.Status != "completed" {
		goal.Status = "completed"
		now := time.Now()
		goal.CompletedAt = &now
	}

	goal.UpdatedAt = time.Now()

	err = s.repo.UpdateGoal(goal)
	if err != nil {
		return nil, err
	}

	return goal, nil
}

// CompleteGoal marks a goal as completed
func (s *UserService) CompleteGoal(goalID uuid.UUID, userID uuid.UUID) error {
	return s.repo.CompleteGoal(goalID, userID)
}

// DeleteGoal deletes a study goal
func (s *UserService) DeleteGoal(goalID uuid.UUID, userID uuid.UUID) error {
	return s.repo.DeleteGoal(goalID, userID)
}

// ============= Skill Statistics =============

// GetDetailedStatistics retrieves comprehensive statistics for all skills
func (s *UserService) GetDetailedStatistics(userID uuid.UUID) (*models.StatisticsResponse, error) {
	statsMap, err := s.repo.GetAllSkillStatistics(userID)
	if err != nil {
		return nil, err
	}

	// Calculate overall statistics from all skills
	totalPractices := 0
	completedPractices := 0
	totalTimeMinutes := 0
	for _, stats := range statsMap {
		totalPractices += stats.TotalPractices
		completedPractices += stats.CompletedPractices
		totalTimeMinutes += stats.TotalTimeMinutes
	}

	averageAccuracy := float64(0)
	if totalPractices > 0 {
		averageAccuracy = (float64(completedPractices) / float64(totalPractices)) * 100
	}

	response := &models.StatisticsResponse{
		TotalPractices:     totalPractices,
		CompletedPractices: completedPractices,
		AverageAccuracy:    averageAccuracy,
		TotalTimeMinutes:   totalTimeMinutes,
		SkillBreakdown:     statsMap,
		WeakSkills:         []string{},
		StrongSkills:       []string{},
	}

	// Extract weak and strong skills based on average score
	for skill, stats := range statsMap {
		if stats.AverageScore < 60 && stats.TotalPractices > 0 {
			response.WeakSkills = append(response.WeakSkills, skill)
		} else if stats.AverageScore >= 80 && stats.TotalPractices > 0 {
			response.StrongSkills = append(response.StrongSkills, skill)
		}
	}

	return response, nil
}

// GetSkillStatistics retrieves statistics for a specific skill
func (s *UserService) GetSkillStatistics(userID uuid.UUID, skillType string) (*models.SkillStatistics, error) {
	return s.repo.GetSkillStatistics(userID, skillType)
}

// ============= Achievements =============

// GetAllAchievements retrieves all available achievements with user's progress
func (s *UserService) GetAllAchievements(userID uuid.UUID) ([]*models.AchievementWithProgress, error) {
	allAchievements, err := s.repo.GetAllAchievements()
	if err != nil {
		return nil, err
	}

	earnedAchievements, err := s.repo.GetUserAchievements(userID)
	if err != nil {
		return nil, err
	}

	// Create map of earned achievement IDs
	earnedMap := make(map[int]time.Time)
	for _, earned := range earnedAchievements {
		earnedMap[earned.AchievementID] = earned.EarnedAt
	}

	// Combine achievements with earned status
	result := make([]*models.AchievementWithProgress, len(allAchievements))
	for i, achievement := range allAchievements {
		earnedAt, isEarned := earnedMap[achievement.ID]
		result[i] = &models.AchievementWithProgress{
			Achievement: &achievement,
			IsEarned:    isEarned,
		}
		if isEarned {
			result[i].EarnedAt = &earnedAt
			result[i].Progress = achievement.CriteriaValue
			result[i].ProgressPercentage = 100
		} else {
			// TODO: Calculate actual progress based on criteria_type
			result[i].Progress = 0
			result[i].ProgressPercentage = 0
		}
	}

	return result, nil
}

// GetEarnedAchievements retrieves only user's earned achievements
func (s *UserService) GetEarnedAchievements(userID uuid.UUID) ([]models.UserAchievement, error) {
	return s.repo.GetUserAchievements(userID)
}

// UnlockAchievement unlocks an achievement for a user (admin function or auto-triggered)
func (s *UserService) UnlockAchievement(userID uuid.UUID, achievementID uuid.UUID) error {
	// Check if already unlocked
	id, err := uuid.Parse(achievementID.String())
	if err != nil {
		return fmt.Errorf("invalid achievement ID")
	}

	// Convert UUID to int (simplified - in production, fix achievement ID type consistency)
	_ = id

	return s.repo.UnlockAchievement(userID, achievementID)
}

// CheckAndUnlockAchievements checks user progress and auto-unlocks eligible achievements
func (s *UserService) CheckAndUnlockAchievements(userID uuid.UUID) error {
	log.Printf("[User-Service] 🏆 Checking achievements for user %s", userID)

	// 1. Get all achievements
	allAchievements, err := s.repo.GetAllAchievements()
	if err != nil {
		log.Printf("❌ Failed to get achievements: %v", err)
		return fmt.Errorf("failed to get achievements: %w", err)
	}

	// 2. Get already earned achievements
	earnedAchievements, err := s.repo.GetUserAchievements(userID)
	if err != nil {
		log.Printf("❌ Failed to get user achievements: %v", err)
		return fmt.Errorf("failed to get user achievements: %w", err)
	}

	// Create set of earned achievement IDs for fast lookup
	earnedSet := make(map[int]bool)
	for _, earned := range earnedAchievements {
		earnedSet[earned.AchievementID] = true
	}

	// 3. Get user's current progress data
	progress, err := s.repo.GetLearningProgress(userID)
	if err != nil {
		log.Printf("⚠️ Failed to get learning progress: %v", err)
		// Continue with empty progress
		progress = &models.LearningProgress{
			UserID: userID,
		}
	}

	// Get skill statistics for skill-specific achievements
	skillStats, err := s.repo.GetAllSkillStatistics(userID)
	if err != nil {
		log.Printf("⚠️ Failed to get skill statistics: %v", err)
		skillStats = make(map[string]*models.SkillStatistics)
	}

	// 4. Check each achievement
	unlockedCount := 0
	for _, achievement := range allAchievements {
		// Skip if already earned
		if earnedSet[achievement.ID] {
			continue
		}

		// Check if criteria is met
		criteriaMet := false
		switch achievement.CriteriaType {
		case "completion":
			criteriaMet = s.checkCompletionCriteria(achievement, progress, skillStats)
		case "streak":
			criteriaMet = s.checkStreakCriteria(achievement, progress)
		case "score":
			criteriaMet = s.checkScoreCriteria(achievement, progress)
		default:
			log.Printf("⚠️ Unknown criteria type: %s for achievement %s", achievement.CriteriaType, achievement.Code)
		}

		// Unlock achievement if criteria met
		if criteriaMet {
			// Note: Achievement ID is INT in database, but repo expects UUID
			// We use a workaround by converting int ID to UUID deterministically
			// TODO: Refactor achievement ID to be consistent (either all INT or all UUID)
			err := s.repo.UnlockAchievementByID(userID, achievement.ID)
			if err != nil {
				log.Printf("❌ Failed to unlock achievement %s (ID: %d): %v", achievement.Code, achievement.ID, err)
				continue
			}

			log.Printf("✅ Achievement unlocked: %s (%s) - %d points", achievement.Name, achievement.Code, achievement.Points)
			unlockedCount++

			// Send achievement notification (async)
			go s.sendAchievementNotification(userID, &achievement)
		}
	}

	if unlockedCount > 0 {
		log.Printf("🎉 User %s unlocked %d new achievements!", userID, unlockedCount)
	} else {
		log.Printf("📊 No new achievements for user %s", userID)
	}

	return nil
}

// Helper functions to check achievement criteria

// checkCompletionCriteria checks if user has completed enough activities
func (s *UserService) checkCompletionCriteria(achievement models.Achievement, progress *models.LearningProgress, skillStats map[string]*models.SkillStatistics) bool {
	switch achievement.Code {
	case "first_lesson":
		// Check if user completed at least 1 lesson OR 1 exercise
		return progress.TotalLessonsCompleted >= achievement.CriteriaValue || 
			   progress.TotalExercisesCompleted >= achievement.CriteriaValue

	case "listening_master":
		// Check if user completed 100 listening exercises
		if listeningStats, ok := skillStats["listening"]; ok {
			return listeningStats.CompletedPractices >= achievement.CriteriaValue
		}
		return false

	default:
		// Generic completion check - use total exercises completed
		return int(progress.TotalExercisesCompleted) >= achievement.CriteriaValue
	}
}

// checkStreakCriteria checks if user has maintained required streak
func (s *UserService) checkStreakCriteria(achievement models.Achievement, progress *models.LearningProgress) bool {
	return int(progress.CurrentStreakDays) >= achievement.CriteriaValue
}

// checkScoreCriteria checks if user has achieved required band score
func (s *UserService) checkScoreCriteria(achievement models.Achievement, progress *models.LearningProgress) bool {
	// Achievement criteria_value is stored as integer (60 for 6.0, 70 for 7.0)
	// Convert to actual band score by dividing by 10
	requiredBandScore := float64(achievement.CriteriaValue) / 10.0

	// Check if user has achieved the required score in ANY skill or overall
	if progress.OverallScore != nil && *progress.OverallScore >= requiredBandScore {
		return true
	}
	if progress.ListeningScore != nil && *progress.ListeningScore >= requiredBandScore {
		return true
	}
	if progress.ReadingScore != nil && *progress.ReadingScore >= requiredBandScore {
		return true
	}
	if progress.WritingScore != nil && *progress.WritingScore >= requiredBandScore {
		return true
	}
	if progress.SpeakingScore != nil && *progress.SpeakingScore >= requiredBandScore {
		return true
	}

	return false
}

// sendAchievementNotification sends a notification when achievement is unlocked
func (s *UserService) sendAchievementNotification(userID uuid.UUID, achievement *models.Achievement) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("❌ PANIC in sendAchievementNotification: %v", r)
		}
	}()

	if s.notificationClient == nil {
		log.Printf("⚠️ Notification client not available, skipping notification")
		return
	}

	// Send notification via Notification Service
	err := s.notificationClient.SendAchievementNotification(
		userID.String(),
		achievement.Name,
	)
	if err != nil {
		log.Printf("⚠️ Failed to send achievement notification: %v", err)
	} else {
		log.Printf("📬 Sent achievement notification for %s (+%d points)", achievement.Name, achievement.Points)
	}
}

// ============= User Preferences =============

// GetPreferences retrieves user preferences (creates default if not exists)
func (s *UserService) GetPreferences(userID uuid.UUID) (*models.UserPreferences, error) {
	return s.repo.GetPreferences(userID)
}

// UpdatePreferences updates user preferences
func (s *UserService) UpdatePreferences(userID uuid.UUID, req *models.UpdatePreferencesRequest) (*models.UserPreferences, error) {
	// Get existing preferences
	prefs, err := s.repo.GetPreferences(userID)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if req.EmailNotifications != nil {
		prefs.EmailNotifications = *req.EmailNotifications
	}
	if req.PushNotifications != nil {
		prefs.PushNotifications = *req.PushNotifications

		// Sync with Notification Service (source of truth)
		if s.notificationClient != nil {
			go func() {
				defer func() {
					if r := recover(); r != nil {
						log.Printf("[User-Service] PANIC in notification sync: %v", r)
					}
				}()

				pushEnabled := *req.PushNotifications
				err := s.syncPushNotificationPreference(userID, pushEnabled)
				if err != nil {
					log.Printf("[User-Service] ⚠️  Failed to sync push_notifications with Notification Service: %v", err)
					// Non-critical error, continue with User Service update
				} else {
					log.Printf("[User-Service] ✅ Synced push_notifications=%v with Notification Service", pushEnabled)
				}
			}()
		}
	}
	if req.StudyReminders != nil {
		prefs.StudyReminders = *req.StudyReminders
	}
	if req.WeeklyReport != nil {
		prefs.WeeklyReport = *req.WeeklyReport
	}
	if req.Theme != nil {
		prefs.Theme = *req.Theme
	}
	if req.FontSize != nil {
		prefs.FontSize = *req.FontSize
	}
	if req.Locale != nil {
		prefs.Locale = *req.Locale
	}
	if req.AutoPlayNextLesson != nil {
		prefs.AutoPlayNextLesson = *req.AutoPlayNextLesson
	}
	if req.ShowAnswerExplanation != nil {
		prefs.ShowAnswerExplanation = *req.ShowAnswerExplanation
	}
	if req.PlaybackSpeed != nil {
		// Validate playback speed range (0.75 - 2.0)
		speed := *req.PlaybackSpeed
		if speed < 0.75 || speed > 2.0 {
			return nil, fmt.Errorf("playback_speed must be between 0.75 and 2.0")
		}
		prefs.PlaybackSpeed = speed
	}
	if req.ProfileVisibility != nil {
		prefs.ProfileVisibility = *req.ProfileVisibility
	}
	if req.ShowStudyStats != nil {
		prefs.ShowStudyStats = *req.ShowStudyStats
	}

	prefs.UpdatedAt = time.Now()

	err = s.repo.UpdatePreferences(prefs)
	if err != nil {
		return nil, err
	}

	return prefs, nil
}

// syncPushNotificationPreference syncs push_notifications with Notification Service
// Notification Service is the source of truth for notification preferences
// Uses retry mechanism with exponential backoff for reliability
func (s *UserService) syncPushNotificationPreference(userID uuid.UUID, pushEnabled bool) error {
	if s.notificationClient == nil || s.notificationClient.ServiceClient == nil {
		return fmt.Errorf("notification client not initialized")
	}

	// Update Notification Service preferences using internal endpoint
	// Map push_notifications → push_enabled and in_app_enabled
	endpoint := fmt.Sprintf("/api/v1/notifications/internal/preferences/%s", userID.String())

	payload := map[string]interface{}{
		"push_enabled":   pushEnabled,
		"in_app_enabled": pushEnabled, // In-app notifications follow the same preference
	}

	// Retry mechanism with exponential backoff (max 3 retries)
	maxRetries := 3
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		// Use internal API endpoint for service-to-service communication
		resp, err := s.notificationClient.ServiceClient.Put(endpoint, payload)
		if err != nil {
			lastErr = fmt.Errorf("failed to call Notification Service: %w", err)
			if attempt < maxRetries {
				// Exponential backoff: 1s, 2s, 4s
				backoff := time.Duration(1<<uint(attempt-1)) * time.Second
				log.Printf("[User-Service] ⚠️  Sync attempt %d/%d failed, retrying in %v: %v", attempt, maxRetries, backoff, lastErr)
				time.Sleep(backoff)
				continue
			}
			return lastErr
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			// Success
			if attempt > 1 {
				log.Printf("[User-Service] ✅ Sync succeeded after %d attempts", attempt)
			}
			return nil
		}

		// Non-2xx status code
		bodyBytes, _ := io.ReadAll(resp.Body)
		lastErr = fmt.Errorf("Notification Service returned status %d: %s", resp.StatusCode, string(bodyBytes))

		// Don't retry on client errors (4xx)
		if resp.StatusCode >= 400 && resp.StatusCode < 500 {
			log.Printf("[User-Service] ❌ Client error, not retrying: %v", lastErr)
			return lastErr
		}

		// Retry on server errors (5xx)
		if attempt < maxRetries {
			backoff := time.Duration(1<<uint(attempt-1)) * time.Second
			log.Printf("[User-Service] ⚠️  Server error on attempt %d/%d, retrying in %v: %v", attempt, maxRetries, backoff, lastErr)
			time.Sleep(backoff)
		}
	}

	return lastErr
}

// ============= Study Reminders =============

// CreateReminder creates a new study reminder with validation
func (s *UserService) CreateReminder(userID uuid.UUID, req *models.CreateReminderRequest) (*models.StudyReminder, error) {
	// Validate time format (simplified - in production, parse and validate HH:MM:SS)
	if len(req.ReminderTime) < 8 {
		return nil, fmt.Errorf("invalid time format, use HH:MM:SS")
	}

	reminder := &models.StudyReminder{
		ID:           uuid.New(),
		UserID:       userID,
		ReminderType: req.ReminderType,
		Title:        req.Title,
		Message:      req.Message,
		ReminderTime: req.ReminderTime,
		DaysOfWeek:   req.DaysOfWeek,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	err := s.repo.CreateReminder(reminder)
	if err != nil {
		return nil, err
	}

	return reminder, nil
}

// GetUserReminders retrieves all reminders for a user
func (s *UserService) GetUserReminders(userID uuid.UUID) ([]models.StudyReminder, error) {
	return s.repo.GetUserReminders(userID)
}

// UpdateReminder updates a study reminder
func (s *UserService) UpdateReminder(reminderID uuid.UUID, userID uuid.UUID, req *models.UpdateReminderRequest) (*models.StudyReminder, error) {
	reminder, err := s.repo.GetReminderByID(reminderID, userID)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if req.Title != nil {
		reminder.Title = *req.Title
	}
	if req.Message != nil {
		reminder.Message = req.Message
	}
	if req.ReminderTime != nil {
		reminder.ReminderTime = *req.ReminderTime
	}
	if req.DaysOfWeek != nil {
		reminder.DaysOfWeek = req.DaysOfWeek
	}
	if req.IsActive != nil {
		reminder.IsActive = *req.IsActive
	}

	reminder.UpdatedAt = time.Now()

	err = s.repo.UpdateReminder(reminder)
	if err != nil {
		return nil, err
	}

	return reminder, nil
}

// DeleteReminder deletes a study reminder
func (s *UserService) DeleteReminder(reminderID uuid.UUID, userID uuid.UUID) error {
	return s.repo.DeleteReminder(reminderID, userID)
}

// ToggleReminder toggles the active status of a reminder automatically and returns the updated reminder
func (s *UserService) ToggleReminder(reminderID uuid.UUID, userID uuid.UUID) (*models.StudyReminder, error) {
	return s.repo.ToggleReminder(reminderID, userID)
}

// ============= Leaderboard =============

// GetLeaderboard retrieves top learners with optional period filtering
func (s *UserService) GetLeaderboard(period string, page, limit int) ([]models.LeaderboardEntry, int, error) {
	if limit <= 0 || limit > 100 {
		limit = 50 // Default limit
	}
	if page < 1 {
		page = 1
	}
	return s.repo.GetTopLearners(period, page, limit)
}

// GetUserRank retrieves the rank of a specific user
func (s *UserService) GetUserRank(userID uuid.UUID) (*models.LeaderboardEntry, error) {
	return s.repo.GetUserRank(userID)
}

// ============= User Follows =============

// FollowUser creates a follow relationship
func (s *UserService) FollowUser(followerID, followingID uuid.UUID) error {
	// Prevent self-follow
	if followerID == followingID {
		return fmt.Errorf("cannot follow yourself")
	}

	// Check if target user's profile is private
	prefs, err := s.repo.GetPreferences(followingID)
	if err == nil && prefs != nil {
		visibility := prefs.ProfileVisibility
		if visibility == "" {
			visibility = "public" // Default to public
		}

		// If profile is private, don't allow follow
		if visibility == "private" {
			return fmt.Errorf("cannot follow private profile")
		}

		// If profile is friends-only, check if followingID is following followerID
		// (one-way friendship: target user must follow requester first)
		if visibility == "friends" {
			isFriend, err := s.repo.IsFollowing(followingID, followerID) // Check if target user follows the requester
			if err != nil || !isFriend {
				return fmt.Errorf("cannot follow friends-only profile")
			}
		}
	}

	err = s.repo.CreateFollow(followerID, followingID)
	if err != nil {
		return err
	}

	// Send notification to the user being followed (async, non-blocking)
	if s.notificationClient != nil {
		go func() {
			defer func() {
				if r := recover(); r != nil {
					log.Printf("[User-Service] PANIC in follow notification: %v", r)
				}
			}()

			// Get follower's profile for notification
			followerProfile, err := s.repo.GetProfileByUserID(followerID)
			if err != nil {
				log.Printf("[User-Service] ⚠️  Failed to get follower profile for notification: %v", err)
				return
			}

			// Build follower name
			followerName := "Một người dùng"
			if followerProfile != nil && followerProfile.FullName != nil && *followerProfile.FullName != "" {
				followerName = *followerProfile.FullName
			}

			// Send notification with translation keys
			actionType := "navigate_to_user_profile"
			notificationErr := s.notificationClient.SendNotification(client.SendNotificationRequest{
				UserID:     followingID.String(),
				Title:      "notifications.new_follower_title",   // Translation key
				Message:    "notifications.new_follower_message", // Translation key
				Type:       "social",
				Category:   "info",
				ActionType: &actionType,
				ActionData: map[string]interface{}{
					"user_id":       followerID.String(),
					"follower_name": followerName, // For template replacement
				},
				Priority: "normal",
			})

			if notificationErr != nil {
				log.Printf("[User-Service] ⚠️  Failed to send follow notification: %v", notificationErr)
			} else {
				log.Printf("[User-Service] ✅ Sent follow notification to user %s", followingID.String())
			}
		}()
	}

	return nil
}

// UnfollowUser removes a follow relationship
func (s *UserService) UnfollowUser(followerID, followingID uuid.UUID) error {
	return s.repo.DeleteFollow(followerID, followingID)
}

// RemoveFollower removes a follower from user's followers list (user removes someone who follows them)
func (s *UserService) RemoveFollower(followingID, followerID uuid.UUID) error {
	// Prevent removing yourself as a follower (shouldn't happen, but safety check)
	if followingID == followerID {
		return fmt.Errorf("cannot remove yourself")
	}
	return s.repo.RemoveFollower(followingID, followerID)
}

// GetFollowers gets the list of followers for a user (paginated)
func (s *UserService) GetFollowers(userID uuid.UUID, requestingUserID *uuid.UUID, page, limit int) ([]models.UserFollowInfo, int, error) {
	// Check if requesting user can view this profile's followers
	isOwner := requestingUserID != nil && *requestingUserID == userID
	if !isOwner {
		// For non-owners, check profile visibility
		prefs, err := s.repo.GetPreferences(userID)
		if err == nil && prefs != nil {
			visibility := prefs.ProfileVisibility
			if visibility == "" {
				visibility = "public"
			}

			// Private profiles: only owner can see followers
			if visibility == "private" {
				return nil, 0, fmt.Errorf("followers list is private")
			}

			// Friends-only: check if userID follows requestingUserID
			if visibility == "friends" {
				if requestingUserID == nil {
					return nil, 0, fmt.Errorf("followers list is only visible to friends")
				}
				isFriend, err := s.repo.IsFollowing(userID, *requestingUserID)
				if err != nil || !isFriend {
					return nil, 0, fmt.Errorf("followers list is only visible to friends")
				}
			}
		}
	}

	return s.repo.GetFollowers(userID, page, limit)
}

// GetFollowing gets the list of users a user is following (paginated)
func (s *UserService) GetFollowing(userID uuid.UUID, requestingUserID *uuid.UUID, page, limit int) ([]models.UserFollowInfo, int, error) {
	// Check if requesting user can view this profile's following list
	isOwner := requestingUserID != nil && *requestingUserID == userID
	if !isOwner {
		// For non-owners, check profile visibility
		prefs, err := s.repo.GetPreferences(userID)
		if err == nil && prefs != nil {
			visibility := prefs.ProfileVisibility
			if visibility == "" {
				visibility = "public"
			}

			// Private profiles: only owner can see following list
			if visibility == "private" {
				return nil, 0, fmt.Errorf("following list is private")
			}

			// Friends-only: check if userID follows requestingUserID
			if visibility == "friends" {
				if requestingUserID == nil {
					return nil, 0, fmt.Errorf("following list is only visible to friends")
				}
				isFriend, err := s.repo.IsFollowing(userID, *requestingUserID)
				if err != nil || !isFriend {
					return nil, 0, fmt.Errorf("following list is only visible to friends")
				}
			}
		}
	}

	return s.repo.GetFollowing(userID, page, limit)
}

// GetPublicAchievements gets achievements for a public user profile
func (s *UserService) GetPublicAchievements(userID uuid.UUID) ([]models.UserAchievement, error) {
	return s.repo.GetUserAchievements(userID)
}

// ============= Internal Service Methods =============

// CreateProfile creates a user profile (called internally by other services)
func (s *UserService) CreateProfile(profile *models.UserProfile) error {
	// Ensure learning progress exists
	return s.repo.CreateProfile(profile.UserID)
}

// CreateProfileWithData creates a new user profile with full name and target band score
func (s *UserService) CreateProfileWithData(userID uuid.UUID, fullName string, targetBandScore float64) error {
	return s.repo.CreateProfileWithData(userID, fullName, targetBandScore)
}

// UpdateProgress updates user learning progress using atomic operations
func (s *UserService) UpdateProgress(userID uuid.UUID, updates map[string]interface{}) error {
	// Ensure progress record exists
	progress, err := s.repo.GetLearningProgress(userID)
	if err != nil || progress == nil {
		// Create progress if doesn't exist
		if err := s.repo.CreateLearningProgress(userID); err != nil {
			return fmt.Errorf("create learning progress: %w", err)
		}
		progress, err = s.repo.GetLearningProgress(userID)
		if err != nil {
			return err
		}
	}

	// Calculate streak logic (requires current state)
	now := time.Now()
	todayDate := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	streakUpdate := make(map[string]interface{})
	if progress.LastStudyDate != nil {
		// Compare date-only parts (fix timezone issues)
		lastDateOnly := time.Date(progress.LastStudyDate.Year(), progress.LastStudyDate.Month(),
			progress.LastStudyDate.Day(), 0, 0, 0, 0, time.UTC)
		daysSince := int(todayDate.Sub(lastDateOnly).Hours() / 24)

		if daysSince == 1 {
			// Consecutive day - increment streak
			streakUpdate["increment_current_streak"] = 1
			streakUpdate["update_longest_if_needed"] = true
		} else if daysSince > 1 {
			// Streak broken - reset to 1
			streakUpdate["current_streak_days"] = 1
		}
		// If daysSince == 0, same day, don't change streak
	} else {
		// First time studying - start streak
		streakUpdate["current_streak_days"] = 1
		streakUpdate["longest_streak_days"] = 1
	}

	// Always update last study date
	updates["last_study_date"] = todayDate

	// Merge streak updates
	for k, v := range streakUpdate {
		updates[k] = v
	}

	// Use repository method for atomic update
	err = s.repo.UpdateLearningProgressAtomic(userID, updates)
	if err != nil {
		return err
	}

	// Check achievements after progress update (async)
	// This handles achievements for streaks, exercises, and scores
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("❌ PANIC in CheckAndUnlockAchievements from UpdateProgress: %v", r)
			}
		}()
		if err := s.CheckAndUnlockAchievements(userID); err != nil {
			log.Printf("⚠️  Failed to check achievements after progress update: %v", err)
		}
	}()

	return nil
}

// UpdateSkillStatistics updates skill-specific statistics
func (s *UserService) UpdateSkillStatistics(userID uuid.UUID, skillType string, updates map[string]interface{}) error {
	stats, err := s.repo.GetSkillStatistics(userID, skillType)
	if err != nil || stats == nil {
		// Create stats if doesn't exist
		if err := s.repo.CreateSkillStatistics(userID, skillType); err != nil {
			return fmt.Errorf("create skill statistics: %w", err)
		}
		// Fetch the newly created stats
		stats, err = s.repo.GetSkillStatistics(userID, skillType)
		if err != nil {
			return fmt.Errorf("get skill statistics after creation: %w", err)
		}
	}

	// Apply updates
	if score, ok := updates["score"].(float64); ok {
		// Calculate new average BEFORE incrementing count (clearer logic)
		if stats.TotalPractices == 0 {
			// First practice
			stats.AverageScore = score
		} else {
			// Calculate total sum from average, add new score, divide by new count
			totalSum := stats.AverageScore * float64(stats.TotalPractices)
			stats.AverageScore = (totalSum + score) / float64(stats.TotalPractices+1)
		}

		// NOW increment counters
		stats.TotalPractices++
		if isCompleted, _ := updates["is_completed"].(bool); isCompleted {
			stats.CompletedPractices++
		}

		// Update best score
		if score > stats.BestScore {
			stats.BestScore = score
		}

		stats.LastPracticeScore = &score
	}

	if timeMinutes, ok := updates["time_minutes"].(int); ok && timeMinutes > 0 {
		stats.TotalTimeMinutes += timeMinutes
	}

	now := time.Now()
	stats.LastPracticeDate = &now

	// Convert stats struct to map for update
	updateMap := make(map[string]interface{})
	updateMap["total_practices"] = stats.TotalPractices
	updateMap["completed_practices"] = stats.CompletedPractices
	updateMap["average_score"] = stats.AverageScore
	updateMap["best_score"] = stats.BestScore
	updateMap["total_time_minutes"] = stats.TotalTimeMinutes
	updateMap["last_practice_date"] = stats.LastPracticeDate
	updateMap["last_practice_score"] = stats.LastPracticeScore

	// Update skill statistics
	err = s.repo.UpdateSkillStatistics(userID, skillType, updateMap)
	if err != nil {
		return err
	}

	// Also update learning_progress.{skill}_score with the latest score
	// This keeps learning_progress in sync with skill_statistics
	if score, ok := updates["score"].(float64); ok {
		progressUpdates := make(map[string]interface{})
		// Map skill type to learning_progress field
		switch skillType {
		case "listening":
			progressUpdates["listening_score"] = score
		case "reading":
			progressUpdates["reading_score"] = score
		case "writing":
			progressUpdates["writing_score"] = score
		case "speaking":
			progressUpdates["speaking_score"] = score
		}

		// Update learning_progress with skill score
		// This will also trigger overall_score recalculation
		if len(progressUpdates) > 0 {
			return s.UpdateProgress(userID, progressUpdates)
		}
	}

	return nil
}

// StartSession starts a study session (internal)
func (s *UserService) StartSession(session *models.StudySession) (*uuid.UUID, error) {
	session.ID = uuid.New()
	session.StartedAt = time.Now()
	session.IsCompleted = false

	if err := s.repo.CreateStudySession(session); err != nil {
		return nil, err
	}

	return &session.ID, nil
}

// EndSession ends a study session (internal)
func (s *UserService) EndSession(sessionID uuid.UUID, isCompleted bool, score float64) error {
	// For now, just log - full implementation needs repository methods
	log.Printf("📝 Session ended: %s, completed=%v, score=%.2f", sessionID, isCompleted, score)
	// TODO: Implement when repository methods are ready
	return nil
}

// RecordCompletedSession creates a completed study session record
func (s *UserService) RecordCompletedSession(session *models.StudySession) error {
	return s.repo.CreateStudySession(session)
}

// ============= Official Test Results =============

// RecordOfficialTestResult records an official test result for ONE skill and updates user progress
// Per-skill model: Each call handles one skill test
// Uses transaction to ensure atomicity of all database operations
func (s *UserService) RecordOfficialTestResult(result *models.OfficialTestResult) error {
	// Begin transaction for atomicity
	tx, err := s.repo.BeginTx()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			log.Printf("❌ Panic in RecordOfficialTestResult: %v", r)
		}
	}()

	// 1. Save test result to database (per-skill record)
	if err := s.repo.CreateOfficialTestResultTx(tx, result); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to create test result: %w", err)
	}

	// 2. Update learning_progress for THIS skill only
	if result.BandScore > 0 {
		if err := s.repo.UpdateLearningProgressWithTestScoreTx(
			tx,
			result.UserID,
			result.SkillType,
			result.BandScore,
			true, // increment test count
		); err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to update learning progress for %s: %w", result.SkillType, err)
		}
		log.Printf("✅ Updated %s score: %.1f", result.SkillType, result.BandScore)
	} else {
		// Note: band_score=0 is not a valid IELTS score, but we allow it for edge cases
		log.Printf("⚠️  Warning: Band score is 0 for skill %s", result.SkillType)
	}

	// 3. Always recalculate overall score from all available skills after any skill update
	progress, err := s.repo.GetLearningProgressTx(tx, result.UserID)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to get learning progress: %w", err)
	}

	if progress != nil {
		// Calculate average of all available skills
		// BUSINESS RULE: Skip skills with band_score = 0
		// Why? In IELTS scoring system:
		// - Valid band scores: 1.0, 1.5, 2.0, ..., 8.5, 9.0 (half-band increments)
		// - 0.0 is NOT a valid IELTS band score
		// - 0.0 means: not tested, test not completed, or data error
		// - Including 0 in average would incorrectly lower overall score
		// Example: If user has Reading=7.0, Listening=0 (not tested), Writing=6.5
		//   Correct: (7.0 + 6.5) / 2 = 6.75 (skip the 0)
		//   Wrong:   (7.0 + 0 + 6.5) / 3 = 4.5 (includes 0, wrong!)
		totalScore := 0.0
		skillCount := 0
		if progress.ListeningScore != nil && *progress.ListeningScore > 0 {
			totalScore += *progress.ListeningScore
			skillCount++
		}
		if progress.ReadingScore != nil && *progress.ReadingScore > 0 {
			totalScore += *progress.ReadingScore
			skillCount++
		}
		if progress.WritingScore != nil && *progress.WritingScore > 0 {
			totalScore += *progress.WritingScore
			skillCount++
		}
		if progress.SpeakingScore != nil && *progress.SpeakingScore > 0 {
			totalScore += *progress.SpeakingScore
			skillCount++
		}

		if skillCount > 0 {
			newOverall := totalScore / float64(skillCount)
			if err := s.repo.UpdateLearningProgressWithTestScoreTx(
				tx,
				result.UserID,
				"overall",
				newOverall,
				false,
			); err != nil {
				tx.Rollback()
				return fmt.Errorf("failed to update overall score: %w", err)
			}
			log.Printf("✅ Recalculated overall score from %d skills: %.1f", skillCount, newOverall)
		}
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	log.Printf("✅ Recorded official test result for user %s (skill: %s, score: %.1f)",
		result.UserID, result.SkillType, result.BandScore)
	return nil
}

// ============= Practice Activities =============

// RecordPracticeActivity records a practice activity and updates statistics
func (s *UserService) RecordPracticeActivity(activity *models.PracticeActivity) error {
	// 1. Save practice activity to database
	if err := s.repo.CreatePracticeActivity(activity); err != nil {
		return fmt.Errorf("failed to create practice activity: %w", err)
	}

	// 2. Update skill_statistics (practice stats only - NOT official scores)
	if activity.CompletionStatus == "completed" {
		// Get current stats
		statsMap, err := s.repo.GetAllSkillStatistics(activity.UserID)
		if err != nil {
			log.Printf("⚠️  Failed to get skill statistics: %v", err)
		} else {
			stats, exists := statsMap[activity.Skill]
			if !exists {
				// Create new stats entry
				stats = &models.SkillStatistics{
					UserID:    activity.UserID,
					SkillType: activity.Skill,
				}
			}

			// Update stats
			stats.TotalPractices++
			stats.CompletedPractices++

			if activity.Score != nil {
				// Recalculate average score
				if stats.AverageScore == 0 {
					stats.AverageScore = *activity.Score
				} else {
					stats.AverageScore = (stats.AverageScore*float64(stats.CompletedPractices-1) + *activity.Score) / float64(stats.CompletedPractices)
				}

				// Update best score
				if *activity.Score > stats.BestScore {
					stats.BestScore = *activity.Score
				}

				stats.LastPracticeScore = activity.Score
			}

			if activity.TimeSpentSeconds != nil {
				stats.TotalTimeMinutes += *activity.TimeSpentSeconds / 60
			}

			if activity.CompletedAt != nil {
				stats.LastPracticeDate = activity.CompletedAt
			}

			// Save updated stats
			if err := s.repo.UpsertSkillStatistics(stats); err != nil {
				log.Printf("⚠️  Failed to update skill statistics: %v", err)
			}
		}

		// 3. Increment exercises_completed in learning_progress
		updates := map[string]interface{}{
			"total_exercises_completed": "total_exercises_completed + 1",
		}
		if err := s.repo.UpdateLearningProgress(activity.UserID, updates); err != nil {
			log.Printf("⚠️  Failed to update exercises completed: %v", err)
		}

		// 4. Check and unlock achievements (async to avoid blocking)
		go func() {
			defer func() {
				if r := recover(); r != nil {
					log.Printf("❌ PANIC in CheckAndUnlockAchievements: %v", r)
				}
			}()
			if err := s.CheckAndUnlockAchievements(activity.UserID); err != nil {
				log.Printf("⚠️  Failed to check achievements: %v", err)
			}
		}()
	}

	log.Printf("✅ Recorded practice activity for user %s: skill=%s, type=%s",
		activity.UserID, activity.Skill, activity.ActivityType)
	return nil
}
