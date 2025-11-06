-- ============================================
-- PHASE 5: AI_DB - WRITING & SPEAKING SUBMISSIONS
-- ============================================
-- Purpose: Create AI submissions and evaluations
-- Database: ai_db
-- 
-- Creates:
-- - Writing prompts
-- - Speaking prompts
-- - Writing submissions & evaluations
-- - Speaking submissions & evaluations
-- ============================================

-- ============================================
-- 1. WRITING_PROMPTS
-- ============================================

INSERT INTO writing_prompts (
    id, task_type, prompt_text, visual_type, visual_url, topic, difficulty,
    has_sample_answer, sample_answer_text, sample_answer_band_score,
    is_published, created_by, times_used, average_score
) VALUES
-- Task 1 Prompts
('c1000001-0000-0000-0000-000000000001'::uuid, 'task1',
 'The chart below shows the percentage of households in owned and rented accommodation in England and Wales between 1918 and 2011.
Summarize the information by selecting and reporting the main features, and make comparisons where relevant.',
 'bar_chart', 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 'housing', 'medium', true,
 'The bar chart illustrates the changes in housing tenure in England and Wales from 1918 to 2011...',
 7.0, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 45, 6.8),

('c1000002-0000-0000-0000-000000000002'::uuid, 'task1',
 'The graph below shows the proportion of the population aged 65 and over between 1940 and 2040 in three different countries.
Summarize the information by selecting and reporting the main features, and make comparisons where relevant.',
 'line_graph', 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 'demographics', 'medium', true,
 'The line graph compares the percentage of people aged 65 and over in Japan, Sweden, and the USA from 1940 to 2040...',
 7.5, true, 'b0000002-0000-0000-0000-000000000002'::uuid, 38, 7.1),

('c1000003-0000-0000-0000-000000000003'::uuid, 'task1',
 'The diagram below shows the process of how rainwater is collected and converted to drinking water in an Australian town.
Summarize the information by selecting and reporting the main features.',
 'diagram', 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 'process', 'hard', true,
 'The diagram illustrates the process of collecting rainwater and converting it into drinking water in an Australian town...',
 6.5, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 32, 6.3),

-- Task 2 Prompts
('c2000001-0000-0000-0000-000000000004'::uuid, 'task2',
 'Some people believe that it is better to study in a group, while others prefer to study alone. Discuss both views and give your own opinion.',
 NULL, NULL, 'education', 'medium', true,
 'There are contrasting views on whether group study or individual study is more effective. While some argue that studying in groups enhances learning, others believe that studying alone is more productive...',
 7.5, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 52, 7.2),

('c2000002-0000-0000-0000-000000000005'::uuid, 'task2',
 'Some people think that the government should provide free healthcare for all citizens, while others believe that individuals should pay for their own medical care. Discuss both views and give your own opinion.',
 NULL, NULL, 'healthcare', 'medium', true,
 'The debate over healthcare funding is a contentious issue in many countries. Some argue that healthcare should be provided free by the government, while others believe individuals should bear the cost...',
 7.0, true, 'b0000002-0000-0000-0000-000000000002'::uuid, 48, 6.9),

('c2000003-0000-0000-0000-000000000006'::uuid, 'task2',
 'Many people believe that social media has a negative impact on society. To what extent do you agree or disagree?',
 NULL, NULL, 'technology', 'easy', true,
 'Social media has become an integral part of modern life, but its impact on society is a subject of debate. While some argue that social media has negative consequences, I believe its effects are more nuanced...',
 6.5, true, 'b0000003-0000-0000-0000-000000000003'::uuid, 65, 6.4);

