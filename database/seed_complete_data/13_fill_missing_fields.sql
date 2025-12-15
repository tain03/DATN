-- ============================================
-- FILL MISSING FIELDS WITH REALISTIC DATA
-- ============================================
-- Purpose: Add data to empty/sparse fields
-- Date: 2025-11-07
-- ============================================

\c user_db

-- ============================================
-- LEARNING_PROGRESS: Add last_test_id
-- ============================================
DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    -- Link to actual test attempts from exercise_db
    WITH test_attempts AS (
        SELECT DISTINCT ON (uea.user_id)
            uea.user_id,
            uea.id as attempt_id,
            uea.score,
            uea.completed_at
        FROM dblink(
            'dbname=exercise_db user=ielts_admin',
            'SELECT user_id, id, score, completed_at FROM user_exercise_attempts WHERE status = ''completed'' AND is_official_test = true ORDER BY completed_at DESC'
        ) AS uea(user_id UUID, id UUID, score NUMERIC, completed_at TIMESTAMP)
        ORDER BY uea.user_id, uea.completed_at DESC
    )
    UPDATE learning_progress lp
    SET 
        last_test_id = ta.attempt_id,
        last_test_date = ta.completed_at,
        last_test_overall_score = ta.score,
        highest_overall_score = GREATEST(COALESCE(lp.highest_overall_score, 0), ta.score)
    FROM test_attempts ta
    WHERE lp.user_id = ta.user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % learning_progress records with test data', updated_count;
END $$;

\c exercise_db

-- ============================================
-- EXERCISES: Fill missing metadata fields
-- ============================================
DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    -- Add total_points based on questions
    WITH points_calc AS (
        SELECT 
            e.id,
            COALESCE(SUM(q.points), 0) as calc_points
        FROM exercises e
        LEFT JOIN questions q ON q.exercise_id = e.id
        GROUP BY e.id
    )
    UPDATE exercises e
    SET total_points = pc.calc_points
    FROM points_calc pc
    WHERE e.id = pc.id
    AND e.total_points IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % exercises with total_points', updated_count;
    
    -- Add passing_score (70% of total_points)
    UPDATE exercises
    SET passing_score = ROUND(total_points * 0.7)
    WHERE passing_score IS NULL
    AND total_points IS NOT NULL
    AND total_points > 0;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % exercises with passing_score', updated_count;
    
    -- Add average_completion_time from actual attempts
    WITH time_calc AS (
        SELECT 
            e.id,
            ROUND(AVG(uea.time_spent_seconds / 60.0))::INT as avg_time
        FROM exercises e
        LEFT JOIN user_exercise_attempts uea ON uea.exercise_id = e.id 
            AND uea.status = 'completed' 
            AND uea.time_spent_seconds > 0
        GROUP BY e.id
        HAVING COUNT(uea.id) > 0
    )
    UPDATE exercises e
    SET average_completion_time = tc.avg_time
    FROM time_calc tc
    WHERE e.id = tc.id
    AND e.average_completion_time IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % exercises with average_completion_time', updated_count;
    
    -- Add passage_count for reading exercises
    WITH passage_calc AS (
        SELECT 
            e.id,
            COUNT(*) as passage_cnt
        FROM exercises e
        LEFT JOIN exercise_sections es ON es.exercise_id = e.id 
            AND es.passage_content IS NOT NULL 
            AND LENGTH(es.passage_content) > 0
        WHERE e.skill_type = 'reading'
        GROUP BY e.id
        HAVING COUNT(*) > 0
    )
    UPDATE exercises e
    SET passage_count = pc.passage_cnt
    FROM passage_calc pc
    WHERE e.id = pc.id
    AND e.passage_count IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % reading exercises with passage_count', updated_count;
    
    -- Add test_category for exercises
    UPDATE exercises
    SET test_category = CASE 
        WHEN difficulty = 'hard' THEN 'official_test'
        WHEN difficulty = 'medium' THEN 'mock_test'
        WHEN difficulty = 'easy' THEN 'practice'
        ELSE 'practice'
    END
    WHERE test_category IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % exercises with test_category', updated_count;
END $$;

-- ============================================
-- EXERCISES: Enhance Writing exercises
-- ============================================
DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    -- Add visual data for Task 1 writing
    UPDATE exercises
    SET 
        writing_visual_type = 'chart',
        writing_visual_url = 'https://example.com/ielts-charts/' || id::text || '.png'
    WHERE skill_type = 'writing'
    AND writing_task_type = 'task1'
    AND writing_visual_type IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % writing task1 exercises with visual data', updated_count;
END $$;

-- ============================================
-- EXERCISES: Enhance Speaking exercises
-- ============================================
DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    -- Add cue card data for Part 2 speaking
    UPDATE exercises
    SET 
        speaking_cue_card_topic = 'Describe a memorable experience from your life',
        speaking_cue_card_points = ARRAY[
            'What the experience was',
            'When and where it happened',
            'Who was involved',
            'Why it was memorable'
        ]
    WHERE skill_type = 'speaking'
    AND speaking_part_number = 2
    AND speaking_cue_card_topic IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % speaking part2 exercises with cue card', updated_count;
    
    -- Add follow-up questions for Part 3
    UPDATE exercises
    SET speaking_follow_up_questions = ARRAY[
        'How do you think this topic will change in the future?',
        'What are the advantages and disadvantages of this?',
        'How does this differ between your country and other countries?'
    ]
    WHERE skill_type = 'speaking'
    AND speaking_part_number = 3
    AND speaking_follow_up_questions IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'âœ… Updated % speaking part3 exercises with follow-up questions', updated_count;
END $$;

-- ============================================
-- SUMMARY
-- ============================================
\c exercise_db

DO $$
DECLARE
    missing_count INT;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'VALIDATION: Check remaining NULL fields';
    RAISE NOTICE '============================================';
    
    SELECT COUNT(*) INTO missing_count FROM exercises WHERE total_points IS NULL;
    RAISE NOTICE 'Exercises missing total_points: %', missing_count;
    
    SELECT COUNT(*) INTO missing_count FROM exercises WHERE passing_score IS NULL;
    RAISE NOTICE 'Exercises missing passing_score: %', missing_count;
    
    SELECT COUNT(*) INTO missing_count FROM exercises 
    WHERE skill_type = 'writing' AND writing_task_type IS NULL;
    RAISE NOTICE 'Writing exercises missing task_type: %', missing_count;
    
    SELECT COUNT(*) INTO missing_count FROM exercises 
    WHERE skill_type = 'speaking' AND speaking_prompt_text IS NULL;
    RAISE NOTICE 'Speaking exercises missing prompt: %', missing_count;
    
    RAISE NOTICE '============================================';
END $$;
