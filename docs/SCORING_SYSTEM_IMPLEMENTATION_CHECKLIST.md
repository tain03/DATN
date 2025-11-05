# ✅ SCORING SYSTEM REFACTORING - IMPLEMENTATION CHECKLIST

**Project**: IELTS Learning Platform Score Management Refactoring  
**Version**: 1.0  
**Date**: November 6, 2025  

---

## 📖 HOW TO USE THIS CHECKLIST

1. ✅ Check off items as you complete them
2. 📝 Add notes in the "Notes" column for important findings
3. ⚠️ Mark "BLOCKED" if you encounter issues
4. 🔄 Update status regularly
5. 🎯 Review with team lead before moving to next phase

**Status Codes**:
- ⬜ Not Started
- 🔄 In Progress
- ✅ Completed
- ⚠️ Blocked
- ❌ Failed (needs rework)

---

## PHASE 0: PREPARATION & SETUP

| Status | Task | Owner | Notes | Deadline |
|--------|------|-------|-------|----------|
| ⬜ | Create feature branch `feature/scoring-system-refactor` | Dev | | Day 0 |
| ⬜ | Backup all databases (user_db, exercise_db, ai_db) | DevOps | Location: | Day 0 |
| ⬜ | Export current database schemas to `/docs/backup/` | Dev | | Day 0 |
| ⬜ | Set up local testing environment | Dev | | Day 0 |
| ⬜ | Create rollback scripts for all migrations | Dev | Location: | Day 0 |
| ⬜ | Document current system behavior (baseline) | Dev | | Day 0 |
| ⬜ | Set up monitoring/logging for testing | Dev | | Day 0 |
| ⬜ | Review plan with team lead | Team | | Day 0 |

**Phase 0 Signoff**: __________ Date: __________

---

## PHASE 1: DATABASE SCHEMA UPDATES

### 1.1 User Service Database (user_db)

| Status | Task | SQL File | Rollback Ready | Notes |
|--------|------|----------|----------------|-------|
| ⬜ | Create `024_create_official_test_results.sql` | ✅ | ⬜ | |
| ⬜ | Create `025_create_practice_activities.sql` | ✅ | ⬜ | |
| ⬜ | Create `026_alter_learning_progress_add_test_tracking.sql` | ✅ | ⬜ | |
| ⬜ | Create `027_alter_skill_statistics_add_separated_metrics.sql` | ✅ | ⬜ | |
| ⬜ | Test migration on local database | | | |
| ⬜ | Verify all indexes created correctly | | | |
| ⬜ | Test all constraints working | | | |
| ⬜ | Test rollback script | | | |
| ⬜ | Run migration on staging database | | | |
| ⬜ | Verify data integrity on staging | | | |

**Verification Queries**:
```sql
-- Check table exists
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('official_test_results', 'practice_activities');

-- Check indexes
SELECT indexname FROM pg_indexes 
WHERE tablename = 'official_test_results';

-- Check constraints
SELECT conname FROM pg_constraint 
WHERE conrelid = 'official_test_results'::regclass;
```

### 1.2 Exercise Service Database (exercise_db)

| Status | Task | SQL File | Rollback Ready | Notes |
|--------|------|----------|----------------|-------|
| ⬜ | Create `005_alter_exercises_add_writing_speaking_fields.sql` | ✅ | ⬜ | |
| ⬜ | Create `006_alter_submissions_add_writing_speaking_fields.sql` | ✅ | ⬜ | |
| ⬜ | Test migration on local database | | | |
| ⬜ | Verify column types correct | | | |
| ⬜ | Test NULL constraints | | | |
| ⬜ | Test rollback script | | | |
| ⬜ | Run migration on staging database | | | |

**Verification Queries**:
```sql
-- Check new columns exist
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'exercises' 
  AND column_name IN ('writing_task_type', 'speaking_part_number', 'task_prompt_text');

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'exercise_submissions' 
  AND column_name IN ('essay_text', 'audio_url', 'transcript_text', 'evaluation_status');
```

### 1.3 AI Service Database (ai_db)

| Status | Task | SQL File | Rollback Ready | Notes |
|--------|------|----------|----------------|-------|
| ⬜ | Create `005_create_evaluation_cache_table.sql` | ✅ | ⬜ | |
| ⬜ | Test migration on local database | | | |
| ⬜ | Verify unique constraint on content_hash | | | |
| ⬜ | Test cache expiry index | | | |
| ⬜ | Test rollback script | | | |
| ⬜ | Run migration on staging database | | | |

