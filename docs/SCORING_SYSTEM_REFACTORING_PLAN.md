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
- Poor user experience (confusing score displays)

### Solution Overview
Implement a centralized architecture where:
1. **Exercise Service** = Central hub for ALL submissions (4 skills)
2. **AI Service** = Pure evaluation engine (stateless, reusable)
3. **User Service** = Progress tracker (receives final results only)
4. Clear separation: Practice activities vs Official tests

### Expected Outcomes
- ✅ Accurate official scores from full tests only
- ✅ Clear practice vs test distinction
- ✅ Centralized score conversion logic
- ✅ Better scalability and maintainability
- ✅ Professional IELTS platform experience

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
                              │ (Only endpoint)
                              │
                    ┌─────────────────────────────────┐
                    │     EXERCISE SERVICE            │
                    │  - ALL submissions (4 skills)   │
                    │  - Exercises (4 skills)         │
                    │  - Grade L/R automatically      │
                    │  - Call AI for W/S evaluation   │
                    │  - Call user-service with final │
                    └─────────────────────────────────┘
                              │
                              │ (Only for evaluation)
                              ↓
                    ┌─────────────────────────────────┐
                    │       AI SERVICE                │
                    │  - Pure evaluation APIs         │
                    │  - Stateless                    │
                    │  - No storage                   │
                    │  - Reusable                     │
                    └─────────────────────────────────┘

✅ Single source of truth (exercise_service)
✅ Clear separation of concerns
✅ Stateless AI service (can scale independently)
```

---

## 📊 DATABASE DESIGN

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

#### Updates to exercises table
```sql
ALTER TABLE exercises
    -- For Writing exercises
    ADD COLUMN writing_task_type VARCHAR(20),     -- task1, task2
    ADD COLUMN task_prompt_text TEXT,
    ADD COLUMN task_prompt_id UUID,
    
    -- For Speaking exercises
    ADD COLUMN speaking_part_number INT,          -- 1, 2, 3
    
    -- Add constraint: skill_type can be listening, reading, writing, speaking
    ADD CONSTRAINT check_skill_type 
        CHECK (skill_type IN ('listening', 'reading', 'writing', 'speaking'));

COMMENT ON COLUMN exercises.skill_type IS 
    'All 4 IELTS skills supported: listening, reading, writing, speaking';
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
    skill_type VARCHAR(20) NOT NULL,           -- writing, speaking
    
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

COMMENT ON TABLE ai_evaluation_cache IS 
    'Caches AI evaluation results to reduce OpenAI API costs';
```

#### REMOVE Tables (migrate data to exercise_service)
```sql
-- These tables will be removed after data migration
-- DROP TABLE writing_submissions;     -- Move to exercise_submissions
-- DROP TABLE writing_evaluations;     -- Evaluation data goes to submissions.detailed_scores
-- DROP TABLE speaking_submissions;    -- Move to exercise_submissions
-- DROP TABLE speaking_evaluations;    -- Evaluation data goes to submissions.detailed_scores
```

#### KEEP Tables (prompts/question bank)
```sql
-- Keep these - AI service owns the question bank
-- writing_prompts (unchanged)
-- speaking_prompts (unchanged)
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

#### 1. Evaluate Writing (Stateless)
```http
POST /api/v1/ai/evaluate/writing
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "essay_text": "Education is very important...",
  "task_type": "task2",
  "task_prompt": "Some people think that education...",
  "word_count": 250
}

Response 200:
{
  "overall_band_score": 7.0,
  "task_achievement_score": 7.0,
  "coherence_cohesion_score": 6.5,
  "lexical_resource_score": 7.0,
  "grammar_accuracy_score": 7.0,
  "strengths": [
    "Clear thesis statement",
    "Good use of linking words"
  ],
  "weaknesses": [
    "Some grammatical errors",
    "Limited vocabulary range"
  ],
  "grammar_errors": [...],
  "vocabulary_suggestions": [...],
  "detailed_feedback": {...},
  "processing_time_ms": 5200,
  "cache_hit": false
}
```

#### 2. Transcribe Speaking (Stateless)
```http
POST /api/v1/ai/transcribe/speaking
Content-Type: application/json
X-Internal-API-Key: {secret}

{
  "audio_url": "s3://bucket/audio.mp3",
  "audio_duration_seconds": 180
}

Response 200:
{
  "transcript_text": "I would like to talk about...",
  "word_count": 150,
  "confidence_score": 0.95,
  "processing_time_ms": 3000
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
  "prompt_text": "Describe a place you visited"
}

Response 200:
{
  "overall_band_score": 7.5,
  "fluency_coherence_score": 7.0,
  "lexical_resource_score": 7.5,
  "grammar_accuracy_score": 7.5,
  "pronunciation_score": 8.0,
  "strengths": [...],
  "weaknesses": [...],
  "detailed_feedback": {...},
  "processing_time_ms": 4500,
  "cache_hit": false
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
├── 005_alter_exercises_add_writing_speaking_fields.sql
└── 006_alter_submissions_add_writing_speaking_fields.sql
```

