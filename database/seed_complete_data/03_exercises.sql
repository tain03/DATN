-- ============================================
-- PHASE 4: EXERCISE_DB - EXERCISES & USER ACTIVITIES
-- ============================================
-- Purpose: Create comprehensive exercises with questions and user attempts
-- Database: exercise_db
-- 
-- IMPORTANT: Run 03_exercises_enhanced.sql after this file for detailed questions
-- 
-- Creates:
-- - Exercises (Listening & Reading)
-- - Exercise sections
-- - Questions with options and answers
-- - User exercise attempts
-- - User answers
-- ============================================

-- ============================================
-- 1. EXERCISES
-- ============================================

-- Listening Exercises
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes, thumbnail_url,
    audio_url, audio_duration_seconds, audio_transcript,
    ielts_test_type,
    course_id,
    is_free, is_published, created_by, published_at, total_attempts, average_score
) VALUES
-- Real YouTube video IDs for IELTS Listening (verified to exist)
-- Format: https://www.youtube.com/watch?v=[VIDEO_ID]
-- List of real videos provided by user:
-- 6QMu7-3DMi0, ys-1LqlUNCk, tml3fxV9w7g, fX3qI4lQ6P0, SeWt7IpZ0CA, oV7qaHKPoK0
-- 9TH5JGYZB4o, vVYONjT2b0Y, kop8O3A-UGs, btAiWvdIxm4, G5orxWQWafI, OZmK0YuSmXU

-- Listening Exercise 1: Beginner - Part 1
('e1000001-0000-0000-0000-000000000001'::uuid, 
 'IELTS Listening Practice Test 1 - Part 1: Social Conversation',
 'ielts-listening-practice-test-1-part-1',
 'Practice IELTS Listening Part 1 with a real social conversation scenario. Perfect for beginners targeting Band 5.5-6.0.',
 'practice', 'listening', 'easy', 'band 5.0-6.0',
 10, 1, 30,
 'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800&h=600&fit=crop',
 'https://www.youtube.com/watch?v=6QMu7-3DMi0', 600, 
 'You will hear a conversation between a student and a housing officer about accommodation...',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000001-0000-0000-0000-000000000001'::uuid, -- Linked to IELTS Listening Basics course
 true, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '60 days', 342, 72.5),

-- Listening Exercise 2: Intermediate - Full Test
('e1000002-0000-0000-0000-000000000002'::uuid,
 'IELTS Listening Full Test - Cambridge 15 Test 1',
 'ielts-listening-full-test-cambridge-15-test-1',
 'Complete IELTS Listening test from Cambridge IELTS 15. All 4 parts included.',
 'full_test', 'listening', 'medium', 'band 6.5-7.0',
 40, 4, 30,
 'https://images.unsplash.com/photo-1589903308904-1010c2294adc?w=800&h=600&fit=crop',
 'https://www.youtube.com/watch?v=ys-1LqlUNCk', 2400,
 'Part 1: You will hear a conversation between a travel agent and a customer...',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000004-0000-0000-0000-000000000004'::uuid, -- Linked to IELTS Listening Full Test Practice course
 false, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '55 days', 289, 68.2),

-- Listening Exercise 3: Advanced - Part 3 & 4
('e1000003-0000-0000-0000-000000000003'::uuid,
 'IELTS Listening Advanced - Parts 3 & 4 Mastery',
 'ielts-listening-advanced-parts-3-4',
 'Advanced practice focusing on the most challenging parts of IELTS Listening.',
 'practice', 'listening', 'hard', 'band 7.5-8.0',
 20, 2, 20,
 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&h=600&fit=crop',
 'https://www.youtube.com/watch?v=tml3fxV9w7g', 840,
 'Part 3: You will hear a discussion between two students and their tutor...',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000003-0000-0000-0000-000000000003'::uuid, -- Linked to IELTS Listening Advanced course
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '50 days', 156, 75.8),

-- Reading Exercises
-- Reading Exercise 1: Beginner - Single Passage
('e2000001-0000-0000-0000-000000000004'::uuid,
 'IELTS Reading Practice - Passage 1: Tourism Industry',
 'ielts-reading-practice-tourism-industry',
 'Academic Reading passage about tourism industry. Perfect for beginners.',
 'practice', 'reading', 'easy', 'band 5.5-6.0',
 13, 1, NULL,
 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000001-0000-0000-0000-000000000005'::uuid, -- Linked to IELTS Reading Fundamentals course
 true, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '45 days', 456, 65.3),

-- Reading Exercise 2: Intermediate - Full Test
('e2000002-0000-0000-0000-000000000005'::uuid,
 'IELTS Academic Reading Full Test - Cambridge 15 Test 2',
 'ielts-academic-reading-full-test-cambridge-15-test-2',
 'Complete Academic Reading test with 3 passages and 40 questions.',
 'full_test', 'reading', 'medium', 'band 6.5-7.0',
 40, 3, 60,
 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800&h=600&fit=crop',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000003-0000-0000-0000-000000000007'::uuid, -- Linked to IELTS Academic Reading Advanced course
 false, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '40 days', 389, 72.1),

-- Reading Exercise 3: Advanced - True/False/Not Given Focus
('e2000003-0000-0000-0000-000000000006'::uuid,
 'IELTS Reading Advanced - True/False/Not Given Mastery',
 'ielts-reading-advanced-true-false-not-given',
 'Advanced practice focusing on the most challenging question type. Master the subtle differences between True, False, and Not Given with comprehensive explanations and extensive practice.',
 'practice', 'reading', 'hard', 'band 7.5-8.0',
 15, 1, 20,
 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&h=600&fit=crop',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000002-0000-0000-0000-000000000006'::uuid, -- Linked to True/False/Not Given Mastery course
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '35 days', 234, 68.5);

-- Additional exercises for main courses (tight coupling)
-- Listening exercises for IELTS Listening Basics course
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes, thumbnail_url,
    audio_url, audio_duration_seconds, audio_transcript,
    ielts_test_type,
    course_id,
    is_free, is_published, created_by, published_at, total_attempts, average_score
) VALUES
-- More exercises for c1000001 (IELTS Listening Basics)
('e1000004-0000-0000-0000-000000000007'::uuid,
 'IELTS Listening Part 1 - Form Completion Practice',
 'ielts-listening-part-1-form-completion-practice',
 'Master Part 1 form completion questions with this focused practice exercise. Learn to identify key information like names, dates, addresses, and phone numbers accurately. Practice with realistic social conversation scenarios featuring everyday situations such as booking accommodation, registering for courses, and making reservations. Includes detailed explanations for common spelling mistakes, number formats, and answer prediction strategies.',
 'practice', 'listening', 'easy', 'band 5.0-6.0',
 10, 1, 20,
 'https://plus.unsplash.com/premium_photo-1681489727671-e4865915197b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
 'https://www.youtube.com/watch?v=6QMu7-3DMi0', 600,
 'You will hear a conversation about booking accommodation. Complete the registration form with the correct information.',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000001-0000-0000-0000-000000000001'::uuid, -- Linked to IELTS Listening Basics
 true, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '55 days', 289, 71.2),

