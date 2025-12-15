-- ============================================
-- WRITING & SPEAKING EVALUATION CRITERIA
-- ============================================
-- Purpose: Add questions for Writing/Speaking exercises to support AI evaluation
-- Database: exercise_db
-- 
-- FIXES:
-- 1. Add evaluation criteria as questions for Writing exercises
-- 2. Add evaluation criteria as questions for Speaking exercises
-- 3. Add model answers for reference
-- 4. Define scoring rubrics
-- ============================================

-- ============================================
-- WRITING TASK 1 - EVALUATION CRITERIA
-- ============================================

-- Get all Writing Task 1 exercises
DO $$
DECLARE
    writing_exercise RECORD;
    q_task_achievement UUID;
    q_coherence UUID;
    q_lexical UUID;
    q_grammar UUID;
BEGIN
    FOR writing_exercise IN 
        SELECT id FROM exercises 
        WHERE skill_type = 'writing' AND writing_task_type = 'task1'
    LOOP
        -- Task Achievement (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text, 
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 1,
            'Task Achievement: Does the response fully address all parts of the task? Are the key features clearly highlighted? Is the overview present and accurate?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 1 - Task Achievement Criterion: Assesses how well you address the task requirements and present key features.',
            1
        ) RETURNING id INTO q_task_achievement;

        -- Add scoring guide as question_answers
        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_task_achievement, 'Band 9: Fully satisfies all requirements. Clear, fully developed response with excellent overview.', true),
        (q_task_achievement, 'Band 7: Covers requirements well. Clear overview. Key features selected and highlighted.', false),
        (q_task_achievement, 'Band 5: Addresses task only partially. Overview may be missing. Some key features not highlighted.', false);

        -- Coherence & Cohesion (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 2,
            'Coherence and Cohesion: Is the information organized logically? Are cohesive devices used effectively? Is there clear progression?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 1 - Coherence and Cohesion: Assesses logical organization and use of cohesive devices.',
            2
        ) RETURNING id INTO q_coherence;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_coherence, 'Band 9: Cohesion is used effectively. Paragraphs are well-organized. Smooth progression throughout.', true),
        (q_coherence, 'Band 7: Information organized logically. Clear progression. Good range of cohesive devices.', false),
        (q_coherence, 'Band 5: Organization is evident but not fully logical. Limited cohesive devices. Some repetition.', false);

        -- Lexical Resource (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 3,
            'Lexical Resource: Is there a wide range of vocabulary? Are words used accurately and appropriately? Are there spelling errors?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 1 - Lexical Resource: Assesses vocabulary range, accuracy, and appropriateness.',
            3
        ) RETURNING id INTO q_lexical;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_lexical, 'Band 9: Wide range of vocabulary with full flexibility. Rare minor errors. Sophisticated word choice.', true),
        (q_lexical, 'Band 7: Sufficient range with some flexibility. Good awareness of style and collocation. Few errors.', false),
        (q_lexical, 'Band 5: Limited range. Basic vocabulary adequate for task. Noticeable errors that cause difficulty.', false);

        -- Grammatical Range and Accuracy (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 4,
            'Grammatical Range and Accuracy: Is there a variety of sentence structures? Are sentences accurate? Are there grammar errors?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 1 - Grammar: Assesses range of structures and accuracy.',
            4
        ) RETURNING id INTO q_grammar;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_grammar, 'Band 9: Full range of structures with flexibility. Rare minor errors. Excellent control.', true),
        (q_grammar, 'Band 7: Variety of complex structures. Good control. Frequent error-free sentences.', false),
        (q_grammar, 'Band 5: Limited range. Mix of simple and complex. Frequent errors. Some difficulty for reader.', false);

    END LOOP;
END $$;

-- ============================================
-- WRITING TASK 2 - EVALUATION CRITERIA
-- ============================================

DO $$
DECLARE
    writing_exercise RECORD;
    q_task_response UUID;
    q_coherence UUID;
    q_lexical UUID;
    q_grammar UUID;
