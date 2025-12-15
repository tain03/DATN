-- ============================================
-- PHASE 2B: USER_DB - OFFICIAL TEST RESULTS (PER-SKILL MODEL)
-- ============================================
-- Purpose: Seed official IELTS test results with per-skill scoring
-- Database: user_db
-- 
-- IMPORTANT SCHEMA CHANGES (Nov 2024):
-- - Now uses PER-SKILL MODEL: Each test creates 4 rows (listening, reading, writing, speaking)
-- - Each row has: skill_type, band_score, raw_score, ielts_variant (for reading)
-- - Reading MUST have ielts_variant (academic or general_training)
-- - Other skills MUST NOT have ielts_variant
-- 
-- Creates:
-- - Official test results for 50 students
-- - Each student has multiple test attempts (2-4 tests)
-- - Each test = 4 rows (one per skill)
-- - Realistic band scores with progression over time
-- ============================================

-- ============================================
-- OFFICIAL TEST RESULTS - LISTENING SKILL
-- ============================================

INSERT INTO official_test_results (
    id, user_id, test_type, test_date, test_duration_minutes, completion_status,
    test_source, notes, skill_type, band_score, raw_score, total_questions,
    source_service, source_table, source_id, ielts_variant
)
SELECT 
    uuid_generate_v4(),
    user_id,
    CASE (attempt_num % 4)
        WHEN 0 THEN 'full_test'
        WHEN 1 THEN 'mock_test'
        WHEN 2 THEN 'sectional_test'
        ELSE 'practice'
    END,
    -- test_date: spread over last 90 days with progression
    CURRENT_TIMESTAMP - (90 - (attempt_num * 25))::INTEGER * INTERVAL '1 day',
    60, -- Listening test duration
    'completed',
    CASE (attempt_num % 3)
        WHEN 0 THEN 'Cambridge IELTS 18'
        WHEN 1 THEN 'Cambridge IELTS 17'
        ELSE 'Mock Test Platform'
    END,
    CASE WHEN attempt_num = 3 THEN 'Final practice test before real exam' ELSE NULL END,
    'listening', -- skill_type
    -- band_score: Realistic progression from 5.5 to 7.5
    ROUND(
        CASE 
            WHEN attempt_num = 0 THEN (random() * 1.0 + 5.0)::NUMERIC -- 5.0-6.0 first attempt
            WHEN attempt_num = 1 THEN (random() * 1.0 + 5.5)::NUMERIC -- 5.5-6.5 second
            WHEN attempt_num = 2 THEN (random() * 1.0 + 6.0)::NUMERIC -- 6.0-7.0 third
            ELSE (random() * 1.5 + 6.5)::NUMERIC -- 6.5-8.0 fourth
        END * 2
    ) / 2, -- Round to nearest 0.5
    -- raw_score: Out of 40 questions for Listening
    CASE 
        WHEN attempt_num = 0 THEN (random() * 7 + 16)::INTEGER -- 16-23 (band 5.0-6.0)
        WHEN attempt_num = 1 THEN (random() * 6 + 20)::INTEGER -- 20-26 (band 5.5-6.5)
        WHEN attempt_num = 2 THEN (random() * 7 + 23)::INTEGER -- 23-30 (band 6.0-7.0)
        ELSE (random() * 8 + 27)::INTEGER -- 27-35 (band 6.5-8.0)
    END,
    40, -- total_questions for Listening
    'exercise_service', -- source_service
    'user_exercise_attempts', -- source_table
    uuid_generate_v4(), -- source_id (mock)
    NULL -- ielts_variant (NULL for listening)
FROM (
    SELECT 
        user_id,
        generate_series(0, 
            -- Students have 2-4 test attempts
            CASE 
                WHEN random() < 0.3 THEN 1 -- 30% have 2 tests
                WHEN random() < 0.7 THEN 2 -- 40% have 3 tests
                ELSE 3 -- 30% have 4 tests
            END
        ) as attempt_num
    FROM user_profiles
    WHERE user_id::text LIKE 'f%' -- 50 students
    LIMIT 50
) AS test_attempts;

-- ============================================
-- OFFICIAL TEST RESULTS - READING SKILL
-- ============================================

