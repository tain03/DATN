# Kế Hoạch Chi Tiết: Filter System cho Toàn Bộ Hệ Thống

## 📊 Tổng Quan

### Mục Tiêu
Xây dựng hệ thống filter hoàn chỉnh, nhất quán cho tất cả các trang danh sách trong hệ thống, đảm bảo:
- **Performance tốt**: Filter ở Backend cho dataset lớn
- **UX tốt**: Filter UI/UX nhất quán
- **Maintainable**: Code dễ maintain, reuse được

---

## 🔍 Phân Tích Hiện Trạng

### ✅ Đã Có Filter (Hoàn Chỉnh)

#### 1. **Exercises List** (`/exercises/list`)
- **Backend**: ✅ Đầy đủ
  - `skill_type`, `difficulty`, `exercise_type`
  - `search`, `is_free`, `course_id`, `module_id`
  - Pagination
- **Frontend**: ✅ Đầy đủ
  - Filter UI component
  - Search với debounce
  - Client-side: `sourceFilter` (course vs standalone)

#### 2. **Courses List** (`/courses`)
- **Backend**: ✅ Đầy đủ
  - `skill_type`, `level`, `enrollment_type`
  - `is_featured`, `search`
  - Pagination
- **Frontend**: ✅ Đầy đủ
  - Filter UI component
  - Search với debounce

---

### ⚠️ Đã Có Filter (Chưa Hoàn Chỉnh)

#### 3. **Notifications** (`/notifications`)
- **Backend**: ⚠️ Có một phần
  - `is_read` (true/false)
  - Pagination
  - ❌ Thiếu: `type`, `category`, `date_range`
- **Frontend**: ⚠️ Chưa có filter UI

#### 4. **Admin Users** (`/admin/users`)
- **Backend**: ❌ Chưa có
- **Frontend**: ⚠️ Client-side filter
  - `search` (name, email)
  - `role` (all, student, instructor, admin)
  - `status` (all, active, inactive)
  - ❌ Filter client-side → Performance kém với dataset lớn

#### 5. **Instructor Pages** (Client-side only)
- **Instructor Students** (`/instructor/students`)
  - ❌ Chỉ có client-side `search`
- **Instructor Courses** (`/instructor/courses`)
  - ❌ Chỉ có client-side `search`
- **Instructor Exercises** (`/instructor/exercises`)
  - ❌ Chỉ có client-side `search` và `filterType`
- **Instructor Messages** (`/instructor/messages`)
  - ❌ Chỉ có client-side `search`

---

### ❌ Chưa Có Filter

#### 6. **Exercise History** (`/exercises/history`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `skill_type`, `status`, `date_range`, `sort`

#### 7. **My Exercises** (`/my-exercises`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `skill_type`, `status`, `sort`

#### 8. **AI Writing Submissions** (`/ai/writing/submissions`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `status`, `task_type`, `date_range`, `band_score_range`

#### 9. **AI Speaking Submissions** (`/ai/speaking/submissions`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `status`, `part_number`, `date_range`, `band_score_range`

#### 10. **AI Writing Prompts** (`/ai/writing`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `task_type`, `difficulty`, `topic`, `is_published`

#### 11. **AI Speaking Prompts** (`/ai/speaking`)
- **Backend**: ❌ Chưa có filter
- **Frontend**: ❌ Chưa có filter UI
- **Cần**: `part_number`, `difficulty`, `topic_category`, `is_published`

---

## 🎯 Priority Classification

### **P0 - Critical (Cần làm ngay)**
1. **Exercise History** - User cần filter submissions của mình
2. **My Exercises** - User cần filter exercises đã làm
3. **Notifications** - Hoàn thiện filter (đã có một phần)

### **P1 - High (Quan trọng)**
4. **AI Writing/Speaking Submissions** - User cần filter submissions
5. **Admin Users** - Chuyển từ client-side sang backend filter
6. **Instructor Pages** - Chuyển từ client-side sang backend filter

### **P2 - Medium (Nice to have)**
7. **AI Prompts** - Filter prompts (admin/instructor)
8. **Advanced filters** - Date range, band score range, etc.

---

## 📋 Implementation Plan

### **Phase 1: Critical Filters (P0)**

#### 1.1 Exercise History Filter