-- Insert more prompts
INSERT INTO writing_prompts (
    id, task_type, prompt_text, visual_type, visual_url, topic, difficulty,
    has_sample_answer, is_published, created_by, times_used, average_score
)
SELECT 
    ('c' || CASE WHEN row_number() OVER () <= 10 THEN '1' ELSE '2' END ||
    LPAD((row_number() OVER () + 3)::text, 6, '0') || '-0000-0000-0000-000000000' ||
    LPAD((row_number() OVER () + 6)::text, 3, '0'))::uuid,
    CASE WHEN row_number() OVER () <= 10 THEN 'task1' ELSE 'task2' END,
    CASE WHEN row_number() OVER () <= 10 THEN
        'The ' || CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'chart'
            WHEN 1 THEN 'graph'
            ELSE 'diagram'
        END || ' below shows ' || 
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'population trends'
            WHEN 1 THEN 'energy consumption'
            WHEN 2 THEN 'employment rates'
            WHEN 3 THEN 'educational achievements'
            ELSE 'economic growth'
        END || ' in different regions. Summarize the information by selecting and reporting the main features.'
    ELSE
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'Some people believe that technology makes our lives more complicated. To what extent do you agree or disagree?'
            WHEN 1 THEN 'Many people think that university education should be free. Discuss both views and give your own opinion.'
            WHEN 2 THEN 'Some argue that fast food has a negative impact on health. Do you agree or disagree?'
            WHEN 3 THEN 'Some people prefer to live in the countryside, while others prefer city life. Discuss both views and give your own opinion.'
            ELSE 'Many believe that climate change is the most serious problem facing the world today. To what extent do you agree or disagree?'
        END
    END,
    CASE WHEN row_number() OVER () <= 10 THEN
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'bar_chart'
            WHEN 1 THEN 'line_graph'
            WHEN 2 THEN 'pie_chart'
            WHEN 3 THEN 'table'
            ELSE 'diagram'
        END
    ELSE NULL END,
    CASE WHEN row_number() OVER () <= 10 THEN 
        CASE (row_number() OVER () % 12)
            WHEN 0 THEN 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800&h=600&fit=crop'
            WHEN 1 THEN 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800&h=600&fit=crop'
            WHEN 2 THEN 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&h=600&fit=crop'
            WHEN 3 THEN 'https://images.unsplash.com/photo-1589903308904-1010c2294adc?w=800&h=600&fit=crop'
            WHEN 4 THEN 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop'
            WHEN 5 THEN 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop'
            WHEN 6 THEN 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=600&fit=crop'
            WHEN 7 THEN 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop'
            WHEN 8 THEN 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&h=600&fit=crop'
            WHEN 9 THEN 'https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=800&h=600&fit=crop'
            WHEN 10 THEN 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=600&fit=crop'
            ELSE 'https://images.unsplash.com/photo-1508921340878-bad53cfe2816?w=800&h=600&fit=crop'
        END
    ELSE NULL END,
    CASE (random() * 8)::INTEGER
        WHEN 0 THEN 'education'
        WHEN 1 THEN 'healthcare'
        WHEN 2 THEN 'technology'
        WHEN 3 THEN 'environment'
        WHEN 4 THEN 'economy'
        WHEN 5 THEN 'society'
        WHEN 6 THEN 'culture'
        ELSE 'politics'
    END,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'easy' WHEN 1 THEN 'medium' ELSE 'hard' END,
    CASE WHEN random() > 0.5 THEN true ELSE false END,
    true,
    ('b' || LPAD((1 + (random() * 14)::INTEGER)::text, 7, '0') || '-0000-0000-0000-000000000' ||
    LPAD((1 + (random() * 14)::INTEGER)::text, 3, '0'))::uuid,
    (random() * 60 + 10)::INTEGER,
    (random() * 2.0 + 5.5)::DECIMAL(2,1)
FROM generate_series(1, 20);

-- Add visual_url for task2 writing prompts that are missing it
UPDATE writing_prompts wp
SET visual_url = CASE (hashtext(wp.id::text) % 12)
    WHEN 0 THEN 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop'
    WHEN 1 THEN 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop'
    WHEN 2 THEN 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop'
    WHEN 3 THEN 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop'
    WHEN 4 THEN 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop'
    WHEN 5 THEN 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=800&h=600&fit=crop'
    WHEN 6 THEN 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800&h=600&fit=crop'
    WHEN 7 THEN 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=600&fit=crop'
    WHEN 8 THEN 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=600&fit=crop'
    WHEN 9 THEN 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop'
    WHEN 10 THEN 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop'
    ELSE 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop'
