-- ============================================
-- PHASE 8: ADDITIONAL MISSING TABLES & RELATIONSHIPS
-- ============================================
-- Purpose: Seed data for tables that were missing
-- Database: exercise_db
-- 
-- Creates:
-- - exercise_tag_mapping
-- - exercise_analytics
-- ============================================

-- ============================================
-- 1. EXERCISE_TAG_MAPPING
-- ============================================
-- Link exercises to tags

INSERT INTO exercise_tag_mapping (exercise_id, tag_id)
SELECT DISTINCT
    e.id,
    et.id
FROM exercises e
CROSS JOIN exercise_tags et
WHERE random() > 0.7 -- 30% chance for each tag
  AND (
    -- Match tags based on exercise properties
    (et.slug = 'multiple-choice' AND e.skill_type = 'listening') OR
    (et.slug = 'cambridge-ielts' AND e.exercise_type = 'full_test') OR
    (et.slug = 'practice-test' AND e.exercise_type = 'practice') OR
    (et.slug = 'mock-test' AND e.exercise_type = 'mock_test') OR
    (et.slug = 'beginner-friendly' AND e.difficulty = 'easy') OR
    (et.slug = 'advanced-level' AND e.difficulty = 'hard') OR
    (et.slug = 'academic' AND e.skill_type = 'reading') OR
    (et.slug = 'true-false-not-given' AND e.skill_type = 'reading') OR
    random() > 0.9 -- 10% random tags
  )
LIMIT 200;

-- ============================================
-- 2. EXERCISE_ANALYTICS
-- ============================================
-- Daily analytics for exercises based on actual attempts
-- Note: Schema is simplified - only tracks: total_attempts, completed_attempts, 
--       average_score, average_completion_time, pass_rate

INSERT INTO exercise_analytics (
    exercise_id, date, total_attempts, completed_attempts,
    average_score, average_completion_time, pass_rate
)
SELECT 
    e.id,
    CURRENT_DATE,
    COALESCE(attempt_stats.total_attempts, 0),
    COALESCE(attempt_stats.completed_attempts, 0),
    COALESCE(score_stats.avg_score, 0),
    COALESCE(time_stats.avg_time, 0),
    CASE 
        WHEN COALESCE(attempt_stats.completed_attempts, 0) = 0 THEN 0
        ELSE COALESCE(score_stats.pass_count::DECIMAL / NULLIF(attempt_stats.completed_attempts, 0) * 100, 0)
    END
FROM exercises e
LEFT JOIN (
    SELECT 
        exercise_id,
        COUNT(*) as total_attempts,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_attempts
    FROM user_exercise_attempts
    GROUP BY exercise_id
) attempt_stats ON e.id = attempt_stats.exercise_id
LEFT JOIN (
    SELECT 
        exercise_id,
        AVG(score) as avg_score,
        COUNT(*) FILTER (WHERE score >= 60) as pass_count -- Assuming 60% is passing
    FROM user_exercise_attempts
    WHERE status = 'completed' AND score IS NOT NULL
    GROUP BY exercise_id
) score_stats ON e.id = score_stats.exercise_id
LEFT JOIN (
    SELECT 
        exercise_id,
        AVG(time_spent_seconds) as avg_time
    FROM user_exercise_attempts
    WHERE status = 'completed' AND time_spent_seconds IS NOT NULL
    GROUP BY exercise_id
) time_stats ON e.id = time_stats.exercise_id
ON CONFLICT (exercise_id, date) DO UPDATE SET
    total_attempts = EXCLUDED.total_attempts,
    completed_attempts = EXCLUDED.completed_attempts,
    average_score = EXCLUDED.average_score,
    average_completion_time = EXCLUDED.average_completion_time,
    pass_rate = EXCLUDED.pass_rate,
    updated_at = CURRENT_TIMESTAMP;

-- Summary
SELECT 
    '✅ Exercise DB Phase 8 Complete' as status,
    (SELECT COUNT(*) FROM exercise_tag_mapping) as exercise_tag_mappings_count,
    (SELECT COUNT(*) FROM exercise_analytics) as exercise_analytics_count;