BEGIN
    FOR writing_exercise IN 
        SELECT id FROM exercises 
        WHERE skill_type = 'writing' AND writing_task_type = 'task2'
    LOOP
        -- Task Response (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 1,
            'Task Response: Does the response fully address all parts of the question? Is there a clear position? Are ideas well-developed?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 2 - Task Response: Assesses how well you address the question and develop ideas.',
            1
        ) RETURNING id INTO q_task_response;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_task_response, 'Band 9: Fully addresses all parts. Clear position maintained. Fully extended ideas.', true),
        (q_task_response, 'Band 7: Addresses all parts. Clear position. Ideas developed with some extension.', false),
        (q_task_response, 'Band 5: Addresses task only partially. Position unclear. Limited idea development.', false);

        -- Coherence & Cohesion (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 2,
            'Coherence and Cohesion: Is the essay well-organized? Are paragraphs used effectively? Are linking devices appropriate?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 2 - Coherence: Assesses organization and use of cohesive devices.',
            2
        ) RETURNING id INTO q_coherence;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_coherence, 'Band 9: Skillful paragraphing. Excellent cohesive devices. Seamless progression.', true),
        (q_coherence, 'Band 7: Logical organization. Clear progression. Good range of cohesive devices.', false),
        (q_coherence, 'Band 5: Inadequate paragraphing. Repetitive cohesive devices. Unclear progression.', false);

        -- Lexical Resource (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 3,
            'Lexical Resource: Is vocabulary varied and sophisticated? Is it used naturally and accurately?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 2 - Vocabulary: Assesses range and accuracy of vocabulary.',
            3
        ) RETURNING id INTO q_lexical;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_lexical, 'Band 9: Wide range with natural sophistication. Rare errors. Excellent word choice.', true),
        (q_lexical, 'Band 7: Sufficient range with flexibility. Less common vocabulary. Good collocation.', false),
        (q_lexical, 'Band 5: Limited range. Basic vocabulary. Noticeable errors in word formation/choice.', false);

        -- Grammatical Range and Accuracy (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), writing_exercise.id, NULL, 4,
            'Grammatical Range and Accuracy: Are complex structures used effectively? How accurate is the grammar?',
            'essay_criterion', 25.00, 'medium',
            'IELTS Writing Task 2 - Grammar: Assesses grammatical range and accuracy.',
            4
        ) RETURNING id INTO q_grammar;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_grammar, 'Band 9: Full flexibility with structures. Rare errors. Excellent control.', true),
        (q_grammar, 'Band 7: Variety of complex structures. Frequent error-free sentences. Good control.', false),
        (q_grammar, 'Band 5: Limited range. Attempts complex but errors persist. Some difficult for reader.', false);

    END LOOP;
END $$;

-- ============================================
-- SPEAKING PART 1 - EVALUATION CRITERIA
-- ============================================

DO $$
DECLARE
    speaking_exercise RECORD;
    q_fluency UUID;
    q_lexical UUID;
    q_grammar UUID;
    q_pronunciation UUID;
BEGIN
    FOR speaking_exercise IN 
        SELECT id FROM exercises 
        WHERE skill_type = 'speaking' AND speaking_part_number = 1
    LOOP
        -- Fluency and Coherence (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 1,
            'Fluency and Coherence: Does the candidate speak fluently without hesitation? Is speech coherent and easy to follow?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking - Fluency: Assesses fluency, coherence, and how naturally you speak.',
            1
        ) RETURNING id INTO q_fluency;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_fluency, 'Band 9: Speaks fluently with minimal hesitation. Coherent and cohesive. Natural development.', true),
        (q_fluency, 'Band 7: Speaks at length. Few hesitations. Good coherence. Clear markers for development.', false),
        (q_fluency, 'Band 5: Speaks with noticeable effort. Frequent hesitations. Simple discourse markers.', false);

        -- Lexical Resource (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 2,
            'Lexical Resource: Is vocabulary varied and appropriate? Can the candidate paraphrase effectively?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking - Vocabulary: Assesses range and flexibility of vocabulary.',
            2
        ) RETURNING id INTO q_lexical;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_lexical, 'Band 9: Uses vocabulary with full flexibility. Precise meanings. Natural idiomatic language.', true),
        (q_lexical, 'Band 7: Flexible vocabulary. Good range. Some ability to paraphrase. Few errors.', false),
        (q_lexical, 'Band 5: Limited range. Repetitive vocabulary. Attempts paraphrasing with mixed success.', false);

        -- Grammatical Range and Accuracy (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 3,
            'Grammatical Range and Accuracy: Does the candidate use complex structures? How accurate is the grammar?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking - Grammar: Assesses grammatical structures and accuracy.',
            3
        ) RETURNING id INTO q_grammar;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_grammar, 'Band 9: Full range with flexibility. Rare errors. Excellent control.', true),
        (q_grammar, 'Band 7: Range of complex structures. Frequent error-free sentences. Good control.', false),
        (q_grammar, 'Band 5: Basic structures. Limited complex sentences. Errors are frequent.', false);

        -- Pronunciation (25%)
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 4,
            'Pronunciation: Is pronunciation clear? Are intonation and stress used effectively?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking - Pronunciation: Assesses clarity, intonation, and stress.',
            4
        ) RETURNING id INTO q_pronunciation;

        INSERT INTO question_answers (question_id, answer_text, is_primary_answer) VALUES
        (q_pronunciation, 'Band 9: Uses features of pronunciation expertly. Easy to understand throughout.', true),
        (q_pronunciation, 'Band 7: Shows features of pronunciation. Generally easy to understand. Some mispronunciation.', false),
        (q_pronunciation, 'Band 5: Pronunciation features limited. Mispronunciation causes some difficulty.', false);

    END LOOP;
