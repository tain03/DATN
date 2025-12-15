-- ============================================
-- PHASE 6: NOTIFICATION_DB - NOTIFICATIONS
-- ============================================
-- Purpose: Create notifications and preferences
-- Database: notification_db
-- 
-- Creates:
-- - Notifications
-- - Push notifications
-- - Email notifications
-- - Notification preferences
-- - Device tokens
-- ============================================

-- ============================================
-- 1. NOTIFICATION_PREFERENCES
-- ============================================

INSERT INTO notification_preferences (
    user_id, push_enabled, push_achievements, push_reminders, push_course_updates,
    push_exercise_graded, email_enabled, email_weekly_report, email_course_updates,
    email_marketing, in_app_enabled, quiet_hours_enabled, quiet_hours_start, quiet_hours_end,
    max_notifications_per_day
)
-- Generate for all users (s0000001 to s0000050, instructors, admins)
SELECT 
    ('f' || LPAD((row_number() OVER ()::text), 7, '0') || '-0000-0000-0000-000000000' || LPAD((row_number() OVER ())::text, 3, '0'))::uuid,
    CASE WHEN random() > 0.2 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.25 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.15 THEN true ELSE false END,
    CASE WHEN random() > 0.4 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.7 THEN true ELSE false END,
    CASE WHEN random() > 0.1 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN TIME '22:00' ELSE NULL END,
    CASE WHEN random() > 0.5 THEN TIME '08:00' ELSE NULL END,
    (random() * 20 + 10)::INTEGER
FROM generate_series(1, 70)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- 2. DEVICE_TOKENS
-- ============================================

INSERT INTO device_tokens (
    id, user_id, device_token, device_type, device_id, device_name,
    app_version, os_version, is_active, last_used_at
)
SELECT 
    uuid_generate_v4(),
    ('f' || LPAD((row_number() OVER ()::text), 7, '0') || '-0000-0000-0000-000000000' || LPAD((row_number() OVER ())::text, 3, '0'))::uuid,
    'device_token_' || 'f' || LPAD((row_number() OVER ()::text), 7, '0') || '_' || (random() * 1000000)::INTEGER::text,
    CASE (random() * 3)::INTEGER WHEN 0 THEN 'web' WHEN 1 THEN 'android' ELSE 'ios' END,
    'device_' || (random() * 1000000)::INTEGER::text,
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Chrome Browser'
        WHEN 1 THEN 'Samsung Galaxy S21'
        ELSE 'iPhone 13'
    END,
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN '1.0.0'
        WHEN 1 THEN '1.1.0'
        ELSE '1.2.0'
    END,
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'Windows 11'
        WHEN 1 THEN 'Android 12'
        ELSE 'iOS 16'
    END,
    CASE WHEN random() > 0.2 THEN true ELSE false END,
    CURRENT_TIMESTAMP - (random() * 7)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 45)
WHERE random() > 0.4; -- 60% of users have devices

-- ============================================
-- 3. NOTIFICATIONS
-- ============================================

-- Achievement notifications
-- Note: This requires data from user_db, but we'll generate based on known achievement IDs
-- Achievement IDs: 1=first_lesson, 2=streak_7, 3=streak_30, 4=band_6, 5=band_7, 6=listening_master
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, created_at
)
SELECT 
    uuid_generate_v4(),
    ('f' || LPAD((row_number() OVER ()::text), 7, '0') || '-0000-0000-0000-000000000' || LPAD((1 + (row_number() OVER () - 1) % 50)::text, 3, '0'))::uuid,
    'achievement',
    'success',
    'ChÃºc má»«ng! ðŸŽ‰',
    'Báº¡n Ä‘Ã£ Ä‘áº¡t Ä‘Æ°á»£c thÃ nh tá»±u "' || 
    CASE (row_number() OVER () % 6)
        WHEN 0 THEN 'BÃ i há»c Ä‘áº§u tiÃªn'
        WHEN 1 THEN '7 ngÃ y liÃªn tiáº¿p'
        WHEN 2 THEN '30 ngÃ y liÃªn tiáº¿p'
        WHEN 3 THEN 'IELTS 6.0'
        WHEN 4 THEN 'IELTS 7.0'
        ELSE 'Listening Master'
    END || '"',
    'navigate_to_achievements',
    jsonb_build_object('achievement_id', 1 + (row_number() OVER () % 6)),
    'https://images.unsplash.com/photo-1550455091-5b7b5d5e5f5f?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.4 THEN true ELSE false END,
    CASE WHEN random() > 0.4 THEN CURRENT_TIMESTAMP - (random() * 7)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 300) gs
WHERE random() > 0.3 -- 70% chance for each notification
ORDER BY random()
LIMIT 300;

