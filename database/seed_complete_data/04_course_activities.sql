-- ============================================
-- PHASE 3: COURSE_DB - USER ACTIVITIES
-- ============================================
-- Purpose: Create course enrollments, progress, reviews, and watch history
-- Database: course_db
-- 
-- Creates:
-- - Course enrollments
-- - Lesson progress
-- - Video watch history
-- - Course reviews
-- ============================================

-- ============================================
-- 1. COURSE_ENROLLMENTS
-- ============================================
-- Note: user_id references users from auth_db (not user_profiles from user_db)
-- IMPORTANT: Only use actual student user IDs from auth_db (f0000001 to f0000050)
-- This ensures tight coupling with auth_db users

-- Create CTE with actual student user IDs (matching auth_db pattern)
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
),
enrollment_data AS (
    SELECT 
        uuid_generate_v4() as id,
        su.user_id,
        c.id as course_id,
        NOW() - (random() * 90)::INTEGER * INTERVAL '1 day' as enrollment_date,
        CASE 
            WHEN c.enrollment_type = 'free' THEN 'free'
            WHEN random() > 0.3 THEN 'purchased'
            ELSE 'free'
        END as enrollment_type,
        CASE WHEN random() > 0.7 THEN uuid_generate_v4() ELSE NULL END as payment_id,
        CASE WHEN random() > 0.3 THEN c.price ELSE 0 END as amount_paid,
        c.currency,
        CASE WHEN random() > 0.3 THEN (random() * 100)::DECIMAL(5,2) ELSE (random() * 50)::DECIMAL(5,2) END as progress_percentage,
        CASE WHEN random() > 0.3 THEN (random() * c.total_lessons)::INTEGER ELSE 0 END as lessons_completed,
        CASE WHEN random() > 0.3 THEN (random() * (c.duration_hours * 60)::INTEGER)::INTEGER ELSE 0 END as total_time_spent_minutes,
        CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'active'
            WHEN 1 THEN 'completed'
            ELSE 'dropped'
        END as status_val,
        CASE WHEN random() > 0.7 THEN true ELSE false END as certificate_issued
    FROM courses c
    CROSS JOIN student_users su
    WHERE random() > 0.2 -- 80% chance for each enrollment
      AND c.status = 'published'
)
INSERT INTO course_enrollments (
    id, user_id, course_id, enrollment_date, enrollment_type,
    payment_id, amount_paid, currency, progress_percentage,
    lessons_completed, total_time_spent_minutes, status,
    completed_at, certificate_issued, last_accessed_at
)
SELECT 
    ed.id,
    ed.user_id,
    ed.course_id,
    ed.enrollment_date,
    ed.enrollment_type,
    ed.payment_id,
    ed.amount_paid,
    ed.currency,
    ed.progress_percentage,
    ed.lessons_completed,
    ed.total_time_spent_minutes,
    ed.status_val,
    -- completed_at: ONLY when status = 'completed', MUST be AFTER enrollment_date and BEFORE NOW
    CASE WHEN ed.status_val = 'completed' THEN 
        LEAST(
            ed.enrollment_date + (random() * EXTRACT(EPOCH FROM (NOW() - ed.enrollment_date)) / 86400)::INTEGER * INTERVAL '1 day',
            NOW() - INTERVAL '1 second'
        )
    ELSE NULL END,
    ed.certificate_issued,
    -- last_accessed_at: MUST be >= enrollment_date, = completed_at if completed, <= NOW
    CASE 
        WHEN ed.status_val = 'completed' THEN
            LEAST(
                ed.enrollment_date + (random() * EXTRACT(EPOCH FROM (NOW() - ed.enrollment_date)) / 86400)::INTEGER * INTERVAL '1 day',
                NOW()
            )
        ELSE
            LEAST(
                ed.enrollment_date + (random() * EXTRACT(EPOCH FROM (NOW() - ed.enrollment_date)) / 86400)::INTEGER * INTERVAL '1 day',
                NOW()
            )
    END
FROM enrollment_data ed
ON CONFLICT (user_id, course_id) DO NOTHING;

