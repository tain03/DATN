-- ============================================
-- AI_DB - EVALUATION CACHE (NEW SCHEMA)
-- ============================================
-- Purpose: Seed AI evaluation cache for performance optimization
-- Database: ai_db
-- Date: 2025-11-07
-- 
-- NEW ARCHITECTURE:
-- - AI service is stateless - only stores evaluation cache
-- - No prompts, no submissions (those are in exercise_db)
-- - Cache keyed by content_hash to avoid re-evaluating same content
-- ============================================

-- Skip if table doesn't exist (schema might not be applied yet)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_evaluation_cache') THEN
        RAISE NOTICE 'âš ï¸  Table ai_evaluation_cache does not exist. Skipping AI cache seeding.';
        RAISE NOTICE '   Run database/schemas/05_ai_service.sql first to create tables.';
        RAISE NOTICE '====================================================';
        RETURN;
    END IF;
    
    RAISE NOTICE 'âœ“ Table ai_evaluation_cache exists. Proceeding with seed data...';
    
-- ============================================
-- AI EVALUATION CACHE - Writing Samples
-- ============================================

INSERT INTO ai_evaluation_cache (
    content_hash, skill_type, task_type,
    overall_band_score, detailed_scores, feedback,
    ai_model_name, processing_time_ms, confidence_score,
    prompt_tokens, completion_tokens, total_cost_usd,
    hit_count, last_hit_at, created_at
) VALUES
-- High-quality writing (Band 7.5)
(
    encode(sha256('online_education_essay_sample_1'::bytea), 'hex'),
    'writing',
    'task2',
    7.5,
    '{"task_response": 8.0, "coherence_cohesion": 7.5, "lexical_resource": 7.5, "grammatical_range": 7.0}'::jsonb,
    '{
        "overall": "Excellent essay with clear position and well-developed arguments. Strong coherence and cohesion throughout.",
        "strengths": ["Clear thesis statement", "Well-organized paragraphs", "Good range of vocabulary", "Effective use of linking devices"],
        "weaknesses": ["Some minor grammatical errors", "Could use more sophisticated vocabulary"],
        "suggestions": ["To achieve Band 8.0+, use more complex sentence structures", "Include more specific examples from personal experience"]
    }'::jsonb,
    'gpt-4',
    3500,
    0.92,
    450,
    280,
    0.035,
    3,
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '5 days'
),

-- Medium writing (Band 6.0)
(
    encode(sha256('technology_children_essay_sample_1'::bytea), 'hex'),
    'writing',
    'task2',
    6.0,
    '{"task_response": 6.0, "coherence_cohesion": 6.0, "lexical_resource": 5.5, "grammatical_range": 6.0}'::jsonb,
    '{
        "overall": "Essay addresses the task with a clear position but needs more development.",
        "strengths": ["Clear structure", "Relevant ideas presented"],
        "weaknesses": ["Limited vocabulary range", "Some repetition", "Ideas not fully developed"],
        "suggestions": ["Use more varied vocabulary", "Develop each paragraph with specific examples", "Avoid repeating the same words"]
    }'::jsonb,
    'gpt-4',
    2800,
    0.88,
    380,
    220,
    0.028,
    1,
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '3 days'
),

-- Task 1 - Line Graph (Band 7.0)
(
    encode(sha256('global_temperature_graph_description_1'::bytea), 'hex'),
    'writing',
    'task1',
    7.0,
    '{"task_achievement": 7.0, "coherence_cohesion": 7.0, "lexical_resource": 7.5, "grammatical_range": 7.0}'::jsonb,
    '{
        "overall": "Good description of trends with accurate data reporting.",
        "strengths": ["Clear overview statement", "Accurate data reporting", "Good use of comparative language"],
        "weaknesses": ["Could include more detailed comparisons", "Some minor grammatical errors"],
        "suggestions": ["Practice using more varied sentence structures", "Include more specific data points"]
    }'::jsonb,
    'gpt-4',
    2500,
    0.90,
    320,
    180,
    0.022,
    2,
    NOW() - INTERVAL '3 hours',
    NOW() - INTERVAL '4 days'
);

-- ============================================
-- AI EVALUATION CACHE - Speaking Samples
-- ============================================