END
WHERE wp.task_type = 'task2' AND (wp.visual_url IS NULL OR wp.visual_url = '');

-- ============================================
-- 2. SPEAKING_PROMPTS
-- ============================================

INSERT INTO speaking_prompts (
    id, part_number, prompt_text, cue_card_topic, cue_card_points,
    preparation_time_seconds, speaking_time_seconds, topic_category, difficulty,
    has_sample_answer, sample_answer_text, sample_answer_band_score,
    is_published, created_by, times_used, average_score
) VALUES
-- Part 1 Prompts
('d1000001-0000-0000-0000-000000000001'::uuid, 1,
 'Let''s talk about your hometown. Where are you from?',
 NULL, NULL, NULL, NULL, 'hometown', 'easy',
 true, 'I''m from Ho Chi Minh City, which is the largest city in Vietnam. It''s a vibrant and bustling metropolis...',
 6.5, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 78, 6.4),

('d1000002-0000-0000-0000-000000000002'::uuid, 1,
 'Do you like reading? What kind of books do you prefer?',
 NULL, NULL, NULL, NULL, 'hobbies', 'easy',
 true, 'Yes, I really enjoy reading. I particularly like fiction novels, especially science fiction and fantasy...',
 7.0, true, 'b0000002-0000-0000-0000-000000000002'::uuid, 65, 6.8),

-- Part 2 Prompts
('d2000001-0000-0000-0000-000000000003'::uuid, 2,
 'Describe a memorable journey you have taken. You should say:
- Where you went
- When you went there
- Who you went with
- And explain why this journey was memorable for you.',
 'A Memorable Journey', ARRAY['Where you went', 'When you went there', 'Who you went with', 'Why it was memorable'],
 60, 120, 'travel', 'medium',
 true, 'I would like to describe a journey I took to Japan last summer. I went there with my family in July...',
 7.5, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 52, 7.2),

('d2000002-0000-0000-0000-000000000004'::uuid, 2,
 'Describe a person who has influenced you. You should say:
- Who this person is
- How you know them
- What they have done
- And explain why they have influenced you.',
 'A Person Who Influenced You', ARRAY['Who the person is', 'How you know them', 'What they have done', 'Why they influenced you'],
 60, 120, 'people', 'medium',
 true, 'I would like to talk about my high school English teacher, Ms. Nguyen. She has had a profound influence on my life...',
 7.0, true, 'b0000002-0000-0000-0000-000000000002'::uuid, 48, 6.9),

-- Part 3 Prompts
('d3000001-0000-0000-0000-000000000005'::uuid, 3,
 'Let''s discuss travel. Do you think travel is important for personal development?',
 NULL, NULL, NULL, NULL, 'travel', 'hard',
 true, 'Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures, customs, and ways of life...',
 7.5, true, 'b0000001-0000-0000-0000-000000000001'::uuid, 45, 7.3);

