-- ============================================
-- ADD MORE REALISTIC IELTS EXERCISES
-- ============================================
-- Purpose: Add comprehensive Writing & Speaking exercises
-- Database: exercise_db
-- 
-- ADDS:
-- - 15 more Writing exercises (10 Task 2, 5 Task 1)
-- - 20 more Speaking exercises (8 Part 1, 7 Part 2, 5 Part 3)
-- - Realistic IELTS topics and prompts
-- ============================================

-- ============================================
-- WRITING TASK 2 - OPINION ESSAYS (10)
-- ============================================

-- Education Topic
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    writing_task_type, writing_prompt_text, writing_word_requirement
) VALUES
('e3000010-0000-0000-0000-000000000010'::uuid,
 'IELTS Writing Task 2 - Education and Technology',
 'writing-task2-education-technology',
 'Discuss the impact of technology on education',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people believe that technology has made children less creative than they were in the past. To what extent do you agree or disagree? Give reasons for your answer and include any relevant examples from your own knowledge or experience. Write at least 250 words.',
 250
),

-- Environment Topic
('e3000011-0000-0000-0000-000000000011'::uuid,
 'IELTS Writing Task 2 - Environmental Protection',
 'writing-task2-environmental-protection',
 'Discuss individual vs government responsibility for environment',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Environmental protection is the responsibility of politicians, not individuals as individuals can do too little. To what extent do you agree or disagree? Write at least 250 words.',
 250
),

-- Work-Life Balance
('e3000012-0000-0000-0000-000000000012'::uuid,
 'IELTS Writing Task 2 - Work-Life Balance',
 'writing-task2-work-life-balance',
 'Discuss the importance of work-life balance in modern society',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people think that long working hours are necessary for success, while others believe that a healthy work-life balance is more important. Discuss both views and give your own opinion. Write at least 250 words.',
 250
),

-- Social Media
('e3000013-0000-0000-0000-000000000013'::uuid,
 'IELTS Writing Task 2 - Social Media Impact',
 'writing-task2-social-media-impact',
 'Analyze the positive and negative effects of social media',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Social media has replaced face-to-face interaction among many people in society. Do you think the advantages outweigh the disadvantages? Write at least 250 words.',
 250
),

-- Healthcare
('e3000014-0000-0000-0000-000000000014'::uuid,
 'IELTS Writing Task 2 - Healthcare Systems',
 'writing-task2-healthcare-systems',
 'Compare public vs private healthcare systems',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people believe that healthcare should be free for everyone, while others believe that people should pay for their own healthcare. Discuss both views and give your opinion. Write at least 250 words.',
 250
),

-- Globalization
('e3000015-0000-0000-0000-000000000015'::uuid,
 'IELTS Writing Task 2 - Globalization',
 'writing-task2-globalization',
 'Discuss the effects of globalization on culture',
 'practice', 'writing', 'hard', 'band 7.0-8.5',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Globalization has led to the loss of cultural identity in many countries. To what extent do you agree or disagree with this statement? Write at least 250 words.',
 250
),

-- Crime & Punishment
('e3000016-0000-0000-0000-000000000016'::uuid,
 'IELTS Writing Task 2 - Crime Prevention',
 'writing-task2-crime-prevention',
 'Discuss methods of reducing crime',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Some people think that the best way to reduce crime is to give longer prison sentences. Others, however, believe there are better alternative ways of reducing crime. Discuss both views and give your opinion. Write at least 250 words.',
 250
),

-- Transportation
('e3000017-0000-0000-0000-000000000017'::uuid,
 'IELTS Writing Task 2 - Public Transport',
 'writing-task2-public-transport',
 'Discuss investment in public transport vs roads',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Governments should spend money on railways rather than roads. To what extent do you agree or disagree with this statement? Write at least 250 words.',
 250
),

-- Tourism
('e3000018-0000-0000-0000-000000000018'::uuid,
 'IELTS Writing Task 2 - Tourism Impact',
 'writing-task2-tourism-impact',
 'Analyze positive and negative effects of tourism',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 40, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'International tourism has become a huge industry in the world. Do the problems of international travel outweigh its advantages? Write at least 250 words.',
 250
),

-- Artificial Intelligence
('e3000019-0000-0000-0000-000000000019'::uuid,
 'IELTS Writing Task 2 - Artificial Intelligence',
 'writing-task2-artificial-intelligence',
 'Discuss AI impact on employment and society',
 'practice', 'writing', 'hard', 'band 7.5-8.5',
 4, 40, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task2',
 'Artificial intelligence will soon replace workers in many industries. Some people welcome this, while others are worried about it. Discuss both views and give your own opinion. Write at least 250 words.',
 250
);

