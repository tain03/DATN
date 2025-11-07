-- ============================================
-- FIX LESSON LAST POSITION FOR VIDEO RESUME
-- ============================================
-- Purpose: Calculate last_position_seconds from progress_percentage
--          This allows users to resume watching from correct position
-- Date: 2025-11-07
-- ============================================

\c course_db

DO $$
DECLARE
    updated_count INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING LESSON LAST POSITION';
    RAISE NOTICE '============================================';
    
    -- Calculate last_position_seconds from progress_percentage
    -- Formula: last_position = (progress_percentage / 100) * video_total_seconds
    -- This ensures users can resume watching from correct position
    UPDATE lesson_progress
    SET last_position_seconds = ROUND((progress_percentage / 100.0) * video_total_seconds)
    WHERE video_total_seconds IS NOT NULL 
      AND video_total_seconds > 0
      AND progress_percentage > 0
      AND last_position_seconds = 0;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Updated % lesson progress records with last_position', updated_count;
    RAISE NOTICE '';
    RAISE NOTICE '📺 Users can now resume watching from correct position!';
    RAISE NOTICE '   Example: 50%% progress on 1000s video → resume at 500s';
    RAISE NOTICE '============================================';
END $$;