**Phase 1 Signoff**: __________ Date: __________

---

## PHASE 2: SHARED LIBRARY

### 2.1 Create IELTS Package Structure

| Status | Task | File | Tests | Notes |
|--------|------|------|-------|-------|
| ⬜ | Create `shared/pkg/ielts/` directory | | | |
| ⬜ | Create `band_score.go` | ✅ | ⬜ | |
| ⬜ | Implement `ConvertListeningScore()` | ✅ | ⬜ | |
| ⬜ | Implement `ConvertReadingScore()` (Academic) | ✅ | ⬜ | |
| ⬜ | Implement `ConvertReadingScore()` (General) | ✅ | ⬜ | |
| ⬜ | Implement `CalculateWritingBand()` | ✅ | ⬜ | |
| ⬜ | Implement `CalculateSpeakingBand()` | ✅ | ⬜ | |
| ⬜ | Implement `CalculateOverallBand()` | ✅ | ⬜ | |
| ⬜ | Create `rounding.go` | ✅ | ⬜ | |
| ⬜ | Implement `RoundToIELTSBand()` | ✅ | ⬜ | |
| ⬜ | Create `validation.go` | ✅ | ⬜ | |
| ⬜ | Implement `ValidateBandScore()` | ✅ | ⬜ | |
| ⬜ | Create comprehensive unit tests | | ✅ | |
| ⬜ | Achieve >95% test coverage | | | Coverage: ___% |
| ⬜ | Create `README.md` with examples | ✅ | | |
| ⬜ | Update `shared/go.mod` | ✅ | | |

**Test Cases to Cover**:
- ✅ Listening: 0, 1, 10, 20, 30, 35, 39, 40 correct answers
- ✅ Reading Academic: Same range
- ✅ Reading General: Same range
- ✅ Writing: Various combinations of 4 criteria
- ✅ Speaking: Various combinations of 4 criteria
- ✅ Overall: All possible combinations
- ✅ Rounding: 6.125→6.0, 6.25→6.5, 6.375→6.5, 6.625→6.5, 6.75→7.0
- ✅ Edge cases: Negative numbers, >9, NULL values

**Phase 2 Signoff**: __________ Date: __________

---

## PHASE 3: USER SERVICE IMPLEMENTATION

### 3.1 Models

| Status | Task | File | Notes |
|--------|------|------|-------|
| ⬜ | Create `internal/models/official_test_result.go` | ✅ | |
| ⬜ | Create `internal/models/practice_activity.go` | ✅ | |
| ⬜ | Add JSONB struct tags for evaluation_criteria | ✅ | |
| ⬜ | Add validation tags | ✅ | |
| ⬜ | Create model tests | ✅ | |

### 3.2 Repository Layer

| Status | Task | Function | Tests | Notes |
|--------|------|----------|-------|-------|
| ⬜ | Implement `CreateOfficialTestResult()` | ✅ | ⬜ | |
| ⬜ | Implement `GetUserTestHistory()` | ✅ | ⬜ | Pagination support |
| ⬜ | Implement `GetUserTestStatistics()` | ✅ | ⬜ | |
| ⬜ | Implement `CreatePracticeActivity()` | ✅ | ⬜ | |
| ⬜ | Implement `GetUserPracticeActivities()` | ✅ | ⬜ | Pagination support |
| ⬜ | Implement `GetUserPracticeStatistics()` | ✅ | ⬜ | |
| ⬜ | Implement `UpdateLearningProgressWithTestScore()` | ✅ | ⬜ | Atomic update |
| ⬜ | Update `UpdateSkillStatistics()` to separate test/practice | ✅ | ⬜ | |
| ⬜ | Create comprehensive repository tests | | ✅ | |
| ⬜ | Test transaction handling | | ✅ | |
| ⬜ | Test error cases | | ✅ | |

### 3.3 Service Layer

