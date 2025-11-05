-- Rollback Migration: Restore exercise_id NOT NULL constraint
-- Purpose: Revert nullable exercise_id to NOT NULL
-- Database: exercise_db

-- WARNING: This will fail if any records have NULL exercise_id
-- Make sure to clean up or assign exercise_ids before running this rollback

ALTER TABLE user_exercise_attempts
    ALTER COLUMN exercise_id SET NOT NULL;

COMMENT ON COLUMN user_exercise_attempts.exercise_id IS 'Exercise ID (NOT NULL)';