-- Exercise graded notifications
-- IMPORTANT: Only use actual student user IDs from auth_db
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
)
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, created_at
)
SELECT 
    uuid_generate_v4(),
    su.user_id,
    'exercise_graded',
    'success',
    'BÃ i táº­p Ä‘Ã£ Ä‘Æ°á»£c cháº¥m Ä‘iá»ƒm',
    'Báº¡n Ä‘áº¡t ' || (random() * 30 + 60)::INTEGER::text || '% trong bÃ i "IELTS ' || 
    CASE (row_number() OVER () % 2) WHEN 0 THEN 'Listening' ELSE 'Reading' END || 
    ' Practice Test". Xem chi tiáº¿t ngay!',
    'navigate_to_exercise',
    jsonb_build_object('exercise_id', uuid_generate_v4(), 'attempt_id', uuid_generate_v4()),
    'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN CURRENT_TIMESTAMP - (random() * 5)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 400) gs
CROSS JOIN student_users su
WHERE random() > 0.3
ORDER BY random()
LIMIT 400;

-- Writing evaluated notifications
-- IMPORTANT: Only use actual student user IDs from auth_db
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
)
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, created_at
)
SELECT 
    uuid_generate_v4(),
    su.user_id,
    'writing_evaluated',
    'success',
    'BÃ i viáº¿t Ä‘Ã£ Ä‘Æ°á»£c Ä‘Ã¡nh giÃ¡',
    'Báº¡n Ä‘áº¡t band ' || (random() * 3.0 + 5.5)::DECIMAL(2,1)::text || ' cho bÃ i Writing. Xem pháº£n há»“i chi tiáº¿t!',
    'navigate_to_writing',
    jsonb_build_object('submission_id', uuid_generate_v4(), 'evaluation_id', uuid_generate_v4()),
    'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN CURRENT_TIMESTAMP - (random() * 5)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 150) gs
CROSS JOIN student_users su
WHERE random() > 0.3
ORDER BY random()
LIMIT 150;

-- Speaking evaluated notifications
-- IMPORTANT: Only use actual student user IDs from auth_db
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
)
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, created_at
)
SELECT 
    uuid_generate_v4(),
    su.user_id,
    'speaking_evaluated',
    'success',
    'BÃ i nÃ³i Ä‘Ã£ Ä‘Æ°á»£c Ä‘Ã¡nh giÃ¡',
    'Báº¡n Ä‘áº¡t band ' || (random() * 3.0 + 5.5)::DECIMAL(2,1)::text || ' cho bÃ i Speaking. Xem pháº£n há»“i chi tiáº¿t!',
    'navigate_to_speaking',
    jsonb_build_object('submission_id', uuid_generate_v4(), 'evaluation_id', uuid_generate_v4()),
    'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.3 THEN true ELSE false END,
    CASE WHEN random() > 0.3 THEN CURRENT_TIMESTAMP - (random() * 5)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 10)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 120) gs
CROSS JOIN student_users su
WHERE random() > 0.3
ORDER BY random()
LIMIT 120;

-- Course update notifications
-- IMPORTANT: Only use actual student user IDs from auth_db (users who enrolled)
-- Note: Cannot query course_enrollments directly from notification_db, use student IDs
WITH enrolled_students AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
    WHERE random() > 0.5 -- 50% are enrolled
    LIMIT 30
)
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, created_at
)
SELECT 
    uuid_generate_v4(),
    es.user_id,
    'course_update',
    'info',
    'KhÃ³a há»c Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t',
    'KhÃ³a há»c "' || 
    CASE (row_number() OVER () % 5)
        WHEN 0 THEN 'IELTS Listening Foundation'
        WHEN 1 THEN 'IELTS Reading Mastery'
        WHEN 2 THEN 'IELTS Writing Advanced'
        WHEN 3 THEN 'IELTS Speaking Complete'
        ELSE 'IELTS Complete Preparation'
    END || '" cÃ³ bÃ i há»c má»›i. Xem ngay!',
    'navigate_to_course',
    jsonb_build_object('course_id', uuid_generate_v4()),
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.4 THEN true ELSE false END,
    CASE WHEN random() > 0.4 THEN CURRENT_TIMESTAMP - (random() * 5)::INTEGER * INTERVAL '1 day' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day',
    CURRENT_TIMESTAMP - (random() * 30)::INTEGER * INTERVAL '1 day'
FROM generate_series(1, 200) gs
CROSS JOIN enrolled_students es
WHERE random() > 0.3
ORDER BY random()
LIMIT 200;

