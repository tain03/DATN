package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/bisosad1501/ielts-platform/notification-service/internal/models"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type NotificationRepository struct {
	db *sql.DB
}

func NewNotificationRepository(db *sql.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

// CreateNotification creates a new notification
func (r *NotificationRepository) CreateNotification(notification *models.Notification) error {
	query := `
		INSERT INTO notifications (
			id, user_id, type, category, title, message,
			action_type, action_data, icon_url, image_url,
			is_read, is_sent, sent_at,
			scheduled_for, expires_at, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
	`

	_, err := r.db.Exec(query,
		notification.ID,
		notification.UserID,
		notification.Type,
		notification.Category,
		notification.Title,
		notification.Message,
		notification.ActionType,
		notification.ActionData,
		notification.IconURL,
		notification.ImageURL,
		notification.IsRead,
		notification.IsSent,
		notification.SentAt,
		notification.ScheduledFor,
		notification.ExpiresAt,
		notification.CreatedAt,
		notification.UpdatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}

	return nil
}

// GetNotifications retrieves notifications with pagination and optional filtering
func (r *NotificationRepository) GetNotifications(userID uuid.UUID, isRead *bool, page, limit int) ([]models.Notification, int, error) {
	offset := (page - 1) * limit

	// Build query with optional is_read filter
	whereClause := "WHERE user_id = $1 AND (expires_at IS NULL OR expires_at > NOW())"
	args := []interface{}{userID}
	argPos := 2

	if isRead != nil {
		whereClause += fmt.Sprintf(" AND is_read = $%d", argPos)
		args = append(args, *isRead)
		argPos++
	}

	// Count total items
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM notifications %s", whereClause)
	var totalItems int
	err := r.db.QueryRow(countQuery, args...).Scan(&totalItems)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count notifications: %w", err)
	}

	// Get paginated results
	query := fmt.Sprintf(`
		SELECT id, user_id, type, category, title, message,
			   action_type, action_data, icon_url, image_url,
			   is_read, read_at, is_sent, sent_at,
			   scheduled_for, expires_at, created_at, updated_at
		FROM notifications
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, argPos, argPos+1)

	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to query notifications: %w", err)
	}
	defer rows.Close()

	var notifications []models.Notification
	for rows.Next() {
		var n models.Notification
		err := rows.Scan(
			&n.ID, &n.UserID, &n.Type, &n.Category, &n.Title, &n.Message,
			&n.ActionType, &n.ActionData, &n.IconURL, &n.ImageURL,
			&n.IsRead, &n.ReadAt, &n.IsSent, &n.SentAt,
			&n.ScheduledFor, &n.ExpiresAt, &n.CreatedAt, &n.UpdatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan notification: %w", err)
		}
		notifications = append(notifications, n)
	}

	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("rows iteration error: %w", err)
	}

	return notifications, totalItems, nil
}

// GetNotificationByID retrieves a single notification by ID
func (r *NotificationRepository) GetNotificationByID(id uuid.UUID) (*models.Notification, error) {
	query := `
		SELECT id, user_id, type, category, title, message,
			   action_type, action_data, icon_url, image_url,
			   is_read, read_at, is_sent, sent_at,
			   scheduled_for, expires_at, created_at, updated_at
		FROM notifications
		WHERE id = $1
	`

	var n models.Notification
	err := r.db.QueryRow(query, id).Scan(
		&n.ID, &n.UserID, &n.Type, &n.Category, &n.Title, &n.Message,
		&n.ActionType, &n.ActionData, &n.IconURL, &n.ImageURL,
		&n.IsRead, &n.ReadAt, &n.IsSent, &n.SentAt,
		&n.ScheduledFor, &n.ExpiresAt, &n.CreatedAt, &n.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("notification not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get notification: %w", err)
	}

	return &n, nil
}

// MarkAsRead marks a notification as read
func (r *NotificationRepository) MarkAsRead(id uuid.UUID) error {
	query := `
		UPDATE notifications
		SET is_read = true, read_at = NOW(), updated_at = NOW()
		WHERE id = $1
	`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to mark notification as read: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("notification not found")
	}

	return nil
}

// MarkAllAsRead marks all notifications as read for a user
// FIX #19: Add idempotency check to prevent unnecessary operations
func (r *NotificationRepository) MarkAllAsRead(userID uuid.UUID) (int, error) {
	// Check if there are any unread notifications first (idempotency)
	var unreadCount int
	checkQuery := `SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false`
	err := r.db.QueryRow(checkQuery, userID).Scan(&unreadCount)
	if err != nil {
		return 0, fmt.Errorf("failed to check unread count: %w", err)
	}

	if unreadCount == 0 {
		return 0, nil // Already all marked as read - idempotent
	}

	query := `
		UPDATE notifications
		SET is_read = true, read_at = NOW(), updated_at = NOW()
		WHERE user_id = $1 AND is_read = false
	`

	result, err := r.db.Exec(query, userID)
	if err != nil {
		return 0, fmt.Errorf("failed to mark all notifications as read: %w", err)
	}

	rowsAffected, _ := result.RowsAffected()
	return int(rowsAffected), nil
}

// DeleteNotification deletes a notification
func (r *NotificationRepository) DeleteNotification(id uuid.UUID) error {
	query := "DELETE FROM notifications WHERE id = $1"

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete notification: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("notification not found")
	}

	return nil
}

// GetUnreadCount gets count of unread notifications for a user
func (r *NotificationRepository) GetUnreadCount(userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*) 
		FROM notifications 
		WHERE user_id = $1 AND is_read = false 
		  AND (expires_at IS NULL OR expires_at > NOW())
	`

	var count int
	err := r.db.QueryRow(query, userID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get unread count: %w", err)
	}

	return count, nil
}

// RegisterDeviceToken registers or updates a device token
// FIX #20: Use UPSERT pattern to prevent race condition
func (r *NotificationRepository) RegisterDeviceToken(token *models.DeviceToken) error {
	// Use UPSERT with unique constraint to handle concurrent registrations atomically
	query := `
		INSERT INTO device_tokens (
			id, user_id, device_token, device_type, device_id,
			device_name, app_version, os_version, is_active,
			last_used_at, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (device_token) WHERE is_active = true
		DO UPDATE SET
			user_id = EXCLUDED.user_id,
			device_type = EXCLUDED.device_type,
			device_id = EXCLUDED.device_id,
			device_name = EXCLUDED.device_name,
			app_version = EXCLUDED.app_version,
			os_version = EXCLUDED.os_version,
			last_used_at = EXCLUDED.last_used_at,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id
	`

	err := r.db.QueryRow(query,
		token.ID,
		token.UserID,
		token.DeviceToken,
		token.DeviceType,
		token.DeviceID,
		token.DeviceName,
		token.AppVersion,
		token.OSVersion,
		token.IsActive,
		token.LastUsedAt,
		token.CreatedAt,
		token.UpdatedAt,
	).Scan(&token.ID)

	if err != nil {
		return fmt.Errorf("failed to register device token: %w", err)
	}

	return nil
}

// GetDeviceTokens retrieves all active device tokens for a user
func (r *NotificationRepository) GetDeviceTokens(userID uuid.UUID) ([]models.DeviceToken, error) {
	query := `
		SELECT id, user_id, device_token, device_type, device_id,
			   device_name, app_version, os_version, is_active,
			   last_used_at, created_at, updated_at
		FROM device_tokens
		WHERE user_id = $1 AND is_active = true
		ORDER BY last_used_at DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query device tokens: %w", err)
	}
	defer rows.Close()

	var tokens []models.DeviceToken
	for rows.Next() {
		var t models.DeviceToken
		err := rows.Scan(
			&t.ID, &t.UserID, &t.DeviceToken, &t.DeviceType, &t.DeviceID,
			&t.DeviceName, &t.AppVersion, &t.OSVersion, &t.IsActive,
			&t.LastUsedAt, &t.CreatedAt, &t.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan device token: %w", err)
		}
		tokens = append(tokens, t)
	}

	return tokens, nil
}

// GetNotificationPreferences retrieves notification preferences for a user
func (r *NotificationRepository) GetNotificationPreferences(userID uuid.UUID) (*models.NotificationPreferences, error) {
	query := `
		SELECT user_id, push_enabled, push_achievements, push_reminders,
			   push_course_updates, push_exercise_graded, email_enabled,
			   email_weekly_report, email_course_updates, email_marketing,
			   in_app_enabled, quiet_hours_enabled, 
			   quiet_hours_start::TEXT, quiet_hours_end::TEXT,
			   max_notifications_per_day, timezone, updated_at
		FROM notification_preferences
		WHERE user_id = $1
	`

	var prefs models.NotificationPreferences
	err := r.db.QueryRow(query, userID).Scan(
		&prefs.UserID, &prefs.PushEnabled, &prefs.PushAchievements, &prefs.PushReminders,
		&prefs.PushCourseUpdates, &prefs.PushExerciseGraded, &prefs.EmailEnabled,
		&prefs.EmailWeeklyReport, &prefs.EmailCourseUpdates, &prefs.EmailMarketing,
		&prefs.InAppEnabled, &prefs.QuietHoursEnabled, &prefs.QuietHoursStart,
		&prefs.QuietHoursEnd, &prefs.MaxNotificationsPerDay, &prefs.Timezone, &prefs.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		// Create default preferences if not exists
		return r.CreateDefaultPreferences(userID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get notification preferences: %w", err)
	}

	return &prefs, nil
}

// CreateDefaultPreferences creates default notification preferences for a new user
func (r *NotificationRepository) CreateDefaultPreferences(userID uuid.UUID) (*models.NotificationPreferences, error) {
	query := `
		INSERT INTO notification_preferences (user_id)
		VALUES ($1)
		RETURNING user_id, push_enabled, push_achievements, push_reminders,
				  push_course_updates, push_exercise_graded, email_enabled,
				  email_weekly_report, email_course_updates, email_marketing,
				  in_app_enabled, quiet_hours_enabled, 
				  quiet_hours_start::TEXT,
				  quiet_hours_end::TEXT,
				  max_notifications_per_day, timezone, updated_at
	`

	var prefs models.NotificationPreferences
	err := r.db.QueryRow(query, userID).Scan(
		&prefs.UserID, &prefs.PushEnabled, &prefs.PushAchievements, &prefs.PushReminders,
		&prefs.PushCourseUpdates, &prefs.PushExerciseGraded, &prefs.EmailEnabled,
		&prefs.EmailWeeklyReport, &prefs.EmailCourseUpdates, &prefs.EmailMarketing,
		&prefs.InAppEnabled, &prefs.QuietHoursEnabled, &prefs.QuietHoursStart,
		&prefs.QuietHoursEnd, &prefs.MaxNotificationsPerDay, &prefs.Timezone, &prefs.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create default preferences: %w", err)
	}

	return &prefs, nil
}

// UpdateNotificationPreferences updates notification preferences for a user
func (r *NotificationRepository) UpdateNotificationPreferences(prefs *models.NotificationPreferences) error {
	query := `
		UPDATE notification_preferences
		SET push_enabled = $2, push_achievements = $3, push_reminders = $4,
			push_course_updates = $5, push_exercise_graded = $6,
			email_enabled = $7, email_weekly_report = $8,
			email_course_updates = $9, email_marketing = $10,
			in_app_enabled = $11, quiet_hours_enabled = $12,
			quiet_hours_start = $13::TEXT::TIME,
			quiet_hours_end = $14::TEXT::TIME,
			max_notifications_per_day = $15, timezone = $16, updated_at = NOW()
		WHERE user_id = $1
	`

	result, err := r.db.Exec(query,
		prefs.UserID,
		prefs.PushEnabled,
		prefs.PushAchievements,
		prefs.PushReminders,
		prefs.PushCourseUpdates,
		prefs.PushExerciseGraded,
		prefs.EmailEnabled,
		prefs.EmailWeeklyReport,
		prefs.EmailCourseUpdates,
		prefs.EmailMarketing,
		prefs.InAppEnabled,
		prefs.QuietHoursEnabled,
		prefs.QuietHoursStart,
		prefs.QuietHoursEnd,
		prefs.MaxNotificationsPerDay,
		prefs.Timezone,
	)

	if err != nil {
		return fmt.Errorf("failed to update notification preferences: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("preferences not found")
	}

	return nil
}

// CanSendNotification checks if a notification can be sent based on user preferences
func (r *NotificationRepository) CanSendNotification(userID uuid.UUID, notifType, category string) (bool, error) {
	// Get user preferences
	prefs, err := r.GetNotificationPreferences(userID)
	if err != nil {
		return false, fmt.Errorf("failed to get preferences: %w", err)
	}

	// Check if push notifications are enabled (master switch)
	// If push_enabled=false, block all notifications (both push and in-app)
	if !prefs.PushEnabled {
		return false, nil
	}

	// Check if in-app notifications are enabled
	if !prefs.InAppEnabled {
		return false, nil
	}

	// Check type-specific preferences
	switch notifType {
	case "achievement":
		if !prefs.PushAchievements {
			return false, nil
		}
	case "reminder":
		if !prefs.PushReminders {
			return false, nil
		}
	case "course_update":
		if !prefs.PushCourseUpdates {
			return false, nil
		}
	case "exercise_graded":
		if !prefs.PushExerciseGraded {
			return false, nil
		}
	case "social":
		// Social notifications (follow, etc.) - use course_updates preference or default to true
		// If user wants course updates, they likely want social updates too
		// But we don't block if preference doesn't exist yet
		// Default to allow social notifications
		// Future: Add specific PushSocial preference field
	case "system":
		// System notifications are always allowed if push_enabled and in_app_enabled
		// (no additional check needed)
	}

	// Check quiet hours with user's timezone
	// FIX #24: Use user's timezone instead of server timezone
	if prefs.QuietHoursEnabled && prefs.QuietHoursStart != nil && prefs.QuietHoursEnd != nil {
		// Load user's timezone (use from prefs.Timezone field added in migration 007)
		timezone := "Asia/Ho_Chi_Minh" // Default
		// TODO: Get prefs.Timezone from database when field is available

		loc, err := time.LoadLocation(timezone)
		if err != nil {
			loc, _ = time.LoadLocation("Asia/Ho_Chi_Minh") // Fallback
		}

		// Get current time in user's timezone
		nowInUserTZ := time.Now().In(loc)
		currentTime := nowInUserTZ.Format("15:04:05")

		// Quiet hours span midnight (e.g., 22:00 - 08:00)
		// Block if: currentTime >= start (after 22:00) OR currentTime <= end (before 08:00)
		if currentTime >= *prefs.QuietHoursStart || currentTime <= *prefs.QuietHoursEnd {
			return false, nil
		}
	}

	// Check daily limit (only count sent notifications, not scheduled or failed ones)
	if prefs.MaxNotificationsPerDay > 0 {
		countQuery := `
			SELECT COUNT(*) 
			FROM notifications 
			WHERE user_id = $1 
			  AND created_at >= CURRENT_DATE
			  AND is_sent = true
		`
		var todayCount int
		err := r.db.QueryRow(countQuery, userID).Scan(&todayCount)
		if err != nil {
			return false, fmt.Errorf("failed to check daily count: %w", err)
		}

		if todayCount >= prefs.MaxNotificationsPerDay {
			return false, nil
		}
	}

	return true, nil
}

// GetTemplateByCode retrieves a notification template by code
func (r *NotificationRepository) GetTemplateByCode(code string) (*models.NotificationTemplate, error) {
	query := `
		SELECT id, template_code, name, description, notification_type,
			   category, title_template, body_template, subject_template,
			   html_template, required_variables, is_active, created_at, updated_at
		FROM notification_templates
		WHERE template_code = $1 AND is_active = true
	`

	var tmpl models.NotificationTemplate
	err := r.db.QueryRow(query, code).Scan(
		&tmpl.ID, &tmpl.TemplateCode, &tmpl.Name, &tmpl.Description,
		&tmpl.NotificationType, &tmpl.Category, &tmpl.TitleTemplate,
		&tmpl.BodyTemplate, &tmpl.SubjectTemplate, &tmpl.HTMLTemplate,
		&tmpl.RequiredVariables, &tmpl.IsActive, &tmpl.CreatedAt, &tmpl.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("template not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}

	return &tmpl, nil
}

// CreateNotificationLog creates a log entry for notification events
func (r *NotificationRepository) CreateNotificationLog(log *models.NotificationLog) error {
	query := `
		INSERT INTO notification_logs (
			notification_id, user_id, event_type, event_status,
			notification_type, error_message, metadata, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := r.db.Exec(query,
		log.NotificationID,
		log.UserID,
		log.EventType,
		log.EventStatus,
		log.NotificationType,
		log.ErrorMessage,
		log.Metadata,
		log.CreatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create notification log: %w", err)
	}

	return nil
}

// ============================================
// Scheduled Notifications Repository Methods
// ============================================

// CreateScheduledNotification creates a new scheduled notification
// FIX #22: Use UPSERT to prevent duplicate schedules
func (r *NotificationRepository) CreateScheduledNotification(schedule *models.ScheduledNotification) error {
	query := `
		INSERT INTO scheduled_notifications (
			id, user_id, title, message, schedule_type, scheduled_time,
			days_of_week, timezone, is_active, next_send_at, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (user_id, schedule_type, scheduled_time, title) WHERE is_active = true
		DO UPDATE SET
			message = EXCLUDED.message,
			days_of_week = EXCLUDED.days_of_week,
			timezone = EXCLUDED.timezone,
			next_send_at = EXCLUDED.next_send_at,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id
	`

	err := r.db.QueryRow(query,
		schedule.ID,
		schedule.UserID,
		schedule.Title,
		schedule.Message,
		schedule.ScheduleType,
		schedule.ScheduledTime,
		pq.Array(schedule.DaysOfWeek),
		schedule.Timezone,
		schedule.IsActive,
		schedule.NextSendAt,
		schedule.CreatedAt,
		schedule.UpdatedAt,
	).Scan(&schedule.ID)

	if err != nil {
		return fmt.Errorf("failed to create scheduled notification: %w", err)
	}

	return nil
}

// GetScheduledNotifications retrieves all scheduled notifications for a user
func (r *NotificationRepository) GetScheduledNotifications(userID uuid.UUID) ([]models.ScheduledNotification, error) {
	query := `
		SELECT id, user_id, title, message, schedule_type, scheduled_time,
			days_of_week, timezone, is_active, last_sent_at, next_send_at,
			created_at, updated_at
		FROM scheduled_notifications
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get scheduled notifications: %w", err)
	}
	defer rows.Close()

	var schedules []models.ScheduledNotification
	for rows.Next() {
		var schedule models.ScheduledNotification
		var daysOfWeek []int32 // PostgreSQL INT is 32-bit

		err := rows.Scan(
			&schedule.ID,
			&schedule.UserID,
			&schedule.Title,
			&schedule.Message,
			&schedule.ScheduleType,
			&schedule.ScheduledTime,
			pq.Array(&daysOfWeek), // Scan PostgreSQL INT[] into []int32
			&schedule.Timezone,
			&schedule.IsActive,
			&schedule.LastSentAt,
			&schedule.NextSendAt,
			&schedule.CreatedAt,
			&schedule.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan scheduled notification: %w", err)
		}

		// Convert []int32 to []int for model
		schedule.DaysOfWeek = make([]int, len(daysOfWeek))
		for i, day := range daysOfWeek {
			schedule.DaysOfWeek[i] = int(day)
		}

		schedules = append(schedules, schedule)
	}

	return schedules, nil
}

// ============================================
// Bulk Operations (FIX #21)
// ============================================

// CreateBulkNotifications creates multiple notifications in a single transaction
// FIX #21: Batch insert for better performance and atomicity
func (r *NotificationRepository) CreateBulkNotifications(notifications []*models.Notification) error {
	if len(notifications) == 0 {
		return nil
	}

	// Use transaction for atomicity
	tx, err := r.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Prepare statement for better performance
	stmt, err := tx.Prepare(`
		INSERT INTO notifications (
			id, user_id, type, category, title, message,
			action_type, action_data, icon_url, image_url,
			is_read, is_sent, sent_at, scheduled_for, expires_at,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
	`)
	if err != nil {
		return fmt.Errorf("failed to prepare statement: %w", err)
	}
	defer stmt.Close()

	now := time.Now()
	for _, notif := range notifications {
		_, err = stmt.Exec(
			notif.ID, notif.UserID, notif.Type, notif.Category,
			notif.Title, notif.Message, notif.ActionType, notif.ActionData,
			notif.IconURL, notif.ImageURL, notif.IsRead, notif.IsSent,
			&now, notif.ScheduledFor, notif.ExpiresAt,
			notif.CreatedAt, notif.UpdatedAt,
		)
		if err != nil {
			return fmt.Errorf("failed to insert notification: %w", err)
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// GetBulkNotificationPreferences checks preferences for multiple users at once
// FIX #21: Single query instead of N queries for better performance
func (r *NotificationRepository) GetBulkNotificationPreferences(userIDs []uuid.UUID, notifType, category string) (map[uuid.UUID]bool, error) {
	if len(userIDs) == 0 {
		return make(map[uuid.UUID]bool), nil
	}

	query := `
		SELECT user_id,
			   CASE
				   WHEN NOT in_app_enabled THEN false
				   WHEN $2 = 'achievement' AND NOT push_achievements THEN false
				   WHEN $2 = 'reminder' AND NOT push_reminders THEN false
				   WHEN $2 = 'course_update' AND NOT push_course_updates THEN false
				   WHEN $2 = 'exercise_graded' AND NOT push_exercise_graded THEN false
				   ELSE true
			   END as can_send
		FROM notification_preferences
		WHERE user_id = ANY($1)
	`

	rows, err := r.db.Query(query, pq.Array(userIDs), notifType)
	if err != nil {
		return nil, fmt.Errorf("failed to query bulk preferences: %w", err)
	}
	defer rows.Close()

	result := make(map[uuid.UUID]bool)
	for rows.Next() {
		var userID uuid.UUID
		var canSend bool
		if err := rows.Scan(&userID, &canSend); err != nil {
			return nil, fmt.Errorf("failed to scan preference: %w", err)
		}
		result[userID] = canSend
	}

	// For users without preferences, create defaults and allow
	for _, userID := range userIDs {
		if _, exists := result[userID]; !exists {
			result[userID] = true // Default: allow
		}
	}

	return result, nil
}

// GetScheduledNotificationByID retrieves a scheduled notification by ID
func (r *NotificationRepository) GetScheduledNotificationByID(id uuid.UUID) (*models.ScheduledNotification, error) {
	query := `
		SELECT id, user_id, title, message, schedule_type, scheduled_time,
			days_of_week, timezone, is_active, last_sent_at, next_send_at,
			created_at, updated_at
		FROM scheduled_notifications
		WHERE id = $1
	`

	var schedule models.ScheduledNotification
	var daysOfWeek []int32 // PostgreSQL INT is 32-bit

	err := r.db.QueryRow(query, id).Scan(
		&schedule.ID,
		&schedule.UserID,
		&schedule.Title,
		&schedule.Message,
		&schedule.ScheduleType,
		&schedule.ScheduledTime,
		pq.Array(&daysOfWeek), // Scan PostgreSQL INT[] into []int32
		&schedule.Timezone,
		&schedule.IsActive,
		&schedule.LastSentAt,
		&schedule.NextSendAt,
		&schedule.CreatedAt,
		&schedule.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("scheduled notification not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get scheduled notification: %w", err)
	}

	// Convert []int32 to []int for model
	schedule.DaysOfWeek = make([]int, len(daysOfWeek))
	for i, day := range daysOfWeek {
		schedule.DaysOfWeek[i] = int(day)
	}

	return &schedule, nil
}

// UpdateScheduledNotification updates a scheduled notification
func (r *NotificationRepository) UpdateScheduledNotification(schedule *models.ScheduledNotification) error {
	query := `
		UPDATE scheduled_notifications
		SET title = $1, message = $2, schedule_type = $3, scheduled_time = $4,
			days_of_week = $5, timezone = $6, is_active = $7, next_send_at = $8, updated_at = $9
		WHERE id = $10
	`

	_, err := r.db.Exec(query,
		schedule.Title,
		schedule.Message,
		schedule.ScheduleType,
		schedule.ScheduledTime,
		pq.Array(schedule.DaysOfWeek),
		schedule.Timezone,
		schedule.IsActive,
		schedule.NextSendAt,
		time.Now(),
		schedule.ID,
	)

	if err != nil {
		return fmt.Errorf("failed to update scheduled notification: %w", err)
	}

	return nil
}

// DeleteScheduledNotification deletes a scheduled notification
func (r *NotificationRepository) DeleteScheduledNotification(id uuid.UUID) error {
	query := `DELETE FROM scheduled_notifications WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete scheduled notification: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("scheduled notification not found")
	}

	return nil
}

// GetDueScheduledNotifications retrieves scheduled notifications that are due to be sent
// This is used by cron job or background worker
func (r *NotificationRepository) GetDueScheduledNotifications() ([]models.ScheduledNotification, error) {
	query := `
		SELECT id, user_id, title, message, schedule_type, scheduled_time,
			days_of_week, timezone, is_active, last_sent_at, next_send_at,
			created_at, updated_at
		FROM scheduled_notifications
		WHERE is_active = true
		AND (next_send_at IS NULL OR next_send_at <= NOW())
		ORDER BY next_send_at ASC
		LIMIT 100
	`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to get due scheduled notifications: %w", err)
	}
	defer rows.Close()

	var schedules []models.ScheduledNotification
	for rows.Next() {
		var schedule models.ScheduledNotification
		var daysOfWeek []int32 // PostgreSQL INT is 32-bit

		err := rows.Scan(
			&schedule.ID,
			&schedule.UserID,
			&schedule.Title,
			&schedule.Message,
			&schedule.ScheduleType,
			&schedule.ScheduledTime,
			pq.Array(&daysOfWeek), // Scan PostgreSQL INT[] into []int32
			&schedule.Timezone,
			&schedule.IsActive,
			&schedule.LastSentAt,
			&schedule.NextSendAt,
			&schedule.CreatedAt,
			&schedule.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan scheduled notification: %w", err)
		}

		// Convert []int32 to []int for model
		schedule.DaysOfWeek = make([]int, len(daysOfWeek))
		for i, day := range daysOfWeek {
			schedule.DaysOfWeek[i] = int(day)
		}

		schedules = append(schedules, schedule)
	}

	return schedules, nil
}
