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
        WHEN 0 THEN 'Khóa học rất hay và hữu ích. Tôi đã học được nhiều điều mới. Giảng viên giải thích rất rõ ràng và dễ hiểu. Các bài tập thực hành giúp tôi cải thiện đáng kể. Đặc biệt thích phần giải thích chi tiết từng đáp án.'
        WHEN 1 THEN 'Content is comprehensive and well-structured. The practice exercises are very helpful. I improved my score significantly after taking this course. My listening score jumped from 6.0 to 7.5. Highly recommend to anyone serious about IELTS!'
        WHEN 2 THEN 'The course covers all the essential topics. Video quality is excellent and subtitles are accurate. The instructor speaks clearly and uses real exam examples. Worth every penny!'
        WHEN 3 THEN 'Giảng viên nhiệt tình, bài giảng chất lượng cao. Tôi đã đạt được mục tiêu band 7.0 nhờ khóa học này. Các tips và strategies rất thực tế và áp dụng được ngay. Cảm ơn rất nhiều!'
        WHEN 4 THEN 'Good course for beginners. The explanations are clear and the pace is comfortable. However, some advanced topics could be explained in more detail. Overall satisfied with the content and would recommend to others.'
        WHEN 5 THEN 'The course helped me understand IELTS format better. Practice tests are very similar to real exams - this was crucial for my preparation. Great preparation material with realistic expectations.'
        WHEN 6 THEN 'Khóa học tốt nhưng một số bài học có thể cải thiện thêm về chất lượng video. Nói chung là đáng giá và hữu ích cho người mới bắt đầu. Tôi đã học được nhiều từ vựng và ngữ pháp quan trọng.'
        WHEN 7 THEN 'Clear explanations and good examples throughout. The instructor speaks clearly and uses helpful visual aids. Very professional approach. The practice exercises are challenging but manageable.'
        WHEN 8 THEN 'I recommend this course to anyone preparing for IELTS. The strategies taught are very effective and easy to apply. My listening score improved from 6.0 to 7.5 after 2 months of consistent practice.'
        WHEN 9 THEN 'The course materials are comprehensive and well-organized. I especially like the downloadable resources and practice exercises. The answer keys with explanations are incredibly helpful for self-study.'
        WHEN 10 THEN 'Tuyệt vời! Khóa học này đã giúp tôi tự tin hơn rất nhiều. Giảng viên hỗ trợ nhiệt tình và giải đáp mọi thắc mắc nhanh chóng. Cộng đồng học viên cũng rất tích cực và hỗ trợ lẫn nhau.'
        WHEN 11 THEN 'Perfect for self-study. The video lessons are well-paced and the exercises are challenging but manageable. Great value for money! I completed the course in 6 weeks and felt much more confident.'
        WHEN 12 THEN 'Khóa học có cấu trúc logic, dễ theo dõi từ đầu đến cuối. Tôi đã học được nhiều tips và tricks hữu ích mà không thấy ở các khóa học khác. Đặc biệt phần phân tích lỗi sai rất chi tiết.'
        WHEN 13 THEN 'Excellent course structure. The step-by-step approach really helped me understand complex topics. My reading score improved significantly from 6.5 to 8.0. The passage analysis techniques are game-changing.'
        WHEN 14 THEN 'Great course overall. The content is relevant and up-to-date. Would love to see more advanced content added in the future. Keep up the good work! The instructor''s teaching style is engaging and effective.'
        WHEN 15 THEN 'After completing this course, I felt much more prepared for the actual exam. The mock tests are very realistic and the feedback provided is constructive. My writing improved from 5.5 to 7.0!'
        WHEN 16 THEN 'Khóa học này đã giúp tôi vượt qua nỗi sợ hãi về IELTS. Các bài học được thiết kế rất khoa học, từ cơ bản đến nâng cao. Tôi đặc biệt thích phần luyện tập với audio chất lượng cao.'
        WHEN 17 THEN 'The course exceeded my expectations. Every lesson is packed with valuable information. The practice questions are challenging and closely mirror the actual exam format. Worth every cent!'
        WHEN 18 THEN 'Tôi đã thử nhiều khóa học IELTS nhưng khóa này là tốt nhất. Giảng viên có kinh nghiệm và biết cách truyền đạt kiến thức. Các ví dụ thực tế giúp tôi hiểu sâu hơn về cách làm bài.'
        WHEN 19 THEN 'This course is perfect for intermediate learners. The content is comprehensive without being overwhelming. I appreciated the detailed explanations for each question type. My speaking confidence improved dramatically.'
        WHEN 20 THEN 'Khóa học rất thực tế và áp dụng được ngay. Tôi đã áp dụng các strategies vào bài thi thật và đạt được kết quả tốt. Cảm ơn giảng viên và team đã tạo ra khóa học chất lượng như vậy.'
        WHEN 21 THEN 'The course materials are professionally prepared. I liked how each module builds upon the previous one. The practice tests are excellent preparation for the real exam. Highly recommend!'
        WHEN 22 THEN 'Tôi đã học được rất nhiều từ khóa học này. Các bài giảng ngắn gọn nhưng đầy đủ thông tin. Giảng viên giải thích rõ ràng và có nhiều ví dụ minh họa. Đây là khoản đầu tư đáng giá.'
        WHEN 23 THEN 'Excellent course! The instructor breaks down complex topics into simple, digestible parts. The practice exercises are relevant and the answer explanations are thorough. My overall band score improved by 1.0!'
        WHEN 24 THEN 'Khóa học này đã giúp tôi hiểu rõ format và yêu cầu của từng phần thi IELTS. Các chiến lược làm bài rất hiệu quả. Tôi đặc biệt thích phần luyện tập với đề thi thật từ Cambridge.'
        WHEN 25 THEN 'The course is well-structured and covers all aspects of IELTS preparation. The video lessons are engaging and the practice materials are comprehensive. I felt much more confident after completing this course.'
        WHEN 26 THEN 'Tuyệt vời! Khóa học này phù hợp với cả người mới bắt đầu và người đã có nền tảng. Tôi đã học được nhiều từ vựng học thuật và cách sử dụng chúng trong bài thi. Rất hài lòng!'
        WHEN 27 THEN 'This course provides excellent value. The instructor is knowledgeable and the content is up-to-date with current IELTS trends. The practice tests helped me identify my weak areas. Highly recommended!'
        WHEN 28 THEN 'Khóa học có nhiều điểm mạnh: nội dung đa dạng, giảng viên nhiệt tình, bài tập thực hành phong phú. Tôi đã cải thiện được điểm số đáng kể. Đây là khóa học tốt nhất mà tôi từng học.'
        WHEN 29 THEN 'The course helped me develop a systematic approach to IELTS preparation. The step-by-step guidance is invaluable. My reading comprehension improved significantly, and I can now handle complex passages confidently.'
        WHEN 30 THEN 'Tôi rất hài lòng với khóa học này. Các bài giảng được chuẩn bị kỹ lưỡng, từ vựng và ngữ pháp được giải thích chi tiết. Giảng viên luôn sẵn sàng hỗ trợ học viên. Cảm ơn rất nhiều!'
        WHEN 31 THEN 'This course is a game-changer for IELTS preparation. The strategies taught are practical and immediately applicable. I improved my writing from 6.0 to 7.5 after following the course recommendations.'
        WHEN 32 THEN 'Khóa học này đã giúp tôi đạt được mục tiêu band 7.0. Các bài học được sắp xếp hợp lý, từ dễ đến khó. Tôi đặc biệt thích phần luyện tập với nhiều đề thi đa dạng. Rất đáng học!'
        WHEN 33 THEN 'The course content is comprehensive and well-researched. The instructor provides clear explanations and practical tips. The practice exercises are challenging but achievable. Great investment for IELTS preparation!'
        WHEN 34 THEN 'Tôi đã học được rất nhiều từ khóa học này. Các chiến lược làm bài rất hiệu quả và dễ áp dụng. Giảng viên có kinh nghiệm và biết cách truyền đạt kiến thức một cách dễ hiểu nhất.'
        WHEN 35 THEN 'This course exceeded my expectations. The quality of the content is excellent and the instructor is very knowledgeable. I appreciated the detailed feedback on practice exercises. My confidence level increased significantly.'
        WHEN 36 THEN 'Khóa học này phù hợp với mọi trình độ. Tôi đã bắt đầu từ Band 5.5 và đạt được 7.0 sau khi hoàn thành khóa học. Các bài giảng rất chi tiết và có nhiều ví dụ minh họa cụ thể.'
        WHEN 37 THEN 'The course structure is logical and easy to follow. Each module focuses on specific skills and provides ample practice opportunities. The mock tests are realistic and helped me prepare effectively for the exam.'
        WHEN 38 THEN 'Tôi rất biết ơn khóa học này. Các tips và tricks được chia sẻ rất thực tế và hữu ích. Tôi đã áp dụng vào bài thi và đạt được kết quả tốt. Đây là khóa học tốt nhất mà tôi từng học.'
        WHEN 39 THEN 'This course is perfect for anyone serious about IELTS. The content is comprehensive, the instruction is clear, and the practice materials are excellent. I improved my overall score by 1.5 bands!'
        WHEN 40 THEN 'Khóa học này đã giúp tôi hiểu rõ hơn về cấu trúc bài thi IELTS. Các bài tập thực hành rất đa dạng và phong phú. Giảng viên giải thích rõ ràng và có nhiều ví dụ minh họa cụ thể.'
        WHEN 41 THEN 'The course provides excellent preparation for IELTS. The instructor is experienced and the content is well-organized. I particularly liked the detailed explanations for each question type. Highly recommend!'
        WHEN 42 THEN 'Tôi đã học được rất nhiều từ khóa học này. Các chiến lược làm bài rất hiệu quả và dễ áp dụng. Giảng viên có kinh nghiệm và biết cách truyền đạt kiến thức một cách dễ hiểu nhất.'
        WHEN 43 THEN 'This course is worth every penny. The quality of instruction is excellent and the practice materials are comprehensive. I felt much more confident after completing this course and achieved my target score.'
        ELSE 'Khóa học này đã giúp tôi đạt được mục tiêu của mình. Các bài giảng chất lượng cao và có nhiều ví dụ thực tế. Tôi đặc biệt thích phần luyện tập với nhiều đề thi đa dạng. Rất đáng học!'
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
    '✅ Phase 3 Complete: Course Activities Created' as status,
    (SELECT COUNT(*) FROM course_enrollments) as total_enrollments,
    (SELECT COUNT(*) FROM lesson_progress) as total_lesson_progress,
    (SELECT COUNT(*) FROM video_watch_history) as total_watch_history,
    (SELECT COUNT(*) FROM course_reviews) as total_reviews;

