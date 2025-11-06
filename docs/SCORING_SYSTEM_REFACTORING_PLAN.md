# 📋 SCORING SYSTEM REFACTORING PLAN

**Project**: IELTS Learning Platform Score Management Refactoring  
**Version**: 1.0  
**Date**: November 6, 2025  
**Status**: Planning Phase  

---

## 🎯 EXECUTIVE SUMMARY

### Problem Statement
Current system has fragmented score management across multiple services, leading to:
- Inconsistent score sources (practice drills vs official tests are treated equally)
- Official scores (listening_score, reading_score, etc.) are never updated
- Logic duplication between exercise-service and ai-service
- **Architectural confusion**: Prompts stored in AI Service but should be in Exercise Service
- AI Service has too many responsibilities (prompts + submissions + evaluation)
- Poor user experience (confusing score displays)

### Solution Overview
Implement a centralized architecture where:
1. **Exercise Service** = Single source of truth for ALL exercise content
   - ✅ Manages exercises for all 4 skills (L/R/W/S)
   - ✅ Owns prompts (Writing + Speaking) 
   - ✅ Stores all submissions
   - ✅ Auto-grades L/R, calls AI for W/S
   
2. **AI Service** = Pure stateless evaluation engine
   - ✅ ONLY evaluates essays/speech (no storage)
   - ✅ ONLY called when grading W/S submissions
   - ✅ Caches results to reduce costs
   - ❌ NO prompts, NO submissions, NO integrations
   
3. **User Service** = Progress tracker (receives final results only)
   - ✅ Official test results (from full tests only)
   - ✅ Practice activities (separate tracking)
   - ✅ Accurate overall scores

4. Clear separation: Practice activities vs Official tests

### Key Architectural Changes

#### Content Ownership
```
BEFORE: Prompts in AI Service ❌
AFTER:  Prompts in Exercise Service ✅
```

**Rationale**: 
- Exercise Service owns ALL exercise content (questions, passages, prompts, audio)
- AI Service should NOT be called during exercise creation
- AI Service is a utility/tool, not a content manager

#### Data Migration
```
ai_db.writing_prompts   → exercise_db.writing_prompts
ai_db.speaking_prompts  → exercise_db.speaking_prompts
ai_db.*_submissions     → exercise_db.exercise_submissions (if any)
```

#### AI Service Simplification
```
BEFORE: 8+ tables (prompts, submissions, evaluations, logs...)
AFTER:  4 tables (cache, logs, criteria, model_versions)

BEFORE: 15+ endpoints (prompts, submissions, evaluation, integration...)
AFTER:  4 endpoints (evaluate writing, evaluate speaking, transcribe, health)
```

### Expected Outcomes
- ✅ Accurate official scores from full tests only
- ✅ Clear practice vs test distinction  
- ✅ Centralized score conversion logic
- ✅ **Prompts managed by exercise service (no AI service dependency)**
- ✅ **AI service ONLY called during grading (not during exercise creation)**
- ✅ Better scalability and maintainability
- ✅ 50%+ reduction in OpenAI API costs (caching)
- ✅ Professional IELTS platform experience matching industry standards

---

## 🏗️ ARCHITECTURE OVERVIEW

### Current Architecture (Problems)
```
┌─────────────────┐
│ EXERCISE SERVICE│ → UpdateSkillStats() → USER SERVICE
│ (L/R only)      │   UpdateProgress()
└─────────────────┘

┌─────────────────┐
│  AI SERVICE     │ → UpdateSkillStats() → USER SERVICE
│ (W/S + Storage) │   UpdateProgress()
└─────────────────┘

❌ Scores not updating learning_progress properly
❌ No distinction between practice and official tests
❌ Logic duplicated in 2 services
```

### Target Architecture (Solution)
```
                    ┌─────────────────────────────────┐
                    │       USER SERVICE              │
                    │  - official_test_results        │
                    │  - practice_activities          │
                    │  - Centralized scoring logic    │
                    └─────────────────────────────────┘
                              ▲
                              │ (Only for recording final results)
                              │
                    ┌─────────────────────────────────┐
                    │     EXERCISE SERVICE            │
                    │  (Single Source of Truth)       │
                    │                                 │
                    │  ✅ ALL exercises (4 skills)    │
                    │  ✅ writing_prompts             │
                    │  ✅ speaking_prompts            │
                    │  ✅ questions (L/R)             │
                    │  ✅ ALL submissions (4 skills)  │
                    │  ✅ Grade L/R automatically     │
                    │  ✅ Call AI ONLY when grading   │
                    │  ✅ Call user-service with final│
                    └─────────────────────────────────┘
                              │
                              │ (ONLY when grading W/S submissions)
                              ↓
                    ┌─────────────────────────────────┐
                    │       AI SERVICE                │
                    │  (Pure Evaluation Engine)       │
                    │                                 │
                    │  ✅ EvaluateWriting()           │
                    │  ✅ EvaluateSpeaking()          │
                    │  ✅ TranscribeAudio()           │
                    │  ✅ Evaluation cache            │
                    │  ❌ NO prompts storage          │
                    │  ❌ NO submissions storage      │
                    │  ❌ NO user integration         │
                    └─────────────────────────────────┘

✅ Single source of truth (exercise_service)
✅ Clear separation of concerns
✅ Stateless AI service (can scale independently)
✅ AI service ONLY called when grading (not when creating exercises)
```

---

## � REAL-WORLD WORKFLOW

### Creating Exercises (Admin/Teacher Flow)

#### Creating a Writing Exercise
```
1. Admin opens "Create Exercise" page
2. Selects: Skill = "Writing", Type = "Full Test"
3. Frontend calls: GET /api/v1/prompts/writing?task_type=task2
4. Exercise Service returns list of available writing prompts
5. Admin selects a prompt (e.g., "Education and Technology")
6. Admin sets: time_limit=40min, difficulty=7.0-8.0
7. Frontend calls: POST /api/v1/exercises
   {
     "skill_type": "writing",
     "writing_prompt_id": "uuid",  // Reference to selected prompt
     "exercise_type": "full_test",
     "time_limit_minutes": 40,
     ...
   }
8. Exercise Service creates exercise (no AI service involved)
```

**Key Point**: AI Service is **NOT called** when creating exercises.

#### Creating a Speaking Exercise
```
Similar flow:
1. Admin calls GET /api/v1/prompts/speaking?part_number=2
2. Selects cue card topic
3. Creates exercise with speaking_prompt_id reference
4. No AI service involvement
```

---

### Student Taking Exercise (User Flow)

#### Listening/Reading Exercise (Immediate Grading)
```
1. Student opens exercise → GET /api/v1/exercises/{id}
2. Exercise Service returns exercise with questions
3. Student answers questions
4. Student submits → POST /api/v1/exercises/{id}/submit
   {
     "user_answers": {"1": "A", "2": "C", ...}
   }
5. Exercise Service:
   ✅ Grades immediately (compare with correct_answer)
   ✅ Calculates band score (using shared/pkg/ielts)
   ✅ Saves submission
   ✅ Calls User Service (record test/practice result)
6. Returns result immediately (< 500ms)
```

**Key Point**: No AI service involvement for L/R.

#### Writing Exercise (Async Grading)
```
1. Student opens exercise → GET /api/v1/exercises/{id}
2. Exercise Service returns:
   - Exercise metadata
   - Writing prompt (from writing_prompts table)
   - Task instructions
3. Student writes essay (40 minutes)
4. Student submits → POST /api/v1/exercises/{id}/submit
   {
     "essay_text": "Education is important...",
     "word_count": 285,
     "time_spent_seconds": 2400
   }
5. Exercise Service:
   ✅ Saves submission (status="pending")
   ✅ Returns 202 Accepted immediately
   ✅ Starts async evaluation:
      a. Calls AI Service: POST /api/v1/ai/evaluate/writing
         {
           "essay_text": "...",
           "task_type": "task2",
           "task_prompt": "Some people think...",
           "word_count": 285
         }
      b. AI Service evaluates (5-10 seconds)
      c. AI Service returns band scores + feedback
      d. Exercise Service updates submission (status="completed")
      e. Exercise Service calls User Service (record result)
      f. Exercise Service sends notification
6. Student polls: GET /api/v1/submissions/{id}
   - Returns: status="completed", band_score=7.0, feedback={...}
```

**Key Point**: AI Service is **ONLY called during grading**, not during exercise creation or viewing.

#### Speaking Exercise (Async Transcription + Grading)
```
Similar to Writing, but with two AI calls:
1. POST /api/v1/ai/transcribe/speaking (Whisper API)
2. POST /api/v1/ai/evaluate/speaking (GPT-4 API)
```

---

### When AI Service is Called

✅ **ONLY these scenarios**:
1. Student submits Writing essay → Exercise Service → AI Service (evaluate)
2. Student submits Speaking audio → Exercise Service → AI Service (transcribe + evaluate)

❌ **NEVER called for**:
1. Creating exercises
2. Listing exercises
3. Viewing exercise details
4. Taking Listening/Reading exercises
5. Any user profile operations
6. Any progress tracking

---

### Architecture Comparison: Before vs After

#### BEFORE (Current - Problematic)
```
Create Writing Exercise:
Admin → Exercise Service → ??? (Where are prompts?)

Submit Writing:
Student → AI Service (stores submission) → AI Service (evaluates)
                                        → User Service (records)

Problem: AI Service doing too much
```

#### AFTER (Target - Clean Separation)
```
Create Writing Exercise:
Admin → Exercise Service (has prompts) → Done
      ↓
   No AI involvement

Submit Writing:
Student → Exercise Service (stores submission)
       ↓
       Exercise Service → AI Service (stateless evaluation)
       ↓                  ↓
       User Service ←─────┘
       (records result)

Clean: Each service has one job
```

