-- ============================================
-- AI Service Database Schema (MINIMAL - Pure Evaluation Engine)
-- ============================================
-- Database: ai_db
-- Purpose: STATELESS AI evaluation service - ONLY for grading Writing & Speaking
--          NO submissions, NO prompts, NO user data
-- Version: 2.0 (Refactored)
-- Last Updated: 2025-01-XX
--
-- ARCHITECTURE PRINCIPLE:
-- AI Service is a PURE EVALUATION ENGINE that:
-- ✅ ONLY evaluates content when called by Exercise Service
-- ✅ ONLY caches results to reduce OpenAI API costs
-- ✅ Does NOT store submissions (Exercise Service does that)
-- ✅ Does NOT store prompts (Exercise Service does that)
-- ✅ Does NOT integrate with other services
--
-- EXPOSED APIs (3 only):
-- POST /ai/internal/writing/evaluate - Evaluate writing submission
-- POST /ai/internal/speaking/transcribe - Transcribe audio to text
-- POST /ai/internal/speaking/evaluate - Evaluate speaking submission
--
-- Create database (run separately)
-- CREATE DATABASE ai_db;

-- ============================================
-- EXTENSIONS
-- ============================================

-- Enable UUID extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CACHE TABLE (Performance Optimization)
-- ============================================

-- ============================================
-- AI_EVALUATION_CACHE TABLE
-- ============================================
-- Cache AI evaluation results to reduce API costs and improve speed
-- If same content submitted again, return cached result instantly
CREATE TABLE ai_evaluation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Cache key (hash of submission content)
    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash
    
    -- Submission metadata
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),
    task_type VARCHAR(20), -- 'task1', 'task2', 'part1', 'part2', 'part3'
    
    -- Cached evaluation results
    overall_band_score NUMERIC(3,1) NOT NULL CHECK (overall_band_score >= 0 AND overall_band_score <= 9),
    detailed_scores JSONB NOT NULL, -- Score breakdown by IELTS criteria
    feedback JSONB NOT NULL, -- Detailed feedback for each criterion
    
    -- AI model info (for debugging/tracking)
    ai_model_name VARCHAR(100), -- 'gpt-4', 'gpt-4-turbo', etc.
    ai_model_version VARCHAR(50),
    
    -- Performance metrics
    processing_time_ms INT,
    confidence_score NUMERIC(3,2), -- AI confidence (0.00 to 1.00)
    
    -- API usage tracking (cost optimization)
    prompt_tokens INT,
    completion_tokens INT,
    total_cost_usd NUMERIC(10,6),
    
    -- Cache management
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- NULL = never expires
    hit_count INT DEFAULT 0, -- How many times cache was reused
    last_hit_at TIMESTAMP,
    
    -- Optional metadata
    notes TEXT
);

-- Indexes for fast cache lookups
CREATE INDEX idx_ai_cache_content_hash ON ai_evaluation_cache(content_hash);
CREATE INDEX idx_ai_cache_skill_type ON ai_evaluation_cache(skill_type);
CREATE INDEX idx_ai_cache_expires_at ON ai_evaluation_cache(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_ai_cache_hit_count ON ai_evaluation_cache(hit_count DESC);
CREATE INDEX idx_ai_cache_created_at ON ai_evaluation_cache(created_at DESC);

-- ============================================
-- MIGRATIONS TABLE (Schema Version Control)
-- ============================================

-- ============================================
-- SCHEMA_MIGRATIONS TABLE
-- ============================================
-- Tracks database migrations that have been applied
-- Prevents re-running same migration multiple times
CREATE TABLE schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_file VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) -- MD5/SHA hash of migration file
);

-- ============================================
-- OPTIONAL: Evaluation Logs (for monitoring)
-- ============================================

-- ============================================
-- AI_EVALUATION_LOGS TABLE (Optional)
-- ============================================
-- Keep lightweight logs of all evaluations for monitoring
-- Useful for debugging, analytics, and cost tracking
-- Can be disabled in production if not needed
CREATE TABLE ai_evaluation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Request info
    skill_type VARCHAR(20) NOT NULL,
    task_type VARCHAR(20),
    content_hash VARCHAR(64), -- For cache hit tracking
    cache_hit BOOLEAN DEFAULT false,
    
    -- Response info
    band_score NUMERIC(3,1),
    processing_time_ms INT,
    
    -- Cost tracking
    prompt_tokens INT,
    completion_tokens INT,
    cost_usd NUMERIC(10,6),
    
    -- Error tracking
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    
    -- Metadata
    ai_model_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for log queries
CREATE INDEX idx_ai_logs_skill_type ON ai_evaluation_logs(skill_type);
CREATE INDEX idx_ai_logs_created_at ON ai_evaluation_logs(created_at DESC);
CREATE INDEX idx_ai_logs_cache_hit ON ai_evaluation_logs(cache_hit);
CREATE INDEX idx_ai_logs_success ON ai_evaluation_logs(success) WHERE success = false;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to calculate IELTS Writing overall band score
-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)
CREATE OR REPLACE FUNCTION calculate_writing_band_score(
    task_achievement NUMERIC,
    coherence_cohesion NUMERIC,
    lexical_resource NUMERIC,
    grammar_accuracy NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    average NUMERIC;
BEGIN
    average := (task_achievement + coherence_cohesion + lexical_resource + grammar_accuracy) / 4.0;
    -- Round to nearest 0.5
    RETURN ROUND(average * 2) / 2;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate IELTS Speaking overall band score
-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)
CREATE OR REPLACE FUNCTION calculate_speaking_band_score(
    fluency_coherence NUMERIC,
    lexical_resource NUMERIC,
    grammar_accuracy NUMERIC,
    pronunciation NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
    average NUMERIC;
BEGIN
    average := (fluency_coherence + lexical_resource + grammar_accuracy + pronunciation) / 4.0;
    -- Round to nearest 0.5
    RETURN ROUND(average * 2) / 2;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired cache entries
-- Run periodically to free up disk space
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INT AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM ai_evaluation_cache
    WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS (Documentation)
-- ============================================

COMMENT ON DATABASE ai_db IS 'AI Service Database - Minimal stateless evaluation engine';
COMMENT ON TABLE ai_evaluation_cache IS 'Cache kết quả đánh giá AI để giảm chi phí API và tăng tốc độ';
COMMENT ON TABLE ai_evaluation_logs IS 'Logs đánh giá AI cho monitoring và analytics (optional)';
COMMENT ON TABLE schema_migrations IS 'Tracking migrations đã chạy';

COMMENT ON COLUMN ai_evaluation_cache.content_hash IS 'SHA-256 hash của nội dung submission, dùng làm cache key';
COMMENT ON COLUMN ai_evaluation_cache.hit_count IS 'Số lần cache được sử dụng (cost savings metric)';
COMMENT ON COLUMN ai_evaluation_cache.expires_at IS 'Thời điểm cache hết hạn, NULL = không hết hạn';

-- ============================================
-- END OF SCHEMA
-- ============================================
