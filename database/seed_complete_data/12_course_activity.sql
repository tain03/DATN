-- ============================================
-- DIVERSE COURSE ENROLLMENTS & REVIEWS
-- ============================================
-- Purpose: Add realistic course enrollments and detailed reviews
-- Database: course_db
-- Date: 2025-11-07
-- ============================================

\c course_db

-- ============================================
-- COURSE ENROLLMENTS - Realistic Patterns
-- ============================================
-- Beginners enroll in foundation courses
-- Intermediate enroll in skill-building courses
-- Advanced enroll in band 7+ preparation courses

DO $$
DECLARE
    user_rec RECORD;
    course_rec RECORD;
    enrollment_count INT := 0;
    progress_percent INT;
BEGIN
    -- Get new users
    FOR user_rec IN 
        SELECT 
            up.id,
            up.created_at,
            CASE 
                WHEN up.id::text LIKE '%-4401%' THEN 'beginner'
                WHEN up.id::text LIKE '%-4402%' THEN 'intermediate'
                WHEN up.id::text LIKE '%-4403%' THEN 'advanced'
            END as level
        FROM dblink(
            'dbname=user_db user=ielts_admin',
            'SELECT id, created_at FROM user_profiles WHERE id::text LIKE ''550e8400-e29b-41d4-a716-4466554401%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554402%'' OR id::text LIKE ''550e8400-e29b-41d4-a716-4466554403%'''
        ) AS up(id UUID, created_at TIMESTAMP)
    LOOP
        -- Each user enrolls in 1-5 courses based on level
        FOR course_rec IN 
            SELECT 
                c.id, 
                c.title, 
                c.level as course_level,
                c.created_at as course_created
            FROM courses c
            WHERE 
                (user_rec.level = 'beginner' AND c.level IN ('beginner', 'elementary')) OR
                (user_rec.level = 'intermediate' AND c.level IN ('intermediate', 'upper_intermediate')) OR
                (user_rec.level = 'advanced' AND c.level IN ('advanced', 'upper_intermediate'))
            AND c.deleted_at IS NULL
            ORDER BY RANDOM()
            LIMIT (1 + FLOOR(RANDOM() * 4))::INT
        LOOP
            -- Progress varies by user level and course difficulty match
            progress_percent := CASE 
                WHEN user_rec.level = 'advanced' THEN (60 + FLOOR(RANDOM() * 40))::INT
                WHEN user_rec.level = 'intermediate' THEN (40 + FLOOR(RANDOM() * 50))::INT
                ELSE (20 + FLOOR(RANDOM() * 60))::INT
            END;
            
            INSERT INTO course_enrollments (
                user_id, course_id, status, progress_percentage,
                enrolled_at, last_accessed_at, completed_at
            ) VALUES (
                user_rec.id,
                course_rec.id,
                CASE 
                    WHEN progress_percent >= 100 THEN 'completed'
                    WHEN progress_percent > 0 THEN 'in_progress'
                    ELSE 'enrolled'
                END,
                LEAST(100, progress_percent),
                GREATEST(user_rec.created_at, course_rec.course_created) + (RANDOM() * INTERVAL '30 days'),
                NOW() - (RANDOM() * INTERVAL '7 days'),
                CASE 
                    WHEN progress_percent >= 100 THEN NOW() - (RANDOM() * INTERVAL '30 days')
                    ELSE NULL
                END
            ) ON CONFLICT DO NOTHING;
            
            enrollment_count := enrollment_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… Course Enrollments: Created % enrollments with realistic progress', enrollment_count;
END $$;

-- ============================================
-- LESSON PROGRESS - Detailed Tracking
-- ============================================
DO $$
DECLARE
    enrollment_rec RECORD;
    lesson_rec RECORD;
    progress_count INT := 0;
    watch_percentage INT;
