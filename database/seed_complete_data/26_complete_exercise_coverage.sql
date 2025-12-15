-- ============================================
-- COMPLETE EXERCISE COVERAGE - IELTS REALISTIC
-- ============================================
-- Purpose: Add missing exercise types for complete IELTS coverage
-- Database: exercise_db
-- 
-- ADDS:
-- - 4 Writing Task 1 (missing visual types)
-- - 10 Speaking exercises (diverse topics)
-- - 5 Writing Task 2 (important topics)
-- ============================================

-- ============================================
-- WRITING TASK 1 - MISSING VISUAL TYPES
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    writing_task_type, writing_prompt_text, writing_visual_type, writing_visual_url, writing_word_requirement
) VALUES
-- Flow Chart
('e3000030-0000-0000-0000-000000000030'::uuid,
 'IELTS Writing Task 1 - Flow Chart: Customer Service Process',
 'writing-task1-flowchart-customer-service',
 'Describe the customer service handling process',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 20, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The flow chart below shows the procedure for handling customer complaints in a retail company. Summarize the information by selecting and reporting the main features. Write at least 150 words.',
 'flow_chart',
 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&h=600&fit=crop',
 150
),

-- Cycle Diagram
('e3000031-0000-0000-0000-000000000031'::uuid,
 'IELTS Writing Task 1 - Cycle Diagram: Water Cycle',
 'writing-task1-cycle-water-cycle',
 'Describe the natural water cycle process',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 20, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The diagram below illustrates the water cycle in nature. Summarize the information by selecting and reporting the main features. Write at least 150 words.',
 'cycle_diagram',
 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=800&h=600&fit=crop',
 150
),

-- Two Maps Comparison
('e3000032-0000-0000-0000-000000000032'::uuid,
 'IELTS Writing Task 1 - Two Maps: Island Development',
 'writing-task1-two-maps-island',
 'Compare two maps showing island development over time',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 20, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The two maps below show an island before and after the construction of tourist facilities. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'two_maps',
 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&h=600&fit=crop',
 150
),

-- Multiple Graphs
('e3000033-0000-0000-0000-000000000033'::uuid,
 'IELTS Writing Task 1 - Multiple Graphs: Energy Consumption',
 'writing-task1-multiple-graphs-energy',
 'Analyze energy consumption using line graph and pie chart',
 'practice', 'writing', 'hard', 'band 7.0-8.5',
 4, 20, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The line graph shows total energy consumption from 2000 to 2020, while the pie chart shows the breakdown by energy source in 2020. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'multiple_graphs',
 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&h=600&fit=crop',
 150
);

-- ============================================
-- WRITING TASK 2 - IMPORTANT IELTS TOPICS
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    writing_task_type, writing_prompt_text, writing_word_requirement
) VALUES
-- Child Development
('e3000040-0000-0000-0000-000000000040'::uuid,
 'IELTS Writing Task 2 - Child Development',
 'writing-task2-child-development',
 'Discuss factors affecting child development',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people think that parents should teach children how to be good members of society. Others, however, believe that school is the place to learn this. Discuss both views and give your own opinion. Write at least 250 words.',
 250
),

-- Urban Planning
('e3000041-0000-0000-0000-000000000041'::uuid,
 'IELTS Writing Task 2 - Urban Planning',
 'writing-task2-urban-planning',
 'Discuss city development priorities',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people believe that governments should invest more in building new housing, while others think priority should be given to preserving old buildings. Discuss both views and give your opinion. Write at least 250 words.',
 250
),

-- Media Influence
('e3000042-0000-0000-0000-000000000042'::uuid,
 'IELTS Writing Task 2 - Media Influence',
 'writing-task2-media-influence',
 'Analyze media impact on society',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'News media have become increasingly influential in people''s lives today. Is this a positive or negative development? Write at least 250 words.',
 250
),

-- Space Exploration
('e3000043-0000-0000-0000-000000000043'::uuid,
 'IELTS Writing Task 2 - Space Exploration',
 'writing-task2-space-exploration',
 'Discuss investment in space exploration',
 'practice', 'writing', 'hard', 'band 7.5-8.5',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people think that space exploration is a waste of money and resources. To what extent do you agree or disagree? Write at least 250 words.',
 250
),

-- Aging Population
('e3000044-0000-0000-0000-000000000044'::uuid,
 'IELTS Writing Task 2 - Aging Population',
 'writing-task2-aging-population',
 'Discuss challenges of aging population',
 'practice', 'writing', 'hard', 'band 7.0-8.5',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'In many countries, the proportion of older people is steadily increasing. Does this trend have more positive or negative effects on society? Write at least 250 words.',
 250
);

