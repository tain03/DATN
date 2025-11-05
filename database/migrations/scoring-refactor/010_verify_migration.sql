-- Verification Script: Verify data migration from ai_db to exercise_db
-- Purpose: Comprehensive verification of writing and speaking submissions migration
-- Database: exercise_db
-- Phase: 6 - Data Migration Verification

-- ==============================================
-- SECTION 1: Record Count Verification
-- ==============================================

-- Writing submissions count
SELECT 
    'Writing Submissions' as type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN band_score IS NOT NULL THEN 1 END) as evaluated_count,
    COUNT(CASE WHEN band_score IS NULL THEN 1 END) as pending_count
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL;

-- Speaking submissions count
SELECT 
    'Speaking Submissions' as type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN band_score IS NOT NULL THEN 1 END) as evaluated_count,
    COUNT(CASE WHEN band_score IS NULL THEN 1 END) as pending_count
FROM user_exercise_attempts
WHERE audio_url IS NOT NULL;

-- Total migrated submissions
SELECT 
    'Total Migrated' as type,
    COUNT(*) as total_count
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL OR audio_url IS NOT NULL;

-- ==============================================
-- SECTION 2: Data Integrity Checks
-- ==============================================

-- Check for NULL user_ids (should be 0)
SELECT 
    'NULL user_id check' as check_name,
    COUNT(*) as violation_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM user_exercise_attempts
WHERE (essay_text IS NOT NULL OR audio_url IS NOT NULL)
  AND user_id IS NULL;

-- Check for invalid band scores (should be 0-9)
SELECT 
    'Invalid band_score check' as check_name,
    COUNT(*) as violation_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM user_exercise_attempts
WHERE (essay_text IS NOT NULL OR audio_url IS NOT NULL)
  AND band_score IS NOT NULL
  AND (band_score < 0 OR band_score > 9);

-- Check writing submissions have required fields
SELECT 
    'Writing required fields' as check_name,
    COUNT(*) as violation_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL
  AND (word_count IS NULL OR task_type IS NULL);

-- Check speaking submissions have required fields
SELECT 
    'Speaking required fields' as check_name,
    COUNT(*) as violation_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM user_exercise_attempts
WHERE audio_url IS NOT NULL
  AND (audio_duration_seconds IS NULL OR speaking_part_number IS NULL);

-- Check evaluation_status consistency
SELECT 
    'Evaluation status consistency' as check_name,
    COUNT(*) as violation_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM user_exercise_attempts
WHERE (essay_text IS NOT NULL OR audio_url IS NOT NULL)
  AND (
    (band_score IS NOT NULL AND evaluation_status NOT IN ('completed', 'failed'))
    OR
    (band_score IS NULL AND evaluation_status = 'completed')
  );

-- ==============================================
-- SECTION 3: Detailed Score Verification
-- ==============================================

-- Writing detailed scores check (should have 4 criteria)
SELECT 
    'Writing detailed_scores structure' as check_name,
    COUNT(*) as total_count,
    COUNT(CASE 
        WHEN detailed_scores ? 'task_achievement'
         AND detailed_scores ? 'coherence_cohesion'
         AND detailed_scores ? 'lexical_resource'
         AND detailed_scores ? 'grammar_accuracy'
        THEN 1 
    END) as valid_count,
    CASE 
        WHEN COUNT(*) = COUNT(CASE 
            WHEN detailed_scores ? 'task_achievement'
             AND detailed_scores ? 'coherence_cohesion'
             AND detailed_scores ? 'lexical_resource'
             AND detailed_scores ? 'grammar_accuracy'
            THEN 1 
        END) THEN 'PASS' 
        ELSE 'FAIL' 
    END as status
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL
  AND detailed_scores IS NOT NULL;

