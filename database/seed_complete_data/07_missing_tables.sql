-- ============================================
-- PHASE 7: MISSING TABLES & CROSS-DB LINKS
-- ============================================
-- Purpose: Seed data for tables that were missing or need cross-db links
-- 
-- Creates:
-- - question_bank (reusable questions)
-- - evaluation_feedback_ratings (user feedback on AI evaluations)
-- - Additional cross-db validations
-- ============================================

-- ============================================
-- 1. QUESTION_BANK (exercise_db)
-- ============================================
-- Reusable question bank for instructors to create exercises

INSERT INTO question_bank (
    id, title, skill_type, question_type, difficulty, topic,
    question_text, context_text, audio_url, image_url,
    answer_data, tags, times_used, created_by, is_verified, is_published
)
SELECT 
    uuid_generate_v4(),
    CASE skill_type
        WHEN 'listening' THEN 'Listening Question: ' || CASE (row_number() OVER () % 5)
            WHEN 0 THEN 'Social Conversation'
            WHEN 1 THEN 'Academic Discussion'
            WHEN 2 THEN 'Monologue'
            WHEN 3 THEN 'Lecture'
            ELSE 'Interview'
        END
        ELSE 'Reading Question: ' || CASE (row_number() OVER () % 5)
            WHEN 0 THEN 'Multiple Choice'
            WHEN 1 THEN 'True/False/Not Given'
            WHEN 2 THEN 'Matching'
            WHEN 3 THEN 'Fill in the Blank'
            ELSE 'Sentence Completion'
        END
    END,
    skill_type,
    question_type,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'easy' WHEN 1 THEN 'medium' ELSE 'hard' END,
    CASE (random() * 8)::INTEGER
        WHEN 0 THEN 'education'
        WHEN 1 THEN 'technology'
        WHEN 2 THEN 'environment'
        WHEN 3 THEN 'health'
        WHEN 4 THEN 'business'
        WHEN 5 THEN 'tourism'
        WHEN 6 THEN 'culture'
        ELSE 'society'
    END,
    CASE skill_type
        WHEN 'listening' THEN 'Listen to the audio and answer the question about ' || 
            CASE (row_number() OVER () % 5)
                WHEN 0 THEN 'accommodation arrangements'
                WHEN 1 THEN 'course registration'
                WHEN 2 THEN 'library facilities'
                WHEN 3 THEN 'student activities'
                ELSE 'campus services'
            END || '.'
        ELSE 'Read the passage and answer the question about ' ||
            CASE (row_number() OVER () % 5)
                WHEN 0 THEN 'the main idea'
                WHEN 1 THEN 'specific details'
                WHEN 2 THEN 'the author''s opinion'
                WHEN 3 THEN 'inference'
                ELSE 'vocabulary meaning'
            END || '.'
    END,
    CASE WHEN skill_type = 'reading' THEN 
        'The passage discusses various aspects of ' ||
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'modern education systems'
            WHEN 1 THEN 'technological advancements'
            WHEN 2 THEN 'environmental conservation'
            WHEN 3 THEN 'healthcare improvements'
            ELSE 'economic development'
        END || '. [Full passage content would be here...]'
    ELSE NULL END,
    CASE WHEN skill_type = 'listening' THEN
        CASE (row_number() OVER () % 6)
            WHEN 0 THEN 'https://www.youtube.com/watch?v=6QMu7-3DMi0'
            WHEN 1 THEN 'https://www.youtube.com/watch?v=ys-1LqlUNCk'
            WHEN 2 THEN 'https://www.youtube.com/watch?v=tml3fxV9w7g'
            WHEN 3 THEN 'https://www.youtube.com/watch?v=oV7qaHKPoK0'
            WHEN 4 THEN 'https://www.youtube.com/watch?v=9TH5JGYZB4o'
            ELSE 'https://www.youtube.com/watch?v=vVYONjT2b0Y'
        END
    ELSE NULL END,
    CASE WHEN random() > 0.7 THEN 
        'https://images.unsplash.com/photo-' || 
        CASE (row_number() OVER () % 10)
            WHEN 0 THEN '1456513080510-7bf3a84b82f8'
            WHEN 1 THEN '1456513080510-7bf3a84b82f8'
            WHEN 2 THEN '1497366216548-37526070297c'
            WHEN 3 THEN '1522202176988-66273c2fd55f'
            WHEN 4 THEN '1521737604893-d14cc237f11d'
            WHEN 5 THEN '1522071820081-009f0129c71c'
            WHEN 6 THEN '1506905925346-21bda4d32df4'
            WHEN 7 THEN '1500648767791-00dcc994a43e'
            WHEN 8 THEN '1534528741775-53994a69daeb'
            ELSE '1507003211169-0a1dd7228f2d'
        END || '?w=800&h=600&fit=crop'
    ELSE NULL END,
    jsonb_build_object(
        'correct_answer', CASE question_type
            WHEN 'multiple_choice' THEN jsonb_build_array('A')
            WHEN 'true_false_not_given' THEN jsonb_build_array('True')
            WHEN 'matching' THEN jsonb_build_array('A-1', 'B-2', 'C-3')
            WHEN 'fill_in_blank' THEN jsonb_build_array('answer')
            WHEN 'sentence_completion' THEN jsonb_build_array('completed answer')
            ELSE jsonb_build_array('answer')
        END,
        'explanation', 'This is the correct answer because...',
        'points', 1
    ),
    ARRAY[
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'academic'
            WHEN 1 THEN 'general'
            WHEN 2 THEN 'conversation'
            WHEN 3 THEN 'lecture'
            ELSE 'discussion'
        END,
        CASE (random() * 5)::INTEGER
            WHEN 0 THEN 'beginner'
            WHEN 1 THEN 'intermediate'
            WHEN 2 THEN 'advanced'
            WHEN 3 THEN 'band-5'
            ELSE 'band-7'
        END
    ],
    (random() * 20)::INTEGER,
    ('b' || LPAD((1 + (random() * 14)::INTEGER)::text, 7, '0') || '-0000-0000-0000-000000000' ||
    LPAD((1 + (random() * 14)::INTEGER)::text, 3, '0'))::uuid,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.2 THEN true ELSE false END
FROM (
    SELECT 'listening' as skill_type, 'multiple_choice' as question_type
    UNION ALL SELECT 'listening', 'fill_in_blank'
    UNION ALL SELECT 'listening', 'sentence_completion'
    UNION ALL SELECT 'reading', 'multiple_choice'
    UNION ALL SELECT 'reading', 'true_false_not_given'
    UNION ALL SELECT 'reading', 'matching'
    UNION ALL SELECT 'reading', 'fill_in_blank'
    UNION ALL SELECT 'reading', 'sentence_completion'
) types
CROSS JOIN generate_series(1, 15); -- 8 types * 15 = 120 questions

-- Summary
SELECT 
    'âœ… Phase 7 Complete: Question Bank Seeded' as status,
    (SELECT COUNT(*) FROM question_bank) as total_question_bank_items;

