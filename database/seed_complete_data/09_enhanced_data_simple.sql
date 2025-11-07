-- ============================================
-- ENHANCED REALISTIC DATA - Simple Addition
-- ============================================
-- Purpose: Add more realistic data to existing users
-- No new users - just enhance current data volume
-- Date: 2025-11-07
-- ============================================

\c user_db

-- ============================================
-- ADD MORE USER FOLLOWS (Social Network)
-- ============================================
DO $$
DECLARE
    follow_count INT := 0;
    follower_id UUID;
    following_id UUID;
BEGIN
    -- Create realistic follow patterns
    FOR follower_id IN 
        SELECT user_id FROM user_profiles 
        ORDER BY RANDOM()
        LIMIT 50
    LOOP
        -- Each user follows 3-8 others
        FOR following_id IN 
            SELECT user_id FROM user_profiles 
            WHERE user_id != follower_id
            ORDER BY RANDOM()
            LIMIT (3 + FLOOR(RANDOM() * 6))::INT
        LOOP
            INSERT INTO user_follows (follower_id, following_id, created_at)
            VALUES (follower_id, following_id, NOW() - (RANDOM() * INTERVAL '180 days'))
            ON CONFLICT DO NOTHING;
            follow_count := follow_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '✅ User Follows: Added % follow relationships', follow_count;
END $$;

-- ============================================
-- ADD MORE STUDY SESSIONS (Realistic Patterns)
-- ============================================
DO $$
DECLARE
    user_rec RECORD;
    session_count INT := 0;
    session_duration INT;
    started_timestamp TIMESTAMP;
    days_back INT;
BEGIN
    FOR user_rec IN 
        SELECT user_id, created_at 
        FROM user_profiles 
        ORDER BY RANDOM()
        LIMIT 40
    LOOP
        -- Add sessions for past 30 days
        days_back := 0;
        WHILE days_back < 30 LOOP
            
            -- 50% chance to study each day
            IF RANDOM() < 0.5 THEN
                -- Peak hours: Morning (6-9 AM) or Evening (8-11 PM)
                IF RANDOM() < 0.6 THEN
                    started_timestamp := (CURRENT_DATE - days_back) + TIME '20:00:00' + (RANDOM() * INTERVAL '3 hours');
                ELSE
                    started_timestamp := (CURRENT_DATE - days_back) + TIME '06:00:00' + (RANDOM() * INTERVAL '3 hours');
                END IF;
                
                -- 30-90 minute sessions
                session_duration := (30 + FLOOR(RANDOM() * 60))::INT;
                
                INSERT INTO study_sessions (
                    user_id, session_type, skill_type, 
                    started_at, ended_at, duration_minutes,
                    is_completed, completion_percentage, created_at
                ) VALUES (
                    user_rec.user_id,
                    (ARRAY['practice', 'lesson', 'test'])[FLOOR(RANDOM() * 3 + 1)]::VARCHAR,
                    (ARRAY['listening', 'reading', 'writing', 'speaking'])[FLOOR(RANDOM() * 4 + 1)]::VARCHAR,
                    started_timestamp,
                    started_timestamp + (session_duration || ' minutes')::INTERVAL,
                    session_duration,
                    RANDOM() < 0.8, -- 80% completed
                    CASE WHEN RANDOM() < 0.8 THEN 100 ELSE (50 + FLOOR(RANDOM() * 50))::INT END,
                    started_timestamp
                ) ON CONFLICT DO NOTHING;
                
                session_count := session_count + 1;
            END IF;
            
            days_back := days_back + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '✅ Study Sessions: Added % realistic study sessions', session_count;
END $$;

-- ============================================
-- ADD MORE STUDY GOALS
-- ============================================
DO $$
DECLARE
    user_id_var UUID;
    goal_count INT := 0;
    target_val INT;
BEGIN
    FOR user_id_var IN 
        SELECT user_id FROM user_profiles 
        WHERE user_id NOT IN (SELECT DISTINCT user_id FROM study_goals)
        ORDER BY RANDOM()
        LIMIT 30
    LOOP
        -- Weekly study time goal
        target_val := (10 + FLOOR(RANDOM() * 20))::INT;
        INSERT INTO study_goals (
            user_id, goal_type, title, description,
            target_value, target_unit, current_value,
            start_date, end_date, status, created_at
        ) VALUES (
            user_id_var,
            'weekly_hours',
            'Complete ' || target_val || ' hours of study this week',
            'Practice IELTS skills for ' || target_val || ' hours to build consistency',
            target_val,
            'hours',
            (FLOOR(RANDOM() * target_val))::INT,
            CURRENT_DATE - 3,
            DATE_TRUNC('week', CURRENT_DATE)::DATE + 6,
            CASE WHEN RANDOM() < 0.3 THEN 'completed' WHEN RANDOM() < 0.7 THEN 'active' ELSE 'not_started' END,
            NOW() - (RANDOM() * INTERVAL '15 days')
        ) ON CONFLICT DO NOTHING;
        goal_count := goal_count + 1;
    END LOOP;
    
    RAISE NOTICE '✅ Study Goals: Added % goals', goal_count;
END $$;

-- ============================================
-- SUMMARY
-- ============================================
DO $$
DECLARE
    total_follows INT;
    total_sessions INT;
    total_goals INT;
BEGIN
    SELECT COUNT(*) INTO total_follows FROM user_follows;
    SELECT COUNT(*) INTO total_sessions FROM study_sessions;
    SELECT COUNT(*) INTO total_goals FROM study_goals;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Enhanced User Data Summary:';
    RAISE NOTICE '  Total follow relationships: %', total_follows;
    RAISE NOTICE '  Total study sessions: %', total_sessions;
    RAISE NOTICE '  Total study goals: %', total_goals;
    RAISE NOTICE '============================================';
END $$;