| Status | Task | Function | Business Logic | Tests | Notes |
|--------|------|----------|----------------|-------|-------|
| ⬜ | Implement `RecordOfficialTestResult()` | ✅ | ✅ | ⬜ | |
| ⬜ | - Calculate band from raw score (L/R) | | ✅ | ⬜ | Use shared lib |
| ⬜ | - Use provided band (W/S) | | ✅ | ⬜ | |
| ⬜ | - Save to official_test_results | | ✅ | ⬜ | |
| ⬜ | - Update learning_progress.{skill}_score | | ✅ | ⬜ | |
| ⬜ | - Increment {skill}_tests_taken | | ✅ | ⬜ | |
| ⬜ | - Recalculate overall_score | | ✅ | ⬜ | |
| ⬜ | - Update skill_statistics | | ✅ | ⬜ | |
| ⬜ | - Update streak tracking | | ✅ | ⬜ | |
| ⬜ | - Check and award achievements | | ✅ | ⬜ | |
| ⬜ | Implement `RecordPracticeActivity()` | ✅ | ✅ | ⬜ | |
| ⬜ | - Save to practice_activities | | ✅ | ⬜ | |
| ⬜ | - Update skill_statistics (practice only) | | ✅ | ⬜ | |
| ⬜ | - Update exercises_completed counter | | ✅ | ⬜ | |
| ⬜ | - Update streak tracking | | ✅ | ⬜ | |
| ⬜ | - NOT update official scores | | ✅ | ⬜ | Critical! |
| ⬜ | Create service layer tests | | | ✅ | |
| ⬜ | Test all edge cases | | | ✅ | |

### 3.4 Handler Layer

| Status | Task | Endpoint | Request Validation | Error Handling | Tests | Notes |
|--------|------|----------|-------------------|----------------|-------|-------|
| ⬜ | Implement `RecordTestResultInternal()` | ✅ | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `RecordPracticeActivityInternal()` | ✅ | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `GetUserTestHistory()` | ✅ | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `GetUserPracticeStatistics()` | ✅ | ✅ | ✅ | ⬜ | |
| ⬜ | Add authentication/authorization | ✅ | | | | |
| ⬜ | Add rate limiting | ✅ | | | | |
| ⬜ | Add request logging | ✅ | | | | |
| ⬜ | Create handler tests | | | | ✅ | |
| ⬜ | Test with invalid inputs | | | | ✅ | |

### 3.5 Shared Client Update

| Status | Task | File | Notes |
|--------|------|------|-------|
| ⬜ | Add `RecordTestResult()` to client | ✅ | |
| ⬜ | Add `RecordPracticeActivity()` to client | ✅ | |
| ⬜ | Add `GetTestHistory()` to client | ✅ | |
| ⬜ | Add `GetPracticeStatistics()` to client | ✅ | |
| ⬜ | Add retry logic | ✅ | |
| ⬜ | Add timeout handling | ✅ | |
| ⬜ | Update client tests | ✅ | |

### 3.6 Integration Testing

| Status | Test Scenario | Expected Result | Actual Result | Notes |
|--------|--------------|-----------------|---------------|-------|
| ⬜ | Record listening test (35/40) | Score = 8.0, tests_taken += 1 | | |
| ⬜ | Record reading test (30/40, Academic) | Score = 7.0, tests_taken += 1 | | |
| ⬜ | Record writing test (7.0 band) | Score = 7.0, tests_taken += 1 | | |
| ⬜ | Record speaking test (7.5 band) | Score = 7.5, tests_taken += 1 | | |
| ⬜ | Overall score recalculation | (8.0+7.0+7.0+7.5)/4 = 7.5 | | |
| ⬜ | Record listening practice | Stats updated, official score unchanged | | |
| ⬜ | Get test history (L) | Returns all listening tests, sorted | | |
| ⬜ | Get practice stats (L) | Returns aggregated practice data | | |

**Phase 3 Signoff**: __________ Date: __________

---

## PHASE 4: EXERCISE SERVICE - WRITING/SPEAKING SUPPORT

### 4.1 Models Update

| Status | Task | Model | Fields Added | Notes |
|--------|------|-------|--------------|-------|
| ⬜ | Update `Exercise` model | ✅ | WritingTaskType, SpeakingPartNumber, TaskPromptText, TaskPromptID | |
| ⬜ | Update `ExerciseSubmission` model | ✅ | EssayText, WordCount, AudioURL, AudioDurationSeconds, TranscriptText, EvaluationStatus, DetailedScores | |
| ⬜ | Add `IsOfficialTest()` method | ✅ | | |
| ⬜ | Add `RequiresAIEvaluation()` method | ✅ | | |
| ⬜ | Update DTOs for W/S | ✅ | | |
| ⬜ | Add validation rules | ✅ | | |

### 4.2 AI Service Client

| Status | Task | File | Method | Tests | Notes |
|--------|------|------|--------|-------|-------|
| ⬜ | Create `internal/client/ai_service_client.go` | ✅ | | | |
| ⬜ | Implement `EvaluateWriting()` | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `TranscribeSpeaking()` | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `EvaluateSpeaking()` | ✅ | ✅ | ⬜ | |
| ⬜ | Add retry logic | ✅ | | ⬜ | Max 3 retries |
| ⬜ | Add timeout handling | ✅ | | ⬜ | 60s timeout |
| ⬜ | Add circuit breaker | ✅ | | ⬜ | Optional |
| ⬜ | Create client tests (mocked) | | | ✅ | |

