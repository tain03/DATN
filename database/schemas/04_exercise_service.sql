-- ============================================================================
-- EXERCISE SERVICE DATABASE SCHEMA (CLEAN VERSION)
-- ============================================================================
-- Database: exercise_db
-- Purpose: Exercise management for ALL 4 IELTS skills (Listening, Reading, Writing, Speaking)
--          Single source of truth for exercises, prompts, questions, and submissions
-- Version: 2.0
-- Last Updated: 2025-11-07
--
-- KEY FEATURES:
-- - Manages exercises for all 4 skills (L/R/W/S)
-- - Stores Writing/Speaking prompts directly in exercises table
-- - Stores all user submissions (user_exercise_attempts)
-- - Auto-grades L/R, calls AI service ONLY for W/S evaluation
--
-- IMPORTANT: This is a CLEAN schema file that creates the database from scratch.
-- It is NOT a migration file. Use this to:
--   1. Create a new exercise_db database
--   2. Understand the current schema structure
--   3. Document the database design
--
-- DO NOT use this file to update an existing database.
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Full-text search
CREATE EXTENSION IF NOT EXISTS "dblink"; -- Cross-database queries

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercises Table
-- ----------------------------------------------------------------------------
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(250) UNIQUE NOT NULL,
    description TEXT,
    exercise_type VARCHAR(50) NOT NULL, -- 'listening', 'reading', 'writing', 'speaking', 'mixed'
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('listening', 'reading', 'writing', 'speaking')),
    difficulty VARCHAR(20) NOT NULL, -- 'easy', 'medium', 'hard'
    ielts_level VARCHAR(20), -- '4.0-5.0', '5.5-6.5', '7.0-8.0', '8.5-9.0'
    
    -- Structure
    total_questions INTEGER DEFAULT 0,
    total_sections INTEGER DEFAULT 0,
    time_limit_minutes INTEGER,
    
    -- Media assets
    thumbnail_url TEXT,
    audio_url TEXT,
    audio_duration_seconds INTEGER,
    audio_transcript TEXT,
    passage_count INTEGER,
    
    -- Course association
    course_id UUID, -- References course_db.courses.id
    
    -- Grading
    passing_score NUMERIC(5,2),
    total_points NUMERIC(5,2),
    
    -- Publishing
    is_free BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,
    total_attempts INTEGER DEFAULT 0,
    average_score NUMERIC(5,2),
    average_completion_time INTEGER, -- seconds
    display_order INTEGER DEFAULT 0,
    created_by UUID NOT NULL,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    module_id UUID, -- References course_db.modules.id
    ielts_test_type VARCHAR(20) CHECK (ielts_test_type IN ('academic', 'general_training')),
    
    -- Test categorization
    is_official_test BOOLEAN DEFAULT false,
    test_category VARCHAR(30) CHECK (test_category IS NULL OR test_category IN ('practice', 'mock_test', 'official_test', 'mini_test')),
    
    -- Writing exercise fields (added for Phase 4)
    writing_task_type VARCHAR(20) CHECK (writing_task_type IN ('task1', 'task2')),
    writing_prompt_text TEXT,
    writing_visual_type VARCHAR(50), -- 'bar_chart', 'line_graph', 'pie_chart', 'table', 'process_diagram', 'map'
    writing_visual_url TEXT,
    writing_word_requirement INTEGER DEFAULT 250, -- Task 1: 150, Task 2: 250
    
    -- Speaking exercise fields (added for Phase 4)
    speaking_part_number INTEGER CHECK (speaking_part_number IN (1, 2, 3)),
    speaking_prompt_text TEXT,
    speaking_cue_card_topic VARCHAR(200), -- For Part 2
    speaking_cue_card_points TEXT[], -- Array of bullet points for Part 2
    speaking_preparation_time_seconds INTEGER DEFAULT 60, -- Part 2: 1 minute prep
    speaking_response_time_seconds INTEGER DEFAULT 120, -- Part 2: 2 minutes speaking
    speaking_follow_up_questions TEXT[], -- For Part 3
    
    -- Constraint: Reading exercises must have ielts_test_type
    CONSTRAINT chk_reading_ielts_test_type CHECK (
        (skill_type = 'reading' AND ielts_test_type IS NOT NULL) OR
        (skill_type != 'reading' AND ielts_test_type IS NULL)
    ),
    
    -- Constraint: Writing exercises must have task type and prompt
    CONSTRAINT chk_writing_required_fields CHECK (
        (skill_type != 'writing') OR 
        (writing_task_type IS NOT NULL AND writing_prompt_text IS NOT NULL)
    ),
    
    -- Constraint: Speaking exercises must have part number and prompt
    CONSTRAINT chk_speaking_required_fields CHECK (
        (skill_type != 'speaking') OR 
        (speaking_part_number IS NOT NULL AND speaking_prompt_text IS NOT NULL)
    )
);