-- ============================================
-- SPEAKING PART 2 - MORE DIVERSE TOPICS
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_cue_card_topic,
    speaking_cue_card_points, speaking_preparation_time_seconds, speaking_response_time_seconds
) VALUES
-- Decision
('e4000040-0000-0000-0000-000000000040'::uuid,
 'IELTS Speaking Part 2 - Describe a Difficult Decision',
 'speaking-part2-difficult-decision',
 'Talk about an important decision you made',
 'practice', 'speaking', 'hard', 'band 7.0-8.0',
 4, 3, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a difficult decision you had to make.',
 'Describe a difficult decision',
 ARRAY['What the decision was', 'When you had to make it', 'What alternatives you considered', 'And explain why it was difficult and what you learned from it'],
 60, 120
),

-- Website/App
('e4000041-0000-0000-0000-000000000041'::uuid,
 'IELTS Speaking Part 2 - Describe a Website or App',
 'speaking-part2-website-app',
 'Describe a useful website or mobile application',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a website or app that you find useful.',
 'Describe a useful website/app',
 ARRAY['What it is', 'How you use it', 'What features it has', 'And explain why you find it useful'],
 60, 120
),

-- Gift
('e4000042-0000-0000-0000-000000000042'::uuid,
 'IELTS Speaking Part 2 - Describe a Gift',
 'speaking-part2-gift',
 'Talk about a special gift you received',
 'practice', 'speaking', 'easy', 'band 6.0-7.0',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a special gift you received.',
 'Describe a special gift',
 ARRAY['What the gift was', 'Who gave it to you', 'On what occasion', 'And explain why it was special to you'],
 60, 120
),

-- Time When...
('e4000043-0000-0000-0000-000000000043'::uuid,
 'IELTS Speaking Part 2 - Describe a Time When You Helped Someone',
 'speaking-part2-helped-someone',
 'Describe an occasion when you helped someone',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a time when you helped someone.',
 'Describe helping someone',
 ARRAY['Who you helped', 'How you helped them', 'Why they needed help', 'And explain how you felt afterwards'],
 60, 120
),

-- Change
('e4000044-0000-0000-0000-000000000044'::uuid,
 'IELTS Speaking Part 2 - Describe a Positive Change',
 'speaking-part2-positive-change',
 'Describe a positive change in your life',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a positive change that happened in your life.',
 'Describe a positive change',
 ARRAY['What the change was', 'When it happened', 'What caused the change', 'And explain how it affected your life'],
 60, 120
);

-- ============================================
-- SPEAKING PART 3 - MORE ABSTRACT TOPICS
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_follow_up_questions, speaking_response_time_seconds
) VALUES
-- Media & Entertainment
('e4000050-0000-0000-0000-000000000050'::uuid,
 'IELTS Speaking Part 3 - Media and Entertainment',
 'speaking-part3-media',
 'Discuss media influence and entertainment trends',
 'practice', 'speaking', 'hard', 'band 7.5-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Let''s discuss media and entertainment in modern society.',
 ARRAY[
    'How has the media industry changed with the rise of the internet?',
    'Do you think traditional media like newspapers will disappear?',
    'What impact does celebrity culture have on young people?',
    'Should there be more regulation of online content?'
 ],
 300
),

-- Science & Research
('e4000051-0000-0000-0000-000000000051'::uuid,
 'IELTS Speaking Part 3 - Science and Research',
 'speaking-part3-science',
 'Analyze the role of science in society',
 'practice', 'speaking', 'hard', 'band 7.5-9.0',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Now I''d like to talk about science and research.',
 ARRAY[
    'Why is scientific research important for society?',
    'Should governments invest more money in scientific research?',
    'What are the ethical considerations in modern scientific research?',
    'How can we encourage more young people to pursue careers in science?'
 ],
 300
),

-- Family & Society
('e4000052-0000-0000-0000-000000000052'::uuid,
 'IELTS Speaking Part 3 - Family Structure',
 'speaking-part3-family',
 'Discuss changing family structures and values',
 'practice', 'speaking', 'hard', 'band 7.0-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Let''s discuss family and society.',
 ARRAY[
    'How have family structures changed in recent decades?',
    'What role do grandparents play in modern families?',
    'Is it better for children to grow up in a large or small family?',
    'How can societies better support working parents?'
 ],
 300
),