### 4.3 Submission Handlers

| Status | Task | Handler | Skill | Logic Complete | Tests | Notes |
|--------|------|---------|-------|----------------|-------|-------|
| ⬜ | Update `SubmitExercise()` main router | ✅ | All | ✅ | ⬜ | |
| ⬜ | Implement `handleListeningReadingSubmission()` | ✅ | L/R | ✅ | ⬜ | Immediate grading |
| ⬜ | - Grade answers | | | ✅ | ⬜ | |
| ⬜ | - Convert to band score | | | ✅ | ⬜ | Use shared lib |
| ⬜ | - Save submission | | | ✅ | ⬜ | |
| ⬜ | - Call user-service (async) | | | ✅ | ⬜ | |
| ⬜ | - Return result immediately | | | ✅ | ⬜ | |
| ⬜ | Implement `handleWritingSubmission()` | ✅ | W | ✅ | ⬜ | Async evaluation |
| ⬜ | - Save submission (status: pending) | | | ✅ | ⬜ | |
| ⬜ | - Return submission_id immediately | | | ✅ | ⬜ | |
| ⬜ | - Start async evaluation goroutine | | | ✅ | ⬜ | |
| ⬜ | - Call AI service for evaluation | | | ✅ | ⬜ | |
| ⬜ | - Update submission with result | | | ✅ | ⬜ | |
| ⬜ | - Call user-service | | | ✅ | ⬜ | |
| ⬜ | - Send notification | | | ✅ | ⬜ | |
| ⬜ | Implement `handleSpeakingSubmission()` | ✅ | S | ✅ | ⬜ | Async transcribe + eval |
| ⬜ | - Save submission (status: processing) | | | ✅ | ⬜ | |
| ⬜ | - Return submission_id immediately | | | ✅ | ⬜ | |
| ⬜ | - Start async processing goroutine | | | ✅ | ⬜ | |
| ⬜ | - Call AI service for transcription | | | ✅ | ⬜ | |
| ⬜ | - Update submission with transcript | | | ✅ | ⬜ | |
| ⬜ | - Call AI service for evaluation | | | ✅ | ⬜ | |
| ⬜ | - Update submission with result | | | ✅ | ⬜ | |
| ⬜ | - Call user-service | | | ✅ | ⬜ | |
| ⬜ | - Send notification | | | ✅ | ⬜ | |

### 4.4 Error Handling & Recovery

| Status | Task | Scenario | Handling | Tests | Notes |
|--------|------|----------|----------|-------|-------|
| ⬜ | AI service unavailable | ✅ | Retry + fallback | ⬜ | |
| ⬜ | OpenAI rate limit exceeded | ✅ | Queue + retry | ⬜ | |
| ⬜ | Transcription failed | ✅ | Mark submission failed | ⬜ | |
| ⬜ | Evaluation failed | ✅ | Mark submission failed | ⬜ | |
| ⬜ | User-service call failed | ✅ | Retry + log | ⬜ | |
| ⬜ | Database error during async | ✅ | Rollback + log | ⬜ | |
| ⬜ | Panic in goroutine | ✅ | Recover + log | ⬜ | |

### 4.5 User Service Integration

| Status | Task | Function | Logic | Tests | Notes |
|--------|------|----------|-------|-------|-------|
| ⬜ | Update `recordToUserService()` | ✅ | ✅ | ⬜ | Unified for all skills |
| ⬜ | Detect official test vs practice | | ✅ | ⬜ | exercise_type check |
| ⬜ | Call RecordTestResult() for official | | ✅ | ⬜ | |
| ⬜ | Call RecordPracticeActivity() for practice | | ✅ | ⬜ | |
| ⬜ | Handle errors gracefully | | ✅ | ⬜ | Log but don't fail |
| ⬜ | Add retry logic | | ✅ | ⬜ | Max 3 retries |

### 4.6 Integration Testing