-- ============================================
-- 2. LESSON_PROGRESS
-- ============================================

INSERT INTO lesson_progress (
    id, user_id, lesson_id, course_id, status,
    progress_percentage, video_watched_seconds, video_total_seconds,
    completed_at, first_accessed_at, last_accessed_at
)
SELECT 
    uuid_generate_v4(),
    ce.user_id,
    l.id,
    l.course_id,
    status_val,
    CASE 
        WHEN status_val = 'completed' THEN (random() * 20 + 80)::DECIMAL(5,2)
        WHEN status_val = 'in_progress' THEN (random() * 50 + 30)::DECIMAL(5,2)
        ELSE 0
    END,
    CASE WHEN l.content_type = 'video' AND status_val != 'not_started' AND random() > 0.3 THEN
        (random() * 600 + 60)::INTEGER
    ELSE 0 END,
    CASE WHEN l.content_type = 'video' THEN
        (l.duration_minutes * 60)::INTEGER
    ELSE NULL END,
    -- completed_at: ONLY when status = 'completed', MUST be AFTER first_accessed_at and BEFORE NOW
    CASE WHEN status_val = 'completed' THEN
        LEAST(
            GREATEST(
                first_accessed_at + (random() * EXTRACT(EPOCH FROM (NOW() - first_accessed_at)) / 3600)::INTEGER * INTERVAL '1 hour',
                first_accessed_at + INTERVAL '1 hour'
            ),
            NOW() - INTERVAL '1 second'
        )
    ELSE NULL END,
    -- first_accessed_at: MUST be AFTER enrollment_date
    first_accessed_at,
    -- last_accessed_at: MUST be >= first_accessed_at, = completed_at if completed, <= NOW
    CASE 
        WHEN status_val = 'completed' THEN 
            LEAST(
                GREATEST(completed_at_val, first_accessed_at),
                NOW()
            )
        WHEN status_val = 'in_progress' THEN 
            LEAST(
                GREATEST(
                    first_accessed_at + (random() * EXTRACT(EPOCH FROM (NOW() - first_accessed_at)) / 3600)::INTEGER * INTERVAL '1 hour',
                    first_accessed_at
                ),
                NOW()
            )
        ELSE first_accessed_at
    END
FROM course_enrollments ce
JOIN lessons l ON l.course_id = ce.course_id
CROSS JOIN LATERAL (
    SELECT 
        CASE 
            WHEN random() > 0.5 THEN 'completed'
            WHEN random() > 0.3 THEN 'in_progress'
            ELSE 'not_started'
        END as status_val,
        -- first_accessed_at: after enrollment_date, within reasonable time (max 90 days)
        ce.enrollment_date + (random() * LEAST(EXTRACT(EPOCH FROM (NOW() - ce.enrollment_date)) / 86400, 90)::INTEGER)::INTEGER * INTERVAL '1 day' as first_accessed_at,
        -- completed_at: only for completed status, MUST be after first_accessed_at and BEFORE NOW
        -- This will be recalculated based on actual first_accessed_at value
        CASE WHEN random() > 0.5 THEN
            ce.enrollment_date + (random() * LEAST(EXTRACT(EPOCH FROM (NOW() - ce.enrollment_date)) / 86400, 90)::INTEGER)::INTEGER * INTERVAL '1 day' +
            (random() * 30 + 1)::INTEGER * INTERVAL '1 day'
        ELSE NULL END as completed_at_val
) AS progress_data
WHERE ce.status IN ('active', 'completed')
  AND random() > 0.15 -- 85% of enrolled users progress through lessons
LIMIT 4000;

-- ============================================
-- 3. VIDEO_WATCH_HISTORY
-- ============================================