**Backend Changes** (`services/exercise-service`):

**File**: `internal/models/dto.go`
```go
// MySubmissionsQuery for filtering user submissions
type MySubmissionsQuery struct {
    Page       int    `form:"page"`
    Limit      int    `form:"limit"`
    SkillType  string `form:"skill_type"`  // listening, reading, writing, speaking
    Status     string `form:"status"`      // in_progress, completed, abandoned
    SortBy     string `form:"sort_by"`     // date, score, band_score
    SortOrder  string `form:"sort_order"`  // asc, desc
    DateFrom   string `form:"date_from"`   // ISO 8601 date
    DateTo     string `form:"date_to"`     // ISO 8601 date
}
```

**File**: `internal/handlers/exercise_handler.go`
```go
func (h *ExerciseHandler) GetMySubmissions(c *gin.Context) {
    userID, _ := c.Get("user_id")
    
    query := &models.MySubmissionsQuery{}
    query.Page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
    query.Limit, _ = strconv.Atoi(c.DefaultQuery("limit", "20"))
    query.SkillType = c.Query("skill_type")
    query.Status = c.Query("status")
    query.SortBy = c.DefaultQuery("sort_by", "date")
    query.SortOrder = c.DefaultQuery("sort_order", "desc")
    query.DateFrom = c.Query("date_from")
    query.DateTo = c.Query("date_to")
    
    // ... rest of handler
}
```

**File**: `internal/repository/exercise_repository.go`
```go
func (r *ExerciseRepository) GetUserSubmissions(userID uuid.UUID, query *models.MySubmissionsQuery) (*models.MySubmissionsResponse, error) {
    where := []string{"a.user_id = $1"}
    args := []interface{}{userID}
    argCount := 1
    
    // Filter by skill_type
    if query.SkillType != "" {
        argCount++
        where = append(where, fmt.Sprintf("e.skill_type = $%d", argCount))
        args = append(args, query.SkillType)
    }
    
    // Filter by status
    if query.Status != "" {
        argCount++
        where = append(where, fmt.Sprintf("a.status = $%d", argCount))
        args = append(args, query.Status)
    }
    
    // Filter by date range
    if query.DateFrom != "" {
        argCount++
        where = append(where, fmt.Sprintf("a.created_at >= $%d", argCount))
        args = append(args, query.DateFrom)
    }
    if query.DateTo != "" {
        argCount++
        where = append(where, fmt.Sprintf("a.created_at <= $%d", argCount))
        args = append(args, query.DateTo)
    }
    
    // Sort
    orderBy := "a.created_at DESC"
    if query.SortBy == "score" {
        orderBy = fmt.Sprintf("a.score %s", query.SortOrder)
    } else if query.SortBy == "band_score" {
        orderBy = fmt.Sprintf("a.band_score %s", query.SortOrder)
    }
    
    whereClause := strings.Join(where, " AND ")
    // ... rest of query
}
```

**Frontend Changes**:

**File**: `lib/api/exercises.ts`
```typescript
export interface SubmissionFilters {
  skill?: string[]
  status?: string[]
  sort_by?: 'date' | 'score' | 'band_score'
  sort_order?: 'asc' | 'desc'
  date_from?: string
  date_to?: string
}

getMySubmissions: async (filters?: SubmissionFilters, page = 1, pageSize = 20) => {
  const params = new URLSearchParams()
  if (filters?.skill?.length) params.append("skill_type", filters.skill.join(","))
  if (filters?.status?.length) params.append("status", filters.status.join(","))
  if (filters?.sort_by) params.append("sort_by", filters.sort_by)
  if (filters?.sort_order) params.append("sort_order", filters.sort_order)
  if (filters?.date_from) params.append("date_from", filters.date_from)
  if (filters?.date_to) params.append("date_to", filters.date_to)
  params.append("page", page.toString())
  params.append("limit", pageSize.toString())
  
  const response = await apiClient.get(`/submissions/my?${params.toString()}`)
  return response.data
}
```

**File**: `components/exercises/submission-filters.tsx` (NEW)
```typescript
export function SubmissionFiltersComponent({ filters, onFiltersChange }: Props) {
  // Similar to ExerciseFiltersComponent
  // Include: Skill type, Status, Sort, Date range
}
```