| Status | Test Case | Skill | Type | Expected | Actual | Notes |
|--------|-----------|-------|------|----------|--------|-------|
| ⬜ | Submit listening full test | L | Official | Immediate grade, score updated | | |
| ⬜ | Submit listening drill | L | Practice | Immediate grade, stats only | | |
| ⬜ | Submit reading full test (Academic) | R | Official | Immediate grade, score updated | | |
| ⬜ | Submit reading drill (General) | R | Practice | Immediate grade, stats only | | |
| ⬜ | Submit writing full test | W | Official | Async eval, score updated | | |
| ⬜ | Submit writing practice | W | Practice | Async eval, stats only | | |
| ⬜ | Submit speaking full test | S | Official | Transcribe+eval, score updated | | |
| ⬜ | Submit speaking practice | S | Practice | Transcribe+eval, stats only | | |
| ⬜ | Concurrent submissions (stress test) | All | Mixed | All processed correctly | | |
| ⬜ | AI service failure scenario | W/S | Both | Graceful failure handling | | |

**Phase 4 Signoff**: __________ Date: __________

---

## PHASE 5: AI SERVICE REFACTORING

### 5.1 Remove Integration Code

| Status | Task | File/Function | Notes |
|--------|------|---------------|-------|
| ⬜ | Delete `internal/service/integration_handler.go` | ✅ | Backup first |
| ⬜ | Remove user-service client imports | ✅ | |
| ⬜ | Remove notification client imports | ✅ | |
| ⬜ | Remove `HandleWritingEvaluationCompletion()` | ✅ | |
| ⬜ | Remove `HandleSpeakingEvaluationCompletion()` | ✅ | |
| ⬜ | Update service initialization | ✅ | No more clients |
| ⬜ | Clean up unused dependencies | ✅ | go.mod |

### 5.2 Implement Pure APIs

| Status | Task | Endpoint | Stateless | Tests | Notes |
|--------|------|----------|-----------|-------|-------|
| ⬜ | Update `EvaluateWriting()` to stateless | ✅ | ✅ | ⬜ | No DB writes |
| ⬜ | Update `TranscribeSpeaking()` to stateless | ✅ | ✅ | ⬜ | No DB writes |
| ⬜ | Update `EvaluateSpeaking()` to stateless | ✅ | ✅ | ⬜ | No DB writes |
| ⬜ | Remove all database write operations | ✅ | | | |
| ⬜ | Remove all service integrations | ✅ | | | |
| ⬜ | Verify pure request/response | ✅ | | | |

### 5.3 Implement Caching

| Status | Task | Function | Logic | Tests | Notes |
|--------|------|----------|-------|-------|-------|
| ⬜ | Create `cache_service.go` | ✅ | | | |
| ⬜ | Implement `generateContentHash()` | ✅ | ✅ | ⬜ | SHA256 |
| ⬜ | Implement `checkCache()` | ✅ | ✅ | ⬜ | |
| ⬜ | Implement `saveCache()` | ✅ | ✅ | ⬜ | |
| ⬜ | Implement cache expiry logic | ✅ | ✅ | ⬜ | 7 days default |
| ⬜ | Add cache hit/miss logging | ✅ | | | |
| ⬜ | Add cache statistics endpoint | ✅ | | | Optional |
| ⬜ | Test cache hit scenario | | | ✅ | Should skip OpenAI |
| ⬜ | Test cache miss scenario | | | ✅ | Should call OpenAI |
| ⬜ | Test cache expiry | | | ✅ | |

### 5.4 Performance Testing

| Status | Test | Metric | Target | Actual | Notes |
|--------|------|--------|--------|--------|-------|
| ⬜ | Writing evaluation (cache miss) | Response time | <10s | | OpenAI call |
| ⬜ | Writing evaluation (cache hit) | Response time | <100ms | | DB lookup |
| ⬜ | Speaking transcription | Response time | <5s | | Whisper API |
| ⬜ | Speaking evaluation | Response time | <10s | | OpenAI call |
| ⬜ | Concurrent requests (10) | Throughput | All complete | | |
| ⬜ | Cache hit rate | Percentage | >30% | | After 1 week |

**Phase 5 Signoff**: __________ Date: __________

---

## PHASE 6: DATA MIGRATION

### 6.1 Preparation

| Status | Task | Notes |
|--------|------|-------|
| ⬜ | Create full backup of ai_db | Location: |
| ⬜ | Create full backup of exercise_db | Location: |
| ⬜ | Export writing_submissions to CSV | Count: |
| ⬜ | Export speaking_submissions to CSV | Count: |
| ⬜ | Document current data statistics | |
| ⬜ | Create dry-run test database | |

### 6.2 Migration Scripts