-- ============================================
-- WRITING TASK 1 - DATA DESCRIPTION (5)
-- ============================================

-- Multiple Bar Charts
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    writing_task_type, writing_prompt_text, writing_visual_type, writing_visual_url, writing_word_requirement
) VALUES
('e3000020-0000-0000-0000-000000000020'::uuid,
 'IELTS Writing Task 1 - Multiple Bar Charts: University Enrollment',
 'writing-task1-multiple-bar-charts',
 'Compare university enrollment across different fields',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 20, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The charts below show the number of students enrolled in different subjects at a UK university in 2010 and 2020. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'bar_chart',
 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&h=600&fit=crop',
 150
),

-- Mixed Charts (Line + Bar)
('e3000021-0000-0000-0000-000000000021'::uuid,
 'IELTS Writing Task 1 - Mixed Charts: Tourism Statistics',
 'writing-task1-mixed-charts-tourism',
 'Describe tourism trends using line and bar charts',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 20, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The chart shows the number of tourists visiting a European country between 2015-2020, while the bar chart shows the reasons for their visits. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'bar_chart',
 'https://images.unsplash.com/photo-1543286386-713bdd548da4?w=800&h=600&fit=crop',
 150
),

-- Process Diagram
('e3000022-0000-0000-0000-000000000022'::uuid,
 'IELTS Writing Task 1 - Process: Coffee Production',
 'writing-task1-process-coffee-production',
 'Describe the coffee production process',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 20, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The diagram below shows the process of producing coffee beans from cultivation to packaging. Summarize the information by selecting and reporting the main features. Write at least 150 words.',
 'process_diagram',
 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&h=600&fit=crop',
 150
),

-- Map Changes
('e3000023-0000-0000-0000-000000000023'::uuid,
 'IELTS Writing Task 1 - Map: City Development',
 'writing-task1-map-city-development',
 'Describe changes in city layout over time',
 'practice', 'writing', 'hard', 'band 7.0-8.0',
 4, 20, false, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The maps below show the changes that occurred in a city center between 1990 and 2020. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'map',
 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800&h=600&fit=crop',
 150
),

-- Complex Table
('e3000024-0000-0000-0000-000000000024'::uuid,
 'IELTS Writing Task 1 - Table: Employment Statistics',
 'writing-task1-table-employment',
 'Analyze employment data from a complex table',
 'practice', 'writing', 'medium', 'band 6.5-7.5',
 4, 20, true, true, 'b0000002-0000-0000-0000-000000000002'::uuid,
 'task1',
 'The table below shows employment statistics for four countries in 2010, 2015, and 2020. Summarize the information by selecting and reporting the main features, and make comparisons where relevant. Write at least 150 words.',
 'table',
 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&h=600&fit=crop',
 150
);

-- ============================================
-- SPEAKING PART 1 - FAMILIAR TOPICS (8)
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_response_time_seconds
) VALUES
-- Hometown
('e4000010-0000-0000-0000-000000000010'::uuid,
 'IELTS Speaking Part 1 - Hometown',
 'speaking-part1-hometown',
 'Answer questions about your hometown',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Let''s talk about your hometown. Where are you from? What do you like most about your hometown? Has your hometown changed much since you were a child? Would you like to live there in the future?',
 180
),

-- Work/Study
('e4000011-0000-0000-0000-000000000011'::uuid,
 'IELTS Speaking Part 1 - Work or Study',
 'speaking-part1-work-study',
 'Discuss your work or studies',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you work or are you a student? What do you study/do? Why did you choose this subject/job? What do you find most interesting about it? What are your future plans?',
 180
),

-- Hobbies
('e4000012-0000-0000-0000-000000000012'::uuid,
 'IELTS Speaking Part 1 - Hobbies and Interests',
 'speaking-part1-hobbies',
 'Talk about your hobbies and free time activities',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'What do you like to do in your free time? How long have you been doing this hobby? Do you prefer to spend time alone or with others? Have your hobbies changed since you were a child?',
 180
),

-- Technology
('e4000013-0000-0000-0000-000000000013'::uuid,
 'IELTS Speaking Part 1 - Technology',
 'speaking-part1-technology',
 'Discuss your use of technology',
 'practice', 'speaking', 'medium', 'band 6.0-7.0',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'How often do you use technology? What kind of technology do you use most? Has technology changed the way you study/work? Do you think technology makes life easier or more complicated?',
 180
),