**File**: `app/exercises/history/page.tsx`
```typescript
const [filters, setFilters] = useState<SubmissionFilters>({})
// Add filter UI and integrate with API
```

---

#### 1.2 My Exercises Filter

**Similar to Exercise History**, but simpler:
- Filter by `skill_type`
- Sort by `date`, `score`

---

#### 1.3 Notifications Filter Enhancement

**Backend Changes** (`services/notification-service`):

**File**: `internal/models/dto.go`
```go
type NotificationListQuery struct {
    Page     int    `form:"page"`
    Limit    int    `form:"limit"`
    IsRead   *bool  `form:"is_read"`
    Type     string `form:"type"`      // achievement, reminder, course_update, etc.
    Category string `form:"category"`  // system, social, learning
    DateFrom string `form:"date_from"`
    DateTo   string `form:"date_to"`
}
```

**File**: `internal/repository/notification_repository.go`
```go
func (r *NotificationRepository) GetNotifications(userID uuid.UUID, query *models.NotificationListQuery) ([]models.Notification, int, error) {
    where := []string{"user_id = $1", "(expires_at IS NULL OR expires_at > NOW())"}
    args := []interface{}{userID}
    argCount := 1
    
    if query.IsRead != nil {
        argCount++
        where = append(where, fmt.Sprintf("is_read = $%d", argCount))
        args = append(args, *query.IsRead)
    }
    
    if query.Type != "" {
        argCount++
        where = append(where, fmt.Sprintf("type = $%d", argCount))
        args = append(args, query.Type)
    }
    
    if query.Category != "" {
        argCount++
        where = append(where, fmt.Sprintf("category = $%d", argCount))
        args = append(args, query.Category)
    }
    
    // Date range filter
    if query.DateFrom != "" {
        argCount++
        where = append(where, fmt.Sprintf("created_at >= $%d", argCount))
        args = append(args, query.DateFrom)
    }
    if query.DateTo != "" {
        argCount++
        where = append(where, fmt.Sprintf("created_at <= $%d", argCount))
        args = append(args, query.DateTo)
    }
    
    // ... rest of query
}
```

**Frontend Changes**:

**File**: `components/notifications/notification-filters.tsx` (NEW)
```typescript
export function NotificationFiltersComponent({ filters, onFiltersChange }: Props) {
  // Filter by: Read/Unread, Type, Category, Date range
}
```

---

### **Phase 2: High Priority Filters (P1)**

#### 2.1 AI Writing/Speaking Submissions Filter

**Backend Changes** (`services/ai-service`):

**File**: `internal/models/dto.go`
```go
type WritingSubmissionListQuery struct {
    Page         int    `form:"page"`
    Limit        int    `form:"limit"`
    Status       string `form:"status"`        // pending, processing, completed, failed
    TaskType     string `form:"task_type"`     // task1, task2
    BandScoreMin *float64 `form:"band_score_min"`
    BandScoreMax *float64 `form:"band_score_max"`
    DateFrom     string `form:"date_from"`
    DateTo       string `form:"date_to"`
}

type SpeakingSubmissionListQuery struct {
    Page         int    `form:"page"`
    Limit        int    `form:"limit"`
    Status       string `form:"status"`
    PartNumber   *int   `form:"part_number"`   // 1, 2, 3
    BandScoreMin *float64 `form:"band_score_min"`
    BandScoreMax *float64 `form:"band_score_max"`
    DateFrom     string `form:"date_from"`
    DateTo       string `form:"date_to"`
}
```

**File**: `internal/repository/ai_repository.go`
```go
func (r *AIRepository) GetWritingSubmissions(userID uuid.UUID, query *models.WritingSubmissionListQuery) ([]models.WritingSubmission, int, error) {
    where := []string{"user_id = $1"}
    args := []interface{}{userID}
    argCount := 1
    
    if query.Status != "" {
        argCount++
        where = append(where, fmt.Sprintf("status = $%d", argCount))
        args = append(args, query.Status)
    }
    
    if query.TaskType != "" {
        argCount++
        where = append(where, fmt.Sprintf("task_type = $%d", argCount))
        args = append(args, query.TaskType)
    }
    
    // Band score range
    if query.BandScoreMin != nil {
        argCount++
        where = append(where, fmt.Sprintf(`
            EXISTS (
                SELECT 1 FROM writing_evaluations we 
                WHERE we.submission_id = ws.id 
                AND we.overall_band_score >= $%d
            )
        `, argCount))
        args = append(args, *query.BandScoreMin)
    }
    
    // Date range
    if query.DateFrom != "" {
        argCount++
        where = append(where, fmt.Sprintf("created_at >= $%d", argCount))
        args = append(args, query.DateFrom)
    }
    
    // ... rest of query
}
```