| Status | Task | Script | Tested | Notes |
|--------|------|--------|--------|-------|
| ⬜ | Create `migrate-writing-submissions.sql` | ✅ | ⬜ | |
| ⬜ | Create `migrate-speaking-submissions.sql` | ✅ | ⬜ | |
| ⬜ | Create `verify-migration.sql` | ✅ | ⬜ | |
| ⬜ | Create `rollback-migration.sql` | ✅ | ⬜ | |
| ⬜ | Test on dry-run database | | ✅ | |
| ⬜ | Verify record counts match | | ✅ | |
| ⬜ | Verify data integrity | | ✅ | |
| ⬜ | Test rollback on dry-run | | ✅ | |

### 6.3 Migration Execution

| Status | Task | Before Count | After Count | Verified | Notes |
|--------|------|--------------|-------------|----------|-------|
| ⬜ | Announce maintenance window | | | | 2 hours |
| ⬜ | Put system in read-only mode | | | | |
| ⬜ | Run writing submissions migration | | | ⬜ | |
| ⬜ | Verify writing data | | | ⬜ | |
| ⬜ | Run speaking submissions migration | | | ⬜ | |
| ⬜ | Verify speaking data | | | ⬜ | |
| ⬜ | Sample random records for accuracy | | | ⬜ | Check 100 records |
| ⬜ | Verify foreign key relationships | | | ⬜ | |
| ⬜ | Archive old ai_db tables | | | ⬜ | Don't drop yet |
| ⬜ | Resume system operations | | | | |
| ⬜ | Monitor for issues | | | | 24 hours |

### 6.4 Post-Migration Verification

| Status | Check | SQL Query | Result | Notes |
|--------|-------|-----------|--------|-------|
| ⬜ | Total submissions count matches | `SELECT COUNT(*) FROM exercise_submissions` | | |
| ⬜ | Writing submissions migrated | `WHERE essay_text IS NOT NULL` | | |
| ⬜ | Speaking submissions migrated | `WHERE audio_url IS NOT NULL` | | |
| ⬜ | All user_ids valid | Join with user_profiles | | |
| ⬜ | All evaluation data present | Check detailed_scores JSONB | | |
| ⬜ | No NULL in required fields | Check constraints | | |
| ⬜ | Indexes functioning | EXPLAIN ANALYZE queries | | |

**Phase 6 Signoff**: __________ Date: __________

---

## PHASE 7: FRONTEND UPDATES

### 7.1 API Client Updates

| Status | Task | File | Functions | Tests | Notes |
|--------|------|------|-----------|-------|-------|
| ⬜ | Update `lib/api/progress.ts` | ✅ | getOfficialScores, getTestHistory, getPracticeStatistics | ⬜ | |
| ⬜ | Update `lib/api/exercises.ts` | ✅ | submitExercise (all 4 skills) | ⬜ | |
| ⬜ | Create `lib/api/tests.ts` | ✅ | pollSubmissionResult, getTestResult | ⬜ | |
| ⬜ | Implement polling mechanism | ✅ | | ⬜ | For W/S async |
| ⬜ | Add error handling | ✅ | | ⬜ | |
| ⬜ | Add loading states | ✅ | | ⬜ | |

### 7.2 New Components

| Status | Component | File | Features | Tests | Notes |
|--------|-----------|------|----------|-------|-------|
| ⬜ | OfficialScoreCard | ✅ | Display official test scores | ⬜ | |
| ⬜ | PracticeStatsCard | ✅ | Display practice statistics | ⬜ | |
| ⬜ | TestHistoryChart | ✅ | Line chart of score progress | ⬜ | |
| ⬜ | TestHistoryTable | ✅ | Detailed test history table | ⬜ | |
| ⬜ | SubmissionPolling | ✅ | Polling UI for W/S evaluation | ⬜ | |
| ⬜ | ScoreExplanation | ✅ | Help text and tooltips | ⬜ | |

### 7.3 Dashboard Refactor

| Status | Task | Component | Notes |
|--------|------|-----------|-------|
| ⬜ | Update `app/dashboard/page.tsx` | ✅ | |
| ⬜ | Add tabs: Official Scores, Practice, History, Activity | ✅ | |
| ⬜ | Update ProgressChart to use official scores | ✅ | |
| ⬜ | Add separate practice chart | ✅ | |
| ⬜ | Update SkillProgressCard | ✅ | Show both official and practice |
| ⬜ | Add tooltips explaining score system | ✅ | |
| ⬜ | Mobile responsiveness | ✅ | |

### 7.4 Exercise Submission Flow

