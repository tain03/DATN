package repository

import (
	"database/sql"
	"fmt"
	"log"
	"math"
	"strings"
	"time"

	"github.com/bisosad1501/DATN/services/user-service/internal/config"
	"github.com/bisosad1501/DATN/services/user-service/internal/database"
	"github.com/bisosad1501/DATN/services/user-service/internal/models"
	"github.com/google/uuid"
)

// calculateIELTSOverallScore calculates overall band score using official IELTS rounding rules
// Formula: (Listening + Reading + Writing + Speaking) / 4
// Rounding rules:
// - If ends in .25 → round UP to next .5
// - If ends in .75 → round UP to next 1.0
// - Otherwise → round DOWN to nearest .5 or 1.0
func calculateIELTSOverallScore(average float64) float64 {
	// Extract decimal part
	decimal := average - math.Floor(average)

	// IELTS rounding rules
	if decimal == 0.25 {
		return math.Floor(average) + 0.5 // 6.25 → 6.5
	} else if decimal == 0.75 {
		return math.Floor(average) + 1.0 // 6.75 → 7.0
	} else if decimal < 0.25 {
		return math.Floor(average) // 6.1 → 6.0
	} else if decimal < 0.75 {
		return math.Floor(average) + 0.5 // 6.6 → 6.5
	} else {
		return math.Floor(average) + 1.0 // 6.9 → 7.0
	}
}

type UserRepository struct {
	db     *database.Database
	config *config.Config
}

func NewUserRepository(db *database.Database, cfg *config.Config) *UserRepository {
	return &UserRepository{db: db, config: cfg}
}

// Transaction support methods

// BeginTx starts a new database transaction
func (r *UserRepository) BeginTx() (*sql.Tx, error) {
	return r.db.DB.Begin()
}

// CreateOfficialTestResultTx creates an official test result within a transaction
func (r *UserRepository) CreateOfficialTestResultTx(tx *sql.Tx, result *models.OfficialTestResult) error {
	query := `
		INSERT INTO official_test_results (
			user_id, test_type, skill_type, ielts_variant, band_score,
			raw_score, total_questions,
			source_service, source_table, source_id,
			test_date, test_duration_minutes, completion_status,
			test_source, notes
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
		) RETURNING id, created_at, updated_at`

	err := tx.QueryRow(
		query,
		result.UserID,
		result.TestType,
		result.SkillType,
		result.IELTSVariant,
		result.BandScore,
		result.RawScore,
		result.TotalQuestions,
		result.SourceService,
		result.SourceTable,
		result.SourceID,
		result.TestDate,
		result.TestDurationMinutes,
		result.CompletionStatus,
		result.TestSource,
		result.Notes,
	).Scan(&result.ID, &result.CreatedAt, &result.UpdatedAt)

	if err != nil {
		log.Printf("❌ Error creating official test result for user %s: %v", result.UserID, err)
		return fmt.Errorf("failed to create official test result: %w", err)
	}

	log.Printf("✅ Created official test result %s for user %s (%s: %.1f)",
		result.ID, result.UserID, result.SkillType, result.BandScore)
	return nil
}

// UpdateLearningProgressWithTestScoreTx updates learning progress within a transaction
func (r *UserRepository) UpdateLearningProgressWithTestScoreTx(
	tx *sql.Tx,
	userID uuid.UUID,
	skillType string,
	bandScore float64,
	incrementTestCount bool,
) error {
	// Build update query dynamically based on skill type
	var scoreColumn string
	switch skillType {
	case "listening":
		scoreColumn = "listening_score"
	case "reading":
		scoreColumn = "reading_score"
	case "writing":
		scoreColumn = "writing_score"
	case "speaking":
		scoreColumn = "speaking_score"
	case "overall":
		scoreColumn = "overall_score"
	default:
		return fmt.Errorf("invalid skill type: %s", skillType)
	}

	// Update score (and optionally increment total test count for individual skills)
	// FIX #11: Use atomic increment to avoid race condition
	// OLD: COALESCE(total_tests_taken, 0) + 1  ❌ (read-modify-write race)
	// NEW: total_tests_taken + 1  ✅ (atomic at SQL level)
	query := fmt.Sprintf(`
		UPDATE learning_progress
		SET %s = $1,
			updated_at = CURRENT_TIMESTAMP
	`, scoreColumn)

	args := []interface{}{bandScore}
	paramCount := 1

	// For individual skills (not overall), increment total_tests_taken atomically
	if incrementTestCount && skillType != "overall" {
		// Atomic increment: PostgreSQL ensures this is thread-safe
		// Even with concurrent transactions, each will increment correctly
		query += ", total_tests_taken = total_tests_taken + 1"
	}

	paramCount++
	query += fmt.Sprintf(" WHERE user_id = $%d", paramCount)
	args = append(args, userID)

	_, err := tx.Exec(query, args...)
	if err != nil {
		return fmt.Errorf("failed to update learning progress: %w", err)
	}

	log.Printf("✅ Updated learning progress for user %s: %s = %.1f", userID, skillType, bandScore)
	return nil
}

// GetLearningProgressTx retrieves learning progress within a transaction
func (r *UserRepository) GetLearningProgressTx(tx *sql.Tx, userID uuid.UUID) (*models.LearningProgress, error) {
	query := `
		SELECT 
			lp.id, lp.user_id,
			lp.total_lessons_completed, lp.total_exercises_completed,
			lp.listening_progress, lp.reading_progress, lp.writing_progress, lp.speaking_progress,
			lp.listening_score, lp.reading_score, lp.writing_score, lp.speaking_score,
			lp.overall_score, lp.current_streak_days, lp.longest_streak_days, lp.last_study_date,
			lp.created_at, lp.updated_at
		FROM learning_progress lp
		WHERE lp.user_id = $1
	`

	progress := &models.LearningProgress{}
	err := tx.QueryRow(query, userID).Scan(
		&progress.ID, &progress.UserID,
		&progress.TotalLessonsCompleted, &progress.TotalExercisesCompleted,
		&progress.ListeningProgress, &progress.ReadingProgress,
		&progress.WritingProgress, &progress.SpeakingProgress, &progress.ListeningScore,
		&progress.ReadingScore, &progress.WritingScore, &progress.SpeakingScore,
		&progress.OverallScore, &progress.CurrentStreakDays, &progress.LongestStreakDays,
		&progress.LastStudyDate, &progress.CreatedAt, &progress.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		log.Printf("❌ Error getting learning progress for user %s: %v", userID, err)
		return nil, fmt.Errorf("failed to get learning progress: %w", err)
	}

	// Calculate total_study_hours from study_sessions (within same transaction)
	var totalStudyHours float64
	studyHoursQuery := `
		SELECT COALESCE(ROUND((SUM(duration_minutes) / 60.0)::numeric, 2), 0)
		FROM study_sessions 
		WHERE user_id = $1
	`
	err = tx.QueryRow(studyHoursQuery, userID).Scan(&totalStudyHours)
	if err != nil {
		log.Printf("⚠️  Error calculating total_study_hours for user %s: %v", userID, err)
		totalStudyHours = 0
	}
	progress.TotalStudyHours = totalStudyHours

	return progress, nil
}

// getDBLinkConnectionString builds dblink connection string from config
// Returns properly escaped string for use in SQL queries
func (r *UserRepository) getDBLinkConnectionString(dbName string) string {
	// Use same password from config, assume same user and host
	// Escape single quotes in password if needed
	password := r.config.DBPassword
	password = strings.ReplaceAll(password, "'", "''")
	return fmt.Sprintf("dbname=%s user=%s password=%s", dbName, r.config.DBUser, password)
}

// CreateProfile creates a new user profile
func (r *UserRepository) CreateProfile(userID uuid.UUID) error {
	return r.CreateProfileWithData(userID, "", 0)
}

// CreateProfileWithData creates a new user profile with full name and target band score
func (r *UserRepository) CreateProfileWithData(userID uuid.UUID, fullName string, targetBandScore float64) error {
	// Build query dynamically based on provided data
	query := `
		INSERT INTO user_profiles (user_id, timezone, language_preference`
	values := `VALUES ($1, $2, $3`
	args := []interface{}{userID, "Asia/Ho_Chi_Minh", "vi"}
	argCount := 3

	if fullName != "" {
		argCount++
		query += `, full_name`
		values += `, $` + fmt.Sprintf("%d", argCount)
		args = append(args, fullName)
	}

	if targetBandScore > 0 {
		argCount++
		query += `, target_band_score`
		values += `, $` + fmt.Sprintf("%d", argCount)
		args = append(args, targetBandScore)
	}

	// Build UPDATE clause for ON CONFLICT
	updateClause := ""
	if fullName != "" {
		updateClause += ` full_name = EXCLUDED.full_name,`
	}
	if targetBandScore > 0 {
		updateClause += ` target_band_score = EXCLUDED.target_band_score,`
	}
	if updateClause != "" {
		updateClause += ` updated_at = CURRENT_TIMESTAMP`
	} else {
		// If no fields to update, just update timestamp
		updateClause = ` updated_at = CURRENT_TIMESTAMP`
	}

	query += `) ` + values + `)
		ON CONFLICT (user_id) DO UPDATE SET ` + updateClause

	log.Printf("🔍 Creating profile for user %s with fullName='%s' (len=%d), targetBandScore=%.1f", userID, fullName, len(fullName), targetBandScore)

	_, err := r.db.DB.Exec(query, args...)
	if err != nil {
		log.Printf("❌ Error creating profile for user %s: %v", userID, err)
		return fmt.Errorf("failed to create profile: %w", err)
	}

	// Also create learning progress record
	progressQuery := `
		INSERT INTO learning_progress (user_id)
		VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING
	`
	_, err = r.db.DB.Exec(progressQuery, userID)
	if err != nil {
		log.Printf("❌ Error creating learning progress for user %s: %v", userID, err)
		return fmt.Errorf("failed to create learning progress: %w", err)
	}

	log.Printf("✅ Profile created for user: %s (fullName: %s, targetBandScore: %.1f)", userID, fullName, targetBandScore)
	return nil
}

