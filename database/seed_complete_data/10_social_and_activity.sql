-- ============================================
-- SOCIAL INTERACTIONS & REALISTIC ACTIVITY
-- ============================================
-- Purpose: Add user follows, realistic study patterns, streaks
-- Database: user_db
-- Date: 2025-11-07
-- ============================================

\c user_db

-- ============================================
-- USER FOLLOWS - Social Network
-- ============================================
-- Advanced users follow each other (learning community)
-- Intermediate users follow advanced users (mentorship)
-- Beginners follow intermediate and advanced users (guidance)

DO $$
DECLARE
    follower_id UUID;
    followee_id UUID;
    follow_count INT := 0;
BEGIN
    -- Advanced users follow each other (create study groups)
    FOR follower_id IN 
        SELECT id FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
        ORDER BY RANDOM()
        LIMIT 30
    LOOP
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
            AND id != follower_id
            ORDER BY RANDOM()
            LIMIT (3 + FLOOR(RANDOM() * 5))::INT -- Each follows 3-7 others
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '200 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
    END LOOP;
    
    -- Intermediate users follow advanced users (mentorship)
    FOR follower_id IN 
        SELECT id FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
        ORDER BY RANDOM()
        LIMIT 40
    LOOP
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
            ORDER BY target_band_score DESC, RANDOM()
            LIMIT (2 + FLOOR(RANDOM() * 4))::INT -- Each follows 2-5 advanced users
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '150 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
        
        -- Also follow some intermediate peers
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
            AND id != follower_id
            ORDER BY RANDOM()
            LIMIT (1 + FLOOR(RANDOM() * 3))::INT
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '150 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
    END LOOP;
    
    -- Beginners follow everyone (guidance from all levels)
    FOR follower_id IN 
        SELECT id FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
        ORDER BY RANDOM()
        LIMIT 30
    LOOP
        -- Follow advanced users
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
            ORDER BY RANDOM()
            LIMIT (1 + FLOOR(RANDOM() * 3))::INT
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '80 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
        
        -- Follow intermediate users
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
            ORDER BY RANDOM()
            LIMIT (1 + FLOOR(RANDOM() * 2))::INT
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '80 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
        
        -- Follow beginner peers
        FOR followee_id IN 
            SELECT id FROM user_profiles 
            WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
            AND id != follower_id
            ORDER BY RANDOM()
            LIMIT (0 + FLOOR(RANDOM() * 2))::INT
        LOOP
            INSERT INTO user_follows (follower_id, followee_id, created_at)
            VALUES (follower_id, followee_id, NOW() - (RANDOM() * INTERVAL '80 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… User Follows: Created % follow relationships', follow_count;
END $$;

-- ============================================
-- REALISTIC STUDY SESSIONS
-- ============================================
-- Peak study times: 6-9 AM, 8-11 PM (before work/after work)
-- Weekend sessions longer than weekday
-- Consistency patterns: Daily learners vs Weekend warriors

DO $$
DECLARE
    user_rec RECORD;
    session_count INT := 0;
    study_day DATE;
    session_duration INT;
    session_time TIME;
    is_weekend BOOLEAN;
BEGIN
    -- For each new user, create realistic study sessions
    FOR user_rec IN 
        SELECT id, created_at, 
            CASE 
                WHEN id::text LIKE '%-4401%' THEN 'beginner'
                WHEN id::text LIKE '%-4402%' THEN 'intermediate'
                WHEN id::text LIKE '%-4403%' THEN 'advanced'
            END as level
        FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
        ORDER BY RANDOM()
        LIMIT 80 -- Create detailed sessions for 80 users
    LOOP
        -- Create sessions from signup date to now
        study_day := user_rec.created_at::DATE;
        
        WHILE study_day <= CURRENT_DATE LOOP
            is_weekend := EXTRACT(DOW FROM study_day) IN (0, 6);
            
            -- Decide if user studies today (realistic patterns)
            IF (user_rec.level = 'advanced' AND RANDOM() < 0.85) OR  -- 85% study rate
               (user_rec.level = 'intermediate' AND RANDOM() < 0.65) OR  -- 65% study rate
               (user_rec.level = 'beginner' AND RANDOM() < 0.45) THEN  -- 45% study rate
                
                -- Peak hours: Morning (6-9 AM) or Evening (8-11 PM)
                IF RANDOM() < 0.6 THEN
                    -- Evening study (more common)
                    session_time := TIME '20:00:00' + (RANDOM() * INTERVAL '3 hours');
                ELSE
                    -- Morning study
                    session_time := TIME '06:00:00' + (RANDOM() * INTERVAL '3 hours');
                END IF;
                
                -- Session duration: weekend longer, advanced users study longer
                session_duration := CASE 
                    WHEN is_weekend AND user_rec.level = 'advanced' THEN (RANDOM() * 90 + 60)::INT -- 60-150 min
                    WHEN is_weekend AND user_rec.level = 'intermediate' THEN (RANDOM() * 60 + 45)::INT -- 45-105 min
                    WHEN is_weekend THEN (RANDOM() * 45 + 30)::INT -- 30-75 min
                    WHEN user_rec.level = 'advanced' THEN (RANDOM() * 60 + 45)::INT -- 45-105 min
                    WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 45 + 30)::INT -- 30-75 min
                    ELSE (RANDOM() * 30 + 20)::INT -- 20-50 min
                END;
                
                INSERT INTO study_sessions (
                    user_id, session_date, start_time, end_time, 
                    duration_minutes, focus_area, created_at
                ) VALUES (
                    user_rec.id,
                    study_day,
                    session_time,
                    session_time + (session_duration || ' minutes')::INTERVAL,
                    session_duration,
                    (ARRAY['listening', 'reading', 'writing', 'speaking', 'vocabulary', 'grammar'])[FLOOR(RANDOM() * 6 + 1)]::VARCHAR,
                    study_day + session_time
                ) ON CONFLICT DO NOTHING;
                
                session_count := session_count + 1;
            END IF;
            
            study_day := study_day + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… Study Sessions: Created % realistic study sessions with peak hour patterns', session_count;
END $$;

-- ============================================
-- LEARNING PROGRESS with Realistic Band Scores
-- ============================================
-- Beginners: 3.0-5.5, gradual improvement
-- Intermediate: 5.0-7.0, steady progress
-- Advanced: 7.0-8.5, fine-tuning

DO $$
DECLARE
    user_rec RECORD;
    listening NUMERIC(3,1);
    reading NUMERIC(3,1);
    writing NUMERIC(3,1);
    speaking NUMERIC(3,1);
    base_score NUMERIC(3,1);
BEGIN
    FOR user_rec IN 
        SELECT id,
            CASE 
                WHEN id::text LIKE '%-4401%' THEN 'beginner'
                WHEN id::text LIKE '%-4402%' THEN 'intermediate'
                WHEN id::text LIKE '%-4403%' THEN 'advanced'
            END as level
        FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
    LOOP
        -- Set base score by level
        base_score := CASE 
            WHEN user_rec.level = 'beginner' THEN 3.5 + (RANDOM() * 2)::NUMERIC(3,1) -- 3.5-5.5
            WHEN user_rec.level = 'intermediate' THEN 5.5 + (RANDOM() * 1.5)::NUMERIC(3,1) -- 5.5-7.0
            WHEN user_rec.level = 'advanced' THEN 7.0 + (RANDOM() * 1.5)::NUMERIC(3,1) -- 7.0-8.5
        END;
        
        -- Realistic skill variations (listening/reading usually higher than writing/speaking)
        listening := LEAST(9.0, base_score + (RANDOM() * 0.5)::NUMERIC(3,1));
        reading := LEAST(9.0, base_score + (RANDOM() * 0.5)::NUMERIC(3,1));
        writing := GREATEST(0.0, base_score - (RANDOM() * 0.5)::NUMERIC(3,1));
        speaking := GREATEST(0.0, base_score - (RANDOM() * 0.5)::NUMERIC(3,1));
        
        -- Round to nearest 0.5
        listening := ROUND(listening * 2) / 2;
        reading := ROUND(reading * 2) / 2;
        writing := ROUND(writing * 2) / 2;
        speaking := ROUND(speaking * 2) / 2;
        
        INSERT INTO learning_progress (
            user_id, current_level, listening_score, reading_score, 
            writing_score, speaking_score, overall_band_score,
            total_study_time_minutes, lessons_completed, exercises_completed,
            streak_days, longest_streak, last_study_date,
            strengths, weaknesses, created_at, updated_at
        ) VALUES (
            user_rec.id,
            user_rec.level,
            listening,
            reading,
            writing,
            speaking,
            ROUND(((listening + reading + writing + speaking) / 4) * 2) / 2,
            CASE 
                WHEN user_rec.level = 'advanced' THEN (RANDOM() * 5000 + 3000)::INT
                WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 2000 + 800)::INT
                ELSE (RANDOM() * 500 + 100)::INT
            END,
            CASE 
                WHEN user_rec.level = 'advanced' THEN (RANDOM() * 300 + 150)::INT
                WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 100 + 40)::INT
                ELSE (RANDOM() * 30 + 5)::INT
            END,
            CASE 
                WHEN user_rec.level = 'advanced' THEN (RANDOM() * 200 + 100)::INT
                WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 80 + 30)::INT
                ELSE (RANDOM() * 20 + 3)::INT
            END,
            CASE 
                WHEN user_rec.level = 'advanced' THEN (RANDOM() * 50 + 30)::INT
                WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 20 + 7)::INT
                ELSE (RANDOM() * 5 + 0)::INT
            END,
            CASE 
                WHEN user_rec.level = 'advanced' THEN (RANDOM() * 80 + 40)::INT
                WHEN user_rec.level = 'intermediate' THEN (RANDOM() * 30 + 10)::INT
                ELSE (RANDOM() * 10 + 3)::INT
            END,
            CURRENT_DATE - (RANDOM() * INTERVAL '7 days')::INTERVAL,
            CASE 
                WHEN listening >= reading AND listening >= writing THEN ARRAY['listening', 'reading']
                WHEN reading >= writing AND reading >= speaking THEN ARRAY['reading', 'vocabulary']
                WHEN writing >= speaking THEN ARRAY['writing', 'grammar']
                ELSE ARRAY['speaking', 'pronunciation']
            END,
            CASE 
                WHEN writing <= speaking AND writing <= listening THEN ARRAY['writing', 'task_response']
                WHEN speaking <= listening AND speaking <= reading THEN ARRAY['speaking', 'fluency']
                ELSE ARRAY['grammar', 'vocabulary']
            END,
            NOW() - (RANDOM() * INTERVAL '90 days'),
            NOW()
        ) ON CONFLICT (user_id) DO NOTHING;
    END LOOP;
    
    RAISE NOTICE 'âœ… Learning Progress: Created realistic band scores for 150 users';
