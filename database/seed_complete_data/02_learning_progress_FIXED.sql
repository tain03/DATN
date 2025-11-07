-- ============================================
-- FIXED LEARNING_PROGRESS WITH VALID BAND SCORES
-- ============================================
-- Purpose: Fix learning_progress records to ensure all band scores are within valid range
-- Database: user_db
-- Date: 2025-11-07
-- 
-- FIXES:
-- 1. All band scores must be NUMERIC(3,1) between 0.0 and 9.0
-- 2. NULL values are allowed
-- 3. Ensure realistic score progression
-- ============================================

-- ============================================
-- FIX EXISTING INVALID SCORES
-- ============================================
UPDATE learning_progress
SET
    listening_score = CASE 
        WHEN listening_score < 0 THEN 0.0
        WHEN listening_score > 9 THEN 9.0
        ELSE ROUND(listening_score::numeric, 1)
    END,
    reading_score = CASE 
        WHEN reading_score < 0 THEN 0.0
        WHEN reading_score > 9 THEN 9.0
        ELSE ROUND(reading_score::numeric, 1)
    END,
    writing_score = CASE 
        WHEN writing_score < 0 THEN 0.0
        WHEN writing_score > 9 THEN 9.0
        ELSE ROUND(writing_score::numeric, 1)
    END,
    speaking_score = CASE 
        WHEN speaking_score < 0 THEN 0.0
        WHEN speaking_score > 9 THEN 9.0
        ELSE ROUND(speaking_score::numeric, 1)
    END,
    overall_score = CASE 
        WHEN overall_score < 0 THEN 0.0
        WHEN overall_score > 9 THEN 9.0
        ELSE ROUND(overall_score::numeric, 1)
    END,
    last_test_overall_score = CASE 
        WHEN last_test_overall_score < 0 THEN 0.0
        WHEN last_test_overall_score > 9 THEN 9.0
        ELSE ROUND(last_test_overall_score::numeric, 1)
    END,
    highest_overall_score = CASE 
        WHEN highest_overall_score < 0 THEN 0.0
        WHEN highest_overall_score > 9 THEN 9.0
        ELSE ROUND(highest_overall_score::numeric, 1)
    END
WHERE listening_score NOT BETWEEN 0 AND 9
   OR reading_score NOT BETWEEN 0 AND 9
   OR writing_score NOT BETWEEN 0 AND 9
   OR speaking_score NOT BETWEEN 0 AND 9
   OR overall_score NOT BETWEEN 0 AND 9
   OR last_test_overall_score NOT BETWEEN 0 AND 9
   OR highest_overall_score NOT BETWEEN 0 AND 9;

-- ============================================
-- ENSURE OVERALL SCORE MATCHES AVERAGE
-- ============================================
-- Overall score should be the average of the 4 skills (if all exist)
UPDATE learning_progress
SET overall_score = ROUND(
    (COALESCE(listening_score, 0) + 
     COALESCE(reading_score, 0) + 
     COALESCE(writing_score, 0) + 
     COALESCE(speaking_score, 0)) / 4.0, 
    1
)
WHERE listening_score IS NOT NULL 
  AND reading_score IS NOT NULL 
  AND writing_score IS NOT NULL 
  AND speaking_score IS NOT NULL
  AND (overall_score IS NULL OR 
       ABS(overall_score - (listening_score + reading_score + writing_score + speaking_score) / 4.0) > 0.2);

-- ============================================
-- CREATE MISSING LEARNING_PROGRESS RECORDS
-- ============================================
-- Ensure every user has a learning_progress record
INSERT INTO learning_progress (
    user_id,
    total_lessons_completed,
    total_exercises_completed,
    listening_progress, reading_progress, writing_progress, speaking_progress,
    listening_score, reading_score, writing_score, speaking_score, overall_score,
    current_streak_days, longest_streak_days, last_study_date,
    total_tests_taken, last_test_overall_score, highest_overall_score, tests_this_month
)
SELECT 
    up.user_id,
    0, -- total_lessons_completed
    0, -- total_exercises_completed
    0.0, 0.0, 0.0, 0.0, -- progress percentages
    NULL, NULL, NULL, NULL, NULL, -- band scores (NULL for new users)
    0, 0, NULL, -- streaks
    0, NULL, NULL, 0 -- test stats
FROM user_profiles up
WHERE NOT EXISTS (
    SELECT 1 FROM learning_progress lp WHERE lp.user_id = up.user_id
)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- ADD REALISTIC PROGRESS FOR ACTIVE STUDENTS
-- ============================================
-- Give first 20 students realistic learning progress
WITH active_students AS (
    SELECT user_id, 
           ROW_NUMBER() OVER (ORDER BY created_at) as student_num
    FROM user_profiles
    WHERE user_id::text LIKE 'f%' -- Students (cast UUID to text for LIKE)
    LIMIT 20
)
UPDATE learning_progress lp
SET
    total_lessons_completed = 10 + (RANDOM() * 30)::int,
    total_exercises_completed = 5 + (RANDOM() * 25)::int,
    
    -- Progress percentages (0-100)
    listening_progress = ROUND((RANDOM() * 60 + 20)::numeric, 2),
    reading_progress = ROUND((RANDOM() * 60 + 20)::numeric, 2),
    writing_progress = ROUND((RANDOM() * 50 + 15)::numeric, 2),
    speaking_progress = ROUND((RANDOM() * 50 + 15)::numeric, 2),
    
    -- Band scores (5.0 to 7.5 for active students)
    listening_score = ROUND((RANDOM() * 2.5 + 5.0)::numeric, 1),
    reading_score = ROUND((RANDOM() * 2.5 + 5.0)::numeric, 1),
    writing_score = ROUND((RANDOM() * 2.0 + 5.0)::numeric, 1),
    speaking_score = ROUND((RANDOM() * 2.0 + 5.0)::numeric, 1),
    
    -- Streaks
    current_streak_days = (RANDOM() * 15)::int,
    longest_streak_days = 5 + (RANDOM() * 25)::int,
    last_study_date = CURRENT_DATE - (RANDOM() * 7)::int,
    
    -- Test statistics
    total_tests_taken = 1 + (RANDOM() * 5)::int,
    tests_this_month = (RANDOM() * 3)::int