| Status | Task | Skill | Notes |
|--------|------|-------|-------|
| ⬜ | Update listening submission UI | L | |
| ⬜ | Update reading submission UI | R | |
| ⬜ | Update writing submission UI | W | Add polling |
| ⬜ | Update speaking submission UI | S | Add audio upload + polling |
| ⬜ | Add loading spinners | All | |
| ⬜ | Add progress indicators | W/S | |
| ⬜ | Add error messages | All | |
| ⬜ | Add success notifications | All | |

### 7.5 Testing

| Status | Test Type | Coverage | Status | Notes |
|--------|-----------|----------|--------|-------|
| ⬜ | Component unit tests | >80% | | Jest |
| ⬜ | Integration tests | Key flows | | React Testing Library |
| ⬜ | E2E tests | Critical paths | | Playwright |
| ⬜ | Mobile testing | All breakpoints | | Chrome DevTools |
| ⬜ | Accessibility testing | WCAG AA | | axe-core |

**Phase 7 Signoff**: __________ Date: __________

---

## PHASE 8: INTEGRATION TESTING

### 8.1 End-to-End Test Scenarios

| Status | Scenario | Steps | Expected Result | Actual Result | Pass/Fail |
|--------|----------|-------|-----------------|---------------|-----------|
| ⬜ | Listening Full Test | Submit → Check Dashboard | Official score updated | | |
| ⬜ | Listening Practice | Submit → Check Dashboard | Practice stats updated, official unchanged | | |
| ⬜ | Reading Full Test (Academic) | Submit → Check Dashboard | Official score updated | | |
| ⬜ | Reading Practice (General) | Submit → Check Dashboard | Practice stats updated, official unchanged | | |
| ⬜ | Writing Full Test | Submit → Wait → Check Dashboard | Official score updated after ~30s | | |
| ⬜ | Writing Practice | Submit → Wait → Check Dashboard | Practice stats updated, official unchanged | | |
| ⬜ | Speaking Full Test | Upload → Wait → Check Dashboard | Official score updated after ~60s | | |
| ⬜ | Speaking Practice | Upload → Wait → Check Dashboard | Practice stats updated, official unchanged | | |
| ⬜ | Mixed Activities (5 drills + 1 test) | Multiple submits → Dashboard | Official = test, Practice avg = drills | | |
| ⬜ | Overall Score Calculation | Do all 4 skills tests → Dashboard | Overall = (L+R+W+S)/4 rounded | | |

### 8.2 Performance Testing

| Status | Test | Load | Response Time | Throughput | Pass/Fail | Notes |
|--------|------|------|---------------|------------|-----------|-------|
| ⬜ | L/R submission | 100 concurrent | <500ms | >200 rps | | |
| ⬜ | W submission | 50 concurrent | <1s (async) | >50 rps | | |
| ⬜ | S submission | 20 concurrent | <2s (async) | >10 rps | | |
| ⬜ | Dashboard load | 100 concurrent | <2s | >50 rps | | |
| ⬜ | Test history API | 50 concurrent | <300ms | >100 rps | | |
| ⬜ | Database queries | All endpoints | <100ms | N/A | | Check EXPLAIN |

### 8.3 Error Handling

| Status | Error Scenario | Expected Behavior | Verified | Notes |
|--------|----------------|-------------------|----------|-------|
| ⬜ | AI service down | Graceful error, retry, notification | ⬜ | |
| ⬜ | Database connection lost | Retry, fallback, log | ⬜ | |
| ⬜ | Invalid submission data | Validation error, clear message | ⬜ | |
| ⬜ | User not authenticated | 401 error, redirect to login | ⬜ | |
| ⬜ | Rate limit exceeded | 429 error, retry-after header | ⬜ | |
| ⬜ | Network timeout | Timeout error, retry option | ⬜ | |

**Phase 8 Signoff**: __________ Date: __________

---

## PHASE 9: DEPLOYMENT & MONITORING

### 9.1 Pre-Deployment Checklist

| Status | Item | Verified | Notes |
|--------|------|----------|-------|
| ⬜ | All tests passing (unit, integration, E2E) | ⬜ | |
| ⬜ | Code review completed | ⬜ | Reviewer: |
| ⬜ | Documentation updated | ⬜ | |
| ⬜ | Changelog created | ⬜ | |
| ⬜ | Migration scripts tested | ⬜ | |
| ⬜ | Rollback plan documented | ⬜ | |
| ⬜ | Monitoring setup completed | ⬜ | |
| ⬜ | Alerts configured | ⬜ | |
| ⬜ | Backup verified | ⬜ | |
| ⬜ | Stakeholders notified | ⬜ | |

