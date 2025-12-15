-- ============================================-- ============================================

-- AI Service Database Schema (MINIMAL - Pure Evaluation Engine)-- AI Service Database Schema (MINIMAL - Pure Evaluation Engine)

-- ============================================-- ============================================

-- Database: ai_db-- Database: ai_db

-- Purpose: STATELESS AI evaluation service - ONLY for grading Writing & Speaking-- Purpose: STATELESS AI evaluation service - ONLY for grading Writing & Speaking

--          NO submissions, NO prompts, NO user data--          NO submissions, NO prompts, NO user data

-- Version: 2.0 (Refactored)-- Version: 2.0 (Refactored)

-- Last Updated: 2025-01-XX-- Last Updated: 2025-01-XX

----

-- ARCHITECTURE PRINCIPLE:-- ARCHITECTURE PRINCIPLE:

-- AI Service is a PURE EVALUATION ENGINE that:-- AI Service is a PURE EVALUATION ENGINE that:

-- âœ… ONLY evaluates content when called by Exercise Service-- âœ… ONLY evaluates content when called by Exercise Service

-- âœ… ONLY caches results to reduce OpenAI API costs-- âœ… ONLY caches results to reduce OpenAI API costs

-- âœ… Does NOT store submissions (Exercise Service does that)-- âœ… Does NOT store submissions (Exercise Service does that)

-- âœ… Does NOT store prompts (Exercise Service does that)-- âœ… Does NOT store prompts (Exercise Service does that)

-- âœ… Does NOT integrate with other services-- âœ… Does NOT integrate with other services

----

-- EXPOSED APIs (3 only):-- EXPOSED APIs (3 only):

-- POST /ai/internal/writing/evaluate - Evaluate writing submission-- POST /ai/internal/writing/evaluate - Evaluate writing submission

-- POST /ai/internal/speaking/transcribe - Transcribe audio to text-- POST /ai/internal/speaking/transcribe - Transcribe audio to text

-- POST /ai/internal/speaking/evaluate - Evaluate speaking submission-- POST /ai/internal/speaking/evaluate - Evaluate speaking submission

----

-- Create database (run separately)-- Create database (run separately)

-- CREATE DATABASE ai_db;-- CREATE DATABASE ai_db;



-- ============================================-- ============================================

-- EXTENSIONS-- EXTENSIONS

-- ============================================-- ============================================



-- Enable UUID extension for UUID generation-- Enable UUID extension for UUID generation

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";CREATE EXTENSION IF NOT EXISTS "uuid-ossp";



-- ============================================-- ============================================

-- CACHE TABLE (Performance Optimization)-- CACHE TABLE (Performance Optimization)

-- ============================================-- ============================================



-- ============================================-- ============================================

-- AI_EVALUATION_CACHE TABLE-- AI_EVALUATION_CACHE TABLE

-- ============================================-- ============================================

-- Cache AI evaluation results to reduce API costs and improve speed-- Cache AI evaluation results to reduce API costs and improve speed

-- If same content submitted again, return cached result instantly-- If same content submitted again, return cached result instantly

