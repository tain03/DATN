#!/bin/bash

# ============================================
# SEED DATA VALIDATION AND FIX SCRIPT
# ============================================
# Purpose: Apply all data fixes and validate database integrity
# Date: 2025-11-07
# Author: IELTS Platform Backend Team
# ============================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}IELTS Platform - Seed Data Fix Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-ielts_admin}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-ielts_secure_password_2025}"

# Database names
AUTH_DB="auth_db"
USER_DB="user_db"
COURSE_DB="course_db"
EXERCISE_DB="exercise_db"
AI_DB="ai_db"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "  Host: ${DB_HOST}:${DB_PORT}"
echo -e "  User: ${POSTGRES_USER}"
echo -e "  Script Dir: ${SCRIPT_DIR}"
echo ""

# Function to execute SQL file
execute_sql() {
    local db_name=$1
    local sql_file=$2
    local description=$3
    
    echo -e "${BLUE}📄 ${description}${NC}"
    echo -e "  Database: ${db_name}"
    echo -e "  File: $(basename ${sql_file})"
    
    if [ ! -f "$sql_file" ]; then
        echo -e "${RED}  ❌ File not found: ${sql_file}${NC}"
        return 1
    fi
    
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $db_name -f "$sql_file" 2>&1 | while read line; do
        if [[ $line == WARNING* ]]; then
            echo -e "${YELLOW}  ⚠️  $line${NC}"
        elif [[ $line == ERROR* ]] || [[ $line == FATAL* ]]; then
            echo -e "${RED}  ❌ $line${NC}"
        elif [[ $line == NOTICE* ]]; then
            if [[ $line == *"✓"* ]]; then
                echo -e "${GREEN}  $line${NC}"
            else
                echo -e "  $line"
            fi
        else
            echo "  $line"
        fi
    done
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Success${NC}"
        return 0
    else
        echo -e "${RED}  ❌ Failed${NC}"
        return 1
    fi
}

