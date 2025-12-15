-- ============================================
-- ADD TIMESTAMP VALIDATION CONSTRAINTS
-- ============================================
-- Purpose: Add check constraints AFTER all data is seeded and fixed
-- Run this as the LAST step
-- ============================================

\c auth_db;

ALTER TABLE users 
    DROP CONSTRAINT IF EXISTS check_last_login_after_create,
    ADD CONSTRAINT check_last_login_after_create 
    CHECK (last_login_at IS NULL OR last_login_at >= created_at);

ALTER TABLE users 
    DROP CONSTRAINT IF EXISTS check_updated_after_create,
    ADD CONSTRAINT check_updated_after_create 
    CHECK (updated_at >= created_at);

\c user_db;

ALTER TABLE practice_activities
    DROP CONSTRAINT IF EXISTS check_completed_after_started,
    ADD CONSTRAINT check_completed_after_started
    CHECK (completed_at IS NULL OR completed_at >= started_at);

ALTER TABLE study_sessions
    DROP CONSTRAINT IF EXISTS check_session_ended_after_started,
    ADD CONSTRAINT check_session_ended_after_started
    CHECK (ended_at IS NULL OR ended_at >= started_at);

ALTER TABLE study_goals
    DROP CONSTRAINT IF EXISTS check_goal_end_after_start,
    ADD CONSTRAINT check_goal_end_after_start
    CHECK (end_date >= start_date);

ALTER TABLE study_goals
    DROP CONSTRAINT IF EXISTS check_goal_completed_in_range,
    ADD CONSTRAINT check_goal_completed_in_range
    CHECK (completed_at IS NULL OR (completed_at >= start_date AND completed_at <= end_date + INTERVAL '7 days'));

\c course_db;

ALTER TABLE course_enrollments
    DROP CONSTRAINT IF EXISTS check_enrollment_last_access_after_enrollment,
    ADD CONSTRAINT check_enrollment_last_access_after_enrollment
    CHECK (last_accessed_at IS NULL OR last_accessed_at >= enrollment_date);

ALTER TABLE course_enrollments
    DROP CONSTRAINT IF EXISTS check_enrollment_completed_after_enrollment,
    ADD CONSTRAINT check_enrollment_completed_after_enrollment
    CHECK (completed_at IS NULL OR completed_at >= enrollment_date);

ALTER TABLE lesson_progress
    DROP CONSTRAINT IF EXISTS check_lesson_last_access_after_first,
    ADD CONSTRAINT check_lesson_last_access_after_first
    CHECK (last_accessed_at >= first_accessed_at);

ALTER TABLE lesson_progress
    DROP CONSTRAINT IF EXISTS check_lesson_completed_after_first_access,
    ADD CONSTRAINT check_lesson_completed_after_first_access
    CHECK (completed_at IS NULL OR completed_at >= first_accessed_at);

\c exercise_db;

ALTER TABLE user_exercise_attempts
    DROP CONSTRAINT IF EXISTS check_attempt_completed_after_started,
    ADD CONSTRAINT check_attempt_completed_after_started
    CHECK (completed_at IS NULL OR completed_at >= started_at);

ALTER TABLE user_exercise_attempts
    DROP CONSTRAINT IF EXISTS check_attempt_sync_after_completed,
    ADD CONSTRAINT check_attempt_sync_after_completed
    CHECK (user_service_last_sync_attempt IS NULL OR 
           completed_at IS NULL OR 
           user_service_last_sync_attempt >= completed_at);

\c notification_db;

ALTER TABLE email_notifications
    DROP CONSTRAINT IF EXISTS check_email_delivered_after_sent,
    ADD CONSTRAINT check_email_delivered_after_sent
    CHECK (delivered_at IS NULL OR sent_at IS NULL OR delivered_at >= sent_at);

ALTER TABLE email_notifications
    DROP CONSTRAINT IF EXISTS check_email_opened_after_delivered,
    ADD CONSTRAINT check_email_opened_after_delivered
    CHECK (opened_at IS NULL OR delivered_at IS NULL OR opened_at >= delivered_at);

ALTER TABLE push_notifications
    DROP CONSTRAINT IF EXISTS check_push_delivered_after_sent,
    ADD CONSTRAINT check_push_delivered_after_sent
    CHECK (delivered_at IS NULL OR sent_at IS NULL OR delivered_at >= sent_at);

\c postgres;

SELECT 'âœ… Timestamp Validation Constraints Added' as status,
       'Data integrity protected against future illogical timestamps' as description;