CREATE TABLE ai_evaluation_cache (CREATE TABLE ai_evaluation_cache (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

        

    -- Cache key (hash of submission content)    -- Cache key (hash of submission content)

    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash    content_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hash

        

    -- Submission metadata    -- Submission metadata

    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),

    task_type VARCHAR(20), -- 'task1', 'task2', 'part1', 'part2', 'part3'    task_type VARCHAR(20), -- 'task1', 'task2', 'part1', 'part2', 'part3'

        

    -- Cached evaluation results    -- Cached evaluation results

    overall_band_score NUMERIC(3,1) NOT NULL CHECK (overall_band_score >= 0 AND overall_band_score <= 9),    overall_band_score NUMERIC(3,1) NOT NULL CHECK (overall_band_score >= 0 AND overall_band_score <= 9),

    detailed_scores JSONB NOT NULL, -- Score breakdown by IELTS criteria    detailed_scores JSONB NOT NULL, -- Score breakdown by IELTS criteria

    feedback JSONB NOT NULL, -- Detailed feedback for each criterion    feedback JSONB NOT NULL, -- Detailed feedback for each criterion

        

    -- AI model info (for debugging/tracking)    -- AI model info (for debugging/tracking)

    ai_model_name VARCHAR(100), -- 'gpt-4', 'gpt-4-turbo', etc.    ai_model_name VARCHAR(100), -- 'gpt-4', 'gpt-4-turbo', etc.

    ai_model_version VARCHAR(50),    ai_model_version VARCHAR(50),

        

    -- Performance metrics    -- Performance metrics

    processing_time_ms INT,    processing_time_ms INT,

    confidence_score NUMERIC(3,2), -- AI confidence (0.00 to 1.00)    confidence_score NUMERIC(3,2), -- AI confidence (0.00 to 1.00)

        

    -- API usage tracking (cost optimization)    -- API usage tracking (cost optimization)

    prompt_tokens INT,    prompt_tokens INT,

    completion_tokens INT,    completion_tokens INT,

    total_cost_usd NUMERIC(10,6),    total_cost_usd NUMERIC(10,6),

        

    -- Cache management    -- Cache management

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    expires_at TIMESTAMP, -- NULL = never expires    expires_at TIMESTAMP, -- NULL = never expires

    hit_count INT DEFAULT 0, -- How many times cache was reused    hit_count INT DEFAULT 0, -- How many times cache was reused

    last_hit_at TIMESTAMP,    last_hit_at TIMESTAMP,

        

    -- Optional metadata    -- Optional metadata

    notes TEXT    notes TEXT

););



-- Indexes for fast cache lookups-- Indexes for fast cache lookups

CREATE INDEX idx_ai_cache_content_hash ON ai_evaluation_cache(content_hash);CREATE INDEX idx_ai_cache_content_hash ON ai_evaluation_cache(content_hash);

CREATE INDEX idx_ai_cache_skill_type ON ai_evaluation_cache(skill_type);CREATE INDEX idx_ai_cache_skill_type ON ai_evaluation_cache(skill_type);

