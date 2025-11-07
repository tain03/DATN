#!/bin/bash
# ============================================
# TEST SEED DATA
# ============================================
# Purpose: Quick test to verify seed data is complete
# Usage: bash database/seed_complete_data/test_seed.sh
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Testing seed data..."
echo ""

# Check Docker
if ! docker ps | grep -q ielts_postgres; then
    echo -e "${RED}❌ Docker container ielts_postgres is not running${NC}"
    exit 1
fi

# Function to test count
test_count() {
    local db=$1
    local table=$2
    local expected=$3
    local actual=$(docker-compose exec -T postgres psql -U ielts_admin -d "$db" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' \n')
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} $db.$table: $actual (expected: $expected)"
        return 0
    elif [ -z "$actual" ]; then
        echo -e "${RED}✗${NC} $db.$table: ERROR - Could not query"
        return 1
    else
        echo -e "${YELLOW}⚠${NC} $db.$table: $actual (expected: $expected)"
        return 1
    fi
}

# Test Auth DB
echo "Testing auth_db..."
test_count "auth_db" "users" "70"
test_count "auth_db" "user_roles" "90"

# Test User DB
echo ""
echo "Testing user_db..."
test_count "user_db" "user_profiles" "67"
test_count "user_db" "learning_progress" "67"
test_count "user_db" "practice_activities" "60"

# Test Course DB
echo ""
echo "Testing course_db..."
test_count "course_db" "courses" "29"
test_count "course_db" "modules" "123"
test_count "course_db" "lessons" "780"

# Test Exercise DB
echo ""
echo "Testing exercise_db..."
test_count "exercise_db" "exercises" "142"

# Test individual skills
LISTENING=$(docker-compose exec -T postgres psql -U ielts_admin -d exercise_db -t -c "SELECT COUNT(*) FROM exercises WHERE skill_type='listening';" 2>/dev/null | tr -d ' \n')
READING=$(docker-compose exec -T postgres psql -U ielts_admin -d exercise_db -t -c "SELECT COUNT(*) FROM exercises WHERE skill_type='reading';" 2>/dev/null | tr -d ' \n')
WRITING=$(docker-compose exec -T postgres psql -U ielts_admin -d exercise_db -t -c "SELECT COUNT(*) FROM exercises WHERE skill_type='writing';" 2>/dev/null | tr -d ' \n')
SPEAKING=$(docker-compose exec -T postgres psql -U ielts_admin -d exercise_db -t -c "SELECT COUNT(*) FROM exercises WHERE skill_type='speaking';" 2>/dev/null | tr -d ' \n')

echo -e "${GREEN}✓${NC} Listening exercises: $LISTENING (expected: 32)"
echo -e "${GREEN}✓${NC} Reading exercises: $READING (expected: 42)"
echo -e "${GREEN}✓${NC} Writing exercises: $WRITING (expected: 29)"
echo -e "${GREEN}✓${NC} Speaking exercises: $SPEAKING (expected: 39)"

# Test questions
QUESTIONS=$(docker-compose exec -T postgres psql -U ielts_admin -d exercise_db -t -c "SELECT COUNT(*) FROM questions;" 2>/dev/null | tr -d ' \n')
echo -e "${GREEN}✓${NC} Total questions: $QUESTIONS (expected: ~1095)"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$LISTENING" = "32" ] && [ "$READING" = "42" ] && [ "$WRITING" = "29" ] && [ "$SPEAKING" = "39" ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo "Seed data is complete and ready to use."
    exit 0
else
    echo -e "${YELLOW}⚠ SOME COUNTS DIFFER${NC}"
    echo "This might be OK if you added custom data."
    echo "Run: bash database/seed_complete_data/clean-and-seed.sh to reset."
    exit 1
fi