INSERT INTO official_test_results (
    id, user_id, test_type, test_date, test_duration_minutes, completion_status,
    test_source, notes, skill_type, band_score, raw_score, total_questions,
    source_service, source_table, source_id, ielts_variant
)
SELECT 
    uuid_generate_v4(),
    user_id,
    CASE (attempt_num % 4)
        WHEN 0 THEN 'full_test'
        WHEN 1 THEN 'mock_test'
        WHEN 2 THEN 'sectional_test'
        ELSE 'practice'
    END,
    -- Same test_date as listening (same test session)
    CURRENT_TIMESTAMP - (90 - (attempt_num * 25))::INTEGER * INTERVAL '1 day',
    60, -- Reading test duration
    'completed',
    CASE (attempt_num % 3)
        WHEN 0 THEN 'Cambridge IELTS 18'
        WHEN 1 THEN 'Cambridge IELTS 17'
        ELSE 'Mock Test Platform'
    END,
    CASE WHEN attempt_num = 3 THEN 'Final practice test before real exam' ELSE NULL END,
    'reading', -- skill_type
    -- band_score: Reading typically slightly higher than Listening for most students
    ROUND(
        CASE 
            WHEN attempt_num = 0 THEN (random() * 1.0 + 5.5)::NUMERIC -- 5.5-6.5 first
            WHEN attempt_num = 1 THEN (random() * 1.0 + 6.0)::NUMERIC -- 6.0-7.0 second
            WHEN attempt_num = 2 THEN (random() * 1.0 + 6.5)::NUMERIC -- 6.5-7.5 third
            ELSE (random() * 1.5 + 7.0)::NUMERIC -- 7.0-8.5 fourth
        END * 2
    ) / 2,
    -- raw_score: Out of 40 questions for Reading (Academic vs General Training have different conversion)
    CASE 
        WHEN attempt_num = 0 THEN (random() * 7 + 18)::INTEGER -- 18-25
        WHEN attempt_num = 1 THEN (random() * 6 + 23)::INTEGER -- 23-29
        WHEN attempt_num = 2 THEN (random() * 7 + 26)::INTEGER -- 26-33
        ELSE (random() * 8 + 30)::INTEGER -- 30-38
    END,
    40, -- total_questions for Reading
    'exercise_service',
    'user_exercise_attempts',
    uuid_generate_v4(),
    -- ielts_variant: REQUIRED for reading (70% academic, 30% general training)
    CASE WHEN random() < 0.7 THEN 'academic' ELSE 'general_training' END
FROM (
    SELECT 
        user_id,
        generate_series(0, 
            CASE 
                WHEN random() < 0.3 THEN 1
                WHEN random() < 0.7 THEN 2
                ELSE 3
            END
        ) as attempt_num
    FROM user_profiles
    WHERE user_id::text LIKE 'f%'
    LIMIT 50
) AS test_attempts;

-- ============================================
-- OFFICIAL TEST RESULTS - WRITING SKILL
-- ============================================

INSERT INTO official_test_results (
    id, user_id, test_type, test_date, test_duration_minutes, completion_status,
    test_source, notes, skill_type, band_score, raw_score, total_questions,
    source_service, source_table, source_id, ielts_variant
)
SELECT 
    uuid_generate_v4(),
    user_id,
    CASE (attempt_num % 4)
        WHEN 0 THEN 'full_test'
        WHEN 1 THEN 'mock_test'
        WHEN 2 THEN 'sectional_test'
        ELSE 'practice'
    END,
    -- Same test_date as listening/reading (same test session)
    CURRENT_TIMESTAMP - (90 - (attempt_num * 25))::INTEGER * INTERVAL '1 day',
    60, -- Writing test duration
    'completed',
    CASE (attempt_num % 3)
        WHEN 0 THEN 'Cambridge IELTS 18'
        WHEN 1 THEN 'Cambridge IELTS 17'
        ELSE 'Mock Test Platform'
    END,
    CASE WHEN attempt_num = 3 THEN 'Final practice test before real exam' ELSE NULL END,
    'writing', -- skill_type
    -- band_score: Writing typically lowest score for most students (productive skill)
    ROUND(
        CASE 
            WHEN attempt_num = 0 THEN (random() * 1.0 + 5.0)::NUMERIC -- 5.0-6.0 first
            WHEN attempt_num = 1 THEN (random() * 1.0 + 5.5)::NUMERIC -- 5.5-6.5 second
            WHEN attempt_num = 2 THEN (random() * 1.0 + 6.0)::NUMERIC -- 6.0-7.0 third
            ELSE (random() * 1.5 + 6.0)::NUMERIC -- 6.0-7.5 fourth
        END * 2
    ) / 2,
    -- raw_score: NULL for writing (scored by criteria, not raw score)
    NULL,
    2, -- total_questions (Task 1 + Task 2)
    'ai_service', -- source_service for writing
    'writing_evaluations',
    uuid_generate_v4(),
    NULL -- ielts_variant (NULL for writing)
