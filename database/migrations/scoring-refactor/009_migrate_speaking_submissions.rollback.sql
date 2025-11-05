-- Rollback Migration: Revert speaking_submissions migration
-- Purpose: Remove migrated speaking submissions from exercise_db
-- Target DB: exercise_db (user_exercise_attempts)
-- Phase: 6 - Data Migration Rollback

-- Step 1: Log rollback start
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '009_migrate_speaking_submissions_ROLLBACK',
    'exercise_db.user_exercise_attempts',
    'ai_db.speaking_submissions',
    (SELECT COUNT(*) FROM user_exercise_attempts WHERE audio_url IS NOT NULL),
    'rolling_back',
    'Starting rollback of speaking submissions migration'
);

-- Step 2: Delete migrated speaking submissions
-- Identify by: audio_url IS NOT NULL (only speaking submissions have audio)
DELETE FROM user_exercise_attempts
WHERE audio_url IS NOT NULL;

-- Step 3: Log rollback completion
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '009_migrate_speaking_submissions_ROLLBACK',
    'exercise_db.user_exercise_attempts',
    'ai_db.speaking_submissions',
    0,
    'rolled_back',
    'Successfully rolled back speaking submissions migration. Data preserved in ai_db.'
);

-- Step 4: Verify rollback
DO $$
DECLARE
    remaining_count INT;
BEGIN
    SELECT COUNT(*) INTO remaining_count
    FROM user_exercise_attempts
    WHERE audio_url IS NOT NULL;
    
    IF remaining_count > 0 THEN
        RAISE WARNING 'Rollback incomplete: % records still exist with audio_url', remaining_count;
    ELSE
        RAISE NOTICE 'Rollback completed successfully: All speaking submissions removed from user_exercise_attempts';
    END IF;
END $$;
