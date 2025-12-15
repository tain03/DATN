-- ============================================
-- PHASE 8: ADDITIONAL MISSING TABLES & RELATIONSHIPS
-- ============================================
-- Purpose: Seed data for tables that were missing
-- Database: course_db
-- 
-- Creates:
-- - video_subtitles
-- - lesson_materials
-- ============================================

-- ============================================
-- 1. VIDEO_SUBTITLES
-- ============================================
-- Subtitle files for lesson videos

INSERT INTO video_subtitles (
    id, video_id, language, subtitle_url, format, is_default
)
SELECT 
    uuid_generate_v4(),
    lv.id,
    lang.lang,
    'https://example.com/subtitles/' || lv.id::text || '_' || lang.lang || '.vtt',
    'vtt',
    CASE WHEN lang.lang = 'vi' THEN true ELSE false END
FROM lesson_videos lv
CROSS JOIN (VALUES ('vi'), ('en')) AS lang(lang)
WHERE random() > 0.3; -- 70% of videos have subtitles

-- ============================================
-- 2. LESSON_MATERIALS
-- ============================================
-- Additional learning materials (PDFs, documents)

WITH lesson_materials_with_rank AS (
    SELECT 
        l.id as lesson_id,
        row_number() OVER (PARTITION BY l.id ORDER BY random()) as rn
    FROM lessons l
    WHERE random() > 0.4 -- 60% of lessons have materials
)
INSERT INTO lesson_materials (
    id, lesson_id, title, description, file_type, file_url, file_size_bytes,
    display_order, total_downloads
)
SELECT 
    uuid_generate_v4(),
    lmwr.lesson_id,
    CASE lmwr.rn
        WHEN 1 THEN 'Lesson Notes PDF'
        WHEN 2 THEN 'Practice Exercises'
        WHEN 3 THEN 'Vocabulary List'
        ELSE 'Additional Resources'
    END,
    CASE (row_number() OVER () % 4)
        WHEN 0 THEN 'Complete lesson notes and key points'
        WHEN 1 THEN 'Practice exercises to reinforce learning'
        WHEN 2 THEN 'Vocabulary list with definitions'
        ELSE 'Additional reading materials'
    END,
    CASE (row_number() OVER () % 3)
        WHEN 0 THEN 'pdf'
        WHEN 1 THEN 'doc'
        ELSE 'zip'
    END,
    'https://example.com/materials/' || lmwr.lesson_id::text || '_' || 
    CASE (row_number() OVER () % 3)
        WHEN 0 THEN 'notes.pdf'
        WHEN 1 THEN 'exercises.doc'
        ELSE 'resources.zip'
    END,
    (random() * 5000000 + 100000)::BIGINT, -- 100KB to 5MB
    lmwr.rn,
    (random() * 100)::INTEGER
FROM lesson_materials_with_rank lmwr
WHERE lmwr.rn <= 3 -- Max 3 materials per lesson
LIMIT 200;

-- Summary
SELECT 
    'âœ… Course DB Phase 8 Complete' as status,
    (SELECT COUNT(*) FROM video_subtitles) as video_subtitles_count,
    (SELECT COUNT(*) FROM lesson_materials) as lesson_materials_count;