CREATE INDEX idx_exercises_skill_type ON exercises(skill_type);
CREATE INDEX idx_exercises_difficulty ON exercises(difficulty);
CREATE INDEX idx_exercises_exercise_type ON exercises(exercise_type);
CREATE INDEX idx_exercises_is_published ON exercises(is_published);
CREATE INDEX idx_exercises_module_id ON exercises(module_id);
CREATE INDEX idx_exercises_slug ON exercises(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercises_test_category ON exercises(test_category);
CREATE INDEX idx_exercises_test_type ON exercises(skill_type, ielts_test_type) WHERE skill_type = 'reading';
CREATE INDEX idx_exercises_is_official_test ON exercises(is_official_test) WHERE is_official_test = true;
CREATE INDEX idx_exercises_writing_task ON exercises(writing_task_type) WHERE skill_type = 'writing';
CREATE INDEX idx_exercises_speaking_part ON exercises(speaking_part_number) WHERE skill_type = 'speaking';

-- ----------------------------------------------------------------------------
-- Exercise Sections Table
-- ----------------------------------------------------------------------------
CREATE TABLE exercise_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    title VARCHAR(200),
    description TEXT,
    section_number INTEGER NOT NULL,
    
    -- Audio content (for listening)
    audio_url TEXT,
    audio_start_time INTEGER, -- seconds
    audio_end_time INTEGER, -- seconds
    transcript TEXT,
    
    -- Reading passage
    passage_title VARCHAR(200),
    passage_content TEXT,
    passage_word_count INTEGER,
    
    -- Instructions
    instructions TEXT,
    
    -- Metadata
    total_questions INTEGER DEFAULT 0,
    time_limit_minutes INTEGER,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_exercise_sections_exercise_id ON exercise_sections(exercise_id);
CREATE INDEX idx_exercise_sections_section_number ON exercise_sections(exercise_id, section_number);

-- ----------------------------------------------------------------------------
-- Questions Table
-- ----------------------------------------------------------------------------
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    section_id UUID REFERENCES exercise_sections(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL, -- 'multiple_choice', 'fill_in_blank', 'matching', 'true_false', 'short_answer', 'essay'
    
    -- Media
    audio_url TEXT,
    image_url TEXT,
    context_text TEXT,
    
    -- Grading
    points NUMERIC(5,2) DEFAULT 1,
    difficulty VARCHAR(20), -- 'easy', 'medium', 'hard'
    
    -- Help content
    explanation TEXT,
    tips TEXT,
    
    -- Metadata
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_questions_exercise_id ON questions(exercise_id);
CREATE INDEX idx_questions_section_id ON questions(section_id);
CREATE INDEX idx_questions_question_type ON questions(question_type);
CREATE INDEX idx_questions_number ON questions(exercise_id, question_number);

-- ----------------------------------------------------------------------------
-- Question Options Table (for multiple choice)
-- ----------------------------------------------------------------------------
CREATE TABLE question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_label VARCHAR(10), -- 'A', 'B', 'C', 'D'
    option_text TEXT NOT NULL,
    option_image_url TEXT,
    is_correct BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_question_options_question_id ON question_options(question_id);

-- ----------------------------------------------------------------------------
-- Question Answers Table (for non-multiple choice)
-- ----------------------------------------------------------------------------
CREATE TABLE question_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    answer_variations TEXT[], -- Alternative accepted answers
    match_left TEXT, -- For matching questions: left side
    match_right TEXT, -- For matching questions: right side
    is_primary_answer BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_question_answers_question_id ON question_answers(question_id);

-- ============================================================================
-- USER ATTEMPT TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- User Exercise Attempts Table
-- ----------------------------------------------------------------------------
CREATE TABLE user_exercise_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE,
    attempt_number INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'completed', 'abandoned'
    
    -- Scoring
    total_questions INTEGER NOT NULL,
    questions_answered INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    score NUMERIC(5,2),
    band_score NUMERIC(3,1) CHECK (band_score IS NULL OR (band_score >= 0 AND band_score <= 9)),
    
    -- Timing
    time_limit_minutes INTEGER,
    time_spent_seconds INTEGER DEFAULT 0,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Metadata
    device_type VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Cross-service synchronization
    is_official_test BOOLEAN DEFAULT false,
    official_test_result_id UUID, -- Reference to user_db.official_test_results.id
    practice_activity_id UUID, -- Reference to user_db.practice_activities.id
    
    -- Writing-specific fields
    essay_text TEXT,
    word_count INTEGER,
    task_type VARCHAR(20), -- 'task1', 'task2'
    prompt_text TEXT,
    
    -- Speaking-specific fields
    audio_url TEXT,
    audio_duration_seconds INTEGER,
    audio_format VARCHAR(20),
    transcript_text TEXT,
    transcript_word_count INTEGER,
    speaking_part_number INTEGER,
    
    -- AI Evaluation
    evaluation_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    ai_evaluation_id UUID,
    detailed_scores JSONB, -- Detailed band scores by criterion
    ai_feedback TEXT,
    ai_model_name VARCHAR(100),
    ai_processing_time_ms INTEGER,
    
    -- Service sync status
    user_service_sync_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'synced', 'failed'
    user_service_sync_attempts INTEGER DEFAULT 0,
    user_service_last_sync_attempt TIMESTAMP,
    user_service_sync_error TEXT
);

CREATE INDEX idx_user_exercise_attempts_user_id ON user_exercise_attempts(user_id);
CREATE INDEX idx_user_exercise_attempts_exercise_id ON user_exercise_attempts(exercise_id);
CREATE INDEX idx_user_exercise_attempts_completed_at ON user_exercise_attempts(completed_at);
CREATE INDEX idx_user_exercise_attempts_status ON user_exercise_attempts(status);
CREATE INDEX idx_user_exercise_attempts_sync_status ON user_exercise_attempts(user_service_sync_status);
CREATE INDEX idx_user_exercise_attempts_evaluation_status ON user_exercise_attempts(evaluation_status) 
    WHERE evaluation_status IN ('pending', 'processing');
CREATE INDEX idx_user_exercise_attempts_is_official ON user_exercise_attempts(is_official_test) 
    WHERE is_official_test = true;
CREATE INDEX idx_user_exercise_attempts_official_test_result_id ON user_exercise_attempts(official_test_result_id) 
    WHERE official_test_result_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- User Answers Table
-- ----------------------------------------------------------------------------
CREATE TABLE user_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES user_exercise_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    
    -- Answer content
    answer_text TEXT, -- For text-based answers
    selected_option_id UUID, -- For single choice (references question_options.id)
    selected_options UUID[], -- For multiple choice
    
    -- Grading
    is_correct BOOLEAN,
    points_earned NUMERIC(5,2) DEFAULT 0,
    time_spent_seconds INTEGER,
    
    -- Metadata
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Unique constraint to prevent duplicate answers for same question in same attempt
ALTER TABLE user_answers 
ADD CONSTRAINT user_answers_attempt_question_unique 
UNIQUE (attempt_id, question_id);

CREATE INDEX idx_user_answers_attempt_id ON user_answers(attempt_id);
CREATE INDEX idx_user_answers_question_id ON user_answers(question_id);
CREATE INDEX idx_user_answers_user_id ON user_answers(user_id);

-- ============================================================================
-- ANALYTICS AND METADATA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise Analytics Table
-- ----------------------------------------------------------------------------
CREATE TABLE exercise_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Daily statistics
    total_attempts INTEGER DEFAULT 0,
    completed_attempts INTEGER DEFAULT 0,
    average_score NUMERIC(5,2),
    average_completion_time INTEGER, -- seconds
    pass_rate NUMERIC(5,2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(exercise_id, date)
);

CREATE INDEX idx_exercise_analytics_exercise_id ON exercise_analytics(exercise_id);
CREATE INDEX idx_exercise_analytics_date ON exercise_analytics(date);

-- ----------------------------------------------------------------------------
-- Exercise Tags Table
-- ----------------------------------------------------------------------------
CREATE TABLE exercise_tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- Exercise Tag Mapping Table
-- ----------------------------------------------------------------------------
CREATE TABLE exercise_tag_mapping (
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES exercise_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (exercise_id, tag_id)
);

CREATE INDEX idx_exercise_tag_mapping_tag_id ON exercise_tag_mapping(tag_id);

-- ============================================================================
-- QUESTION BANK (Reusable Questions)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question Bank Table
-- ----------------------------------------------------------------------------
CREATE TABLE question_bank (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200),
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('listening', 'reading', 'writing', 'speaking')),
    question_type VARCHAR(50) NOT NULL,
    difficulty VARCHAR(20),
    topic VARCHAR(100),
    
    -- Content
    question_text TEXT NOT NULL,
    context_text TEXT,
    audio_url TEXT,
    image_url TEXT,
    answer_data JSONB, -- Flexible answer storage
    
    -- Metadata
    tags TEXT[],
    times_used INTEGER DEFAULT 0,
    created_by UUID,
    is_verified BOOLEAN DEFAULT false,
    is_published BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_question_bank_skill_type ON question_bank(skill_type);
