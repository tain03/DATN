-- ============================================
-- CROSS-DATABASE VALIDATION TRIGGERS
-- ============================================
-- Purpose: Add validation triggers for cross-database foreign key references
-- Databases: All databases with cross-db references
-- 
-- NOTE: TEMPORARILY DISABLED due to dblink connection issues during seeding
-- These triggers can be enabled after initial seed is complete
-- For production, update dblink connection strings with proper credentials
-- 
-- VALIDATES:
-- 1. course_db.courses.instructor_id â†’ auth_db.users.id
-- 2. exercise_db.exercises.course_id â†’ course_db.courses.id
-- 3. All user_id references â†’ auth_db.users.id
-- ============================================

-- ============================================
-- DROP EXISTING TRIGGERS FIRST
-- ============================================

\c course_db;
DROP TRIGGER IF EXISTS check_instructor_before_insert ON courses;
DROP TRIGGER IF EXISTS check_user_before_enrollment ON course_enrollments;
DROP TRIGGER IF EXISTS check_user_before_lesson_progress ON lesson_progress;
DROP TRIGGER IF EXISTS check_user_before_review ON course_reviews;
DROP FUNCTION IF EXISTS validate_instructor_exists();
DROP FUNCTION IF EXISTS validate_user_exists_for_enrollment();

\c exercise_db;
DROP TRIGGER IF EXISTS check_course_before_exercise ON exercises;
DROP TRIGGER IF EXISTS check_module_before_exercise ON exercises;
DROP TRIGGER IF EXISTS check_user_before_attempt ON user_exercise_attempts;
DROP TRIGGER IF EXISTS check_user_before_answer ON user_answers;
DROP TRIGGER IF EXISTS check_creator_before_exercise ON exercises;
DROP FUNCTION IF EXISTS validate_course_exists();
DROP FUNCTION IF EXISTS validate_module_exists();
DROP FUNCTION IF EXISTS validate_user_exists_for_attempt();
DROP FUNCTION IF EXISTS validate_creator_exists();

\c user_db;
DROP TRIGGER IF EXISTS check_user_before_profile ON user_profiles;
DROP TRIGGER IF EXISTS check_user_before_progress ON learning_progress;
DROP TRIGGER IF EXISTS check_user_before_statistics ON skill_statistics;
DROP TRIGGER IF EXISTS check_user_before_practice ON practice_activities;
DROP TRIGGER IF EXISTS check_user_before_test_result ON official_test_results;
DROP TRIGGER IF EXISTS check_user_before_session ON study_sessions;
DROP TRIGGER IF EXISTS check_user_before_goal ON study_goals;
DROP TRIGGER IF EXISTS check_user_before_achievement ON user_achievements;
DROP FUNCTION IF EXISTS validate_user_exists_for_profile();

\c notification_db;
DROP TRIGGER IF EXISTS check_user_before_notification ON notifications;
DROP TRIGGER IF EXISTS check_user_before_email ON email_notifications;
DROP TRIGGER IF EXISTS check_user_before_push ON push_notifications;
DROP TRIGGER IF EXISTS check_user_before_device ON device_tokens;
DROP FUNCTION IF EXISTS validate_user_exists_for_notification();

-- SKIP ALL TRIGGER CREATION FOR NOW
-- Uncomment below to enable cross-database validation

