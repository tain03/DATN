-- ============================================================================
-- PHASE 18: PRACTICE ACTIVITIES - Comprehensive Practice Tracking
-- ============================================================================
-- Purpose: Populate practice_activities table with realistic user practice history
-- Logic: 
--   1. Convert ALL completed user_exercise_attempts â†’ practice_activities
--   2. Add additional drill/section_practice activities (khÃ´ng pháº£i full test)
--   3. Ensure timeline logic: practice times within user's study period
--   4. Activity types: 'drill', 'part_test', 'section_practice', 'question_set'
--   5. Skills: listening, reading, writing, speaking
-- ============================================================================

\c user_db

-- ============================================================================
-- PART 0: Create temporary table and import exercise data
-- ============================================================================

CREATE TEMP TABLE temp_exercise_attempts (
    id uuid,
    user_id uuid,
    exercise_id uuid,
    score numeric,
    correct_answers integer,
    total_questions integer,
    time_spent_seconds integer,
    started_at timestamp,
    completed_at timestamp,
    created_at timestamp,
    updated_at timestamp,
    title varchar,
    skill_type varchar,
    test_category varchar,
    difficulty varchar,
    total_points numeric,
    passing_score numeric
);

-- Import from CSV
COPY temp_exercise_attempts FROM '/tmp/exercise_attempts.csv' WITH CSV HEADER;

-- Show temp table count
SELECT 'âœ… Loaded exercise attempts: ' || COUNT(*)::text as step FROM temp_exercise_attempts;

-- ============================================================================
-- PART 1: Insert from Completed Exercise Attempts (Full Tests/Exercises)
-- ============================================================================
-- Map user_exercise_attempts â†’ practice_activities
-- activity_type = 'part_test' for full exercises

INSERT INTO practice_activities (
    user_id,
    skill,
    activity_type,
    exercise_id,
    exercise_title,
    score,
    max_score,
    band_score,
    correct_answers,
    total_questions,
    accuracy_percentage,
    time_spent_seconds,
    started_at,
    completed_at,
    completion_status,
    ai_evaluated,
    ai_feedback_summary,
    difficulty_level,
    tags,
    notes,
    created_at,
    updated_at
)
SELECT 
    uea.user_id,
    uea.skill_type as skill,
    -- Activity type based on test_category
    CASE 
        WHEN uea.test_category = 'official_test' THEN 'part_test'
        WHEN uea.test_category = 'mock_test' THEN 'part_test'
        WHEN uea.test_category = 'practice' THEN 'question_set'
        ELSE 'question_set'
    END as activity_type,
    uea.exercise_id,
    uea.title as exercise_title,
    uea.score,
    CASE 
        -- Writing/Speaking use band scores
        WHEN uea.skill_type IN ('writing', 'speaking') THEN 9.0
        ELSE uea.total_points
    END as max_score,
    CASE 
        -- Writing/Speaking: score IS band_score
        WHEN uea.skill_type IN ('writing', 'speaking') THEN uea.score
        -- Listening/Reading: convert score to band (approximation)
        WHEN uea.skill_type IN ('listening', 'reading') THEN 
            CASE 
                WHEN uea.score >= uea.total_points * 0.9 THEN 9.0
                WHEN uea.score >= uea.total_points * 0.8 THEN 8.0
                WHEN uea.score >= uea.total_points * 0.7 THEN 7.0
                WHEN uea.score >= uea.total_points * 0.6 THEN 6.0
                WHEN uea.score >= uea.total_points * 0.5 THEN 5.5
                ELSE 5.0
            END
        ELSE NULL
    END as band_score,
    uea.correct_answers,
    uea.total_questions,
    ROUND((uea.correct_answers::numeric / NULLIF(uea.total_questions, 0)) * 100, 2) as accuracy_percentage,
    uea.time_spent_seconds,
    uea.started_at,
    uea.completed_at,
    'completed' as completion_status,
    -- Writing/Speaking are AI evaluated
    CASE 
        WHEN uea.skill_type IN ('writing', 'speaking') THEN true
        ELSE false
    END as ai_evaluated,
    CASE 
        WHEN uea.skill_type IN ('writing', 'speaking') THEN 
            'AI evaluation completed. Overall performance: ' || 
            CASE 
                WHEN uea.score >= 7.0 THEN 'Excellent'
                WHEN uea.score >= 6.0 THEN 'Good'
                WHEN uea.score >= 5.0 THEN 'Satisfactory'
                ELSE 'Needs improvement'
            END
        ELSE NULL
    END as ai_feedback_summary,
    CASE 
        WHEN uea.difficulty = 'easy' THEN 'beginner'
        WHEN uea.difficulty = 'medium' THEN 'intermediate'
        WHEN uea.difficulty = 'hard' THEN 'advanced'
        ELSE 'intermediate'
    END as difficulty_level,
    ARRAY[uea.skill_type, uea.test_category, uea.difficulty]::text[] as tags,
    CASE 
        WHEN uea.score >= uea.passing_score THEN 'Passed - Good job!'
        ELSE 'Keep practicing to improve'
    END as notes,
    uea.created_at,
    uea.updated_at