END $$;

-- ============================================
-- STUDY GOALS
-- ============================================
DO $$
DECLARE
    user_id_var UUID;
    goal_count INT := 0;
BEGIN
    FOR user_id_var IN 
        SELECT id FROM user_profiles 
        WHERE id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
           OR id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
        ORDER BY RANDOM()
        LIMIT 100
    LOOP
        -- Weekly study time goal
        INSERT INTO study_goals (
            user_id, goal_type, target_value, current_value,
            deadline, status, created_at
        ) VALUES (
            user_id_var,
            'weekly_study_hours',
            (10 + FLOOR(RANDOM() * 20))::INT,
            (5 + FLOOR(RANDOM() * 15))::INT,
            DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days',
            CASE WHEN RANDOM() < 0.3 THEN 'completed' WHEN RANDOM() < 0.6 THEN 'in_progress' ELSE 'not_started' END,
            NOW() - (RANDOM() * INTERVAL '30 days')
        ) ON CONFLICT DO NOTHING;
        goal_count := goal_count + 1;
        
        -- Complete 5 exercises this week
        IF RANDOM() < 0.7 THEN
            INSERT INTO study_goals (
                user_id, goal_type, target_value, current_value,
                deadline, status, created_at
            ) VALUES (
                user_id_var,
                'weekly_exercises',
                5,
                (0 + FLOOR(RANDOM() * 6))::INT,
                DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days',
                CASE WHEN RANDOM() < 0.4 THEN 'completed' WHEN RANDOM() < 0.7 THEN 'in_progress' ELSE 'not_started' END,
                NOW() - (RANDOM() * INTERVAL '15 days')
            ) ON CONFLICT DO NOTHING;
            goal_count := goal_count + 1;
        END IF;
        
        -- Achieve target band score (monthly)
        IF RANDOM() < 0.5 THEN
            INSERT INTO study_goals (
                user_id, goal_type, target_value, current_value,
                deadline, status, created_at
            ) VALUES (
                user_id_var,
                'target_band_score',
                (CASE 
                    WHEN user_id_var::text LIKE '%-4401%' THEN 6.0
                    WHEN user_id_var::text LIKE '%-4402%' THEN 7.0
                    ELSE 8.0
                END)::INT,
                0,
                CURRENT_DATE + (30 + FLOOR(RANDOM() * 60))::INT,
                'in_progress',
                NOW() - (RANDOM() * INTERVAL '60 days')
            ) ON CONFLICT DO NOTHING;
            goal_count := goal_count + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'âœ… Study Goals: Created % realistic goals', goal_count;
END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================
DO $$
DECLARE
    total_users INT;
    total_follows INT;
    total_sessions INT;
    total_progress INT;
    total_goals INT;
    avg_session_duration NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_users FROM user_profiles;
    SELECT COUNT(*) INTO total_follows FROM user_follows;
    SELECT COUNT(*) INTO total_sessions FROM study_sessions;
    SELECT COUNT(*) INTO total_progress FROM learning_progress;
    SELECT COUNT(*) INTO total_goals FROM study_goals;
    SELECT ROUND(AVG(duration_minutes), 1) INTO avg_session_duration FROM study_sessions;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'âœ… Social & Activity Summary:';
    RAISE NOTICE '  Total users: %', total_users;
    RAISE NOTICE '  Total follow relationships: %', total_follows;
    RAISE NOTICE '  Total study sessions: %', total_sessions;
    RAISE NOTICE '  Average session duration: % minutes', avg_session_duration;
    RAISE NOTICE '  Users with learning progress: %', total_progress;
    RAISE NOTICE '  Active study goals: %', total_goals;
    RAISE NOTICE '============================================';
END $$;