/*

-- ============================================
-- DATABASE: course_db
-- ============================================

\c course_db;

-- Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- ============================================
-- VALIDATE INSTRUCTOR EXISTS IN AUTH_DB
-- ============================================

CREATE OR REPLACE FUNCTION validate_instructor_exists()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
    v_has_instructor_role BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1 
        FROM dblink('dbname=auth_db', 
            format('SELECT id FROM users WHERE id = %L AND is_active = true AND deleted_at IS NULL', NEW.instructor_id)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'Instructor with ID % does not exist or is inactive', NEW.instructor_id;
    END IF;

    -- Check if user has instructor role (role_id = 2)
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT user_id FROM user_roles WHERE user_id = %L AND role_id = 2', NEW.instructor_id)
        ) AS t(user_id UUID)
    ) INTO v_has_instructor_role;

    IF NOT v_has_instructor_role THEN
        RAISE EXCEPTION 'User % does not have instructor role', NEW.instructor_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS check_instructor_before_insert ON courses;
CREATE TRIGGER check_instructor_before_insert
    BEFORE INSERT OR UPDATE OF instructor_id ON courses
    FOR EACH ROW
    EXECUTE FUNCTION validate_instructor_exists();

-- ============================================
-- VALIDATE USER EXISTS FOR ENROLLMENTS
-- ============================================

CREATE OR REPLACE FUNCTION validate_user_exists_for_enrollment()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT id FROM users WHERE id = %L AND is_active = true AND deleted_at IS NULL', NEW.user_id)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'User with ID % does not exist or is inactive', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to course_enrollments
DROP TRIGGER IF EXISTS check_user_before_enrollment ON course_enrollments;
CREATE TRIGGER check_user_before_enrollment
    BEFORE INSERT ON course_enrollments
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_enrollment();

-- Apply to lesson_progress
DROP TRIGGER IF EXISTS check_user_before_lesson_progress ON lesson_progress;
CREATE TRIGGER check_user_before_lesson_progress
    BEFORE INSERT ON lesson_progress
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_enrollment();

-- Apply to course_reviews
DROP TRIGGER IF EXISTS check_user_before_review ON course_reviews;
CREATE TRIGGER check_user_before_review
    BEFORE INSERT ON course_reviews
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_enrollment();

-- ============================================
-- DATABASE: exercise_db
-- ============================================

\c exercise_db;

-- Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- ============================================
-- VALIDATE COURSE EXISTS IN COURSE_DB
-- ============================================

CREATE OR REPLACE FUNCTION validate_course_exists()
RETURNS TRIGGER AS $$
DECLARE
    v_course_exists BOOLEAN;
BEGIN
    -- Skip validation if course_id is NULL (exercises without courses)
    IF NEW.course_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if course exists in course_db  
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=course_db user=ielts_admin',
            format('SELECT id FROM courses WHERE id = %L AND status = ''published'' AND deleted_at IS NULL', NEW.course_id)
        ) AS t(id UUID)
    ) INTO v_course_exists;

    IF NOT v_course_exists THEN
        RAISE EXCEPTION 'Course with ID % does not exist or is not published', NEW.course_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to exercises table
DROP TRIGGER IF EXISTS check_course_before_exercise ON exercises;
CREATE TRIGGER check_course_before_exercise
    BEFORE INSERT OR UPDATE OF course_id ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION validate_course_exists();

-- ============================================
-- VALIDATE MODULE EXISTS FOR EXERCISES
-- ============================================

CREATE OR REPLACE FUNCTION validate_module_exists()
RETURNS TRIGGER AS $$
DECLARE
    v_module_exists BOOLEAN;
BEGIN
    -- Skip validation if module_id is NULL
    IF NEW.module_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if module exists in course_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=course_db',
            format('SELECT id FROM modules WHERE id = %L AND is_published = true', NEW.module_id)
        ) AS t(id UUID)
    ) INTO v_module_exists;

    IF NOT v_module_exists THEN
        RAISE EXCEPTION 'Module with ID % does not exist or is not published', NEW.module_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to exercises table
DROP TRIGGER IF EXISTS check_module_before_exercise ON exercises;
CREATE TRIGGER check_module_before_exercise
    BEFORE INSERT OR UPDATE OF module_id ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION validate_module_exists();

-- ============================================
-- VALIDATE USER EXISTS FOR EXERCISE ATTEMPTS
-- ============================================

CREATE OR REPLACE FUNCTION validate_user_exists_for_attempt()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT id FROM users WHERE id = %L AND is_active = true AND deleted_at IS NULL', NEW.user_id)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'User with ID % does not exist or is inactive', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to user_exercise_attempts
DROP TRIGGER IF EXISTS check_user_before_attempt ON user_exercise_attempts;
CREATE TRIGGER check_user_before_attempt
    BEFORE INSERT ON user_exercise_attempts
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_attempt();

-- Apply to user_answers
DROP TRIGGER IF EXISTS check_user_before_answer ON user_answers;
CREATE TRIGGER check_user_before_answer
    BEFORE INSERT ON user_answers
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_attempt();

-- ============================================
-- VALIDATE CREATED_BY EXISTS
-- ============================================

CREATE OR REPLACE FUNCTION validate_creator_exists()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
    v_has_instructor_role BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT id FROM users WHERE id = %L AND is_active = true', NEW.created_by)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'Creator with ID % does not exist or is inactive', NEW.created_by;
    END IF;

    -- Check if user has instructor or admin role
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT user_id FROM user_roles WHERE user_id = %L AND role_id IN (2, 3)', NEW.created_by)
        ) AS t(user_id UUID)
    ) INTO v_has_instructor_role;

    IF NOT v_has_instructor_role THEN
        RAISE EXCEPTION 'User % does not have instructor or admin role', NEW.created_by;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to exercises table
DROP TRIGGER IF EXISTS check_creator_before_exercise ON exercises;
CREATE TRIGGER check_creator_before_exercise
    BEFORE INSERT ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION validate_creator_exists();

-- ============================================
-- DATABASE: user_db
-- ============================================

\c user_db;

-- Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- ============================================
-- VALIDATE USER EXISTS FOR USER PROFILES
-- ============================================

CREATE OR REPLACE FUNCTION validate_user_exists_for_profile()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT id FROM users WHERE id = %L AND is_active = true AND deleted_at IS NULL', NEW.user_id)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'User with ID % does not exist or is inactive', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to user_profiles
DROP TRIGGER IF EXISTS check_user_before_profile ON user_profiles;
CREATE TRIGGER check_user_before_profile
    BEFORE INSERT ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to learning_progress
DROP TRIGGER IF EXISTS check_user_before_progress ON learning_progress;
CREATE TRIGGER check_user_before_progress
    BEFORE INSERT ON learning_progress
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to skill_statistics
DROP TRIGGER IF EXISTS check_user_before_statistics ON skill_statistics;
CREATE TRIGGER check_user_before_statistics
    BEFORE INSERT ON skill_statistics
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to practice_activities
DROP TRIGGER IF EXISTS check_user_before_practice ON practice_activities;
CREATE TRIGGER check_user_before_practice
    BEFORE INSERT ON practice_activities
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to official_test_results
DROP TRIGGER IF EXISTS check_user_before_test_result ON official_test_results;
CREATE TRIGGER check_user_before_test_result
    BEFORE INSERT ON official_test_results
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to study_sessions
DROP TRIGGER IF EXISTS check_user_before_session ON study_sessions;
CREATE TRIGGER check_user_before_session
    BEFORE INSERT ON study_sessions
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to study_goals
DROP TRIGGER IF EXISTS check_user_before_goal ON study_goals;
CREATE TRIGGER check_user_before_goal
    BEFORE INSERT ON study_goals
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- Apply to user_achievements
DROP TRIGGER IF EXISTS check_user_before_achievement ON user_achievements;
CREATE TRIGGER check_user_before_achievement
    BEFORE INSERT ON user_achievements
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_profile();

-- ============================================
-- DATABASE: notification_db
-- ============================================

\c notification_db;

-- Ensure dblink extension exists
CREATE EXTENSION IF NOT EXISTS dblink;

-- ============================================
-- VALIDATE USER EXISTS FOR NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION validate_user_exists_for_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Check if user exists in auth_db
    SELECT EXISTS (
        SELECT 1
        FROM dblink('dbname=auth_db',
            format('SELECT id FROM users WHERE id = %L AND is_active = true AND deleted_at IS NULL', NEW.user_id)
        ) AS t(id UUID)
    ) INTO v_user_exists;

    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'User with ID % does not exist or is inactive', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to notifications
DROP TRIGGER IF EXISTS check_user_before_notification ON notifications;
CREATE TRIGGER check_user_before_notification
    BEFORE INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_notification();

-- Apply to email_notifications
DROP TRIGGER IF EXISTS check_user_before_email ON email_notifications;
CREATE TRIGGER check_user_before_email
    BEFORE INSERT ON email_notifications
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_notification();

-- Apply to push_notifications
DROP TRIGGER IF EXISTS check_user_before_push ON push_notifications;
CREATE TRIGGER check_user_before_push
    BEFORE INSERT ON push_notifications
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_notification();

-- Apply to device_tokens
DROP TRIGGER IF EXISTS check_user_before_device ON device_tokens;
CREATE TRIGGER check_user_before_device
    BEFORE INSERT ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_exists_for_notification();

-- ============================================
-- SUMMARY & VERIFICATION
-- ============================================

-- Switch back to default database
\c postgres;

-- Print summary
SELECT 
    'âœ… Phase Complete: Cross-Database Validation Triggers Added' as status,
    'All foreign key references now validated across databases' as description;

-- ============================================
-- NOTES
-- ============================================

/*
IMPORTANT NOTES:

1. DBLINK CONNECTION:
   - These triggers use dblink to query other databases
   - Ensure dblink extension is installed in all databases
   - Connection uses default credentials (same PostgreSQL server)

2. PERFORMANCE CONSIDERATIONS:
   - Each trigger makes 1-2 database queries via dblink
   - For high-volume inserts, this may impact performance
   - Consider disabling triggers for bulk imports

3. DISABLE TRIGGERS FOR BULK OPERATIONS:
   ALTER TABLE table_name DISABLE TRIGGER trigger_name;
   -- Do bulk insert
   ALTER TABLE table_name ENABLE TRIGGER trigger_name;

4. ERROR HANDLING:
   - Triggers will RAISE EXCEPTION on validation failure
   - Transaction will be rolled back
   - Useful for catching data integrity issues early

5. SECURITY:
   - Triggers validate that users are active and not deleted
   - Instructors must have proper role assigned
   - Course creators must be instructors or admins

6. CASCADE BEHAVIOR:
   - These triggers do NOT implement cascade deletes
   - If a user is deleted from auth_db, related records remain
   - Implement cleanup jobs or soft deletes instead

7. TESTING:
   - Test each trigger independently
   - Verify error messages are clear
   - Check performance impact on inserts

8. MAINTENANCE:
   - Document any changes to table structure
   - Update triggers if foreign key relationships change
   - Monitor trigger execution times

TESTING EXAMPLES:

-- Test invalid instructor:
INSERT INTO courses (instructor_id, ...) 
VALUES ('00000000-0000-0000-0000-000000000000'::uuid, ...);
-- Expected: ERROR - Instructor does not exist

-- Test user without instructor role:
INSERT INTO courses (instructor_id, ...) 
VALUES ('f0000001-...'::uuid, ...); -- Student ID
-- Expected: ERROR - User does not have instructor role

-- Test invalid course reference:
INSERT INTO exercises (course_id, ...) 
VALUES ('00000000-0000-0000-0000-000000000000'::uuid, ...);
-- Expected: ERROR - Course does not exist

-- Test inactive user:
UPDATE users SET is_active = false WHERE id = '...';
INSERT INTO course_enrollments (user_id, ...) VALUES ('...'::uuid, ...);
-- Expected: ERROR - User is inactive
*/

*/
SELECT 'âš ï¸ Cross-Database Validation Triggers DISABLED' as status, 'Enable after seed by uncommenting' as action;