BEGIN
    -- Create lesson progress for active enrollments
    FOR enrollment_rec IN 
        SELECT ce.id, ce.user_id, ce.course_id, ce.progress_percentage
        FROM course_enrollments ce
        WHERE ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
           OR ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
           OR ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554403%'
        ORDER BY RANDOM()
        LIMIT 200 -- Create detailed progress for 200 enrollments
    LOOP
        -- Get lessons for this course
        FOR lesson_rec IN 
            SELECT l.id, l.module_id, l.order_index
            FROM lessons l
            JOIN modules m ON m.id = l.module_id
            WHERE m.course_id = enrollment_rec.course_id
            ORDER BY m.order_index, l.order_index
        LOOP
            -- Only track progress for lessons user has started
            -- Progress correlates with enrollment progress
            IF RANDOM() * 100 < enrollment_rec.progress_percentage + 20 THEN
                
                watch_percentage := CASE 
                    WHEN RANDOM() < 0.7 THEN 100 -- Most lessons fully completed
                    WHEN RANDOM() < 0.85 THEN (50 + FLOOR(RANDOM() * 50))::INT -- Some partially watched
                    ELSE (10 + FLOOR(RANDOM() * 40))::INT -- Few just started
                END;
                
                INSERT INTO lesson_progress (
                    user_id, lesson_id, status, watch_percentage,
                    watch_time_seconds, last_position_seconds,
                    started_at, completed_at, last_watched_at
                ) VALUES (
                    enrollment_rec.user_id,
                    lesson_rec.id,
                    CASE 
                        WHEN watch_percentage >= 90 THEN 'completed'
                        WHEN watch_percentage > 0 THEN 'in_progress'
                        ELSE 'not_started'
                    END,
                    watch_percentage,
                    (watch_percentage * 10 + FLOOR(RANDOM() * 100))::INT, -- Rough watch time
                    (watch_percentage * 10)::INT,
                    NOW() - (RANDOM() * INTERVAL '60 days'),
                    CASE 
                        WHEN watch_percentage >= 90 THEN NOW() - (RANDOM() * INTERVAL '45 days')
                        ELSE NULL
                    END,
                    NOW() - (RANDOM() * INTERVAL '14 days')
                ) ON CONFLICT DO NOTHING;
                
                progress_count := progress_count + 1;
            END IF;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'âœ… Lesson Progress: Created % lesson progress records', progress_count;
END $$;

-- ============================================
-- COURSE REVIEWS - Diverse & Detailed
-- ============================================
DO $$
DECLARE
    enrollment_rec RECORD;
    review_count INT := 0;
    rating INT;
    review_text TEXT;
BEGIN
    -- Create reviews for completed courses
    FOR enrollment_rec IN 
        SELECT ce.user_id, ce.course_id, ce.completed_at, c.title
        FROM course_enrollments ce
        JOIN courses c ON c.id = ce.course_id
        WHERE ce.status = 'completed'
        AND (ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554401%'
            OR ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554402%'
            OR ce.user_id::text LIKE '550e8400-e29b-41d4-a716-4466554403%')
        AND RANDOM() < 0.6 -- 60% of completed courses get reviewed
        ORDER BY RANDOM()
        LIMIT 150
    LOOP
        -- Rating distribution: Most 4-5 stars, some 3 stars, rare 1-2 stars
        rating := CASE 
            WHEN RANDOM() < 0.5 THEN 5
            WHEN RANDOM() < 0.80 THEN 4
            WHEN RANDOM() < 0.95 THEN 3
            WHEN RANDOM() < 0.98 THEN 2
            ELSE 1
        END;
        
        -- Review text based on rating
        review_text := CASE 
            WHEN rating = 5 THEN 
                (ARRAY[
                    'Excellent course! The content is well-structured and easy to follow. Highly recommend for anyone preparing for IELTS.',
                    'Amazing! This course helped me improve from band 6.0 to 7.5. The exercises are realistic and very helpful.',
                    'Best IELTS course I''ve taken. The instructor explains concepts clearly and provides great examples.',
                    'Outstanding content and presentation. I feel much more confident about my upcoming IELTS test.',
                    'Perfect for self-study. The lessons are comprehensive and the practice exercises are very similar to actual IELTS questions.'
                ])[FLOOR(RANDOM() * 5 + 1)]
            WHEN rating = 4 THEN
                (ARRAY[
                    'Very good course overall. A few lessons could be more detailed, but generally excellent quality.',
                    'Great content! Would be 5 stars if there were more practice exercises for speaking.',
                    'Solid course with good explanations. The only downside is some videos are a bit long.',
                    'Really helpful for understanding IELTS format. Lost one star because I wish there were more writing samples.',
                    'Highly recommended! Just needs a few more advanced level exercises.'
                ])[FLOOR(RANDOM() * 5 + 1)]
            WHEN rating = 3 THEN
                (ARRAY[
                    'Decent course but nothing exceptional. Good for beginners but advanced learners might want more depth.',
                    'Average quality. Some lessons are great, others feel rushed. Still helpful overall.',
                    'The course covers the basics well, but I was expecting more advanced strategies.',
                    'It''s okay. Some good tips but could use more variety in exercise types.',
                    'Fair course for the price. Would benefit from more interactive elements.'
                ])[FLOOR(RANDOM() * 5 + 1)]
            WHEN rating = 2 THEN
                (ARRAY[
                    'Disappointed with the content depth. Expected more comprehensive coverage.',
                    'Not what I expected. Some lessons feel incomplete and lack detail.',
                    'Below average. The course needs major updates to be competitive.',
                    'Limited value. Would not recommend unless you''re a complete beginner.'
                ])[FLOOR(RANDOM() * 4 + 1)]
            ELSE
                (ARRAY[
                    'Very disappointing. The content is outdated and doesn''t match current IELTS format.',
                    'Waste of time. Better free resources available online.',
                    'Poor quality. Many errors in examples and unclear explanations.'
                ])[FLOOR(RANDOM() * 3 + 1)]
        END;
        
        INSERT INTO course_reviews (
            user_id, course_id, rating, review_text,
            helpful_count, created_at, updated_at
        ) VALUES (
            enrollment_rec.user_id,
            enrollment_rec.course_id,
            rating,
            review_text,
            (FLOOR(RANDOM() * 20))::INT, -- 0-19 people found it helpful
            enrollment_rec.completed_at + (RANDOM() * INTERVAL '7 days'),
            enrollment_rec.completed_at + (RANDOM() * INTERVAL '7 days')
        ) ON CONFLICT DO NOTHING;
        
        review_count := review_count + 1;
    END LOOP;
    
    RAISE NOTICE 'âœ… Course Reviews: Created % detailed reviews', review_count;
