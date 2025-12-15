-- ============================================
-- ENHANCED REALISTIC IELTS QUESTIONS
-- ============================================
-- Purpose: Add detailed, realistic IELTS questions with proper options and answers
-- This file supplements 03_exercises.sql with detailed question content
-- ============================================

-- ============================================
-- DETAILED LISTENING QUESTIONS FOR EXERCISE 1
-- ============================================
-- Update questions for Listening Exercise 1 with realistic IELTS Part 1 content

-- First, let's ensure we have proper sections
DO $$
DECLARE
    v_section_id UUID;
    v_exercise_id UUID := 'e1000001-0000-0000-0000-000000000001'::uuid;
BEGIN
    -- Get or create section for this exercise
    SELECT id INTO v_section_id FROM exercise_sections 
    WHERE exercise_id = v_exercise_id LIMIT 1;
    
    IF v_section_id IS NULL THEN
        INSERT INTO exercise_sections (
            id, exercise_id, title, description, section_number,
            audio_url, audio_start_time, audio_end_time,
            transcript, instructions, total_questions, display_order
        ) VALUES (
            uuid_generate_v4(),
            v_exercise_id,
            'Part 1: Social Conversation',
            'A conversation between a student and accommodation officer',
            1,
            'https://www.youtube.com/watch?v=6QMu7-3DMi0',
            0,
            600,
            'OFFICER: Good morning. How can I help you today?
STUDENT: Hi, I''m looking for accommodation near the university.
OFFICER: I see. What type of accommodation are you interested in?
STUDENT: Well, I''d prefer a shared apartment if possible. Something affordable.
OFFICER: Of course. What''s your budget per week?
STUDENT: I''m hoping to spend around Â£120 per week, maximum Â£150.
OFFICER: Right. And which area would you prefer?
STUDENT: I''d like to be close to the university, maybe within walking distance.
OFFICER: We have a few options. Can I take your details first?
STUDENT: Sure. My name is James Mitchell. That''s M-I-T-C-H-E-L-L.
OFFICER: Thank you. And your phone number?
STUDENT: It''s 07782 459301.
OFFICER: Right. And when would you like to move in?
STUDENT: I''m hoping to move in on the 15th of September, if possible.
OFFICER: Let me check... Yes, we have availability from that date. Do you need any furniture?
STUDENT: Yes, I''d need a bed and a desk at least. A wardrobe would be nice too.
OFFICER: Most of our properties come fully furnished, so that shouldn''t be a problem. Do you have any pets?
STUDENT: No, no pets. I''m a student, so I don''t have time for that.
OFFICER: And what do you do?
STUDENT: I''m studying engineering at the university.
OFFICER: Great. And your email address?
STUDENT: It''s james.mitchell@email.com
OFFICER: Perfect. I''ll send you some options later today.',
            'Listen carefully and answer questions 1-10. Write NO MORE THAN THREE WORDS AND/OR A NUMBER for each answer.',
            10,
            1
        ) RETURNING id INTO v_section_id;
    END IF;
    
    -- Update/Insert detailed questions
    -- Delete existing questions for this exercise
    DELETE FROM questions WHERE exercise_id = v_exercise_id;
    
    -- Question 1: Multiple Choice
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        1,
        'What type of accommodation is the student looking for?',
        'multiple_choice',
        1.0,
        'easy',
        'The student says "I''d prefer a shared apartment if possible", so the answer is B.',
        'Listen for the exact words the speaker uses. Don''t choose an answer just because it sounds similar.',
        1
    );
    
    -- Question 2: Fill in blank - Number
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        2,
        'How much does the student want to pay per week? Write Â£_____ per week.',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "I''m hoping to spend around Â£120 per week, maximum Â£150", so the answer is 120.',
        'Pay attention to numbers. Sometimes speakers mention more than one number, so listen for the specific amount requested.',
        2
    );
    
    -- Question 3: Multiple Choice
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        3,
        'Which area does the student prefer?',
        'multiple_choice',
        1.0,
        'easy',
        'The student says "I''d like to be close to the university, maybe within walking distance", so the answer is B.',
        'Listen for location preferences and distances mentioned.',
        3
    );
    
    -- Question 4: Fill in blank - Name
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        4,
        'What is the student''s surname?',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "My name is James Mitchell. That''s M-I-T-C-H-E-L-L", so the surname is Mitchell.',
        'Names are often spelled out letter by letter. Write down the letters as you hear them.',
        4
    );
    
    -- Question 5: Fill in blank - Phone number
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        5,
        'What is the student''s phone number?',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "It''s 07782 459301", so the answer is 07782 459301.',
        'Phone numbers are usually said digit by digit or in groups. Write them exactly as you hear them.',
        5
    );
    
    -- Question 6: Fill in blank - Date
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        6,
        'When does the student want to move in?',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "I''m hoping to move in on the 15th of September", so the answer is 15th September or 15 September.',
        'Dates can be written in different formats. Both "15th September" and "15 September" are acceptable.',
        6
    );
    
    -- Question 7: Multiple Choice - Furniture
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        7,
        'What furniture does the student need?',
        'multiple_choice',
        1.0,
        'easy',
        'The student says "I''d need a bed and a desk at least. A wardrobe would be nice too", so the answer includes all three items.',
        'Listen for lists of items. The question might ask for all items mentioned.',
        7
    );
    
    -- Question 8: Multiple Choice - Pets
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        8,
        'Does the student have any pets?',
        'multiple_choice',
        1.0,
        'easy',
        'The student says "No, no pets", so the answer is B.',
        'Simple yes/no questions are common in Part 1. Listen for the direct answer.',
        8
    );
    
    -- Question 9: Fill in blank - Occupation
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        9,
        'What is the student''s occupation?',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "I''m studying engineering at the university", so the answer is student or engineering student.',
        'Occupation can be "student" or more specific like "engineering student".',
        9
    );
    
    -- Question 10: Fill in blank - Email
    INSERT INTO questions (
        id, exercise_id, section_id, question_number, question_text, question_type,
        points, difficulty, explanation, tips, display_order
    ) VALUES (
        uuid_generate_v4(),
        v_exercise_id,
        v_section_id,
        10,
        'What is the student''s email address?',
        'fill_in_blank',
        1.0,
        'easy',
        'The student says "It''s james.mitchell@email.com", so the answer is james.mitchell@email.com.',
        'Email addresses are usually spelled out. Write them exactly as you hear them, including dots and @ symbol.',
        10
    );