INSERT INTO video_watch_history (
    id, user_id, video_id, lesson_id, watched_seconds,
    total_seconds, watch_percentage, session_id, device_type, watched_at
)
SELECT 
    uuid_generate_v4(),
    lp.user_id,
    lv.id,
    lv.lesson_id,
    watched_seconds_val,
    lv.duration_seconds,
    -- Calculate watch_percentage correctly based on watched_seconds / total_seconds
    ROUND((watched_seconds_val::numeric / NULLIF(lv.duration_seconds, 0) * 100)::numeric, 2),
    uuid_generate_v4(),
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'web' WHEN 1 THEN 'android' ELSE 'ios' END,
    -- watched_at must be AFTER first_accessed_at and BEFORE last_accessed_at (or NOW if not completed)
    lp.first_accessed_at + (random() * EXTRACT(EPOCH FROM (COALESCE(lp.last_accessed_at, NOW()) - lp.first_accessed_at)))::INTEGER * INTERVAL '1 second'
FROM lesson_progress lp
JOIN lessons l ON l.id = lp.lesson_id
JOIN lesson_videos lv ON lv.lesson_id = l.id
CROSS JOIN LATERAL (
    SELECT 
        CASE 
            WHEN random() > 0.3 THEN (random() * (lv.duration_seconds - 60) + 60)::INTEGER
            ELSE (random() * LEAST(300, lv.duration_seconds * 0.5))::INTEGER
        END as watched_seconds_val
) w
WHERE lp.status IN ('in_progress', 'completed')
  AND l.content_type = 'video'
  AND lp.first_accessed_at IS NOT NULL
  AND lv.duration_seconds > 0
  AND random() > 0.3 -- 70% of video lessons have watch history
LIMIT 3000;

-- ============================================
-- 4. COURSE_REVIEWS
-- ============================================
-- IMPORTANT: Only create reviews from users who have actually enrolled
-- Reviews must be created AFTER enrollment (at least 7 days after)
-- This ensures tight coupling: course_reviews -> course_enrollments -> courses

