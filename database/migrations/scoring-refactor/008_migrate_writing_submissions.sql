-- Migration: Migrate writing_submissions from ai_db to exercise_db
-- Purpose: Transfer existing writing submissions and evaluations to unified schema
-- Source DB: ai_db (writing_submissions, writing_evaluations)
-- Target DB: exercise_db (user_exercise_attempts)
-- Phase: 6 - Data Migration

-- IMPORTANT: Run this AFTER Phase 1 migrations are complete
-- IMPORTANT: This requires dblink extension (migration 012)

-- Step 1: Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- Step 2: Create dblink connection to ai_db if not exists
-- Note: Connection parameters should match docker-compose.yml
DO $$
BEGIN
    PERFORM dblink_connect('ai_db_conn', 
        'host=postgres port=5432 dbname=ai_db user=ielts_admin password=ielts_password_2025');
EXCEPTION 
    WHEN duplicate_object THEN 
        NULL; -- Connection already exists
END $$;

-- Step 3: Migrate writing submissions with their evaluations
-- Insert into user_exercise_attempts from ai_db.writing_submissions
INSERT INTO user_exercise_attempts (
    id,                      -- Use original submission_id
    user_id,
    exercise_id,             -- NULL for migrated data (no exercise reference in old schema)
    
    -- Attempt details
    attempt_number,
    status,
    
    -- Scoring (will be filled from evaluations)
    total_questions,
    questions_answered,
    correct_answers,
    score,
    band_score,
    
    -- Test categorization
    is_official_test,        -- FALSE for all migrated submissions (they were practice)
    official_test_result_id, -- NULL
    practice_activity_id,    -- NULL (will be created later if needed)
    
    -- Writing-specific fields
    essay_text,
    word_count,
    task_type,
    prompt_text,
    
    -- AI evaluation fields
    evaluation_status,
    ai_evaluation_id,        -- Original evaluation ID from ai_db
    detailed_scores,         -- JSONB with 4 criteria scores
    ai_feedback,
    ai_model_name,
    ai_processing_time_ms,
    
    -- Time tracking
    time_spent_seconds,
    started_at,
    completed_at,
    
    -- Metadata
    device_type,
    
    -- Timestamps
    created_at,
    updated_at
)
SELECT 
    ws.id,                                      -- Original submission ID
    ws.user_id,
    ws.exercise_id,                             -- May be NULL
    
    -- Attempt details (default values for migrated data)
    1,                                          -- attempt_number (all first attempts)
    CASE 
        WHEN ws.status = 'completed' THEN 'completed'
        WHEN ws.status = 'failed' THEN 'abandoned'
        ELSE 'in_progress'
    END,                                        -- status
    
    -- Scoring (Writing doesn't have questions, use band score)
    0,                                          -- total_questions
    0,                                          -- questions_answered
    0,                                          -- correct_answers
    COALESCE(ws.overall_band_score * 10, 0),   -- score (convert band to percentage-like)
    ws.overall_band_score,                      -- band_score
    
    -- Test categorization
    FALSE,                                      -- is_official_test (all practice)
    NULL,                                       -- official_test_result_id
    NULL,                                       -- practice_activity_id
    
    -- Writing-specific fields
    ws.essay_text,
    ws.word_count,
    ws.task_type,
    ws.task_prompt_text,
    
    -- AI evaluation fields
    CASE 
        WHEN ws.eval_id IS NOT NULL THEN 'completed'
        WHEN ws.status = 'failed' THEN 'failed'
        WHEN ws.status = 'processing' THEN 'processing'
        ELSE 'pending'
    END,                                        -- evaluation_status
    ws.eval_id,                                 -- ai_evaluation_id
    CASE 
        WHEN ws.eval_id IS NOT NULL THEN 
            jsonb_build_object(
                'task_achievement', ws.task_achievement_score,
                'coherence_cohesion', ws.coherence_cohesion_score,
                'lexical_resource', ws.lexical_resource_score,
                'grammar_accuracy', ws.grammar_accuracy_score
            )
        ELSE NULL
    END,                                        -- detailed_scores
    ws.detailed_feedback,                       -- ai_feedback
    ws.ai_model_name,
    ws.processing_time_ms,
    
    -- Time tracking
    ws.time_spent_seconds,
    ws.submitted_at,                            -- started_at (use submitted as proxy)
    ws.evaluated_at,                            -- completed_at
    
    -- Metadata
    ws.submitted_from,                          -- device_type
    
    -- Timestamps
    ws.created_at,
    ws.updated_at
FROM dblink('ai_db_conn', 
    'SELECT 
        ws.id, ws.user_id, ws.exercise_id,
        ws.status, ws.essay_text, ws.word_count,
        ws.task_type, ws.task_prompt_text,
        ws.time_spent_seconds, ws.submitted_at,
        ws.submitted_from, ws.created_at, ws.updated_at,
        ws.evaluated_at,
        we.id as eval_id, we.overall_band_score,
        we.task_achievement_score, we.coherence_cohesion_score,
        we.lexical_resource_score, we.grammar_accuracy_score,
        we.detailed_feedback, we.ai_model_name, we.processing_time_ms
    FROM writing_submissions ws
    LEFT JOIN writing_evaluations we ON ws.id = we.submission_id'
) AS ws(
    id UUID, user_id UUID, exercise_id UUID,
    status VARCHAR, essay_text TEXT, word_count INT,
    task_type VARCHAR, task_prompt_text TEXT,
    time_spent_seconds INT, submitted_at TIMESTAMP,
    submitted_from VARCHAR, created_at TIMESTAMP, updated_at TIMESTAMP,
    evaluated_at TIMESTAMP,
    eval_id UUID, overall_band_score DECIMAL,
    task_achievement_score DECIMAL, coherence_cohesion_score DECIMAL,
    lexical_resource_score DECIMAL, grammar_accuracy_score DECIMAL,
    detailed_feedback TEXT, ai_model_name VARCHAR, processing_time_ms INT
)
ON CONFLICT (id) DO NOTHING; -- Skip if already migrated

-- Step 4: Disconnect from ai_db
SELECT dblink_disconnect('ai_db_conn');

-- Step 5: Verify migration
DO $$
DECLARE
    migrated_count INT;
    original_count INT;
BEGIN
    -- Count migrated records
    SELECT COUNT(*) INTO migrated_count
    FROM user_exercise_attempts
    WHERE essay_text IS NOT NULL;
    
    -- Get original count from ai_db (commented for now, needs dblink)
    -- SELECT COUNT(*) INTO original_count FROM dblink(...) 
    
    RAISE NOTICE 'Migration completed: % writing submissions migrated to user_exercise_attempts', migrated_count;
END $$;

-- Step 6: Create temporary tracking table for migration audit
CREATE TABLE IF NOT EXISTS migration_audit (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(100) NOT NULL,
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    records_migrated INT,
    migration_status VARCHAR(20),
    migrated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Log migration
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '008_migrate_writing_submissions',
    'ai_db.writing_submissions',
    'exercise_db.user_exercise_attempts',
    (SELECT COUNT(*) FROM user_exercise_attempts WHERE essay_text IS NOT NULL),
    'completed',
    'Migrated writing submissions and evaluations from ai_db to exercise_db'
);

-- Add comments
COMMENT ON TABLE migration_audit IS 'Audit log for data migrations between databases';
