-- ============================================================================
-- PRACTICE ACTIVITIES VALIDATION
-- ============================================================================
-- Verify practice_activities data is logical and synchronized with other tables

\c user_db

SELECT '=============================================' as separator
UNION ALL SELECT '✅ PRACTICE ACTIVITIES VALIDATION'
UNION ALL SELECT '=============================================';

-- Check 1: All have valid timeline
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE completed_at < started_at) = 0 
        THEN '✅ PASS: All practice activities have valid timeline (completed_at >= started_at)'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE completed_at < started_at)::text || ' activities have completed_at < started_at'
    END as validation
FROM practice_activities;

-- Check 2: All have valid band scores (0-9)
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE band_score < 0 OR band_score > 9) = 0 
        THEN '✅ PASS: All band scores are in valid range (0-9)'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE band_score < 0 OR band_score > 9)::text || ' activities have invalid band_score'
    END as validation
FROM practice_activities
WHERE band_score IS NOT NULL;

-- Check 3: All linked exercises exist
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM practice_activities pa
            LEFT JOIN dblink(
                'dbname=exercise_db user=ielts_admin',
                'SELECT id FROM exercises'
            ) AS e(id uuid) ON e.id = pa.exercise_id
            WHERE pa.exercise_id IS NOT NULL AND e.id IS NULL
        )
        THEN '✅ PASS: All linked exercises exist in exercise_db'
        ELSE '❌ FAIL: Some practice activities link to non-existent exercises'
    END as validation;

-- Check 4: All users exist
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM practice_activities pa
            LEFT JOIN user_profiles up ON up.user_id = pa.user_id
            WHERE up.user_id IS NULL
        )
        THEN '✅ PASS: All practice activity users exist in user_profiles'
        ELSE '❌ FAIL: Some practice activities have non-existent users'
    END as validation;

-- Check 5: Activity type matches valid enum
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE activity_type NOT IN ('drill', 'part_test', 'section_practice', 'question_set')) = 0 
        THEN '✅ PASS: All activity_type values are valid'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE activity_type NOT IN ('drill', 'part_test', 'section_practice', 'question_set'))::text || ' activities have invalid activity_type'
    END as validation
FROM practice_activities;

-- Check 6: Skill matches valid enum
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE skill NOT IN ('listening', 'reading', 'writing', 'speaking')) = 0 
        THEN '✅ PASS: All skill values are valid'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE skill NOT IN ('listening', 'reading', 'writing', 'speaking'))::text || ' activities have invalid skill'
    END as validation
FROM practice_activities;

-- Check 7: Difficulty level matches valid enum
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE difficulty_level NOT IN ('beginner', 'intermediate', 'advanced', 'expert')) = 0 
        THEN '✅ PASS: All difficulty_level values are valid'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE difficulty_level NOT IN ('beginner', 'intermediate', 'advanced', 'expert'))::text || ' activities have invalid difficulty_level'
    END as validation
FROM practice_activities
WHERE difficulty_level IS NOT NULL;

-- Check 8: Accuracy percentage is consistent with correct/total
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (
            WHERE total_questions > 0 
            AND ABS(accuracy_percentage - (correct_answers::numeric / total_questions * 100)) > 1.0
        ) = 0 
        THEN '✅ PASS: All accuracy_percentage values match correct_answers/total_questions'
        ELSE '⚠️  WARNING: ' || COUNT(*) FILTER (
            WHERE total_questions > 0 
            AND ABS(accuracy_percentage - (correct_answers::numeric / total_questions * 100)) > 1.0
        )::text || ' activities have mismatched accuracy_percentage (tolerance 1%)'
    END as validation
FROM practice_activities;

-- Check 9: Time spent is reasonable (not 0 for completed activities)
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (WHERE completion_status = 'completed' AND time_spent_seconds = 0) = 0 
        THEN '✅ PASS: All completed activities have time_spent > 0'
        ELSE '❌ FAIL: ' || COUNT(*) FILTER (WHERE completion_status = 'completed' AND time_spent_seconds = 0)::text || ' completed activities have time_spent_seconds = 0'
    END as validation
FROM practice_activities;

-- Check 10: AI evaluated activities have feedback (for writing/speaking)
SELECT 
    CASE 
        WHEN COUNT(*) FILTER (
            WHERE skill IN ('writing', 'speaking') 
            AND ai_evaluated = true 
            AND (ai_feedback_summary IS NULL OR ai_feedback_summary = '')
        ) = 0 
        THEN '✅ PASS: All AI-evaluated writing/speaking activities have feedback'
        ELSE '⚠️  WARNING: ' || COUNT(*) FILTER (
            WHERE skill IN ('writing', 'speaking') 
            AND ai_evaluated = true 
            AND (ai_feedback_summary IS NULL OR ai_feedback_summary = '')
        )::text || ' AI-evaluated activities missing feedback (OK for drills)'
    END as validation
FROM practice_activities;

-- Summary
SELECT '=============================================' as info
UNION ALL SELECT 'PRACTICE ACTIVITIES SUMMARY'
UNION ALL SELECT '============================================='
UNION ALL SELECT 'Total Activities: ' || (SELECT COUNT(*)::text FROM practice_activities)
UNION ALL SELECT 'By Activity Type:'
UNION ALL SELECT '  - part_test: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE activity_type = 'part_test')
UNION ALL SELECT '  - question_set: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE activity_type = 'question_set')
UNION ALL SELECT '  - section_practice: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE activity_type = 'section_practice')
UNION ALL SELECT '  - drill: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE activity_type = 'drill')
UNION ALL SELECT 'By Skill:'
UNION ALL SELECT '  - listening: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE skill = 'listening')
UNION ALL SELECT '  - reading: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE skill = 'reading')
UNION ALL SELECT '  - writing: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE skill = 'writing')
UNION ALL SELECT '  - speaking: ' || (SELECT COUNT(*)::text FROM practice_activities WHERE skill = 'speaking')
UNION ALL SELECT 'Users with Activities: ' || (SELECT COUNT(DISTINCT user_id)::text FROM practice_activities)
UNION ALL SELECT 'Average Band Score: ' || (SELECT ROUND(AVG(band_score), 2)::text FROM practice_activities)
UNION ALL SELECT 'Average Accuracy: ' || (SELECT ROUND(AVG(accuracy_percentage), 2)::text || '%' FROM practice_activities)
UNION ALL SELECT 'Date Range: ' || (SELECT MIN(started_at)::date::text || ' to ' || MAX(completed_at)::date::text FROM practice_activities)
UNION ALL SELECT '=============================================';
