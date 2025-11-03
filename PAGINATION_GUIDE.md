# 📖 Hướng dẫn Sử dụng Pagination API - IELTS Platform

## 🎯 Tổng quan

Toàn bộ backend đã được chuẩn hóa với **pagination chuẩn chỉnh** cho tất cả các endpoint trả về danh sách.

## 📋 Format Response chuẩn:

### Tất cả endpoints pagination đều trả về:

```json
{
  "success": true,
  "data": {
    "items": [...],           // courses, exercises, reviews, etc.
    "pagination": {
      "page": 1,              // Trang hiện tại
      "limit": 20,            // Số items/trang
      "total": 100,           // Tổng số items
      "total_pages": 5        // Tổng số trang
    }
  }
}
```

## 🔧 Parameters:

| Parameter | Type | Mặc định | Tối đa | Bắt buộc | Mô tả |
|-----------|------|----------|--------|----------|-------|
| `page` | integer | 1 | - | Không | Số trang (≥ 1) |
| `limit` | integer | 20 | 100 | Không | Số items/trang |

**Lưu ý:** Một số endpoint dùng `pageSize` thay vì `limit` (followers, following)

## 📚 Danh sách Endpoints có Pagination:

### 🎓 Course Service

#### 1. Lấy danh sách khóa học
```http
GET /api/v1/courses?page=1&limit=20&skill_type=listening&level=intermediate
```

**Filters hỗ trợ:**
- `skill_type`: listening, reading, writing, speaking, general
- `level`: beginner, intermediate, advanced
- `enrollment_type`: free, premium
- `is_featured`: true/false
- `search`: tìm kiếm trong title, description

**Response:**
```json
{
  "success": true,
  "data": {
    "courses": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "total_pages": 3
    }
  }
}
```

#### 2. Lấy reviews của khóa học
```http
GET /api/v1/courses/{courseId}/reviews?page=1&limit=20
```

#### 3. Lấy danh sách enrollment của user
```http
GET /api/v1/courses/my-courses?page=1&limit=20
Authorization: Bearer {token}
```

#### 4. Lấy lịch sử xem video
```http
GET /api/v1/videos/history?page=1&limit=20
Authorization: Bearer {token}
```

---

### 📝 Exercise Service

#### 1. Lấy danh sách bài tập
```http
GET /api/v1/exercises?page=1&limit=20&skill_type=listening&difficulty=medium
```

**Filters hỗ trợ:**
- `skill_type`: listening, reading
- `difficulty`: easy, medium, hard
- `exercise_type`: practice, mock_test, full_test
- `is_free`: true/false
- `course_id`: UUID
- `module_id`: UUID
- `search`: tìm kiếm

**Response:**
```json
{
  "success": true,
  "data": {
    "exercises": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

#### 2. Lấy submissions của user
```http
GET /api/v1/submissions/my?page=1&limit=20
Authorization: Bearer {token}
```

#### 3. Lấy ngân hàng câu hỏi
```http
GET /api/v1/bank/questions?page=1&limit=20&skill_type=listening
Authorization: Bearer {token}
```

---

### 👤 User Service

#### 1. Lấy lịch sử học tập
```http
GET /api/v1/users/me/history?page=1&limit=20
Authorization: Bearer {token}
```

Hoặc dùng `page_size`:
```http
GET /api/v1/users/me/history?page=1&page_size=20
```

#### 2. Lấy bảng xếp hạng
```http
GET /api/v1/leaderboard?page=1&limit=50&period=weekly
Authorization: Bearer {token}
```

**Periods:** daily, weekly, monthly, all-time

#### 3. Lấy followers của user
```http
GET /api/v1/users/{userId}/followers?page=1&pageSize=20
```

#### 4. Lấy following của user
```http
GET /api/v1/users/{userId}/following?page=1&pageSize=20
```

---

### 🔔 Notification Service

#### 1. Lấy thông báo
```http
GET /api/v1/notifications?page=1&limit=20&is_read=false
Authorization: Bearer {token}
```

**Filters:**
- `is_read`: true/false

**Response format đặc biệt:**
```json
{
  "notifications": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_items": 50,
    "total_pages": 3
  }
}
```

---

## 🔒 Validation Rules:

Tất cả services đều validate:

```go
// Page validation
if page < 1 {
    page = 1  // Auto-correct về 1
}