#### Task 1.3: AI Service Migrations
Create migrations:
```
services/ai-service/migrations/
├── 005_create_evaluation_cache_table.sql
└── 006_prepare_for_submissions_migration.sql
```

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
**Goal**: Extend exercise service to handle all 4 skills

#### Task 4.1: Update Models
```go
services/exercise-service/internal/models/
├── models.go (update Exercise, ExerciseSubmission)
└── dto.go (update request/response DTOs)
```

Add to Exercise model:
- Writing-specific fields
- Speaking-specific fields
- Helper methods: `IsOfficialTest()`, `RequiresAIEvaluation()`

#### Task 4.2: Create AI Service Client
```go
services/exercise-service/internal/client/
└── ai_service_client.go
```

Methods:
- `EvaluateWriting()`
- `TranscribeSpeaking()`
- `EvaluateSpeaking()`

#### Task 4.3: Unified Submission Handler
Update `exercise_service.go`:
```go
func (s *ExerciseService) SubmitExercise(...) {
    switch exercise.SkillType {
    case "listening", "reading":
        return s.handleListeningReadingSubmission()
    case "writing":
        return s.handleWritingSubmission()
    case "speaking":
        return s.handleSpeakingSubmission()
    }
}
```

#### Task 4.4: Async Evaluation Logic
- Implement background processing for W/S
- Error handling and retry logic
- Status tracking in database
- Webhook/polling support

#### Task 4.5: User Service Integration
Update `recordToUserService()`:
- Detect official test vs practice
- Call appropriate endpoint
- Handle errors gracefully

**Testing**:
- Unit tests for each skill type
- Integration tests with mocked AI service
- End-to-end tests for full flow
- Load testing for async processing

**Deliverables**:
- ✅ All 4 skills supported
- ✅ AI client implemented
- ✅ Async evaluation working
- ✅ Tests passing
- ✅ Error handling robust

---

### Phase 5: AI Service Refactoring (6-8 hours)
**Goal**: Convert AI service to pure evaluation engine

#### Task 5.1: Remove Integration Code
Delete files:
- `internal/service/integration_handler.go`
- References to user-service client
- References to notification client

#### Task 5.2: Implement Pure APIs
Update `ai_service.go`:
- `EvaluateWriting()` - stateless
- `TranscribeSpeaking()` - stateless
- `EvaluateSpeaking()` - stateless

#### Task 5.3: Implement Caching
Create `cache_service.go`:
- SHA256 content hashing
- Cache lookup before OpenAI call
- Cache storage after evaluation
- Cache expiration management

#### Task 5.4: Update Handlers
Simplify handlers to pure request/response:
- No database writes
- No service integrations
- Just evaluation logic

**Testing**:
- Unit tests for evaluation logic
- Cache hit/miss tests
- Performance tests
- Cost calculation tests

**Deliverables**:
- ✅ AI service stateless
- ✅ Caching implemented
- ✅ Integration code removed
- ✅ Tests passing
- ✅ Performance improved

---

### Phase 6: Data Migration (4-5 hours)
**Goal**: Migrate existing data from ai_db to exercise_db

#### Task 6.1: Create Migration Scripts
```
scripts/data-migration/
├── migrate-writing-submissions.sql
├── migrate-speaking-submissions.sql
├── verify-migration.sql
└── README.md
```

#### Task 6.2: Migration Logic
1. Read from `ai_db.writing_submissions`
2. Create corresponding `exercise_db.exercises` (if not exists)
3. Insert into `exercise_db.exercise_submissions`
4. Copy evaluation data to `detailed_scores` JSONB
5. Verify data integrity
6. Create backup of original data

#### Task 6.3: Verification
- Count records before/after
- Sample data comparison
- Check foreign key relationships
- Verify JSONB data structure

**Testing**:
- Dry run on test database
- Rollback test
- Production migration rehearsal

**Deliverables**:
- ✅ Migration scripts tested
- ✅ Data migrated successfully
- ✅ Verification passed
- ✅ Backup created
- ✅ Old data archived

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
| Phase | Duration | Dependencies | Risk Level |
|-------|----------|--------------|------------|
| Phase 0: Preparation | 2 hours | None | Low |
| Phase 1: Database | 4-5 hours | Phase 0 | Medium |
| Phase 2: Shared Library | 4 hours | None | Low |
| Phase 3: User Service | 8-10 hours | Phase 1, 2 | Medium |
| Phase 4: Exercise Service | 10-12 hours | Phase 1, 2, 3 | High |
| Phase 5: AI Service | 6-8 hours | Phase 4 | Medium |
| Phase 6: Data Migration | 4-5 hours | Phase 1, 5 | High |
| Phase 7: Frontend | 6-8 hours | Phase 3, 4 | Low |
| Phase 8: Integration Testing | 4-6 hours | Phase 7 | Medium |
| Phase 9: Deployment | 4-6 hours | Phase 8 | High |

**Total**: 52-68 hours (~7-9 working days)

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

**Document Version**: 1.0  
**Last Updated**: November 6, 2025  
**Next Review**: After Phase 1 completion