END $$;

-- ============================================
-- DETAILED OPTIONS FOR MULTIPLE CHOICE QUESTIONS
-- ============================================

-- Options for Question 1 (Accommodation type)
INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'A',
    'Student dormitory',
    false,
    1
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 1;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'B',
    'Shared apartment',
    true,
    2
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 1;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'C',
    'Private house',
    false,
    3
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 1;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'D',
    'Homestay',
    false,
    4
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 1;

-- Options for Question 3 (Area preference)
INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'A',
    'City center',
    false,
    1
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 3;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'B',
    'Close to university',
    true,
    2
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 3;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'C',
    'Near shopping center',
    false,
    3
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 3;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'D',
    'Suburban area',
    false,
    4
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 3;

-- Options for Question 7 (Furniture)
INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'A',
    'Bed and desk only',
    false,
    1
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 7;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'B',
    'Bed, desk, and wardrobe',
    true,
    2
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 7;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'C',
    'All furniture included',
    false,
    3
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 7;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'D',
    'No furniture needed',
    false,
    4
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 7;

-- Options for Question 8 (Pets)
INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'A',
    'Yes, a dog',
    false,
    1
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 8;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'B',
    'No pets',
    true,
    2
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 8;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'C',
    'Yes, a cat',
    false,
    3
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 8;

INSERT INTO question_options (id, question_id, option_label, option_text, is_correct, display_order)
SELECT 
    uuid_generate_v4(),
    q.id,
    'D',
    'Planning to get one',
    false,
    4
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 8;

-- ============================================
-- DETAILED ANSWERS FOR FILL-IN-BLANK QUESTIONS
-- ============================================

-- Answer for Question 2 (Price)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    '120',
    ARRAY['Â£120', '120 pounds', 'one hundred and twenty'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 2;

-- Answer for Question 4 (Surname)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    'Mitchell',
    ARRAY['MITCHELL', 'mitchell'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 4;

-- Answer for Question 5 (Phone)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    '07782 459301',
    ARRAY['07782459301', '07782-459301'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 5;

-- Answer for Question 6 (Date)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    '15th September',
    ARRAY['15 September', '15/09', 'September 15', 'September 15th'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 6;

-- Answer for Question 9 (Occupation)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    'student',
    ARRAY['Student', 'engineering student', 'Engineering student'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 9;

-- Answer for Question 10 (Email)
INSERT INTO question_answers (id, question_id, answer_text, answer_variations, is_primary_answer)
SELECT 
    uuid_generate_v4(),
    q.id,
    'james.mitchell@email.com',
    ARRAY['james.mitchell@email.com', 'james.mitchell@email.com'],
    true
FROM questions q
WHERE q.exercise_id = 'e1000001-0000-0000-0000-000000000001' AND q.question_number = 10;

-- Update exercise total_questions to match actual count
DO $$
DECLARE
    v_exercise_id UUID := 'e1000001-0000-0000-0000-000000000001'::uuid;
BEGIN
    UPDATE exercises 
    SET total_questions = (
        SELECT COUNT(*) FROM questions WHERE exercise_id = v_exercise_id
    )
    WHERE id = v_exercise_id;

    -- Update section total_questions
    UPDATE exercise_sections
    SET total_questions = (
        SELECT COUNT(*) FROM questions 
        WHERE section_id = exercise_sections.id
    )
    WHERE exercise_id = v_exercise_id;
END $$;

SELECT 'âœ… Enhanced realistic questions added for Exercise 1' as status;