---

## �📊 DATABASE DESIGN

### 1. User Service (user_db)

#### New Table: official_test_results
```sql
CREATE TABLE official_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id),
    
    -- Classification
    test_type VARCHAR(50) NOT NULL,      -- full_test, mock_test, sectional_test
    skill_type VARCHAR(20) NOT NULL,     -- listening, reading, writing, speaking
    
    -- Source tracking (critical for audit)
    source_service VARCHAR(50) NOT NULL, -- exercise_service
    source_table VARCHAR(50) NOT NULL,   -- exercise_submissions
    source_id UUID NOT NULL,             -- submission_id
    
    -- Raw data (for L/R from exercise_service)
    raw_score INT,                       -- Number of correct answers (0-40)
    total_questions INT,                 -- Total questions (usually 40)
    
    -- AI evaluation data (for W/S from ai_service via exercise_service)
    ai_model_name VARCHAR(100),          -- gpt-4-turbo, etc.
    evaluation_criteria JSONB,           -- {task_achievement: 7.0, ...}
    
    -- Final score (unified for all 4 skills)
    band_score DECIMAL(2,1) NOT NULL,    -- IELTS band 0-9
    
    -- Metadata
    time_spent_minutes INT,
    taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_test_results_user_skill (user_id, skill_type, taken_at DESC),
    INDEX idx_test_results_source (source_service, source_id)
);
```

**Purpose**: Store only official test results that will update user's official scores.

#### New Table: practice_activities
```sql
CREATE TABLE practice_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id),
    
    -- Classification
    activity_type VARCHAR(50) NOT NULL,  -- drill, mini_exercise, practice_question
    skill_type VARCHAR(20) NOT NULL,     -- listening, reading, writing, speaking
    
    -- Source tracking
    source_service VARCHAR(50) NOT NULL, -- exercise_service
    source_table VARCHAR(50) NOT NULL,   -- exercise_submissions
    source_id UUID NOT NULL,             -- submission_id
    
    -- Performance metrics
    score DECIMAL(5,2),                  -- Band score or percentage
    questions_attempted INT,
    questions_correct INT,
    
    -- Time tracking
    time_spent_minutes INT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_practice_user_skill (user_id, skill_type, completed_at DESC),
    INDEX idx_practice_source (source_service, source_id)
);
```

**Purpose**: Track practice activities separately from official tests.

#### Updates to learning_progress
```sql
ALTER TABLE learning_progress 
    ADD COLUMN listening_tests_taken INT DEFAULT 0,
    ADD COLUMN reading_tests_taken INT DEFAULT 0,
    ADD COLUMN writing_tests_taken INT DEFAULT 0,
    ADD COLUMN speaking_tests_taken INT DEFAULT 0,
    ADD COLUMN last_test_date DATE;
```

#### Updates to skill_statistics
```sql
ALTER TABLE skill_statistics 
    ADD COLUMN total_official_tests INT DEFAULT 0,
    ADD COLUMN total_practice_activities INT DEFAULT 0,
    ADD COLUMN best_test_score DECIMAL(2,1),
    ADD COLUMN average_test_score DECIMAL(5,2),
    ADD COLUMN average_practice_score DECIMAL(5,2);

COMMENT ON COLUMN skill_statistics.average_score IS 
    'Legacy field: average of both tests and practices (for backward compatibility)';
```

---

### 2. Exercise Service (exercise_db)

#### New Table: writing_prompts (migrated from ai_db)
```sql
CREATE TABLE writing_prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Task information
    task_type VARCHAR(20) NOT NULL CHECK (task_type IN ('task1', 'task2')),
    prompt_text TEXT NOT NULL,
    
    -- Visual data for Task 1
    visual_type VARCHAR(50), -- 'bar_chart', 'line_graph', 'pie_chart', 'table', 'process_diagram'
    visual_url TEXT,
    
    -- Categorization
    topic VARCHAR(100),
    difficulty VARCHAR(20) CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    
    -- Sample answer (optional)
    has_sample_answer BOOLEAN DEFAULT false,
    sample_answer_text TEXT,
    sample_answer_band_score DECIMAL(2,1),
    
    -- Usage statistics
    times_used INT DEFAULT 0,
    average_score DECIMAL(2,1),
    
    -- Publishing
    is_published BOOLEAN DEFAULT true,
    created_by UUID,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_writing_prompts_task_type ON writing_prompts(task_type);
CREATE INDEX idx_writing_prompts_topic ON writing_prompts(topic);
CREATE INDEX idx_writing_prompts_is_published ON writing_prompts(is_published);
```

#### New Table: speaking_prompts (migrated from ai_db)
```sql
CREATE TABLE speaking_prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Part information
    part_number INT NOT NULL CHECK (part_number IN (1, 2, 3)),
    prompt_text TEXT NOT NULL,
    
    -- Part 2 specific: Cue card
    cue_card_topic VARCHAR(200),
    cue_card_points TEXT[], -- Array of points to cover
    preparation_time_seconds INT DEFAULT 60,
    speaking_time_seconds INT DEFAULT 120,
    
    -- Part 3 specific: Follow-up questions
    follow_up_questions TEXT[],
    
    -- Categorization
    topic_category VARCHAR(100),
    difficulty VARCHAR(20) CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    
    -- Sample answer (optional)
    has_sample_answer BOOLEAN DEFAULT false,
    sample_answer_text TEXT,
    sample_answer_audio_url TEXT,
    sample_answer_band_score DECIMAL(2,1),
    
    -- Usage statistics
    times_used INT DEFAULT 0,
    average_score DECIMAL(2,1),
    
    -- Publishing
    is_published BOOLEAN DEFAULT true,
    created_by UUID,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_speaking_prompts_part_number ON speaking_prompts(part_number);
CREATE INDEX idx_speaking_prompts_topic_category ON speaking_prompts(topic_category);
CREATE INDEX idx_speaking_prompts_is_published ON speaking_prompts(is_published);
```

#### Updates to exercises table
```sql
ALTER TABLE exercises
    -- For Writing exercises (reference to prompt)
    ADD COLUMN writing_prompt_id UUID REFERENCES writing_prompts(id),
    ADD COLUMN writing_task_type VARCHAR(20),     -- task1, task2
    
    -- For Speaking exercises (reference to prompt)
    ADD COLUMN speaking_prompt_id UUID REFERENCES speaking_prompts(id),
    ADD COLUMN speaking_part_number INT,          -- 1, 2, 3
    
    -- Add constraint: skill_type can be listening, reading, writing, speaking
    ADD CONSTRAINT check_skill_type 
        CHECK (skill_type IN ('listening', 'reading', 'writing', 'speaking'));

COMMENT ON COLUMN exercises.skill_type IS 
    'All 4 IELTS skills supported: listening, reading, writing, speaking';

COMMENT ON COLUMN exercises.writing_prompt_id IS 
    'References writing_prompts table. Exercise uses this prompt for content.';

COMMENT ON COLUMN exercises.speaking_prompt_id IS 
    'References speaking_prompts table. Exercise uses this prompt for content.';
```

#### Updates to exercise_submissions table
```sql
ALTER TABLE exercise_submissions
    -- For Writing submissions
    ADD COLUMN essay_text TEXT,
    ADD COLUMN word_count INT,
    
    -- For Speaking submissions
    ADD COLUMN audio_url TEXT,
    ADD COLUMN audio_duration_seconds INT,
    ADD COLUMN transcript_text TEXT,
    
    -- AI Evaluation tracking
    ADD COLUMN evaluation_status VARCHAR(20),     -- pending, processing, completed, failed
    ADD COLUMN ai_evaluation_id UUID,             -- Reference to cache/log
    
    -- Detailed scores (JSONB for flexibility)
    ADD COLUMN detailed_scores JSONB;             -- {task_achievement: 7.0, ...}

COMMENT ON COLUMN exercise_submissions.evaluation_status IS 
    'Tracks AI evaluation progress for Writing/Speaking';

-- Add index for pending evaluations
CREATE INDEX idx_submissions_pending_eval 
    ON exercise_submissions(evaluation_status, created_at) 
    WHERE evaluation_status IN ('pending', 'processing');
```

---

### 3. AI Service (ai_db)

#### New Table: ai_evaluation_cache (for cost optimization)
```sql
CREATE TABLE ai_evaluation_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content identification
    content_hash VARCHAR(64) UNIQUE NOT NULL,  -- SHA256(essay_text or transcript)
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),
    
    -- Evaluation result (cached)
    overall_band_score DECIMAL(2,1) NOT NULL,
    detailed_scores JSONB NOT NULL,            -- Criteria scores
    feedback JSONB NOT NULL,                   -- Structured feedback
    
    -- AI metadata
    ai_model_name VARCHAR(100),
    ai_model_version VARCHAR(50),
    processing_time_ms INT,
    confidence_score DECIMAL(3,2),
    
    -- Cache management
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,                      -- NULL = never expires
    hit_count INT DEFAULT 0,                   -- Track cache usage
    
    INDEX idx_cache_hash (content_hash),
    INDEX idx_cache_expiry (expires_at) WHERE expires_at IS NOT NULL
);

CREATE INDEX idx_ai_cache_skill_created ON ai_evaluation_cache(skill_type, created_at DESC);

COMMENT ON TABLE ai_evaluation_cache IS 
    'Caches AI evaluation results to reduce OpenAI API costs';
```

