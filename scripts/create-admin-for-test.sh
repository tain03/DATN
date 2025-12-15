#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Creating Admin User for Testing ===${NC}\n"

# Admin credentials
ADMIN_EMAIL="test_admin@ielts.com"
ADMIN_PASSWORD="Test@123"  # Same as student for simplicity
ADMIN_NAME="Test Administrator"

# Check if admin exists
EXISTING=$(docker exec ielts_postgres psql -U ielts_admin -d auth_db -tAc "SELECT COUNT(*) FROM users WHERE email = '$ADMIN_EMAIL';")

if [ "$EXISTING" -gt "0" ]; then
    echo -e "${GREEN}âœ“ Admin user already exists: $ADMIN_EMAIL${NC}"
else
    echo -e "${BLUE}Creating new admin user...${NC}"
    
    # Get password hash from student user (same password: Test@123)
    PASSWORD_HASH=$(docker exec ielts_postgres psql -U ielts_admin -d auth_db -tAc "SELECT password_hash FROM users WHERE email = 'student1@test.com';")
    
    # Insert user (no ON CONFLICT since we checked already)
    docker exec ielts_postgres psql -U ielts_admin -d auth_db -c "
        INSERT INTO users (email, password_hash, is_active, is_verified, email_verified_at)
        VALUES ('$ADMIN_EMAIL', '$PASSWORD_HASH', true, true, NOW());
    " > /dev/null
    
    # Get user ID
    USER_ID=$(docker exec ielts_postgres psql -U ielts_admin -d auth_db -tAc "SELECT id FROM users WHERE email = '$ADMIN_EMAIL';")
    
    if [ -z "$USER_ID" ]; then
        echo -e "${RED}âœ— Failed to create user${NC}"
        exit 1
    fi
    
    # Get admin role ID
    ADMIN_ROLE_ID=$(docker exec ielts_postgres psql -U ielts_admin -d auth_db -tAc "SELECT id FROM roles WHERE name = 'admin';")
    
    if [ -z "$ADMIN_ROLE_ID" ]; then
        echo -e "${RED}âœ— Admin role not found${NC}"
        exit 1
    fi
    
    # Assign admin role
    docker exec ielts_postgres psql -U ielts_admin -d auth_db -c "
        INSERT INTO user_roles (user_id, role_id)
        VALUES ('$USER_ID', '$ADMIN_ROLE_ID')
        ON CONFLICT (user_id, role_id) DO NOTHING;
    " > /dev/null
    
    echo -e "${GREEN}âœ“ Admin user created successfully${NC}"
fi

echo -e "\n${BLUE}=== Admin Credentials ===${NC}"
echo "Email: $ADMIN_EMAIL"
echo "Password: $ADMIN_PASSWORD"
echo ""

# Login and get token
echo -e "${BLUE}=== Logging in as admin ===${NC}"
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":\"$ADMIN_EMAIL\",
    \"password\":\"$ADMIN_PASSWORD\"
  }")

ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.data.access_token')
ADMIN_USER_ID=$(echo $ADMIN_RESPONSE | jq -r '.data.user_id')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo -e "${RED}âœ— Failed to login${NC}"
    echo "Response: $ADMIN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}âœ“ Login successful${NC}"
echo "User ID: $ADMIN_USER_ID"
echo "Token: ${ADMIN_TOKEN:0:50}..."
echo ""

# Save tokens for reuse
echo "export ADMIN_EMAIL='$ADMIN_EMAIL'" > /tmp/admin_creds.sh
echo "export ADMIN_TOKEN='$ADMIN_TOKEN'" >> /tmp/admin_creds.sh
echo "export ADMIN_USER_ID='$ADMIN_USER_ID'" >> /tmp/admin_creds.sh

# Also get student token
STUDENT_RESPONSE=$(curl -s -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student1@test.com","password":"Test@123"}')

STUDENT_TOKEN=$(echo $STUDENT_RESPONSE | jq -r '.data.access_token')
STUDENT_USER_ID=$(echo $STUDENT_RESPONSE | jq -r '.data.user_id')

echo "export STUDENT_EMAIL='student1@test.com'" >> /tmp/admin_creds.sh
echo "export STUDENT_TOKEN='$STUDENT_TOKEN'" >> /tmp/admin_creds.sh
echo "export STUDENT_USER_ID='$STUDENT_USER_ID'" >> /tmp/admin_creds.sh

echo -e "${GREEN}âœ“ Credentials saved to /tmp/admin_creds.sh${NC}"
echo -e "${BLUE}Run: source /tmp/admin_creds.sh to use these credentials${NC}\n"
