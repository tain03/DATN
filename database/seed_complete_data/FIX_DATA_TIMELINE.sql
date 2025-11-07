-- ============================================
-- FIX DATA TIMELINE & LOGIC ISSUES
-- ============================================
-- Purpose: Repair timeline violations and ensure logical flow
-- Date: 2025-11-07
-- ============================================

\c course_db

-- ============================================
-- FIX 1: Enrollments before course creation
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Update enrollment_date to be after course creation
    UPDATE course_enrollments ce
    SET enrollment_date = c.created_at + (RANDOM() * INTERVAL '30 days')
    FROM courses c
    WHERE ce.course_id = c.id
    AND ce.enrollment_date < c.created_at;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % enrollments with invalid timestamps', fixed_count;
END $$;

-- ============================================
-- FIX 2: Last accessed should be >= completed_at
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Update last_accessed_at to be same as or after completed_at
    UPDATE course_enrollments
    SET last_accessed_at = completed_at + (RANDOM() * INTERVAL '7 days')
    WHERE completed_at IS NOT NULL
    AND last_accessed_at IS NOT NULL
    AND last_accessed_at < completed_at;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % enrollments where completion > last access', fixed_count;
END $$;

-- ============================================
-- FIX 3: Lesson progress timestamps must be after enrollment
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Update first_accessed_at to be after enrollment using CTE
    WITH lesson_fixes AS (
        SELECT 
            lp.id as lp_id,
            ce.enrollment_date
        FROM lesson_progress lp
        JOIN lessons l ON l.id = lp.lesson_id
        JOIN modules m ON m.id = l.module_id
        JOIN course_enrollments ce ON ce.course_id = m.course_id AND ce.user_id = lp.user_id
        WHERE lp.first_accessed_at < ce.enrollment_date
    )
    UPDATE lesson_progress lp
    SET first_accessed_at = lf.enrollment_date + (RANDOM() * INTERVAL '5 days'),
        last_accessed_at = lf.enrollment_date + (RANDOM() * INTERVAL '10 days')
    FROM lesson_fixes lf
    WHERE lp.id = lf.lp_id;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % lesson progress records with invalid timestamps', fixed_count;
END $$;

-- ============================================
-- FIX 4: Completed lessons should have completed_at timestamp
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    UPDATE lesson_progress
    SET completed_at = last_accessed_at + (RANDOM() * INTERVAL '30 minutes')
    WHERE status = 'completed'
    AND completed_at IS NULL
    AND last_accessed_at IS NOT NULL;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % completed lessons without completion timestamp', fixed_count;
END $$;

-- ============================================
-- FIX 5: Ensure lesson progress follows logical order
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Completed lessons should have 100% progress and full watch time
    UPDATE lesson_progress lp
    SET 
        progress_percentage = 100,
        video_watched_seconds = COALESCE(lv.duration_seconds, 600)
    FROM lessons l
    LEFT JOIN lesson_videos lv ON lv.lesson_id = l.id
    WHERE lp.lesson_id = l.id
    AND lp.status = 'completed'
    AND (lp.progress_percentage < 100 OR lp.video_watched_seconds = 0);
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % completed lessons with incomplete progress', fixed_count;
END $$;

\c exercise_db

-- ============================================
-- FIX 6: Exercise attempts timeline
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Ensure started_at < completed_at for completed attempts
    UPDATE user_exercise_attempts
    SET completed_at = started_at + (time_spent_seconds || ' seconds')::INTERVAL
    WHERE status = 'completed'
    AND completed_at IS NOT NULL
    AND completed_at < started_at;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % exercise attempts with invalid completion times', fixed_count;
END $$;

-- ============================================
-- FIX 7: Update exercise analytics with accurate data
-- ============================================
DO $$
DECLARE
    exercise_rec RECORD;
    updated_count INT := 0;
BEGIN
    FOR exercise_rec IN 
        SELECT 
            e.id,
            COUNT(uea.id) as total_attempts,
            COUNT(CASE WHEN uea.status = 'completed' THEN 1 END) as completed_attempts,
            ROUND(AVG(CASE WHEN uea.status = 'completed' THEN uea.score END), 2) as avg_score,
            ROUND(AVG(CASE WHEN uea.status = 'completed' THEN (uea.time_spent_seconds / 60.0) END), 1) as avg_time,
            COUNT(DISTINCT uea.user_id) as unique_users
        FROM exercises e
        LEFT JOIN user_exercise_attempts uea ON uea.exercise_id = e.id
        GROUP BY e.id
        HAVING COUNT(uea.id) > 0
    LOOP
        UPDATE exercise_analytics
        SET 
            total_attempts = exercise_rec.total_attempts,
            completed_attempts = exercise_rec.completed_attempts,
            average_score = exercise_rec.avg_score,
            average_completion_time = exercise_rec.avg_time,
            pass_rate = ROUND((exercise_rec.completed_attempts::NUMERIC / NULLIF(exercise_rec.total_attempts, 0)) * 100, 1),
            updated_at = NOW()
        WHERE exercise_id = exercise_rec.id;
        
        updated_count := updated_count + 1;
    END LOOP;
    
    RAISE NOTICE '✅ Updated analytics for % exercises', updated_count;
END $$;

\c user_db

-- ============================================
-- FIX 8: Study sessions must have logical timestamps
-- ============================================
DO $$
DECLARE
    fixed_count INT := 0;
BEGIN
    -- Ensure ended_at = started_at + duration
    UPDATE study_sessions
    SET ended_at = started_at + (duration_minutes || ' minutes')::INTERVAL
    WHERE ended_at IS NOT NULL
    AND started_at IS NOT NULL
    AND duration_minutes IS NOT NULL
    AND ABS(EXTRACT(EPOCH FROM (ended_at - started_at))/60 - duration_minutes) > 1;
    
    GET DIAGNOSTICS fixed_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % study sessions with duration mismatch', fixed_count;
END $$;

-- ============================================
-- VALIDATION SUMMARY
-- ============================================
\c course_db

DO $$
DECLARE
    issue1 INT;
    issue2 INT;
BEGIN
    SELECT COUNT(*) INTO issue1
    FROM course_enrollments ce
    JOIN courses c ON c.id = ce.course_id
    WHERE ce.enrollment_date < c.created_at;
    
    SELECT COUNT(*) INTO issue2
    FROM course_enrollments ce
    WHERE ce.completed_at IS NOT NULL 
    AND ce.last_accessed_at IS NOT NULL
    AND ce.completed_at > ce.last_accessed_at;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'POST-FIX VALIDATION';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Enrollments before course: %', issue1;
    RAISE NOTICE 'Completed before last access: %', issue2;
    
    IF issue1 = 0 AND issue2 = 0 THEN
        RAISE NOTICE '✅ ALL TIMELINE ISSUES RESOLVED';
    ELSE
        RAISE NOTICE '⚠️  Some issues remain';
    END IF;
    RAISE NOTICE '============================================';
END $$;