('e1000005-0000-0000-0000-000000000008'::uuid,
 'IELTS Listening Part 1 - Multiple Choice Practice',
 'ielts-listening-part-1-multiple-choice-practice',
 'Develop skills for Part 1 multiple choice questions with authentic practice materials. Learn to identify correct answers while avoiding distractors, understand paraphrasing, and recognize synonyms. Practice with conversations covering common Part 1 topics including accommodation, travel, employment, and daily activities.',
 'practice', 'listening', 'easy', 'band 5.0-6.0',
 10, 1, 20,
 'https://images.unsplash.com/photo-1563120145-ecb346208872?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
 'https://www.youtube.com/watch?v=ys-1LqlUNCk', 650,
 'Listen to a conversation and choose the correct answer for each question.',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000001-0000-0000-0000-000000000001'::uuid, -- Linked to IELTS Listening Basics
 true, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '50 days', 312, 69.8),

-- More exercises for c1000003 (IELTS Listening Advanced)
('e1000006-0000-0000-0000-000000000009'::uuid,
 'IELTS Listening Part 3 - Academic Discussion Practice',
 'ielts-listening-part-3-academic-discussion-practice',
 'Master Part 3 academic discussions with this comprehensive practice exercise. Focus on understanding complex conversations between students and tutors about assignments, research projects, and academic topics. Develop skills for identifying speaker opinions, following multi-speaker discussions, and extracting specific information from academic contexts.',
 'practice', 'listening', 'medium', 'band 6.5-7.0',
 10, 1, NULL,
 'https://plus.unsplash.com/premium_photo-1661490813116-3b678da41ff4?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
 'https://www.youtube.com/watch?v=tml3fxV9w7g', 1200,
 'Listen to a discussion between two students and their tutor about a research project.',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000003-0000-0000-0000-000000000003'::uuid, -- Linked to IELTS Listening Advanced
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '45 days', 178, 74.3),

('e1000007-0000-0000-0000-000000000010'::uuid,
 'IELTS Listening Part 4 - Academic Lecture Practice',
 'ielts-listening-part-4-academic-lecture-practice',
 'Challenge yourself with Part 4 academic lectures covering diverse university-level topics. Practice understanding formal academic language, following complex arguments, and taking effective notes. Learn to identify main ideas, supporting details, and specific information in lecture contexts.',
 'practice', 'listening', 'hard', 'band 7.5-8.0',
 10, 1, NULL,
 'https://plus.unsplash.com/premium_photo-1664382465450-6dc3c2bae5d0?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=764',
 'https://www.youtube.com/watch?v=oV7qaHKPoK0', 1800,
 'Listen to an academic lecture on a scientific topic and answer the questions.',
 NULL, -- ielts_test_type (not needed for listening)
 'c1000003-0000-0000-0000-000000000003'::uuid, -- Linked to IELTS Listening Advanced
 false, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '40 days', 145, 76.1),

-- More exercises for c2000001 (IELTS Reading Fundamentals)
('e2000004-0000-0000-0000-000000000011'::uuid,
 'IELTS Reading - Skimming and Scanning Practice',
 'ielts-reading-skimming-scanning-practice',
 'Master essential reading techniques: skimming for main ideas and scanning for specific information. Practice with carefully selected passages that gradually increase in difficulty, allowing you to build confidence step by step. Learn to identify key information quickly and efficiently.',
 'practice', 'reading', 'easy', 'band 5.5-6.0',
 13, 1, NULL,
 'https://images.unsplash.com/photo-1568667256549-094345857637?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2030',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000001-0000-0000-0000-000000000005'::uuid, -- Linked to IELTS Reading Fundamentals
 true, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '50 days', 423, 67.5),

('e2000005-0000-0000-0000-000000000012'::uuid,
 'IELTS Reading - Multiple Choice Question Practice',
 'ielts-reading-multiple-choice-practice',
 'Develop skills for multiple choice questions with comprehensive practice exercises. Learn to identify main ideas, understand specific details, and recognize paraphrasing in reading passages. Practice eliminating wrong answers and selecting the correct option efficiently.',
 'practice', 'reading', 'easy', 'band 5.5-6.0',
 13, 1, NULL,
 'https://images.unsplash.com/photo-1683871268982-a19153dbb35d?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000001-0000-0000-0000-000000000005'::uuid, -- Linked to IELTS Reading Fundamentals
 true, true, 'b0000002-0000-0000-0000-000000000002'::uuid, NOW() - INTERVAL '48 days', 387, 66.8),

-- More exercises for c2000002 (True/False/Not Given Mastery)
('e2000006-0000-0000-0000-000000000013'::uuid,
 'IELTS Reading - True/False/Not Given Advanced Practice',
 'ielts-reading-true-false-not-given-advanced-practice',
 'Advanced practice with True/False/Not Given questions featuring complex academic passages. Master the subtle differences between what is stated, implied, or not mentioned. Learn to avoid common traps and develop pattern recognition skills for this challenging question type.',
 'practice', 'reading', 'hard', 'band 7.5-8.0',
 15, 1, 20,
 'https://plus.unsplash.com/premium_photo-1750360906456-b28d130fa7f8?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
 NULL, NULL, NULL,
 'academic', -- ielts_test_type required for reading exercises
 'c2000002-0000-0000-0000-000000000006'::uuid, -- Linked to True/False/Not Given Mastery
 false, true, 'b0000003-0000-0000-0000-000000000003'::uuid, NOW() - INTERVAL '42 days', 198, 72.3),

('e2000007-0000-0000-0000-000000000014'::uuid,
 'IELTS Reading - True/False/Not Given Intermediate Practice',
 'ielts-reading-true-false-not-given-intermediate-practice',
 'Intermediate practice with True/False/Not Given questions to build your confidence. Learn proven strategies for identifying factual statements, distinguishing between False and Not Given, and understanding nuanced meanings in reading passages.',
 'practice', 'reading', 'medium', 'band 6.5-7.0',
 14, 1, 18,
 'https://plus.unsplash.com/premium_photo-1750360905827-af6cb76a55bb?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1236',
 NULL, NULL, NULL,
 'general_training', -- ielts_test_type required for reading exercises (30% general_training)
 'c2000002-0000-0000-0000-000000000006'::uuid, -- Linked to True/False/Not Given Mastery
 false, true, 'b0000001-0000-0000-0000-000000000001'::uuid, NOW() - INTERVAL '38 days', 267, 70.5);

