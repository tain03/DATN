#!/bin/bash

# Backup script for scoring system refactoring
# Created: $(date +"%Y-%m-%d %H:%M:%S")

BACKUP_DIR="/Users/bisosad/DATN/database/backups/scoring-refactor-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Starting database backup to $BACKUP_DIR"

# Backup user_db
echo "Backing up user_db..."
docker exec -i ielts_postgres pg_dump -U ielts_admin user_db > "$BACKUP_DIR/user_db_backup.sql"
if [ $? -eq 0 ]; then
    echo "✅ user_db backed up successfully"
else
    echo "❌ Failed to backup user_db"
    exit 1
fi

# Backup exercise_db
echo "Backing up exercise_db..."
docker exec -i ielts_postgres pg_dump -U ielts_admin exercise_db > "$BACKUP_DIR/exercise_db_backup.sql"
if [ $? -eq 0 ]; then
    echo "✅ exercise_db backed up successfully"
else
    echo "❌ Failed to backup exercise_db"
    exit 1
fi

# Backup ai_db
echo "Backing up ai_db..."
docker exec -i ielts_postgres pg_dump -U ielts_admin ai_db > "$BACKUP_DIR/ai_db_backup.sql"
if [ $? -eq 0 ]; then
    echo "✅ ai_db backed up successfully"
else
    echo "❌ Failed to backup ai_db"
    exit 1
fi

# Create backup metadata
cat > "$BACKUP_DIR/backup_metadata.txt" <<EOF
Backup Date: $(date +"%Y-%m-%d %H:%M:%S")
Purpose: Scoring System Refactoring - Phase 0
Branch: $(git branch --show-current)
Commit: $(git rev-parse HEAD)

Databases backed up:
- user_db
- exercise_db
- ai_db

Restore commands:
docker exec -i ielts_postgres psql -U ielts_admin -d user_db < user_db_backup.sql
docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < exercise_db_backup.sql
docker exec -i ielts_postgres psql -U ielts_admin -d ai_db < ai_db_backup.sql
EOF

echo ""
echo "✅ All databases backed up successfully!"
echo "📁 Backup location: $BACKUP_DIR"
echo ""
echo "To restore, run:"
echo "  cd $BACKUP_DIR"
echo "  docker exec -i postgres psql -U postgres -d user_db < user_db_backup.sql"
echo "  docker exec -i postgres psql -U postgres -d exercise_db < exercise_db_backup.sql"
echo "  docker exec -i postgres psql -U postgres -d ai_db < ai_db_backup.sql"