#### New Table: ai_evaluation_logs (for monitoring)
```sql
CREATE TABLE ai_evaluation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Request info
    skill_type VARCHAR(20) NOT NULL CHECK (skill_type IN ('writing', 'speaking')),
    content_hash VARCHAR(64) NOT NULL,
    cache_hit BOOLEAN DEFAULT false,
    
    -- Performance metrics
    processing_time_ms INT NOT NULL,
    tokens_used INT,
    api_cost_usd DECIMAL(10,6),
    
    -- Model info
    ai_model_name VARCHAR(100),
    ai_model_version VARCHAR(50),
    
    -- Result
    overall_band_score DECIMAL(2,1),
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_logs_created ON ai_evaluation_logs(created_at DESC);
CREATE INDEX idx_ai_logs_cache_hit ON ai_evaluation_logs(cache_hit, created_at DESC);

COMMENT ON TABLE ai_evaluation_logs IS 
    'Logs all AI evaluation requests for monitoring, cost tracking, and debugging';
```

#### KEEP Tables (reference data only)
```sql
-- Keep these for reference/configuration
-- grading_criteria (IELTS band descriptors - reference data)
-- ai_model_versions (model configuration and version tracking)
```

#### REMOVE Tables (migrate to exercise_service)
```sql
-- These tables will be DROPPED after data migration to exercise_service
-- Their data will be moved to exercise_db

DROP TABLE IF EXISTS writing_submissions CASCADE;
DROP TABLE IF EXISTS writing_evaluations CASCADE;
DROP TABLE IF EXISTS speaking_submissions CASCADE;
DROP TABLE IF EXISTS speaking_evaluations CASCADE;
DROP TABLE IF EXISTS writing_prompts CASCADE;       -- → exercise_db.writing_prompts
DROP TABLE IF EXISTS speaking_prompts CASCADE;      -- → exercise_db.speaking_prompts
```

#### Final AI Service Schema (After Refactoring)
```sql
-- AI Service becomes a PURE EVALUATION ENGINE with minimal storage:

ai_db:
├── grading_criteria           -- IELTS band descriptors (reference)
├── ai_model_versions          -- Model configuration
├── ai_evaluation_cache        -- Cache to reduce API costs
└── ai_evaluation_logs         -- Monitoring and audit trail

Total: 4 tables (from 8+ tables before)
Purpose: Pure stateless evaluation with caching and monitoring
```

---

## 🔌 API DESIGN

### User Service - New Internal Endpoints

#### 1. Record Official Test Result
```http
POST /api/v1/user/internal/test-result/record
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "user_id": "uuid",
  "test_type": "full_test",              // full_test, mock_test, sectional_test
  "skill_type": "listening",             // listening, reading, writing, speaking
  
  "source_service": "exercise_service",
  "source_table": "exercise_submissions",
  "source_id": "uuid",
  
  // For Listening/Reading (raw score provided)
  "raw_score": 35,                       // Optional: number of correct answers
  "total_questions": 40,                 // Optional: total questions
  
  // For Writing/Speaking (band already calculated by AI)
  "ai_model_name": "gpt-4-turbo",       // Optional
  "evaluation_criteria": {               // Optional
    "task_achievement": 7.0,
    "coherence_cohesion": 6.5,
    "lexical_resource": 7.0,
    "grammar_accuracy": 7.0
  },
  "band_score": 7.0,                    // Optional: if not provided, calculate from raw_score
  
  "time_spent_minutes": 60
}

Response 200:
{
  "success": true,
  "test_result_id": "uuid",
  "band_score": 7.0,
  "updated_fields": {
    "listening_score": 7.0,
    "overall_score": 7.2,
    "listening_tests_taken": 5
  }
}
```

**Logic**:
1. If `band_score` provided → use it
2. Else if `raw_score` + `total_questions` → calculate using conversion table
3. Save to `official_test_results`
4. Update `learning_progress.{skill}_score` = band_score
5. Update `learning_progress.{skill}_tests_taken` += 1
6. Recalculate `learning_progress.overall_score` (average of 4 skills)
7. Update `skill_statistics` (test counters, best_test_score, average_test_score)
8. Update streak tracking
9. Check and award achievements

#### 2. Record Practice Activity
```http
POST /api/v1/user/internal/practice/record
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "user_id": "uuid",
  "activity_type": "drill",              // drill, mini_exercise, practice_question
  "skill_type": "listening",
  
  "source_service": "exercise_service",
  "source_table": "exercise_submissions",
  "source_id": "uuid",
  
  "score": 7.5,                          // Band score or percentage
  "questions_attempted": 10,             // Optional
  "questions_correct": 8,                // Optional
  
  "time_spent_minutes": 15
}

Response 200:
{
  "success": true,
  "activity_id": "uuid"
}
```

**Logic**:
1. Save to `practice_activities`
2. Update `skill_statistics.total_practice_activities` += 1
3. Update `skill_statistics.average_practice_score`
4. Update `learning_progress.exercises_completed` += 1 (legacy counter)
5. Update streak tracking
6. DO NOT update `learning_progress.{skill}_score` (official score unchanged)

#### 3. Get Test History
```http
GET /api/v1/user/{user_id}/test-history?skill_type=listening&limit=10
X-API-Key: {user_token}

Response 200:
{
  "tests": [
    {
      "id": "uuid",
      "test_type": "full_test",
      "skill_type": "listening",
      "band_score": 7.5,
      "raw_score": 35,
      "total_questions": 40,
      "taken_at": "2025-11-05T10:00:00Z",
      "time_spent_minutes": 60
    }
  ],
  "statistics": {
    "total_tests": 5,
    "average_score": 7.2,
    "best_score": 7.5,
    "latest_score": 7.5,
    "improvement": "+0.5"
  }
}
```

#### 4. Get Practice Summary
```http
GET /api/v1/user/{user_id}/practice-summary?skill_type=listening
X-API-Key: {user_token}

Response 200:
{
  "skill_type": "listening",
  "total_activities": 45,
  "average_score": 6.8,
  "total_time_minutes": 680,
  "recent_activities": [...]
}
```

---

### Exercise Service - Updated Endpoints

#### 1. Submit Exercise (Unified for all 4 skills)
```http
POST /api/v1/exercises/{exercise_id}/submit
Content-Type: application/json
X-API-Key: {user_token}

// For Listening/Reading
{
  "user_answers": {
    "1": "A",
    "2": "C",
    "3": "B"
  },
  "time_spent_seconds": 3600
}

// For Writing
{
  "essay_text": "Education is very important...",
  "word_count": 250,
  "time_spent_seconds": 2400
}

// For Speaking
{
  "audio_url": "s3://bucket/audio.mp3",
  "audio_duration_seconds": 180
}

Response 200 (Listening/Reading - immediate):
{
  "submission_id": "uuid",
  "status": "completed",
  "band_score": 7.5,
  "correct_answers": 35,
  "total_questions": 40,
  "score_percentage": 87.5,
  "detailed_results": [
    {
      "question_number": 1,
      "user_answer": "A",
      "correct_answer": "A",
      "is_correct": true
    }
  ]
}

Response 202 (Writing/Speaking - async):
{
  "submission_id": "uuid",
  "status": "pending",  // or "processing"
  "message": "Your essay is being evaluated. Please check back in a moment.",
  "estimated_wait_seconds": 30
}
```

#### 2. Get Submission Result (Polling for W/S)
```http
GET /api/v1/submissions/{submission_id}
X-API-Key: {user_token}

Response 200 (completed):
{
  "id": "uuid",
  "status": "completed",
  "band_score": 7.0,
  "detailed_scores": {
    "task_achievement": 7.0,
    "coherence_cohesion": 6.5,
    "lexical_resource": 7.0,
    "grammar_accuracy": 7.0
  },
  "feedback": {
    "strengths": [...],
    "weaknesses": [...],
    "suggestions": [...]
  },
  "completed_at": "2025-11-06T10:05:00Z"
}

Response 202 (still processing):
{
  "id": "uuid",
  "status": "processing",
  "message": "Evaluation in progress...",
  "progress_percentage": 50
}

Response 500 (failed):
{
  "id": "uuid",
  "status": "failed",
  "error": "AI service unavailable",
  "message": "Please try again later"
}
```

---

### AI Service - Pure Evaluation APIs

**IMPORTANT**: AI Service is a **stateless evaluation engine**. It:
- ✅ ONLY evaluates content (Writing essays, Speaking transcripts)
- ✅ Returns evaluation results immediately
- ✅ Caches results internally (for cost optimization)
- ❌ NEVER stores submissions
- ❌ NEVER manages prompts
- ❌ NEVER integrates with user-service or other services

**When is AI Service called?**
- ✅ When Exercise Service needs to grade a Writing submission
- ✅ When Exercise Service needs to grade a Speaking submission
- ❌ NOT when creating exercises
- ❌ NOT when listing exercises
- ❌ NOT when users view exercise details

#### 1. Evaluate Writing (Stateless)
```http
POST /api/v1/ai/evaluate/writing
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "essay_text": "Education is very important...",
  "task_type": "task2",                          // task1 or task2
  "task_prompt": "Some people think that education...",
  "word_count": 250,
  "request_id": "uuid"                           // For logging/tracking
}

Response 200:
{
  "overall_band_score": 7.0,
  "detailed_scores": {
    "task_achievement": 7.0,
    "coherence_cohesion": 6.5,
    "lexical_resource": 7.0,
    "grammar_accuracy": 7.0
  },
  "feedback": {
    "strengths": [
      "Clear thesis statement",
      "Good use of linking words"
    ],
    "weaknesses": [
      "Some grammatical errors",
      "Limited vocabulary range"
    ],
    "grammar_errors": [...],
    "vocabulary_suggestions": [...]
  },
  "metadata": {
    "processing_time_ms": 5200,
    "cache_hit": false,
    "tokens_used": 1200,
    "model_name": "gpt-4-turbo",
    "model_version": "2024-11-05"
  }
}
```