-- Insert more exercises using pattern
INSERT INTO exercises (
    id, title, slug, description, exercise_type, skill_type, difficulty, ielts_level,
    total_questions, total_sections, time_limit_minutes, thumbnail_url,
    audio_url, audio_duration_seconds, audio_transcript,
    ielts_test_type,
    course_id,
    is_free, is_published, created_by, published_at, total_attempts, average_score
)
SELECT 
    ('e' || CASE WHEN row_number() OVER () <= 25 THEN '1' ELSE '2' END || 
    LPAD((row_number() OVER () + 10)::text, 6, '0') || '-0000-0000-0000-000000000' || 
    LPAD((row_number() OVER () + 13)::text, 3, '0'))::uuid,
    CASE WHEN row_number() OVER () <= 25 THEN 'IELTS Listening Practice Test ' || (row_number() OVER () + 3)::text
         ELSE 'IELTS Reading Practice Test ' || (row_number() OVER () - 25 + 3)::text
    END,
    'ielts-' || CASE WHEN row_number() OVER () <= 25 THEN 'listening' ELSE 'reading' END || 
    '-practice-test-' || (row_number() OVER () + 3)::text,
    CASE WHEN row_number() OVER () <= 25 THEN
        CASE (random() * 15)::INTEGER
            WHEN 0 THEN 'Master IELTS Listening Part 1 with authentic social conversation scenarios. Practice identifying key information like names, numbers, dates, and addresses in everyday contexts. Perfect for building confidence and improving accuracy in the easiest part of the test.'
            WHEN 1 THEN 'Comprehensive IELTS Listening practice focusing on Part 2 monologues. Learn to follow single-speaker presentations about facilities, services, and general information. Includes detailed explanations for each question type.'
            WHEN 2 THEN 'Advanced Listening practice covering Part 3 academic discussions. Practice understanding complex conversations between students and tutors about assignments, research, and academic topics. Builds critical listening skills.'
            WHEN 3 THEN 'Challenge yourself with Part 4 academic lectures. These exercises feature university-level content on various subjects. Perfect for targeting Band 7.5+ with detailed note-taking strategies.'
            WHEN 4 THEN 'Complete IELTS Listening test simulation with all 4 parts. Timed practice with realistic audio quality and question types. Includes answer explanations and score breakdown to identify improvement areas.'
            WHEN 5 THEN 'Focus on note-taking and multiple-choice questions. Learn effective strategies for managing time and identifying correct answers while listening. Includes practice with distractors and synonyms.'
            WHEN 6 THEN 'Practice with map and diagram labeling exercises. Develop spatial awareness and ability to follow directions accurately. Essential skills for Part 2 of the Listening test.'
            WHEN 7 THEN 'Form completion practice with Part 1 dialogues. Master spelling, numbers, dates, and common vocabulary. Includes pronunciation tips and common spelling mistakes to avoid.'
            WHEN 8 THEN 'Sentence completion and short-answer questions practice. Learn to extract specific information from longer passages. Focus on paraphrasing and understanding key vocabulary.'
            WHEN 9 THEN 'Multiple choice with three options practice. Develop skills to understand main ideas and specific details. Includes strategies for eliminating wrong answers.'
            WHEN 10 THEN 'Table completion exercises for Part 1 and Part 2. Practice organizing information systematically while listening. Builds ability to process information quickly.'
            WHEN 11 THEN 'Matching questions practice for Part 3. Learn to connect information and understand relationships between speakers'' opinions. Includes vocabulary for expressing agreement and disagreement.'
            WHEN 12 THEN 'Academic vocabulary focus for Part 4. Practice recognizing formal language and technical terms in lecture contexts. Essential for understanding complex academic content.'
            WHEN 13 THEN 'Complete test practice with Cambridge-style questions. Realistic exam conditions with professional audio quality. Includes detailed performance analysis and improvement recommendations.'
            ELSE 'Comprehensive listening practice covering all question types and difficulty levels. Designed to systematically improve your listening skills from Band 5.0 to Band 7.0+. Includes tips, strategies, and detailed answer explanations.'
        END
    ELSE
        CASE (random() * 15)::INTEGER
            WHEN 0 THEN 'Master IELTS Reading with authentic academic passages. Learn effective scanning and skimming techniques to find answers quickly. Practice with passages from journals, books, and magazines similar to real exam materials.'
            WHEN 1 THEN 'Comprehensive practice with True/False/Not Given questions. Understand the subtle differences between these answer choices. Includes detailed explanations and strategies for identifying key information.'
            WHEN 2 THEN 'Matching headings practice for Passage 1 and Passage 2. Develop ability to identify main ideas and paragraph structure. Learn effective paragraph analysis techniques.'
            WHEN 3 THEN 'Multiple choice questions with 4 options practice. Master strategies for eliminating wrong answers and identifying correct information. Includes practice with paraphrasing and synonyms.'
            WHEN 4 THEN 'Complete Academic Reading test with 3 passages and 40 questions. Timed practice simulating real exam conditions. Includes detailed answer explanations and vocabulary building exercises.'
            WHEN 5 THEN 'Sentence completion and summary completion practice. Learn to locate specific information and understand text structure. Essential skills for achieving Band 6.5+ in Reading.'
            WHEN 6 THEN 'Matching information to paragraphs practice. Develop ability to scan for specific details and understand text organization. Includes practice with complex academic vocabulary.'
            WHEN 7 THEN 'Flow-chart and diagram completion exercises. Practice understanding processes and visual information from text. Useful for both Academic and General Training modules.'
            WHEN 8 THEN 'Short-answer questions practice focusing on factual information. Learn to locate exact answers quickly and efficiently. Includes strategies for time management.'
            WHEN 9 THEN 'Reading for main ideas and details practice. Develop both intensive and extensive reading skills. Includes practice with inference and understanding writer''s opinions.'
            WHEN 10 THEN 'Academic vocabulary focus with high-frequency IELTS words. Practice understanding context and meaning from surrounding text. Essential for comprehending complex passages.'
            WHEN 11 THEN 'Matching sentence endings practice. Develop understanding of sentence structure and logical connections. Includes practice with grammatical patterns and cohesive devices.'
            WHEN 12 THEN 'Complex passage analysis with advanced vocabulary. Practice with university-level texts on various academic subjects. Perfect for targeting Band 7.5+ scores.'
            WHEN 13 THEN 'Complete test practice with Cambridge IELTS authentic materials. Realistic exam format with detailed explanations. Includes performance tracking and improvement areas identification.'
            ELSE 'Comprehensive reading practice covering all question types and passages. Designed to systematically improve reading speed and comprehension. Includes time management strategies and detailed answer explanations.'
        END
    END,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'practice' WHEN 1 THEN 'mock_test' ELSE 'full_test' END,
    CASE WHEN row_number() OVER () <= 25 THEN 'listening' ELSE 'reading' END,
    -- Difficulty mapped to course levels for tight coupling
    CASE WHEN row_number() OVER () <= 25 THEN 
        -- Listening exercises: map difficulty to course level
        CASE 
            WHEN (row_number() OVER () % 10) IN (0, 1, 2) THEN 'easy' -- Maps to beginner course (c1000001)
            WHEN (row_number() OVER () % 10) IN (3, 4, 5, 6) THEN 'medium' -- Maps to intermediate course (c1000003)
            ELSE 'hard' -- Maps to advanced course (c1000004)
        END
    ELSE
        -- Reading exercises: map difficulty to course level
        CASE 
            WHEN (row_number() OVER () % 10) IN (0, 1, 2) THEN 'easy' -- Maps to beginner course (c2000001)
            WHEN (row_number() OVER () % 10) IN (3, 4, 5, 6) THEN 'medium' -- Maps to intermediate course (c2000002)
            ELSE 'hard' -- Maps to advanced course (c2000003)
        END
    END,
    CASE (random() * 3)::INTEGER 
        WHEN 0 THEN 'band 5.0-6.0'
        WHEN 1 THEN 'band 6.5-7.0'
        ELSE 'band 7.5-8.0'
    END,
    CASE WHEN row_number() OVER () <= 25 THEN 10 + (random() * 30)::INTEGER ELSE 13 + (random() * 27)::INTEGER END,
    CASE WHEN row_number() OVER () <= 25 THEN 1 + (random() * 3)::INTEGER ELSE 1 + (random() * 2)::INTEGER END,
    CASE WHEN row_number() OVER () <= 25 THEN 30 ELSE NULL END,
    -- Diverse thumbnail URLs based on skill type
    CASE WHEN row_number() OVER () <= 25 THEN -- Listening exercises
        (ARRAY[
            'https://plus.unsplash.com/premium_photo-1681489727671-e4865915197b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
            'https://images.unsplash.com/photo-1563120145-ecb346208872?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://plus.unsplash.com/premium_photo-1661490813116-3b678da41ff4?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://plus.unsplash.com/premium_photo-1664382465450-6dc3c2bae5d0?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=764',
            'https://images.unsplash.com/photo-1599139894727-62676829679b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1074',
            'https://images.unsplash.com/photo-1590650046871-92c887180603?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://images.unsplash.com/photo-1526662092594-e98c1e356d6a?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1171',
            'https://plus.unsplash.com/premium_photo-1723924809917-c0b1b5d6f53b?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170'
        ])[1 + ((row_number() OVER ()) % 8)]
    ELSE -- Reading exercises
        (ARRAY[
            'https://images.unsplash.com/photo-1568667256549-094345857637?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2030',
            'https://images.unsplash.com/photo-1683871268982-a19153dbb35d?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://plus.unsplash.com/premium_photo-1750360906456-b28d130fa7f8?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://plus.unsplash.com/premium_photo-1750360905827-af6cb76a55bb?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1236',
            'https://images.unsplash.com/photo-1662582631700-676a217d511f?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
            'https://images.unsplash.com/photo-1706210880873-87d8a1ebd3af?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://images.unsplash.com/photo-1648999528869-5292670c6681?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
            'https://images.unsplash.com/photo-1553729784-e91953dec042?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1170',
            'https://images.unsplash.com/photo-1620701168009-da332c79c2dc?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687'
        ])[1 + ((row_number() OVER ()) % 9)]
    END,
    -- Real YouTube video IDs for Listening exercises (rotating through verified videos)
    CASE WHEN row_number() OVER () <= 25 THEN 
        CASE (row_number() OVER () % 6)
            WHEN 0 THEN 'https://www.youtube.com/watch?v=6QMu7-3DMi0'
            WHEN 1 THEN 'https://www.youtube.com/watch?v=ys-1LqlUNCk'
            WHEN 2 THEN 'https://www.youtube.com/watch?v=tml3fxV9w7g'
            WHEN 3 THEN 'https://www.youtube.com/watch?v=oV7qaHKPoK0'
            WHEN 4 THEN 'https://www.youtube.com/watch?v=9TH5JGYZB4o'
            ELSE 'https://www.youtube.com/watch?v=vVYONjT2b0Y'
        END
    ELSE NULL END,
    CASE WHEN row_number() OVER () <= 25 THEN 
        -- Realistic audio durations based on IELTS Listening parts:
        -- Part 1: 5-7 minutes (300-420 seconds)
        -- Part 2: 6-8 minutes (360-480 seconds)
        -- Part 3: 8-10 minutes (480-600 seconds)
        -- Part 4: 10-12 minutes (600-720 seconds)
        -- Full test: 30 minutes (1800 seconds)
        CASE 
            WHEN (row_number() OVER () % 10) IN (0, 1, 2) THEN 
                -- Part 1 exercises: 5-7 minutes
                300 + ((row_number() OVER () % 3) * 60)::INTEGER
            WHEN (row_number() OVER () % 10) IN (3, 4, 5, 6) THEN 
                -- Part 2-3 exercises: 6-9 minutes
                360 + ((row_number() OVER () % 4) * 60)::INTEGER
            ELSE 
                -- Part 4 exercises: 8-12 minutes
                480 + ((row_number() OVER () % 5) * 60)::INTEGER
        END
    ELSE NULL END,
    CASE WHEN row_number() OVER () <= 25 THEN 'Transcript for listening exercise...' ELSE NULL END,
    -- ielts_test_type: Required for reading exercises only (academic or general_training)
    CASE WHEN row_number() OVER () > 25 THEN 
        -- Reading exercises: 70% academic, 30% general_training
        CASE WHEN random() > 0.3 THEN 'academic' ELSE 'general_training' END
    ELSE NULL END,
    -- Link to course (80% linked to courses for tight coupling, 20% standalone)
    -- Exercises are strongly linked to courses for better learning paths
    CASE WHEN random() > 0.2 THEN -- 80% linked to courses
        CASE WHEN row_number() OVER () <= 25 THEN 
            -- Listening exercises linked to listening courses based on difficulty
            CASE 
                WHEN (row_number() OVER () % 10) IN (0, 1, 2) THEN 'c1000001-0000-0000-0000-000000000001'::uuid -- IELTS Listening Basics (easy exercises)
                WHEN (row_number() OVER () % 10) IN (3, 4, 5, 6) THEN 'c1000003-0000-0000-0000-000000000003'::uuid -- IELTS Listening Advanced (medium-hard exercises)
                WHEN (row_number() OVER () % 10) IN (7, 8, 9) THEN 'c1000004-0000-0000-0000-000000000004'::uuid -- IELTS Listening Full Test Practice (full test exercises)
                ELSE 'c1000001-0000-0000-0000-000000000001'::uuid -- Default fallback
            END
        ELSE
            -- Reading exercises linked to reading courses based on difficulty
            CASE 
                WHEN (row_number() OVER () % 10) IN (0, 1, 2) THEN 'c2000001-0000-0000-0000-000000000005'::uuid -- IELTS Reading Fundamentals (easy exercises)
                WHEN (row_number() OVER () % 10) IN (3, 4, 5, 6) THEN 'c2000002-0000-0000-0000-000000000006'::uuid -- True/False/Not Given Mastery (medium exercises)
                WHEN (row_number() OVER () % 10) IN (7, 8, 9) THEN 'c2000003-0000-0000-0000-000000000007'::uuid -- IELTS Academic Reading Advanced (hard exercises)
                ELSE 'c2000001-0000-0000-0000-000000000005'::uuid -- Default fallback
            END
        END
    ELSE NULL END, -- 20% standalone exercises for general practice
    CASE WHEN random() > 0.6 THEN true ELSE false END,
    true,
    ('b' || LPAD((1 + (random() * 14)::INTEGER)::text, 7, '0') || '-0000-0000-0000-000000000' ||
    LPAD((1 + (random() * 14)::INTEGER)::text, 3, '0'))::uuid,
    NOW() - (random() * 60)::INTEGER * INTERVAL '1 day',
    (random() * 400 + 50)::INTEGER,
    (random() * 30 + 60)::DECIMAL(5,2)
