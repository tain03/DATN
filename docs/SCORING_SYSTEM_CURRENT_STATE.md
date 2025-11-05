# Scoring System Refactoring - Current State Documentation

**Date:** November 6, 2025  
**Branch:** feature/scoring-system-refactor  
**Phase:** 0 (Preparation)

## Database Backup

✅ **Backup Created:** `/Users/bisosad/DATN/database/backups/scoring-refactor-20251106-003555`

### Databases Backed Up:
- `user_db` - User profiles, progress tracking, skill statistics
- `exercise_db` - Exercise definitions and submissions  
- `ai_db` - AI evaluation results

### Restore Command:
```bash
./scripts/restore-databases.sh /Users/bisosad/DATN/database/backups/scoring-refactor-20251106-003555
```

## Current System Architecture

### Service Responsibilities (Before Refactoring):

**user-service:**
- Manages user profiles and authentication
- Tracks learning progress in `learning_progress` table
- Maintains skill statistics in `skill_statistics` table
- **Problem:** Official scores (listening_score, reading_score, etc.) never updated

**exercise-service:**
- Handles Listening and Reading exercise submissions
- Converts raw scores to band scores using conversion tables
- Calls user-service UpdateSkillStatistics() and UpdateProgress()
- **Problem:** Only handles 2 skills, no practice vs test distinction

**ai-service:**
- Evaluates Writing and Speaking submissions using GPT-4
- Manages submission storage for W/S
- Calls user-service to update statistics
- **Problem:** Too much responsibility - should only evaluate, not manage data

**course-service:**
- Manages course catalog, modules, lessons
- No involvement in scoring

### Current Database Schema Issues:

**learning_progress table:**
```sql
- listening_score DECIMAL(3,1)  -- Never updated
- reading_score DECIMAL(3,1)    -- Never updated  
- writing_score DECIMAL(3,1)    -- Never updated
- speaking_score DECIMAL(3,1)   -- Never updated
```

**skill_statistics table:**
- Tracks practice statistics but no separation from test scores
- Mixed data from both practice drills and official tests

**No distinction between:**
- Practice drills (for learning)
- Official tests (for certification)

## Target Architecture (After Refactoring)

### New Service Responsibilities:

**exercise-service (Central Hub):**
- Handle ALL 4 skills (Listening, Reading, Writing, Speaking)
- Manage all exercise submissions
- Coordinate with ai-service for W/S evaluation
- Call user-service with proper test vs practice distinction
- Single source of truth for submission data

**ai-service (Pure Evaluation):**
- ONLY evaluate Writing/Speaking content
- Stateless - no database operations
- Return evaluation results to exercise-service
- No direct communication with user-service

**user-service (Progress Tracker):**
- New endpoints: RecordTestResult(), RecordPracticeActivity()
- Update official scores ONLY from full tests
- Track practice separately
- Clear separation of concerns

### New Database Tables:

**official_test_results:**
- Stores ONLY official full test scores
- Source of truth for band scores displayed on certificates
- One row per completed official test

**practice_activities:**
- Tracks individual practice drills and part tests
- Separate from official scores
- Used for progress tracking and recommendations

**Updated learning_progress:**
- New fields: last_test_date, total_tests_taken
- Official scores now properly updated from test results

## Implementation Plan

Following the 9-phase plan in `docs/SCORING_SYSTEM_REFACTORING_PLAN.md`:

- [✅] Phase 0: Preparation & Setup (Current)
- [ ] Phase 1: Database Schema Updates
- [ ] Phase 2: Shared Library Implementation  
- [ ] Phase 3: User Service Updates
- [ ] Phase 4: Exercise Service Refactoring
- [ ] Phase 5: AI Service Simplification
- [ ] Phase 6: Frontend Updates
- [ ] Phase 7: Integration Testing
- [ ] Phase 8: Data Migration & Deployment

## Rollback Strategy

If any phase fails:

1. **Stop immediately** - Do not proceed to next phase
2. **Run restore script:**
   ```bash
   ./scripts/restore-databases.sh /Users/bisosad/DATN/database/backups/scoring-refactor-20251106-003555
   ```
3. **Revert code changes:**
   ```bash
   git checkout main
   git branch -D feature/scoring-system-refactor
   ```
4. **Restart services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Testing Environment

- **Local:** Development environment on macOS
- **Docker Services:** All running via docker-compose
- **Database:** PostgreSQL 15 (container: ielts_postgres)
- **Database User:** ielts_admin

### Running Services:
```
✅ ielts_postgres (healthy)
✅ ielts_api_gateway (healthy)
✅ ielts_user_service (healthy)
✅ ielts_ai_service (healthy)
⚠️  ielts_exercise_service (unhealthy)
⚠️  ielts_course_service (unhealthy)
⚠️  ielts_notification_service (unhealthy)
✅ ielts_rabbitmq (healthy)
✅ ielts_redis (healthy)
```

## Success Criteria

This refactoring will be considered successful when:

1. **Official Scores Working:**
   - listening_score, reading_score, writing_score, speaking_score properly updated
   - Only updated from completed official tests, not practice drills

2. **Clear Data Separation:**
   - official_test_results contains ONLY full test scores
   - practice_activities tracks individual practice sessions
   - Dashboard clearly shows "Official Band Score" vs "Practice Progress"

3. **Proper Architecture:**
   - exercise-service handles all 4 skills uniformly
   - ai-service is stateless evaluation engine
   - user-service is single source for progress data

4. **All Tests Pass:**
   - Unit tests for all new/modified functions
   - Integration tests for complete flows (all 4 skills)
   - Manual testing scenarios verified

5. **Backwards Compatibility:**
   - Existing data migrated successfully
   - No loss of historical progress data
   - Frontend displays correctly

## Notes

- Keep checklist updated: `docs/SCORING_SYSTEM_IMPLEMENTATION_CHECKLIST.md`
- Document any deviations from plan
- Test thoroughly after each phase before proceeding
- Seek approval before deployment to staging/production