END $$;

-- ============================================
-- UPDATE COURSE STATISTICS
-- ============================================
DO $$
DECLARE
    course_rec RECORD;
BEGIN
    FOR course_rec IN 
        SELECT 
            c.id,
            COUNT(ce.id) as enrollment_count,
            COUNT(CASE WHEN ce.status = 'completed' THEN 1 END) as completion_count,
            ROUND(AVG(ce.progress_percentage), 1) as avg_progress,
            COUNT(cr.id) as review_count,
            ROUND(AVG(cr.rating), 2) as avg_rating
        FROM courses c
        LEFT JOIN course_enrollments ce ON ce.course_id = c.id
        LEFT JOIN course_reviews cr ON cr.course_id = c.id
        GROUP BY c.id
    LOOP
        UPDATE courses
        SET 
            enrollment_count = course_rec.enrollment_count,
            average_rating = course_rec.avg_rating,
            updated_at = NOW()
        WHERE id = course_rec.id;
    END LOOP;
    
    RAISE NOTICE 'âœ… Course Statistics: Updated enrollment and rating stats';
END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================
DO $$
DECLARE
    total_enrollments INT;
    active_enrollments INT;
    completed_enrollments INT;
    total_lesson_progress INT;
    completed_lessons INT;
    total_reviews INT;
    avg_rating NUMERIC;
    five_star INT;
    four_star INT;
    three_star INT;
BEGIN
    SELECT COUNT(*) INTO total_enrollments FROM course_enrollments;
    SELECT COUNT(*) INTO active_enrollments FROM course_enrollments WHERE status = 'in_progress';
    SELECT COUNT(*) INTO completed_enrollments FROM course_enrollments WHERE status = 'completed';
    SELECT COUNT(*) INTO total_lesson_progress FROM lesson_progress;
    SELECT COUNT(*) INTO completed_lessons FROM lesson_progress WHERE status = 'completed';
    SELECT COUNT(*) INTO total_reviews FROM course_reviews;
    SELECT ROUND(AVG(rating), 2) INTO avg_rating FROM course_reviews;
    SELECT COUNT(*) INTO five_star FROM course_reviews WHERE rating = 5;
    SELECT COUNT(*) INTO four_star FROM course_reviews WHERE rating = 4;
    SELECT COUNT(*) INTO three_star FROM course_reviews WHERE rating = 3;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'âœ… Course Activity Summary:';
    RAISE NOTICE '  Total enrollments: %', total_enrollments;
    RAISE NOTICE '  Active enrollments: %', active_enrollments;
    RAISE NOTICE '  Completed enrollments: %', completed_enrollments;
    RAISE NOTICE '  Total lesson progress: %', total_lesson_progress;
    RAISE NOTICE '  Completed lessons: %', completed_lessons;
    RAISE NOTICE '  Total reviews: %', total_reviews;
    RAISE NOTICE '  Average rating: % stars', avg_rating;
    RAISE NOTICE '  5-star reviews: %', five_star;
    RAISE NOTICE '  4-star reviews: %', four_star;
    RAISE NOTICE '  3-star reviews: %', three_star;
    RAISE NOTICE '============================================';
END $$;