FROM generate_series(1, 60);

-- ============================================
-- 2. EXERCISE_SECTIONS
-- ============================================

-- Sections for Listening Full Test (4 parts)
INSERT INTO exercise_sections (
    id, exercise_id, title, description, section_number, audio_url, audio_start_time, audio_end_time,
    transcript, instructions, total_questions, time_limit_minutes, display_order
)
SELECT 
    uuid_generate_v4(),
    'e1000002-0000-0000-0000-000000000002'::uuid,
    'Part ' || section_number || ': ' || 
    CASE section_number
        WHEN 1 THEN 'Social Conversation'
        WHEN 2 THEN 'Monologue'
        WHEN 3 THEN 'Academic Conversation'
        WHEN 4 THEN 'Academic Lecture'
    END,
    'IELTS Listening Part ' || section_number,
    section_number,
    -- Real YouTube video URL for Listening sections
    CASE section_number
        WHEN 1 THEN 'https://www.youtube.com/watch?v=6QMu7-3DMi0'
        WHEN 2 THEN 'https://www.youtube.com/watch?v=ys-1LqlUNCk'
        WHEN 3 THEN 'https://www.youtube.com/watch?v=tml3fxV9w7g'
        ELSE 'https://www.youtube.com/watch?v=oV7qaHKPoK0'
    END,
    -- audio_start_time: Start from 0 for Part 1, then increment
    -- Total exercise duration is 1800 seconds (30 minutes), divided into 4 parts of ~450 seconds each
    -- Realistic IELTS Listening test: Part 1 (~5 min), Part 2 (~6 min), Part 3 (~7 min), Part 4 (~7 min)
    CASE section_number
        WHEN 1 THEN 0
        WHEN 2 THEN 300  -- ~5 minutes
        WHEN 3 THEN 660  -- ~11 minutes (5+6)
        ELSE 1080  -- ~18 minutes (5+6+7)
    END,
    -- audio_end_time: Should match realistic section durations
    -- Part 1: 5 minutes (300s), Part 2: 6 minutes (360s), Part 3: 7 minutes (420s), Part 4: 7 minutes (420s)
    CASE section_number
        WHEN 1 THEN 300  -- Part 1: 5 minutes
        WHEN 2 THEN 660  -- Part 2: 11 minutes total (5+6)
        WHEN 3 THEN 1080 -- Part 3: 18 minutes total (5+6+7)
        ELSE 1800  -- Part 4: 30 minutes total (5+6+7+7)
    END,
    'Transcript for Part ' || section_number || '...',
    'Listen carefully and answer questions ' || ((section_number - 1) * 10 + 1) || ' to ' || (section_number * 10),
    10,
    NULL,
    section_number