#### 2. Transcribe Speaking (Stateless)
```http
POST /api/v1/ai/transcribe/speaking
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "audio_url": "s3://bucket/audio.mp3",
  "audio_duration_seconds": 180,
  "language": "en",                              // English
  "request_id": "uuid"
}

Response 200:
{
  "transcript_text": "I would like to talk about...",
  "word_count": 150,
  "confidence_score": 0.95,
  "metadata": {
    "processing_time_ms": 3000,
    "model_name": "whisper-1",
    "detected_language": "en"
  }
}
```

#### 3. Evaluate Speaking (Stateless)
```http
POST /api/v1/ai/evaluate/speaking
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "transcript_text": "I would like to talk about...",
  "audio_url": "s3://bucket/audio.mp3",
  "part_number": 2,
  "prompt_text": "Describe a place you visited",
  "audio_duration_seconds": 180,
  "request_id": "uuid"
}

Response 200:
{
  "overall_band_score": 7.5,
  "detailed_scores": {
    "fluency_coherence": 7.0,
    "lexical_resource": 7.5,
    "grammar_accuracy": 7.5,
    "pronunciation": 8.0
  },
  "feedback": {
    "strengths": [
      "Natural flow and good pacing",
      "Wide range of vocabulary"
    ],
    "weaknesses": [
      "Some hesitation in complex sentences",
      "Minor pronunciation issues with certain words"
    ],
    "pronunciation_notes": [...],
    "grammar_notes": [...]
  },
  "metadata": {
    "processing_time_ms": 4500,
    "cache_hit": false,
    "tokens_used": 1500,
    "model_name": "gpt-4-turbo",
    "model_version": "2024-11-05"
  }
}
```

#### 4. Health Check
```http
GET /api/v1/ai/health
Response 200:
{
  "status": "healthy",
  "services": {
    "openai_api": "connected",
    "cache": "operational"
  },
  "cache_stats": {
    "total_entries": 1250,
    "hit_rate": 0.65,
    "total_size_mb": 12.5
  }
}
```

---

## 🔧 IMPLEMENTATION PHASES

### Phase 0: Preparation & Setup (2 hours)
**Goal**: Set up development environment and create feature branch

**Tasks**:
1. Create feature branch: `feature/scoring-system-refactor`
2. Backup current database schemas
3. Create rollback scripts
4. Set up local testing environment
5. Document current system state

**Deliverables**:
- ✅ Feature branch created
- ✅ Database backup completed
- ✅ Rollback scripts ready
- ✅ Testing environment verified

---

### Phase 1: Database Schema Updates (4-5 hours)
**Goal**: Create new tables and update existing ones

#### Task 1.1: User Service Migrations
**Priority**: P0 (Critical)

Create migrations:
```
database/migrations/
├── 024_create_official_test_results.sql
├── 025_create_practice_activities.sql
├── 026_alter_learning_progress_add_test_tracking.sql
└── 027_alter_skill_statistics_add_separated_metrics.sql
```

**Testing**:
- Run migrations on local database
- Verify indexes created
- Check constraints working
- Test rollback scripts

#### Task 1.2: Exercise Service Migrations
Create migrations:
```
services/exercise-service/migrations/
├── 005_create_writing_prompts_table.sql
├── 006_create_speaking_prompts_table.sql
├── 007_alter_exercises_add_prompt_references.sql
└── 008_alter_submissions_add_writing_speaking_fields.sql
```

**Migration Details**:

**005_create_writing_prompts_table.sql**:
- Create `writing_prompts` table (full structure from design)
- Create indexes for performance

**006_create_speaking_prompts_table.sql**:
- Create `speaking_prompts` table (full structure from design)
- Create indexes for performance

**007_alter_exercises_add_prompt_references.sql**:
- Add `writing_prompt_id` foreign key to exercises
- Add `speaking_prompt_id` foreign key to exercises
- Add `writing_task_type` column
- Add `speaking_part_number` column

**008_alter_submissions_add_writing_speaking_fields.sql**:
- Add `essay_text`, `word_count` for writing
- Add `audio_url`, `audio_duration_seconds`, `transcript_text` for speaking
- Add `evaluation_status` (pending/processing/completed/failed)
- Add `detailed_scores` JSONB
- Add `ai_feedback` JSONB
- Create index on `evaluation_status`

#### Task 1.3: AI Service Migrations
Create migrations:
```
services/ai-service/migrations/
├── 005_create_evaluation_cache_table.sql
├── 006_create_evaluation_logs_table.sql
└── 007_prepare_for_cleanup.sql (marks tables for future deletion)
```

**Migration Details**:

**005_create_evaluation_cache_table.sql**:
- Create `ai_evaluation_cache` table for caching results
- Create indexes for fast lookup

**006_create_evaluation_logs_table.sql**:
- Create `ai_evaluation_logs` table for monitoring
- Create indexes for analytics queries

**007_prepare_for_cleanup.sql**:
- Add comments marking tables for deletion after migration:
  - `writing_prompts` → will be dropped
  - `speaking_prompts` → will be dropped
  - `writing_submissions` → will be dropped
  - `speaking_submissions` → will be dropped
- This migration does NOT drop anything yet (safety)

**Deliverables**:
- ✅ All migration files created
- ✅ Migrations tested locally
- ✅ Rollback scripts verified
- ✅ Database schemas documented

---

### Phase 2: Shared Library (4 hours)
**Goal**: Create centralized IELTS scoring logic

#### Task 2.1: Create Shared IELTS Package
```
shared/pkg/ielts/
├── band_score.go           # Conversion logic
├── band_score_test.go      # Unit tests (100% coverage)
├── rounding.go             # IELTS rounding rules
├── validation.go           # Score validation
└── README.md               # Documentation
```

**band_score.go** functions:
- `ConvertListeningScore(correct, total int) float64`
- `ConvertReadingScore(correct, total int, testType string) float64`
- `CalculateWritingBand(ta, cc, lr, gra float64) float64`
- `CalculateSpeakingBand(fc, lr, gra, pr float64) float64`
- `CalculateOverallBand(l, r, w, s float64) float64`

**Testing**:
- Unit tests for all conversion tables
- Edge cases (0 correct, all correct)
- Rounding accuracy tests
- Validation tests

**Deliverables**:
- ✅ Shared library implemented
- ✅ 100% test coverage
- ✅ Documentation complete
- ✅ CI/CD integration verified

---

### Phase 3: User Service Implementation (8-10 hours)
**Goal**: Implement new endpoints and scoring logic

#### Task 3.1: Create Models
```go
services/user-service/internal/models/
├── official_test_result.go
└── practice_activity.go
```

#### Task 3.2: Repository Layer
Update `user_repository.go`:
- `CreateOfficialTestResult()`
- `GetUserTestHistory()`
- `GetUserTestStatistics()`
- `CreatePracticeActivity()`
- `GetUserPracticeActivities()`
- `GetUserPracticeStatistics()`
- `UpdateLearningProgressWithTestScore()`

#### Task 3.3: Service Layer
Update `user_service.go`:
- `RecordOfficialTestResult()`
  - Calculate band if needed
  - Save to official_test_results
  - Update learning_progress
  - Recalculate overall_score
  - Update skill_statistics
  - Check achievements
- `RecordPracticeActivity()`
  - Save to practice_activities
  - Update statistics
  - NO update to official scores

#### Task 3.4: Handler Layer
Create `internal/handlers/scoring_handler.go`:
- `RecordTestResultInternal()`
- `RecordPracticeActivityInternal()`
- `GetUserTestHistory()`
- `GetUserPracticeStatistics()`

#### Task 3.5: Update Shared Client
```go
shared/pkg/client/user_service_client.go
// Add methods:
- RecordTestResult()
- RecordPracticeActivity()
- GetTestHistory()
- GetPracticeStatistics()
```

**Testing**:
- Unit tests for all repository methods
- Integration tests for service layer
- API endpoint tests
- Test both practice and official test flows

**Deliverables**:
- ✅ All models implemented
- ✅ Repository layer complete with tests
- ✅ Service layer complete with tests
- ✅ API endpoints working
- ✅ Client library updated

---

### Phase 4: Exercise Service - Writing/Speaking Support (10-12 hours)
**Goal**: Extend exercise service to handle all 4 skills and manage prompts

#### Task 4.1: Add Prompt Management
Create `services/exercise-service/internal/models/prompt.go`:
```go
type WritingPrompt struct {
    ID                    uuid.UUID
    TaskType              string    // task1, task2
    PromptText            string
    VisualType            *string   // For Task 1
    VisualURL             *string
    Topic                 string
    Difficulty            string
    HasSampleAnswer       bool
    SampleAnswerText      *string
    SampleAnswerBandScore *float64
    TimesUsed             int
    AverageScore          *float64
    IsPublished           bool
    CreatedBy             uuid.UUID
    CreatedAt             time.Time
    UpdatedAt             time.Time
}

type SpeakingPrompt struct {
    ID                      uuid.UUID
    PartNumber              int       // 1, 2, 3
    PromptText              string
    CueCardTopic            *string   // For Part 2
    CueCardPoints           []string  // For Part 2
    PreparationTimeSeconds  int
    SpeakingTimeSeconds     int
    FollowUpQuestions       []string  // For Part 3
    TopicCategory           string
    Difficulty              string
    HasSampleAnswer         bool
    SampleAnswerText        *string
    SampleAnswerAudioURL    *string
    SampleAnswerBandScore   *float64
    TimesUsed               int
    AverageScore            *float64
    IsPublished             bool
    CreatedBy               uuid.UUID
    CreatedAt               time.Time
    UpdatedAt               time.Time
}
```