INSERT INTO course_reviews (
    id, user_id, course_id, rating, title, comment,
    helpful_count, is_approved, approved_by, approved_at, created_at
)
SELECT 
    uuid_generate_v4(),
    ce.user_id,
    ce.course_id,
    -- Weighted distribution: more 4-5 stars
    CASE 
        WHEN random() > 0.7 THEN 5
        WHEN random() > 0.4 THEN 4
        WHEN random() > 0.2 THEN 3
        WHEN random() > 0.1 THEN 2
        ELSE 1
    END,
    CASE (random() * 35)::INTEGER
        WHEN 0 THEN 'Excellent course!'
        WHEN 1 THEN 'Very helpful content'
        WHEN 2 THEN 'Great instructor'
        WHEN 3 THEN 'Highly recommended'
        WHEN 4 THEN 'Good for beginners'
        WHEN 5 THEN 'Comprehensive and well-structured'
        WHEN 6 THEN 'Practical and effective'
        WHEN 7 THEN 'Worth every penny'
        WHEN 8 THEN 'Game changer for my IELTS prep'
        WHEN 9 THEN 'Clear and concise explanations'
        WHEN 10 THEN 'Perfect pace for learning'
        WHEN 11 THEN 'Real exam-like practice materials'
        WHEN 12 THEN 'Excellent feedback and support'
        WHEN 13 THEN 'Helped me achieve my target score'
        WHEN 14 THEN 'Well-organized content'
        WHEN 15 THEN 'Professional and engaging'
        WHEN 16 THEN 'Best IELTS course I''ve taken'
        WHEN 17 THEN 'Great value for money'
        WHEN 18 THEN 'Improvement guaranteed'
        WHEN 19 THEN 'Teacher explains everything clearly'
        WHEN 20 THEN 'Perfect for self-study'
        WHEN 21 THEN 'Comprehensive practice tests'
        WHEN 22 THEN 'Detailed answer explanations'
        WHEN 23 THEN 'Strategies that actually work'
        WHEN 24 THEN 'Easy to follow and understand'
        WHEN 25 THEN 'Boosted my confidence significantly'
        WHEN 26 THEN 'Real-world examples included'
        WHEN 27 THEN 'Step-by-step guidance'
        WHEN 28 THEN 'Covers all question types'
        WHEN 29 THEN 'Interactive and engaging'
        WHEN 30 THEN 'Thorough preparation materials'
        WHEN 31 THEN 'Expert teaching methods'
        WHEN 32 THEN 'Worth the investment'
        WHEN 33 THEN 'Achieved Band 7.5 thanks to this course'
        ELSE 'Exceeded my expectations'
    END,
    CASE (random() * 45)::INTEGER
        WHEN 0 THEN 'KhÃ³a há»c ráº¥t hay vÃ  há»¯u Ã­ch. TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c nhiá»u Ä‘iá»u má»›i. Giáº£ng viÃªn giáº£i thÃ­ch ráº¥t rÃµ rÃ ng vÃ  dá»… hiá»ƒu. CÃ¡c bÃ i táº­p thá»±c hÃ nh giÃºp tÃ´i cáº£i thiá»‡n Ä‘Ã¡ng ká»ƒ. Äáº·c biá»‡t thÃ­ch pháº§n giáº£i thÃ­ch chi tiáº¿t tá»«ng Ä‘Ã¡p Ã¡n.'
        WHEN 1 THEN 'Content is comprehensive and well-structured. The practice exercises are very helpful. I improved my score significantly after taking this course. My listening score jumped from 6.0 to 7.5. Highly recommend to anyone serious about IELTS!'
        WHEN 2 THEN 'The course covers all the essential topics. Video quality is excellent and subtitles are accurate. The instructor speaks clearly and uses real exam examples. Worth every penny!'
        WHEN 3 THEN 'Giáº£ng viÃªn nhiá»‡t tÃ¬nh, bÃ i giáº£ng cháº¥t lÆ°á»£ng cao. TÃ´i Ä‘Ã£ Ä‘áº¡t Ä‘Æ°á»£c má»¥c tiÃªu band 7.0 nhá» khÃ³a há»c nÃ y. CÃ¡c tips vÃ  strategies ráº¥t thá»±c táº¿ vÃ  Ã¡p dá»¥ng Ä‘Æ°á»£c ngay. Cáº£m Æ¡n ráº¥t nhiá»u!'
        WHEN 4 THEN 'Good course for beginners. The explanations are clear and the pace is comfortable. However, some advanced topics could be explained in more detail. Overall satisfied with the content and would recommend to others.'
        WHEN 5 THEN 'The course helped me understand IELTS format better. Practice tests are very similar to real exams - this was crucial for my preparation. Great preparation material with realistic expectations.'
        WHEN 6 THEN 'KhÃ³a há»c tá»‘t nhÆ°ng má»™t sá»‘ bÃ i há»c cÃ³ thá»ƒ cáº£i thiá»‡n thÃªm vá» cháº¥t lÆ°á»£ng video. NÃ³i chung lÃ  Ä‘Ã¡ng giÃ¡ vÃ  há»¯u Ã­ch cho ngÆ°á»i má»›i báº¯t Ä‘áº§u. TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c nhiá»u tá»« vá»±ng vÃ  ngá»¯ phÃ¡p quan trá»ng.'
        WHEN 7 THEN 'Clear explanations and good examples throughout. The instructor speaks clearly and uses helpful visual aids. Very professional approach. The practice exercises are challenging but manageable.'
        WHEN 8 THEN 'I recommend this course to anyone preparing for IELTS. The strategies taught are very effective and easy to apply. My listening score improved from 6.0 to 7.5 after 2 months of consistent practice.'
        WHEN 9 THEN 'The course materials are comprehensive and well-organized. I especially like the downloadable resources and practice exercises. The answer keys with explanations are incredibly helpful for self-study.'
        WHEN 10 THEN 'Tuyá»‡t vá»i! KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i tá»± tin hÆ¡n ráº¥t nhiá»u. Giáº£ng viÃªn há»— trá»£ nhiá»‡t tÃ¬nh vÃ  giáº£i Ä‘Ã¡p má»i tháº¯c máº¯c nhanh chÃ³ng. Cá»™ng Ä‘á»“ng há»c viÃªn cÅ©ng ráº¥t tÃ­ch cá»±c vÃ  há»— trá»£ láº«n nhau.'
        WHEN 11 THEN 'Perfect for self-study. The video lessons are well-paced and the exercises are challenging but manageable. Great value for money! I completed the course in 6 weeks and felt much more confident.'
        WHEN 12 THEN 'KhÃ³a há»c cÃ³ cáº¥u trÃºc logic, dá»… theo dÃµi tá»« Ä‘áº§u Ä‘áº¿n cuá»‘i. TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c nhiá»u tips vÃ  tricks há»¯u Ã­ch mÃ  khÃ´ng tháº¥y á»Ÿ cÃ¡c khÃ³a há»c khÃ¡c. Äáº·c biá»‡t pháº§n phÃ¢n tÃ­ch lá»—i sai ráº¥t chi tiáº¿t.'
        WHEN 13 THEN 'Excellent course structure. The step-by-step approach really helped me understand complex topics. My reading score improved significantly from 6.5 to 8.0. The passage analysis techniques are game-changing.'
        WHEN 14 THEN 'Great course overall. The content is relevant and up-to-date. Would love to see more advanced content added in the future. Keep up the good work! The instructor''s teaching style is engaging and effective.'
        WHEN 15 THEN 'After completing this course, I felt much more prepared for the actual exam. The mock tests are very realistic and the feedback provided is constructive. My writing improved from 5.5 to 7.0!'
        WHEN 16 THEN 'KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i vÆ°á»£t qua ná»—i sá»£ hÃ£i vá» IELTS. CÃ¡c bÃ i há»c Ä‘Æ°á»£c thiáº¿t káº¿ ráº¥t khoa há»c, tá»« cÆ¡ báº£n Ä‘áº¿n nÃ¢ng cao. TÃ´i Ä‘áº·c biá»‡t thÃ­ch pháº§n luyá»‡n táº­p vá»›i audio cháº¥t lÆ°á»£ng cao.'
        WHEN 17 THEN 'The course exceeded my expectations. Every lesson is packed with valuable information. The practice questions are challenging and closely mirror the actual exam format. Worth every cent!'
        WHEN 18 THEN 'TÃ´i Ä‘Ã£ thá»­ nhiá»u khÃ³a há»c IELTS nhÆ°ng khÃ³a nÃ y lÃ  tá»‘t nháº¥t. Giáº£ng viÃªn cÃ³ kinh nghiá»‡m vÃ  biáº¿t cÃ¡ch truyá»n Ä‘áº¡t kiáº¿n thá»©c. CÃ¡c vÃ­ dá»¥ thá»±c táº¿ giÃºp tÃ´i hiá»ƒu sÃ¢u hÆ¡n vá» cÃ¡ch lÃ m bÃ i.'
        WHEN 19 THEN 'This course is perfect for intermediate learners. The content is comprehensive without being overwhelming. I appreciated the detailed explanations for each question type. My speaking confidence improved dramatically.'
        WHEN 20 THEN 'KhÃ³a há»c ráº¥t thá»±c táº¿ vÃ  Ã¡p dá»¥ng Ä‘Æ°á»£c ngay. TÃ´i Ä‘Ã£ Ã¡p dá»¥ng cÃ¡c strategies vÃ o bÃ i thi tháº­t vÃ  Ä‘áº¡t Ä‘Æ°á»£c káº¿t quáº£ tá»‘t. Cáº£m Æ¡n giáº£ng viÃªn vÃ  team Ä‘Ã£ táº¡o ra khÃ³a há»c cháº¥t lÆ°á»£ng nhÆ° váº­y.'
        WHEN 21 THEN 'The course materials are professionally prepared. I liked how each module builds upon the previous one. The practice tests are excellent preparation for the real exam. Highly recommend!'
        WHEN 22 THEN 'TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c ráº¥t nhiá»u tá»« khÃ³a há»c nÃ y. CÃ¡c bÃ i giáº£ng ngáº¯n gá»n nhÆ°ng Ä‘áº§y Ä‘á»§ thÃ´ng tin. Giáº£ng viÃªn giáº£i thÃ­ch rÃµ rÃ ng vÃ  cÃ³ nhiá»u vÃ­ dá»¥ minh há»a. ÄÃ¢y lÃ  khoáº£n Ä‘áº§u tÆ° Ä‘Ã¡ng giÃ¡.'
        WHEN 23 THEN 'Excellent course! The instructor breaks down complex topics into simple, digestible parts. The practice exercises are relevant and the answer explanations are thorough. My overall band score improved by 1.0!'
        WHEN 24 THEN 'KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i hiá»ƒu rÃµ format vÃ  yÃªu cáº§u cá»§a tá»«ng pháº§n thi IELTS. CÃ¡c chiáº¿n lÆ°á»£c lÃ m bÃ i ráº¥t hiá»‡u quáº£. TÃ´i Ä‘áº·c biá»‡t thÃ­ch pháº§n luyá»‡n táº­p vá»›i Ä‘á» thi tháº­t tá»« Cambridge.'
        WHEN 25 THEN 'The course is well-structured and covers all aspects of IELTS preparation. The video lessons are engaging and the practice materials are comprehensive. I felt much more confident after completing this course.'
        WHEN 26 THEN 'Tuyá»‡t vá»i! KhÃ³a há»c nÃ y phÃ¹ há»£p vá»›i cáº£ ngÆ°á»i má»›i báº¯t Ä‘áº§u vÃ  ngÆ°á»i Ä‘Ã£ cÃ³ ná»n táº£ng. TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c nhiá»u tá»« vá»±ng há»c thuáº­t vÃ  cÃ¡ch sá»­ dá»¥ng chÃºng trong bÃ i thi. Ráº¥t hÃ i lÃ²ng!'
        WHEN 27 THEN 'This course provides excellent value. The instructor is knowledgeable and the content is up-to-date with current IELTS trends. The practice tests helped me identify my weak areas. Highly recommended!'
        WHEN 28 THEN 'KhÃ³a há»c cÃ³ nhiá»u Ä‘iá»ƒm máº¡nh: ná»™i dung Ä‘a dáº¡ng, giáº£ng viÃªn nhiá»‡t tÃ¬nh, bÃ i táº­p thá»±c hÃ nh phong phÃº. TÃ´i Ä‘Ã£ cáº£i thiá»‡n Ä‘Æ°á»£c Ä‘iá»ƒm sá»‘ Ä‘Ã¡ng ká»ƒ. ÄÃ¢y lÃ  khÃ³a há»c tá»‘t nháº¥t mÃ  tÃ´i tá»«ng há»c.'
        WHEN 29 THEN 'The course helped me develop a systematic approach to IELTS preparation. The step-by-step guidance is invaluable. My reading comprehension improved significantly, and I can now handle complex passages confidently.'
        WHEN 30 THEN 'TÃ´i ráº¥t hÃ i lÃ²ng vá»›i khÃ³a há»c nÃ y. CÃ¡c bÃ i giáº£ng Ä‘Æ°á»£c chuáº©n bá»‹ ká»¹ lÆ°á»¡ng, tá»« vá»±ng vÃ  ngá»¯ phÃ¡p Ä‘Æ°á»£c giáº£i thÃ­ch chi tiáº¿t. Giáº£ng viÃªn luÃ´n sáºµn sÃ ng há»— trá»£ há»c viÃªn. Cáº£m Æ¡n ráº¥t nhiá»u!'
        WHEN 31 THEN 'This course is a game-changer for IELTS preparation. The strategies taught are practical and immediately applicable. I improved my writing from 6.0 to 7.5 after following the course recommendations.'
        WHEN 32 THEN 'KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i Ä‘áº¡t Ä‘Æ°á»£c má»¥c tiÃªu band 7.0. CÃ¡c bÃ i há»c Ä‘Æ°á»£c sáº¯p xáº¿p há»£p lÃ½, tá»« dá»… Ä‘áº¿n khÃ³. TÃ´i Ä‘áº·c biá»‡t thÃ­ch pháº§n luyá»‡n táº­p vá»›i nhiá»u Ä‘á» thi Ä‘a dáº¡ng. Ráº¥t Ä‘Ã¡ng há»c!'
        WHEN 33 THEN 'The course content is comprehensive and well-researched. The instructor provides clear explanations and practical tips. The practice exercises are challenging but achievable. Great investment for IELTS preparation!'
        WHEN 34 THEN 'TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c ráº¥t nhiá»u tá»« khÃ³a há»c nÃ y. CÃ¡c chiáº¿n lÆ°á»£c lÃ m bÃ i ráº¥t hiá»‡u quáº£ vÃ  dá»… Ã¡p dá»¥ng. Giáº£ng viÃªn cÃ³ kinh nghiá»‡m vÃ  biáº¿t cÃ¡ch truyá»n Ä‘áº¡t kiáº¿n thá»©c má»™t cÃ¡ch dá»… hiá»ƒu nháº¥t.'
        WHEN 35 THEN 'This course exceeded my expectations. The quality of the content is excellent and the instructor is very knowledgeable. I appreciated the detailed feedback on practice exercises. My confidence level increased significantly.'
        WHEN 36 THEN 'KhÃ³a há»c nÃ y phÃ¹ há»£p vá»›i má»i trÃ¬nh Ä‘á»™. TÃ´i Ä‘Ã£ báº¯t Ä‘áº§u tá»« Band 5.5 vÃ  Ä‘áº¡t Ä‘Æ°á»£c 7.0 sau khi hoÃ n thÃ nh khÃ³a há»c. CÃ¡c bÃ i giáº£ng ráº¥t chi tiáº¿t vÃ  cÃ³ nhiá»u vÃ­ dá»¥ minh há»a cá»¥ thá»ƒ.'
        WHEN 37 THEN 'The course structure is logical and easy to follow. Each module focuses on specific skills and provides ample practice opportunities. The mock tests are realistic and helped me prepare effectively for the exam.'
        WHEN 38 THEN 'TÃ´i ráº¥t biáº¿t Æ¡n khÃ³a há»c nÃ y. CÃ¡c tips vÃ  tricks Ä‘Æ°á»£c chia sáº» ráº¥t thá»±c táº¿ vÃ  há»¯u Ã­ch. TÃ´i Ä‘Ã£ Ã¡p dá»¥ng vÃ o bÃ i thi vÃ  Ä‘áº¡t Ä‘Æ°á»£c káº¿t quáº£ tá»‘t. ÄÃ¢y lÃ  khÃ³a há»c tá»‘t nháº¥t mÃ  tÃ´i tá»«ng há»c.'
        WHEN 39 THEN 'This course is perfect for anyone serious about IELTS. The content is comprehensive, the instruction is clear, and the practice materials are excellent. I improved my overall score by 1.5 bands!'
        WHEN 40 THEN 'KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i hiá»ƒu rÃµ hÆ¡n vá» cáº¥u trÃºc bÃ i thi IELTS. CÃ¡c bÃ i táº­p thá»±c hÃ nh ráº¥t Ä‘a dáº¡ng vÃ  phong phÃº. Giáº£ng viÃªn giáº£i thÃ­ch rÃµ rÃ ng vÃ  cÃ³ nhiá»u vÃ­ dá»¥ minh há»a cá»¥ thá»ƒ.'
        WHEN 41 THEN 'The course provides excellent preparation for IELTS. The instructor is experienced and the content is well-organized. I particularly liked the detailed explanations for each question type. Highly recommend!'
        WHEN 42 THEN 'TÃ´i Ä‘Ã£ há»c Ä‘Æ°á»£c ráº¥t nhiá»u tá»« khÃ³a há»c nÃ y. CÃ¡c chiáº¿n lÆ°á»£c lÃ m bÃ i ráº¥t hiá»‡u quáº£ vÃ  dá»… Ã¡p dá»¥ng. Giáº£ng viÃªn cÃ³ kinh nghiá»‡m vÃ  biáº¿t cÃ¡ch truyá»n Ä‘áº¡t kiáº¿n thá»©c má»™t cÃ¡ch dá»… hiá»ƒu nháº¥t.'
        WHEN 43 THEN 'This course is worth every penny. The quality of instruction is excellent and the practice materials are comprehensive. I felt much more confident after completing this course and achieved my target score.'
        ELSE 'KhÃ³a há»c nÃ y Ä‘Ã£ giÃºp tÃ´i Ä‘áº¡t Ä‘Æ°á»£c má»¥c tiÃªu cá»§a mÃ¬nh. CÃ¡c bÃ i giáº£ng cháº¥t lÆ°á»£ng cao vÃ  cÃ³ nhiá»u vÃ­ dá»¥ thá»±c táº¿. TÃ´i Ä‘áº·c biá»‡t thÃ­ch pháº§n luyá»‡n táº­p vá»›i nhiá»u Ä‘á» thi Ä‘a dáº¡ng. Ráº¥t Ä‘Ã¡ng há»c!'
    END,
    (random() * 25)::INTEGER,
    is_approved_val,
    -- If approved, must have approved_by and approved_at
    CASE WHEN is_approved_val THEN 'a0000001-0000-0000-0000-000000000001'::uuid ELSE NULL END,
    CASE WHEN is_approved_val THEN created_at_val + INTERVAL '1 day' ELSE NULL END,
    -- Reviews MUST be created after enrollment (at least 7 days after)
    -- This ensures users have actually used the course before reviewing
    created_at_val