FROM generate_series(1, 4) AS section_number;

-- Sections for Reading Full Test (3 passages)
INSERT INTO exercise_sections (
    id, exercise_id, title, description, section_number, passage_title, passage_content,
    passage_word_count, instructions, total_questions, time_limit_minutes, display_order
)
SELECT 
    uuid_generate_v4(),
    'e2000002-0000-0000-0000-000000000005'::uuid,
    'Passage ' || section_number,
    'Reading Passage ' || section_number || ' from Academic test',
    section_number,
    CASE section_number
        WHEN 1 THEN 'The Development of Writing Systems'
        WHEN 2 THEN 'Climate Change and Agriculture'
        WHEN 3 THEN 'The Psychology of Memory'
    END,
    'The passage discusses ' || 
    CASE section_number
        WHEN 1 THEN 'the historical development of writing systems across different civilizations...'
        WHEN 2 THEN 'the impact of climate change on global agriculture and food security...'
        WHEN 3 THEN 'various theories and research findings about human memory and cognition...'
    END || ' [Full passage content would be here with 800-900 words]',
    (800 + random() * 100)::INTEGER,
    'Read the passage and answer questions ' || ((section_number - 1) * 13 + 1) || ' to ' || 
    CASE section_number WHEN 3 THEN '40' ELSE (section_number * 13)::text END,
    CASE section_number WHEN 3 THEN 14 ELSE 13 END,
    20,
    section_number
FROM generate_series(1, 3) AS section_number;