# ============================================
# STEP 1: FIX EXERCISES (CRITICAL)
# ============================================
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 1: Fix Exercise Constraints${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

if execute_sql "$EXERCISE_DB" "${SCRIPT_DIR}/03_exercises_FIXED.sql" "Fixing Writing & Speaking exercises with required fields"; then
    echo -e "${GREEN}✅ Exercise fixes applied successfully${NC}\n"
else
    echo -e "${RED}❌ Failed to fix exercises${NC}\n"
    exit 1
fi

# ============================================
# STEP 2: FIX LEARNING PROGRESS
# ============================================
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 2: Fix Learning Progress & Band Scores${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

if execute_sql "$USER_DB" "${SCRIPT_DIR}/02_learning_progress_FIXED.sql" "Fixing band scores and creating missing records"; then
    echo -e "${GREEN}✅ Learning progress fixes applied successfully${NC}\n"
else
    echo -e "${RED}❌ Failed to fix learning progress${NC}\n"
    exit 1
fi

# ============================================
# STEP 3: VALIDATION QUERIES
# ============================================
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 3: Running Validation Checks${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

# Check 1: Writing exercises
echo -e "${BLUE}🔍 Checking Writing exercises...${NC}"
INVALID_WRITING=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $EXERCISE_DB -t -c "
SELECT COUNT(*) FROM exercises 
WHERE skill_type = 'writing' 
  AND (writing_task_type IS NULL OR writing_prompt_text IS NULL);
" | tr -d ' ')

if [ "$INVALID_WRITING" -eq 0 ]; then
    echo -e "${GREEN}✅ All writing exercises have required fields${NC}\n"
else
    echo -e "${RED}❌ Found $INVALID_WRITING writing exercises with missing fields${NC}\n"
fi

# Check 2: Speaking exercises
echo -e "${BLUE}🔍 Checking Speaking exercises...${NC}"
INVALID_SPEAKING=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $EXERCISE_DB -t -c "
SELECT COUNT(*) FROM exercises 
WHERE skill_type = 'speaking' 
  AND (speaking_part_number IS NULL OR speaking_prompt_text IS NULL);
" | tr -d ' ')

if [ "$INVALID_SPEAKING" -eq 0 ]; then
    echo -e "${GREEN}✅ All speaking exercises have required fields${NC}\n"
else
    echo -e "${RED}❌ Found $INVALID_SPEAKING speaking exercises with missing fields${NC}\n"
fi

# Check 3: Reading exercises
echo -e "${BLUE}🔍 Checking Reading exercises...${NC}"
INVALID_READING=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $EXERCISE_DB -t -c "
SELECT COUNT(*) FROM exercises 
WHERE skill_type = 'reading' 
  AND ielts_test_type IS NULL;
" | tr -d ' ')

if [ "$INVALID_READING" -eq 0 ]; then
    echo -e "${GREEN}✅ All reading exercises have ielts_test_type${NC}\n"
else
    echo -e "${RED}❌ Found $INVALID_READING reading exercises without ielts_test_type${NC}\n"
fi

# Check 4: Band scores
echo -e "${BLUE}🔍 Checking Band scores in learning_progress...${NC}"
INVALID_SCORES=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $USER_DB -t -c "
SELECT COUNT(*) FROM learning_progress 
WHERE (listening_score IS NOT NULL AND listening_score NOT BETWEEN 0 AND 9)
   OR (reading_score IS NOT NULL AND reading_score NOT BETWEEN 0 AND 9)
   OR (writing_score IS NOT NULL AND writing_score NOT BETWEEN 0 AND 9)
   OR (speaking_score IS NOT NULL AND speaking_score NOT BETWEEN 0 AND 9)
   OR (overall_score IS NOT NULL AND overall_score NOT BETWEEN 0 AND 9);
" | tr -d ' ')

if [ "$INVALID_SCORES" -eq 0 ]; then
    echo -e "${GREEN}✅ All band scores are within valid range (0.0-9.0)${NC}\n"
else
    echo -e "${RED}❌ Found $INVALID_SCORES records with invalid band scores${NC}\n"
fi

# Check 5: User profiles consistency
echo -e "${BLUE}🔍 Checking User profiles consistency...${NC}"
MISSING_PROGRESS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $USER_DB -t -c "
SELECT COUNT(*) FROM user_profiles up 
WHERE NOT EXISTS (
    SELECT 1 FROM learning_progress lp WHERE lp.user_id = up.user_id
);
" | tr -d ' ')

if [ "$MISSING_PROGRESS" -eq 0 ]; then
    echo -e "${GREEN}✅ All users have learning_progress records${NC}\n"
else
    echo -e "${RED}❌ Found $MISSING_PROGRESS users without learning_progress${NC}\n"
fi

# ============================================
# STEP 4: STATISTICS
# ============================================
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}STEP 4: Database Statistics${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

# Exercise counts by type
echo -e "${BLUE}📊 Exercise Statistics:${NC}"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $EXERCISE_DB -c "
SELECT 
    skill_type,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE is_published = true) as published,
    COUNT(*) FILTER (WHERE is_free = true) as free
FROM exercises
GROUP BY skill_type
ORDER BY skill_type;
"

# User statistics
echo -e "\n${BLUE}📊 User Statistics:${NC}"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGRES_USER -d $USER_DB -c "
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE listening_score IS NOT NULL) as with_listening_score,
    COUNT(*) FILTER (WHERE overall_score IS NOT NULL) as with_overall_score,
    ROUND(AVG(overall_score), 1) as avg_overall_score
FROM learning_progress;
"

# ============================================
# FINAL SUMMARY
# ============================================
echo -e "\n${YELLOW}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}Summary${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════${NC}\n"

TOTAL_ISSUES=$((INVALID_WRITING + INVALID_SPEAKING + INVALID_READING + INVALID_SCORES + MISSING_PROGRESS))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ All validation checks passed!${NC}"
    echo -e "${GREEN}✅ Database is ready for use${NC}\n"
    exit 0
else
    echo -e "${RED}❌ Found $TOTAL_ISSUES validation issues${NC}"
    echo -e "${YELLOW}⚠️  Please review the errors above and run fixes again${NC}\n"
    exit 1
fi
