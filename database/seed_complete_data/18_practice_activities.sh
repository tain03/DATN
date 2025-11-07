#!/bin/bash
# ============================================================================
# PHASE 18: Seed Practice Activities
# ============================================================================

set -e  # Exit on error

echo "============================================="
echo "PHASE 18: SEEDING PRACTICE ACTIVITIES"
echo "============================================="

# Step 1: Export exercise attempts from exercise_db
echo "📤 Exporting exercise attempts from exercise_db..."
docker exec ielts_postgres psql -U ielts_admin -d exercise_db -c "
COPY (
    SELECT 
        uea.id,
        uea.user_id,
        uea.exercise_id,
        uea.score,
        uea.correct_answers,
        uea.total_questions,
        uea.time_spent_seconds,
        uea.started_at,
        uea.completed_at,
        uea.created_at,
        uea.updated_at,
        e.title,
        e.skill_type,
        e.test_category,
        e.difficulty,
        e.total_points,
        e.passing_score
    FROM user_exercise_attempts uea
    JOIN exercises e ON e.id = uea.exercise_id
    WHERE uea.status = 'completed' AND uea.completed_at IS NOT NULL
) TO '/tmp/exercise_attempts.csv' WITH CSV HEADER;
"

# Step 2: Run main seeding script
echo "📥 Importing to practice_activities..."
docker exec -i ielts_postgres psql -U ielts_admin < "$(dirname "$0")/18_practice_activities.sql"

# Step 3: Cleanup
echo "🧹 Cleaning up temporary files..."
docker exec ielts_postgres rm -f /tmp/exercise_attempts.csv

echo ""
echo "✅ PHASE 18 COMPLETE!"
echo "============================================="