-- Generate sections for other exercises
INSERT INTO exercise_sections (
    id, exercise_id, title, description, section_number, audio_url, audio_start_time, audio_end_time,
    transcript, instructions, total_questions, display_order
)
SELECT 
    uuid_generate_v4(),
    e.id,
    CASE WHEN e.skill_type = 'listening' THEN 'Part 1' ELSE 'Passage 1' END,
    'First section of ' || e.title,
    1,
    -- Real YouTube video URL for Listening sections
    CASE WHEN e.skill_type = 'listening' THEN 
        CASE ((row_number() OVER ()) % 6)
            WHEN 0 THEN 'https://www.youtube.com/watch?v=6QMu7-3DMi0'
            WHEN 1 THEN 'https://www.youtube.com/watch?v=ys-1LqlUNCk'
            WHEN 2 THEN 'https://www.youtube.com/watch?v=tml3fxV9w7g'
            WHEN 3 THEN 'https://www.youtube.com/watch?v=oV7qaHKPoK0'
            WHEN 4 THEN 'https://www.youtube.com/watch?v=9TH5JGYZB4o'
            ELSE 'https://www.youtube.com/watch?v=vVYONjT2b0Y'
        END
    ELSE NULL END,
    CASE WHEN e.skill_type = 'listening' THEN 0 ELSE NULL END,
    -- audio_end_time: Should match audio_duration_seconds from exercise
    -- For single section exercises, end_time = audio_duration_seconds
    -- For multi-section exercises, divide evenly based on total sections
    CASE WHEN e.skill_type = 'listening' AND e.audio_duration_seconds IS NOT NULL THEN 
        CASE 
            WHEN e.total_sections = 1 THEN e.audio_duration_seconds
            ELSE (e.audio_duration_seconds / e.total_sections)::INTEGER
        END
    ELSE NULL END,
    -- Note: audio_start_time is 0 for first section, audio_end_time matches duration
    -- For multi-section exercises, start_time and end_time should be calculated based on section_number
    -- But since we're only creating section 1 here, end_time = total duration for single section
    CASE WHEN e.skill_type = 'listening' THEN 'Transcript for this section...' ELSE NULL END,
    'Answer all questions in this section',
    CASE WHEN e.total_sections = 1 THEN e.total_questions ELSE (e.total_questions / e.total_sections)::INTEGER END,
    1
FROM exercises e
WHERE e.total_sections > 0 
  AND NOT EXISTS (
      SELECT 1 FROM exercise_sections es WHERE es.exercise_id = e.id
  )
LIMIT 50;

-- ============================================
-- 3. QUESTIONS
-- ============================================

-- Questions for Listening Exercise 1 (Part 1 - 10 questions)
INSERT INTO questions (
    id, exercise_id, section_id, question_number, question_text, question_type,
    points, difficulty, explanation, tips, display_order
)
SELECT 
    uuid_generate_v4(),
    'e1000001-0000-0000-0000-000000000001'::uuid,
    (SELECT id FROM exercise_sections WHERE exercise_id = 'e1000001-0000-0000-0000-000000000001' LIMIT 1),
    q_num,
    CASE q_num
        WHEN 1 THEN 'What type of accommodation is the student looking for?'
        WHEN 2 THEN 'How much does the student want to pay per week?'
        WHEN 3 THEN 'Which area does the student prefer?'
        WHEN 4 THEN 'What is the student''s name?'
        WHEN 5 THEN 'What is the student''s phone number?'
        WHEN 6 THEN 'When does the student want to move in?'
        WHEN 7 THEN 'What furniture does the student need?'
        WHEN 8 THEN 'Does the student have any pets?'
        WHEN 9 THEN 'What is the student''s occupation?'
        WHEN 10 THEN 'What is the student''s email address?'
    END,
    CASE WHEN q_num <= 6 THEN 'multiple_choice' ELSE 'fill_in_blank' END,
    1.0,
    'easy',
    'The correct answer can be found in the conversation.',
    'Listen carefully for key information and numbers.',
    q_num
FROM generate_series(1, 10) q_num;

-- Questions for Reading Exercise 1 (13 questions)
INSERT INTO questions (
    id, exercise_id, section_id, question_number, question_text, question_type,
    points, difficulty, explanation, tips, display_order
)
SELECT 
    uuid_generate_v4(),
    'e2000001-0000-0000-0000-000000000004'::uuid,
    (SELECT id FROM exercise_sections WHERE exercise_id = 'e2000001-0000-0000-0000-000000000004' LIMIT 1),
    q_num,
    CASE 
        WHEN q_num <= 6 THEN 'Questions ' || q_num || ': Choose the correct letter A, B, C or D.'
        WHEN q_num <= 9 THEN 'Questions ' || q_num || ': Do the following statements agree with the information given in the passage? Write TRUE, FALSE, or NOT GIVEN.'
        ELSE 'Questions ' || q_num || ': Complete the sentences below. Choose NO MORE THAN TWO WORDS from the passage for each answer.'
    END,
    CASE 
        WHEN q_num <= 6 THEN 'multiple_choice'
        WHEN q_num <= 9 THEN 'true_false_not_given'
        ELSE 'sentence_completion'
    END,
    1.0,
    CASE WHEN q_num <= 6 THEN 'easy' WHEN q_num <= 9 THEN 'medium' ELSE 'easy' END,
    'Refer to the relevant section of the passage to find the answer.',
    CASE 
        WHEN q_num <= 6 THEN 'Read all options carefully before choosing.'
        WHEN q_num <= 9 THEN 'Focus on the exact meaning of the statement.'
        ELSE 'Look for synonyms and paraphrasing in the passage.'
    END,
    q_num
FROM generate_series(1, 13) q_num;

-- Generate questions for remaining exercises
INSERT INTO questions (
    id, exercise_id, section_id, question_number, question_text, question_type,
    points, difficulty, explanation, tips, display_order
)
SELECT 
    uuid_generate_v4(),
    e.id,
    (SELECT id FROM exercise_sections WHERE exercise_id = e.id LIMIT 1),
    q_num,
    CASE 
        WHEN e.skill_type = 'listening' THEN
            CASE (q_num % 4)
                WHEN 0 THEN 'Question ' || q_num || ': Complete the form below. Write NO MORE THAN THREE WORDS AND/OR A NUMBER for each answer.'
                WHEN 1 THEN 'Question ' || q_num || ': Choose the correct letter A, B, C or D.'
                WHEN 2 THEN 'Question ' || q_num || ': Complete the notes below. Write NO MORE THAN TWO WORDS for each answer.'
                ELSE 'Question ' || q_num || ': Label the map below. Choose FIVE answers from the box.'
            END
        ELSE
            CASE (q_num % 5)
                WHEN 0 THEN 'Question ' || q_num || ': Choose the correct letter A, B, C or D.'
                WHEN 1 THEN 'Question ' || q_num || ': Do the following statements agree with the information? Write TRUE, FALSE, or NOT GIVEN.'
                WHEN 2 THEN 'Question ' || q_num || ': Match each heading with the correct paragraph A-G.'
                WHEN 3 THEN 'Question ' || q_num || ': Complete the summary below. Choose NO MORE THAN TWO WORDS from the passage.'
                ELSE 'Question ' || q_num || ': Look at the following statements and the list of people below. Match each statement with the correct person.'
            END
    END,
    CASE 
        WHEN e.skill_type = 'listening' THEN
            CASE (q_num % 4)
                WHEN 0 THEN 'fill_in_blank'
                WHEN 1 THEN 'multiple_choice'
                WHEN 2 THEN 'sentence_completion'
                ELSE 'diagram_labeling'
            END
        ELSE
            CASE (q_num % 5)
                WHEN 0 THEN 'multiple_choice'
                WHEN 1 THEN 'true_false_not_given'
                WHEN 2 THEN 'matching_headings'
                WHEN 3 THEN 'sentence_completion'
                ELSE 'matching'
            END
    END,
    1.0,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'easy' WHEN 1 THEN 'medium' ELSE 'hard' END,
    'Refer to the relevant section of the ' || CASE WHEN e.skill_type = 'listening' THEN 'audio' ELSE 'passage' END || ' to find the answer.',
    'Read carefully and look for key information.',
    q_num