FROM active_students
WHERE lp.user_id = active_students.user_id;

-- Update overall_score to match average of skills for active students
UPDATE learning_progress
SET overall_score = ROUND(
    (listening_score + reading_score + writing_score + speaking_score) / 4.0, 
    1
),
    last_test_overall_score = ROUND(
        (listening_score + reading_score + writing_score + speaking_score) / 4.0, 
        1
    ),
    highest_overall_score = ROUND(
        (listening_score + reading_score + writing_score + speaking_score) / 4.0 + (RANDOM() * 0.5)::numeric, 
        1
    ),
    last_test_date = CURRENT_TIMESTAMP - ((RANDOM() * 30)::int || ' days')::interval
WHERE user_id IN (
    SELECT user_id FROM user_profiles WHERE user_id::text LIKE 'f%' LIMIT 20
)
AND listening_score IS NOT NULL
AND reading_score IS NOT NULL
AND writing_score IS NOT NULL
AND speaking_score IS NOT NULL;

-- ============================================
-- VALIDATION CHECKS
-- ============================================

-- Check 1: All band scores within valid range
DO $$
DECLARE
    invalid_count INT;
BEGIN
    SELECT COUNT(*) INTO invalid_count
    FROM learning_progress
    WHERE (listening_score IS NOT NULL AND listening_score NOT BETWEEN 0 AND 9)
       OR (reading_score IS NOT NULL AND reading_score NOT BETWEEN 0 AND 9)
       OR (writing_score IS NOT NULL AND writing_score NOT BETWEEN 0 AND 9)
       OR (speaking_score IS NOT NULL AND speaking_score NOT BETWEEN 0 AND 9)
       OR (overall_score IS NOT NULL AND overall_score NOT BETWEEN 0 AND 9)
       OR (last_test_overall_score IS NOT NULL AND last_test_overall_score NOT BETWEEN 0 AND 9)
       OR (highest_overall_score IS NOT NULL AND highest_overall_score NOT BETWEEN 0 AND 9);
    
    IF invalid_count > 0 THEN
        RAISE WARNING 'Found % learning_progress records with invalid band scores', invalid_count;
    ELSE
        RAISE NOTICE '✓ All band scores are within valid range (0.0-9.0)';
    END IF;
END $$;

-- Check 2: Progress percentages within valid range
DO $$
DECLARE
    invalid_progress INT;
BEGIN
    SELECT COUNT(*) INTO invalid_progress
    FROM learning_progress
    WHERE listening_progress NOT BETWEEN 0 AND 100
       OR reading_progress NOT BETWEEN 0 AND 100
       OR writing_progress NOT BETWEEN 0 AND 100
       OR speaking_progress NOT BETWEEN 0 AND 100;
    
    IF invalid_progress > 0 THEN
        RAISE WARNING 'Found % learning_progress records with invalid progress percentages', invalid_progress;
    ELSE
        RAISE NOTICE '✓ All progress percentages are within valid range (0-100)';
    END IF;
END $$;

-- Check 3: All users have learning_progress record
DO $$
DECLARE
    missing_count INT;
BEGIN
    SELECT COUNT(*) INTO missing_count
    FROM user_profiles up
    WHERE NOT EXISTS (
        SELECT 1 FROM learning_progress lp WHERE lp.user_id = up.user_id
    );
    
    IF missing_count > 0 THEN
        RAISE WARNING '% users are missing learning_progress records', missing_count;
    ELSE
        RAISE NOTICE '✓ All users have learning_progress records';
    END IF;
END $$;

-- Check 4: Overall score matches average (within tolerance)
DO $$
DECLARE
    mismatch_count INT;
BEGIN
    SELECT COUNT(*) INTO mismatch_count
    FROM learning_progress
    WHERE listening_score IS NOT NULL 
      AND reading_score IS NOT NULL 
      AND writing_score IS NOT NULL 
      AND speaking_score IS NOT NULL
      AND overall_score IS NOT NULL
      AND ABS(overall_score - (listening_score + reading_score + writing_score + speaking_score) / 4.0) > 0.2;
    
    IF mismatch_count > 0 THEN
        RAISE WARNING '% records have overall_score not matching average of skills', mismatch_count;
    ELSE
        RAISE NOTICE '✓ Overall scores match average of individual skills';
    END IF;
END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================
DO $$
DECLARE
    total_users INT;
    users_with_scores INT;
    avg_overall NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_users FROM learning_progress;
    
    SELECT COUNT(*), ROUND(AVG(overall_score), 1)
    INTO users_with_scores, avg_overall
    FROM learning_progress
    WHERE overall_score IS NOT NULL;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Learning Progress Summary:';
    RAISE NOTICE '  Total users: %', total_users;
    RAISE NOTICE '  Users with band scores: %', users_with_scores;
    RAISE NOTICE '  Average overall score: %', COALESCE(avg_overall::text, 'N/A');
    RAISE NOTICE '============================================';
END $$;
