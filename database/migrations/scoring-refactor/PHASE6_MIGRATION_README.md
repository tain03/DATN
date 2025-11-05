# Phase 6: Data Migration - README

## Overview

This phase migrates existing writing and speaking submissions from `ai_db` to `exercise_db`, consolidating all exercise attempts into a unified schema.

**Migration Path**: `ai_db` → `exercise_db`

## Current State

### Source Data (ai_db)
- **Writing submissions**: 41 records
- **Speaking submissions**: 34 records
- **Total**: 75 submissions with evaluations

### Target Schema (exercise_db)
- Table: `user_exercise_attempts`
- Extended with Writing/Speaking fields via migration `006_update_user_exercise_attempts.sql`

## Migration Files

| File | Purpose | Database |
|------|---------|----------|
| `008_migrate_writing_submissions.sql` | Migrate writing submissions & evaluations | exercise_db |
| `008_migrate_writing_submissions.rollback.sql` | Rollback writing migration | exercise_db |
| `009_migrate_speaking_submissions.sql` | Migrate speaking submissions & evaluations | exercise_db |
| `009_migrate_speaking_submissions.rollback.sql` | Rollback speaking migration | exercise_db |
| `010_verify_migration.sql` | Comprehensive verification checks | exercise_db |
| `run_phase6_migration.sh` | Automated migration execution script | Both |

## Prerequisites

✅ **Phase 1 migrations must be completed first**:
- `005_update_exercises_table.sql` - Adds `is_official_test`, `test_category`
- `006_update_user_exercise_attempts.sql` - Adds W/S fields to attempts table

✅ **dblink extension must be enabled** (migration 012):
```sql
CREATE EXTENSION IF NOT EXISTS dblink;
```

✅ **Database connections working**:
- `exercise_db` - Target database
- `ai_db` - Source database

## Migration Strategy

### Data Mapping

#### Writing Submissions
```
ai_db.writing_submissions + writing_evaluations
    ↓
exercise_db.user_exercise_attempts
```

**Field Mappings**:
- `id` → `id` (preserved)
- `user_id` → `user_id`
- `essay_text` → `essay_text`
- `word_count` → `word_count`
- `task_type` → `task_type`
- `task_prompt_text` → `prompt_text`
- `evaluation.overall_band_score` → `band_score`
- `evaluation.{4 criteria}` → `detailed_scores` (JSONB)

#### Speaking Submissions
```
ai_db.speaking_submissions + speaking_evaluations
    ↓
exercise_db.user_exercise_attempts
```

**Field Mappings**:
- `id` → `id` (preserved)
- `user_id` → `user_id`
- `audio_url` → `audio_url`
- `audio_duration_seconds` → `audio_duration_seconds`
- `transcript_text` → `transcript_text`
- `part_number` → `speaking_part_number`
- `evaluation.overall_band_score` → `band_score`
- `evaluation.{4 criteria}` → `detailed_scores` (JSONB)

### Default Values for Migrated Data