INSERT INTO ai_evaluation_cache (
    content_hash, skill_type, task_type,
    overall_band_score, detailed_scores, feedback,
    ai_model_name, processing_time_ms, confidence_score,
    prompt_tokens, completion_tokens, total_cost_usd,
    hit_count, last_hit_at, created_at
) VALUES
-- High-quality speaking (Band 7.0)
(
    encode(sha256('describe_person_part2_sample_1'::bytea), 'hex'),
    'speaking',
    'part2',
    7.0,
    '{"fluency_coherence": 7.0, "lexical_resource": 7.5, "grammatical_range": 7.0, "pronunciation": 6.5}'::jsonb,
    '{
        "overall": "Excellent response with clear structure and detailed development.",
        "strengths": ["Speaks fluently with minimal hesitation", "Good range of vocabulary", "Well-organized response covering all bullet points"],
        "weaknesses": ["Some pronunciation issues with certain words", "Could use more idiomatic expressions"],
        "suggestions": ["Practice pronunciation of difficult words", "Learn more common idiomatic expressions", "Work on word stress and intonation"]
    }'::jsonb,
    'gpt-4',
    4200,
    0.89,
    520,
    320,
    0.042,
    1,
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '4 days'
),

-- Medium speaking (Band 5.5)
(
    encode(sha256('describe_place_part2_sample_1'::bytea), 'hex'),
    'speaking',
    'part2',
    5.5,
    '{"fluency_coherence": 5.5, "lexical_resource": 5.0, "grammatical_range": 5.5, "pronunciation": 6.0}'::jsonb,
    '{
        "overall": "Response covers the points but lacks detail and uses basic vocabulary.",
        "strengths": ["Clear pronunciation", "Covers all bullet points"],
        "weaknesses": ["Limited vocabulary range", "Basic sentence structures", "Some hesitation and repetition"],
        "suggestions": ["Expand vocabulary for describing places", "Practice speaking for longer without hesitation", "Use more complex sentence structures", "Add more specific details and examples"]
    }'::jsonb,
    'gpt-4',
    3100,
    0.85,
    420,
    240,
    0.032,
    0,
    NULL,
    NOW() - INTERVAL '2 days'
),

-- Part 1 response (Band 6.5)
(
    encode(sha256('hometown_family_part1_sample_1'::bytea), 'hex'),
    'speaking',
    'part1',
    6.5,
    '{"fluency_coherence": 6.5, "lexical_resource": 6.5, "grammatical_range": 6.5, "pronunciation": 6.5}'::jsonb,
    '{
        "overall": "Good responses with appropriate detail for Part 1.",
        "strengths": ["Natural and fluent delivery", "Appropriate amount of detail", "Good pronunciation"],
        "weaknesses": ["Some simple errors in grammar", "Could use more varied vocabulary"],
        "suggestions": ["Practice using different grammatical structures", "Expand vocabulary for everyday topics"]
    }'::jsonb,
    'gpt-4',
    2200,
    0.87,
    280,
    160,
    0.019,
    4,
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '6 days'
);

END $$;

-- ============================================
-- SUMMARY STATISTICS
-- ============================================
DO $$
DECLARE
    total_cache INT;
    writing_cache INT;
    speaking_cache INT;
    avg_band NUMERIC;
    total_hits INT;
BEGIN
    -- Skip if table doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_evaluation_cache') THEN
        RAISE NOTICE '============================================';
        RAISE NOTICE 'âš ï¸  AI DB Summary: Schema not applied';
        RAISE NOTICE '   No tables found in ai_db';
        RAISE NOTICE '   Run: docker exec -i ielts_postgres psql -U ielts_admin -d ai_db < database/schemas/05_ai_service.sql';
        RAISE NOTICE '============================================';
        RETURN;
    END IF;
    
    SELECT COUNT(*) INTO total_cache FROM ai_evaluation_cache;
    SELECT COUNT(*) INTO writing_cache FROM ai_evaluation_cache WHERE skill_type = 'writing';
    SELECT COUNT(*) INTO speaking_cache FROM ai_evaluation_cache WHERE skill_type = 'speaking';
    SELECT ROUND(AVG(overall_band_score), 1) INTO avg_band FROM ai_evaluation_cache;
    SELECT SUM(hit_count) INTO total_hits FROM ai_evaluation_cache;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'âœ… AI Evaluation Cache Summary:';
    RAISE NOTICE '  Total cached evaluations: %', total_cache;
    RAISE NOTICE '  - Writing evaluations: %', writing_cache;
    RAISE NOTICE '  - Speaking evaluations: %', speaking_cache;
    RAISE NOTICE '  Average band score: %', avg_band;
    RAISE NOTICE '  Total cache hits: % (saved % OpenAI API calls)', total_hits, total_hits;
    RAISE NOTICE '============================================';
END $$;