Create Repository & Service for prompt management:
```
services/exercise-service/internal/
├── repository/
│   ├── writing_prompt_repository.go
│   └── speaking_prompt_repository.go
└── service/
    └── prompt_service.go
```

#### Task 4.2: Update Exercise Models
Update `services/exercise-service/internal/models/models.go`:
```go
type Exercise struct {
    // ... existing fields ...
    
    // Writing exercise fields
    WritingPromptID  *uuid.UUID
    WritingTaskType  *string    // task1, task2
    
    // Speaking exercise fields
    SpeakingPromptID *uuid.UUID
    SpeakingPartNumber *int     // 1, 2, 3
    
    // Relationships (loaded on demand)
    WritingPrompt  *WritingPrompt  `gorm:"-" json:"writing_prompt,omitempty"`
    SpeakingPrompt *SpeakingPrompt `gorm:"-" json:"speaking_prompt,omitempty"`
}

// Helper methods
func (e *Exercise) IsOfficialTest() bool {
    return e.ExerciseType == "full_test" || e.ExerciseType == "mock_test"
}

func (e *Exercise) RequiresAIEvaluation() bool {
    return e.SkillType == "writing" || e.SkillType == "speaking"
}

func (e *Exercise) LoadPrompt(repo PromptRepository) error {
    if e.SkillType == "writing" && e.WritingPromptID != nil {
        prompt, err := repo.GetWritingPrompt(*e.WritingPromptID)
        if err != nil {
            return err
        }
        e.WritingPrompt = prompt
    }
    if e.SkillType == "speaking" && e.SpeakingPromptID != nil {
        prompt, err := repo.GetSpeakingPrompt(*e.SpeakingPromptID)
        if err != nil {
            return err
        }
        e.SpeakingPrompt = prompt
    }
    return nil
}
```

Update `ExerciseSubmission` model:
```go
type ExerciseSubmission struct {
    // ... existing fields ...
    
    // Writing submission fields
    EssayText     *string
    WordCount     *int
    
    // Speaking submission fields
    AudioURL            *string
    AudioDurationSeconds *int
    TranscriptText      *string
    
    // AI Evaluation tracking
    EvaluationStatus  string    // pending, processing, completed, failed
    AIEvaluationID    *uuid.UUID
    DetailedScores    JSONB     // {task_achievement: 7.0, ...}
    AIFeedback        JSONB     // Structured feedback from AI
}
```

#### Task 4.3: Create AI Service Client
Create `services/exercise-service/internal/client/ai_service_client.go`:
```go
type AIServiceClient struct {
    baseURL    string
    apiKey     string
    httpClient *http.Client
}

func (c *AIServiceClient) EvaluateWriting(ctx context.Context, req *EvaluateWritingRequest) (*EvaluationResponse, error) {
    // POST to AI Service: /api/v1/ai/evaluate/writing
}

func (c *AIServiceClient) TranscribeSpeaking(ctx context.Context, audioURL string) (*TranscriptionResponse, error) {
    // POST to AI Service: /api/v1/ai/transcribe/speaking
}

func (c *AIServiceClient) EvaluateSpeaking(ctx context.Context, req *EvaluateSpeakingRequest) (*EvaluationResponse, error) {
    // POST to AI Service: /api/v1/ai/evaluate/speaking
}
```

#### Task 4.4: Unified Submission Handler
Update `services/exercise-service/internal/service/exercise_service.go`:
```go
func (s *ExerciseService) SubmitExercise(ctx context.Context, exerciseID uuid.UUID, userID uuid.UUID, submissionData interface{}) (*SubmissionResult, error) {
    // 1. Get exercise
    exercise, err := s.repo.GetExerciseByID(exerciseID)
    if err != nil {
        return nil, err
    }
    
    // 2. Load prompt if needed
    if exercise.RequiresAIEvaluation() {
        exercise.LoadPrompt(s.promptRepo)
    }
    
    // 3. Route to appropriate handler
    switch exercise.SkillType {
    case "listening", "reading":
        return s.handleListeningReadingSubmission(ctx, exercise, userID, submissionData)
    case "writing":
        return s.handleWritingSubmission(ctx, exercise, userID, submissionData)
    case "speaking":
        return s.handleSpeakingSubmission(ctx, exercise, userID, submissionData)
    default:
        return nil, errors.New("unsupported skill type")
    }
}

func (s *ExerciseService) handleWritingSubmission(ctx context.Context, exercise *Exercise, userID uuid.UUID, data interface{}) (*SubmissionResult, error) {
    // 1. Save submission with status="pending"
    submission := &ExerciseSubmission{
        ExerciseID:       exercise.ID,
        UserID:           userID,
        EssayText:        data.EssayText,
        WordCount:        data.WordCount,
        EvaluationStatus: "pending",
        StartedAt:        data.StartedAt,
        SubmittedAt:      time.Now(),
    }
    
    if err := s.repo.CreateSubmission(submission); err != nil {
        return nil, err
    }
    
    // 2. Call AI service asynchronously
    go s.evaluateWritingAsync(submission.ID, exercise.WritingPrompt)
    
    // 3. Return immediately with pending status
    return &SubmissionResult{
        SubmissionID:     submission.ID,
        Status:           "pending",
        Message:          "Your essay is being evaluated. This may take up to 30 seconds.",
        EstimatedWaitSec: 30,
    }, nil
}

func (s *ExerciseService) evaluateWritingAsync(submissionID uuid.UUID, prompt *WritingPrompt) {
    ctx := context.Background()
    
    // 1. Get submission
    submission, err := s.repo.GetSubmissionByID(submissionID)
    if err != nil {
        s.logger.Error("Failed to get submission", "error", err)
        return
    }
    
    // 2. Update status to "processing"
    submission.EvaluationStatus = "processing"
    s.repo.UpdateSubmission(submission)
    
    // 3. Call AI service
    result, err := s.aiClient.EvaluateWriting(ctx, &EvaluateWritingRequest{
        EssayText:  *submission.EssayText,
        TaskType:   prompt.TaskType,
        TaskPrompt: prompt.PromptText,
        WordCount:  *submission.WordCount,
    })
    
    if err != nil {
        submission.EvaluationStatus = "failed"
        s.repo.UpdateSubmission(submission)
        return
    }
    
    // 4. Update submission with results
    submission.BandScore = result.OverallBandScore
    submission.DetailedScores = result.DetailedScores
    submission.AIFeedback = result.Feedback
    submission.EvaluationStatus = "completed"
    submission.CompletedAt = time.Now()
    
    s.repo.UpdateSubmission(submission)
    
    // 5. Record to user service
    s.recordToUserService(submission, exercise)
    
    // 6. Send notification
    s.notificationClient.SendNotification(submission.UserID, "Your essay has been graded!")
}
```

#### Task 4.5: Add Prompt Management APIs
Create `services/exercise-service/internal/handlers/prompt_handler.go`:
```go
// GET /api/v1/prompts/writing
func (h *PromptHandler) ListWritingPrompts(c *gin.Context)

// POST /api/v1/prompts/writing
func (h *PromptHandler) CreateWritingPrompt(c *gin.Context)

// GET /api/v1/prompts/speaking
func (h *PromptHandler) ListSpeakingPrompts(c *gin.Context)

// POST /api/v1/prompts/speaking
func (h *PromptHandler) CreateSpeakingPrompt(c *gin.Context)
```

#### Task 4.6: User Service Integration
Update `recordToUserService()`:
```go
func (s *ExerciseService) recordToUserService(submission *ExerciseSubmission, exercise *Exercise) error {
    // Determine if official test or practice
    isOfficialTest := exercise.IsOfficialTest()
    
    if isOfficialTest {
        // Record as official test result
        return s.userClient.RecordTestResult(&RecordTestResultRequest{
            UserID:            submission.UserID,
            TestType:          exercise.ExerciseType,
            SkillType:         exercise.SkillType,
            SourceService:     "exercise_service",
            SourceTable:       "exercise_submissions",
            SourceID:          submission.ID,
            BandScore:         submission.BandScore,
            DetailedScores:    submission.DetailedScores,
            TimeSpentMinutes:  submission.TimeSpentMinutes,
        })
    } else {
        // Record as practice activity
        return s.userClient.RecordPracticeActivity(&RecordPracticeRequest{
            UserID:            submission.UserID,
            ActivityType:      exercise.ExerciseType,
            SkillType:         exercise.SkillType,
            SourceService:     "exercise_service",
            SourceTable:       "exercise_submissions",
            SourceID:          submission.ID,
            Score:             submission.BandScore,
            TimeSpentMinutes:  submission.TimeSpentMinutes,
        })
    }
}
```

**Testing**:
- ✅ Unit tests for each skill type handler
- ✅ Unit tests for prompt management
- ✅ Integration tests with mocked AI service
- ✅ End-to-end tests for full submission flow
- ✅ Async evaluation tests (verify status transitions)
- ✅ Load testing for concurrent submissions
- ✅ Error handling tests (AI service down, timeout, etc.)

**Deliverables**:
- ✅ Prompts managed by exercise service
- ✅ All 4 skills fully supported
- ✅ AI client implemented and tested
- ✅ Async evaluation working reliably
- ✅ User service integration complete
- ✅ Frontend APIs ready
- ✅ Error handling robust
- ✅ Performance acceptable (<5s for AI evaluation)

---

### Phase 5: AI Service Refactoring (6-8 hours)
**Goal**: Convert AI service to pure evaluation engine (stateless)

#### Task 5.1: Remove Integration Code
**Delete files**:
```
services/ai-service/internal/
├── integration/           # DELETE entire directory
│   ├── user_service_client.go
│   ├── notification_client.go
│   └── exercise_service_client.go
└── handlers/
    └── submission_handler.go  # DELETE (no more submission endpoints)
```