CREATE INDEX idx_ai_cache_expires_at ON ai_evaluation_cache(expires_at) WHERE expires_at IS NOT NULL;CREATE INDEX idx_ai_cache_expires_at ON ai_evaluation_cache(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX idx_ai_cache_hit_count ON ai_evaluation_cache(hit_count DESC);CREATE INDEX idx_ai_cache_hit_count ON ai_evaluation_cache(hit_count DESC);

CREATE INDEX idx_ai_cache_created_at ON ai_evaluation_cache(created_at DESC);CREATE INDEX idx_ai_cache_created_at ON ai_evaluation_cache(created_at DESC);



-- ============================================-- ============================================

-- MIGRATIONS TABLE (Schema Version Control)-- MIGRATIONS TABLE (Schema Version Control)

-- ============================================-- ============================================



-- ============================================-- ============================================

-- SCHEMA_MIGRATIONS TABLE-- SCHEMA_MIGRATIONS TABLE

-- ============================================-- ============================================

-- Tracks database migrations that have been applied-- Tracks database migrations that have been applied

-- Prevents re-running same migration multiple times-- Prevents re-running same migration multiple times

CREATE TABLE schema_migrations (CREATE TABLE schema_migrations (

    id SERIAL PRIMARY KEY,    id SERIAL PRIMARY KEY,

    migration_file VARCHAR(255) UNIQUE NOT NULL,    migration_file VARCHAR(255) UNIQUE NOT NULL,

    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    checksum VARCHAR(64) -- MD5/SHA hash of migration file    checksum VARCHAR(64) -- MD5/SHA hash of migration file

););



-- ============================================-- ============================================

-- OPTIONAL: Evaluation Logs (for monitoring)-- OPTIONAL: Evaluation Logs (for monitoring)

-- ============================================-- ============================================



-- ============================================-- ============================================

-- AI_EVALUATION_LOGS TABLE (Optional)-- AI_EVALUATION_LOGS TABLE (Optional)

-- ============================================-- ============================================

-- Keep lightweight logs of all evaluations for monitoring-- Keep lightweight logs of all evaluations for monitoring

-- Useful for debugging, analytics, and cost tracking-- Useful for debugging, analytics, and cost tracking

-- Can be disabled in production if not needed-- Can be disabled in production if not needed

CREATE TABLE ai_evaluation_logs (CREATE TABLE ai_evaluation_logs (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

        

    -- Request info    -- Request info

    skill_type VARCHAR(20) NOT NULL,    skill_type VARCHAR(20) NOT NULL,

    task_type VARCHAR(20),    task_type VARCHAR(20),

    content_hash VARCHAR(64), -- For cache hit tracking    content_hash VARCHAR(64), -- For cache hit tracking

    cache_hit BOOLEAN DEFAULT false,    cache_hit BOOLEAN DEFAULT false,

        

    -- Response info    -- Response info

    band_score NUMERIC(3,1),    band_score NUMERIC(3,1),

    processing_time_ms INT,    processing_time_ms INT,

        

    -- Cost tracking    -- Cost tracking

    prompt_tokens INT,    prompt_tokens INT,

    completion_tokens INT,    completion_tokens INT,

    cost_usd NUMERIC(10,6),    cost_usd NUMERIC(10,6),

        

    -- Error tracking    -- Error tracking

    success BOOLEAN DEFAULT true,    success BOOLEAN DEFAULT true,

    error_message TEXT,    error_message TEXT,

        

    -- Metadata    -- Metadata

    ai_model_name VARCHAR(100),    ai_model_name VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

););



-- Indexes for log queries-- Indexes for log queries

CREATE INDEX idx_ai_logs_skill_type ON ai_evaluation_logs(skill_type);CREATE INDEX idx_ai_logs_skill_type ON ai_evaluation_logs(skill_type);

CREATE INDEX idx_ai_logs_created_at ON ai_evaluation_logs(created_at DESC);CREATE INDEX idx_ai_logs_created_at ON ai_evaluation_logs(created_at DESC);

CREATE INDEX idx_ai_logs_cache_hit ON ai_evaluation_logs(cache_hit);CREATE INDEX idx_ai_logs_cache_hit ON ai_evaluation_logs(cache_hit);

CREATE INDEX idx_ai_logs_success ON ai_evaluation_logs(success) WHERE success = false;CREATE INDEX idx_ai_logs_success ON ai_evaluation_logs(success) WHERE success = false;



-- ============================================-- ============================================

-- HELPER FUNCTIONS-- HELPER FUNCTIONS

-- ============================================-- ============================================



-- Function to calculate IELTS Writing overall band score-- Function to calculate IELTS Writing overall band score

-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)

CREATE OR REPLACE FUNCTION calculate_writing_band_score(CREATE OR REPLACE FUNCTION calculate_writing_band_score(

    task_achievement NUMERIC,    task_achievement NUMERIC,

    coherence_cohesion NUMERIC,    coherence_cohesion NUMERIC,

    lexical_resource NUMERIC,    lexical_resource NUMERIC,

    grammar_accuracy NUMERIC    grammar_accuracy NUMERIC

))

RETURNS NUMERIC AS $$RETURNS NUMERIC AS $$

DECLAREDECLARE

    average NUMERIC;    average NUMERIC;

BEGINBEGIN

    average := (task_achievement + coherence_cohesion + lexical_resource + grammar_accuracy) / 4.0;    average := (task_achievement + coherence_cohesion + lexical_resource + grammar_accuracy) / 4.0;

    -- Round to nearest 0.5    -- Round to nearest 0.5

    RETURN ROUND(average * 2) / 2;    RETURN ROUND(average * 2) / 2;

END;END;

$$ LANGUAGE plpgsql;$$ LANGUAGE plpgsql;



-- Function to calculate IELTS Speaking overall band score-- Function to calculate IELTS Speaking overall band score

-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)-- Takes 4 criteria scores, returns overall band (average rounded to 0.5)

CREATE OR REPLACE FUNCTION calculate_speaking_band_score(CREATE OR REPLACE FUNCTION calculate_speaking_band_score(

    fluency_coherence NUMERIC,    fluency_coherence NUMERIC,

    lexical_resource NUMERIC,    lexical_resource NUMERIC,

    grammar_accuracy NUMERIC,    grammar_accuracy NUMERIC,

    pronunciation NUMERIC    pronunciation NUMERIC

))

