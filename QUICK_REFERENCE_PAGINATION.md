# 🚀 Quick Reference - Pagination APIs

## 📍 Bạn đang làm việc tại:
```
/Users/bisosad/DATN/  ← Repo chính (main branch)
```

## 🧪 Test nhanh các API:

### 1. Courses (có 4 courses)
```bash
curl 'http://localhost:8080/api/v1/courses?page=1&limit=2'
# → Returns 2 courses, page 1/2

curl 'http://localhost:8080/api/v1/courses?page=2&limit=2'  
# → Returns 2 courses, page 2/2
```

### 2. Exercises (có 10 exercises)
```bash
curl 'http://localhost:8080/api/v1/exercises?page=1&limit=3'
# → Returns 3 exercises, page 1/4

curl 'http://localhost:8080/api/v1/exercises?page=2&limit=3'
# → Returns 3 exercises, page 2/4
```

### 3. Reviews
```bash
# Lấy course ID trước
COURSE_ID=$(curl -s 'http://localhost:8080/api/v1/courses?page=1&limit=1' | jq -r '.data.courses[0].id')

# Get reviews
curl "http://localhost:8080/api/v1/courses/${COURSE_ID}/reviews?page=1&limit=5"
```

### 4. Format response:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

## ✅ Validation đã test:

| Test | Input | Output | Status |
|------|-------|--------|--------|
| Invalid page | `page=0` | `page=1` | ✅ |
| Invalid limit | `limit=0` | `limit=20` | ✅ |
| Over max | `limit=500` | `limit=20` | ✅ |

## 📊 Tất cả endpoints có pagination:

✅ **Course Service:** courses, reviews, enrollments, video history  
✅ **Exercise Service:** exercises, submissions, bank questions  
✅ **User Service:** study history, leaderboard, followers, following  
✅ **Notification Service:** notifications  

## 🔧 Services đang chạy:

```bash
docker-compose ps
# → 10 containers (API Gateway, Auth, User, Course, Exercise, Notification, Postgres, Redis, RabbitMQ, pgAdmin)
```

**API Gateway:** http://localhost:8080  
**Health:** http://localhost:8080/health

---

## 📁 Files quan trọng:

- `PAGINATION_GUIDE.md` - Hướng dẫn chi tiết
- `TEST_RESULTS.md` - Kết quả test
- `shared/pkg/pagination.go` - Shared pagination struct

**Commits:**
- `47ea592` - feat: Add standardized pagination
- `6abe167` - fix: Update GetRecentSessions call

