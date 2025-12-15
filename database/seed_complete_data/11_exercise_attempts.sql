-- ============================================
-- REALISTIC EXERCISE ATTEMPTS & SCORES
-- ============================================
-- Purpose: Add diverse exercise attempts with realistic score distributions
-- Database: exercise_db
-- Date: 2025-11-07
-- ============================================

\c exercise_db

-- ============================================
-- USER EXERCISE ATTEMPTS - Realistic Distribution
-- ============================================
-- Score distribution follows normal bell curve:
-- - Beginners: 40-60% correct (Band 3-5)
-- - Intermediate: 60-80% correct (Band 5-7)
-- - Advanced: 80-95% correct (Band 7-9)

DO $$
DECLARE
    user_rec RECORD;
    exercise_rec RECORD;
    attempt_count INT := 0;
    score NUMERIC(5,2);
    accuracy NUMERIC(5,2);
    base_accuracy NUMERIC(5,2);
    attempt_num INT;
    time_spent INT;
BEGIN
    -- Get new users and create exercise attempts
    FOR user_rec IN 
        SELECT 
            up.id, 
            CASE 
                WHEN up.id::text LIKE '%-4401%' THEN 'beginner'
                WHEN up.id::text LIKE '%-4402%' THEN 'intermediate'
                WHEN up.id::text LIKE '%-4403%' THEN 'advanced'
            END as level,
            up.created_at
        FROM dblink(
            'dbname=user_db user=ielts_admin',
            'SELECT id, created_at FROM user_profiles WHERE id::text LIKE ''550e8400-e29b-41d4-a716-4466554401%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554402%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554403%'''
        ) AS up(id UUID, created_at TIMESTAMP)
        ORDER BY RANDOM()
        LIMIT 100 -- Create attempts for 100 users
    LOOP
        -- Each user attempts 3-15 exercises
        FOR exercise_rec IN 
            SELECT id, skill_type, difficulty_level, estimated_duration_minutes
            FROM exercises 
            WHERE deleted_at IS NULL
            ORDER BY RANDOM()
            LIMIT (3 + FLOOR(RANDOM() * 13))::INT
        LOOP
            -- Users may attempt same exercise multiple times (1-3 attempts)
            FOR attempt_num IN 1..(1 + FLOOR(RANDOM() * 2))::INT LOOP
                
                -- Base accuracy by level and difficulty
                base_accuracy := CASE 
                    WHEN user_rec.level = 'beginner' THEN
                        CASE 
                            WHEN exercise_rec.difficulty_level = 'easy' THEN 50 + (RANDOM() * 20)
                            WHEN exercise_rec.difficulty_level = 'medium' THEN 35 + (RANDOM() * 20)
                            ELSE 20 + (RANDOM() * 20)
                        END
                    WHEN user_rec.level = 'intermediate' THEN
                        CASE 
                            WHEN exercise_rec.difficulty_level = 'easy' THEN 70 + (RANDOM() * 20)
                            WHEN exercise_rec.difficulty_level = 'medium' THEN 60 + (RANDOM() * 20)
                            ELSE 45 + (RANDOM() * 20)
                        END
                    ELSE -- advanced
                        CASE 
                            WHEN exercise_rec.difficulty_level = 'easy' THEN 85 + (RANDOM() * 10)
                            WHEN exercise_rec.difficulty_level = 'medium' THEN 80 + (RANDOM() * 15)
                            ELSE 70 + (RANDOM() * 20)
                        END
                END;
                
                -- Improvement on retry (2nd attempt +5%, 3rd attempt +8%)
                accuracy := LEAST(100, base_accuracy + ((attempt_num - 1) * 5 * RANDOM()));
                
                -- Convert to IELTS band score (rough mapping)
                score := CASE 
                    WHEN accuracy >= 95 THEN 9.0
                    WHEN accuracy >= 90 THEN 8.5
                    WHEN accuracy >= 85 THEN 8.0
                    WHEN accuracy >= 80 THEN 7.5
                    WHEN accuracy >= 75 THEN 7.0
                    WHEN accuracy >= 70 THEN 6.5
                    WHEN accuracy >= 65 THEN 6.0
                    WHEN accuracy >= 60 THEN 5.5
                    WHEN accuracy >= 55 THEN 5.0
                    WHEN accuracy >= 50 THEN 4.5
                    WHEN accuracy >= 45 THEN 4.0
                    WHEN accuracy >= 40 THEN 3.5
                    WHEN accuracy >= 35 THEN 3.0
                    WHEN accuracy >= 30 THEN 2.5
                    ELSE 2.0
                END;
                
                -- Time spent: varies by difficulty and user level
                time_spent := CASE 
                    WHEN user_rec.level = 'advanced' THEN
                        GREATEST(5, exercise_rec.estimated_duration_minutes::INT - (10 + FLOOR(RANDOM() * 10)))
                    WHEN user_rec.level = 'intermediate' THEN
                        exercise_rec.estimated_duration_minutes::INT + (FLOOR(RANDOM() * 10) - 5)
                    ELSE
                        exercise_rec.estimated_duration_minutes::INT + (5 + FLOOR(RANDOM() * 15))
                END;
                
                INSERT INTO user_exercise_attempts (
                    user_id, exercise_id, status, score, 
                    time_spent_minutes, attempt_number,
                    started_at, completed_at, submitted_at
                ) VALUES (
                    user_rec.id,
                    exercise_rec.id,
                    CASE 
                        WHEN RANDOM() < 0.85 THEN 'completed'
                        WHEN RANDOM() < 0.90 THEN 'in_progress'
                        ELSE 'not_started'
                    END,
                    score,
                    time_spent,
                    attempt_num,
                    user_rec.created_at + (RANDOM() * (NOW() - user_rec.created_at)),
                    user_rec.created_at + (RANDOM() * (NOW() - user_rec.created_at)) + (time_spent || ' minutes')::INTERVAL,
                    user_rec.created_at + (RANDOM() * (NOW() - user_rec.created_at)) + (time_spent || ' minutes')::INTERVAL
                ) ON CONFLICT DO NOTHING;
                
                attempt_count := attempt_count + 1;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… Exercise Attempts: Created % attempts with realistic score distribution', attempt_count;
