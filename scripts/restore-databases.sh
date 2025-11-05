#!/bin/bash

# Restore script for scoring system refactoring rollback
# Usage: ./restore-databases.sh <backup_directory>

if [ -z "$1" ]; then
    echo "❌ Error: Backup directory path required"
    echo "Usage: ./restore-databases.sh <backup_directory>"
    echo ""
    echo "Available backups:"
    ls -la /Users/bisosad/DATN/database/backups/ | grep scoring-refactor
    exit 1
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Error: Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

echo "⚠️  WARNING: This will restore databases from backup and overwrite current data!"
echo "📁 Backup directory: $BACKUP_DIR"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Restore cancelled"
    exit 1
fi

echo ""
echo "🔄 Starting database restore from $BACKUP_DIR"

# Restore user_db
if [ -f "$BACKUP_DIR/user_db_backup.sql" ]; then
    echo "Restoring user_db..."
    docker exec -i ielts_postgres psql -U ielts_admin -d user_db < "$BACKUP_DIR/user_db_backup.sql"
    if [ $? -eq 0 ]; then
        echo "✅ user_db restored successfully"
    else
        echo "❌ Failed to restore user_db"
        exit 1
    fi
else
    echo "⚠️  Warning: user_db backup file not found"
fi

# Restore exercise_db
if [ -f "$BACKUP_DIR/exercise_db_backup.sql" ]; then
    echo "Restoring exercise_db..."
    docker exec -i ielts_postgres psql -U ielts_admin -d exercise_db < "$BACKUP_DIR/exercise_db_backup.sql"
    if [ $? -eq 0 ]; then
        echo "✅ exercise_db restored successfully"
    else
        echo "❌ Failed to restore exercise_db"
        exit 1
    fi
else
    echo "⚠️  Warning: exercise_db backup file not found"
fi

# Restore ai_db
if [ -f "$BACKUP_DIR/ai_db_backup.sql" ]; then
    echo "Restoring ai_db..."
    docker exec -i ielts_postgres psql -U ielts_admin -d ai_db < "$BACKUP_DIR/ai_db_backup.sql"
    if [ $? -eq 0 ]; then
        echo "✅ ai_db restored successfully"
    else
        echo "❌ Failed to restore ai_db"
        exit 1
    fi
else
    echo "⚠️  Warning: ai_db backup file not found"
fi

echo ""
echo "✅ Database restore completed!"
echo "📝 Check backup metadata: $BACKUP_DIR/backup_metadata.txt"
