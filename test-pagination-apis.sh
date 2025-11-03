#!/bin/bash

# Script test pagination APIs
# Chạy: bash test-pagination-apis.sh

echo "🧪 Testing Pagination APIs"
echo "================================"
echo ""

API_URL="http://localhost:8080"

# Test 1: Courses pagination
echo "1️⃣ Testing GET /api/v1/courses (page=1, limit=3)"
curl -s "${API_URL}/api/v1/courses?page=1&limit=3" | jq '{
  success, 
  courses_count: (.data.courses | length),
  pagination: .data.pagination
}'
echo ""

# Test 2: Exercises pagination  
echo "2️⃣ Testing GET /api/v1/exercises (page=1, limit=3)"
curl -s "${API_URL}/api/v1/exercises?page=1&limit=3" | jq '{
  success,
  exercises_count: (.data.exercises | length),
  page: .data.page,
  limit: .data.limit,
  total: .data.total,
  total_pages: .data.total_pages
}'
echo ""

# Test 3: Exercises page 2
echo "3️⃣ Testing GET /api/v1/exercises (page=2, limit=3)"
curl -s "${API_URL}/api/v1/exercises?page=2&limit=3" | jq '{
  success,
  exercises_count: (.data.exercises | length),
  page: .data.page,
  total: .data.total,
  total_pages: .data.total_pages
}'
echo ""

# Test 4: Course reviews (needs course_id)
COURSE_ID=$(curl -s "${API_URL}/api/v1/courses?page=1&limit=1" | jq -r '.data.courses[0].id')
if [ "$COURSE_ID" != "null" ] && [ -n "$COURSE_ID" ]; then
  echo "4️⃣ Testing GET /api/v1/courses/${COURSE_ID}/reviews (page=1, limit=5)"
  curl -s "${API_URL}/api/v1/courses/${COURSE_ID}/reviews?page=1&limit=5" | jq '{
    success,
    reviews_count: (.data.reviews | length),
    pagination: {
      page: .data.page,
      limit: .data.limit,
      total: .data.total,
      total_pages: .data.total_pages
    }
  }'
else
  echo "⚠️  No courses found to test reviews"
fi
echo ""

# Test 5: Different page sizes
echo "5️⃣ Testing different page sizes for courses"
for limit in 2 5 10; do
  echo "   - limit=$limit:"
  curl -s "${API_URL}/api/v1/courses?page=1&limit=${limit}" | jq -c '{limit: .data.pagination.limit, total: .data.pagination.total, pages: .data.pagination.total_pages}'
done
echo ""

# Test 6: Edge cases
echo "6️⃣ Testing edge cases"
echo "   - Invalid page (0):"
curl -s "${API_URL}/api/v1/courses?page=0&limit=5" | jq -c '{page: .data.pagination.page}'
echo "   - Invalid limit (0):"
curl -s "${API_URL}/api/v1/courses?page=1&limit=0" | jq -c '{limit: .data.pagination.limit}'
echo "   - Limit > max (200):"
curl -s "${API_URL}/api/v1/courses?page=1&limit=200" | jq -c '{limit: .data.pagination.limit}'
echo ""

echo "✅ Pagination tests completed!"