FROM temp_exercise_attempts uea
WHERE uea.completed_at IS NOT NULL;

-- Show insert count
SELECT 
    'âœ… Inserted from user_exercise_attempts' as step,
    COUNT(*) as count 
FROM practice_activities;

-- ============================================================================
-- PART 2: Add Additional Drill Activities (Targeted Practice)
-- ============================================================================
-- Users practice specific skills without full tests
-- Generate drill activities based on user's weak areas

WITH user_skill_stats AS (
    -- Find users' weak skills from their test results
    SELECT 
        up.user_id,
        (ROW_NUMBER() OVER (PARTITION BY up.user_id ORDER BY ss.test_average_band_score ASC)) as skill_num,
        ss.test_average_band_score as average_band_score
    FROM user_profiles up
    JOIN skill_statistics ss ON ss.user_id = up.user_id
    WHERE ss.test_average_band_score < 7.0
),
drill_sessions AS (
    -- Generate 2-4 drill sessions for each user's weakest skill
    SELECT 
        uss.user_id,
        uss.skill_num,
        uss.average_band_score,
        generate_series(1, 2 + (RANDOM() * 2)::integer) as drill_number,
        (
            SELECT MIN(created_at) + 
                   (RANDOM() * EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MIN(created_at))))::integer * interval '1 second'
            FROM study_sessions 
            WHERE user_id = uss.user_id
        ) as drill_start_time,
        (300 + (RANDOM() * 900)::integer) as drill_duration,
        (5 + (RANDOM() * 5)::integer) as drill_correct_answers  -- Pre-calculate for accuracy
    FROM user_skill_stats uss
    WHERE uss.skill_num = 1  -- Focus on weakest skill
)
INSERT INTO practice_activities (
    user_id,
    skill,
    activity_type,
    exercise_id,
    exercise_title,
    score,
    max_score,
    band_score,
    correct_answers,
    total_questions,
    accuracy_percentage,
    time_spent_seconds,
    started_at,
    completed_at,
    completion_status,
    ai_evaluated,
    difficulty_level,
    tags,
    notes,
    created_at,
    updated_at
)
SELECT 
    ds.user_id,
    CASE ds.skill_num
        WHEN 1 THEN 'listening'
        WHEN 2 THEN 'reading'
        WHEN 3 THEN 'writing'
        ELSE 'speaking'
    END as skill,
    CASE 
        WHEN RANDOM() < 0.6 THEN 'drill'
        WHEN RANDOM() < 0.8 THEN 'section_practice'
        ELSE 'question_set'
    END as activity_type,
    NULL as exercise_id,  -- Drill activities don't link to full exercises
    'Skill Drill: ' || 
    CASE ds.skill_num
        WHEN 1 THEN 
            CASE (RANDOM() * 4)::integer
                WHEN 0 THEN 'Note Completion Practice'
                WHEN 1 THEN 'Multiple Choice Drills'
                WHEN 2 THEN 'Sentence Completion'
                ELSE 'Matching Practice'
            END
        WHEN 2 THEN 
            CASE (RANDOM() * 4)::integer
                WHEN 0 THEN 'True/False/Not Given Drills'
                WHEN 1 THEN 'Heading Matching Practice'
                WHEN 2 THEN 'Summary Completion'
                ELSE 'Short Answer Questions'
            END
        WHEN 3 THEN 
            CASE (RANDOM() * 3)::integer
                WHEN 0 THEN 'Task 1 Structure Practice'
                WHEN 1 THEN 'Task 2 Idea Development'
                ELSE 'Vocabulary Enhancement'
            END
        ELSE 
            CASE (RANDOM() * 3)::integer
                WHEN 0 THEN 'Part 1 Fluency Practice'
                WHEN 1 THEN 'Part 2 Topic Card Drills'
                ELSE 'Part 3 Discussion Practice'
            END
    END as exercise_title,
    -- Random score between 60-100% of max
    ROUND(5 + (RANDOM() * 4)::numeric, 2) as score,
    10.0 as max_score,
    -- Band score improves over time (learning effect)
    ROUND(
        GREATEST(
            4.0,
            LEAST(
                8.5,
                ds.average_band_score + (ds.drill_number * 0.3) + (RANDOM() * 0.8)
            )
        )::numeric,
        1
    ) as band_score,
    ds.drill_correct_answers as correct_answers,
    10 as total_questions,
    -- Calculate accuracy_percentage from correct_answers/total_questions
    ROUND((ds.drill_correct_answers::numeric / 10) * 100, 2) as accuracy_percentage,
    ds.drill_duration as time_spent_seconds,
    ds.drill_start_time as started_at,
    ds.drill_start_time + (ds.drill_duration || ' seconds')::interval as completed_at,
    'completed' as completion_status,
    CASE ds.skill_num
        WHEN 3 THEN true  -- writing
        WHEN 4 THEN true  -- speaking
        ELSE false
    END as ai_evaluated,
    CASE 
        WHEN ds.drill_number <= 1 THEN 'beginner'
        WHEN ds.drill_number <= 2 THEN 'intermediate'
        ELSE 'advanced'
    END as difficulty_level,
    ARRAY[
        CASE ds.skill_num WHEN 1 THEN 'listening' WHEN 2 THEN 'reading' WHEN 3 THEN 'writing' ELSE 'speaking' END,
        'drill', 
        'skill_improvement'
    ]::text[] as tags,
    'Targeted practice to improve ' || 
    CASE ds.skill_num WHEN 1 THEN 'listening' WHEN 2 THEN 'reading' WHEN 3 THEN 'writing' ELSE 'speaking' END ||
    ' skills' as notes,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at
