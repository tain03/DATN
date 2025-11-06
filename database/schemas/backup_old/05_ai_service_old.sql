-- ============================================
-- AI Service Database Schema (MINIMAL - Pure Evaluation Engine)
-- ============================================
-- Database: ai_db
-- Purpose: STATELESS AI evaluation service - ONLY for grading Writing & Speaking
--          NO submissions, NO prompts, NO user data
-- Version: 2.0 (Refactored)
-- Last Updated: 2025-11-07
--
-- ARCHITECTURE PRINCIPLE:
-- AI Service is a PURE EVALUATION ENGINE that:
-- ✅ ONLY evaluates content when called by Exercise Service
-- ✅ ONLY caches results to reduce OpenAI API costs
-- ✅ Does NOT store submissions (Exercise Service does that)
-- ✅ Does NOT store prompts (Exercise Service does that)
-- ✅ Does NOT integrate with other services
--
-- Create database (run separately)
-- CREATE DATABASE ai_db;

-- ============================================
-- EXTENSIONS
-- ============================================

-- Enable UUID extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- AI_EVALUATION_CACHE TABLE
-- ============================================
-- Cache AI evaluation results to reduce API costs and improve speed
-- If same content submitted again, return cached result
CREATE TABLE ai_evaluation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Cache key
    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash of submission content
    
    -- Submission info
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),
    task_type VARCHAR(20), -- 'task1', 'task2', 'part1', 'part2', 'part3'
    
    -- Evaluation results
    overall_band_score NUMERIC(3,1) NOT NULL CHECK (overall_band_score >= 0 AND overall_band_score <= 9),
    detailed_scores JSONB NOT NULL, -- Score breakdown by criteria
    feedback JSONB NOT NULL, -- Detailed feedback
    
    -- AI model info
    ai_model_name VARCHAR(100),
    ai_model_version VARCHAR(50),
    
    -- Performance metrics
    processing_time_ms INT,
    confidence_score NUMERIC(3,2), -- 0.00 to 1.00
    
    -- API usage tracking
    prompt_tokens INT,
    completion_tokens INT,
    total_cost_usd NUMERIC(10,6),
    
    -- Cache management
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- NULL = never expires
    hit_count INT DEFAULT 0, -- Number of cache hits
    last_hit_at TIMESTAMP,
    
    notes TEXT -- Optional notes about this cache entry
);

-- Indexes
CREATE INDEX idx_ai_cache_content_hash ON ai_evaluation_cache(content_hash);
CREATE INDEX idx_ai_cache_skill_type ON ai_evaluation_cache(skill_type);
CREATE INDEX idx_ai_cache_expires_at ON ai_evaluation_cache(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_ai_cache_hit_count ON ai_evaluation_cache(hit_count DESC);

-- ============================================
-- PROCESSING QUEUE TABLES
-- ============================================

-- ============================================
-- AI_PROCESSING_QUEUE TABLE
-- ============================================
-- Queue for async AI evaluation tasks
-- Used when evaluation takes longer than request timeout
CREATE TABLE ai_processing_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Task info
    task_type VARCHAR(50) NOT NULL, -- 'writing_evaluation', 'speaking_evaluation'
    submission_id UUID NOT NULL, -- Reference to writing_submission or speaking_submission
    submission_type VARCHAR(20) NOT NULL, -- 'writing' or 'speaking'
    
    -- Queue management
    priority INT DEFAULT 5, -- 1 (highest) to 10 (lowest)
    status VARCHAR(20) DEFAULT 'queued', -- 'queued', 'processing', 'completed', 'failed'
    
    -- Retry logic
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    error_message TEXT,
    
    -- Worker info
    worker_id VARCHAR(100), -- ID of worker processing this task
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_ai_processing_queue_status ON ai_processing_queue(status);
CREATE INDEX idx_ai_processing_queue_priority ON ai_processing_queue(priority DESC, created_at);
CREATE INDEX idx_ai_processing_queue_submission ON ai_processing_queue(submission_id, submission_type);

-- ============================================
-- FEEDBACK & QUALITY TABLES
-- ============================================

-- ============================================
-- EVALUATION_FEEDBACK_RATINGS TABLE
-- ============================================
-- Collect user feedback on AI evaluations
-- Used to improve model accuracy and quality
CREATE TABLE evaluation_feedback_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID NOT NULL, -- User who provided feedback
    
    -- Reference to evaluation
    evaluation_type VARCHAR(20) NOT NULL, -- 'writing' or 'speaking'
    evaluation_id UUID NOT NULL, -- writing_evaluation_id or speaking_evaluation_id
    
    -- Feedback
    is_helpful BOOLEAN, -- Was the feedback helpful?
    accuracy_rating INT CHECK (accuracy_rating BETWEEN 1 AND 5), -- 1-5 stars
    feedback_text TEXT, -- Optional written feedback
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_evaluation_feedback_user_id ON evaluation_feedback_ratings(user_id);
CREATE INDEX idx_evaluation_feedback_evaluation_id ON evaluation_feedback_ratings(evaluation_id);

-- ============================================
-- SYSTEM TABLES
-- ============================================

-- ============================================
-- SCHEMA_MIGRATIONS TABLE
-- ============================================
-- Tracks database migrations that have been applied
-- Used by migration system to prevent re-running migrations
CREATE TABLE schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_file VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) -- Optional: MD5/SHA hash of migration file
);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for tables with updated_at
CREATE TRIGGER update_writing_prompts_updated_at
    BEFORE UPDATE ON writing_prompts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_speaking_prompts_updated_at
    BEFORE UPDATE ON speaking_prompts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_processing_queue_updated_at
    BEFORE UPDATE ON ai_processing_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate IELTS Writing band score
