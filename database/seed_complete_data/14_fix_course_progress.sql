-- ============================================
-- FIX COURSE PROGRESS LOGIC
-- ============================================
-- Purpose: Remove manually-set progress_percentage in course_enrollments
--          Backend calculates this REAL-TIME from lesson_progress
-- Date: 2025-11-07
-- ============================================

\c course_db

DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING COURSE ENROLLMENT PROGRESS';
    RAISE NOTICE '============================================';
    
    -- Reset all progress_percentage to 0 (will be calculated real-time by backend)
    -- Backend query in GetUserEnrollments:
    -- progress_percentage = ROUND(SUM(lp.progress_percentage) / total_lessons, 2)
    UPDATE course_enrollments
    SET 
        progress_percentage = 0,
        total_time_spent_minutes = 0,  -- Also calculated real-time from lesson_progress.last_position_seconds
        lessons_completed = 0          -- Also calculated real-time from COUNT(lp WHERE status='completed')
    WHERE progress_percentage > 0 
       OR total_time_spent_minutes > 0 
       OR lessons_completed > 0;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Reset % enrollment records (will be calculated real-time)', updated_count;
    RAISE NOTICE '';
    RAISE NOTICE '📊 Backend calculates these fields dynamically:';
    RAISE NOTICE '   - progress_percentage = SUM(lesson.progress) / total_lessons';
    RAISE NOTICE '   - lessons_completed = COUNT(lessons WHERE status=completed)';
    RAISE NOTICE '   - total_time_spent = SUM(lesson.last_position_seconds / 60)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ This ensures data consistency - no drift between enrollments and lesson_progress!';
    RAISE NOTICE '============================================';
END $$;
