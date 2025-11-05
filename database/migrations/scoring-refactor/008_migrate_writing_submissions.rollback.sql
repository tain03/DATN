-- Rollback Migration: Revert writing_submissions migration
-- Purpose: Remove migrated writing submissions from exercise_db
-- Target DB: exercise_db (user_exercise_attempts)
-- Phase: 6 - Data Migration Rollback

-- Step 1: Log rollback start
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '008_migrate_writing_submissions_ROLLBACK',
    'exercise_db.user_exercise_attempts',
    'ai_db.writing_submissions',
    (SELECT COUNT(*) FROM user_exercise_attempts WHERE essay_text IS NOT NULL),
    'rolling_back',
    'Starting rollback of writing submissions migration'
);

-- Step 2: Delete migrated writing submissions
-- Identify by: essay_text IS NOT NULL (only writing submissions have essays)
DELETE FROM user_exercise_attempts
WHERE essay_text IS NOT NULL;

-- Step 3: Log rollback completion
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '008_migrate_writing_submissions_ROLLBACK',
    'exercise_db.user_exercise_attempts',
    'ai_db.writing_submissions',
    0,
    'rolled_back',
    'Successfully rolled back writing submissions migration. Data preserved in ai_db.'
);

-- Step 4: Verify rollback
DO $$
DECLARE
    remaining_count INT;
BEGIN
    SELECT COUNT(*) INTO remaining_count
    FROM user_exercise_attempts
    WHERE essay_text IS NOT NULL;
    
    IF remaining_count > 0 THEN
        RAISE WARNING 'Rollback incomplete: % records still exist with essay_text', remaining_count;
    ELSE
        RAISE NOTICE 'Rollback completed successfully: All writing submissions removed from user_exercise_attempts';
    END IF;
END $$;