-- Economy & Development
('e4000053-0000-0000-0000-000000000053'::uuid,
 'IELTS Speaking Part 3 - Economic Development',
 'speaking-part3-economy',
 'Analyze economic development and its impacts',
 'practice', 'speaking', 'hard', 'band 7.5-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Now let''s talk about economic development.',
 ARRAY[
    'What are the main drivers of economic growth?',
    'Should countries prioritize economic development or environmental protection?',
    'How does economic inequality affect society?',
    'What role should governments play in regulating the economy?'
 ],
 300
),

-- Arts & Creativity
('e4000054-0000-0000-0000-000000000054'::uuid,
 'IELTS Speaking Part 3 - Arts and Creativity',
 'speaking-part3-arts',
 'Discuss the importance of arts in society',
 'practice', 'speaking', 'hard', 'band 7.0-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Let''s discuss arts and creativity.',
 ARRAY[
    'Why is art important in society?',
    'Should art and music be compulsory subjects in schools?',
    'How has technology affected the arts?',
    'Do you think governments should fund the arts?'
 ],
 300
);

-- ============================================
-- SPEAKING PART 1 - MORE TOPICS
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_response_time_seconds
) VALUES
-- Reading Habits
('e4000060-0000-0000-0000-000000000060'::uuid,
 'IELTS Speaking Part 1 - Reading Habits',
 'speaking-part1-reading',
 'Talk about your reading preferences',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you like reading? What kind of books do you prefer? How often do you read? Do you prefer e-books or printed books? Did you enjoy reading when you were a child?',
 180
),

-- Music
('e4000061-0000-0000-0000-000000000061'::uuid,
 'IELTS Speaking Part 1 - Music',
 'speaking-part1-music',
 'Discuss your music preferences and habits',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you like music? What kind of music do you listen to? Have your music tastes changed over time? Can you play any musical instruments? When do you usually listen to music?',
 180
),

-- Daily Routine
('e4000062-0000-0000-0000-000000000062'::uuid,
 'IELTS Speaking Part 1 - Daily Routine',
 'speaking-part1-daily-routine',
 'Describe your typical day',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'What is your daily routine? Are you a morning person or a night person? Has your daily routine changed recently? What is your favorite part of the day? How do you manage your time?',
 180
),

-- Shopping
('e4000063-0000-0000-0000-000000000063'::uuid,
 'IELTS Speaking Part 1 - Shopping',
 'speaking-part1-shopping',
 'Talk about your shopping habits',
 'practice', 'speaking', 'medium', 'band 6.0-7.0',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you enjoy shopping? How often do you go shopping? Do you prefer shopping online or in stores? What do you usually buy? Has your shopping behavior changed over the years?',
 180
),

-- Animals/Pets
('e4000064-0000-0000-0000-000000000064'::uuid,
 'IELTS Speaking Part 1 - Animals and Pets',
 'speaking-part1-animals-pets',
 'Discuss your views on animals and pets',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you like animals? Do you have any pets? What is your favorite animal? Did you have pets when you were a child? Are people in your country fond of animals?',
 180
);

-- Update total_questions
UPDATE exercises SET total_questions = 4 WHERE skill_type IN ('writing', 'speaking') AND total_questions = 0;

-- ============================================
-- VERIFICATION
-- ============================================

SELECT '=== WRITING TASK 1 VISUAL TYPES ===' as section;

SELECT 
    writing_visual_type,
    COUNT(*) as count
FROM exercises
WHERE skill_type = 'writing' AND writing_task_type = 'task1'
GROUP BY writing_visual_type
ORDER BY COUNT(*) DESC;

SELECT '=== EXERCISES BY SKILL ===' as section;

SELECT 
    skill_type,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE difficulty = 'easy') as easy,
    COUNT(*) FILTER (WHERE difficulty = 'medium') as medium,
    COUNT(*) FILTER (WHERE difficulty = 'hard') as hard
FROM exercises
GROUP BY skill_type
ORDER BY skill_type;

-- ============================================
-- SUMMARY
-- ============================================

SELECT 
    'âœ… Complete Exercise Coverage Achieved' as status,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'writing' AND writing_task_type = 'task1') as writing_task1,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'writing' AND writing_task_type = 'task2') as writing_task2,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'speaking' AND speaking_part_number = 1) as speaking_part1,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'speaking' AND speaking_part_number = 2) as speaking_part2,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'speaking' AND speaking_part_number = 3) as speaking_part3,
    (SELECT COUNT(*) FROM exercises) as total_all;