-- Speaking detailed scores check (should have 4 criteria)
SELECT 
    'Speaking detailed_scores structure' as check_name,
    COUNT(*) as total_count,
    COUNT(CASE 
        WHEN detailed_scores ? 'fluency_coherence'
         AND detailed_scores ? 'lexical_resource'
         AND detailed_scores ? 'grammar_accuracy'
         AND detailed_scores ? 'pronunciation'
        THEN 1 
    END) as valid_count,
    CASE 
        WHEN COUNT(*) = COUNT(CASE 
            WHEN detailed_scores ? 'fluency_coherence'
             AND detailed_scores ? 'lexical_resource'
             AND detailed_scores ? 'grammar_accuracy'
             AND detailed_scores ? 'pronunciation'
            THEN 1 
        END) THEN 'PASS' 
        ELSE 'FAIL' 
    END as status
FROM user_exercise_attempts
WHERE audio_url IS NOT NULL
  AND detailed_scores IS NOT NULL;

-- ==============================================
-- SECTION 4: Sample Data Inspection
-- ==============================================

-- Sample writing submission
SELECT 
    'SAMPLE WRITING SUBMISSION' as section_title;
SELECT 
    id,
    user_id,
    task_type,
    word_count,
    band_score,
    evaluation_status,
    LEFT(essay_text, 100) || '...' as essay_preview,
    detailed_scores,
    created_at
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL
LIMIT 1;

-- Sample speaking submission
SELECT 
    'SAMPLE SPEAKING SUBMISSION' as section_title;
SELECT 
    id,
    user_id,
    speaking_part_number,
    audio_duration_seconds,
    band_score,
    evaluation_status,
    audio_url,
    transcript_word_count,
    detailed_scores,
    created_at
FROM user_exercise_attempts
WHERE audio_url IS NOT NULL
LIMIT 1;

-- ==============================================
-- SECTION 5: Migration Audit Log
-- ==============================================

SELECT 
    'MIGRATION AUDIT LOG' as section_title;
SELECT 
    migration_name,
    source_table,
    target_table,
    records_migrated,
    migration_status,
    migrated_at,
    notes
FROM migration_audit
WHERE migration_name LIKE '%migrate%writing%' 
   OR migration_name LIKE '%migrate%speaking%'
ORDER BY migrated_at DESC;

-- ==============================================
-- SECTION 6: Summary Report
-- ==============================================

SELECT 
    'MIGRATION SUMMARY REPORT' as section_title;

WITH counts AS (
    SELECT 
        COUNT(*) FILTER (WHERE essay_text IS NOT NULL) as writing_count,
        COUNT(*) FILTER (WHERE audio_url IS NOT NULL) as speaking_count,
        COUNT(*) FILTER (WHERE (essay_text IS NOT NULL OR audio_url IS NOT NULL) AND band_score IS NOT NULL) as evaluated_count,
        COUNT(*) FILTER (WHERE (essay_text IS NOT NULL OR audio_url IS NOT NULL) AND band_score IS NULL) as pending_count
    FROM user_exercise_attempts
)
SELECT 
    'Writing Submissions' as metric, writing_count as value FROM counts
UNION ALL
SELECT 
    'Speaking Submissions', speaking_count FROM counts
UNION ALL
SELECT 
    'Total Migrated', writing_count + speaking_count FROM counts
UNION ALL
SELECT 
    'Evaluated', evaluated_count FROM counts
UNION ALL
SELECT 
    'Pending Evaluation', pending_count FROM counts;

-- ==============================================
-- SECTION 7: User Distribution Check
-- ==============================================

SELECT 
    'USER DISTRIBUTION' as section_title;
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE essay_text IS NOT NULL) as writing_submissions,
    COUNT(*) FILTER (WHERE audio_url IS NOT NULL) as speaking_submissions,
    COUNT(*) as total_submissions
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL OR audio_url IS NOT NULL
GROUP BY user_id
ORDER BY total_submissions DESC
LIMIT 10;

-- Final message
SELECT 
    '✓ Verification script completed' as status,
    NOW() as verified_at;
