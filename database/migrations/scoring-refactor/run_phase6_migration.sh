#!/bin/bash

# ============================================
# Phase 6: Data Migration Execution Script
# ============================================
# Purpose: Migrate writing/speaking submissions from ai_db to exercise_db
# Author: DATN Team
# Date: November 6, 2025

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection parameters (from docker-compose.yml)
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="ielts_admin"
DB_PASSWORD="ielts_password_secure_2024"
EXERCISE_DB="exercise_db"
AI_DB="ai_db"

# Migration directory
MIGRATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to execute SQL in a database
execute_sql() {
    local db=$1
    local sql_file=$2
    
    log "Executing $sql_file in $db..."
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db -f "$sql_file" -v ON_ERROR_STOP=1
    
    if [ $? -eq 0 ]; then
        log_success "Successfully executed $sql_file"
        return 0
    else
        log_error "Failed to execute $sql_file"
        return 1
    fi
}

# Function to count records
count_records() {
    local db=$1
    local query=$2
    
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $db -t -c "$query" | xargs
}

# Header
echo ""
echo "============================================"
echo "  PHASE 6: DATA MIGRATION"
echo "  ai_db → exercise_db"
echo "============================================"
echo ""

# Step 1: Pre-migration checks
log "Step 1: Pre-migration checks..."

# Check if databases exist
log "Checking database connectivity..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $EXERCISE_DB -c "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_error "Cannot connect to $EXERCISE_DB"
    exit 1
fi

PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $AI_DB -c "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_error "Cannot connect to $AI_DB"
    exit 1
fi

log_success "Database connectivity verified"

# Count original records
log "Counting original records in ai_db..."
WRITING_COUNT=$(count_records $AI_DB "SELECT COUNT(*) FROM writing_submissions;")
SPEAKING_COUNT=$(count_records $AI_DB "SELECT COUNT(*) FROM speaking_submissions;")

log "Original data counts:"
log "  - Writing submissions: $WRITING_COUNT"
log "  - Speaking submissions: $SPEAKING_COUNT"
log "  - Total: $((WRITING_COUNT + SPEAKING_COUNT))"

# Check if migration already done
MIGRATED_WRITING=$(count_records $EXERCISE_DB "SELECT COUNT(*) FROM user_exercise_attempts WHERE essay_text IS NOT NULL;")
MIGRATED_SPEAKING=$(count_records $EXERCISE_DB "SELECT COUNT(*) FROM user_exercise_attempts WHERE audio_url IS NOT NULL;")

if [ "$MIGRATED_WRITING" -gt 0 ] || [ "$MIGRATED_SPEAKING" -gt 0 ]; then
    log_warning "Migration may have already been run!"
    log_warning "  - Writing submissions in exercise_db: $MIGRATED_WRITING"
    log_warning "  - Speaking submissions in exercise_db: $MIGRATED_SPEAKING"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Migration cancelled by user"
        exit 0
    fi
fi

# Step 2: Create backup
log ""
log "Step 2: Creating backups..."
BACKUP_DIR="$MIGRATION_DIR/backups/$(date +'%Y%m%d_%H%M%S')"
mkdir -p "$BACKUP_DIR"

log "Backing up exercise_db.user_exercise_attempts..."
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $EXERCISE_DB -t user_exercise_attempts -F c -f "$BACKUP_DIR/user_exercise_attempts.backup"
log_success "Backup created: $BACKUP_DIR/user_exercise_attempts.backup"

log "Backing up ai_db submissions tables..."
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $AI_DB -t writing_submissions -t writing_evaluations -t speaking_submissions -t speaking_evaluations -F c -f "$BACKUP_DIR/ai_db_submissions.backup"
log_success "Backup created: $BACKUP_DIR/ai_db_submissions.backup"

# Step 3: Run migrations
log ""
log "Step 3: Running data migrations..."

# Migrate writing submissions
log "Migrating writing submissions..."
if execute_sql $EXERCISE_DB "$MIGRATION_DIR/008_migrate_writing_submissions.sql"; then
    MIGRATED_WRITING_NEW=$(count_records $EXERCISE_DB "SELECT COUNT(*) FROM user_exercise_attempts WHERE essay_text IS NOT NULL;")
    log_success "Writing migration completed: $MIGRATED_WRITING_NEW records"
else
    log_error "Writing migration failed!"
    log "You can restore from: $BACKUP_DIR"
    exit 1
fi

# Migrate speaking submissions
log "Migrating speaking submissions..."
if execute_sql $EXERCISE_DB "$MIGRATION_DIR/009_migrate_speaking_submissions.sql"; then
    MIGRATED_SPEAKING_NEW=$(count_records $EXERCISE_DB "SELECT COUNT(*) FROM user_exercise_attempts WHERE audio_url IS NOT NULL;")
    log_success "Speaking migration completed: $MIGRATED_SPEAKING_NEW records"
else
    log_error "Speaking migration failed!"
    log "You can restore from: $BACKUP_DIR"
    exit 1
fi

# Step 4: Verification
log ""
log "Step 4: Running verification checks..."
if execute_sql $EXERCISE_DB "$MIGRATION_DIR/010_verify_migration.sql"; then
    log_success "Verification completed - check output above for details"
else
    log_warning "Verification script had issues - please review manually"
fi

# Step 5: Summary
log ""
log "============================================"
log "  MIGRATION SUMMARY"
log "============================================"
log ""
log "Original counts (ai_db):"
log "  - Writing: $WRITING_COUNT"
log "  - Speaking: $SPEAKING_COUNT"
log ""
log "Migrated counts (exercise_db):"
log "  - Writing: $MIGRATED_WRITING_NEW"
log "  - Speaking: $MIGRATED_SPEAKING_NEW"
log ""

if [ "$WRITING_COUNT" -eq "$MIGRATED_WRITING_NEW" ] && [ "$SPEAKING_COUNT" -eq "$MIGRATED_SPEAKING_NEW" ]; then
    log_success "✓ All records migrated successfully!"
else
    log_warning "! Record count mismatch detected"
    log_warning "  Please review the verification output above"
fi

log ""
log "Backups stored at: $BACKUP_DIR"
log ""
log_success "Migration completed!"
log ""
log "Next steps:"
log "  1. Review verification output above"
log "  2. Test application with migrated data"
log "  3. Monitor for any issues"
log "  4. If everything is OK, you can archive ai_db tables later"
log ""