FROM exercises e
CROSS JOIN generate_series(1, 20) q_num
WHERE e.id NOT IN ('e1000001-0000-0000-0000-000000000001', 'e2000001-0000-0000-0000-000000000004')
  AND q_num <= e.total_questions
LIMIT 800;

-- ============================================
-- 4. QUESTION_OPTIONS (for multiple choice)
-- ============================================

INSERT INTO question_options (
    id, question_id, option_label, option_text, is_correct, display_order
)
SELECT 
    uuid_generate_v4(),
    q.id,
    chr(64 + opt_num), -- A, B, C, D
    CASE opt_num
        WHEN 1 THEN 'Option A: ' || CASE (random() * 4)::INTEGER
            WHEN 0 THEN 'Student accommodation'
            WHEN 1 THEN 'Shared apartment'
            WHEN 2 THEN 'Private room'
            ELSE 'Homestay'
        END
        WHEN 2 THEN 'Option B: ' || CASE (random() * 4)::INTEGER
            WHEN 0 THEN 'City center'
            WHEN 1 THEN 'Near university'
            WHEN 2 THEN 'Quiet area'
            ELSE 'Suburban'
        END
        WHEN 3 THEN 'Option C: ' || CASE (random() * 4)::INTEGER
            WHEN 0 THEN 'Fully furnished'
            WHEN 1 THEN 'Partially furnished'
            WHEN 2 THEN 'Unfurnished'
            ELSE 'Semi-furnished'
        END
        ELSE 'Option D: ' || CASE (random() * 4)::INTEGER
            WHEN 0 THEN 'Immediately'
            WHEN 1 THEN 'Next month'
            WHEN 2 THEN 'Next week'
            ELSE 'In two weeks'
        END
    END,
    CASE WHEN opt_num = 1 THEN true ELSE false END, -- First option is correct (simplified)
    opt_num
FROM questions q
CROSS JOIN generate_series(1, 4) opt_num
WHERE q.question_type = 'multiple_choice'
LIMIT 1200;

-- ============================================
-- 5. QUESTION_ANSWERS (for fill-in-blank, matching, etc.)
-- ============================================

INSERT INTO question_answers (
    id, question_id, answer_text, answer_variations, is_primary_answer
)
SELECT 
    uuid_generate_v4(),
    q.id,
    CASE q.question_type
        WHEN 'fill_in_blank' THEN CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'accommodation'
            WHEN 1 THEN 'university'
            WHEN 2 THEN 'library'
            WHEN 3 THEN 'student'
            ELSE 'apartment'
        END
        WHEN 'sentence_completion' THEN CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'research study'
            WHEN 1 THEN 'climate change'
            WHEN 2 THEN 'economic growth'
            WHEN 3 THEN 'social media'
            ELSE 'technology'
        END
        WHEN 'true_false_not_given' THEN CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'TRUE'
            WHEN 1 THEN 'FALSE'
            ELSE 'NOT GIVEN'
        END
        ELSE 'Answer ' || (random() * 10 + 1)::INTEGER::text
    END,
    CASE WHEN random() > 0.7 THEN ARRAY['alternative spelling', 'alternative form'] ELSE NULL END,
    true
FROM questions q
WHERE q.question_type IN ('fill_in_blank', 'sentence_completion', 'true_false_not_given', 'matching', 'diagram_labeling', 'short_answer')
  -- Ensure all fill questions have at least one answer
  AND NOT EXISTS (
      SELECT 1 FROM question_answers qa WHERE qa.question_id = q.id
  );

-- ============================================
-- 6. USER_EXERCISE_ATTEMPTS
-- ============================================
-- Note: user_id references users from auth_db (not user_profiles from user_db)
-- IMPORTANT: Only use actual student user IDs from auth_db (f0000001 to f0000050)
-- This ensures tight coupling with auth_db users

-- Create CTE with actual student user IDs (matching auth_db pattern)
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
),
attempt_data AS (
    SELECT 
        uuid_generate_v4() as id,
        su.user_id,
        e.id as exercise_id,
        ROW_NUMBER() OVER (PARTITION BY su.user_id, e.id ORDER BY random()) as attempt_number,
        CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'completed'
            WHEN 1 THEN 'in_progress'
            ELSE 'abandoned'
        END as status_val,
        CURRENT_TIMESTAMP - (random() * 60)::INTEGER * INTERVAL '1 day' - (random() * 23)::INTEGER * INTERVAL '1 hour' as started_at
    FROM exercises e
    CROSS JOIN student_users su
    WHERE random() > 0.5 -- 50% chance for each attempt
)
INSERT INTO user_exercise_attempts (
    id, user_id, exercise_id, attempt_number, status,
    total_questions, questions_answered, correct_answers, score, band_score,
    time_limit_minutes, time_spent_seconds, started_at, completed_at, device_type
)
SELECT 
    ad.id,
    ad.user_id,
    ad.exercise_id,
    ad.attempt_number,
    ad.status_val,
    e.total_questions,
    CASE WHEN ad.status_val != 'abandoned' THEN e.total_questions ELSE (random() * (e.total_questions - 1) + 1)::INTEGER END,
    CASE WHEN ad.status_val = 'completed' THEN 
        (random() * (e.total_questions * 0.4) + e.total_questions * 0.6)::INTEGER
    ELSE (random() * e.total_questions * 0.5)::INTEGER END,
    CASE WHEN ad.status_val = 'completed' THEN (random() * 30 + 60)::DECIMAL(5,2) ELSE NULL END,
    CASE WHEN ad.status_val = 'completed' AND random() > 0.3 THEN 
        CASE e.skill_type
            WHEN 'listening' THEN (random() * 5.0 + 4.0)::DECIMAL(2,1)
            WHEN 'reading' THEN (random() * 5.0 + 4.0)::DECIMAL(2,1)
            ELSE NULL
        END
    ELSE NULL END,
    e.time_limit_minutes,
    CASE WHEN ad.status_val != 'abandoned' THEN 
        COALESCE(e.time_limit_minutes * 60, (random() * 1800 + 600)::INTEGER)
    ELSE (random() * 600)::INTEGER END,
    ad.started_at,
    -- completed_at: ONLY when status = 'completed', MUST be AFTER started_at and BEFORE NOW
    -- Use a minimum of 10 minutes (600 seconds) to ensure realistic duration
    CASE WHEN ad.status_val = 'completed' THEN 
        LEAST(
            ad.started_at + (random() * 1800 + 600)::INTEGER * INTERVAL '1 second',
            NOW() - INTERVAL '1 second'
        )
    ELSE NULL END,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'web' WHEN 1 THEN 'android' ELSE 'ios' END