-- Insert more speaking prompts
INSERT INTO speaking_prompts (
    id, part_number, prompt_text, cue_card_topic, cue_card_points,
    preparation_time_seconds, speaking_time_seconds, topic_category, difficulty,
    is_published, created_by, times_used, average_score
)
SELECT 
    ('d' || part_num::text || LPAD((row_number() OVER () + 1)::text, 6, '0') || '-0000-0000-0000-000000000' ||
    LPAD((row_number() OVER () + 5)::text, 3, '0'))::uuid,
    part_num,
    CASE part_num
        WHEN 1 THEN CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'Do you work or study?'
            WHEN 1 THEN 'What do you like to do in your free time?'
            WHEN 2 THEN 'Tell me about your family.'
            WHEN 3 THEN 'Do you enjoy cooking?'
            ELSE 'What kind of music do you like?'
        END
        WHEN 2 THEN 'Describe ' || CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'a place you would like to visit'
            WHEN 1 THEN 'a skill you want to learn'
            WHEN 2 THEN 'a book you recently read'
            WHEN 3 THEN 'a memorable event'
            ELSE 'your favorite hobby'
        END || '. You should say: what it is, when you encountered it, and why it is important to you.'
        ELSE 'Let''s discuss ' || CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'education'
            WHEN 1 THEN 'technology'
            WHEN 2 THEN 'environment'
            WHEN 3 THEN 'social media'
            ELSE 'work'
        END || '. Do you think [topic] is important in modern society?'
    END,
    CASE WHEN part_num = 2 THEN 
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'A Place You Want to Visit'
            WHEN 1 THEN 'A Skill to Learn'
            WHEN 2 THEN 'A Book You Read'
            WHEN 3 THEN 'A Memorable Event'
            ELSE 'Your Favorite Hobby'
        END
    ELSE NULL END,
    CASE WHEN part_num = 2 THEN ARRAY['What it is', 'When you encountered it', 'Why it is important'] ELSE NULL END,
    CASE WHEN part_num = 2 THEN 60 ELSE NULL END,
    CASE WHEN part_num = 2 THEN 120 ELSE NULL END,
    CASE (random() * 8)::INTEGER
        WHEN 0 THEN 'family'
        WHEN 1 THEN 'hobbies'
        WHEN 2 THEN 'work'
        WHEN 3 THEN 'travel'
        WHEN 4 THEN 'education'
        WHEN 5 THEN 'technology'
        WHEN 6 THEN 'culture'
        ELSE 'society'
    END,
    CASE part_num WHEN 1 THEN 'easy' WHEN 2 THEN 'medium' ELSE 'hard' END,
    true,
    ('b' || LPAD((1 + (random() * 14)::INTEGER)::text, 7, '0') || '-0000-0000-0000-000000000' ||
    LPAD((1 + (random() * 14)::INTEGER)::text, 3, '0'))::uuid,
    (random() * 70 + 10)::INTEGER,
    (random() * 2.0 + 5.5)::DECIMAL(2,1)
FROM generate_series(1, 3) part_num
CROSS JOIN generate_series(1, 15);

-- ============================================
-- 3. WRITING_SUBMISSIONS & EVALUATIONS
-- ============================================
-- ⚠️  DEPRECATED: These tables have been migrated to exercise_service
-- Writing and Speaking submissions are now stored in exercise_submissions table (exercise_db)
-- Evaluations are stored as JSONB in exercise_submissions.ai_evaluation_result
-- 
-- References:
-- - /docs/SCORING_SYSTEM_REFACTORING_PLAN.md
-- - /database/schemas/04_exercise_service.sql (exercise_submissions table)
--
-- This section is commented out to avoid errors.
-- New submissions will be created through exercise-service API.