// GetProfileByUserID retrieves user profile by user ID
func (r *UserRepository) GetProfileByUserID(userID uuid.UUID) (*models.UserProfile, error) {
	query := `
		SELECT user_id, first_name, last_name, full_name, date_of_birth, gender,
		       phone, address, city, country, timezone, avatar_url, cover_image_url,
		       current_level, target_band_score, target_exam_date, bio,
		       learning_preferences, language_preference, created_at, updated_at
		FROM user_profiles
		WHERE user_id = $1 AND deleted_at IS NULL
	`

	profile := &models.UserProfile{}
	err := r.db.DB.QueryRow(query, userID).Scan(
		&profile.UserID, &profile.FirstName, &profile.LastName, &profile.FullName,
		&profile.DateOfBirth, &profile.Gender, &profile.Phone, &profile.Address,
		&profile.City, &profile.Country, &profile.Timezone, &profile.AvatarURL,
		&profile.CoverImageURL, &profile.CurrentLevel, &profile.TargetBandScore,
		&profile.TargetExamDate, &profile.Bio, &profile.LearningPreferences,
		&profile.LanguagePreference, &profile.CreatedAt, &profile.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		log.Printf("❌ Error getting profile for user %s: %v", userID, err)
		return nil, fmt.Errorf("failed to get profile: %w", err)
	}

	return profile, nil
}

// UpdateProfile updates user profile
func (r *UserRepository) UpdateProfile(userID uuid.UUID, req *models.UpdateProfileRequest) error {
	// Build dynamic update query
	query := `UPDATE user_profiles SET updated_at = CURRENT_TIMESTAMP`
	args := []interface{}{userID}
	paramCount := 1

	// full_name takes priority if provided directly
	if req.FullName != nil {
		paramCount++
		query += fmt.Sprintf(", full_name = $%d", paramCount)
		args = append(args, *req.FullName)
	} else if req.FirstName != nil && req.LastName != nil {
		// Auto-generate full_name if both first and last name are provided (and full_name not provided)
		paramCount++
		query += fmt.Sprintf(", full_name = $%d", paramCount)
		args = append(args, fmt.Sprintf("%s %s", *req.FirstName, *req.LastName))
	}

	if req.FirstName != nil {
		paramCount++
		query += fmt.Sprintf(", first_name = $%d", paramCount)
		args = append(args, *req.FirstName)
	}
	if req.LastName != nil {
		paramCount++
		query += fmt.Sprintf(", last_name = $%d", paramCount)
		args = append(args, *req.LastName)
	}
	if req.DateOfBirth != nil {
		paramCount++
		query += fmt.Sprintf(", date_of_birth = $%d", paramCount)
		args = append(args, *req.DateOfBirth)
	}
	if req.Gender != nil {
		paramCount++
		query += fmt.Sprintf(", gender = $%d", paramCount)
		args = append(args, *req.Gender)
	}
	if req.Phone != nil {
		paramCount++
		query += fmt.Sprintf(", phone = $%d", paramCount)
		args = append(args, *req.Phone)
	}
	if req.Address != nil {
		paramCount++
		query += fmt.Sprintf(", address = $%d", paramCount)
		args = append(args, *req.Address)
	}
	if req.City != nil {
		paramCount++
		query += fmt.Sprintf(", city = $%d", paramCount)
		args = append(args, *req.City)
	}
	if req.Country != nil {
		paramCount++
		query += fmt.Sprintf(", country = $%d", paramCount)
		args = append(args, *req.Country)
	}
	if req.Timezone != nil {
		paramCount++
		query += fmt.Sprintf(", timezone = $%d", paramCount)
		args = append(args, *req.Timezone)
	}
	if req.CurrentLevel != nil {
		paramCount++
		query += fmt.Sprintf(", current_level = $%d", paramCount)
		args = append(args, *req.CurrentLevel)
	}
	if req.TargetBandScore != nil {
		paramCount++
		query += fmt.Sprintf(", target_band_score = $%d", paramCount)
		args = append(args, *req.TargetBandScore)
	}
	if req.TargetExamDate != nil {
		paramCount++
		query += fmt.Sprintf(", target_exam_date = $%d", paramCount)
		args = append(args, *req.TargetExamDate)
	}
	if req.Bio != nil {
		paramCount++
		query += fmt.Sprintf(", bio = $%d", paramCount)
		args = append(args, *req.Bio)
	}
	if req.LearningPreferences != nil {
		paramCount++
		query += fmt.Sprintf(", learning_preferences = $%d", paramCount)
		args = append(args, *req.LearningPreferences)
	}
	if req.LanguagePreference != nil {
		paramCount++
		query += fmt.Sprintf(", language_preference = $%d", paramCount)
		args = append(args, *req.LanguagePreference)
	}

	query += " WHERE user_id = $1"

	result, err := r.db.DB.Exec(query, args...)
	if err != nil {
		log.Printf("❌ Error updating profile for user %s: %v", userID, err)
		return fmt.Errorf("failed to update profile: %w", err)
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("profile not found")
	}

	log.Printf("✅ Profile updated for user: %s", userID)
	return nil
}

// UpdateAvatar updates user avatar URL
func (r *UserRepository) UpdateAvatar(userID uuid.UUID, avatarURL string) error {
	query := `
		UPDATE user_profiles
		SET avatar_url = $1, updated_at = CURRENT_TIMESTAMP
		WHERE user_id = $2
	`
	_, err := r.db.DB.Exec(query, avatarURL, userID)
	if err != nil {
		log.Printf("❌ Error updating avatar for user %s: %v", userID, err)
		return fmt.Errorf("failed to update avatar: %w", err)
	}

	log.Printf("✅ Avatar updated for user: %s", userID)
	return nil
}

// GetLearningProgress retrieves learning progress for a user with REAL-TIME study hours
func (r *UserRepository) GetLearningProgress(userID uuid.UUID) (*models.LearningProgress, error) {
	// 📊 Query learning_progress (without deprecated total_study_hours field)
	query := `
		SELECT 
			lp.id, lp.user_id,
			lp.total_lessons_completed, lp.total_exercises_completed,
			lp.listening_progress, lp.reading_progress, lp.writing_progress, lp.speaking_progress,
			lp.listening_score, lp.reading_score, lp.writing_score, lp.speaking_score,
			lp.overall_score, lp.current_streak_days, lp.longest_streak_days, lp.last_study_date,
			lp.created_at, lp.updated_at
		FROM learning_progress lp
		WHERE lp.user_id = $1
	`

	progress := &models.LearningProgress{}
	err := r.db.DB.QueryRow(query, userID).Scan(
		&progress.ID, &progress.UserID,
		&progress.TotalLessonsCompleted, &progress.TotalExercisesCompleted,
		&progress.ListeningProgress, &progress.ReadingProgress,
		&progress.WritingProgress, &progress.SpeakingProgress, &progress.ListeningScore,
		&progress.ReadingScore, &progress.WritingScore, &progress.SpeakingScore,
		&progress.OverallScore, &progress.CurrentStreakDays, &progress.LongestStreakDays,
		&progress.LastStudyDate, &progress.CreatedAt, &progress.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		log.Printf("❌ Error getting learning progress for user %s: %v", userID, err)
		return nil, fmt.Errorf("failed to get learning progress: %w", err)
	}

	// 📊 SOURCE OF TRUTH: Calculate total_study_hours from study_sessions (real-time)
	var totalStudyHours float64
	studyHoursQuery := `
		SELECT COALESCE(ROUND((SUM(duration_minutes) / 60.0)::numeric, 2), 0)
		FROM study_sessions 
		WHERE user_id = $1
	`
	err = r.db.DB.QueryRow(studyHoursQuery, userID).Scan(&totalStudyHours)
	if err != nil {
		log.Printf("⚠️  Error calculating total_study_hours for user %s: %v", userID, err)
		totalStudyHours = 0
	}
	progress.TotalStudyHours = totalStudyHours

	return progress, nil
}

// CreateLearningProgress creates a new learning progress record
func (r *UserRepository) CreateLearningProgress(userID uuid.UUID) error {
	query := `
		INSERT INTO learning_progress (user_id)
		VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING
	`
	_, err := r.db.DB.Exec(query, userID)
	if err != nil {
		log.Printf("❌ Error creating learning progress for user %s: %v", userID, err)
		return fmt.Errorf("failed to create learning progress: %w", err)
	}
	return nil
}

// UpdateLearningProgress updates learning progress fields
func (r *UserRepository) UpdateLearningProgress(userID uuid.UUID, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}

	// Build dynamic update query
	query := "UPDATE learning_progress SET updated_at = CURRENT_TIMESTAMP"
	args := []interface{}{}
	paramCount := 0

	for field, value := range updates {
		paramCount++
		query += fmt.Sprintf(", %s = $%d", field, paramCount)
		args = append(args, value)
	}

	paramCount++
	query += fmt.Sprintf(" WHERE user_id = $%d", paramCount)
	args = append(args, userID)

	result, err := r.db.DB.Exec(query, args...)
	if err != nil {
		log.Printf("❌ Error updating learning progress for user %s: %v", userID, err)
		return fmt.Errorf("failed to update learning progress: %w", err)
	}

	// Check if row was actually updated
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}
	if rowsAffected == 0 {
		log.Printf("⚠️  Warning: No rows updated for user %s (may not exist)", userID)
		return fmt.Errorf("learning progress not found for user %s", userID)
	}

	return nil
}