FROM course_enrollments ce
JOIN courses c ON c.id = ce.course_id
CROSS JOIN LATERAL (
    SELECT 
        CASE WHEN random() > 0.2 THEN true ELSE false END as is_approved_val,
        ce.enrollment_date + INTERVAL '7 days' + 
        (random() * (NOW() - ce.enrollment_date - INTERVAL '7 days'))::INTERVAL as created_at_val
) review_data
WHERE ce.status IN ('active', 'completed')
  -- Only users enrolled at least 7 days ago can write reviews
  AND ce.enrollment_date < NOW() - INTERVAL '7 days'
  -- 50% of eligible enrolled users write reviews
  AND random() > 0.5
  -- Ensure one review per user per course
  AND NOT EXISTS (
      SELECT 1 FROM course_reviews cr 
      WHERE cr.user_id = ce.user_id AND cr.course_id = ce.course_id
  )
ORDER BY random()
LIMIT 200;

-- Update course statistics based on actual reviews
UPDATE courses c
SET 
    total_reviews = (
        SELECT COUNT(*) 
        FROM course_reviews cr 
        WHERE cr.course_id = c.id AND cr.is_approved = true
    ),
    average_rating = (
        SELECT COALESCE(AVG(rating), 0)
        FROM course_reviews cr
        WHERE cr.course_id = c.id AND cr.is_approved = true
    ),
    total_enrollments = (
        SELECT COUNT(*)
        FROM course_enrollments ce
        WHERE ce.course_id = c.id
    );

