#!/bin/bash

# Script kiá»ƒm tra health cá»§a há»‡ thá»‘ng

echo "ðŸ” Äang kiá»ƒm tra health cá»§a cÃ¡c services..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local service_name=$1
    local url=$2
    
    echo -n "Checking $service_name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" == "200" ] || [ "$response" == "204" ]; then
        echo -e "${GREEN}âœ“ OK${NC}"
        return 0
    else
        echo -e "${RED}âœ— FAIL (HTTP $response)${NC}"
        return 1
    fi
}

# Function to check container status
check_container() {
    local container_name=$1
    
    echo -n "Checking container $container_name... "
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${GREEN}âœ“ RUNNING${NC}"
        return 0
    else
        echo -e "${RED}âœ— NOT RUNNING${NC}"
        return 1
    fi
}

# Counter
success_count=0
total_count=0

echo "ðŸ“¦ Kiá»ƒm tra Docker containers:"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

# Check infrastructure containers
containers=(
    "ielts_postgres"
    "ielts_redis"
    "ielts_rabbitmq"
    "ielts_pgadmin"
)

for container in "${containers[@]}"; do
    ((total_count++))
    if check_container "$container"; then
        ((success_count++))
    fi
done

echo ""
echo "ðŸŒ Kiá»ƒm tra HTTP endpoints:"
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"

# Check HTTP endpoints
services=(
    "PgAdmin:http://localhost:5050"
    "RabbitMQ Management:http://localhost:15672"
)

# Add auth service if container exists
if docker ps --format '{{.Names}}' | grep -q "^ielts_auth_service$"; then
    services+=("Auth Service Health:http://localhost:8001/health")
fi

for service_info in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service_info"
    ((total_count++))
    if check_service "$name" "$url"; then
        ((success_count++))
    fi
done

echo ""
echo "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”"
echo ""

# Summary
echo "ðŸ“Š Káº¿t quáº£: $success_count/$total_count services Ä‘ang hoáº¡t Ä‘á»™ng"
echo ""

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}âœ… Táº¥t cáº£ services Ä‘ang hoáº¡t Ä‘á»™ng tá»‘t!${NC}"
    echo ""
    echo "ðŸ”— Truy cáº­p:"
    echo "  â€¢ PgAdmin: http://localhost:5050"
    echo "  â€¢ RabbitMQ: http://localhost:15672"
    if docker ps --format '{{.Names}}' | grep -q "^ielts_auth_service$"; then
        echo "  â€¢ Auth API: http://localhost:8001/health"
    fi
    exit 0
else
    echo -e "${YELLOW}âš ï¸  Má»™t sá»‘ services chÆ°a sáºµn sÃ ng${NC}"
    echo ""
    echo "ðŸ’¡ Thá»­ cÃ¡c lá»‡nh sau:"
    echo "  â€¢ docker-compose ps          - Xem tráº¡ng thÃ¡i containers"
    echo "  â€¢ docker-compose logs        - Xem logs"
    echo "  â€¢ make restart               - Khá»Ÿi Ä‘á»™ng láº¡i"
    exit 1
fi