FROM drill_sessions ds
WHERE EXISTS (SELECT 1 FROM study_sessions WHERE user_id = ds.user_id);

-- Show new count
SELECT 
    'âœ… Added drill activities' as step,
    COUNT(*) FILTER (WHERE activity_type = 'drill') as drills,
    COUNT(*) FILTER (WHERE activity_type = 'section_practice') as section_practice,
    COUNT(*) FILTER (WHERE activity_type = 'question_set') as question_sets,
    COUNT(*) FILTER (WHERE activity_type = 'part_test') as part_tests
FROM practice_activities;

-- ============================================================================
-- PART 3: Add Section Practice Activities (Mixed Skills)
-- ============================================================================
-- Users practice specific sections of tests (e.g., Reading Part 2, Listening Part 1)

WITH active_users AS (
    SELECT DISTINCT user_id 
    FROM study_sessions 
    WHERE duration_minutes > 15
    LIMIT 30  -- Active users who do section practice
),
section_sessions AS (
    SELECT 
        au.user_id,
        (ARRAY['listening', 'reading'])[1 + (RANDOM() * 1)::integer] as skill,
        generate_series(1, 1 + (RANDOM() * 2)::integer) as session_number,
        (
            SELECT MIN(created_at) + 
                   (RANDOM() * EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MIN(created_at))))::integer * interval '1 second'
            FROM study_sessions 
            WHERE user_id = au.user_id
        ) as section_start_time,
        (600 + (RANDOM() * 1200)::integer) as section_duration,
        (6 + (RANDOM() * 6)::integer) as section_correct_answers  -- Pre-calculate for accuracy
    FROM active_users au
)
INSERT INTO practice_activities (
    user_id,
    skill,
    activity_type,
    exercise_id,
    exercise_title,
    score,
    max_score,
    band_score,
    correct_answers,
    total_questions,
    accuracy_percentage,
    time_spent_seconds,
    started_at,
    completed_at,
    completion_status,
    difficulty_level,
    tags,
    notes,
    created_at,
    updated_at
)
SELECT 
    ss.user_id,
    ss.skill,
    'section_practice' as activity_type,
    NULL as exercise_id,
    ss.skill || ' Section ' || (1 + (RANDOM() * 3)::integer) || ' Practice' as exercise_title,
    ROUND((6 + RANDOM() * 6)::numeric, 2) as score,
    12.0 as max_score,
    ROUND((5.0 + RANDOM() * 3.5)::numeric, 1) as band_score,
    ss.section_correct_answers as correct_answers,
    12 as total_questions,
    ROUND((ss.section_correct_answers::numeric / 12) * 100, 2) as accuracy_percentage,
    ss.section_duration as time_spent_seconds,
    ss.section_start_time as started_at,
    ss.section_start_time + (ss.section_duration || ' seconds')::interval as completed_at,
    'completed' as completion_status,
    CASE 
        WHEN RANDOM() < 0.3 THEN 'beginner'
        WHEN RANDOM() < 0.7 THEN 'intermediate'
        ELSE 'advanced'
    END as difficulty_level,
    ARRAY[ss.skill, 'section_practice', 'timed']::text[] as tags,
    'Section-focused practice for exam preparation' as notes,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at