FROM (
    SELECT 
        user_id,
        generate_series(0, 
            CASE 
                WHEN random() < 0.3 THEN 1
                WHEN random() < 0.7 THEN 2
                ELSE 3
            END
        ) as attempt_num
    FROM user_profiles
    WHERE user_id::text LIKE 'f%'
    LIMIT 50
) AS test_attempts;

-- ============================================
-- OFFICIAL TEST RESULTS - SPEAKING SKILL
-- ============================================

INSERT INTO official_test_results (
    id, user_id, test_type, test_date, test_duration_minutes, completion_status,
    test_source, notes, skill_type, band_score, raw_score, total_questions,
    source_service, source_table, source_id, ielts_variant
)
SELECT 
    uuid_generate_v4(),
    user_id,
    CASE (attempt_num % 4)
        WHEN 0 THEN 'full_test'
        WHEN 1 THEN 'mock_test'
        WHEN 2 THEN 'sectional_test'
        ELSE 'practice'
    END,
    -- Speaking test usually 1-2 days after written test
    CURRENT_TIMESTAMP - (90 - (attempt_num * 25))::INTEGER * INTERVAL '1 day' + INTERVAL '1 day',
    15, -- Speaking test duration (11-14 minutes typically)
    'completed',
    CASE (attempt_num % 3)
        WHEN 0 THEN 'Cambridge IELTS 18'
        WHEN 1 THEN 'Cambridge IELTS 17'
        ELSE 'Mock Test Platform'
    END,
    CASE WHEN attempt_num = 3 THEN 'Final practice test before real exam' ELSE NULL END,
    'speaking', -- skill_type
    -- band_score: Speaking often higher than Writing but lower than Reading for most students
    ROUND(
        CASE 
            WHEN attempt_num = 0 THEN (random() * 1.0 + 5.5)::NUMERIC -- 5.5-6.5 first
            WHEN attempt_num = 1 THEN (random() * 1.0 + 6.0)::NUMERIC -- 6.0-7.0 second
            WHEN attempt_num = 2 THEN (random() * 1.0 + 6.5)::NUMERIC -- 6.5-7.5 third
            ELSE (random() * 1.5 + 6.5)::NUMERIC -- 6.5-8.0 fourth
        END * 2
    ) / 2,
    -- raw_score: NULL for speaking (scored by criteria, not raw score)
    NULL,
    3, -- total_questions (Part 1, Part 2, Part 3)
    'ai_service', -- source_service for speaking
    'speaking_evaluations',
    uuid_generate_v4(),
    NULL -- ielts_variant (NULL for speaking)
FROM (
    SELECT 
        user_id,
        generate_series(0, 
            CASE 
                WHEN random() < 0.3 THEN 1
                WHEN random() < 0.7 THEN 2
                ELSE 3
            END
        ) as attempt_num
    FROM user_profiles
    WHERE user_id::text LIKE 'f%'
    LIMIT 50
) AS test_attempts;

-- ============================================
-- VERIFICATION QUERY
-- ============================================
-- Uncomment to verify the data after seeding:

-- SELECT 
--     user_id,
--     test_date::date,
--     test_type,
--     skill_type,
--     band_score,
--     raw_score,
--     ielts_variant,
--     test_source
-- FROM official_test_results
-- ORDER BY user_id, test_date, skill_type
-- LIMIT 20;

-- -- Count per user per skill:
-- SELECT 
--     skill_type,
--     COUNT(*) as total_records,
--     COUNT(DISTINCT user_id) as unique_users,
--     ROUND(AVG(band_score), 2) as avg_band_score
-- FROM official_test_results
-- GROUP BY skill_type
-- ORDER BY skill_type;
