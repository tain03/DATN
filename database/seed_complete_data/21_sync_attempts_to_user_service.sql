-- ============================================
-- SYNC EXERCISE ATTEMPTS TO USER SERVICE
-- ============================================
-- Purpose: Sync completed exercise attempts to user_db tables
-- Databases: exercise_db â†’ user_db
-- 
-- SYNCS:
-- 1. Completed attempts â†’ practice_activities (drills, mini-tests)
-- 2. Official test attempts â†’ official_test_results (full tests)
-- 3. Update sync status in user_exercise_attempts
-- ============================================

-- ============================================
-- SETUP: Create dblink connection if not exists
-- ============================================

-- Note: This assumes databases are on same PostgreSQL server
-- If on different servers, adjust connection string accordingly

DO $$
BEGIN
    -- Test connection to user_db
    PERFORM dblink_connect('user_db_conn', 'dbname=user_db');
    PERFORM dblink_disconnect('user_db_conn');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not connect to user_db: %', SQLERRM;
END $$;

-- ============================================
-- SYNC TO PRACTICE_ACTIVITIES
-- ============================================

-- Sync completed exercise attempts (non-official tests) to practice_activities
DO $$
DECLARE
    attempt_record RECORD;
    new_activity_id UUID;
    skill_mapped VARCHAR(20);
    activity_type_mapped VARCHAR(30);
BEGIN
    FOR attempt_record IN 
        SELECT 
            uea.id,
            uea.user_id,
            uea.exercise_id,
            uea.correct_answers,
            uea.total_questions,
            uea.score,
            uea.band_score,
            uea.time_spent_seconds,
            uea.started_at,
            uea.completed_at,
            e.skill_type,
            e.title,
            e.difficulty,
            e.is_official_test,
            e.test_category,
            -- Calculate accuracy
            CASE 
                WHEN uea.total_questions > 0 THEN 
                    ROUND((uea.correct_answers::NUMERIC / uea.total_questions::NUMERIC) * 100, 2)
                ELSE 0
            END as accuracy_percentage
        FROM user_exercise_attempts uea
        JOIN exercises e ON uea.exercise_id = e.id
        WHERE 
            uea.status = 'completed'
            AND uea.user_service_sync_status = 'pending'
            AND uea.is_official_test = false
            AND uea.completed_at IS NOT NULL
        ORDER BY uea.completed_at
    LOOP
        -- Map activity_type based on exercise
        activity_type_mapped := CASE
            WHEN attempt_record.test_category = 'mini_test' THEN 'part_test'
            WHEN attempt_record.test_category = 'practice' THEN 'drill'
            ELSE 'question_set'
        END;

        -- Generate new activity ID
        new_activity_id := gen_random_uuid();

        -- Insert to practice_activities via dblink
        BEGIN
            PERFORM dblink_exec('user_db_conn',
                format('
                    INSERT INTO practice_activities (
                        id, user_id, skill, activity_type,
                        exercise_id, exercise_title,
                        score, max_score, band_score,
                        correct_answers, total_questions, accuracy_percentage,
                        time_spent_seconds, started_at, completed_at,
                        completion_status, ai_evaluated, difficulty_level,
                        created_at, updated_at
                    ) VALUES (
                        %L, %L, %L, %L,
                        %L, %L,
                        %L, %L, %L,
                        %L, %L, %L,
                        %L, %L, %L,
                        %L, %L, %L,
                        %L, %L
                    )
                    ON CONFLICT (id) DO NOTHING
                ',
                    new_activity_id,
                    attempt_record.user_id,
                    attempt_record.skill_type,
                    activity_type_mapped,
                    attempt_record.exercise_id,
                    attempt_record.title,
                    attempt_record.score,
                    attempt_record.score, -- max_score = score for now
                    attempt_record.band_score,
                    attempt_record.correct_answers,
                    attempt_record.total_questions,
                    attempt_record.accuracy_percentage,
                    attempt_record.time_spent_seconds,
                    attempt_record.started_at,
                    attempt_record.completed_at,
                    'completed',
                    CASE WHEN attempt_record.skill_type IN ('writing', 'speaking') THEN true ELSE false END,
                    attempt_record.difficulty,
                    attempt_record.completed_at,
                    attempt_record.completed_at
                )
            );

            -- Update sync status
            UPDATE user_exercise_attempts
            SET 
                user_service_sync_status = 'synced',
                practice_activity_id = new_activity_id,
                user_service_last_sync_attempt = NOW(),
                updated_at = NOW()
            WHERE id = attempt_record.id;

            RAISE NOTICE 'Synced attempt % to practice_activity %', attempt_record.id, new_activity_id;

        EXCEPTION
            WHEN OTHERS THEN
                -- Update sync status to failed
                UPDATE user_exercise_attempts
                SET 
                    user_service_sync_status = 'failed',
                    user_service_sync_attempts = user_service_sync_attempts + 1,
                    user_service_last_sync_attempt = NOW(),
                    user_service_sync_error = SQLERRM,
                    updated_at = NOW()
                WHERE id = attempt_record.id;

                RAISE NOTICE 'Failed to sync attempt %: %', attempt_record.id, SQLERRM;
        END;

    END LOOP;