-- Takes 4 criteria scores and returns overall band score
CREATE OR REPLACE FUNCTION calculate_writing_band_score(
    task_achievement NUMERIC,
    coherence_cohesion NUMERIC,
    lexical_resource NUMERIC,
    grammar_accuracy NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND((task_achievement + coherence_cohesion + lexical_resource + grammar_accuracy) / 4, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate IELTS Speaking band score
-- Takes 4 criteria scores and returns overall band score
CREATE OR REPLACE FUNCTION calculate_speaking_band_score(
    fluency_coherence NUMERIC,
    lexical_resource NUMERIC,
    grammar_accuracy NUMERIC,
    pronunciation NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND((fluency_coherence + lexical_resource + grammar_accuracy + pronunciation) / 4, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to create AI processing task automatically
-- Triggered when new submission is created in exercise_db
CREATE OR REPLACE FUNCTION create_ai_processing_task()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'writing_submissions' THEN
        INSERT INTO ai_processing_queue (task_type, submission_id, submission_type)
        VALUES ('evaluate_writing', NEW.id, 'writing');
    ELSIF TG_TABLE_NAME = 'speaking_submissions' THEN
        -- First transcribe audio, then evaluate
        INSERT INTO ai_processing_queue (task_type, submission_id, submission_type, priority)
        VALUES ('transcribe_audio', NEW.id, 'speaking', 8);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Triggers for create_ai_processing_task are in exercise_db
-- They are created on writing_submissions and speaking_submissions tables

-- ============================================
-- SEED DATA (Optional)
-- ============================================

-- Insert default AI models
INSERT INTO ai_model_versions (model_type, model_name, version, description, is_default) VALUES
('writing_evaluator', 'gpt-4', '1.0', 'OpenAI GPT-4 for writing evaluation', true),
('speaking_evaluator', 'gpt-4', '1.0', 'OpenAI GPT-4 for speaking evaluation', true);

-- Insert sample grading criteria (Task Achievement for Writing Task 2)
INSERT INTO grading_criteria (skill_type, criterion_name, band_score, description, key_features) VALUES
('writing', 'Task Achievement', 9.0, 'Fully addresses all parts of the task', 
 ARRAY['fully addresses the task', 'presents a fully developed position', 'ideas are highly relevant']),
('writing', 'Task Achievement', 8.0, 'Sufficiently addresses all parts of the task',
 ARRAY['sufficiently addresses the task', 'presents a well-developed response', 'ideas are mostly relevant']),
('writing', 'Task Achievement', 7.0, 'Addresses all parts of the task',
 ARRAY['addresses all parts', 'presents a clear position', 'main ideas are extended and supported']);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE writing_prompts IS 'Bảng lưu đề bài IELTS Writing (Task 1 & 2)';
COMMENT ON TABLE speaking_prompts IS 'Bảng lưu câu hỏi IELTS Speaking (Part 1, 2, 3)';
COMMENT ON TABLE grading_criteria IS 'Bảng lưu tiêu chí chấm điểm IELTS chính thức';
COMMENT ON TABLE ai_model_versions IS 'Bảng quản lý phiên bản AI models';
COMMENT ON TABLE ai_evaluation_cache IS 'Bảng cache kết quả đánh giá AI để tối ưu chi phí và tốc độ';
COMMENT ON TABLE ai_processing_queue IS 'Hàng đợi xử lý đánh giá AI bất đồng bộ';
COMMENT ON TABLE evaluation_feedback_ratings IS 'Bảng thu thập phản hồi từ người dùng về chất lượng đánh giá AI';

-- Column comments for important fields
COMMENT ON COLUMN ai_evaluation_cache.content_hash IS 'SHA-256 hash của nội dung submission, dùng làm cache key';
COMMENT ON COLUMN ai_evaluation_cache.hit_count IS 'Số lần cache được sử dụng (cost savings metric)';
COMMENT ON COLUMN ai_processing_queue.priority IS 'Độ ưu tiên: 1 (cao nhất) đến 10 (thấp nhất)';
