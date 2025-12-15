-- ============================================
-- PHASE 8: ADDITIONAL MISSING TABLES & RELATIONSHIPS
-- ============================================
-- Purpose: Seed data for tables that were missing
-- Database: notification_db
-- 
-- Creates:
-- - scheduled_notifications
-- ============================================

-- ============================================
-- SCHEDULED_NOTIFICATIONS
-- ============================================
-- Recurring scheduled notifications (study reminders)

INSERT INTO scheduled_notifications (
    id, user_id, title, message, schedule_type, scheduled_time,
    days_of_week, timezone, is_active, last_sent_at, next_send_at
)
SELECT 
    uuid_generate_v4(),
    ('f' || LPAD((row_number() OVER ()::text), 7, '0') || '-0000-0000-0000-000000000' || LPAD((row_number() OVER ())::text, 3, '0'))::uuid,
    'Nháº¯c nhá»Ÿ há»c táº­p hÃ ng ngÃ y',
    'ÄÃ£ Ä‘áº¿n giá» há»c rá»“i! HÃ£y dÃ nh thá»i gian Ä‘á»ƒ luyá»‡n táº­p IELTS ngay hÃ´m nay.',
    'daily',
    CASE (row_number() OVER () % 3)
        WHEN 0 THEN TIME '07:00'
        WHEN 1 THEN TIME '19:00'
        ELSE TIME '21:00'
    END,
    CASE (row_number() OVER () % 3)
        WHEN 0 THEN ARRAY[1,2,3,4,5] -- Weekdays
        WHEN 1 THEN ARRAY[0,6] -- Weekends
        ELSE ARRAY[1,2,3,4,5,6,0] -- Every day
    END,
    'Asia/Ho_Chi_Minh',
    CASE WHEN random() > 0.2 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN CURRENT_TIMESTAMP - INTERVAL '1 day' ELSE NULL END,
    CASE WHEN random() > 0.5 THEN CURRENT_TIMESTAMP + INTERVAL '1 day' ELSE NULL END
FROM generate_series(1, 40) -- 40 users have scheduled reminders
WHERE random() > 0.4;

-- Summary
SELECT 
    'âœ… Notification DB Phase 8 Complete' as status,
    COUNT(*) as total_scheduled,
    COUNT(*) FILTER (WHERE is_active = true) as active_scheduled
FROM scheduled_notifications;