**Remove from code**:
- All references to user-service client
- All references to notification client
- All submission management logic
- All prompt management endpoints (prompts moved to exercise-service)

#### Task 5.2: Implement Pure Evaluation APIs
Create/Update `services/ai-service/internal/service/evaluation_service.go`:

```go
type EvaluationService struct {
    openaiClient *openai.Client
    cacheService *CacheService
    logger       *logger.Logger
}

// Pure evaluation - no side effects
func (s *EvaluationService) EvaluateWriting(ctx context.Context, req *EvaluateWritingRequest) (*EvaluationResult, error) {
    // 1. Hash content for cache lookup
    contentHash := s.hashContent(req.EssayText)
    
    // 2. Check cache first
    if cached, found := s.cacheService.Get(contentHash); found {
        return cached, nil
    }
    
    // 3. Call OpenAI API
    result, err := s.callOpenAI(ctx, req)
    if err != nil {
        return nil, err
    }
    
    // 4. Cache result
    s.cacheService.Set(contentHash, result)
    
    // 5. Log for monitoring
    s.logEvaluation(contentHash, result, false)
    
    return result, nil
}

// Similar for Speaking evaluation
func (s *EvaluationService) EvaluateSpeaking(ctx context.Context, req *EvaluateSpeakingRequest) (*EvaluationResult, error)

// Pure transcription - no side effects
func (s *EvaluationService) TranscribeAudio(ctx context.Context, req *TranscribeRequest) (*TranscriptionResult, error)
```

#### Task 5.3: Implement Caching Layer
Create `services/ai-service/internal/service/cache_service.go`:

```go
type CacheService struct {
    repo   *repository.CacheRepository
    logger *logger.Logger
}

// Generate cache key
func (s *CacheService) hashContent(content string) string {
    h := sha256.New()
    h.Write([]byte(content))
    return hex.EncodeToString(h.Sum(nil))
}

// Check cache
func (s *CacheService) Get(contentHash string) (*EvaluationResult, bool) {
    cached, err := s.repo.GetByHash(contentHash)
    if err != nil || cached == nil {
        return nil, false
    }
    
    // Update hit count
    s.repo.IncrementHitCount(cached.ID)
    
    return s.toEvaluationResult(cached), true
}

// Store in cache
func (s *CacheService) Set(contentHash string, result *EvaluationResult) error {
    cache := &models.AIEvaluationCache{
        ContentHash:      contentHash,
        SkillType:        result.SkillType,
        OverallBandScore: result.OverallBandScore,
        DetailedScores:   result.DetailedScores,
        Feedback:         result.Feedback,
        AIModelName:      result.ModelName,
        AIModelVersion:   result.ModelVersion,
        ProcessingTimeMs: result.ProcessingTimeMs,
        ExpiresAt:        nil, // Never expire by default
    }
    
    return s.repo.Create(cache)
}
```

#### Task 5.4: Update Handlers (Stateless)
Create `services/ai-service/internal/handlers/evaluation_handler.go`:

```go
type EvaluationHandler struct {
    evaluationService *service.EvaluationService
}

// POST /api/v1/ai/evaluate/writing
func (h *EvaluationHandler) EvaluateWriting(c *gin.Context) {
    var req dto.EvaluateWritingRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    // Just evaluate and return - NO database writes except cache
    result, err := h.evaluationService.EvaluateWriting(c.Request.Context(), &req)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, result)
}

// POST /api/v1/ai/evaluate/speaking
func (h *EvaluationHandler) EvaluateSpeaking(c *gin.Context)

// POST /api/v1/ai/transcribe/speaking
func (h *EvaluationHandler) TranscribeAudio(c *gin.Context)
```

#### Task 5.5: Update Routes
Update `services/ai-service/internal/routes/routes.go`:

```go
func SetupRoutes(r *gin.Engine) {
    api := r.Group("/api/v1")
    
    // ONLY evaluation endpoints
    ai := api.Group("/ai")
    ai.Use(middleware.InternalAPIAuth()) // Require internal API key
    {
        ai.POST("/evaluate/writing", handlers.EvaluateWriting)
        ai.POST("/evaluate/speaking", handlers.EvaluateSpeaking)
        ai.POST("/transcribe/speaking", handlers.TranscribeAudio)
        ai.GET("/health", handlers.HealthCheck)
    }
    
    // REMOVED: All submission endpoints
    // REMOVED: All prompt management endpoints
    // REMOVED: All user integration endpoints
}
```

#### Task 5.6: Database Cleanup
Update `services/ai-service/internal/repository/`:
- Keep: `cache_repository.go` (for ai_evaluation_cache)
- Keep: `log_repository.go` (for ai_evaluation_logs)
- Keep: `criteria_repository.go` (for grading_criteria - read-only)
- **Delete**: `writing_submission_repository.go`
- **Delete**: `speaking_submission_repository.go`
- **Delete**: `prompt_repository.go` (prompts moved to exercise-service)

**Testing**:
- ✅ Unit tests for evaluation logic (mock OpenAI)
- ✅ Cache hit/miss tests
- ✅ Performance tests (response time < 500ms for cache hits)
- ✅ Load tests (100 concurrent requests)
- ✅ Cost calculation tests (verify cache reduces API calls)
- ✅ Integration tests with exercise-service

**Deliverables**:
- ✅ AI service is completely stateless (except cache)
- ✅ No submissions stored in AI service
- ✅ No prompts stored in AI service
- ✅ No integration with user-service
- ✅ Caching reduces OpenAI API costs by 50%+
- ✅ API response time < 5s for cache misses, < 100ms for cache hits
- ✅ All tests passing (>90% coverage)

---

### Phase 6: Data Migration (5-6 hours)
**Goal**: Migrate prompts and submissions from ai_db to exercise_db

#### Task 6.1: Create Migration Scripts
```
scripts/data-migration/
├── 01-backup-ai-service-data.sh
├── 02-migrate-prompts.sql
├── 03-migrate-writing-submissions.sql
├── 04-migrate-speaking-submissions.sql
├── 05-verify-migration.sql
├── 06-cleanup-ai-service.sql
└── README.md
```

#### Task 6.2: Migration Steps

**Step 1: Backup AI Service Data**
```bash
# Backup entire ai_db before migration
pg_dump -U postgres -h localhost ai_db > backup_ai_db_$(date +%Y%m%d_%H%M%S).sql
```

**Step 2: Migrate Prompts (Priority: Critical)**
```sql
-- FROM: ai_db.writing_prompts
-- TO: exercise_db.writing_prompts

BEGIN;

-- Insert writing prompts
INSERT INTO exercise_db.writing_prompts (
    id, task_type, prompt_text, visual_type, visual_url,
    topic, difficulty, has_sample_answer, sample_answer_text,
    sample_answer_band_score, times_used, average_score,
    is_published, created_by, created_at, updated_at
)
SELECT 
    id, task_type, prompt_text, visual_type, visual_url,
    topic, difficulty, has_sample_answer, sample_answer_text,
    sample_answer_band_score, times_used, average_score,
    is_published, created_by, created_at, updated_at
FROM ai_db.writing_prompts
ON CONFLICT (id) DO NOTHING;

-- Verify count
DO $$
DECLARE
    source_count INTEGER;
    target_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO source_count FROM ai_db.writing_prompts;
    SELECT COUNT(*) INTO target_count FROM exercise_db.writing_prompts;
    
    IF source_count != target_count THEN
        RAISE EXCEPTION 'Writing prompts migration failed: source=%, target=%', source_count, target_count;
    END IF;
    
    RAISE NOTICE 'Writing prompts migrated successfully: % records', target_count;
END $$;

-- Insert speaking prompts
INSERT INTO exercise_db.speaking_prompts (
    id, part_number, prompt_text, cue_card_topic, cue_card_points,
    preparation_time_seconds, speaking_time_seconds, follow_up_questions,
    topic_category, difficulty, has_sample_answer, sample_answer_text,
    sample_answer_audio_url, sample_answer_band_score, times_used,
    average_score, is_published, created_by, created_at, updated_at
)
SELECT 
    id, part_number, prompt_text, cue_card_topic, cue_card_points,
    preparation_time_seconds, speaking_time_seconds, follow_up_questions,
    topic_category, difficulty, has_sample_answer, sample_answer_text,
    sample_answer_audio_url, sample_answer_band_score, times_used,
    average_score, is_published, created_by, created_at, updated_at
FROM ai_db.speaking_prompts
ON CONFLICT (id) DO NOTHING;

-- Verify count
DO $$
DECLARE
    source_count INTEGER;
    target_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO source_count FROM ai_db.speaking_prompts;
    SELECT COUNT(*) INTO target_count FROM exercise_db.speaking_prompts;
    
    IF source_count != target_count THEN
        RAISE EXCEPTION 'Speaking prompts migration failed: source=%, target=%', source_count, target_count;
    END IF;
    
    RAISE NOTICE 'Speaking prompts migrated successfully: % records', target_count;
END $$;

COMMIT;
```

**Step 3: Migrate Submissions (if any exist in ai_db)**
```sql
-- If there are existing writing/speaking submissions in ai_db,
-- they need to be migrated to exercise_db.exercise_submissions

-- Note: This may require creating "legacy" exercises first
-- to satisfy foreign key constraints
```

**Step 4: Update Exercise References**
```sql
-- Update existing exercises that reference prompts
-- (if any were created before migration)

UPDATE exercise_db.exercises
SET writing_prompt_id = wp.id
FROM ai_db.writing_prompts wp
WHERE exercises.skill_type = 'writing'
  AND exercises.writing_prompt_id IS NULL
  -- Add logic to match exercises to prompts
  -- (depends on your data structure);
```