-- Daily reminder notifications
-- IMPORTANT: Only use actual student user IDs from auth_db
WITH student_users AS (
    SELECT ('f' || LPAD(series::text, 7, '0') || '-0000-0000-0000-000000000' || LPAD(series::text, 3, '0'))::uuid as user_id
    FROM generate_series(1, 50) series
)
INSERT INTO notifications (
    id, user_id, type, category, title, message,
    action_type, action_data, icon_url, is_read, read_at,
    is_sent, sent_at, scheduled_for, created_at
)
SELECT 
    uuid_generate_v4(),
    su.user_id,
    'reminder',
    'info',
    'ÄÃ£ Ä‘áº¿n giá» há»c rá»“i! ðŸ“š',
    'HÃ£y dÃ nh ' || (30 + (random() * 60)::INTEGER)::text || ' phÃºt Ä‘á»ƒ tiáº¿p tá»¥c hÃ nh trÃ¬nh chinh phá»¥c IELTS cá»§a báº¡n!',
    'navigate_to_dashboard',
    jsonb_build_object(),
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&h=100&fit=crop',
    CASE WHEN random() > 0.5 THEN true ELSE false END,
    CASE WHEN random() > 0.5 THEN CURRENT_TIMESTAMP - (random() * 2)::INTEGER * INTERVAL '1 hour' ELSE NULL END,
    true,
    CURRENT_TIMESTAMP - (random() * 7)::INTEGER * INTERVAL '1 day' + (random() * 12 + 8)::INTEGER * INTERVAL '1 hour',
    CURRENT_TIMESTAMP - (random() * 7)::INTEGER * INTERVAL '1 day' + (random() * 12 + 8)::INTEGER * INTERVAL '1 hour',
    CURRENT_TIMESTAMP - (random() * 7)::INTEGER * INTERVAL '1 day' + (random() * 12 + 8)::INTEGER * INTERVAL '1 hour'
FROM generate_series(1, 150) gs
CROSS JOIN student_users su;

-- ============================================
-- 4. PUSH_NOTIFICATIONS
-- ============================================

INSERT INTO push_notifications (
    id, notification_id, user_id, device_token, device_type, device_id,
    title, body, data, status, sent_at, delivered_at, clicked_at
)
SELECT 
    uuid_generate_v4(),
    n.id,
    n.user_id,
    dt.device_token,
    dt.device_type,
    dt.device_id,
    n.title,
    n.message,
    n.action_data,
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'sent'
        WHEN 2 THEN 'delivered'
        ELSE 'failed'
    END,
    CASE WHEN random() > 0.3 THEN n.sent_at ELSE NULL END,
    CASE WHEN random() > 0.5 THEN n.sent_at + INTERVAL '5 seconds' ELSE NULL END,
    CASE WHEN random() > 0.6 THEN n.sent_at + INTERVAL '30 seconds' ELSE NULL END
FROM notifications n
JOIN device_tokens dt ON dt.user_id = n.user_id
WHERE n.is_sent = true
  AND random() > 0.4 -- 60% of notifications have push
LIMIT 600;

-- ============================================
-- 5. EMAIL_NOTIFICATIONS
-- ============================================

INSERT INTO email_notifications (
    id, notification_id, user_id, to_email, subject, body_html, body_text,
    template_name, template_data, status, sent_at, delivered_at, opened_at
)
SELECT 
    uuid_generate_v4(),
    n.id,
    n.user_id,
    'student' || LPAD((row_number() OVER ()::text), 2, '0') || '@example.com',
    n.title,
    '<html><body><h2>' || n.title || '</h2><p>' || n.message || '</p></body></html>',
    n.message,
    CASE n.type
        WHEN 'achievement' THEN 'achievement_unlocked'
        WHEN 'exercise_graded' THEN 'exercise_graded'
        WHEN 'course_update' THEN 'course_enrolled'
        ELSE 'generic'
    END,
    n.action_data,
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'sent'
        WHEN 2 THEN 'delivered'
        ELSE 'bounced'
    END,
    CASE WHEN random() > 0.3 THEN n.sent_at ELSE NULL END,
    CASE WHEN random() > 0.5 THEN n.sent_at + INTERVAL '1 minute' ELSE NULL END,
    CASE WHEN random() > 0.4 THEN n.sent_at + INTERVAL '5 minutes' ELSE NULL END
FROM notifications n
WHERE n.is_sent = true
  AND random() > 0.5 -- 50% of notifications have email
LIMIT 500;

-- Summary
SELECT 
    'âœ… Phase 6 Complete: Notifications Created' as status,
    (SELECT COUNT(*) FROM notification_preferences) as total_preferences,
    (SELECT COUNT(*) FROM device_tokens) as total_devices,
    (SELECT COUNT(*) FROM notifications) as total_notifications,
    (SELECT COUNT(*) FROM push_notifications) as total_push,
    (SELECT COUNT(*) FROM email_notifications) as total_email;

