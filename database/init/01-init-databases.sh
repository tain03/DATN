#!/bin/bash
set -e

# This script creates multiple databases in PostgreSQL
# Used by docker-compose to initialize all service databases

echo "Creating multiple databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    -- Create databases for each microservice
    CREATE DATABASE auth_db;
    CREATE DATABASE user_db;
    CREATE DATABASE course_db;
    CREATE DATABASE exercise_db;
    CREATE DATABASE ai_db;
    CREATE DATABASE notification_db;
    
    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE auth_db TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE user_db TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE course_db TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE exercise_db TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE ai_db TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE notification_db TO $POSTGRES_USER;
EOSQL

echo "Databases created successfully!"

# Execute schema files
echo "Initializing database schemas..."

for db in auth_db user_db course_db exercise_db ai_db notification_db; do
    echo "Initializing schema for $db..."
    case $db in
        auth_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/01_auth_service.sql
            ;;
        user_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/02_user_service.sql
            ;;
        course_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/03_course_service.sql
            ;;
        exercise_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/04_exercise_service.sql
            ;;
        ai_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/05_ai_service.sql
            ;;
        notification_db)
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" < /schemas/06_notification_service.sql
            ;;
    esac
done

echo "All database schemas initialized successfully!"
