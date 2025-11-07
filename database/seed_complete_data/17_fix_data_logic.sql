-- ============================================
-- FIX REMAINING DATA LOGIC ISSUES
-- ============================================
-- Purpose: Fix all validation failures from comprehensive check
-- Date: 2025-11-07
-- ============================================

\c exercise_db

DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING WRITING/SPEAKING EXERCISE SCORES';
    RAISE NOTICE '============================================';
    
    -- Writing/Speaking exercises use band scores (0-9), not point-based scoring
    -- Set total_points = 9.0 (max band score) and passing_score = 5.0 (minimum passing)
    UPDATE exercises
    SET 
        total_points = 9.0,
        passing_score = 5.0
    WHERE skill_type IN ('writing', 'speaking')
      AND (total_points = 0 OR passing_score IS NULL);
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Updated % writing/speaking exercises with band score logic', updated_count;
    RAISE NOTICE '   total_points = 9.0 (max band score)';
    RAISE NOTICE '   passing_score = 5.0 (minimum passing band)';
END $$;

\c user_db

DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING STREAK LOGIC';
    RAISE NOTICE '============================================';
    
    -- Longest streak must be >= current streak (by definition)
    UPDATE learning_progress
    SET longest_streak_days = GREATEST(longest_streak_days, current_streak_days)
    WHERE current_streak_days > longest_streak_days;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % users with current_streak > longest_streak', updated_count;
    RAISE NOTICE '   Set longest_streak = MAX(longest, current)';
END $$;

\c course_db

DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING LESSON ACCESS TIMES';
    RAISE NOTICE '============================================';
    
    -- last_accessed_at must be >= first_accessed_at (timeline logic)
    UPDATE lesson_progress
    SET last_accessed_at = GREATEST(last_accessed_at, first_accessed_at)
    WHERE last_accessed_at < first_accessed_at;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Fixed % lessons with last_accessed < first_accessed', updated_count;
    RAISE NOTICE '   Set last_accessed = MAX(last, first)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'ALL FIXES APPLIED';
    RAISE NOTICE '============================================';
END $$;