-- Food
('e4000014-0000-0000-0000-000000000014'::uuid,
 'IELTS Speaking Part 1 - Food and Cooking',
 'speaking-part1-food-cooking',
 'Talk about food preferences and cooking',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'What is your favorite food? Do you like cooking? How often do you eat out? Has your diet changed over the years? What is a traditional dish from your country?',
 180
),

-- Travel
('e4000015-0000-0000-0000-000000000015'::uuid,
 'IELTS Speaking Part 1 - Travel',
 'speaking-part1-travel',
 'Discuss your travel experiences',
 'practice', 'speaking', 'medium', 'band 6.0-7.0',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you like traveling? Where have you traveled to? What do you enjoy most about traveling? Do you prefer traveling alone or with others? Where would you like to travel in the future?',
 180
),

-- Weather
('e4000016-0000-0000-0000-000000000016'::uuid,
 'IELTS Speaking Part 1 - Weather and Seasons',
 'speaking-part1-weather',
 'Talk about weather and seasons',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'What is the weather like in your country? Which season do you prefer? Does weather affect your mood? Have you noticed any changes in weather patterns? What do you usually do on rainy days?',
 180
),

-- Sports
('e4000017-0000-0000-0000-000000000017'::uuid,
 'IELTS Speaking Part 1 - Sports and Exercise',
 'speaking-part1-sports',
 'Discuss sports and physical activities',
 'practice', 'speaking', 'easy', 'band 5.5-6.5',
 4, 5, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 1,
 'Do you play any sports? How often do you exercise? Did you play sports when you were younger? What is the most popular sport in your country? Do you prefer watching or playing sports?',
 180
);

-- ============================================
-- SPEAKING PART 2 - CUE CARDS (7)
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_cue_card_topic,
    speaking_cue_card_points, speaking_preparation_time_seconds, speaking_response_time_seconds
) VALUES
-- Person Topic
('e4000020-0000-0000-0000-000000000020'::uuid,
 'IELTS Speaking Part 2 - Describe a Person',
 'speaking-part2-person',
 'Describe a person who has influenced you',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a person who has had a significant influence on your life.',
 'Describe a person who has influenced you',
 ARRAY['Who this person is', 'How you know this person', 'What this person did that influenced you', 'And explain why this person is important to you'],
 60, 120
),

-- Place Topic
('e4000021-0000-0000-0000-000000000021'::uuid,
 'IELTS Speaking Part 2 - Describe a Place',
 'speaking-part2-place',
 'Describe a place you would like to visit',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a place you would like to visit in the future.',
 'Describe a place you want to visit',
 ARRAY['Where this place is', 'How you know about this place', 'What you would do there', 'And explain why you want to visit this place'],
 60, 120
),

-- Object Topic
('e4000022-0000-0000-0000-000000000022'::uuid,
 'IELTS Speaking Part 2 - Describe an Object',
 'speaking-part2-object',
 'Describe something important you own',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe something important that you own.',
 'Describe an important possession',
 ARRAY['What it is', 'When you got it', 'How you use it', 'And explain why it is important to you'],
 60, 120
),

-- Event Topic
('e4000023-0000-0000-0000-000000000023'::uuid,
 'IELTS Speaking Part 2 - Describe an Event',
 'speaking-part2-event',
 'Describe a memorable event from your life',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a memorable event from your life.',
 'Describe a memorable event',
 ARRAY['What the event was', 'When it happened', 'Who was there', 'And explain why it was memorable'],
 60, 120
),

-- Achievement Topic
('e4000024-0000-0000-0000-000000000024'::uuid,
 'IELTS Speaking Part 2 - Describe an Achievement',
 'speaking-part2-achievement',
 'Describe something you are proud of',
 'practice', 'speaking', 'hard', 'band 7.0-8.0',
 4, 3, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe something you have achieved that you are proud of.',
 'Describe an achievement',
 ARRAY['What you achieved', 'When you achieved it', 'What difficulties you faced', 'And explain why you are proud of this achievement'],
 60, 120
),

-- Book/Film Topic
('e4000025-0000-0000-0000-000000000025'::uuid,
 'IELTS Speaking Part 2 - Describe a Book or Film',
 'speaking-part2-book-film',
 'Describe a book or film that impressed you',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a book or film that made a strong impression on you.',
 'Describe an impressive book/film',
 ARRAY['What it was about', 'When you read/watched it', 'Why you chose it', 'And explain why it impressed you'],
 60, 120
),