// Limit validation  
if limit < 1 {
    limit = 20  // Default
}
if limit > 100 {
    limit = 100  // Cap tối đa (trừ study history là 200)
}
```

## 📊 Tính toán Total Pages:

```go
totalPages = (total + limit - 1) / limit

// Ví dụ:
// total = 10, limit = 3 → totalPages = 4
// total = 10, limit = 5 → totalPages = 2
// total = 10, limit = 10 → totalPages = 1
```

## 🧪 Ví dụ Test với curl:

### Test pagination cơ bản:
```bash
# Page 1
curl 'http://localhost:8080/api/v1/courses?page=1&limit=5'

# Page 2
curl 'http://localhost:8080/api/v1/courses?page=2&limit=5'
```

### Test với filters:
```bash
# Exercises: skill_type + pagination
curl 'http://localhost:8080/api/v1/exercises?page=1&limit=10&skill_type=listening&difficulty=medium'

# Courses: search + pagination
curl 'http://localhost:8080/api/v1/courses?page=1&limit=20&search=IELTS&level=intermediate'
```

### Test edge cases:
```bash
# Invalid page → auto-correct to 1
curl 'http://localhost:8080/api/v1/courses?page=0&limit=5'

# Invalid limit → default 20
curl 'http://localhost:8080/api/v1/courses?page=1&limit=0'

# Over max → cap at 100
curl 'http://localhost:8080/api/v1/courses?page=1&limit=500'
```

## 🎯 Best Practices:

### Frontend Implementation:

```typescript
// Type định nghĩa
interface PaginationResponse {
  page: number
  limit: number
  total: number
  total_pages: number
}

interface PaginatedData<T> {
  items: T[]
  pagination: PaginationResponse
}

// Example usage
const fetchCourses = async (page = 1, limit = 20) => {
  const response = await fetch(
    `/api/v1/courses?page=${page}&limit=${limit}`
  )
  const data = await response.json()
  
  return {
    courses: data.data.courses,
    pagination: data.data.pagination
  }
}
```

### React Component Example:

```tsx
const [currentPage, setCurrentPage] = useState(1)
const [pageSize, setPageSize] = useState(20)
const [data, setData] = useState<PaginatedData>()

useEffect(() => {
  fetchCourses(currentPage, pageSize).then(setData)
}, [currentPage, pageSize])

// Render pagination controls
<Pagination
  current={data.pagination.page}
  pageSize={data.pagination.limit}
  total={data.pagination.total}
  onChange={(page) => setCurrentPage(page)}
/>
```

---

## 📌 Endpoints KHÔNG cần pagination:

Các endpoints sau trả về số lượng nhỏ (thường < 50 items):

- **Categories:** `GET /api/v1/categories`
- **Tags:** `GET /api/v1/exercises/tags`
- **User Goals:** `GET /api/v1/users/me/goals`
- **User Reminders:** `GET /api/v1/users/me/reminders`
- **User Achievements:** `GET /api/v1/users/me/achievements`
- **Lesson Videos:** `GET /api/v1/lessons/{id}` (videos bên trong)
- **Lesson Materials:** Embedded trong lesson detail
- **Exercise Sections/Questions:** Embedded trong exercise detail

---

## 🚀 Testing Checklist:

- [x] Test page navigation (page 1, 2, 3...)
- [x] Test limit variations (5, 10, 20, 50)
- [x] Test with filters
- [x] Test edge cases (page=0, limit=0, limit=500)
- [x] Test empty results
- [x] Test last page (partial results)
- [x] Verify total_pages calculation
- [x] Verify total count accuracy

---

**Cập nhật:** 2025-11-03  
**Version:** 1.0  
**Status:** ✅ Production Ready

