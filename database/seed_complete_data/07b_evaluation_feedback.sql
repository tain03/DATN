-- ============================================
-- PHASE 7B: EVALUATION_FEEDBACK_RATINGS (ai_db)
-- ============================================
-- ⚠️  DEPRECATED: Evaluation feedback is no longer stored separately
-- 
-- AI evaluations have been migrated to exercise_service:
-- - Submissions are in exercise_submissions table (exercise_db)
-- - Evaluations are stored as JSONB in exercise_submissions.ai_evaluation_result
-- - Feedback can be added to exercise_submissions.feedback field
--
-- This seed file is commented out to avoid errors.
-- Feedback functionality should be implemented through exercise-service API.

/*
INSERT INTO evaluation_feedback_ratings (
    id, user_id, evaluation_type, evaluation_id,
    is_helpful, accuracy_rating, feedback_text
)
SELECT 
    uuid_generate_v4(),
    ws.user_id,
    'writing',
    we.id,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN (random() * 4 + 1)::INTEGER ELSE NULL END,
    CASE WHEN random() > 0.4 THEN 
        CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'Very helpful feedback, especially the grammar suggestions.'
            WHEN 1 THEN 'The evaluation was accurate and detailed.'
            ELSE 'Good feedback overall, but could be more specific in some areas.'
        END
    ELSE NULL END
FROM writing_evaluations we
INNER JOIN writing_submissions ws ON ws.id = we.submission_id
WHERE random() > 0.7 -- 30% of evaluations get feedback
LIMIT 50;

INSERT INTO evaluation_feedback_ratings (
    id, user_id, evaluation_type, evaluation_id,
    is_helpful, accuracy_rating, feedback_text
)
SELECT 
    uuid_generate_v4(),
    ss.user_id,
    'speaking',
    se.id,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN (random() * 4 + 1)::INTEGER ELSE NULL END,
    CASE WHEN random() > 0.4 THEN 
        CASE (random() * 3)::INTEGER
            WHEN 0 THEN 'Pronunciation feedback was very useful.'
            WHEN 1 THEN 'The evaluation helped me understand my weaknesses.'
            ELSE 'Good overall, but the fluency score seems too low.'
        END
    ELSE NULL END
FROM speaking_evaluations se
INNER JOIN speaking_submissions ss ON ss.id = se.submission_id
WHERE random() > 0.7 -- 30% of evaluations get feedback
LIMIT 50;
*/

-- Summary
SELECT 
    '✅ Phase 7B Complete: Evaluation Feedback Seeded' as status,
    0 as writing_feedback_count,  -- Migrated to exercise_submissions.feedback
    0 as speaking_feedback_count; -- Migrated to exercise_submissions.feedback