RETURNS NUMERIC AS $$RETURNS NUMERIC AS $$

DECLAREDECLARE

    average NUMERIC;    average NUMERIC;

BEGINBEGIN

    average := (fluency_coherence + lexical_resource + grammar_accuracy + pronunciation) / 4.0;    average := (fluency_coherence + lexical_resource + grammar_accuracy + pronunciation) / 4.0;

    -- Round to nearest 0.5    -- Round to nearest 0.5

    RETURN ROUND(average * 2) / 2;    RETURN ROUND(average * 2) / 2;

END;END;

$$ LANGUAGE plpgsql;$$ LANGUAGE plpgsql;



-- Function to clean up expired cache entries-- Function to clean up expired cache entries

-- Run periodically to free up disk space-- Run periodically to free up disk space

CREATE OR REPLACE FUNCTION cleanup_expired_cache()CREATE OR REPLACE FUNCTION cleanup_expired_cache()

RETURNS INT AS $$RETURNS INT AS $$

DECLAREDECLARE

    deleted_count INT;    deleted_count INT;

BEGINBEGIN

    DELETE FROM ai_evaluation_cache    DELETE FROM ai_evaluation_cache

    WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;    WHERE expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP;

        

    GET DIAGNOSTICS deleted_count = ROW_COUNT;    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;    RETURN deleted_count;

END;END;

$$ LANGUAGE plpgsql;$$ LANGUAGE plpgsql;



-- ============================================-- ============================================

-- COMMENTS (Documentation)-- COMMENTS (Documentation)

-- ============================================-- ============================================



COMMENT ON DATABASE ai_db IS 'AI Service Database - Minimal stateless evaluation engine';COMMENT ON DATABASE ai_db IS 'AI Service Database - Minimal stateless evaluation engine';

COMMENT ON TABLE ai_evaluation_cache IS 'Cache káº¿t quáº£ Ä‘Ã¡nh giÃ¡ AI Ä‘á»ƒ giáº£m chi phÃ­ API vÃ  tÄƒng tá»‘c Ä‘á»™';COMMENT ON TABLE ai_evaluation_cache IS 'Cache káº¿t quáº£ Ä‘Ã¡nh giÃ¡ AI Ä‘á»ƒ giáº£m chi phÃ­ API vÃ  tÄƒng tá»‘c Ä‘á»™';

COMMENT ON TABLE ai_evaluation_logs IS 'Logs Ä‘Ã¡nh giÃ¡ AI cho monitoring vÃ  analytics (optional)';COMMENT ON TABLE ai_evaluation_logs IS 'Logs Ä‘Ã¡nh giÃ¡ AI cho monitoring vÃ  analytics (optional)';

COMMENT ON TABLE schema_migrations IS 'Tracking migrations Ä‘Ã£ cháº¡y';COMMENT ON TABLE schema_migrations IS 'Tracking migrations Ä‘Ã£ cháº¡y';



COMMENT ON COLUMN ai_evaluation_cache.content_hash IS 'SHA-256 hash cá»§a ná»™i dung submission, dÃ¹ng lÃ m cache key';COMMENT ON COLUMN ai_evaluation_cache.content_hash IS 'SHA-256 hash cá»§a ná»™i dung submission, dÃ¹ng lÃ m cache key';

COMMENT ON COLUMN ai_evaluation_cache.hit_count IS 'Sá»‘ láº§n cache Ä‘Æ°á»£c sá»­ dá»¥ng (cost savings metric)';COMMENT ON COLUMN ai_evaluation_cache.hit_count IS 'Sá»‘ láº§n cache Ä‘Æ°á»£c sá»­ dá»¥ng (cost savings metric)';

COMMENT ON COLUMN ai_evaluation_cache.expires_at IS 'Thá»i Ä‘iá»ƒm cache háº¿t háº¡n, NULL = khÃ´ng háº¿t háº¡n';COMMENT ON COLUMN ai_evaluation_cache.expires_at IS 'Thá»i Ä‘iá»ƒm cache háº¿t háº¡n, NULL = khÃ´ng háº¿t háº¡n';



-- ============================================-- ============================================

-- END OF SCHEMA-- END OF SCHEMA

-- ============================================-- ============================================