**Frontend Changes**:

**File**: `components/ai/submission-filters.tsx` (NEW)
```typescript
export function AISubmissionFiltersComponent({ 
  type, // 'writing' | 'speaking'
  filters, 
  onFiltersChange 
}: Props) {
  // Writing: Status, Task Type, Band Score Range, Date Range
  // Speaking: Status, Part Number, Band Score Range, Date Range
}
```

---

#### 2.2 Admin Users Filter (Backend)

**Backend Changes** (`services/user-service`):

**File**: `internal/models/dto.go`
```go
type UserListQuery struct {
    Page    int    `form:"page"`
    Limit   int    `form:"limit"`
    Search  string `form:"search"`  // Search in name, email
    Role    string `form:"role"`    // student, instructor, admin
    Status  string `form:"status"`  // active, inactive, banned
    SortBy  string `form:"sort_by"` // name, email, created_at, last_active
    SortOrder string `form:"sort_order"` // asc, desc
}
```

**Frontend Changes**:

**File**: `lib/api/admin.ts`
```typescript
export interface UserFilters {
  search?: string
  role?: string[]
  status?: string[]
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

getUsers: async (filters?: UserFilters, page = 1, pageSize = 20) => {
  // Send filters to backend instead of client-side filtering
}
```

---

#### 2.3 Instructor Pages Filter (Backend)

**Similar pattern**:
- Create query models in each service
- Add filter parameters to repository queries
- Update frontend to send filters to backend

---

### **Phase 3: Medium Priority (P2)**

#### 3.1 AI Prompts Filter

**Backend Changes** (`services/ai-service`):

**File**: `internal/models/dto.go`
```go
type WritingPromptListQuery struct {
    Page        int    `form:"page"`
    Limit       int    `form:"limit"`
    TaskType    string `form:"task_type"`    // task1, task2
    Difficulty  string `form:"difficulty"`    // easy, medium, hard
    Topic       string `form:"topic"`
    IsPublished *bool  `form:"is_published"`
    Search      string `form:"search"`
}

type SpeakingPromptListQuery struct {
    Page            int    `form:"page"`
    Limit           int    `form:"limit"`
    PartNumber      *int   `form:"part_number"`
    Difficulty      string `form:"difficulty"`
    TopicCategory   string `form:"topic_category"`
    IsPublished     *bool  `form:"is_published"`
    Search          string `form:"search"`
}
```

---

## 🛠️ Implementation Steps

### **Step 1: Setup Common Filter Components**

#### 1.1 Create Shared Filter Types
```typescript
// lib/types/filters.ts
export interface BaseFilters {
  search?: string
  page?: number
  limit?: number
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

export interface DateRangeFilter {
  date_from?: string
  date_to?: string
}

export interface SkillTypeFilter {
  skill?: string[]
}

export interface StatusFilter {
  status?: string[]
}
```

#### 1.2 Create Reusable Filter Components
```typescript
// components/filters/base-filter-component.tsx
export function BaseFilterComponent({ filters, onFiltersChange, children }: Props) {
  // Common filter UI structure
}

// components/filters/skill-type-filter.tsx
export function SkillTypeFilter({ value, onChange }: Props) {
  // Reusable skill type filter
}

// components/filters/date-range-filter.tsx
export function DateRangeFilter({ value, onChange }: Props) {
  // Reusable date range picker
}

// components/filters/status-filter.tsx
export function StatusFilter({ value, onChange }: Props) {
  // Reusable status filter
}
```

---

### **Step 2: Backend Implementation**

#### 2.1 Standardize Filter Query Models
- All services: Create `{Resource}ListQuery` struct
- Include: Pagination, Search, Common filters
- Support comma-separated values for OR logic