// CreateStudySession creates a new study session
func (r *UserRepository) CreateStudySession(session *models.StudySession) error {
	// Check if this is a completed session (has duration and ended_at)
	if session.DurationMinutes != nil && session.EndedAt != nil {
		// Use CreateCompletedStudySession for completed sessions
		return r.CreateCompletedStudySession(session)
	}

	// Otherwise, create regular in-progress session
	query := `
		INSERT INTO study_sessions (id, user_id, session_type, skill_type, resource_id, resource_type, started_at, device_type)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.DB.Exec(query, session.ID, session.UserID, session.SessionType,
		session.SkillType, session.ResourceID, session.ResourceType, session.StartedAt, session.DeviceType)

	if err != nil {
		log.Printf("❌ Error creating study session for user %s: %v", session.UserID, err)
		return fmt.Errorf("failed to create study session: %w", err)
	}

	log.Printf("✅ Study session created: %s for user: %s", session.ID, session.UserID)
	return nil
}

// CreateCompletedStudySession creates a completed study session with all fields
func (r *UserRepository) CreateCompletedStudySession(session *models.StudySession) error {
	query := `
		INSERT INTO study_sessions (
			id, user_id, session_type, skill_type, resource_id, resource_type,
			started_at, ended_at, duration_minutes, is_completed, score, device_type
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.DB.Exec(query,
		session.ID,
		session.UserID,
		session.SessionType,
		session.SkillType,
		session.ResourceID,
		session.ResourceType,
		session.StartedAt,
		session.EndedAt,
		session.DurationMinutes,
		session.IsCompleted,
		session.Score,
		session.DeviceType,
	)

	if err != nil {
		log.Printf("❌ Error creating completed study session for user %s: %v", session.UserID, err)
		return fmt.Errorf("failed to create completed study session: %w", err)
	}

	log.Printf("✅ Completed study session created: %s for user: %s (duration: %dm)",
		session.ID, session.UserID, *session.DurationMinutes)
	return nil
}

// EndStudySession ends a study session
func (r *UserRepository) EndStudySession(sessionID uuid.UUID, completionPercentage *float64, score *float64) error {
	endedAt := time.Now()

	// First, get the session to calculate duration
	var startedAt time.Time
	var userID uuid.UUID
	getQuery := `SELECT started_at, user_id FROM study_sessions WHERE id = $1`
	err := r.db.DB.QueryRow(getQuery, sessionID).Scan(&startedAt, &userID)
	if err != nil {
		return fmt.Errorf("session not found: %w", err)
	}

	durationMinutes := int(endedAt.Sub(startedAt).Minutes())

	query := `
		UPDATE study_sessions
		SET ended_at = $1, duration_minutes = $2, is_completed = true, 
		    completion_percentage = $3, score = $4
		WHERE id = $5
	`
	_, err = r.db.DB.Exec(query, endedAt, durationMinutes, completionPercentage, score, sessionID)
	if err != nil {
		log.Printf("❌ Error ending study session %s: %v", sessionID, err)
		return fmt.Errorf("failed to end study session: %w", err)
	}

	// Update study streak
	_, err = r.db.DB.Exec(`SELECT update_study_streak($1)`, userID)
	if err != nil {
		log.Printf("⚠️  Warning: Failed to update streak for user %s: %v", userID, err)
	}

	log.Printf("✅ Study session ended: %s (duration: %d minutes)", sessionID, durationMinutes)
	return nil
}

// GetRecentSessions retrieves recent study sessions
func (r *UserRepository) GetRecentSessions(userID uuid.UUID, page, limit int) ([]models.StudySession, int, error) {
	// Get total count first
	countQuery := `SELECT COUNT(*) FROM study_sessions WHERE user_id = $1`
	var total int
	err := r.db.DB.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count sessions: %w", err)
	}

	// Calculate offset
	offset := (page - 1) * limit

	query := `
		SELECT id, user_id, session_type, skill_type, resource_id, resource_type,
		       started_at, ended_at, duration_minutes, is_completed, completion_percentage,
		       score, device_type, created_at
		FROM study_sessions
		WHERE user_id = $1
		ORDER BY started_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get recent sessions: %w", err)
	}
	defer rows.Close()

	sessions := []models.StudySession{}
	for rows.Next() {
		session := models.StudySession{}
		err := rows.Scan(
			&session.ID, &session.UserID, &session.SessionType, &session.SkillType,
			&session.ResourceID, &session.ResourceType, &session.StartedAt, &session.EndedAt,
			&session.DurationMinutes, &session.IsCompleted, &session.CompletionPercentage,
			&session.Score, &session.DeviceType, &session.CreatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan session: %w", err)
		}
		sessions = append(sessions, session)
	}

	return sessions, total, nil
}

// GetUserAchievements retrieves user's earned achievements
func (r *UserRepository) GetUserAchievements(userID uuid.UUID) ([]models.UserAchievement, error) {
	query := `
		SELECT id, user_id, achievement_id, earned_at
		FROM user_achievements
		WHERE user_id = $1
		ORDER BY earned_at DESC
	`

	rows, err := r.db.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user achievements: %w", err)
	}
	defer rows.Close()

	achievements := []models.UserAchievement{}
	for rows.Next() {
		achievement := models.UserAchievement{}
		err := rows.Scan(&achievement.ID, &achievement.UserID, &achievement.AchievementID, &achievement.EarnedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan achievement: %w", err)
		}
		achievements = append(achievements, achievement)
	}

	return achievements, nil
}

// ============= User Follows =============

// CreateFollow creates a new follow relationship
func (r *UserRepository) CreateFollow(followerID, followingID uuid.UUID) error {
	// Prevent self-follow
	if followerID == followingID {
		return fmt.Errorf("cannot follow yourself")
	}

	query := `
		INSERT INTO user_follows (follower_id, following_id, created_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (follower_id, following_id) DO NOTHING
	`
	_, err := r.db.DB.Exec(query, followerID, followingID)
	if err != nil {
		return fmt.Errorf("failed to create follow: %w", err)
	}
	return nil
}

// DeleteFollow removes a follow relationship
func (r *UserRepository) DeleteFollow(followerID, followingID uuid.UUID) error {
	query := `
		DELETE FROM user_follows
		WHERE follower_id = $1 AND following_id = $2
	`
	result, err := r.db.DB.Exec(query, followerID, followingID)
	if err != nil {
		return fmt.Errorf("failed to delete follow: %w", err)
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("follow relationship not found")
	}
	return nil
}

// RemoveFollower removes a follower from user's followers list (user removes someone who follows them)
func (r *UserRepository) RemoveFollower(followingID, followerID uuid.UUID) error {
	query := `
		DELETE FROM user_follows
		WHERE follower_id = $1 AND following_id = $2
	`
	result, err := r.db.DB.Exec(query, followerID, followingID)
	if err != nil {
		return fmt.Errorf("failed to remove follower: %w", err)
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("follower relationship not found")
	}
	return nil
}

// IsFollowing checks if a user is following another user
func (r *UserRepository) IsFollowing(followerID, followingID uuid.UUID) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM user_follows
			WHERE follower_id = $1 AND following_id = $2
		)
	`
	var exists bool
	err := r.db.DB.QueryRow(query, followerID, followingID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check follow status: %w", err)
	}
	return exists, nil
}

// GetFollowersCount gets the count of followers for a user
func (r *UserRepository) GetFollowersCount(userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*) FROM user_follows
		WHERE following_id = $1
	`
	var count int
	err := r.db.DB.QueryRow(query, userID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get followers count: %w", err)
	}
	return count, nil
}

// GetFollowingCount gets the count of users a user is following
func (r *UserRepository) GetFollowingCount(userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*) FROM user_follows
		WHERE follower_id = $1
	`
	var count int
	err := r.db.DB.QueryRow(query, userID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get following count: %w", err)
	}
	return count, nil
}

// GetFollowers gets the list of followers for a user (paginated)
func (r *UserRepository) GetFollowers(userID uuid.UUID, page, limit int) ([]models.UserFollowInfo, int, error) {
	offset := (page - 1) * limit

	// Get total count
	countQuery := `
		SELECT COUNT(*) FROM user_follows
		WHERE following_id = $1
	`
	var total int
	err := r.db.DB.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get followers count: %w", err)
	}

	// Get followers with user info
	query := `
		SELECT 
			uf.follower_id,
			COALESCE(up.full_name, '') as full_name,
			up.avatar_url,
			up.bio,
			uf.created_at as followed_at
		FROM user_follows uf
		INNER JOIN user_profiles up ON uf.follower_id = up.user_id
		WHERE uf.following_id = $1
		ORDER BY uf.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get followers: %w", err)
	}
	defer rows.Close()

	followers := []models.UserFollowInfo{}
	for rows.Next() {
		var info models.UserFollowInfo
		var fullName sql.NullString
		var bio sql.NullString
		err := rows.Scan(
			&info.UserID,
			&fullName,
			&info.AvatarURL,
			&bio,
			&info.FollowedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan follower: %w", err)
		}

		// Handle NULL values
		info.FullName = fullName.String
		if bio.Valid {
			info.Bio = &bio.String
		}

		// Get level and points from learning_progress
		progressQuery := `
			SELECT 
				COALESCE(
					(SELECT SUM(points) FROM achievements a
					 INNER JOIN user_achievements ua ON a.id = ua.achievement_id
					 WHERE ua.user_id = $1), 0
				) as points
		`
		var points int
		_ = r.db.DB.QueryRow(progressQuery, info.UserID).Scan(&points)
		info.Points = points

		// Simple level calculation based on points (every 100 points = 1 level)
		if points/100 < 1 {
			info.Level = 1
		} else {
			info.Level = points / 100
		}

		followers = append(followers, info)
	}

	return followers, total, nil
}

// GetFollowing gets the list of users a user is following (paginated)
func (r *UserRepository) GetFollowing(userID uuid.UUID, page, limit int) ([]models.UserFollowInfo, int, error) {
	offset := (page - 1) * limit

	// Get total count
	countQuery := `
		SELECT COUNT(*) FROM user_follows
		WHERE follower_id = $1
	`
	var total int
	err := r.db.DB.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get following count: %w", err)
	}

	// Get following with user info
	query := `
		SELECT 
			uf.following_id,
			COALESCE(up.full_name, '') as full_name,
			up.avatar_url,
			up.bio,
			uf.created_at as followed_at
		FROM user_follows uf
		INNER JOIN user_profiles up ON uf.following_id = up.user_id
		WHERE uf.follower_id = $1
		ORDER BY uf.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.DB.Query(query, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get following: %w", err)
	}
	defer rows.Close()

	following := []models.UserFollowInfo{}
	for rows.Next() {
		var info models.UserFollowInfo
		var fullName sql.NullString
		var bio sql.NullString
		err := rows.Scan(
			&info.UserID,
			&fullName,
			&info.AvatarURL,
			&bio,
			&info.FollowedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan following: %w", err)
		}

		// Handle NULL values
		info.FullName = fullName.String
		if bio.Valid {
			info.Bio = &bio.String
		}

		// Get level and points from learning_progress
		progressQuery := `
			SELECT 
				COALESCE(
					(SELECT SUM(points) FROM achievements a
					 INNER JOIN user_achievements ua ON a.id = ua.achievement_id
					 WHERE ua.user_id = $1), 0
				) as points
		`
		var points int
		_ = r.db.DB.QueryRow(progressQuery, info.UserID).Scan(&points)
		info.Points = points

		// Simple level calculation based on points (every 100 points = 1 level)
		if points/100 < 1 {
			info.Level = 1
		} else {
			info.Level = points / 100
		}

		following = append(following, info)
	}

	return following, total, nil
}