END $$;

-- ============================================
-- QUESTION ANSWERS - Detailed Responses
-- ============================================
DO $$
DECLARE
    attempt_rec RECORD;
    question_rec RECORD;
    answer_count INT := 0;
    is_correct BOOLEAN;
BEGIN
    -- For completed attempts, generate question answers
    FOR attempt_rec IN 
        SELECT id, user_id, exercise_id, score, completed_at
        FROM user_exercise_attempts
        WHERE status = 'completed'
        AND id NOT IN (SELECT DISTINCT attempt_id FROM question_answers WHERE attempt_id IS NOT NULL)
        ORDER BY RANDOM()
        LIMIT 500 -- Add detailed answers for 500 attempts
    LOOP
        FOR question_rec IN 
            SELECT q.id, q.question_type, q.points
            FROM questions q
            WHERE q.exercise_id = attempt_rec.exercise_id
            ORDER BY q.order_index
        LOOP
            -- Determine if answer is correct based on attempt score
            -- Higher score = more correct answers
            is_correct := RANDOM() * 10 < attempt_rec.score;
            
            INSERT INTO question_answers (
                attempt_id, question_id, user_id,
                selected_option_id, user_answer, is_correct,
                points_earned, time_spent_seconds, created_at
            ) VALUES (
                attempt_rec.id,
                question_rec.id,
                attempt_rec.user_id,
                CASE 
                    WHEN question_rec.question_type = 'multiple_choice' THEN
                        (SELECT id FROM question_options 
                         WHERE question_id = question_rec.id 
                         ORDER BY CASE WHEN is_correct = is_correct THEN 0 ELSE 1 END, RANDOM() 
                         LIMIT 1)
                    ELSE NULL
                END,
                CASE 
                    WHEN question_rec.question_type = 'fill_in_blank' THEN 'user response text'
                    WHEN question_rec.question_type = 'essay' THEN 'User essay response with multiple sentences...'
                    ELSE NULL
                END,
                is_correct,
                CASE WHEN is_correct THEN question_rec.points ELSE 0 END,
                (10 + FLOOR(RANDOM() * 50))::INT,
                attempt_rec.completed_at
            ) ON CONFLICT DO NOTHING;
            
            answer_count := answer_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… Question Answers: Created % detailed answers', answer_count;
END $$;

-- ============================================
-- EXERCISE ANALYTICS - Update Stats
-- ============================================
DO $$
DECLARE
    exercise_rec RECORD;
BEGIN
    -- Update analytics for exercises with new attempts
    FOR exercise_rec IN 
        SELECT 
            e.id,
            COUNT(uea.id) as total_attempts,
            COUNT(CASE WHEN uea.status = 'completed' THEN 1 END) as completed_attempts,
            ROUND(AVG(CASE WHEN uea.status = 'completed' THEN uea.score END), 2) as avg_score,
            ROUND(AVG(CASE WHEN uea.status = 'completed' THEN uea.time_spent_minutes END), 1) as avg_time,
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
            average_time_minutes = exercise_rec.avg_time,
            unique_users = exercise_rec.unique_users,
            completion_rate = ROUND((exercise_rec.completed_attempts::NUMERIC / NULLIF(exercise_rec.total_attempts, 0)) * 100, 1),
            updated_at = NOW()
        WHERE exercise_id = exercise_rec.id;
    END LOOP;
    
    RAISE NOTICE 'âœ… Exercise Analytics: Updated statistics';
END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================
DO $$
DECLARE
    total_attempts INT;
    completed_attempts INT;
    total_answers INT;
    avg_score NUMERIC;
    beginner_avg NUMERIC;
    intermediate_avg NUMERIC;
    advanced_avg NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_attempts FROM user_exercise_attempts;
    SELECT COUNT(*) INTO completed_attempts FROM user_exercise_attempts WHERE status = 'completed';
    SELECT COUNT(*) INTO total_answers FROM question_answers;
    SELECT ROUND(AVG(score), 2) INTO avg_score FROM user_exercise_attempts WHERE status = 'completed';
    
    -- Average by user level
    SELECT ROUND(AVG(uea.score), 2) INTO beginner_avg
    FROM user_exercise_attempts uea
    WHERE uea.user_id::text LIKE '%-4401%' AND uea.status = 'completed';
    
    SELECT ROUND(AVG(uea.score), 2) INTO intermediate_avg
    FROM user_exercise_attempts uea
    WHERE uea.user_id::text LIKE '%-4402%' AND uea.status = 'completed';
    
    SELECT ROUND(AVG(uea.score), 2) INTO advanced_avg
    FROM user_exercise_attempts uea
    WHERE uea.user_id::text LIKE '%-4403%' AND uea.status = 'completed';
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'âœ… Exercise Attempts Summary:';
    RAISE NOTICE '  Total attempts: %', total_attempts;
    RAISE NOTICE '  Completed attempts: %', completed_attempts;
    RAISE NOTICE '  Total question answers: %', total_answers;
    RAISE NOTICE '  Overall average score: %', avg_score;
    RAISE NOTICE '  Beginner average: %', beginner_avg;
    RAISE NOTICE '  Intermediate average: %', intermediate_avg;
    RAISE NOTICE '  Advanced average: %', advanced_avg;
    RAISE NOTICE '============================================';
END $$;