END $$;

-- ============================================
-- SPEAKING PART 2 - EVALUATION CRITERIA
-- ============================================

DO $$
DECLARE
    speaking_exercise RECORD;
BEGIN
    FOR speaking_exercise IN 
        SELECT id FROM exercises 
        WHERE skill_type = 'speaking' AND speaking_part_number = 2
    LOOP
        -- Same 4 criteria as Part 1 but adapted for long turn
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 1,
            'Fluency and Coherence: Can the candidate speak at length coherently? Is there logical development of ideas?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking Part 2 - Fluency: Assesses ability to speak at length on a given topic.',
            1
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 2,
            'Lexical Resource: Is vocabulary appropriate for the topic? Is there flexibility in describing and discussing?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking Part 2 - Vocabulary: Assesses topic-specific vocabulary and paraphrasing.',
            2
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 3,
            'Grammatical Range and Accuracy: Does the candidate use varied structures when elaborating?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking Part 2 - Grammar: Assesses grammar during extended speech.',
            3
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 4,
            'Pronunciation: Is sustained speech clear and easy to understand?',
            'speaking_criterion', 25.00, 'medium',
            'IELTS Speaking Part 2 - Pronunciation: Assesses clarity during long turn.',
            4
        );
    END LOOP;
END $$;

-- ============================================
-- SPEAKING PART 3 - EVALUATION CRITERIA
-- ============================================

DO $$
DECLARE
    speaking_exercise RECORD;
BEGIN
    FOR speaking_exercise IN 
        SELECT id FROM exercises 
        WHERE skill_type = 'speaking' AND speaking_part_number = 3
    LOOP
        -- Same 4 criteria but adapted for abstract discussion
        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 1,
            'Fluency and Coherence: Can the candidate express and justify opinions? Is reasoning clear?',
            'speaking_criterion', 25.00, 'hard',
            'IELTS Speaking Part 3 - Fluency: Assesses ability to discuss abstract topics.',
            1
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 2,
            'Lexical Resource: Can abstract ideas be expressed precisely? Is language sophisticated?',
            'speaking_criterion', 25.00, 'hard',
            'IELTS Speaking Part 3 - Vocabulary: Assesses vocabulary for abstract discussion.',
            2
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 3,
            'Grammatical Range and Accuracy: Are complex ideas expressed with varied grammar?',
            'speaking_criterion', 25.00, 'hard',
            'IELTS Speaking Part 3 - Grammar: Assesses grammar for complex ideas.',
            3
        );

        INSERT INTO questions (
            id, exercise_id, section_id, question_number, question_text,
            question_type, points, difficulty, explanation, display_order
        ) VALUES (
            gen_random_uuid(), speaking_exercise.id, NULL, 4,
            'Pronunciation: Is abstract discussion clearly articulated?',
            'speaking_criterion', 25.00, 'hard',
            'IELTS Speaking Part 3 - Pronunciation: Assesses clarity in abstract discussion.',
            4
        );
    END LOOP;
END $$;

-- ============================================
-- UPDATE EXERCISE TOTALS
-- ============================================

-- Update total_questions for Writing exercises
UPDATE exercises
SET total_questions = 4
WHERE skill_type = 'writing';

-- Update total_questions for Speaking exercises
UPDATE exercises
SET total_questions = 4
WHERE skill_type = 'speaking';

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify Writing exercises have questions
SELECT 
    'Writing Exercises' as category,
    COUNT(DISTINCT e.id) as total_exercises,
    COUNT(DISTINCT q.id) as total_questions,
    COUNT(DISTINCT qa.id) as total_answers
FROM exercises e
LEFT JOIN questions q ON e.id = q.exercise_id
LEFT JOIN question_answers qa ON q.id = qa.question_id
WHERE e.skill_type = 'writing'
GROUP BY category;

-- Verify Speaking exercises have questions
SELECT 
    'Speaking Exercises' as category,
    COUNT(DISTINCT e.id) as total_exercises,
    COUNT(DISTINCT q.id) as total_questions
FROM exercises e
LEFT JOIN questions q ON e.id = q.exercise_id
WHERE e.skill_type = 'speaking'
GROUP BY category;

-- ============================================
-- SUMMARY
-- ============================================
SELECT 
    'âœ… Phase Complete: Writing & Speaking Evaluation Criteria Added' as status,
    (SELECT COUNT(*) FROM exercises WHERE skill_type IN ('writing', 'speaking')) as total_exercises,
    (SELECT COUNT(*) FROM questions WHERE question_type IN ('essay_criterion', 'speaking_criterion')) as total_criteria,
    (SELECT COUNT(*) FROM question_answers WHERE question_id IN 
        (SELECT id FROM questions WHERE question_type IN ('essay_criterion', 'speaking_criterion'))) as total_rubric_items;