CREATE INDEX idx_question_bank_question_type ON question_bank(question_type);
CREATE INDEX idx_question_bank_difficulty ON question_bank(difficulty);
CREATE INDEX idx_question_bank_tags ON question_bank USING gin(tags);

-- ============================================================================
-- MIGRATION TRACKING
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Migration Audit Table
-- ----------------------------------------------------------------------------
CREATE TABLE migration_audit (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Auto-update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Update exercise statistics when attempt is completed
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_exercise_statistics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Update exercise stats
        UPDATE exercises
        SET total_attempts = total_attempts + 1,
            average_score = (
                SELECT AVG(score)
                FROM user_exercise_attempts
                WHERE exercise_id = NEW.exercise_id AND status = 'completed'
            ),
            average_completion_time = (
                SELECT AVG(time_spent_seconds) / 60
                FROM user_exercise_attempts
                WHERE exercise_id = NEW.exercise_id AND status = 'completed'
            )
        WHERE id = NEW.exercise_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercise_sections_updated_at
    BEFORE UPDATE ON exercise_sections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_exercise_attempts_updated_at
    BEFORE UPDATE ON user_exercise_attempts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_exercise_statistics
    AFTER UPDATE ON user_exercise_attempts
    FOR EACH ROW EXECUTE FUNCTION update_exercise_statistics();

CREATE TRIGGER update_user_answers_updated_at
    BEFORE UPDATE ON user_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Auto-grade answer function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_grade_answer(p_question_id UUID, p_selected_option_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_correct BOOLEAN;
BEGIN
    SELECT is_correct INTO v_is_correct
    FROM question_options
    WHERE id = p_selected_option_id AND question_id = p_question_id;
    
    RETURN COALESCE(v_is_correct, false);
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Calculate band score function
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_band_score(
    skill VARCHAR(20),
    correct_answers INTEGER,
    total_questions INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
    accuracy NUMERIC;
BEGIN
    IF total_questions = 0 THEN
        RETURN 0;
    END IF;
    
    accuracy := (correct_answers::NUMERIC / total_questions::NUMERIC);
    
    -- Simplified band score calculation
    -- Real IELTS band calculation is more complex
    IF accuracy >= 0.89 THEN RETURN 9.0;
    ELSIF accuracy >= 0.80 THEN RETURN 8.0;
    ELSIF accuracy >= 0.71 THEN RETURN 7.0;
    ELSIF accuracy >= 0.62 THEN RETURN 6.0;
    ELSIF accuracy >= 0.53 THEN RETURN 5.0;
    ELSIF accuracy >= 0.44 THEN RETURN 4.0;
    ELSIF accuracy >= 0.35 THEN RETURN 3.0;
    ELSIF accuracy >= 0.26 THEN RETURN 2.0;
    ELSE RETURN 1.0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Common exercise tags
INSERT INTO exercise_tags (name, slug) VALUES
    ('Cambridge IELTS', 'cambridge-ielts'),
    ('Mock Test', 'mock-test'),
    ('Practice Test', 'practice-test'),
    ('Beginner Friendly', 'beginner-friendly'),
    ('Advanced Level', 'advanced-level'),
    ('Academic', 'academic'),
    ('General Training', 'general-training'),
    ('Map Diagram', 'map-diagram'),
    ('Multiple Choice', 'multiple-choice'),
    ('True/False/Not Given', 'true-false-not-given'),
    ('Matching Headings', 'matching-headings'),
    ('Sentence Completion', 'sentence-completion');

-- ============================================================================
-- SCHEMA MIGRATIONS TRACKING
-- ============================================================================

CREATE TABLE schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schema_migrations (version) VALUES ('001_initial_schema');

-- ============================================================================
-- END OF EXERCISE SERVICE SCHEMA
-- ============================================================================