#### 2.2 Update Repository Methods
- Add filter parameters to all `Get*` methods
- Build dynamic WHERE clauses
- Support sorting

#### 2.3 Update Handlers
- Parse query parameters
- Pass to service layer
- Return paginated results

---

### **Step 3: Frontend Implementation**

#### 3.1 Update API Clients
- Add filter parameters to all API methods
- Standardize filter interfaces
- Handle pagination responses

#### 3.2 Create Filter Components
- Reusable filter components
- Consistent UI/UX
- Support all filter types

#### 3.3 Update Pages
- Add filter state management
- Integrate filter components
- Handle filter changes

---

## 📊 Filter Requirements Matrix

| Page/Component | Priority | Backend Filter | Frontend Filter | Status |
|----------------|----------|----------------|-----------------|--------|
| Exercises List | P0 | ✅ Complete | ✅ Complete | ✅ Done |
| Courses List | P0 | ✅ Complete | ✅ Complete | ✅ Done |
| Exercise History | P0 | ❌ Missing | ❌ Missing | 🔴 TODO |
| My Exercises | P0 | ❌ Missing | ❌ Missing | 🔴 TODO |
| Notifications | P0 | ⚠️ Partial | ❌ Missing | 🟡 TODO |
| AI Writing Submissions | P1 | ❌ Missing | ❌ Missing | 🔴 TODO |
| AI Speaking Submissions | P1 | ❌ Missing | ❌ Missing | 🔴 TODO |
| Admin Users | P1 | ❌ Missing | ⚠️ Client-side | 🟡 TODO |
| Instructor Students | P1 | ❌ Missing | ⚠️ Client-side | 🟡 TODO |
| Instructor Courses | P1 | ❌ Missing | ⚠️ Client-side | 🟡 TODO |
| Instructor Exercises | P1 | ❌ Missing | ⚠️ Client-side | 🟡 TODO |
| Instructor Messages | P1 | ❌ Missing | ⚠️ Client-side | 🟡 TODO |
| AI Writing Prompts | P2 | ❌ Missing | ❌ Missing | ⚪ TODO |
| AI Speaking Prompts | P2 | ❌ Missing | ❌ Missing | ⚪ TODO |

---

## 🎨 UI/UX Guidelines

### Filter Component Design
- **Consistent**: Tất cả filter có cùng design pattern
- **Accessible**: Support keyboard navigation, screen readers
- **Responsive**: Mobile-friendly
- **Debounced**: Search input có debounce (500ms)

### Filter Types
1. **Multi-select**: Skill type, Difficulty, Status
2. **Single select**: Sort by, Sort order
3. **Search**: Text input với debounce
4. **Date range**: Date picker (from/to)
5. **Range**: Band score min/max (number inputs)

### Filter UI Patterns
- **Sheet/Drawer**: Mobile filter menu
- **Inline**: Desktop filter dropdowns
- **Active filters**: Badge hiển thị filters đang active
- **Clear all**: Button để clear tất cả filters

---

## 📝 Testing Checklist

### Backend Testing
- [ ] Filter by single value
- [ ] Filter by multiple values (comma-separated)
- [ ] Search functionality
- [ ] Date range filter
- [ ] Pagination with filters
- [ ] Sort functionality
- [ ] Empty results handling
- [ ] Invalid filter values handling

### Frontend Testing
- [ ] Filter UI rendering
- [ ] Filter state management
- [ ] API integration
- [ ] Loading states
- [ ] Error handling
- [ ] Empty states
- [ ] Mobile responsiveness
- [ ] Accessibility (keyboard, screen reader)

---

## 🚀 Deployment Plan

### Phase 1: Critical (Week 1-2)
1. Exercise History Filter
2. My Exercises Filter
3. Notifications Filter Enhancement

### Phase 2: High Priority (Week 3-4)
4. AI Submissions Filter
5. Admin Users Backend Filter
6. Instructor Pages Backend Filter

### Phase 3: Medium Priority (Week 5+)
7. AI Prompts Filter
8. Advanced filters (date range, score range)

---

## 📈 Success Metrics

- ✅ All list pages have filter functionality
- ✅ Consistent filter UI/UX across system
- ✅ Backend filter for all large datasets
- ✅ Performance: < 500ms filter response time
- ✅ User satisfaction: Easy to find content

