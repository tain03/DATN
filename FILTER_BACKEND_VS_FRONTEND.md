# Filter: Backend vs Frontend - Best Practices

## 📊 Filter Hiện Tại

### ✅ Backend Đã Có:
- `skill_type` (listening, reading, writing, speaking)
- `difficulty` (easy, medium, hard)
- `exercise_type` (practice, mock_test, full_test)
- `search` (title, description ILIKE)
- `is_free` (boolean)
- `course_id`, `module_id` (UUID)
- `pagination` (page, limit)

### ✅ Frontend:
- Gửi filter params lên BE qua API
- `sourceFilter` (course vs standalone) - **FILTER CLIENT-SIDE**

---

## 🎯 Khi Nào Nên Làm Ở Backend?

### ✅ **Nên làm ở Backend** (Database Queries):

1. **Filter dựa trên database fields**:
   - `skill_type`, `difficulty`, `exercise_type`
   - `is_free`, `course_id`, `module_id`
   - `is_published`, `created_at`, etc.

2. **Search/Full-text search**:
   - Search trong `title`, `description`
   - Cần ILIKE queries ở database level

3. **Pagination**:
   - `LIMIT` và `OFFSET` ở database
   - Trả về `total`, `total_pages` chính xác

4. **Performance**:
   - Database indexes giúp query nhanh
   - Không cần load tất cả data về FE rồi filter

### ✅ **Ví dụ Backend Filter**:
```go
// Backend: Efficient database query
WHERE skill_type IN ('listening', 'reading')
  AND difficulty = 'medium'
  AND is_published = true
  AND (title ILIKE '%keyword%' OR description ILIKE '%keyword%')
LIMIT 12 OFFSET 0
```

---

## 🎨 Khi Nào Có Thể Làm Ở Frontend?

### ✅ **Có thể làm ở Frontend** (Client-side Filtering):

1. **Filter UI/UX nhẹ**:
   - `sourceFilter` (course vs standalone) - chỉ filter từ data đã có
   - Sort order (ascending/descending) - nếu data ít

2. **Filter không có trong database**:
   - Filter dựa trên computed fields
   - Filter dựa trên UI state

3. **Real-time filter** (không cần API call):
   - Toggle visibility
   - Highlight/search trong danh sách đã load

### ⚠️ **Lưu ý khi filter ở Frontend**:
- Chỉ filter data đã load (không filter toàn bộ database)
- Pagination sẽ không chính xác nếu filter sau khi load
- Performance kém với dataset lớn

---

## 📝 So Sánh

### Backend Filter (Recommended):
```typescript
// Frontend: Gửi params
GET /api/v1/exercises?skill_type=listening,reading&difficulty=medium&page=1&limit=12

// Backend: Database query
SELECT * FROM exercises 
WHERE skill_type IN ('listening', 'reading')
  AND difficulty = 'medium'
  AND is_published = true
LIMIT 12 OFFSET 0

// Response: Chỉ data phù hợp + pagination chính xác
{
  exercises: [...], // 12 items
  pagination: {
    total: 45,      // Total matching exercises
    total_pages: 4  // Accurate pagination
  }
}
```

### Frontend Filter (Limited Use):
```typescript
// Frontend: Load all, then filter
const allExercises = await fetch('/api/v1/exercises?limit=1000')
const courseExercises = allExercises.filter(ex => ex.module_id !== null)

// ❌ Problems:
// - Load quá nhiều data không cần thiết
// - Pagination không chính xác
// - Performance kém
```

---

## ✅ Best Practices

### 1. **Filter chính → Backend**:
- ✅ `skill_type`, `difficulty`, `exercise_type`
- ✅ `search`, `is_free`, `course_id`
- ✅ Pagination, sorting

### 2. **Filter UI/UX nhẹ → Frontend**:
- ✅ `sourceFilter` (course vs standalone) từ data đã load
- ✅ Toggle visibility, highlight
- ✅ Local sort (nếu data ít)

### 3. **Current Implementation**:
```typescript
// ✅ Good: Main filters ở Backend
GET /api/v1/exercises?skill_type=listening,reading&difficulty=medium

// ✅ Acceptable: sourceFilter ở Frontend (filter từ response)
const filtered = response.data.filter(ex => 
  sourceFilter === "course" ? ex.module_id : !ex.module_id
)
```

---

## 🎯 Recommendation

### ✅ **Giữ nguyên như hiện tại**:

1. **Backend Filter** (đã có, đúng):
   - `skill_type`, `difficulty`, `exercise_type`
   - `search`, `is_free`, `course_id`, `module_id`
   - Pagination

2. **Frontend Filter** (acceptable):
   - `sourceFilter` (course vs standalone) - filter từ data đã có
   - Không cần load lại từ backend

### 💡 **Nếu muốn optimize hơn**:

1. **Option 1**: Thêm `sourceFilter` vào Backend:
   ```go
   // Backend: Add module_id filter
   if query.SourceFilter == "course" {
       where = append(where, "module_id IS NOT NULL")
   } else if query.SourceFilter == "standalone" {
       where = append(where, "module_id IS NULL")
   }
   ```
   - ✅ Pagination chính xác
   - ✅ Performance tốt hơn
   - ❌ Cần thay đổi BE

2. **Option 2**: Giữ nguyên Frontend filter:
   - ✅ Đơn giản, không cần thay đổi BE
   - ⚠️ Pagination không chính xác (nhưng acceptable nếu data ít)

---

## 📊 Kết Luận

### ✅ **Filter chính → Backend** (Đã có, đúng):
- Database queries hiệu quả
- Pagination chính xác
- Performance tốt

### ✅ **Filter UI/UX nhẹ → Frontend** (Current):
- `sourceFilter` - filter từ data đã load
- Acceptable cho dataset nhỏ/medium

### 🎯 **Khuyến nghị**:
- **Giữ nguyên** như hiện tại (đã đúng)
- Nếu muốn optimize: Thêm `sourceFilter` vào Backend (optional)