/*
INSERT INTO writing_submissions (
    id, user_id, task_type, task_prompt_id, task_prompt_text,
    essay_text, word_count, time_spent_seconds, submitted_from,
    course_id, exercise_id, lesson_id,
    status, evaluated_at, created_at, updated_at
)
SELECT 
    uuid_generate_v4(),
    -- Generate student user IDs (f0000001 to f0000050) - matching auth_db pattern
    ('f' || LPAD((1 + (row_number() OVER () - 1) % 50)::text, 7, '0') || 
    '-0000-0000-0000-000000000' || LPAD((1 + (row_number() OVER () - 1) % 50)::text, 3, '0'))::uuid,
    wp.task_type,
    wp.id,
    wp.prompt_text,
    CASE wp.task_type
        WHEN 'task1' THEN 'The chart illustrates the trends in ' || wp.topic || ' over the period from 2000 to 2020. Overall, there is a clear pattern showing significant changes. The data reveals that [detailed analysis of the chart with 150-180 words]...'
        ELSE 'In recent years, the topic of ' || wp.topic || ' has become increasingly important. While some people argue that [perspective 1], others believe that [perspective 2]. In my opinion, [balanced view with 250-280 words]...'
    END,
    CASE wp.task_type WHEN 'task1' THEN (random() * 30 + 150)::INTEGER ELSE (random() * 50 + 250)::INTEGER END,
    CASE wp.task_type WHEN 'task1' THEN (random() * 600 + 1200)::INTEGER ELSE (random() * 1200 + 2400)::INTEGER END,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'web' WHEN 1 THEN 'android' ELSE 'ios' END,
    -- Cross-db links: 50% standalone, 50% linked to courses/lessons
    -- Writing courses: c3000001 (Task 1), c3000002 (Task 2)
    CASE WHEN random() > 0.5 THEN
        CASE wp.task_type
            WHEN 'task1' THEN 'c3000001-0000-0000-0000-000000000008'::uuid
            ELSE 'c3000002-0000-0000-0000-000000000009'::uuid
        END
    ELSE NULL END,
    NULL, -- exercise_id - Writing exercises are not in exercise_db
    NULL, -- lesson_id - Will be set via application if needed
    CASE WHEN random() > 0.15 THEN 'completed' ELSE 'pending' END,
    CASE WHEN random() > 0.15 THEN CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    CURRENT_TIMESTAMP - (random() * 60)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 60)::INTEGER * INTERVAL '1 day'
FROM writing_prompts wp
CROSS JOIN generate_series(1, 5) -- Generate submissions per prompt
WHERE random() > 0.7 -- 30% chance for each submission
LIMIT 200;

-- ============================================
-- 4. WRITING_EVALUATIONS
-- ============================================

INSERT INTO writing_evaluations (
    id, submission_id, overall_band_score,
    task_achievement_score, coherence_cohesion_score, lexical_resource_score, grammar_accuracy_score,
    strengths, weaknesses, grammar_errors, grammar_error_count,
    vocabulary_level, vocabulary_range_score, vocabulary_suggestions,
    paragraph_count, has_introduction, has_conclusion, structure_feedback,
    linking_words_used, coherence_feedback, addresses_all_parts, task_response_feedback,
    detailed_feedback, detailed_feedback_json, improvement_suggestions,
    ai_model_name, ai_model_version, confidence_score, processing_time_ms
)
SELECT 
    uuid_generate_v4(),
    ws.id,
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    ARRAY[
        'Good use of linking words',
        'Clear paragraph structure',
        'Appropriate vocabulary range',
        'Mostly accurate grammar'
    ],
    ARRAY[
        'Some spelling errors',
        'Could use more complex sentence structures',
        'Limited range of vocabulary in some areas'
    ],
    jsonb_build_array(
        jsonb_build_object('type', 'subject-verb agreement', 'example', 'The data shows...', 'correction', 'Correct'),
        jsonb_build_object('type', 'article usage', 'example', '...a university', 'correction', 'Correct')
    ),
    (random() * 5 + 1)::INTEGER,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'intermediate' WHEN 1 THEN 'advanced' ELSE 'basic' END,
    (random() * 0.4 + 0.6)::DECIMAL(3,2),
    jsonb_build_array(
        jsonb_build_object('word', 'good', 'suggestion', 'excellent/outstanding'),
        jsonb_build_object('word', 'big', 'suggestion', 'significant/substantial')
    ),
    CASE ws.task_type WHEN 'task1' THEN 3 ELSE 4 END,
    true,
    true,
    'The essay has a clear introduction, body paragraphs, and conclusion. Structure is logical.',
    ARRAY['however', 'moreover', 'therefore', 'furthermore'],
    'The essay flows well with appropriate linking devices.',
    CASE WHEN random() > 0.2 THEN true ELSE false END,
    CASE WHEN random() > 0.2 THEN 'The task has been addressed adequately.' ELSE 'Could address all parts of the task more completely.' END,
    'Overall, this is a well-written essay with good structure and vocabulary. However, there is room for improvement in grammar accuracy and lexical resource.',
    jsonb_build_object(
        'task_achievement', jsonb_build_object(
            'vi', 'Bạn đã hoàn thành tốt yêu cầu của đề bài.',
            'en', 'You have addressed the task requirements well.'
        ),
        'coherence_cohesion', jsonb_build_object(
            'vi', 'Bài viết có cấu trúc rõ ràng và logic.',
            'en', 'The essay has clear and logical structure.'
        ),
        'lexical_resource', jsonb_build_object(
            'vi', 'Sử dụng từ vựng phù hợp nhưng có thể đa dạng hơn.',
            'en', 'Appropriate vocabulary usage but could be more varied.'
        ),
        'grammar_accuracy', jsonb_build_object(
            'vi', 'Ngữ pháp chủ yếu chính xác nhưng có một số lỗi nhỏ.',
            'en', 'Grammar is mostly accurate with some minor errors.'
        )
    ),
    ARRAY[
        'Try to use more complex sentence structures',
        'Expand your vocabulary range',
        'Pay attention to article usage',
        'Practice writing more to improve fluency'
    ],
    'gpt-4',
    '1.0',
    (random() * 0.2 + 0.8)::DECIMAL(3,2),
    (random() * 2000 + 3000)::INTEGER
FROM writing_submissions ws
WHERE ws.status = 'completed';

-- ============================================
-- 5. SPEAKING_SUBMISSIONS
-- ============================================
-- Note: user_id references users from auth_db (not user_profiles from user_db)

INSERT INTO speaking_submissions (
    id, user_id, part_number, task_prompt_id, task_prompt_text,
    audio_url, audio_duration_seconds, audio_format, audio_file_size_bytes,
    transcript_text, transcript_word_count, recorded_from,
    course_id, exercise_id, lesson_id,
    status, transcribed_at, evaluated_at, created_at, updated_at
)
SELECT 
    uuid_generate_v4(),
    -- Generate student user IDs (f0000001 to f0000050) - matching auth_db pattern
    ('f' || LPAD((1 + (row_number() OVER () - 1) % 50)::text, 7, '0') || 
    '-0000-0000-0000-000000000' || LPAD((1 + (row_number() OVER () - 1) % 50)::text, 3, '0'))::uuid,
    sp.part_number,
    sp.id,
    sp.prompt_text,
    'https://storage.example.com/audio/' || uuid_generate_v4()::text || '.mp3',
    CASE sp.part_number 
        WHEN 1 THEN (random() * 60 + 30)::INTEGER
        WHEN 2 THEN (random() * 60 + 120)::INTEGER
        ELSE (random() * 60 + 120)::INTEGER
    END,
    'mp3',
    (random() * 2000000 + 500000)::BIGINT,
    CASE sp.part_number
        WHEN 1 THEN 'Well, I''m from Ho Chi Minh City, which is the largest city in Vietnam. It''s a very vibrant and bustling city with lots of activities and opportunities...'
        WHEN 2 THEN 'I would like to describe a memorable journey I took to Japan last summer. I went there with my family in July, and it was absolutely amazing. We visited Tokyo, Kyoto, and Osaka...'
        ELSE 'Yes, I believe travel is extremely important for personal development. When you travel, you expose yourself to different cultures and ways of life. This broadens your perspective and helps you understand the world better...'
    END,
    CASE sp.part_number
        WHEN 1 THEN (random() * 50 + 50)::INTEGER
        WHEN 2 THEN (random() * 150 + 150)::INTEGER
        ELSE (random() * 100 + 100)::INTEGER
    END,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'web' WHEN 1 THEN 'android' ELSE 'ios' END,
    -- Cross-db links: 50% standalone, 50% linked to speaking courses
    -- Speaking courses: c4000001 (Part 1), c4000002 (Part 2)
    CASE WHEN random() > 0.5 THEN
        CASE sp.part_number
            WHEN 1 THEN 'c4000001-0000-0000-0000-000000000010'::uuid
            WHEN 2 THEN 'c4000002-0000-0000-0000-000000000011'::uuid
            ELSE 'c4000002-0000-0000-0000-000000000011'::uuid -- Part 3 also uses Part 2 course
        END
    ELSE NULL END,
    NULL, -- exercise_id - Speaking exercises are not in exercise_db
    NULL, -- lesson_id - Will be set via application if needed
    CASE WHEN random() > 0.2 THEN 'completed' ELSE 'pending' END,
    CASE WHEN random() > 0.2 THEN CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    CASE WHEN random() > 0.2 THEN CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    CURRENT_TIMESTAMP - (random() * 60)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 60)::INTEGER * INTERVAL '1 day'
FROM speaking_prompts sp
CROSS JOIN generate_series(1, 3) -- Generate submissions per prompt
WHERE random() > 0.75 -- 25% chance for each submission
LIMIT 150;

-- ============================================
-- 6. SPEAKING_EVALUATIONS
-- ============================================

INSERT INTO speaking_evaluations (
    id, submission_id, overall_band_score,
    fluency_coherence_score, lexical_resource_score, grammar_accuracy_score, pronunciation_score,
    pronunciation_accuracy, problematic_sounds, intonation_score, stress_accuracy,
    speech_rate_wpm, pause_frequency, filler_words_count, filler_words_used, hesitation_count,
    vocabulary_level, unique_words_count, advanced_words_used, vocabulary_suggestions,
    grammar_errors, grammar_error_count, sentence_complexity,
    answers_question_directly, uses_linking_devices, coherence_feedback,
    content_relevance_score, idea_development_score, content_feedback,
    strengths, weaknesses, detailed_feedback, improvement_suggestions,
    transcription_model, evaluation_model, model_version, confidence_score,
    transcription_time_ms, evaluation_time_ms
)
SELECT 
    uuid_generate_v4(),
    ss.id,
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 3.0 + 5.5)::DECIMAL(2,1),
    (random() * 20 + 70)::DECIMAL(5,2),
    jsonb_build_array(
        jsonb_build_object('phoneme', 'θ', 'word', 'think', 'issue', 'Difficulty with th sound')
    ),
    (random() * 0.3 + 0.7)::DECIMAL(3,2),
    (random() * 0.3 + 0.7)::DECIMAL(3,2),
    (random() * 40 + 120)::INTEGER,
    (random() * 5 + 2)::DECIMAL(5,2),
    (random() * 5 + 1)::INTEGER,
    ARRAY['um', 'uh', 'like'],
    (random() * 3 + 1)::INTEGER,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'intermediate' WHEN 1 THEN 'advanced' ELSE 'basic' END,
    (random() * 50 + 50)::INTEGER,
    ARRAY['significant', 'substantial', 'considerable'],
    jsonb_build_array(
        jsonb_build_object('word', 'good', 'suggestion', 'excellent/outstanding')
    ),
    jsonb_build_array(
        jsonb_build_object('type', 'tense consistency', 'example', '...', 'correction', '...')
    ),
    (random() * 3 + 1)::INTEGER,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'simple' WHEN 1 THEN 'compound' ELSE 'complex' END,
    CASE WHEN random() > 0.2 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    'The response flows well with appropriate linking devices.',
    (random() * 0.3 + 0.7)::DECIMAL(3,2),
    (random() * 0.3 + 0.7)::DECIMAL(3,2),
    'Content is relevant and well-developed.',
    ARRAY[
        'Good pronunciation',
        'Appropriate vocabulary',
        'Clear ideas'
    ],
    ARRAY[
        'Some hesitation',
        'Could use more complex grammar',
        'Work on intonation'
    ],
    'Overall, this is a good performance with clear pronunciation and appropriate vocabulary. However, there is room for improvement in fluency and grammatical range.',
    ARRAY[
        'Practice speaking more to improve fluency',
        'Work on reducing hesitation',
        'Try to use more complex sentence structures',
        'Focus on pronunciation of difficult sounds'
    ],
    'whisper-1',
    'gpt-4',
    '1.0',
    (random() * 0.2 + 0.8)::DECIMAL(3,2),
    (random() * 1000 + 2000)::INTEGER,
    (random() * 3000 + 4000)::INTEGER
FROM speaking_submissions ss
WHERE ss.status = 'completed';
*/

-- Summary
SELECT 
    '✅ Phase 5 Complete: AI Prompts Created' as status,
    (SELECT COUNT(*) FROM writing_prompts) as total_writing_prompts,
    (SELECT COUNT(*) FROM speaking_prompts) as total_speaking_prompts,
    0 as total_writing_submissions, -- Migrated to exercise_submissions
    0 as total_writing_evaluations, -- Stored in exercise_submissions.ai_evaluation_result
    0 as total_speaking_submissions, -- Migrated to exercise_submissions
    0 as total_speaking_evaluations; -- Stored in exercise_submissions.ai_evaluation_result

