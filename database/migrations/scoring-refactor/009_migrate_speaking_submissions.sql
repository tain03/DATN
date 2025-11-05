-- Migration: Migrate speaking_submissions from ai_db to exercise_db
-- Purpose: Transfer existing speaking submissions and evaluations to unified schema
-- Source DB: ai_db (speaking_submissions, speaking_evaluations)
-- Target DB: exercise_db (user_exercise_attempts)
-- Phase: 6 - Data Migration

-- IMPORTANT: Run this AFTER writing migration (008) is complete
-- IMPORTANT: This requires dblink extension (migration 012)

-- Step 1: Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- Step 2: Create dblink connection to ai_db if not exists
DO $$
BEGIN
    PERFORM dblink_connect('ai_db_conn', 
        'host=postgres port=5432 dbname=ai_db user=ielts_admin password=ielts_password_2025');
EXCEPTION 
    WHEN duplicate_object THEN 
        NULL; -- Connection already exists
END $$;

-- Step 3: Migrate speaking submissions with their evaluations
-- Insert into user_exercise_attempts from ai_db.speaking_submissions
INSERT INTO user_exercise_attempts (
    id,                      -- Use original submission_id
    user_id,
    exercise_id,             -- NULL for migrated data
    
    -- Attempt details
    attempt_number,
    status,
    
    -- Scoring
    total_questions,
    questions_answered,
    correct_answers,
    score,
    band_score,
    
    -- Test categorization
    is_official_test,
    official_test_result_id,
    practice_activity_id,
    
    -- Speaking-specific fields
    audio_url,
    audio_duration_seconds,
    audio_format,
    transcript_text,
    transcript_word_count,
    speaking_part_number,
    prompt_text,              -- From task_prompt_text
    
    -- AI evaluation fields
    evaluation_status,
    ai_evaluation_id,
    detailed_scores,          -- JSONB with 4 criteria scores
    ai_feedback,
    ai_model_name,
    ai_processing_time_ms,
    
    -- Time tracking
    time_spent_seconds,       -- NULL for speaking (not tracked in old schema)
    started_at,
    completed_at,
    
    -- Metadata
    device_type,
    
    -- Timestamps
    created_at,
    updated_at
)
SELECT 
    ss.id,                                      -- Original submission ID
    ss.user_id,
    ss.exercise_id,                             -- May be NULL
    
    -- Attempt details
    1,                                          -- attempt_number
    CASE 
        WHEN ss.status = 'completed' THEN 'completed'
        WHEN ss.status = 'failed' THEN 'abandoned'
        ELSE 'in_progress'
    END,                                        -- status
    
    -- Scoring
    0,                                          -- total_questions
    0,                                          -- questions_answered
    0,                                          -- correct_answers
    COALESCE(ss.overall_band_score * 10, 0),   -- score
    ss.overall_band_score,                      -- band_score
    
    -- Test categorization
    FALSE,                                      -- is_official_test
    NULL,                                       -- official_test_result_id
    NULL,                                       -- practice_activity_id
    
    -- Speaking-specific fields
    ss.audio_url,
    ss.audio_duration_seconds,
    ss.audio_format,
    ss.transcript_text,
    ss.transcript_word_count,
    ss.part_number,
    ss.task_prompt_text,
    
    -- AI evaluation fields
    CASE 
        WHEN ss.eval_id IS NOT NULL THEN 'completed'
        WHEN ss.status = 'failed' THEN 'failed'
        WHEN ss.status = 'transcribing' THEN 'processing'
        WHEN ss.status = 'processing' THEN 'processing'
        ELSE 'pending'
    END,                                        -- evaluation_status
    ss.eval_id,                                 -- ai_evaluation_id
    CASE 
        WHEN ss.eval_id IS NOT NULL THEN 
            jsonb_build_object(
                'fluency_coherence', ss.fluency_coherence_score,
                'lexical_resource', ss.lexical_resource_score,
                'grammar_accuracy', ss.grammar_accuracy_score,
                'pronunciation', ss.pronunciation_score
            )
        ELSE NULL
    END,                                        -- detailed_scores
    ss.detailed_feedback,                       -- ai_feedback
    ss.evaluation_model,                        -- ai_model_name
    COALESCE(ss.transcription_time_ms, 0) + COALESCE(ss.evaluation_time_ms, 0), -- Total processing time
    
    -- Time tracking
    NULL,                                       -- time_spent_seconds (not in old schema)
    ss.submitted_at,                            -- started_at
    ss.evaluated_at,                            -- completed_at
    
    -- Metadata
    ss.recorded_from,                           -- device_type
    
    -- Timestamps
    ss.created_at,
    ss.updated_at
FROM dblink('ai_db_conn', 
    'SELECT 
        ss.id, ss.user_id, ss.exercise_id,
        ss.status, ss.audio_url, ss.audio_duration_seconds,
        ss.audio_format, ss.transcript_text, ss.transcript_word_count,
        ss.part_number, ss.task_prompt_text,
        ss.submitted_at, ss.recorded_from,
        ss.created_at, ss.updated_at,
        ss.evaluated_at,
        se.id as eval_id, se.overall_band_score,
        se.fluency_coherence_score, se.lexical_resource_score,
        se.grammar_accuracy_score, se.pronunciation_score,
        se.detailed_feedback, se.evaluation_model,
        se.transcription_time_ms, se.evaluation_time_ms
    FROM speaking_submissions ss
    LEFT JOIN speaking_evaluations se ON ss.id = se.submission_id'
) AS ss(
    id UUID, user_id UUID, exercise_id UUID,
    status VARCHAR, audio_url TEXT, audio_duration_seconds INT,
    audio_format VARCHAR, transcript_text TEXT, transcript_word_count INT,
    part_number INT, task_prompt_text TEXT,
    submitted_at TIMESTAMP, recorded_from VARCHAR,
    created_at TIMESTAMP, updated_at TIMESTAMP,
    evaluated_at TIMESTAMP,
    eval_id UUID, overall_band_score DECIMAL,
    fluency_coherence_score DECIMAL, lexical_resource_score DECIMAL,
    grammar_accuracy_score DECIMAL, pronunciation_score DECIMAL,
    detailed_feedback TEXT, evaluation_model VARCHAR,
    transcription_time_ms INT, evaluation_time_ms INT
)
ON CONFLICT (id) DO NOTHING; -- Skip if already migrated

-- Step 4: Disconnect from ai_db
SELECT dblink_disconnect('ai_db_conn');

-- Step 5: Verify migration
DO $$
DECLARE
    migrated_count INT;
BEGIN
    SELECT COUNT(*) INTO migrated_count
    FROM user_exercise_attempts
    WHERE audio_url IS NOT NULL;
    
    RAISE NOTICE 'Migration completed: % speaking submissions migrated to user_exercise_attempts', migrated_count;
END $$;

-- Step 6: Log migration
INSERT INTO migration_audit (migration_name, source_table, target_table, records_migrated, migration_status, notes)
VALUES (
    '009_migrate_speaking_submissions',
    'ai_db.speaking_submissions',
    'exercise_db.user_exercise_attempts',
    (SELECT COUNT(*) FROM user_exercise_attempts WHERE audio_url IS NOT NULL),
    'completed',
    'Migrated speaking submissions and evaluations from ai_db to exercise_db'
);