-- Skill Topic
('e4000026-0000-0000-0000-000000000026'::uuid,
 'IELTS Speaking Part 2 - Describe a Skill',
 'speaking-part2-skill',
 'Describe a skill you would like to learn',
 'practice', 'speaking', 'medium', 'band 6.5-7.5',
 4, 3, true, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 2,
 'Describe a skill you would like to learn in the future.',
 'Describe a skill to learn',
 ARRAY['What the skill is', 'Why you want to learn it', 'How you would learn it', 'And explain how this skill would benefit you'],
 60, 120
);

-- ============================================
-- SPEAKING PART 3 - DISCUSSION (5)
-- ============================================

INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, time_limit_minutes, is_free, is_published, created_by,
    speaking_part_number, speaking_prompt_text, speaking_follow_up_questions, speaking_response_time_seconds
) VALUES
-- Education Discussion
('e4000030-0000-0000-0000-000000000030'::uuid,
 'IELTS Speaking Part 3 - Education System',
 'speaking-part3-education',
 'Discuss education-related topics in depth',
 'practice', 'speaking', 'hard', 'band 7.0-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Now let''s talk about education in more general terms.',
 ARRAY[
    'How has education changed in your country over the past few decades?',
    'What role should technology play in education?',
    'Do you think university education should be free for everyone? Why or why not?',
    'How can we make education more accessible to everyone?'
 ],
 300
),

-- Technology Discussion
('e4000031-0000-0000-0000-000000000031'::uuid,
 'IELTS Speaking Part 3 - Technology and Society',
 'speaking-part3-technology',
 'Analyze the impact of technology on society',
 'practice', 'speaking', 'hard', 'band 7.5-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Let''s discuss technology and its impact on society.',
 ARRAY[
    'How has technology changed the way people communicate?',
    'What are the potential dangers of becoming too dependent on technology?',
    'Do you think technology has made people''s lives better or worse overall?',
    'How might technology continue to change society in the future?'
 ],
 300
),

-- Environment Discussion
('e4000032-0000-0000-0000-000000000032'::uuid,
 'IELTS Speaking Part 3 - Environmental Issues',
 'speaking-part3-environment',
 'Discuss environmental challenges and solutions',
 'practice', 'speaking', 'hard', 'band 7.0-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Now I''d like to discuss some environmental issues.',
 ARRAY[
    'What are the biggest environmental challenges facing the world today?',
    'Should governments or individuals be more responsible for protecting the environment?',
    'How can we encourage people to adopt more environmentally friendly behaviors?',
    'Do you think it''s too late to reverse climate change?'
 ],
 300
),

-- Work Discussion
('e4000033-0000-0000-0000-000000000033'::uuid,
 'IELTS Speaking Part 3 - Work and Career',
 'speaking-part3-work-career',
 'Discuss work culture and career development',
 'practice', 'speaking', 'hard', 'band 7.0-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Let''s talk about work and careers.',
 ARRAY[
    'How has the nature of work changed in recent years?',
    'What makes a job satisfying?',
    'Do you think work-life balance is important? Why?',
    'How will the workplace change in the future?'
 ],
 300
),

-- Culture Discussion
('e4000034-0000-0000-0000-000000000034'::uuid,
 'IELTS Speaking Part 3 - Culture and Tradition',
 'speaking-part3-culture',
 'Analyze cultural changes and preservation',
 'practice', 'speaking', 'hard', 'band 7.5-8.5',
 4, 5, false, true, 'b0000001-0000-0000-0000-000000000001'::uuid,
 3,
 'Now let''s discuss culture and tradition.',
 ARRAY[
    'Why is it important to preserve traditional culture?',
    'How is globalization affecting local cultures?',
    'Should young people follow traditional customs?',
    'How can countries maintain their cultural identity in a globalized world?'
 ],
 300
);

-- Update total_questions
UPDATE exercises SET total_questions = 4 WHERE skill_type IN ('writing', 'speaking');

-- ============================================
-- SUMMARY
-- ============================================

SELECT 
    'âœ… Phase Complete: Additional Exercises Added' as status,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'writing') as total_writing,
    (SELECT COUNT(*) FROM exercises WHERE skill_type = 'speaking') as total_speaking,
    (SELECT COUNT(*) FROM exercises) as total_all_exercises;