#### Task 6.3: Verification
```sql
-- Verification script
SELECT 'writing_prompts' as table_name,
       (SELECT COUNT(*) FROM ai_db.writing_prompts) as source_count,
       (SELECT COUNT(*) FROM exercise_db.writing_prompts) as target_count;

SELECT 'speaking_prompts' as table_name,
       (SELECT COUNT(*) FROM ai_db.speaking_prompts) as source_count,
       (SELECT COUNT(*) FROM exercise_db.speaking_prompts) as target_count;

-- Sample data comparison (check 5 random records)
SELECT 'Sample writing prompts match:' as check;
SELECT w1.id, w1.prompt_text = w2.prompt_text as text_match
FROM ai_db.writing_prompts w1
JOIN exercise_db.writing_prompts w2 ON w1.id = w2.id
ORDER BY RANDOM()
LIMIT 5;
```

#### Task 6.4: Cleanup AI Service
```sql
-- After verification passes, clean up ai_db
-- Keep this script separate and run ONLY after thorough verification

BEGIN;

-- Drop prompt tables (data now in exercise_db)
DROP TABLE IF EXISTS ai_db.writing_prompts CASCADE;
DROP TABLE IF EXISTS ai_db.speaking_prompts CASCADE;

-- Drop submission tables (if migrated)
DROP TABLE IF EXISTS ai_db.writing_submissions CASCADE;
DROP TABLE IF EXISTS ai_db.writing_evaluations CASCADE;
DROP TABLE IF EXISTS ai_db.speaking_submissions CASCADE;
DROP TABLE IF EXISTS ai_db.speaking_evaluations CASCADE;

-- Keep only:
-- - grading_criteria
-- - ai_model_versions
-- - ai_evaluation_cache (new)
-- - ai_evaluation_logs (new)

COMMIT;
```

**Testing**:
- ✅ Dry run on development database
- ✅ Dry run on staging database
- ✅ Rollback test (restore from backup)
- ✅ Production migration rehearsal
- ✅ Verify all foreign key relationships
- ✅ Check application still works with migrated data

**Deliverables**:
- ✅ All prompts migrated successfully
- ✅ All submissions migrated (if any)
- ✅ Verification passed (counts match)
- ✅ Sample data verified (content matches)
- ✅ Backup created and tested
- ✅ AI Service tables cleaned up
- ✅ Application tested with new data location

---

### Phase 7: Frontend Updates (6-8 hours)
**Goal**: Update UI to reflect new scoring system

#### Task 7.1: Update API Client
```typescript
Frontend-IELTSGo/lib/api/
├── progress.ts (update)
├── exercises.ts (update)
└── tests.ts (new)
```

New functions:
- `getOfficialScores()`
- `getTestHistory()`
- `getPracticeStatistics()`
- `pollSubmissionResult()` (for W/S)

#### Task 7.2: Create New Components
```typescript
Frontend-IELTSGo/components/dashboard/
├── OfficialScoreCard.tsx      # Official test scores
├── PracticeStatsCard.tsx      # Practice activity stats
├── TestHistoryChart.tsx       # Score progress over time
├── TestHistoryTable.tsx       # Detailed test history
└── SubmissionPolling.tsx      # For W/S async evaluation
```

#### Task 7.3: Update Dashboard
```typescript
Frontend-IELTSGo/app/dashboard/page.tsx
```

Add tabs:
- Official Scores (default)
- Practice Statistics
- Test History
- Activity Log

#### Task 7.4: Add Tooltips & Help
Add explanations:
- "Official scores from full tests only"
- "Practice drills help improve but don't affect official score"
- Score calculation methodology

**Testing**:
- Component unit tests
- Integration tests
- E2E tests with Playwright
- Mobile responsiveness

**Deliverables**:
- ✅ API client updated
- ✅ New components created
- ✅ Dashboard refactored
- ✅ Help text added
- ✅ Tests passing
- ✅ UX verified

---

### Phase 8: Integration Testing (4-6 hours)
**Goal**: End-to-end testing of entire system

#### Test Scenarios
1. **Listening Full Test Flow**
   - Create full test exercise
   - User submits answers
   - Verify immediate grading
   - Check official score updated
   - Verify dashboard displays correctly

2. **Reading Practice Drill Flow**
   - Create practice exercise
   - User submits answers
   - Verify quick grading
   - Check practice stats updated
   - Verify official score NOT changed

3. **Writing Official Test Flow**
   - Create full test exercise
   - User submits essay
   - Verify async evaluation
   - Check AI service called
   - Verify score updated after completion
   - Check notification sent

4. **Speaking Practice Flow**
   - Create practice exercise
   - User uploads audio
   - Verify transcription
   - Verify evaluation
   - Check practice stats updated
   - Verify official score NOT changed

5. **Mixed Activities**
   - User does 5 listening drills
   - User does 1 listening full test
   - Verify dashboard shows:
     - Official Score = full test result
     - Practice Average = drills average
     - Test count = 1
     - Practice count = 5

**Deliverables**:
- ✅ All test scenarios pass
- ✅ No regressions found
- ✅ Performance acceptable
- ✅ Error handling verified

---

### Phase 9: Deployment & Monitoring (4-6 hours)
**Goal**: Deploy to production safely

#### Task 9.1: Pre-Deployment
- Code review completed
- All tests passing
- Documentation updated
- Rollback plan ready
- Monitoring setup

#### Task 9.2: Deployment Strategy
**Blue-Green Deployment**:
1. Deploy new services to "green" environment
2. Run smoke tests
3. Migrate 10% traffic to green
4. Monitor for 1 hour
5. If OK, migrate 50% traffic
6. Monitor for 2 hours
7. If OK, migrate 100% traffic
8. Keep blue environment for 24h (quick rollback)

#### Task 9.3: Monitoring
Set up alerts for:
- API response times
- Error rates
- AI service call failures
- Database query performance
- User-facing errors

#### Task 9.4: Post-Deployment
- Verify all services healthy
- Check key metrics
- Monitor user feedback
- Document any issues
- Create incident response plan

**Deliverables**:
- ✅ Deployment successful
- ✅ All services healthy
- ✅ Monitoring active
- ✅ No critical issues
- ✅ Documentation complete

---

## ⏱️ TIMELINE & RESOURCES

### Estimated Timeline
| Phase | Duration | Dependencies | Risk Level | Key Deliverables |
|-------|----------|--------------|------------|------------------|
| Phase 0: Preparation | 2 hours | None | Low | Feature branch, backups, rollback scripts |
| Phase 1: Database | 5-6 hours | Phase 0 | Medium | All schemas updated, prompts tables created |
| Phase 2: Shared Library | 4 hours | None | Low | IELTS scoring package with 100% test coverage |
| Phase 3: User Service | 8-10 hours | Phase 1, 2 | Medium | Test/practice recording endpoints |
| Phase 4: Exercise Service | 12-14 hours | Phase 1, 2, 3 | High | **Prompts management + W/S support** |
| Phase 5: AI Service | 6-8 hours | Phase 4 | Medium | Stateless evaluation APIs + caching |
| Phase 6: Data Migration | 5-6 hours | Phase 1, 5 | High | **Prompts + submissions migrated** |
| Phase 7: Frontend | 6-8 hours | Phase 3, 4 | Low | Updated dashboard + async polling |
| Phase 8: Integration Testing | 5-7 hours | Phase 7 | Medium | All test scenarios passing |
| Phase 9: Deployment | 4-6 hours | Phase 8 | High | Production deployment + monitoring |

**Total**: 57-75 hours (~7-10 working days)

**Critical Path**: Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

**Parallel Work Possible**:
- Phase 2 (Shared Library) can be done in parallel with Phase 1
- Phase 5 (AI Service) can start while Phase 4 is in progress (if different developers)

### Resource Requirements
- **Developer**: 1 full-stack developer
- **Database Access**: Read/write to all databases
- **OpenAI API Key**: For AI service testing
- **Staging Environment**: For integration testing
- **Production Access**: For deployment

---

## 🔒 RISK MANAGEMENT

### Risk Matrix
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Data loss during migration | Low | Critical | Backup before migration, dry run on staging |
| Breaking existing features | Medium | High | Comprehensive testing, feature flags |
| AI service downtime | Medium | Medium | Implement retry logic, queue system |
| Performance degradation | Low | Medium | Load testing, query optimization |
| User confusion | Medium | Low | Clear UI labels, help documentation |

### Rollback Strategy
**If critical issues found**:
1. Switch traffic back to old services (blue environment)
2. Investigate issue in green environment
3. Fix and retest
4. Attempt deployment again

**Database rollback**:
1. Run rollback migration scripts
2. Restore from backup if needed
3. Verify data integrity
4. Document issue for future prevention

---

## 🤔 ARCHITECTURE DECISION RATIONALE

### Why Prompts Belong in Exercise Service (Not AI Service)

#### ❌ If Prompts Stay in AI Service:
```
Problems:
1. Tight Coupling
   - Exercise Service must call AI Service just to create exercises
   - Creates unnecessary dependency
   - Slows down exercise creation

2. Semantic Confusion
   - AI Service name implies "evaluation/intelligence"
   - But it's also managing content (prompts)?
   - Mixed responsibilities violate SRP (Single Responsibility Principle)

3. Scaling Issues
   - AI Service should scale based on evaluation load
   - But now it must handle both evaluation AND prompt queries
   - Can't scale independently

4. Development Friction
   - Adding a new prompt requires AI Service deployment
   - But prompts have nothing to do with AI models
   - Frontend must integrate with 2 services for exercise creation
```

