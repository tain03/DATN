-- ============================================
-- CHECK MISSING DATA IN ALL TABLES
-- ============================================
-- Purpose: Identify columns with many NULL values
-- Date: 2025-11-07
-- ============================================

\c user_db

DO $$
DECLARE
    total_rows INT;
    col_record RECORD;
BEGIN
    SELECT COUNT(*) INTO total_rows FROM learning_progress;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'LEARNING_PROGRESS - Total rows: %', total_rows;
    RAISE NOTICE '============================================';
    
    FOR col_record IN 
        SELECT 
            column_name,
            data_type
        FROM information_schema.columns
        WHERE table_name = 'learning_progress'
        AND column_name NOT IN ('id', 'user_id', 'created_at', 'updated_at')
        ORDER BY ordinal_position
    LOOP
        EXECUTE format('
            SELECT COUNT(*) 
            FROM learning_progress 
            WHERE %I IS NOT NULL
        ', col_record.column_name) INTO total_rows;
        
        IF total_rows = 0 THEN
            RAISE NOTICE '❌ %: 0 rows (100%% NULL)', col_record.column_name;
        ELSIF total_rows < 10 THEN
            RAISE NOTICE '⚠️  %: % rows', col_record.column_name, total_rows;
        END IF;
    END LOOP;
    
    RAISE NOTICE '============================================';
END $$;

\c course_db

DO $$
DECLARE
    total_rows INT;
    col_record RECORD;
BEGIN
    SELECT COUNT(*) INTO total_rows FROM courses;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'COURSES - Total rows: %', total_rows;
    RAISE NOTICE '============================================';
    
    FOR col_record IN 
        SELECT 
            column_name,
            data_type
        FROM information_schema.columns
        WHERE table_name = 'courses'
        AND column_name NOT IN ('id', 'created_at', 'updated_at', 'deleted_at')
        ORDER BY ordinal_position
    LOOP
        EXECUTE format('
            SELECT COUNT(*) 
            FROM courses 
            WHERE %I IS NOT NULL
        ', col_record.column_name) INTO total_rows;
        
        IF total_rows = 0 THEN
            RAISE NOTICE '❌ %: 0 rows (100%% NULL)', col_record.column_name;
        ELSIF total_rows < 10 THEN
            RAISE NOTICE '⚠️  %: % rows', col_record.column_name, total_rows;
        END IF;
    END LOOP;
    
    RAISE NOTICE '============================================';
END $$;

\c exercise_db

DO $$
DECLARE
    total_rows INT;
    col_record RECORD;
BEGIN
    SELECT COUNT(*) INTO total_rows FROM exercises;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXERCISES - Total rows: %', total_rows;
    RAISE NOTICE '============================================';
    
    FOR col_record IN 
        SELECT 
            column_name,
            data_type
        FROM information_schema.columns
        WHERE table_name = 'exercises'
        AND column_name NOT IN ('id', 'created_at', 'updated_at', 'deleted_at')
        ORDER BY ordinal_position
    LOOP
        EXECUTE format('
            SELECT COUNT(*) 
            FROM exercises 
            WHERE %I IS NOT NULL
        ', col_record.column_name) INTO total_rows;
        
        IF total_rows = 0 THEN
            RAISE NOTICE '❌ %: 0 rows (100%% NULL)', col_record.column_name;
        ELSIF total_rows < 10 THEN
            RAISE NOTICE '⚠️  %: % rows', col_record.column_name, total_rows;
        END IF;
    END LOOP;
    
    RAISE NOTICE '============================================';
END $$;
