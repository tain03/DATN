-- Migration: Make exercise_id nullable in user_exercise_attempts
-- Purpose: Allow migrated submissions from ai_db (which don't have exercise_id)
-- Database: exercise_db
-- Phase: 6 - Data Migration Preparation

-- Make exercise_id nullable (was NOT NULL before)
ALTER TABLE user_exercise_attempts
    ALTER COLUMN exercise_id DROP NOT NULL;

-- Add comment explaining why NULL is allowed
COMMENT ON COLUMN user_exercise_attempts.exercise_id IS 'Exercise ID (nullable for migrated submissions from ai_db that were standalone practice)';

-- Note: Foreign key constraint still exists, so if exercise_id is provided, it must be valid