// ============= Study Goals =============

// CreateGoal creates a new study goal
func (r *UserRepository) CreateGoal(goal *models.StudyGoal) error {
	query := `
		INSERT INTO study_goals (id, user_id, goal_type, title, description, target_value, target_unit, current_value, skill_type, start_date, end_date, status, reminder_enabled, reminder_time, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW(), NOW())
	`
	_, err := r.db.DB.Exec(query, goal.ID, goal.UserID, goal.GoalType, goal.Title, goal.Description, goal.TargetValue, goal.TargetUnit, goal.CurrentValue, goal.SkillType, goal.StartDate, goal.EndDate, goal.Status, goal.ReminderEnabled, goal.ReminderTime)
	if err != nil {
		return fmt.Errorf("failed to create goal: %w", err)
	}
	return nil
}

// GetUserGoals retrieves all goals for a user
func (r *UserRepository) GetUserGoals(userID uuid.UUID) ([]models.StudyGoal, error) {
	query := `
		SELECT id, user_id, goal_type, title, description, target_value, target_unit, current_value, skill_type, start_date, end_date, 
		       status, completed_at, reminder_enabled, reminder_time, created_at, updated_at
		FROM study_goals
		WHERE user_id = $1
		ORDER BY created_at DESC
	`
	rows, err := r.db.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user goals: %w", err)
	}
	defer rows.Close()

	goals := []models.StudyGoal{}
	for rows.Next() {
		goal := models.StudyGoal{}
		err := rows.Scan(&goal.ID, &goal.UserID, &goal.GoalType, &goal.Title, &goal.Description, &goal.TargetValue, &goal.TargetUnit, &goal.CurrentValue,
			&goal.SkillType, &goal.StartDate, &goal.EndDate, &goal.Status, &goal.CompletedAt,
			&goal.ReminderEnabled, &goal.ReminderTime, &goal.CreatedAt, &goal.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan goal: %w", err)
		}
		goals = append(goals, goal)
	}
	return goals, nil
}

// GetGoalByID retrieves a specific goal by ID
func (r *UserRepository) GetGoalByID(goalID uuid.UUID, userID uuid.UUID) (*models.StudyGoal, error) {
	query := `
		SELECT id, user_id, goal_type, title, description, target_value, target_unit, current_value, skill_type, start_date, end_date, 
		       status, completed_at, reminder_enabled, reminder_time, created_at, updated_at
		FROM study_goals
		WHERE id = $1 AND user_id = $2
	`
	goal := &models.StudyGoal{}
	err := r.db.DB.QueryRow(query, goalID, userID).Scan(
		&goal.ID, &goal.UserID, &goal.GoalType, &goal.Title, &goal.Description, &goal.TargetValue, &goal.TargetUnit, &goal.CurrentValue,
		&goal.SkillType, &goal.StartDate, &goal.EndDate, &goal.Status, &goal.CompletedAt,
		&goal.ReminderEnabled, &goal.ReminderTime, &goal.CreatedAt, &goal.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("goal not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get goal: %w", err)
	}
	return goal, nil
}

// UpdateGoal updates a study goal
func (r *UserRepository) UpdateGoal(goal *models.StudyGoal) error {
	query := `
		UPDATE study_goals
		SET title = $1, description = $2, target_value = $3, target_unit = $4, current_value = $5, 
		    skill_type = $6, end_date = $7, status = $8, completed_at = $9, 
		    reminder_enabled = $10, reminder_time = $11, updated_at = NOW()
		WHERE id = $12 AND user_id = $13
	`
	_, err := r.db.DB.Exec(query, goal.Title, goal.Description, goal.TargetValue, goal.TargetUnit, goal.CurrentValue,
		goal.SkillType, goal.EndDate, goal.Status, goal.CompletedAt,
		goal.ReminderEnabled, goal.ReminderTime, goal.ID, goal.UserID)
	if err != nil {
		return fmt.Errorf("failed to update goal: %w", err)
	}
	return nil
}

// UpdateGoalProgress updates the current progress of a goal
func (r *UserRepository) UpdateGoalProgress(goalID uuid.UUID, userID uuid.UUID, currentValue int) error {
	query := `
		UPDATE study_goals
		SET current_value = $1, updated_at = NOW()
		WHERE id = $2 AND user_id = $3
	`
	_, err := r.db.DB.Exec(query, currentValue, goalID, userID)
	if err != nil {
		return fmt.Errorf("failed to update goal progress: %w", err)
	}
	return nil
}

// CompleteGoal marks a goal as completed
func (r *UserRepository) CompleteGoal(goalID uuid.UUID, userID uuid.UUID) error {
	now := time.Now()
	query := `
		UPDATE study_goals
		SET status = 'completed', completed_at = $1, updated_at = NOW()
		WHERE id = $2 AND user_id = $3
	`
	_, err := r.db.DB.Exec(query, now, goalID, userID)
	if err != nil {
		return fmt.Errorf("failed to complete goal: %w", err)
	}
	return nil
}

// DeleteGoal deletes a study goal
func (r *UserRepository) DeleteGoal(goalID uuid.UUID, userID uuid.UUID) error {
	query := `DELETE FROM study_goals WHERE id = $1 AND user_id = $2`
	_, err := r.db.DB.Exec(query, goalID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete goal: %w", err)
	}
	return nil
}

// UpdateLearningProgressAtomic updates learning progress using atomic operations to prevent race conditions
func (r *UserRepository) UpdateLearningProgressAtomic(userID uuid.UUID, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}

	query := "UPDATE learning_progress SET updated_at = CURRENT_TIMESTAMP"
	args := []interface{}{}
	paramCount := 0

	// Handle atomic increments
	if lessonsCompleted, ok := updates["lessons_completed"].(int); ok && lessonsCompleted > 0 {
		paramCount++
		query += fmt.Sprintf(", total_lessons_completed = total_lessons_completed + $%d", paramCount)
		args = append(args, lessonsCompleted)
	}
	if exercisesCompleted, ok := updates["exercises_completed"].(int); ok && exercisesCompleted > 0 {
		paramCount++
		query += fmt.Sprintf(", total_exercises_completed = total_exercises_completed + $%d", paramCount)
		args = append(args, exercisesCompleted)
	}
	// study_minutes update REMOVED - Migration 013
	// total_study_hours field removed from DB
	// SOURCE OF TRUTH: Real-time calculation from study_sessions in GetLearningProgress()

	// Handle streak updates
	if increment, ok := updates["increment_current_streak"].(int); ok && increment > 0 {
		paramCount++
		query += fmt.Sprintf(", current_streak_days = current_streak_days + $%d", paramCount)
		args = append(args, increment)

		// Update longest streak if needed
		if shouldUpdate, ok := updates["update_longest_if_needed"].(bool); ok && shouldUpdate {
			query += ", longest_streak_days = GREATEST(longest_streak_days, current_streak_days)"
		}
	} else if currentStreak, ok := updates["current_streak_days"].(int); ok {
		paramCount++
		query += fmt.Sprintf(", current_streak_days = $%d", paramCount)
		args = append(args, currentStreak)
	}

	if longestStreak, ok := updates["longest_streak_days"].(int); ok {
		paramCount++
		query += fmt.Sprintf(", longest_streak_days = $%d", paramCount)
		args = append(args, longestStreak)
	}

	// Handle skill-specific score updates for LearningProgress
	if score, ok := updates["listening_score"].(float64); ok {
		paramCount++
		query += fmt.Sprintf(", listening_score = $%d", paramCount)
		args = append(args, score)
	}
	if score, ok := updates["reading_score"].(float64); ok {
		paramCount++
		query += fmt.Sprintf(", reading_score = $%d", paramCount)
		args = append(args, score)
	}
	if score, ok := updates["writing_score"].(float64); ok {
		paramCount++
		query += fmt.Sprintf(", writing_score = $%d", paramCount)
		args = append(args, score)
	}
	if score, ok := updates["speaking_score"].(float64); ok {
		paramCount++
		query += fmt.Sprintf(", speaking_score = $%d", paramCount)
		args = append(args, score)
	}

	// Handle direct updates
	if lastStudyDate, ok := updates["last_study_date"].(time.Time); ok {
		paramCount++
		query += fmt.Sprintf(", last_study_date = $%d", paramCount)
		args = append(args, lastStudyDate)
	}

	// Calculate overall_score based on the four skill scores (IELTS official formula)
	// Only calculate if at least one skill score was updated
	hasSkillScoreUpdate := updates["listening_score"] != nil || updates["reading_score"] != nil ||
		updates["writing_score"] != nil || updates["speaking_score"] != nil

	if hasSkillScoreUpdate {
		// Fetch current progress to get all skill scores (including ones not being updated)
		currentProgress, err := r.GetLearningProgress(userID)
		if err != nil {
			log.Printf("⚠️  Could not fetch current learning progress for overall score calculation: %v", err)
			// Continue without updating overall score if we can't get current progress
		} else {
			// Collect all skill scores (use updated values if provided, otherwise current values)
			var scores []float64

			if val, ok := updates["listening_score"].(float64); ok {
				scores = append(scores, val)
			} else if currentProgress.ListeningScore != nil {
				scores = append(scores, *currentProgress.ListeningScore)
			}

			if val, ok := updates["reading_score"].(float64); ok {
				scores = append(scores, val)
			} else if currentProgress.ReadingScore != nil {
				scores = append(scores, *currentProgress.ReadingScore)
			}

			if val, ok := updates["writing_score"].(float64); ok {
				scores = append(scores, val)
			} else if currentProgress.WritingScore != nil {
				scores = append(scores, *currentProgress.WritingScore)
			}

			if val, ok := updates["speaking_score"].(float64); ok {
				scores = append(scores, val)
			} else if currentProgress.SpeakingScore != nil {
				scores = append(scores, *currentProgress.SpeakingScore)
			}

			// Calculate overall score if we have at least one skill score
			if len(scores) > 0 {
				total := 0.0
				for _, s := range scores {
					total += s
				}
				average := total / float64(len(scores))

				// Apply IELTS rounding rules
				overallScore := calculateIELTSOverallScore(average)

				paramCount++
				query += fmt.Sprintf(", overall_score = $%d", paramCount)
				args = append(args, overallScore)
			}
		}
	}

	// Add WHERE clause
	paramCount++
	query += fmt.Sprintf(" WHERE user_id = $%d", paramCount)
	args = append(args, userID)

	result, err := r.db.DB.Exec(query, args...)
	if err != nil {
		log.Printf("❌ Error updating learning progress atomically for user %s: %v", userID, err)
		return fmt.Errorf("failed to update learning progress: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}
	if rowsAffected == 0 {
		return fmt.Errorf("learning progress not found for user %s", userID)
	}

	return nil
}

// ============= Skill Statistics =============

// GetSkillStatistics retrieves statistics for a specific skill
func (r *UserRepository) GetSkillStatistics(userID uuid.UUID, skillType string) (*models.SkillStatistics, error) {
	query := `
		SELECT id, user_id, skill_type, total_practices, completed_practices, average_score, best_score, 
		       total_time_minutes, last_practice_date, last_practice_score, score_trend, weak_areas, created_at, updated_at
		FROM skill_statistics
		WHERE user_id = $1 AND skill_type = $2
	`
	stats := &models.SkillStatistics{}
	err := r.db.DB.QueryRow(query, userID, skillType).Scan(
		&stats.ID, &stats.UserID, &stats.SkillType, &stats.TotalPractices, &stats.CompletedPractices,
		&stats.AverageScore, &stats.BestScore, &stats.TotalTimeMinutes, &stats.LastPracticeDate,
		&stats.LastPracticeScore, &stats.ScoreTrend, &stats.WeakAreas, &stats.CreatedAt, &stats.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil // Return nil if no statistics exist yet
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get skill statistics: %w", err)
	}
	return stats, nil
}

// CreateSkillStatistics creates a new skill statistics record
func (r *UserRepository) CreateSkillStatistics(userID uuid.UUID, skillType string) error {
	query := `
		INSERT INTO skill_statistics (
			user_id, skill_type, 
			total_practices, completed_practices, 
			average_score, best_score, 
			total_time_minutes
		)
		VALUES ($1, $2, 0, 0, 0.0, 0.0, 0)
		ON CONFLICT (user_id, skill_type) DO NOTHING
	`
	_, err := r.db.DB.Exec(query, userID, skillType)
	if err != nil {
		log.Printf("❌ Error creating skill statistics for user %s, skill %s: %v", userID, skillType, err)
		return fmt.Errorf("failed to create skill statistics: %w", err)
	}
	return nil
}

// UpdateSkillStatistics updates skill statistics fields
func (r *UserRepository) UpdateSkillStatistics(userID uuid.UUID, skillType string, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}

	// Build dynamic update query
	query := "UPDATE skill_statistics SET updated_at = CURRENT_TIMESTAMP"
	args := []interface{}{}
	paramCount := 0

	for field, value := range updates {
		paramCount++
		query += fmt.Sprintf(", %s = $%d", field, paramCount)
		args = append(args, value)
	}

	paramCount++
	query += fmt.Sprintf(" WHERE user_id = $%d", paramCount)
	args = append(args, userID)

	paramCount++
	query += fmt.Sprintf(" AND skill_type = $%d", paramCount)
	args = append(args, skillType)

	_, err := r.db.DB.Exec(query, args...)
	if err != nil {
		log.Printf("❌ Error updating skill statistics for user %s, skill %s: %v", userID, skillType, err)
		return fmt.Errorf("failed to update skill statistics: %w", err)
	}

	return nil
}

