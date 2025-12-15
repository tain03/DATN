#!/bin/bash
# check-and-init-db.sh
# Script nÃ y kiá»ƒm tra vÃ  táº¡o database náº¿u chÆ°a tá»“n táº¡i

set -e

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-ielts_admin}"
DB_PASSWORD="${DB_PASSWORD:-ielts_password_2025}"
DB_NAME="${DB_NAME:-auth_db}"

echo "ðŸ” Checking if database '$DB_NAME' exists..."

# Wait for PostgreSQL to be ready
until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c '\q' 2>/dev/null; do
  echo "â³ Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "âœ… PostgreSQL is ready!"

# Check if database exists
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo "âœ… Database '$DB_NAME' already exists"
else
    echo "ðŸ“¦ Creating database '$DB_NAME'..."
    PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c "CREATE DATABASE $DB_NAME;"
    echo "âœ… Database '$DB_NAME' created successfully!"
    
    # If schema file exists, run it
    SCHEMA_FILE="/schemas/01_auth_service.sql"
    if [ -f "$SCHEMA_FILE" ]; then
        echo "ðŸ“‹ Running schema initialization..."
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCHEMA_FILE"
        echo "âœ… Schema initialized successfully!"
    fi
fi

echo "ðŸš€ Ready to start service!"