-- Fix course enrollments: completed status must have progress_percentage = 100
UPDATE course_enrollments ce
SET progress_percentage = 100
WHERE ce.status = 'completed' AND ce.progress_percentage < 100;

-- Fix lesson progress: completed status should have progress_percentage >= 80
UPDATE lesson_progress lp
SET progress_percentage = GREATEST(80, lp.progress_percentage)
WHERE lp.status = 'completed' AND lp.progress_percentage < 80;

-- Fix video watch history: recalculate watch_percentage if incorrect
UPDATE video_watch_history vwh
SET watch_percentage = ROUND((vwh.watched_seconds::numeric / NULLIF(vwh.total_seconds, 0) * 100)::numeric, 2)
WHERE vwh.total_seconds > 0 
  AND (vwh.watch_percentage IS NULL 
       OR ABS(vwh.watch_percentage - (vwh.watched_seconds::numeric / NULLIF(vwh.total_seconds, 0) * 100)) > 0.01);

-- Summary
SELECT 
    'âœ… Phase 3 Complete: Course Activities Created' as status,
    (SELECT COUNT(*) FROM course_enrollments) as total_enrollments,
    (SELECT COUNT(*) FROM lesson_progress) as total_lesson_progress,
    (SELECT COUNT(*) FROM video_watch_history) as total_watch_history,
    (SELECT COUNT(*) FROM course_reviews) as total_reviews;

