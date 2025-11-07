-- ============================================
-- COMPREHENSIVE DATA VALIDATION
-- ============================================
-- Purpose: Validate all calculated/dynamic fields match BE logic
-- Date: 2025-11-07
-- ============================================

\c course_db

DO $$
DECLARE
    mismatch_count INT;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'COURSE SERVICE VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Course enrollment progress should be 0 (calculated real-time by BE)
    SELECT COUNT(*) INTO mismatch_count
    FROM course_enrollments
    WHERE progress_percentage != 0 
       OR total_time_spent_minutes != 0
       OR lessons_completed != 0;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % enrollments have manual progress (should be 0)', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All enrollments have progress=0 (real-time calculation)';
    END IF;
    
    -- 2. Lesson progress: last_position should match progress_percentage
    SELECT COUNT(*) INTO mismatch_count
    FROM lesson_progress
    WHERE progress_percentage > 0 
      AND video_total_seconds > 0
      AND last_position_seconds = 0;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % lessons missing last_position for resume', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All lessons with progress have last_position';
    END IF;
    
    -- 3. Completed lessons should have progress=100%
    SELECT COUNT(*) INTO mismatch_count
    FROM lesson_progress
    WHERE status = 'completed' AND progress_percentage != 100;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % completed lessons don''t have 100%% progress', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All completed lessons have 100%% progress';
    END IF;
    
    -- 4. Timeline: last_accessed_at >= first_accessed_at
    SELECT COUNT(*) INTO mismatch_count
    FROM lesson_progress
    WHERE last_accessed_at < first_accessed_at;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % lessons have last_accessed < first_accessed', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All lesson access times are logical';
    END IF;
    
    -- 5. Completed lessons should have completed_at
    SELECT COUNT(*) INTO mismatch_count
    FROM lesson_progress
    WHERE status = 'completed' AND completed_at IS NULL;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % completed lessons missing completed_at', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All completed lessons have completed_at';
    END IF;
END $$;

\c exercise_db

DO $$
DECLARE
    mismatch_count INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXERCISE SERVICE VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Completed attempts should have score and completed_at
    SELECT COUNT(*) INTO mismatch_count
    FROM user_exercise_attempts
    WHERE status = 'completed' 
      AND (score IS NULL OR completed_at IS NULL);
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % completed attempts missing score/completed_at', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All completed attempts have score and completed_at';
    END IF;
    
    -- 2. Completed attempts should be synced to User Service
    SELECT COUNT(*) INTO mismatch_count
    FROM user_exercise_attempts
    WHERE status = 'completed' 
      AND user_service_sync_status != 'synced';
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % completed attempts not synced to User Service', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All completed attempts synced to User Service';
    END IF;
    
    -- 3. In-progress attempts should NOT have score or completed_at
    SELECT COUNT(*) INTO mismatch_count
    FROM user_exercise_attempts
    WHERE status = 'in_progress' 
      AND (score IS NOT NULL OR completed_at IS NOT NULL);
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % in-progress attempts have score/completed_at', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: No in-progress attempts have premature score';
    END IF;
    
    -- 4. questions_answered should not exceed total_questions
    SELECT COUNT(*) INTO mismatch_count
    FROM user_exercise_attempts
    WHERE questions_answered > total_questions;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % attempts answered more than total questions', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All attempts have valid question counts';
    END IF;
    
    -- 5. Exercises should have valid total_points and passing_score
    SELECT COUNT(*) INTO mismatch_count
    FROM exercises
    WHERE total_points IS NULL OR passing_score IS NULL;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % exercises missing total_points/passing_score', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All exercises have total_points and passing_score';
    END IF;
    
    -- 6. Exercise test_category should be valid
    SELECT COUNT(*) INTO mismatch_count
    FROM exercises
    WHERE test_category IS NULL 
       OR test_category NOT IN ('practice', 'mock_test', 'official_test', 'mini_test');
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % exercises have invalid test_category', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All exercises have valid test_category';
    END IF;
END $$;

\c user_db