END $$;

-- ============================================
-- SYNC TO OFFICIAL_TEST_RESULTS
-- ============================================

-- Sync official test attempts to official_test_results
DO $$
DECLARE
    attempt_record RECORD;
    new_result_id UUID;
    test_type_mapped VARCHAR(20);
    ielts_variant_value VARCHAR(20);
BEGIN
    FOR attempt_record IN 
        SELECT 
            uea.id,
            uea.user_id,
            uea.exercise_id,
            uea.correct_answers,
            uea.total_questions,
            uea.band_score,
            uea.time_spent_seconds,
            uea.started_at,
            uea.completed_at,
            e.skill_type,
            e.title,
            e.test_category,
            e.ielts_test_type,
            e.time_limit_minutes
        FROM user_exercise_attempts uea
        JOIN exercises e ON uea.exercise_id = e.id
        WHERE 
            uea.status = 'completed'
            AND uea.user_service_sync_status = 'pending'
            AND uea.is_official_test = true
            AND uea.completed_at IS NOT NULL
            AND uea.band_score IS NOT NULL
        ORDER BY uea.completed_at
    LOOP
        -- Map test_type
        test_type_mapped := CASE
            WHEN attempt_record.test_category = 'official_test' THEN 'full_test'
            WHEN attempt_record.test_category = 'mock_test' THEN 'mock_test'
            WHEN attempt_record.test_category = 'sectional_test' THEN 'sectional_test'
            ELSE 'practice'
        END;

        -- Get IELTS variant for reading
        ielts_variant_value := CASE
            WHEN attempt_record.skill_type = 'reading' THEN attempt_record.ielts_test_type
            ELSE NULL
        END;

        -- Generate new result ID
        new_result_id := gen_random_uuid();

        -- Insert to official_test_results via dblink
        BEGIN
            PERFORM dblink_exec('user_db_conn',
                format('
                    INSERT INTO official_test_results (
                        id, user_id, test_type,
                        test_date, test_duration_minutes, completion_status,
                        skill_type, band_score, raw_score, total_questions,
                        source_service, source_table, source_id,
                        ielts_variant, created_at, updated_at
                    ) VALUES (
                        %L, %L, %L,
                        %L, %L, %L,
                        %L, %L, %L, %L,
                        %L, %L, %L,
                        %L, %L, %L
                    )
                    ON CONFLICT (source_service, source_table, source_id) 
                    WHERE source_id IS NOT NULL
                    DO NOTHING
                ',
                    new_result_id,
                    attempt_record.user_id,
                    test_type_mapped,
                    attempt_record.completed_at,
                    COALESCE(attempt_record.time_limit_minutes, 0),
                    'completed',
                    attempt_record.skill_type,
                    attempt_record.band_score,
                    attempt_record.correct_answers,
                    attempt_record.total_questions,
                    'exercise-service',
                    'user_exercise_attempts',
                    attempt_record.id,
                    ielts_variant_value,
                    attempt_record.completed_at,
                    attempt_record.completed_at
                )
            );

            -- Update sync status
            UPDATE user_exercise_attempts
            SET 
                user_service_sync_status = 'synced',
                official_test_result_id = new_result_id,
                user_service_last_sync_attempt = NOW(),
                updated_at = NOW()
            WHERE id = attempt_record.id;

            RAISE NOTICE 'Synced official test % to result %', attempt_record.id, new_result_id;

        EXCEPTION
            WHEN OTHERS THEN
                -- Update sync status to failed
                UPDATE user_exercise_attempts
                SET 
                    user_service_sync_status = 'failed',
                    user_service_sync_attempts = user_service_sync_attempts + 1,
                    user_service_last_sync_attempt = NOW(),
                    user_service_sync_error = SQLERRM,
                    updated_at = NOW()
                WHERE id = attempt_record.id;

                RAISE NOTICE 'Failed to sync official test %: %', attempt_record.id, SQLERRM;
        END;

    END LOOP;
END $$;

-- ============================================
-- UPDATE AGGREGATIONS IN USER_DB
-- ============================================

