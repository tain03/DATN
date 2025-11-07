-- ============================================
-- FIX EXERCISE SYNC STATUS
-- ============================================
-- Purpose: Mark completed exercises as synced
--          In production, Exercise Service syncs to User Service automatically
--          For seed data, we simulate this sync
-- Date: 2025-11-07
-- ============================================

\c exercise_db

DO $$
DECLARE
    synced_count INT := 0;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FIXING EXERCISE USER SERVICE SYNC';
    RAISE NOTICE '============================================';
    
    -- Mark all completed attempts as synced to User Service
    -- In production: Exercise Service calls User Service API after completion
    -- For seed data: Simulate successful sync
    UPDATE user_exercise_attempts
    SET 
        user_service_sync_status = 'synced',
        user_service_sync_attempts = 1,
        user_service_last_sync_attempt = completed_at
    WHERE status = 'completed' 
      AND user_service_sync_status = 'pending';
    
    GET DIAGNOSTICS synced_count = ROW_COUNT;
    RAISE NOTICE '✅ Marked % completed attempts as synced', synced_count;
    RAISE NOTICE '';
    RAISE NOTICE '📊 This simulates successful sync to User Service:';
    RAISE NOTICE '   - learning_progress.total_exercises_completed updated';
    RAISE NOTICE '   - Skill-specific progress tracked';
    RAISE NOTICE '   - Achievement checks performed';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  In production: Exercise Service → User Service API call';
    RAISE NOTICE '============================================';
END $$;

-- Validation
\c exercise_db
DO $$
DECLARE
    pending_count INT;
    synced_count INT;
BEGIN
    SELECT COUNT(*) INTO pending_count
    FROM user_exercise_attempts 
    WHERE status = 'completed' AND user_service_sync_status = 'pending';
    
    SELECT COUNT(*) INTO synced_count
    FROM user_exercise_attempts 
    WHERE status = 'completed' AND user_service_sync_status = 'synced';
    
    RAISE NOTICE '';
    RAISE NOTICE 'VALIDATION RESULTS:';
    RAISE NOTICE '✅ Completed & Synced: %', synced_count;
    RAISE NOTICE '⚠️  Completed & Pending: %', pending_count;
    
    IF pending_count > 0 THEN
        RAISE NOTICE '❌ Still have % pending completed attempts!', pending_count;
    ELSE
        RAISE NOTICE '✅ All completed attempts are synced!';
    END IF;
END $$;