// GetAllSkillStatistics retrieves all skill statistics for a user
func (r *UserRepository) GetAllSkillStatistics(userID uuid.UUID) (map[string]*models.SkillStatistics, error) {
	query := `
		SELECT id, user_id, skill_type, total_practices, completed_practices, average_score, best_score, 
		       total_time_minutes, last_practice_date, last_practice_score, score_trend, weak_areas, created_at, updated_at
		FROM skill_statistics
		WHERE user_id = $1
	`
	rows, err := r.db.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get all skill statistics: %w", err)
	}
	defer rows.Close()

	statsMap := make(map[string]*models.SkillStatistics)
	for rows.Next() {
		stats := &models.SkillStatistics{}
		err := rows.Scan(&stats.ID, &stats.UserID, &stats.SkillType, &stats.TotalPractices, &stats.CompletedPractices,
			&stats.AverageScore, &stats.BestScore, &stats.TotalTimeMinutes, &stats.LastPracticeDate,
			&stats.LastPracticeScore, &stats.ScoreTrend, &stats.WeakAreas, &stats.CreatedAt, &stats.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan skill statistics: %w", err)
		}
		statsMap[stats.SkillType] = stats
	}
	return statsMap, nil
}

// UpsertSkillStatistics creates or updates skill statistics
func (r *UserRepository) UpsertSkillStatistics(stats *models.SkillStatistics) error {
	query := `
		INSERT INTO skill_statistics (user_id, skill_type, total_practices, completed_practices, average_score, best_score, 
		                               total_time_minutes, last_practice_date, last_practice_score, score_trend, weak_areas, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
		ON CONFLICT (user_id, skill_type) 
		DO UPDATE SET 
			total_practices = EXCLUDED.total_practices,
			completed_practices = EXCLUDED.completed_practices,
			average_score = EXCLUDED.average_score,
			best_score = CASE WHEN EXCLUDED.best_score > skill_statistics.best_score THEN EXCLUDED.best_score ELSE skill_statistics.best_score END,
			total_time_minutes = EXCLUDED.total_time_minutes,
			last_practice_date = EXCLUDED.last_practice_date,
			last_practice_score = EXCLUDED.last_practice_score,
			score_trend = EXCLUDED.score_trend,
			weak_areas = EXCLUDED.weak_areas,
			updated_at = NOW()
	`
	_, err := r.db.DB.Exec(query, stats.UserID, stats.SkillType, stats.TotalPractices, stats.CompletedPractices,
		stats.AverageScore, stats.BestScore, stats.TotalTimeMinutes, stats.LastPracticeDate,
		stats.LastPracticeScore, stats.ScoreTrend, stats.WeakAreas)
	if err != nil {
		return fmt.Errorf("failed to upsert skill statistics: %w", err)
	}
	return nil
}

// ============= Achievements =============

// GetAllAchievements retrieves all available achievements
func (r *UserRepository) GetAllAchievements() ([]models.Achievement, error) {
	query := `
		SELECT id, code, name, description, criteria_type, criteria_value, 
		       icon_url, badge_color, points, created_at
		FROM achievements
		ORDER BY points
	`
	rows, err := r.db.DB.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get achievements: %w", err)
	}
	defer rows.Close()

	achievements := []models.Achievement{}
	for rows.Next() {
		achievement := models.Achievement{}
		err := rows.Scan(&achievement.ID, &achievement.Code, &achievement.Name, &achievement.Description,
			&achievement.CriteriaType, &achievement.CriteriaValue, &achievement.IconURL,
			&achievement.BadgeColor, &achievement.Points, &achievement.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan achievement: %w", err)
		}
		achievements = append(achievements, achievement)
	}
	return achievements, nil
}

// UnlockAchievement unlocks an achievement for a user (UUID version)
func (r *UserRepository) UnlockAchievement(userID uuid.UUID, achievementID uuid.UUID) error {
	query := `
		INSERT INTO user_achievements (id, user_id, achievement_id, earned_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (user_id, achievement_id) DO NOTHING
	`
	id := uuid.New()
	_, err := r.db.DB.Exec(query, id, userID, achievementID)
	if err != nil {
		return fmt.Errorf("failed to unlock achievement: %w", err)
	}
	return nil
}

// UnlockAchievementByID unlocks an achievement for a user (INT ID version)
func (r *UserRepository) UnlockAchievementByID(userID uuid.UUID, achievementID int) error {
	query := `
		INSERT INTO user_achievements (user_id, achievement_id, earned_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (user_id, achievement_id) DO NOTHING
		RETURNING id
	`
	var insertedID int64
	err := r.db.DB.QueryRow(query, userID, achievementID).Scan(&insertedID)
	if err != nil {
		// If error is "no rows", it means conflict (already unlocked)
		if err.Error() == "sql: no rows in result set" {
			log.Printf("ℹ️  Achievement %d already unlocked for user %s", achievementID, userID)
			return nil
		}
		return fmt.Errorf("failed to unlock achievement: %w", err)
	}
	log.Printf("✅ Achievement %d unlocked for user %s (row ID: %d)", achievementID, userID, insertedID)
	return nil
}