-- Update skill_statistics based on synced practice_activities
DO $$
BEGIN
    -- Connect to user_db
    PERFORM dblink_connect('user_db_conn', 'dbname=user_db');
    
    PERFORM dblink_exec('user_db_conn', '
        -- Update practice-only statistics
        UPDATE skill_statistics ss
        SET 
            practice_only_count = pa_stats.practice_count,
            practice_average_score = pa_stats.avg_score,
            practice_best_score = pa_stats.best_score,
            last_practice_date = pa_stats.last_practice,
            last_practice_score = pa_stats.last_score,
            updated_at = NOW()
        FROM (
            SELECT 
                user_id,
                skill,
                COUNT(*) as practice_count,
                AVG(score) as avg_score,
                MAX(score) as best_score,
                MAX(completed_at) as last_practice,
                (ARRAY_AGG(score ORDER BY completed_at DESC))[1] as last_score
            FROM practice_activities
            WHERE completion_status = ''completed'' AND score IS NOT NULL
            GROUP BY user_id, skill
        ) pa_stats
        WHERE ss.user_id = pa_stats.user_id 
          AND ss.skill_type = pa_stats.skill
    ');

    -- Update test statistics based on official_test_results
    PERFORM dblink_exec('user_db_conn', '
        UPDATE skill_statistics ss
        SET 
            test_count = otr_stats.test_count,
            test_average_band_score = otr_stats.avg_band,
            test_best_band_score = otr_stats.best_band,
            last_test_date = otr_stats.last_test,
            last_test_band_score = otr_stats.last_band,
            updated_at = NOW()
        FROM (
            SELECT 
                user_id,
                skill_type,
                COUNT(*) as test_count,
                AVG(band_score) as avg_band,
                MAX(band_score) as best_band,
                MAX(test_date) as last_test,
                (ARRAY_AGG(band_score ORDER BY test_date DESC))[1] as last_band
            FROM official_test_results
            WHERE completion_status = ''completed'' AND band_score IS NOT NULL
            GROUP BY user_id, skill_type
        ) otr_stats
        WHERE ss.user_id = otr_stats.user_id 
          AND ss.skill_type = otr_stats.skill_type
    ');

    -- Update learning_progress with test results
    PERFORM dblink_exec('user_db_conn', '
        UPDATE learning_progress lp
        SET 
            last_test_date = test_data.last_test,
            total_tests_taken = test_data.total_tests,
            last_test_overall_score = test_data.last_overall,
            highest_overall_score = test_data.highest_overall,
            updated_at = NOW()
        FROM (
            SELECT 
                user_id,
                MAX(test_date) as last_test,
                COUNT(*) as total_tests,
                (ARRAY_AGG(band_score ORDER BY test_date DESC))[1] as last_overall,
                MAX(band_score) as highest_overall
            FROM official_test_results
            WHERE completion_status = ''completed'' AND band_score IS NOT NULL
            GROUP BY user_id
        ) test_data
        WHERE lp.user_id = test_data.user_id
    ');

    -- Disconnect
    PERFORM dblink_disconnect('user_db_conn');
    
    RAISE NOTICE 'Updated aggregations in user_db';
END $$;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check sync status
SELECT 
    'Exercise Attempts Sync Status' as report,
    user_service_sync_status as status,
    is_official_test,
    COUNT(*) as count
FROM user_exercise_attempts
WHERE status = 'completed'
GROUP BY user_service_sync_status, is_official_test
ORDER BY is_official_test, user_service_sync_status;

-- Check practice_activities count (via dblink)
DO $$
DECLARE
    pa_count INTEGER;
    otr_count INTEGER;
BEGIN
    -- Connect to user_db
    PERFORM dblink_connect('temp_conn', 'dbname=user_db');
    
    -- Get practice_activities count
    SELECT count INTO pa_count
    FROM dblink('temp_conn', 
        'SELECT COUNT(*)::INTEGER FROM practice_activities'
    ) AS t(count INTEGER);
    
    -- Get official_test_results count
    SELECT count INTO otr_count
    FROM dblink('temp_conn',
        'SELECT COUNT(*)::INTEGER FROM official_test_results 
         WHERE source_service = ''exercise-service'''
    ) AS t(count INTEGER);

    -- Disconnect
    PERFORM dblink_disconnect('temp_conn');

    RAISE NOTICE 'Practice Activities synced: %', pa_count;
    RAISE NOTICE 'Official Test Results synced: %', otr_count;
END $$;

-- Check failed syncs
SELECT 
    'Failed Syncs' as report,
    id,
    user_id,
    exercise_id,
    user_service_sync_status,
    user_service_sync_attempts,
    user_service_sync_error
FROM user_exercise_attempts
WHERE user_service_sync_status = 'failed'
ORDER BY user_service_last_sync_attempt DESC
LIMIT 10;

-- ============================================
-- SUMMARY
-- ============================================

SELECT 
    'âœ… Phase Complete: Exercise Attempts Synced to User Service' as status,
    (SELECT COUNT(*) FROM user_exercise_attempts 
     WHERE user_service_sync_status = 'synced') as synced_count,
    (SELECT COUNT(*) FROM user_exercise_attempts 
     WHERE user_service_sync_status = 'failed') as failed_count,
    (SELECT COUNT(*) FROM user_exercise_attempts 
     WHERE user_service_sync_status = 'pending') as pending_count;

-- ============================================
-- NOTES
-- ============================================

/*
IMPORTANT:
1. This script uses dblink to sync data between exercise_db and user_db
2. Ensure dblink extension is installed: CREATE EXTENSION IF NOT EXISTS dblink;
3. Connection string may need adjustment based on your setup
4. For production, implement this as a background job/cron task
5. Add retry logic with exponential backoff for failed syncs
6. Monitor user_service_sync_attempts to identify persistent failures

RETRY FAILED SYNCS:
- Re-run this script to retry failed syncs
- Failed attempts are not retried automatically to avoid infinite loops
- Investigate user_service_sync_error for root causes

PERFORMANCE:
- This script processes attempts sequentially
- For large volumes, implement batch processing
- Consider using LISTEN/NOTIFY for real-time sync
*/

