#!/bin/bash

# ============================================
# RUN ALL DATABASE MIGRATIONS
# ============================================
# This script applies migrations to ALL databases in order
# Suitable for: setup.sh, update.sh, fresh installations
# ============================================

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Database connection details
DB_HOST=${DB_HOST:-postgres}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-ielts_admin}
PGPASSWORD=${PGPASSWORD:-ielts_password_2025}
DB_CONTAINER="ielts_postgres"

export PGPASSWORD

# Determine execution environment
if [ -f /.dockerenv ]; then
    echo -e "${GREEN}âœ… Running inside Docker container${NC}"
    PSQL_CMD_BASE="psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER}"
    MIGRATION_DIR="/migrations"
elif docker ps | grep -q $DB_CONTAINER; then
    echo -e "${GREEN}âœ… Using Docker container: ${DB_CONTAINER}${NC}"
    PSQL_CMD_BASE="docker exec -i ${DB_CONTAINER} psql -U ${DB_USER}"
    MIGRATION_DIR="./database/migrations"
else
    echo -e "${YELLOW}âš ï¸  Using local PostgreSQL${NC}"
    PSQL_CMD_BASE="PGPASSWORD=${PGPASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER}"
    MIGRATION_DIR="./database/migrations"
fi

echo ""
echo -e "${CYAN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•‘                                                            â•‘${NC}"
echo -e "${CYAN}â•‘        DATABASE MIGRATIONS - ALL SERVICES                  â•‘${NC}"
echo -e "${CYAN}â•‘                                                            â•‘${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""

# List of databases to run migrations on
DATABASES=(
    "auth_db:Auth Service"
    "user_db:User Service"
    "course_db:Course Service"
    "exercise_db:Exercise Service"
    "notification_db:Notification Service"
    "ai_db:AI Service"
)

TOTAL_APPLIED=0
TOTAL_SKIPPED=0
TOTAL_ERRORS=0

# Function to create migration tracking table
create_migration_table() {
    local db_name=$1
    echo -e "${YELLOW}ðŸ“‹ Creating migrations tracking table in ${db_name}...${NC}"
    
    $PSQL_CMD_BASE -d $db_name << 'EOF' 2>/dev/null || true
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_file VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64)
);
EOF
    echo -e "${GREEN}âœ… Migration tracking ready${NC}"
}

