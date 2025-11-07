-- ============================================
-- FIXED EXERCISES WITH PROPER CONSTRAINTS
-- ============================================
-- Purpose: Add/Update exercises with all required fields per schema constraints
-- Database: exercise_db
-- Date: 2025-11-07
-- 
-- FIXES:
-- 1. Writing exercises MUST have: writing_task_type, writing_prompt_text
-- 2. Speaking exercises MUST have: speaking_part_number, speaking_prompt_text
-- 3. Reading exercises MUST have: ielts_test_type ('academic' or 'general_training')
-- ============================================

-- ============================================
-- DELETE INVALID EXERCISES (if any exist)
-- ============================================
-- Remove any exercises that don't meet schema constraints
DELETE FROM exercises 
WHERE (skill_type = 'writing' AND (writing_task_type IS NULL OR writing_prompt_text IS NULL))
   OR (skill_type = 'speaking' AND (speaking_part_number IS NULL OR speaking_prompt_text IS NULL))
   OR (skill_type = 'reading' AND ielts_test_type IS NULL);

-- ============================================
-- WRITING EXERCISES (Task 1 & Task 2)
-- ============================================

-- Writing Task 1: Line Graph
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    -- Writing-specific required fields
    writing_task_type,
    writing_prompt_text,
    writing_visual_type,
    writing_visual_url,
    writing_word_requirement
) VALUES
('e3000001-0000-0000-0000-000000000001'::uuid,
 'IELTS Writing Task 1 - Line Graph: Global Temperature',
 'ielts-writing-task1-line-graph-temperature',
 'Describe the trends shown in the line graph about global temperature changes over 50 years.',
 'practice', 'writing', 'medium', 'band 6.0-7.0',
 1, 1, 20,
 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&h=600&fit=crop',
 'c3000001-0000-0000-0000-000000000008'::uuid, -- Writing Task 1 course
 true, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '40 days',
 -- Writing fields
 'task1',
 'The graph below shows the average global temperature from 1970 to 2020. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'line_graph',
 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 150
) ON CONFLICT (id) DO UPDATE SET
    writing_task_type = EXCLUDED.writing_task_type,
    writing_prompt_text = EXCLUDED.writing_prompt_text,
    writing_visual_type = EXCLUDED.writing_visual_type,
    writing_visual_url = EXCLUDED.writing_visual_url,
    writing_word_requirement = EXCLUDED.writing_word_requirement;

-- Writing Task 1: Bar Chart
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    writing_task_type, writing_prompt_text, writing_visual_type, writing_visual_url, writing_word_requirement
) VALUES
('e3000002-0000-0000-0000-000000000002'::uuid,
 'IELTS Writing Task 1 - Bar Chart: Internet Usage',
 'ielts-writing-task1-bar-chart-internet',
 'Analyze and describe the bar chart showing internet usage across different age groups.',
 'practice', 'writing', 'medium', 'band 6.0-7.0',
 1, 1, 20,
 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 'c3000001-0000-0000-0000-000000000008'::uuid,
 true, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '38 days',
 'task1',
 'The bar chart shows the percentage of internet users by age group in five countries in 2022. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'bar_chart',
 'https://images.unsplash.com/photo-1543286386-713bdd548da4?w=800&h=600&fit=crop',
 150
) ON CONFLICT (id) DO UPDATE SET
    writing_task_type = EXCLUDED.writing_task_type,
    writing_prompt_text = EXCLUDED.writing_prompt_text,
    writing_visual_type = EXCLUDED.writing_visual_type,
    writing_visual_url = EXCLUDED.writing_visual_url,
    writing_word_requirement = EXCLUDED.writing_word_requirement;

-- Writing Task 1: Pie Chart
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    writing_task_type, writing_prompt_text, writing_visual_type, writing_visual_url, writing_word_requirement
) VALUES
('e3000003-0000-0000-0000-000000000003'::uuid,
 'IELTS Writing Task 1 - Pie Chart: Energy Sources',
 'ielts-writing-task1-pie-chart-energy',
 'Describe the proportion of different energy sources used in a country.',
 'practice', 'writing', 'easy', 'band 5.5-6.5',
 1, 1, 20,
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&h=600&fit=crop',
 'c3000001-0000-0000-0000-000000000008'::uuid,
 true, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '36 days',
 'task1',
 'The pie charts show the sources of electricity in Australia in 1980 and 2000. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'pie_chart',
 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800&h=600&fit=crop',
 150
) ON CONFLICT (id) DO UPDATE SET
    writing_task_type = EXCLUDED.writing_task_type,
    writing_prompt_text = EXCLUDED.writing_prompt_text,
    writing_visual_type = EXCLUDED.writing_visual_type,
    writing_visual_url = EXCLUDED.writing_visual_url,
    writing_word_requirement = EXCLUDED.writing_word_requirement;