### 9.2 Deployment Execution

| Status | Task | Time | Status | Notes |
|--------|------|------|--------|-------|
| ⬜ | Deploy user-service to staging | | | |
| ⬜ | Deploy exercise-service to staging | | | |
| ⬜ | Deploy ai-service to staging | | | |
| ⬜ | Deploy frontend to staging | | | |
| ⬜ | Run smoke tests on staging | | | |
| ⬜ | Deploy user-service to production | | | |
| ⬜ | Run database migrations | | | |
| ⬜ | Deploy exercise-service to production | | | |
| ⬜ | Deploy ai-service to production | | | |
| ⬜ | Deploy frontend to production | | | |
| ⬜ | Monitor for 1 hour | | | |
| ⬜ | Gradual traffic ramp-up (10% → 50% → 100%) | | | |

### 9.3 Post-Deployment Monitoring (24 hours)

| Status | Metric | Target | Hour 1 | Hour 6 | Hour 12 | Hour 24 | Status |
|--------|--------|--------|--------|--------|---------|---------|--------|
| ⬜ | API response time (p95) | <500ms | | | | | |
| ⬜ | Error rate | <1% | | | | | |
| ⬜ | Database CPU | <70% | | | | | |
| ⬜ | Database connections | <80% pool | | | | | |
| ⬜ | AI service call success rate | >95% | | | | | |
| ⬜ | User-facing errors | 0 critical | | | | | |
| ⬜ | Cache hit rate | >20% | | | | | |

### 9.4 Rollback Triggers

| Status | Condition | Action Taken | Time | Notes |
|--------|-----------|--------------|------|-------|
| ⬜ | Error rate >5% | | | |
| ⬜ | Critical bug reported | | | |
| ⬜ | Data integrity issue | | | |
| ⬜ | Performance degradation >50% | | | |
| ⬜ | User-facing service down | | | |

**Phase 9 Signoff**: __________ Date: __________

---

## FINAL VERIFICATION

### System Health Check

| Status | Check | Result | Notes |
|--------|-------|--------|-------|
| ⬜ | All services running | | |
| ⬜ | All databases accessible | | |
| ⬜ | All API endpoints responding | | |
| ⬜ | Frontend loading correctly | | |
| ⬜ | User authentication working | | |
| ⬜ | Scoring system accurate | | |
| ⬜ | Dashboard displaying correctly | | |
| ⬜ | No error spikes in logs | | |

### Success Criteria Verification

| Status | Criteria | Target | Actual | Pass/Fail |
|--------|----------|--------|--------|-----------|
| ⬜ | Official scores updated correctly | 100% | | |
| ⬜ | Practice activities tracked separately | 100% | | |
| ⬜ | Test vs practice distinction clear | User survey | | |
| ⬜ | No data loss | 0 records | | |
| ⬜ | API response time | <500ms p95 | | |
| ⬜ | Error rate | <1% | | |
| ⬜ | User satisfaction | >80% positive | | |

---

## 📝 NOTES & ISSUES LOG

### Issues Encountered

| Date | Phase | Issue | Resolution | Time Lost |
|------|-------|-------|------------|-----------|
| | | | | |

### Important Decisions

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| | | | |

### Lessons Learned

| Area | Lesson | Action Item |
|------|--------|-------------|
| | | |

---

## ✅ PROJECT SIGN-OFF

### Phase Completions

- [ ] Phase 0: Preparation __________ (Date)
- [ ] Phase 1: Database __________ (Date)
- [ ] Phase 2: Shared Library __________ (Date)
- [ ] Phase 3: User Service __________ (Date)
- [ ] Phase 4: Exercise Service __________ (Date)
- [ ] Phase 5: AI Service __________ (Date)
- [ ] Phase 6: Data Migration __________ (Date)
- [ ] Phase 7: Frontend __________ (Date)
- [ ] Phase 8: Integration Testing __________ (Date)
- [ ] Phase 9: Deployment __________ (Date)

### Final Sign-Off

**Developer**: ________________________ Date: __________

**Tech Lead**: ________________________ Date: __________

**Product Manager**: __________________ Date: __________

**QA Lead**: __________________________ Date: __________

---

**Project Status**: ⬜ Planning | ⬜ In Progress | ⬜ Testing | ⬜ Deployed | ⬜ Complete

**Document Version**: 1.0  
**Last Updated**: November 6, 2025  
**Next Review**: After each phase completion