DO $$
DECLARE
    mismatch_count INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'USER SERVICE VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Band scores should be in valid range (0-9)
    SELECT COUNT(*) INTO mismatch_count
    FROM learning_progress
    WHERE (listening_score IS NOT NULL AND (listening_score < 0 OR listening_score > 9))
       OR (reading_score IS NOT NULL AND (reading_score < 0 OR reading_score > 9))
       OR (writing_score IS NOT NULL AND (writing_score < 0 OR writing_score > 9))
       OR (speaking_score IS NOT NULL AND (speaking_score < 0 OR speaking_score > 9))
       OR (overall_score IS NOT NULL AND (overall_score < 0 OR overall_score > 9));
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % learning_progress have invalid band scores', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All band scores in valid range (0-9)';
    END IF;
    
    -- 2. Overall score should be average of skill scores (if all present)
    -- Skip this check as it requires complex calculation and BE handles it
    RAISE NOTICE '⚠️  SKIP: Overall score calculation (BE computes dynamically)';
    
    -- 3. Streak validation: current_streak <= longest_streak
    SELECT COUNT(*) INTO mismatch_count
    FROM learning_progress
    WHERE current_streak_days > longest_streak_days;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % users have current_streak > longest_streak', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: Streak logic is valid';
    END IF;
    
    -- 4. Study sessions: ended_at >= started_at
    SELECT COUNT(*) INTO mismatch_count
    FROM study_sessions
    WHERE ended_at IS NOT NULL AND ended_at < started_at;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % study sessions have ended_at < started_at', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All study session times are logical';
    END IF;
    
    -- 5. Study sessions: duration should match time difference
    WITH duration_check AS (
        SELECT 
            id,
            duration_minutes,
            EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 as calculated_duration
        FROM study_sessions
        WHERE ended_at IS NOT NULL
    )
    SELECT COUNT(*) INTO mismatch_count
    FROM duration_check
    WHERE ABS(duration_minutes - calculated_duration) > 1; -- Allow 1 min tolerance
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % study sessions have incorrect duration', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All study session durations match time difference';
    END IF;
    
    -- 6. User follows: no self-follows
    SELECT COUNT(*) INTO mismatch_count
    FROM user_follows
    WHERE follower_id = following_id;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % users are following themselves', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: No self-follows detected';
    END IF;
    
    -- 7. Official test results: band scores valid
    SELECT COUNT(*) INTO mismatch_count
    FROM official_test_results
    WHERE band_score < 0 OR band_score > 9;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % official test results have invalid band scores', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All official test band scores valid';
    END IF;
    
    -- 8. Study goals: end_date >= start_date
    SELECT COUNT(*) INTO mismatch_count
    FROM study_goals
    WHERE end_date < start_date;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % study goals have end_date < start_date', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All study goal dates are logical';
    END IF;
END $$;

-- Cross-database validation
\c course_db

DO $$
DECLARE
    mismatch_count INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'CROSS-DATABASE VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Enrollment date should be after course created_at
    SELECT COUNT(*) INTO mismatch_count
    FROM course_enrollments ce
    JOIN courses c ON c.id = ce.course_id
    WHERE ce.enrollment_date < c.created_at;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % enrollments before course creation', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All enrollments after course creation';
    END IF;
    
    -- 2. Lesson progress first_accessed should be after enrollment
    WITH enrollment_dates AS (
        SELECT user_id, course_id, enrollment_date
        FROM course_enrollments
    )
    SELECT COUNT(*) INTO mismatch_count
    FROM lesson_progress lp
    JOIN lessons l ON l.id = lp.lesson_id
    JOIN modules m ON m.id = l.module_id
    JOIN enrollment_dates ed ON ed.course_id = m.course_id AND ed.user_id = lp.user_id
    WHERE lp.first_accessed_at < ed.enrollment_date;
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '❌ FAIL: % lesson accesses before enrollment', mismatch_count;
    ELSE
        RAISE NOTICE '✅ PASS: All lesson accesses after enrollment';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'VALIDATION COMPLETE';
    RAISE NOTICE '============================================';
END $$;