#### ✅ Prompts in Exercise Service:
```
Benefits:
1. Single Source of Truth
   - Exercise Service manages ALL exercise content
   - Prompts, questions, passages, audio - all in one place
   - Clear ownership: "Need exercise content? → Exercise Service"

2. Zero Coupling During Creation
   - Admin creates exercise without calling AI Service
   - Faster response times
   - Works even if AI Service is down

3. Clean Separation of Concerns
   - Exercise Service = Content Management
   - AI Service = Pure Evaluation (like a utility/tool)
   - Each service has ONE clear job

4. Real-World Parallel
   - Khan Academy: Content Service (owns questions, videos, exercises)
   - Grading Service: Evaluates answers (stateless)
   - They don't mix content storage with evaluation logic

5. Better Developer Experience
   - Want to add prompts? → Exercise Service only
   - Want to improve AI evaluation? → AI Service only
   - No coordination needed between teams
```

---

### Why AI Service Should Be Stateless

#### Real-World Analogy: Payment Processing
```
Your E-commerce Service:
├── Manages orders, products, cart
└── Stores order history

Stripe API (Payment Service):
├── Processes payments (stateless)
├── Returns success/failure
└── Doesn't store your order details

You wouldn't store your product catalog in Stripe, right?
Similarly, don't store exercise content in AI Service.
```

#### Benefits of Stateless AI Service:

1. **Independent Scaling**
   ```
   Heavy evaluation load? → Scale up AI Service only
   Don't need to scale prompt database with it
   ```

2. **Cost Efficiency**
   ```
   Caching works better with stateless design
   Same essay submitted twice? → Cache hit (no OpenAI cost)
   ```

3. **Reliability**
   ```
   AI Service down? → Exercises still work (view, create, L/R grading)
   Only W/S grading affected
   ```

4. **Testing & Development**
   ```
   Mock AI Service easily (just 3 endpoints)
   No need to seed prompt data in AI Service
   Faster integration tests
   ```

---

### Comparison with Industry Standards

#### Duolingo Architecture (Inferred)
```
Content Service:
├── Lessons, exercises, questions
└── Audio files, images

AI/ML Service:
└── Speech recognition, difficulty adjustment (stateless APIs)

Scoring Service:
└── Calculates XP, streaks, levels
```

#### IELTS Official Platforms (IDP, British Council)
```
Test Delivery Service:
├── Test papers (L/R/W/S content)
└── Test attempts

Human Grading Service:
└── Examiners grade W/S (manual, not AI, but same concept - stateless workers)

Scoring Service:
└── Calculates final band scores
```

#### Our Architecture (After Refactoring)
```
Exercise Service:
├── Exercises (4 skills)
├── Prompts (W/S)
├── Questions (L/R)
└── Submissions (4 skills)

AI Service:
└── Evaluation APIs (stateless, like a microservice utility)

User Service:
└── Progress tracking, official scores
```

**Matches industry best practices** ✅

---

## ✅ SUCCESS CRITERIA

### Technical Criteria
- ✅ All unit tests passing (>90% coverage)
- ✅ All integration tests passing
- ✅ API response time <500ms (p95)
- ✅ Zero data loss
- ✅ Zero breaking changes to existing APIs (with deprecation plan)

### Business Criteria
- ✅ Official scores accurately reflect test performance
- ✅ Practice activities tracked separately
- ✅ Dashboard displays clear distinction
- ✅ User confusion reduced (measured by support tickets)
- ✅ System scalability improved

### User Experience Criteria
- ✅ Dashboard loads in <2 seconds
- ✅ Score updates visible within 5 minutes (for W/S async)
- ✅ Clear explanation of score calculation
- ✅ No disruption to active users during deployment

---

## 📚 DOCUMENTATION REQUIREMENTS

### Technical Documentation
1. **Architecture Diagrams**
   - System architecture overview
   - Database schema diagrams
   - API flow diagrams
   - Deployment architecture

2. **API Documentation**
   - OpenAPI/Swagger specs
   - Request/response examples
   - Error codes and handling
   - Rate limiting policies

3. **Database Documentation**
   - Table relationships
   - Index strategies
   - Migration history
   - Backup procedures

### User Documentation
1. **User Guide**
   - Understanding scores
   - Practice vs Official tests
   - How scoring works
   - FAQs

2. **Release Notes**
   - What's new
   - What's changed
   - Migration guide for existing users

---

## 📞 COMMUNICATION PLAN

### Stakeholder Updates
- **Daily**: Progress updates to team lead
- **Weekly**: Demo to product team
- **Pre-deployment**: Notification to all stakeholders
- **Post-deployment**: Summary report

### User Communication
- **2 weeks before**: Announcement of upcoming changes
- **1 week before**: Detailed explanation of new features
- **Launch day**: Release notes and guide
- **1 week after**: Survey for feedback

---

## 🎯 CONCLUSION

This refactoring plan provides a comprehensive, step-by-step approach to transforming the scoring system into a professional, scalable, and maintainable architecture that matches real-world IELTS learning platforms.

**Key Principles**:
1. **Safety First**: Comprehensive testing and rollback plans
2. **Clear Separation**: Each service has a single, well-defined purpose
3. **Data Integrity**: Official scores only from official tests
4. **User Experience**: Clear, accurate, and helpful feedback
5. **Scalability**: Stateless services, efficient caching, optimized queries

By following this plan meticulously and adhering to the checklist, the implementation will be successful with minimal risk.

---

---

## ✅ ARCHITECTURE VERIFICATION CHECKLIST

Use this checklist to verify the refactoring follows the correct architecture:

### Exercise Service (Single Source of Truth)
- [ ] `writing_prompts` table exists in `exercise_db`
- [ ] `speaking_prompts` table exists in `exercise_db`
- [ ] `exercises` table has foreign keys to prompts (`writing_prompt_id`, `speaking_prompt_id`)
- [ ] Exercise creation does NOT call AI Service
- [ ] GET /api/v1/exercises/{id} returns prompt data (no AI service call)
- [ ] Prompt management APIs exist: GET/POST /api/v1/prompts/writing
- [ ] Prompt management APIs exist: GET/POST /api/v1/prompts/speaking

### AI Service (Stateless Evaluation Only)
- [ ] `writing_prompts` table does NOT exist in `ai_db` (migrated out)
- [ ] `speaking_prompts` table does NOT exist in `ai_db` (migrated out)
- [ ] `writing_submissions` table does NOT exist in `ai_db` (migrated out)
- [ ] `speaking_submissions` table does NOT exist in `ai_db` (migrated out)
- [ ] AI Service has ONLY 4 tables: cache, logs, criteria, model_versions
- [ ] POST /api/v1/ai/evaluate/writing is stateless (no DB writes except cache)
- [ ] POST /api/v1/ai/evaluate/speaking is stateless (no DB writes except cache)
- [ ] AI Service does NOT integrate with user-service
- [ ] AI Service does NOT integrate with notification-service
- [ ] AI Service has NO submission management endpoints

### Integration Flow
- [ ] Admin creates writing exercise → ONLY Exercise Service (no AI call)
- [ ] Student views exercise → ONLY Exercise Service (no AI call)
- [ ] Student submits L/R → Exercise Service grades immediately (no AI call)
- [ ] Student submits Writing → Exercise Service calls AI Service ONLY for grading
- [ ] Student submits Speaking → Exercise Service calls AI Service ONLY for grading
- [ ] AI Service receives full prompt text in evaluation request (not prompt_id)
- [ ] AI Service returns result, Exercise Service stores it

### Data Migration
- [ ] All prompts migrated from ai_db to exercise_db
- [ ] Prompt counts match: SELECT COUNT(*) matches between old and new location
- [ ] Sample prompts verified: Content matches exactly
- [ ] Old prompt tables dropped from ai_db
- [ ] Backup of ai_db created before cleanup

### User Service
- [ ] `official_test_results` table exists
- [ ] `practice_activities` table exists  
- [ ] Exercise Service calls correct endpoint based on test type
- [ ] Official scores updated ONLY from full_test/mock_test
- [ ] Practice activities tracked separately

### Frontend
- [ ] Exercise creation page fetches prompts from Exercise Service
- [ ] No direct calls to AI Service from frontend
- [ ] Writing/Speaking submissions show async status (pending → completed)
- [ ] Dashboard separates official scores from practice stats

### Performance & Reliability
- [ ] Exercise creation < 500ms (no AI dependency)
- [ ] L/R grading < 500ms (no AI dependency)
- [ ] W/S grading < 10s (AI call)
- [ ] Cache hit rate > 30% (reducing API costs)
- [ ] System works when AI Service is down (except W/S grading)

---

## 📝 FINAL NOTES

### Critical Success Factors
1. **Prompts MUST be in Exercise Service** (not AI Service)
2. **AI Service MUST be stateless** (no submissions, no integrations)
3. **Data migration MUST be verified** (counts + sample data)
4. **Testing MUST cover all 4 skills** (not just L/R)
5. **Rollback plan MUST be ready** (database backups + blue-green deployment)

### Common Mistakes to Avoid
❌ Keeping prompts in AI Service "because it's already there"
❌ Calling AI Service during exercise creation
❌ Making AI Service store submissions
❌ Mixing practice and official test scores
❌ Skipping data migration verification

### Success Indicators
✅ Exercise Service is truly the single source of truth for content
✅ AI Service has minimal responsibilities (just evaluation)
✅ Clear separation of concerns across all services
✅ System matches industry standards (Duolingo, Khan Academy patterns)
✅ Reduced operational costs (caching reduces API calls)

---

**Document Version**: 2.0  
**Last Updated**: November 7, 2025  
**Changes in v2.0**: 
- Clarified prompts belong in Exercise Service (not AI Service)
- Updated architecture diagrams to reflect correct flow
- Added detailed migration plan for prompts
- Added real-world workflow examples
- Added architecture decision rationale
- Added verification checklist
**Next Review**: After Phase 1 completion