All migrated submissions will have:
- `is_official_test` = FALSE (all were practice)
- `official_test_result_id` = NULL
- `practice_activity_id` = NULL (can be created later if needed)
- `attempt_number` = 1 (assumed first attempt)
- `total_questions` = 0 (W/S don't have discrete questions)

## Execution Steps

### Option A: Automated Script (Recommended)

```bash
cd /Users/bisosad/DATN/database/migrations/scoring-refactor
./run_phase6_migration.sh
```

**The script will**:
1. ✅ Check database connectivity
2. 📊 Count original records
3. ⚠️  Warn if migration already run
4. 💾 Create backups (timestamped)
5. 🔄 Execute writing migration (008)
6. 🔄 Execute speaking migration (009)
7. ✔️  Run verification checks (010)
8. 📋 Display summary report

### Option B: Manual Execution

1. **Backup databases**:
```bash
pg_dump -U ielts_admin -d exercise_db -t user_exercise_attempts -F c -f exercise_db_backup.dump
pg_dump -U ielts_admin -d ai_db -t writing_submissions -t writing_evaluations -t speaking_submissions -t speaking_evaluations -F c -f ai_db_backup.dump
```

2. **Run migrations** (inside Docker container):
```bash
# Writing migration
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < 008_migrate_writing_submissions.sql

# Speaking migration
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < 009_migrate_speaking_submissions.sql

# Verification
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < 010_verify_migration.sql
```

3. **Review verification output** carefully

## Verification Checklist

After migration, the verification script checks:

- ✅ **Record counts match**
  - Writing: 41 expected
  - Speaking: 34 expected
  
- ✅ **Data integrity**
  - No NULL `user_id`
  - Band scores in valid range (0-9)
  - Required fields populated
  
- ✅ **Evaluation status consistency**
  - `band_score` NOT NULL → `evaluation_status` = 'completed'
  - `band_score` NULL → `evaluation_status` != 'completed'
  
- ✅ **JSONB structure**
  - Writing: 4 criteria (task_achievement, coherence_cohesion, lexical_resource, grammar_accuracy)
  - Speaking: 4 criteria (fluency_coherence, lexical_resource, grammar_accuracy, pronunciation)
  
- ✅ **User distribution**
  - All users have valid IDs
  - Submission counts per user reasonable

## Rollback Procedure

If migration fails or data is incorrect:

```bash
# Rollback speaking migration
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < 009_migrate_speaking_submissions.rollback.sql

# Rollback writing migration
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < 008_migrate_writing_submissions.rollback.sql

# Restore from backup if needed
pg_restore -U ielts_admin -d exercise_db -c exercise_db_backup.dump
```

**Note**: Original data in `ai_db` is never deleted by migration scripts.

## Post-Migration

### What Happens to ai_db?

**DO NOT DELETE YET!**

The migration preserves all data in `ai_db`:
- `writing_submissions` table intact
- `speaking_submissions` table intact
- All evaluations preserved

**Recommended approach**:
1. ✅ Run migration
2. ✅ Verify all data correct
3. ✅ Test application thoroughly (1-2 weeks)
4. ✅ Monitor for any issues
5. ⚠️  **Only then** consider archiving `ai_db` tables

### Archive Strategy (Future)

When ready to archive:

```sql
-- Rename tables (don't drop)
ALTER TABLE writing_submissions RENAME TO writing_submissions_archived;
ALTER TABLE writing_evaluations RENAME TO writing_evaluations_archived;
ALTER TABLE speaking_submissions RENAME TO speaking_submissions_archived;
ALTER TABLE speaking_evaluations RENAME TO speaking_evaluations_archived;

-- Add archive marker
COMMENT ON TABLE writing_submissions_archived IS 'Archived 2025-11-XX - Data migrated to exercise_db';
```

### Monitoring After Migration

**Check these metrics**:
- Application errors related to W/S submissions
- Score calculation accuracy
- User dashboard displays correctly
- AI evaluation workflow still works

**SQL queries to monitor**:
```sql
-- Check recent submissions after migration
SELECT 
    DATE(created_at) as date,
    COUNT(*) FILTER (WHERE essay_text IS NOT NULL) as writing,
    COUNT(*) FILTER (WHERE audio_url IS NOT NULL) as speaking
FROM user_exercise_attempts
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Check evaluation status distribution
SELECT 
    evaluation_status,
    COUNT(*) FILTER (WHERE essay_text IS NOT NULL) as writing_count,
    COUNT(*) FILTER (WHERE audio_url IS NOT NULL) as speaking_count
FROM user_exercise_attempts
WHERE essay_text IS NOT NULL OR audio_url IS NOT NULL
GROUP BY evaluation_status;
```

## Troubleshooting

### Issue: "duplicate_object" error for dblink

**Solution**: dblink connection already exists, this is normal. Migration will continue.

### Issue: Record count mismatch

**Possible causes**:
1. Migration run twice (check for duplicates)
2. New submissions created during migration
3. dblink connection issues

**Solution**:
```sql
-- Check for duplicates
SELECT id, COUNT(*) 
FROM user_exercise_attempts 
WHERE essay_text IS NOT NULL OR audio_url IS NOT NULL
GROUP BY id 
HAVING COUNT(*) > 1;

-- If duplicates found, rollback and re-run
```

### Issue: NULL band_scores after migration

**Cause**: Submissions in `ai_db` were pending evaluation

**Solution**: This is expected. These submissions will be picked up by the AI evaluation worker.

### Issue: Migration script permission denied

**Solution**:
```bash
chmod +x run_phase6_migration.sh
```

## Success Criteria

✅ Migration is successful when:

1. **Record counts match** (within reason for concurrent submissions)
2. **All integrity checks pass** in verification script
3. **No application errors** when viewing submissions
4. **Scores display correctly** in user dashboard
5. **New submissions work** after migration

## Migration Audit

All migrations are logged in `migration_audit` table:

```sql
SELECT * FROM migration_audit 
WHERE migration_name LIKE '%migrate%' 
ORDER BY migrated_at DESC;
```

## Timeline

- **Preparation**: 15 minutes (backups, checks)
- **Execution**: 5 minutes (migration runs)
- **Verification**: 10 minutes (check results)
- **Total**: ~30 minutes

## Support

If issues occur:
1. Check `migration_audit` table for error details
2. Review verification script output
3. Check Docker logs: `docker logs ielts_postgres`
4. Restore from backup if needed
5. Contact team lead

---

**Phase 6 Status**: Ready for execution  
**Last Updated**: November 6, 2025  
**Next Phase**: Phase 7 - Frontend Updates
