-- ============================================
-- DATA INTEGRITY & FLOW VALIDATION
-- ============================================
-- Purpose: Check for logical inconsistencies and timeline violations
-- Date: 2025-11-07
-- ============================================

\c course_db

DO $$
DECLARE
    violation_count INT;
    total_issues INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'DATA INTEGRITY VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Enrollments before course creation
    SELECT COUNT(*) INTO violation_count
    FROM course_enrollments ce
    JOIN courses c ON c.id = ce.course_id
    WHERE ce.enrollment_date < c.created_at;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 1: % enrollments created before course existed', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 1: No enrollments before course creation';
    END IF;
    
    -- 2. Lesson progress without enrollment
    SELECT COUNT(*) INTO violation_count
    FROM lesson_progress lp
    JOIN lessons l ON l.id = lp.lesson_id
    JOIN modules m ON m.id = l.module_id
    WHERE NOT EXISTS (
        SELECT 1 FROM course_enrollments ce 
        WHERE ce.user_id = lp.user_id 
        AND ce.course_id = m.course_id
    );
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 2: % lesson progress records without course enrollment', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 2: All lesson progress has corresponding enrollment';
    END IF;
    
    -- 3. Lesson progress before enrollment
    SELECT COUNT(*) INTO violation_count
    FROM lesson_progress lp
    JOIN lessons l ON l.id = lp.lesson_id
    JOIN modules m ON m.id = l.module_id
    JOIN course_enrollments ce ON ce.user_id = lp.user_id AND ce.course_id = m.course_id
    WHERE lp.first_accessed_at < ce.enrollment_date;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 3: % lessons accessed before enrollment', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 3: All lesson access after enrollment';
    END IF;
    
    -- 4. Completed lessons but enrollment shows 0% progress
    SELECT COUNT(*) INTO violation_count
    FROM course_enrollments ce
    WHERE ce.lessons_completed > 0 AND ce.progress_percentage = 0;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 4: % enrollments with completed lessons but 0%% progress', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 4: Progress percentage matches completed lessons';
    END IF;
    
    -- 5. Completed after last accessed (WRONG - should complete THEN access later to review)
    SELECT COUNT(*) INTO violation_count
    FROM course_enrollments ce
    WHERE ce.completed_at IS NOT NULL 
    AND ce.last_accessed_at IS NOT NULL
    AND ce.completed_at > ce.last_accessed_at;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 5: % courses completed after last access (impossible)', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 5: Completion dates are logical';
    END IF;
    
    RAISE NOTICE '============================================';
    IF total_issues = 0 THEN
        RAISE NOTICE '✅ ALL COURSE DATA IS LOGICALLY CONSISTENT';
    ELSE
        RAISE NOTICE '⚠️  TOTAL ISSUES FOUND: %', total_issues;
    END IF;
    RAISE NOTICE '============================================';
END $$;

\c exercise_db

DO $$
DECLARE
    violation_count INT;
    total_issues INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXERCISE DATA VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Exercise attempts for non-existent exercises
    SELECT COUNT(*) INTO violation_count
    FROM user_exercise_attempts uea
    WHERE NOT EXISTS (SELECT 1 FROM exercises e WHERE e.id = uea.exercise_id);
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 1: % attempts for non-existent exercises', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 1: All attempts reference valid exercises';
    END IF;
    
    -- 2. Completed attempts without completion time
    SELECT COUNT(*) INTO violation_count
    FROM user_exercise_attempts uea
    WHERE uea.status = 'completed' AND uea.completed_at IS NULL;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 2: % completed attempts without completion time', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 2: All completed attempts have completion time';
    END IF;
    
    -- 3. Question answers consistency (skip if no attempts tracked)
    SELECT COUNT(*) INTO violation_count
    FROM question_answers qa
    WHERE qa.question_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM questions q 
        WHERE q.id = qa.question_id
    );
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 3: % question answers for non-existent questions', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 3: All answers reference valid questions';
    END IF;
    
    -- 4. Writing/Speaking exercises without required fields
    SELECT COUNT(*) INTO violation_count
    FROM exercises
    WHERE (skill_type = 'writing' AND (writing_task_type IS NULL OR writing_prompt_text IS NULL))
    OR (skill_type = 'speaking' AND (speaking_part_number IS NULL OR speaking_prompt_text IS NULL));
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 4: % writing/speaking exercises missing required fields', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 4: All writing/speaking exercises have required fields';
    END IF;
    
    RAISE NOTICE '============================================';
    IF total_issues = 0 THEN
        RAISE NOTICE '✅ ALL EXERCISE DATA IS LOGICALLY CONSISTENT';
    ELSE
        RAISE NOTICE '⚠️  TOTAL ISSUES FOUND: %', total_issues;
    END IF;
    RAISE NOTICE '============================================';
END $$;

\c user_db

DO $$
DECLARE
    violation_count INT;
    total_issues INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'USER DATA VALIDATION';
    RAISE NOTICE '============================================';
    
    -- 1. Study sessions with end before start
    SELECT COUNT(*) INTO violation_count
    FROM study_sessions
    WHERE ended_at < started_at;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 1: % study sessions end before they start', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 1: All study session timelines are logical';
    END IF;
    
    -- 2. Study sessions duration mismatch
    SELECT COUNT(*) INTO violation_count
    FROM study_sessions
    WHERE duration_minutes IS NOT NULL
    AND ended_at IS NOT NULL
    AND started_at IS NOT NULL
    AND ABS(EXTRACT(EPOCH FROM (ended_at - started_at))/60 - duration_minutes) > 1;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 2: % study sessions with duration mismatch', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 2: Study session durations match timestamps';
    END IF;
    
    -- 3. Study goals with end date before start date
    SELECT COUNT(*) INTO violation_count
    FROM study_goals
    WHERE end_date < start_date;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 3: % study goals end before they start', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 3: All study goal timelines are logical';
    END IF;
    
    -- 4. Following yourself
    SELECT COUNT(*) INTO violation_count
    FROM user_follows
    WHERE follower_id = following_id;
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 4: % users following themselves', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 4: No users following themselves';
    END IF;
    
    -- 5. Learning progress with invalid band scores
    SELECT COUNT(*) INTO violation_count
    FROM learning_progress
    WHERE (listening_score IS NOT NULL AND (listening_score < 0 OR listening_score > 9))
    OR (reading_score IS NOT NULL AND (reading_score < 0 OR reading_score > 9))
    OR (writing_score IS NOT NULL AND (writing_score < 0 OR writing_score > 9))
    OR (speaking_score IS NOT NULL AND (speaking_score < 0 OR speaking_score > 9));
    
    IF violation_count > 0 THEN
        RAISE NOTICE '❌ Issue 5: % learning progress records with invalid band scores', violation_count;
        total_issues := total_issues + violation_count;
    ELSE
        RAISE NOTICE '✅ Issue 5: All band scores are within valid range (0-9)';
    END IF;
    
    RAISE NOTICE '============================================';
    IF total_issues = 0 THEN
        RAISE NOTICE '✅ ALL USER DATA IS LOGICALLY CONSISTENT';
    ELSE
        RAISE NOTICE '⚠️  TOTAL ISSUES FOUND: %', total_issues;
    END IF;
    RAISE NOTICE '============================================';
END $$;