FROM section_sessions ss;

-- ============================================================================
-- VALIDATION & SUMMARY
-- ============================================================================

-- Check 1: All practice_activities have valid timeline
SELECT 
    'âœ… Timeline Check' as validation,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE completed_at >= started_at) as valid_timeline,
    COUNT(*) FILTER (WHERE completed_at < started_at) as invalid_timeline
FROM practice_activities;

-- Check 2: All have valid band scores
SELECT 
    'âœ… Band Score Check' as validation,
    COUNT(*) FILTER (WHERE band_score IS NOT NULL) as has_band_score,
    COUNT(*) FILTER (WHERE band_score < 0 OR band_score > 9) as invalid_band_score,
    ROUND(AVG(band_score), 2) as avg_band_score,
    ROUND(MIN(band_score), 2) as min_band_score,
    ROUND(MAX(band_score), 2) as max_band_score
FROM practice_activities;

-- Check 3: Activity type distribution
SELECT 
    'âœ… Activity Distribution' as validation,
    activity_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM practice_activities
GROUP BY activity_type
ORDER BY count DESC;

-- Check 4: Skill distribution
SELECT 
    'âœ… Skill Distribution' as validation,
    skill,
    COUNT(*) as count,
    ROUND(AVG(band_score), 2) as avg_band_score,
    ROUND(AVG(accuracy_percentage), 2) as avg_accuracy
FROM practice_activities
GROUP BY skill
ORDER BY count DESC;

-- Check 5: User practice summary
SELECT 
    'âœ… User Summary' as validation,
    COUNT(DISTINCT user_id) as total_users,
    ROUND(AVG(activities_per_user), 2) as avg_activities_per_user,
    MAX(activities_per_user) as max_activities_per_user,
    MIN(activities_per_user) as min_activities_per_user
FROM (
    SELECT 
        user_id,
        COUNT(*) as activities_per_user
    FROM practice_activities
    GROUP BY user_id
) sub;

-- Check 6: AI evaluation coverage
SELECT 
    'âœ… AI Evaluation' as validation,
    skill,
    COUNT(*) FILTER (WHERE ai_evaluated = true) as ai_evaluated,
    COUNT(*) FILTER (WHERE ai_evaluated = false) as not_evaluated,
    COUNT(*) FILTER (WHERE ai_evaluated = true AND ai_feedback_summary IS NOT NULL) as has_feedback
FROM practice_activities
GROUP BY skill
ORDER BY skill;

-- Final summary
SELECT 
    '===========================================' as separator
UNION ALL
SELECT 
    'âœ… PRACTICE ACTIVITIES SEEDED SUCCESSFULLY'
UNION ALL
SELECT 
    '===========================================' 
UNION ALL
SELECT 
    'Total Activities: ' || COUNT(*)::text
FROM practice_activities
UNION ALL
SELECT 
    'Activity Types: ' || COUNT(DISTINCT activity_type)::text
FROM practice_activities
UNION ALL
SELECT 
    'Skills Covered: ' || COUNT(DISTINCT skill)::text
FROM practice_activities
UNION ALL
SELECT 
    'Users with Activities: ' || COUNT(DISTINCT user_id)::text
FROM practice_activities
UNION ALL
SELECT 
    'AI Evaluated: ' || COUNT(*) FILTER (WHERE ai_evaluated = true)::text
FROM practice_activities
UNION ALL
SELECT 
    'Average Band Score: ' || ROUND(AVG(band_score), 2)::text
FROM practice_activities
UNION ALL
SELECT 
    'Date Range: ' || MIN(started_at)::date::text || ' to ' || MAX(completed_at)::date::text
FROM practice_activities
UNION ALL
SELECT 
    '===========================================';