-- Writing Task 2: Opinion Essay
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    writing_task_type, writing_prompt_text, writing_word_requirement
) VALUES
('e3000004-0000-0000-0000-000000000004'::uuid,
 'IELTS Writing Task 2 - Opinion Essay: Online Education',
 'ielts-writing-task2-opinion-online-education',
 'Write an opinion essay about online education versus traditional classroom learning.',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 1, 1, 40,
 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=600&fit=crop',
 'c3000002-0000-0000-0000-000000000009'::uuid, -- Writing Task 2 course
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '34 days',
 'task2',
 'Some people believe that online learning is more effective than traditional classroom education, while others think face-to-face teaching is irreplaceable. Discuss both views and give your own opinion. Give reasons for your answer and include any relevant examples from your own knowledge or experience. Write at least 250 words.',
 250
) ON CONFLICT (id) DO UPDATE SET
    writing_task_type = EXCLUDED.writing_task_type,
    writing_prompt_text = EXCLUDED.writing_prompt_text,
    writing_word_requirement = EXCLUDED.writing_word_requirement;

-- Writing Task 2: Discussion Essay
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    writing_task_type, writing_prompt_text, writing_word_requirement
) VALUES
('e3000005-0000-0000-0000-000000000005'::uuid,
 'IELTS Writing Task 2 - Discussion: Technology and Children',
 'ielts-writing-task2-discussion-technology-children',
 'Discuss both positive and negative effects of technology on children.',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 1, 1, 40,
 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&h=600&fit=crop',
 'c3000002-0000-0000-0000-000000000009'::uuid,
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '32 days',
 'task2',
 'Some people think that technology has made children less creative than they were in the past. To what extent do you agree or disagree? Give reasons for your answer and include any relevant examples from your own knowledge or experience. Write at least 250 words.',
 250
) ON CONFLICT (id) DO UPDATE SET
    writing_task_type = EXCLUDED.writing_task_type,
    writing_prompt_text = EXCLUDED.writing_prompt_text,
    writing_word_requirement = EXCLUDED.writing_word_requirement;

-- ============================================
-- SPEAKING EXERCISES (Parts 1, 2, 3)
-- ============================================

-- Speaking Part 1: Introduction & Interview
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    -- Speaking-specific required fields
    speaking_part_number,
    speaking_prompt_text
) VALUES
('e4000001-0000-0000-0000-000000000006'::uuid,
 'IELTS Speaking Part 1 - Hometown and Family',
 'ielts-speaking-part1-hometown-family',
 'Practice common Part 1 questions about hometown and family.',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 5, 1, 5,
 'https://images.unsplash.com/photo-1556761175-b413da4baf72?w=800&h=600&fit=crop',
 'c4000001-0000-0000-0000-000000000010'::uuid, -- Speaking Part 1 course
 true, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '30 days',
 1,
 'In this part, I''m going to ask you some questions about yourself. Let''s talk about your hometown. Where are you from? What do you like about living there? Has your hometown changed much over the years? Let''s move on to talk about your family. Can you tell me about your family? Who are you closest to in your family?'
) ON CONFLICT (id) DO UPDATE SET
    speaking_part_number = EXCLUDED.speaking_part_number,
    speaking_prompt_text = EXCLUDED.speaking_prompt_text;

-- Speaking Part 2: Cue Card - Describe a Person
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    speaking_part_number, speaking_prompt_text, speaking_cue_card_topic,
    speaking_cue_card_points, speaking_preparation_time_seconds, speaking_response_time_seconds
) VALUES
('e4000002-0000-0000-0000-000000000007'::uuid,
 'IELTS Speaking Part 2 - Describe a Person You Admire',
 'ielts-speaking-part2-person-admire',
 'Practice describing a person you admire with the cue card method.',
 'practice', 'speaking', 'medium', 'band 6.0-7.0',
 1, 1, 3,
 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=600&fit=crop',
 'c4000002-0000-0000-0000-000000000011'::uuid, -- Speaking Part 2 course
 false, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '28 days',
 2,
 'Describe a person who has had an important influence on your life. You should say: who the person is, how long you have known this person, what qualities this person has, and explain why this person has had such an influence on you.',
 'Describe a person who has had an important influence on your life',
 ARRAY[
     'Who the person is',
     'How long you have known this person',
     'What qualities this person has',
     'Explain why this person has had such an influence on you'
 ],
 60, -- 1 minute preparation
 120 -- 2 minutes speaking
) ON CONFLICT (id) DO UPDATE SET
    speaking_part_number = EXCLUDED.speaking_part_number,
    speaking_prompt_text = EXCLUDED.speaking_prompt_text,
    speaking_cue_card_topic = EXCLUDED.speaking_cue_card_topic,
    speaking_cue_card_points = EXCLUDED.speaking_cue_card_points,
    speaking_preparation_time_seconds = EXCLUDED.speaking_preparation_time_seconds,
    speaking_response_time_seconds = EXCLUDED.speaking_response_time_seconds;