// CheckAchievementUnlocked checks if a user has unlocked a specific achievement
func (r *UserRepository) CheckAchievementUnlocked(userID uuid.UUID, achievementID uuid.UUID) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM user_achievements WHERE user_id = $1 AND achievement_id = $2)`
	var exists bool
	err := r.db.DB.QueryRow(query, userID, achievementID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check achievement: %w", err)
	}
	return exists, nil
}

// ============= User Preferences =============

// GetPreferences retrieves user preferences
func (r *UserRepository) GetPreferences(userID uuid.UUID) (*models.UserPreferences, error) {
	query := `
		SELECT user_id, email_notifications, push_notifications, study_reminders, weekly_report, 
		       theme, font_size, locale, auto_play_next_lesson, show_answer_explanation, playback_speed, 
		       profile_visibility, show_study_stats, updated_at
		FROM user_preferences
		WHERE user_id = $1
	`
	prefs := &models.UserPreferences{}
	err := r.db.DB.QueryRow(query, userID).Scan(
		&prefs.UserID, &prefs.EmailNotifications, &prefs.PushNotifications, &prefs.StudyReminders, &prefs.WeeklyReport,
		&prefs.Theme, &prefs.FontSize, &prefs.Locale, &prefs.AutoPlayNextLesson, &prefs.ShowAnswerExplanation, &prefs.PlaybackSpeed,
		&prefs.ProfileVisibility, &prefs.ShowStudyStats, &prefs.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		// Create default preferences
		return r.CreateDefaultPreferences(userID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get preferences: %w", err)
	}
	return prefs, nil
}

// CreateDefaultPreferences creates default preferences for a new user
func (r *UserRepository) CreateDefaultPreferences(userID uuid.UUID) (*models.UserPreferences, error) {
	query := `
		INSERT INTO user_preferences (user_id, email_notifications, push_notifications, study_reminders, weekly_report, 
		                              theme, font_size, locale, auto_play_next_lesson, show_answer_explanation, playback_speed, 
		                              profile_visibility, show_study_stats, updated_at)
		VALUES ($1, true, true, true, true, 'light', 'medium', 'vi', true, true, 1.0, 'private', true, NOW())
		RETURNING user_id, email_notifications, push_notifications, study_reminders, weekly_report, 
		          theme, font_size, locale, auto_play_next_lesson, show_answer_explanation, playback_speed, 
		          profile_visibility, show_study_stats, updated_at
	`
	prefs := &models.UserPreferences{}
	err := r.db.DB.QueryRow(query, userID).Scan(
		&prefs.UserID, &prefs.EmailNotifications, &prefs.PushNotifications, &prefs.StudyReminders, &prefs.WeeklyReport,
		&prefs.Theme, &prefs.FontSize, &prefs.Locale, &prefs.AutoPlayNextLesson, &prefs.ShowAnswerExplanation, &prefs.PlaybackSpeed,
		&prefs.ProfileVisibility, &prefs.ShowStudyStats, &prefs.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create default preferences: %w", err)
	}
	return prefs, nil
}

// UpdatePreferences updates user preferences
func (r *UserRepository) UpdatePreferences(prefs *models.UserPreferences) error {
	query := `
		UPDATE user_preferences
		SET email_notifications = $1, push_notifications = $2, study_reminders = $3, weekly_report = $4, 
		    theme = $5, font_size = $6, locale = $7, auto_play_next_lesson = $8, show_answer_explanation = $9, playback_speed = $10, 
		    profile_visibility = $11, show_study_stats = $12, updated_at = NOW()
		WHERE user_id = $13
	`
	_, err := r.db.DB.Exec(query, prefs.EmailNotifications, prefs.PushNotifications, prefs.StudyReminders, prefs.WeeklyReport,
		prefs.Theme, prefs.FontSize, prefs.Locale, prefs.AutoPlayNextLesson, prefs.ShowAnswerExplanation, prefs.PlaybackSpeed,
		prefs.ProfileVisibility, prefs.ShowStudyStats, prefs.UserID)
	if err != nil {
		return fmt.Errorf("failed to update preferences: %w", err)
	}
	return nil
}

// ============= Study Reminders =============

// CreateReminder creates a new study reminder
func (r *UserRepository) CreateReminder(reminder *models.StudyReminder) error {
	query := `
		INSERT INTO study_reminders (id, user_id, title, message, reminder_type, reminder_time, 
		                             days_of_week, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
	`
	_, err := r.db.DB.Exec(query, reminder.ID, reminder.UserID, reminder.Title, reminder.Message,
		reminder.ReminderType, reminder.ReminderTime, reminder.DaysOfWeek, reminder.IsActive)
	if err != nil {
		return fmt.Errorf("failed to create reminder: %w", err)
	}
	return nil
}

// GetUserReminders retrieves all reminders for a user
func (r *UserRepository) GetUserReminders(userID uuid.UUID) ([]models.StudyReminder, error) {
	query := `
		SELECT id, user_id, title, message, reminder_type, reminder_time, days_of_week, 
		       is_active, last_sent_at, next_send_at, created_at, updated_at
		FROM study_reminders
		WHERE user_id = $1
		ORDER BY reminder_time
	`
	rows, err := r.db.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get reminders: %w", err)
	}
	defer rows.Close()

	reminders := []models.StudyReminder{}
	for rows.Next() {
		reminder := models.StudyReminder{}
		err := rows.Scan(&reminder.ID, &reminder.UserID, &reminder.Title, &reminder.Message,
			&reminder.ReminderType, &reminder.ReminderTime, &reminder.DaysOfWeek, &reminder.IsActive,
			&reminder.LastSentAt, &reminder.NextSendAt, &reminder.CreatedAt, &reminder.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan reminder: %w", err)
		}
		reminders = append(reminders, reminder)
	}
	return reminders, nil
}

// GetReminderByID retrieves a specific reminder
func (r *UserRepository) GetReminderByID(reminderID uuid.UUID, userID uuid.UUID) (*models.StudyReminder, error) {
	query := `
		SELECT id, user_id, title, message, reminder_type, reminder_time, days_of_week, 
		       is_active, last_sent_at, next_send_at, created_at, updated_at
		FROM study_reminders
		WHERE id = $1 AND user_id = $2
	`
	reminder := &models.StudyReminder{}
	err := r.db.DB.QueryRow(query, reminderID, userID).Scan(
		&reminder.ID, &reminder.UserID, &reminder.Title, &reminder.Message, &reminder.ReminderType,
		&reminder.ReminderTime, &reminder.DaysOfWeek, &reminder.IsActive, &reminder.LastSentAt,
		&reminder.NextSendAt, &reminder.CreatedAt, &reminder.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("reminder not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get reminder: %w", err)
	}
	return reminder, nil
}

// UpdateReminder updates a study reminder
func (r *UserRepository) UpdateReminder(reminder *models.StudyReminder) error {
	query := `
		UPDATE study_reminders
		SET title = $1, message = $2, reminder_time = $3, days_of_week = $4, 
		    is_active = $5, updated_at = NOW()
		WHERE id = $6 AND user_id = $7
	`
	_, err := r.db.DB.Exec(query, reminder.Title, reminder.Message, reminder.ReminderTime,
		reminder.DaysOfWeek, reminder.IsActive, reminder.ID, reminder.UserID)
	if err != nil {
		return fmt.Errorf("failed to update reminder: %w", err)
	}
	return nil
}

// DeleteReminder deletes a study reminder
func (r *UserRepository) DeleteReminder(reminderID uuid.UUID, userID uuid.UUID) error {
	query := `DELETE FROM study_reminders WHERE id = $1 AND user_id = $2`
	_, err := r.db.DB.Exec(query, reminderID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete reminder: %w", err)
	}
	return nil
}

// ToggleReminder toggles the active status of a reminder automatically and returns the updated reminder
func (r *UserRepository) ToggleReminder(reminderID uuid.UUID, userID uuid.UUID) (*models.StudyReminder, error) {
	// First, get the current reminder to check its status
	var reminder models.StudyReminder
	queryGet := `SELECT id, user_id, title, message, reminder_type, reminder_time, days_of_week, is_active, created_at, updated_at 
	             FROM study_reminders WHERE id = $1 AND user_id = $2`
	err := r.db.DB.QueryRow(queryGet, reminderID, userID).Scan(
		&reminder.ID,
		&reminder.UserID,
		&reminder.Title,
		&reminder.Message,
		&reminder.ReminderType,
		&reminder.ReminderTime,
		&reminder.DaysOfWeek,
		&reminder.IsActive,
		&reminder.CreatedAt,
		&reminder.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("reminder not found")
		}
		return nil, fmt.Errorf("failed to get reminder: %w", err)
	}

	// Toggle the status
	newStatus := !reminder.IsActive

	// Update the reminder with the new status
	queryUpdate := `UPDATE study_reminders SET is_active = $1, updated_at = NOW() 
	                WHERE id = $2 AND user_id = $3 
	                RETURNING id, user_id, title, message, reminder_type, reminder_time, days_of_week, is_active, created_at, updated_at`

	var updatedReminder models.StudyReminder
	err = r.db.DB.QueryRow(queryUpdate, newStatus, reminderID, userID).Scan(
		&updatedReminder.ID,
		&updatedReminder.UserID,
		&updatedReminder.Title,
		&updatedReminder.Message,
		&updatedReminder.ReminderType,
		&updatedReminder.ReminderTime,
		&updatedReminder.DaysOfWeek,
		&updatedReminder.IsActive,
		&updatedReminder.CreatedAt,
		&updatedReminder.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to toggle reminder: %w", err)
	}

	return &updatedReminder, nil
}

// ============= Leaderboard =============

// GetTopLearners retrieves top learners by achievements count and study hours
// Optimized query using CTEs to avoid repeated subqueries
// Supports period filtering (daily, weekly, monthly, all-time) and pagination
func (r *UserRepository) GetTopLearners(period string, page, limit int) ([]models.LeaderboardEntry, int, error) {
	// Default to all-time if period is empty or invalid
	if period == "" {
		period = "all-time"
	}

	// Calculate date range based on period
	var dateFilter string
	switch period {
	case "daily":
		dateFilter = "AND ss.started_at >= CURRENT_DATE"
	case "weekly":
		dateFilter = "AND ss.started_at >= DATE_TRUNC('week', CURRENT_DATE)"
	case "monthly":
		dateFilter = "AND ss.started_at >= DATE_TRUNC('month', CURRENT_DATE)"
	case "all-time":
		dateFilter = ""
	default:
		dateFilter = ""
	}

	// Get total count for pagination
	var totalCount int
	countQuery := `
		SELECT COUNT(DISTINCT up.user_id)
		FROM user_profiles up
		LEFT JOIN learning_progress lp ON up.user_id = lp.user_id
		LEFT JOIN (
			SELECT user_id, COUNT(*) as achievements_count
			FROM user_achievements
			GROUP BY user_id
		) achievement_counts ON up.user_id = achievement_counts.user_id
		LEFT JOIN (
			SELECT 
				user_id,
				ROUND((SUM(duration_minutes) / 60.0)::numeric, 2) as total_study_hours
			FROM study_sessions ss
			WHERE 1=1 ` + dateFilter + `
			GROUP BY user_id
		) study_times ON up.user_id = study_times.user_id
		WHERE COALESCE(achievement_counts.achievements_count, 0) > 0 
		   OR COALESCE(study_times.total_study_hours, 0) > 0
	`
	err := r.db.DB.QueryRow(countQuery).Scan(&totalCount)
	if err != nil {
		totalCount = 0
	}

	// Calculate offset for pagination
	offset := (page - 1) * limit

	// Build dblink connection string from config
	dbLinkConnStr := r.getDBLinkConnectionString("auth_db")

	// Build achievement filter
	achievementFilter := func() string {
		if period == "daily" {
			return "WHERE earned_at >= CURRENT_DATE"
		} else if period == "weekly" {
			return "WHERE earned_at >= DATE_TRUNC('week', CURRENT_DATE)"
		} else if period == "monthly" {
			return "WHERE earned_at >= DATE_TRUNC('month', CURRENT_DATE)"
		}
		return ""
	}()

	// Build query with period filtering
	query := fmt.Sprintf(`
		WITH user_stats AS (
			SELECT 
				up.user_id,
				COALESCE(
					NULLIF(TRIM(up.full_name), ''),
					TRIM(CONCAT(COALESCE(up.first_name, ''), ' ', COALESCE(up.last_name, ''))),
					COALESCE(SPLIT_PART(au.email, '@', 1), 'Học viên')
				) as full_name,
				up.avatar_url,
				COALESCE(lp.current_streak_days, 0) as current_streak_days,
				COALESCE(achievement_counts.achievements_count, 0) as achievements_count,
				COALESCE(study_times.total_study_hours, 0) as total_study_hours
			FROM user_profiles up
			LEFT JOIN learning_progress lp ON up.user_id = lp.user_id
			LEFT JOIN dblink(
				'%s',
				'SELECT id, email FROM users WHERE deleted_at IS NULL'
			) AS au(id uuid, email text) ON up.user_id = au.id
			LEFT JOIN (
				SELECT user_id, COUNT(*) as achievements_count
				FROM user_achievements
				%s
				GROUP BY user_id
			) achievement_counts ON up.user_id = achievement_counts.user_id
			LEFT JOIN (
				SELECT 
					user_id,
					ROUND((SUM(duration_minutes) / 60.0)::numeric, 2) as total_study_hours
				FROM study_sessions ss
				WHERE 1=1 %s
				GROUP BY user_id
			) study_times ON up.user_id = study_times.user_id
		),
		ranked_users AS (
			SELECT 
				ROW_NUMBER() OVER (
					ORDER BY achievements_count DESC, total_study_hours DESC
				) as rank,
				user_id,
				full_name,
				avatar_url,
				achievements_count * 10 as total_points,
				current_streak_days,
				total_study_hours,
				achievements_count
			FROM user_stats
			WHERE achievements_count > 0 OR total_study_hours > 0
		)
		SELECT rank, user_id, full_name, avatar_url, total_points, 
		       current_streak_days, total_study_hours, achievements_count
		FROM ranked_users
		ORDER BY rank ASC
		LIMIT $1 OFFSET $2
	`, dbLinkConnStr, achievementFilter, dateFilter)
	rows, err := r.db.DB.Query(query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get top learners: %w", err)
	}
	defer rows.Close()

	entries := []models.LeaderboardEntry{}
	for rows.Next() {
		entry := models.LeaderboardEntry{}
		err := rows.Scan(&entry.Rank, &entry.UserID, &entry.FullName, &entry.AvatarURL,
			&entry.TotalPoints, &entry.CurrentStreakDays, &entry.TotalStudyHours, &entry.AchievementsCount)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan leaderboard entry: %w", err)
		}
		// Adjust rank for pagination
		entry.Rank = offset + len(entries) + 1
		entries = append(entries, entry)
	}
	return entries, totalCount, nil
}

// GetUserRank retrieves the rank of a specific user
// Uses the same optimized query structure as GetTopLearners
// Always returns a rank, even if user has no achievements or study hours yet
func (r *UserRepository) GetUserRank(userID uuid.UUID) (*models.LeaderboardEntry, error) {
	// Build dblink connection string from config
	dbLinkConnStr := r.getDBLinkConnectionString("auth_db")

	query := fmt.Sprintf(`
		WITH all_user_stats AS (
			SELECT 
				up.user_id,
				COALESCE(
					NULLIF(TRIM(up.full_name), ''),
					TRIM(CONCAT(COALESCE(up.first_name, ''), ' ', COALESCE(up.last_name, ''))),
					COALESCE(SPLIT_PART(au.email, '@', 1), 'Học viên')
				) as full_name,
				up.avatar_url,
				COALESCE(lp.current_streak_days, 0) as current_streak_days,
				COALESCE(achievement_counts.achievements_count, 0) as achievements_count,
				COALESCE(study_times.total_study_hours, 0) as total_study_hours
			FROM user_profiles up
			LEFT JOIN learning_progress lp ON up.user_id = lp.user_id
			LEFT JOIN dblink(
				'%s',
				'SELECT id, email FROM users WHERE deleted_at IS NULL'
			) AS au(id uuid, email text) ON up.user_id = au.id
			LEFT JOIN (
				SELECT user_id, COUNT(*) as achievements_count
				FROM user_achievements
				GROUP BY user_id
			) achievement_counts ON up.user_id = achievement_counts.user_id
			LEFT JOIN (
				SELECT 
					user_id,
					ROUND((SUM(duration_minutes) / 60.0)::numeric, 2) as total_study_hours
				FROM study_sessions
				GROUP BY user_id
			) study_times ON up.user_id = study_times.user_id
		),
		ranked_users AS (
			SELECT 
				ROW_NUMBER() OVER (
					ORDER BY achievements_count DESC, total_study_hours DESC
				) as rank,
				user_id,
				full_name,
				avatar_url,
				achievements_count * 10 as total_points,
				current_streak_days,
				total_study_hours,
				achievements_count
			FROM all_user_stats
			WHERE achievements_count > 0 OR total_study_hours > 0
		),
		active_count AS (
			SELECT COALESCE(COUNT(*), 0) as total_active
			FROM ranked_users
		),
		current_user_stats AS (
			SELECT user_id, full_name, avatar_url, current_streak_days,
			       achievements_count, total_study_hours
			FROM all_user_stats
			WHERE user_id = $1
		)
		SELECT 
			COALESCE(ru.rank, ac.total_active + 1) as rank,
			cus.user_id,
			cus.full_name,
			cus.avatar_url,
			COALESCE(ru.total_points, cus.achievements_count * 10) as total_points,
			cus.current_streak_days,
			cus.total_study_hours,
			cus.achievements_count
		FROM current_user_stats cus
		CROSS JOIN active_count ac
		LEFT JOIN ranked_users ru ON cus.user_id = ru.user_id
	`, dbLinkConnStr)
	entry := &models.LeaderboardEntry{}
	err := r.db.DB.QueryRow(query, userID).Scan(&entry.Rank, &entry.UserID, &entry.FullName,
		&entry.AvatarURL, &entry.TotalPoints, &entry.CurrentStreakDays, &entry.TotalStudyHours,
		&entry.AchievementsCount)
	if err != nil {
		return nil, fmt.Errorf("failed to get user rank: %w", err)
	}
	return entry, nil
}

// ============= Official Test Results =============

// CreateOfficialTestResult creates a new official test result (per-skill model)
// Each call creates ONE record for ONE skill test
func (r *UserRepository) CreateOfficialTestResult(result *models.OfficialTestResult) error {
	query := `
		INSERT INTO official_test_results (
			user_id, test_type, skill_type, ielts_variant, band_score,
			raw_score, total_questions,
			source_service, source_table, source_id,
			test_date, test_duration_minutes, completion_status,
			test_source, notes
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
		) RETURNING id, created_at, updated_at`

	err := r.db.DB.QueryRow(
		query,
		result.UserID,
		result.TestType,
		result.SkillType,
		result.IELTSVariant,
		result.BandScore,
		result.RawScore,
		result.TotalQuestions,
		result.SourceService,
		result.SourceTable,
		result.SourceID,
		result.TestDate,
		result.TestDurationMinutes,
		result.CompletionStatus,
		result.TestSource,
		result.Notes,
	).Scan(&result.ID, &result.CreatedAt, &result.UpdatedAt)

	if err != nil {
		log.Printf("❌ Error creating official test result for user %s: %v", result.UserID, err)
		return fmt.Errorf("failed to create official test result: %w", err)
	}

	log.Printf("✅ Created official test result %s for user %s (%s: %.1f)",
		result.ID, result.UserID, result.SkillType, result.BandScore)
	return nil
}

// GetUserTestHistory retrieves user's test history with pagination (per-skill model)
func (r *UserRepository) GetUserTestHistory(userID uuid.UUID, skillType *string, page, limit int) ([]models.OfficialTestResult, int, error) {
	offset := (page - 1) * limit

	// Base query
	whereClause := "WHERE user_id = $1"
	args := []interface{}{userID}
	paramCount := 1

	// Add skill filter if provided
	if skillType != nil && *skillType != "" {
		paramCount++
		whereClause += fmt.Sprintf(" AND skill_type = $%d", paramCount)
		args = append(args, *skillType)
	}

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM official_test_results %s", whereClause)
	var totalCount int
	err := r.db.DB.QueryRow(countQuery, args...).Scan(&totalCount)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count test results: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, user_id, test_type, skill_type, band_score,
			   raw_score, total_questions,
			   source_service, source_table, source_id,
			   test_date, test_duration_minutes, completion_status,
			   test_source, notes, created_at, updated_at
		FROM official_test_results
		%s
		ORDER BY test_date DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, paramCount+1, paramCount+2)

	args = append(args, limit, offset)
	rows, err := r.db.DB.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get test history: %w", err)
	}
	defer rows.Close()

	var results []models.OfficialTestResult
	for rows.Next() {
		var result models.OfficialTestResult
		err := rows.Scan(
			&result.ID,
			&result.UserID,
			&result.TestType,
			&result.SkillType,
			&result.BandScore,
			&result.RawScore,
			&result.TotalQuestions,
			&result.SourceService,
			&result.SourceTable,
			&result.SourceID,
			&result.TestDate,
			&result.TestDurationMinutes,
			&result.CompletionStatus,
			&result.TestSource,
			&result.Notes,
			&result.CreatedAt,
			&result.UpdatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan test result: %w", err)
		}
		results = append(results, result)
	}

	return results, totalCount, nil
}

// GetUserTestStatistics retrieves aggregated statistics from official tests (per-skill model)
func (r *UserRepository) GetUserTestStatistics(userID uuid.UUID) (map[string]interface{}, error) {
	// Query per-skill statistics
	query := `
		SELECT 
			skill_type,
			COUNT(*) as test_count,
			MAX(band_score) as highest_score,
			AVG(band_score) as average_score,
			MAX(test_date) as most_recent_date
		FROM official_test_results
		WHERE user_id = $1 AND completion_status = 'completed'
		GROUP BY skill_type
	`

	rows, err := r.db.DB.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get test statistics: %w", err)
	}
	defer rows.Close()

	stats := make(map[string]interface{})
	totalTests := 0

	// Build per-skill statistics
	for rows.Next() {
		var skillType string
		var testCount int
		var highestScore, avgScore sql.NullFloat64
		var mostRecent sql.NullTime

		err := rows.Scan(&skillType, &testCount, &highestScore, &avgScore, &mostRecent)
		if err != nil {
			return nil, fmt.Errorf("failed to scan test statistics: %w", err)
		}

		totalTests += testCount
		stats[fmt.Sprintf("highest_%s", skillType)] = highestScore.Float64
		stats[fmt.Sprintf("average_%s", skillType)] = avgScore.Float64
		stats[fmt.Sprintf("total_%s_tests", skillType)] = testCount
	}

	stats["total_tests"] = totalTests

	// Get overall most recent test date
	var mostRecentTestDate sql.NullTime
	err = r.db.DB.QueryRow(`
		SELECT MAX(test_date) FROM official_test_results 
		WHERE user_id = $1 AND completion_status = 'completed'
	`, userID).Scan(&mostRecentTestDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get most recent test date: %w", err)
	}
	if mostRecentTestDate.Valid {
		stats["most_recent_test_date"] = mostRecentTestDate.Time
	}

	return stats, nil
}

// ============= Practice Activities =============

// CreatePracticeActivity creates a new practice activity record
func (r *UserRepository) CreatePracticeActivity(activity *models.PracticeActivity) error {
	query := `
		INSERT INTO practice_activities (
			user_id, skill, activity_type,
			exercise_id, exercise_title,
			score, max_score, band_score,
			correct_answers, total_questions, accuracy_percentage,
			time_spent_seconds, started_at, completed_at,
			completion_status, ai_evaluated, ai_feedback_summary,
			difficulty_level, tags, notes
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
			$11, $12, $13, $14, $15, $16, $17, $18, $19, $20
		) RETURNING id, created_at, updated_at`

	err := r.db.DB.QueryRow(
		query,
		activity.UserID,
		activity.Skill,
		activity.ActivityType,
		activity.ExerciseID,
		activity.ExerciseTitle,
		activity.Score,
		activity.MaxScore,
		activity.BandScore,
		activity.CorrectAnswers,
		activity.TotalQuestions,
		activity.AccuracyPercentage,
		activity.TimeSpentSeconds,
		activity.StartedAt,
		activity.CompletedAt,
		activity.CompletionStatus,
		activity.AIEvaluated,
		activity.AIFeedbackSummary,
		activity.DifficultyLevel,
		activity.Tags,
		activity.Notes,
	).Scan(&activity.ID, &activity.CreatedAt, &activity.UpdatedAt)

	if err != nil {
		log.Printf("❌ Error creating practice activity for user %s: %v", activity.UserID, err)
		return fmt.Errorf("failed to create practice activity: %w", err)
	}

	log.Printf("✅ Created practice activity %s for user %s (skill: %s, type: %s)",
		activity.ID, activity.UserID, activity.Skill, activity.ActivityType)
	return nil
}

// GetUserPracticeActivities retrieves user's practice activities with pagination
func (r *UserRepository) GetUserPracticeActivities(userID uuid.UUID, skillType *string, page, limit int) ([]models.PracticeActivity, int, error) {
	offset := (page - 1) * limit

	// Build WHERE clause
	whereClause := "WHERE user_id = $1"
	args := []interface{}{userID}
	paramCount := 1

	if skillType != nil && *skillType != "" {
		paramCount++
		whereClause += fmt.Sprintf(" AND skill = $%d", paramCount)
		args = append(args, *skillType)
	}

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM practice_activities %s", whereClause)
	var totalCount int
	err := r.db.DB.QueryRow(countQuery, args...).Scan(&totalCount)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count practice activities: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, user_id, skill, activity_type,
			   exercise_id, exercise_title,
			   score, max_score, band_score,
			   correct_answers, total_questions, accuracy_percentage,
			   time_spent_seconds, started_at, completed_at,
			   completion_status, ai_evaluated, ai_feedback_summary,
			   difficulty_level, tags, notes,
			   created_at, updated_at
		FROM practice_activities
		%s
		ORDER BY completed_at DESC NULLS LAST, created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, paramCount+1, paramCount+2)

	args = append(args, limit, offset)
	rows, err := r.db.DB.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get practice activities: %w", err)
	}
	defer rows.Close()

	var activities []models.PracticeActivity
	for rows.Next() {
		var activity models.PracticeActivity
		err := rows.Scan(
			&activity.ID,
			&activity.UserID,
			&activity.Skill,
			&activity.ActivityType,
			&activity.ExerciseID,
			&activity.ExerciseTitle,
			&activity.Score,
			&activity.MaxScore,
			&activity.BandScore,
			&activity.CorrectAnswers,
			&activity.TotalQuestions,
			&activity.AccuracyPercentage,
			&activity.TimeSpentSeconds,
			&activity.StartedAt,
			&activity.CompletedAt,
			&activity.CompletionStatus,
			&activity.AIEvaluated,
			&activity.AIFeedbackSummary,
			&activity.DifficultyLevel,
			&activity.Tags,
			&activity.Notes,
			&activity.CreatedAt,
			&activity.UpdatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan practice activity: %w", err)
		}
		activities = append(activities, activity)
	}

	return activities, totalCount, nil
}

// GetUserPracticeStatistics retrieves aggregated statistics from practice activities
func (r *UserRepository) GetUserPracticeStatistics(userID uuid.UUID, skillType *string) (map[string]interface{}, error) {
	whereClause := "WHERE user_id = $1 AND completion_status = 'completed'"
	args := []interface{}{userID}

	if skillType != nil && *skillType != "" {
		whereClause += " AND skill = $2"
		args = append(args, *skillType)
	}

	query := fmt.Sprintf(`
		SELECT 
			skill,
			COUNT(*) as total_activities,
			AVG(score) as average_score,
			MAX(score) as best_score,
			AVG(accuracy_percentage) as average_accuracy,
			SUM(time_spent_seconds) as total_time_seconds,
			COUNT(CASE WHEN ai_evaluated = true THEN 1 END) as ai_evaluated_count
		FROM practice_activities
		%s
		GROUP BY skill
	`, whereClause)

	rows, err := r.db.DB.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to get practice statistics: %w", err)
	}
	defer rows.Close()

	stats := make(map[string]interface{})
	skillStats := make(map[string]map[string]interface{})

	for rows.Next() {
		var skill string
		var totalActivities int
		var avgScore, bestScore, avgAccuracy sql.NullFloat64
		var totalTime, aiEvaluatedCount sql.NullInt64

		err := rows.Scan(&skill, &totalActivities, &avgScore, &bestScore, &avgAccuracy, &totalTime, &aiEvaluatedCount)
		if err != nil {
			return nil, fmt.Errorf("failed to scan practice statistics: %w", err)
		}

		skillStats[skill] = map[string]interface{}{
			"total_activities":   totalActivities,
			"average_score":      avgScore.Float64,
			"best_score":         bestScore.Float64,
			"average_accuracy":   avgAccuracy.Float64,
			"total_time_seconds": totalTime.Int64,
			"ai_evaluated_count": aiEvaluatedCount.Int64,
		}
	}

	stats["by_skill"] = skillStats
	return stats, nil
}

// UpdateLearningProgressWithTestScore updates learning_progress with official test scores
// This should be called after recording an official test result
func (r *UserRepository) UpdateLearningProgressWithTestScore(
	userID uuid.UUID,
	skillType string,
	bandScore float64,
	incrementTestCount bool,
) error {
	tx, err := r.db.DB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// Build update query dynamically based on skill type
	var scoreColumn string
	switch skillType {
	case "listening":
		scoreColumn = "listening_score"
	case "reading":
		scoreColumn = "reading_score"
	case "writing":
		scoreColumn = "writing_score"
	case "speaking":
		scoreColumn = "speaking_score"
	case "overall":
		scoreColumn = "overall_score"
	default:
		return fmt.Errorf("invalid skill type: %s", skillType)
	}

	// Update score (and optionally increment total test count for individual skills)
	// FIX #11: Use atomic increment to avoid race condition
	query := fmt.Sprintf(`
		UPDATE learning_progress
		SET %s = $1,
			updated_at = CURRENT_TIMESTAMP
	`, scoreColumn)

	args := []interface{}{bandScore}
	paramCount := 1

	// For individual skills (not overall), increment total_tests_taken atomically
	if incrementTestCount && skillType != "overall" {
		query += ", total_tests_taken = total_tests_taken + 1"
	}

	paramCount++
	query += fmt.Sprintf(" WHERE user_id = $%d", paramCount)
	args = append(args, userID)

	_, err = tx.Exec(query, args...)
	if err != nil {
		return fmt.Errorf("failed to update learning progress: %w", err)
	}

	// If all 4 skills are updated, recalculate overall score
	if skillType != "overall" {
		recalcQuery := `
			UPDATE learning_progress
			SET overall_score = (
				COALESCE(listening_score, 0) + 
				COALESCE(reading_score, 0) + 
				COALESCE(writing_score, 0) + 
				COALESCE(speaking_score, 0)
			) / 
			NULLIF(
				(CASE WHEN listening_score IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN reading_score IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN writing_score IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN speaking_score IS NOT NULL THEN 1 ELSE 0 END),
				0
			)
			WHERE user_id = $1
		`
		_, err = tx.Exec(recalcQuery, userID)
		if err != nil {
			return fmt.Errorf("failed to recalculate overall score: %w", err)
		}
	}

	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	log.Printf("✅ Updated learning progress for user %s: %s = %.1f", userID, skillType, bandScore)
	return nil
}