# Function to run migrations for a specific database
run_database_migrations() {
    local db_name=$1
    local service_name=$2
    
    echo ""
    echo -e "${BLUE}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
    echo -e "${BLUE}ðŸ“š ${service_name} (${db_name})${NC}"
    echo -e "${BLUE}â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”${NC}"
    
    # Create tracking table
    create_migration_table $db_name
    
    # Track counts for this database
    local applied=0
    local skipped=0
    
    # Find numbered migration files (001_*.sql, 002_*.sql, etc.)
    local found_migrations=false
    for migration_file in $(ls ${MIGRATION_DIR}/[0-9][0-9][0-9]_*.sql 2>/dev/null | sort); do
        found_migrations=true
        local filename=$(basename "$migration_file")
        
        # Skip rollback files
        if [[ $filename == *.rollback.sql ]]; then
            continue
        fi
        
        # Check if already applied
        local already_applied=$($PSQL_CMD_BASE -d $db_name -t -c \
            "SELECT COUNT(*) FROM schema_migrations WHERE migration_file = '${filename}';" 2>/dev/null | tr -d ' ')
        
        if [ "$already_applied" -gt 0 ]; then
            echo -e "${YELLOW}â­ï¸  SKIP: ${filename}${NC}"
            skipped=$((skipped + 1))
        else
            echo -e "${CYAN}ðŸ“ APPLYING: ${filename}${NC}"
            
            # Apply migration
            if [ -f /.dockerenv ]; then
                # Inside Docker: direct file access
                if $PSQL_CMD_BASE -d $db_name < "$migration_file" 2>&1; then
                    $PSQL_CMD_BASE -d $db_name -c \
                        "INSERT INTO schema_migrations (migration_file) VALUES ('${filename}');" >/dev/null
                    echo -e "${GREEN}âœ… SUCCESS: ${filename}${NC}"
                    applied=$((applied + 1))
                else
                    echo -e "${RED}âŒ FAILED: ${filename}${NC}"
                    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
                fi
            else
                # Outside Docker: use cat pipe
                if cat "$migration_file" | $PSQL_CMD_BASE -d $db_name 2>&1; then
                    echo "INSERT INTO schema_migrations (migration_file) VALUES ('${filename}');" | \
                        $PSQL_CMD_BASE -d $db_name >/dev/null
                    echo -e "${GREEN}âœ… SUCCESS: ${filename}${NC}"
                    applied=$((applied + 1))
                else
                    echo -e "${RED}âŒ FAILED: ${filename}${NC}"
                    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
                fi
            fi
        fi
    done

    # If no migrations found in ${MIGRATION_DIR}, attempt to apply base schema from /schemas
    if [ "$found_migrations" = false ]; then
        # Determine base schema file path by db_name
        local schema_file=""
        case "$db_name" in
            auth_db) schema_file="/schemas/01_auth_service.sql" ;;
            user_db) schema_file="/schemas/02_user_service.sql" ;;
            course_db) schema_file="/schemas/03_course_service.sql" ;;
            exercise_db) schema_file="/schemas/04_exercise_service.sql" ;;
            ai_db) schema_file="/schemas/05_ai_service.sql" ;;
            notification_db) schema_file="/schemas/06_notification_service.sql" ;;
        esac

        if [ -n "$schema_file" ] && [ -f "$schema_file" ]; then
            # Apply base schema only if DB is empty (no user tables) to avoid duplicate CREATE errors
            local table_count=$($PSQL_CMD_BASE -d $db_name -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tr -d ' ')
            if [ -z "$table_count" ]; then table_count=0; fi
            if [ "$table_count" -eq 0 ]; then
                echo -e "${CYAN}ðŸ§± No migrations found. Applying base schema for ${service_name} from ${schema_file}${NC}"
                if [ -f /.dockerenv ]; then
                    $PSQL_CMD_BASE -d $db_name < "$schema_file" 2>&1 || true
                else
                    cat "$schema_file" | $PSQL_CMD_BASE -d $db_name 2>&1 || true
                fi
                # Recompute table count
                table_count=$($PSQL_CMD_BASE -d $db_name -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | tr -d ' ')
                if [ "$table_count" -gt 0 ]; then
                    echo -e "${GREEN}âœ… Base schema applied for ${service_name}${NC}"
                else
                    echo -e "${YELLOW}âš ï¸  Could not apply base schema for ${service_name}. Please check logs.${NC}"
                fi
            else
                echo -e "${YELLOW}â„¹ï¸  ${service_name} already has tables; skipping base schema.${NC}"
            fi
        fi
    fi
    
    TOTAL_APPLIED=$((TOTAL_APPLIED + applied))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped))
    
    if [ $applied -gt 0 ] || [ $skipped -gt 0 ]; then
        echo -e "${GREEN}ðŸ“Š ${service_name}: Applied ${applied}, Skipped ${skipped}${NC}"
    else
        echo -e "${YELLOW}â„¹ï¸  No migrations found for ${service_name}${NC}"
    fi
}

# Run migrations for each database
for db_info in "${DATABASES[@]}"; do
    IFS=':' read -r db_name service_name <<< "$db_info"
    
    # Check if database exists
    db_exists=$($PSQL_CMD_BASE -d postgres -t -c \
        "SELECT 1 FROM pg_database WHERE datname = '${db_name}';" 2>/dev/null | tr -d ' ')
    
    if [ "$db_exists" = "1" ]; then
        run_database_migrations "$db_name" "$service_name"
    else
        echo -e "${YELLOW}âš ï¸  Database ${db_name} does not exist, skipping${NC}"
    fi
done

# Summary
echo ""
echo -e "${CYAN}â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—${NC}"
echo -e "${CYAN}â•‘                                                            â•‘${NC}"
echo -e "${CYAN}â•‘                   MIGRATION SUMMARY                        â•‘${NC}"
echo -e "${CYAN}â•‘                                                            â•‘${NC}"
echo -e "${CYAN}â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•${NC}"
echo ""
echo -e "Total Applied:  ${GREEN}${TOTAL_APPLIED}${NC}"
echo -e "Total Skipped:  ${YELLOW}${TOTAL_SKIPPED}${NC}"
echo -e "Total Errors:   ${RED}${TOTAL_ERRORS}${NC}"
echo ""

if [ $TOTAL_ERRORS -gt 0 ]; then
    echo -e "${RED}âŒ Some migrations failed! Please check the errors above.${NC}"
    exit 1
else
    echo -e "${GREEN}âœ… All migrations completed successfully!${NC}"
    exit 0
fi