-- Speaking Part 2: Cue Card - Describe a Place
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    speaking_part_number, speaking_prompt_text, speaking_cue_card_topic,
    speaking_cue_card_points, speaking_preparation_time_seconds, speaking_response_time_seconds
) VALUES
('e4000003-0000-0000-0000-000000000008'::uuid,
 'IELTS Speaking Part 2 - Describe a Place You Visited',
 'ielts-speaking-part2-place-visited',
 'Describe a memorable place you have visited.',
 'practice', 'speaking', 'medium', 'band 6.0-7.0',
 1, 1, 3,
 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&h=600&fit=crop',
 'c4000002-0000-0000-0000-000000000011'::uuid,
 false, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '26 days',
 2,
 'Describe a place you visited that left a strong impression on you. You should say: where it was, when you went there, what you did there, and explain why it left such a strong impression on you.',
 'Describe a place you visited that left a strong impression on you',
 ARRAY[
     'Where it was',
     'When you went there',
     'What you did there',
     'Explain why it left such a strong impression on you'
 ],
 60,
 120
) ON CONFLICT (id) DO UPDATE SET
    speaking_part_number = EXCLUDED.speaking_part_number,
    speaking_prompt_text = EXCLUDED.speaking_prompt_text,
    speaking_cue_card_topic = EXCLUDED.speaking_cue_card_topic,
    speaking_cue_card_points = EXCLUDED.speaking_cue_card_points,
    speaking_preparation_time_seconds = EXCLUDED.speaking_preparation_time_seconds,
    speaking_response_time_seconds = EXCLUDED.speaking_response_time_seconds;

-- Speaking Part 3: Discussion
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes,
    thumbnail_url, course_id, is_free, is_published, created_by, published_at,
    speaking_part_number, speaking_prompt_text, speaking_follow_up_questions
) VALUES
('e4000004-0000-0000-0000-000000000009'::uuid,
 'IELTS Speaking Part 3 - Education Discussion',
 'ielts-speaking-part3-education',
 'Discuss abstract topics related to education with follow-up questions.',
 'practice', 'speaking', 'hard', 'band 7.0-8.0',
 4, 1, 5,
 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=800&h=600&fit=crop',
 'c4000002-0000-0000-0000-000000000011'::uuid,
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '24 days',
 3,
 'We''ve been talking about influential people and places. Now I''d like to discuss with you some more general questions related to education and personal development.',
 ARRAY[
     'How has education changed in your country over the past few decades?',
     'What role do you think technology should play in modern education?',
     'Some people believe that practical skills are more important than academic knowledge. What is your opinion?',
     'How can schools better prepare students for the challenges of the future?'
 ]
) ON CONFLICT (id) DO UPDATE SET
    speaking_part_number = EXCLUDED.speaking_part_number,
    speaking_prompt_text = EXCLUDED.speaking_prompt_text,
    speaking_follow_up_questions = EXCLUDED.speaking_follow_up_questions;

-- ============================================
-- VALIDATION
-- ============================================
-- The following should return 0 rows if all constraints are met

-- Check Writing exercises
DO $$
DECLARE
    invalid_writing_count INT;
BEGIN
    SELECT COUNT(*) INTO invalid_writing_count
    FROM exercises
    WHERE skill_type = 'writing'
      AND (writing_task_type IS NULL OR writing_prompt_text IS NULL);
    
    IF invalid_writing_count > 0 THEN
        RAISE WARNING 'Found % writing exercises with missing required fields', invalid_writing_count;
    ELSE
        RAISE NOTICE '✓ All writing exercises have required fields';
    END IF;
END $$;

-- Check Speaking exercises
DO $$
DECLARE
    invalid_speaking_count INT;
BEGIN
    SELECT COUNT(*) INTO invalid_speaking_count
    FROM exercises
    WHERE skill_type = 'speaking'
      AND (speaking_part_number IS NULL OR speaking_prompt_text IS NULL);
    
    IF invalid_speaking_count > 0 THEN
        RAISE WARNING 'Found % speaking exercises with missing required fields', invalid_speaking_count;
    ELSE
        RAISE NOTICE '✓ All speaking exercises have required fields';
    END IF;
END $$;

-- Check Reading exercises
DO $$
DECLARE
    invalid_reading_count INT;
BEGIN
    SELECT COUNT(*) INTO invalid_reading_count
    FROM exercises
    WHERE skill_type = 'reading'
      AND ielts_test_type IS NULL;
    
    IF invalid_reading_count > 0 THEN
        RAISE WARNING 'Found % reading exercises with missing ielts_test_type', invalid_reading_count;
    ELSE
        RAISE NOTICE '✓ All reading exercises have ielts_test_type';
    END IF;
END $$;