FROM attempt_data ad
JOIN exercises e ON e.id = ad.exercise_id
LIMIT 500;

-- ============================================
-- 7. USER_ANSWERS
-- ============================================
-- IMPORTANT: Only create answers for completed attempts
-- This ensures tight coupling: user_answers -> user_exercise_attempts -> exercises

INSERT INTO user_answers (
    id, attempt_id, question_id, user_id, answer_text, selected_option_id,
    is_correct, points_earned, time_spent_seconds, answered_at
)
SELECT 
    uuid_generate_v4(),
    uea.id,
    q.id,
    uea.user_id,
    CASE WHEN q.question_type IN ('fill_in_blank', 'sentence_completion') THEN
        CASE WHEN random() > 0.4 THEN 
            COALESCE(
                (SELECT answer_text FROM question_answers WHERE question_id = q.id LIMIT 1),
                'answer'
            )
        ELSE 'wrong answer'
        END
    ELSE NULL END,
    selected_opt.id as selected_option_id,
    -- Calculate correctness: check if selected option is correct
    COALESCE(selected_opt.is_correct, false) as is_correct,
    CASE WHEN COALESCE(selected_opt.is_correct, false) THEN 1.0 ELSE 0.0 END,
    (random() * 120 + 30)::INTEGER,
    -- answered_at: MUST be AFTER started_at and BEFORE completed_at (if completed)
    -- Ensure sequential order: started_at <= answered_at <= completed_at (or NOW)
    -- Use LEAST to ensure answered_at never exceeds completed_at
    CASE 
        WHEN uea.completed_at IS NOT NULL THEN
            LEAST(
                uea.started_at + (random() * EXTRACT(EPOCH FROM (uea.completed_at - uea.started_at)))::INTEGER * INTERVAL '1 second',
                uea.completed_at - INTERVAL '1 second'
            )
        ELSE
            uea.started_at + (random() * EXTRACT(EPOCH FROM (NOW() - uea.started_at)))::INTEGER * INTERVAL '1 second'
    END
FROM user_exercise_attempts uea
JOIN exercises e ON e.id = uea.exercise_id
JOIN questions q ON q.exercise_id = e.id
LEFT JOIN LATERAL (
    SELECT id, is_correct
    FROM question_options
    WHERE question_id = q.id
    ORDER BY CASE WHEN random() > 0.4 THEN 
        CASE WHEN is_correct THEN 0 ELSE 1 END
    ELSE random() END
    LIMIT 1
) selected_opt ON q.question_type = 'multiple_choice'
WHERE uea.status = 'completed'
  AND uea.started_at IS NOT NULL
  AND (uea.completed_at IS NULL OR uea.completed_at >= uea.started_at)
  AND q.display_order <= uea.questions_answered
  AND q.display_order <= COALESCE(uea.total_questions, 999)
ORDER BY uea.id, q.display_order
LIMIT 8000;

-- Update exercise statistics to match actual data
UPDATE exercises e
SET 
    total_questions = (SELECT COUNT(*) FROM questions q WHERE q.exercise_id = e.id),
    total_sections = (SELECT COUNT(*) FROM exercise_sections es WHERE es.exercise_id = e.id),
    total_attempts = (SELECT COUNT(*) FROM user_exercise_attempts uea WHERE uea.exercise_id = e.id),
    average_score = (
        SELECT COALESCE(AVG(score), 0)
        FROM user_exercise_attempts uea
        WHERE uea.exercise_id = e.id AND uea.score IS NOT NULL
    )
WHERE e.id IN (
    SELECT DISTINCT e2.id FROM exercises e2
    WHERE e2.total_questions != (SELECT COUNT(*) FROM questions q WHERE q.exercise_id = e2.id)
       OR e2.total_sections != (SELECT COUNT(*) FROM exercise_sections es WHERE es.exercise_id = e2.id)
       OR e2.total_attempts != (SELECT COUNT(*) FROM user_exercise_attempts uea WHERE uea.exercise_id = e2.id)
);

-- Update exercise_sections.total_questions to match actual question count
-- This ensures tight coupling: section.total_questions = actual count of questions in that section
UPDATE exercise_sections es
SET 
    total_questions = (
        SELECT COUNT(*) 
        FROM questions q 
        WHERE q.section_id = es.id
    )
WHERE es.id IN (
    SELECT DISTINCT es2.id 
    FROM exercise_sections es2
    WHERE es2.total_questions != (
        SELECT COUNT(*) 
        FROM questions q 
        WHERE q.section_id = es2.id
    )
);

-- Note: lesson_id will be set separately if needed via application logic
-- Cross-database joins are not supported in microservices architecture
-- Exercises can be:
-- 1. Standalone (course_id = NULL, lesson_id = NULL)
-- 2. Linked to course only (course_id IS NOT NULL, lesson_id = NULL)
-- 3. Linked to both course and lesson (course_id IS NOT NULL, lesson_id IS NOT NULL)
-- Application should handle lesson_id linking when accessing exercises

-- Summary
SELECT 
    'âœ… Phase 4 Complete: Exercises Created' as status,
    (SELECT COUNT(*) FROM exercises) as total_exercises,
    (SELECT COUNT(*) FROM exercise_sections) as total_sections,
    (SELECT COUNT(*) FROM questions) as total_questions,
    (SELECT COUNT(*) FROM question_options) as total_options,
    (SELECT COUNT(*) FROM question_answers) as total_answers,
    (SELECT COUNT(*) FROM user_exercise_attempts) as total_attempts,
    (SELECT COUNT(*) FROM user_answers) as total_user_answers;

