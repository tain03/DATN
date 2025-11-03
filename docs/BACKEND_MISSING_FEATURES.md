# 🚧 BACKEND - CÁC CHỨC NĂNG CÒN THIẾU

> Phân tích chi tiết các chức năng backend còn thiếu và cần implement

**Ngày phân tích:** 2025-01-15  
**Trạng thái:** Backend đã có 5 services (Auth, User, Course, Exercise, Notification) nhưng thiếu AI Service và một số Admin endpoints

---

## 📊 TỔNG QUAN

### Services Đã Có ✅
1. **Auth Service** - ✅ Đầy đủ (login, register, OAuth, password reset, email verification)
2. **User Service** - ✅ Đầy đủ (profile, progress, goals, achievements, leaderboard, social)
3. **Course Service** - ✅ Đầy đủ (courses, modules, lessons, enrollments, reviews, videos)
4. **Exercise Service** - ✅ Đầy đủ (exercises, submissions, questions, analytics)
5. **Notification Service** - ✅ Hầu như đầy đủ (notifications, preferences, scheduled)

### Services Thiếu ❌
1. **AI Service** - ❌ **HOÀN TOÀN THIẾU** (chỉ có database schema)

---

## 🔴 1. AI SERVICE - CHƯA CÓ (ƯU TIÊN CAO)

### Tình trạng
- ✅ Database schema đã có (`database/schemas/05_ai_service.sql`)
- ❌ **Service code chưa có** (không có thư mục `services/ai-service/`)
- ❌ **Chưa có routes/handlers**
- ❌ **Chưa có service logic**

### Endpoints Cần Implement

#### Writing Endpoints
```
POST   /api/v1/ai/writing/submit                    - Nộp bài Writing để chấm
GET    /api/v1/ai/writing/submissions               - List submissions của user
GET    /api/v1/ai/writing/submissions/:id            - Xem kết quả chấm Writing
GET    /api/v1/ai/writing/prompts                    - Lấy danh sách đề Writing
GET    /api/v1/ai/writing/prompts/:id               - Lấy chi tiết đề Writing
```

#### Speaking Endpoints
```
POST   /api/v1/ai/speaking/submit                   - Nộp bài Speaking (upload audio)
GET    /api/v1/ai/speaking/submissions               - List submissions của user
GET    /api/v1/ai/speaking/submissions/:id           - Xem kết quả chấm Speaking
GET    /api/v1/ai/speaking/prompts                  - Lấy danh sách đề Speaking
GET    /api/v1/ai/speaking/prompts/:id               - Lấy chi tiết đề Speaking
```

#### Admin Endpoints (AI Service)
```
POST   /api/v1/admin/ai/writing/prompts             - Tạo đề Writing mới
PUT    /api/v1/admin/ai/writing/prompts/:id         - Update đề Writing
DELETE /api/v1/admin/ai/writing/prompts/:id         - Xóa đề Writing
POST   /api/v1/admin/ai/speaking/prompts            - Tạo đề Speaking mới
PUT    /api/v1/admin/ai/speaking/prompts/:id         - Update đề Speaking
DELETE /api/v1/admin/ai/speaking/prompts/:id         - Xóa đề Speaking
GET    /api/v1/admin/ai/queue                       - Xem processing queue
GET    /api/v1/admin/ai/stats                       - Xem thống kê AI processing
```

### Database Tables Cần Sử Dụng
- `writing_submissions` - Bài Writing được nộp
- `writing_evaluations` - Kết quả chấm Writing
- `speaking_submissions` - Bài Speaking được ghi âm
- `speaking_evaluations` - Kết quả chấm Speaking
- `writing_prompts` - Ngân hàng đề Writing
- `speaking_prompts` - Ngân hàng đề Speaking
- `ai_processing_queue` - Queue xử lý AI
- `ai_model_versions` - Track AI model versions
- `evaluation_feedback_ratings` - User feedback về evaluation

### Công nghệ Cần Dùng
- **AI Model**: OpenAI GPT-4, Claude, hoặc custom model
- **Speech-to-Text**: OpenAI Whisper hoặc Google Speech-to-Text
- **Audio Processing**: FFmpeg, librosa
- **Queue System**: Redis Queue hoặc PostgreSQL-based queue

### Ước tính Effort
- **Development**: 2-3 tuần
- **Testing**: 1 tuần
- **Integration**: 1 tuần
- **Total**: ~4-5 tuần

---

## 🔴 2. ADMIN - USER MANAGEMENT (ƯU TIÊN CAO)

### Tình trạng
- ❌ **Chưa có endpoints** trong user-service
- ✅ Frontend đã có UI (`/admin/users`)
- ✅ Database có đủ tables (users, roles, permissions)

### Endpoints Cần Implement trong User Service

#### User CRUD
```
GET    /api/v1/admin/users                          - List all users (with filters, pagination)
GET    /api/v1/admin/users/:id                      - Get user detail
PUT    /api/v1/admin/users/:id                      - Update user
DELETE /api/v1/admin/users/:id                      - Delete user (soft delete)
```

#### User Status Management
```
POST   /api/v1/admin/users/:id/activate            - Activate account
POST   /api/v1/admin/users/:id/deactivate          - Deactivate account
POST   /api/v1/admin/users/:id/lock                - Lock account (với reason)
POST   /api/v1/admin/users/:id/unlock              - Unlock account
```

#### Role Management
```
GET    /api/v1/admin/users/:id/roles               - Get user roles
POST   /api/v1/admin/users/:id/assign-role         - Assign role (student/instructor/admin)
POST   /api/v1/admin/users/:id/revoke-role         - Revoke role
```

#### User Utilities
```
POST   /api/v1/admin/users/:id/reset-password      - Admin reset user password
GET    /api/v1/admin/users/:id/login-history      - Xem login history
```

### Filters Cần Hỗ Trợ
- `role`: student, instructor, admin
- `status`: active, inactive, locked
- `search`: tìm theo email, name
- `page`, `limit`: pagination

### Ước tính Effort
- **Development**: 1 tuần
- **Testing**: 3 ngày
- **Total**: ~1.5 tuần

---

## 🟡 3. ADMIN - ANALYTICS & REPORTS (ƯU TIÊN TRUNG BÌNH)

### Tình trạng
- ❌ **Chưa có endpoints**
- ✅ Frontend đã có UI với mock data (`/admin/analytics`)
- ✅ Database có đủ data để tính toán

### Endpoints Cần Implement

#### Analytics Overview
```
GET    /api/v1/admin/analytics/overview            - System overview stats
       Response: {
         totalUsers, totalCourses, totalExercises,
         activeUsers, newUsersToday, enrollmentsToday,
         completionRate, averageScore, etc.
       }
```

#### User Analytics
```
GET    /api/v1/admin/analytics/users               - User analytics
       Query params: days (7, 30, 90, all-time)
       Response: {
         newUsers: [{date, count}],
         activeUsers: [{date, count}],
         userGrowth: number,
         retentionRate: number
       }
```

#### Course Analytics
```
GET    /api/v1/admin/analytics/courses             - Course analytics
       Response: {
         totalCourses, publishedCourses,
         totalEnrollments, averageEnrollmentPerCourse,
         topCourses: [{course, enrollments, completionRate}]
       }
```

#### Exercise Analytics
```
GET    /api/v1/admin/analytics/exercises           - Exercise analytics
       Response: {
         totalExercises, publishedExercises,
         totalSubmissions, averageScore,
         difficultyDistribution: {easy, medium, hard}
       }
```

#### Enrollment Analytics
```
GET    /api/v1/admin/analytics/enrollments          - Enrollment stats
       Query params: days
       Response: {
         enrollments: [{date, count}],
         completionRate: number,
         averageCompletionTime: number
       }
```

#### Engagement Analytics
```
GET    /api/v1/admin/analytics/engagement           - User engagement
       Response: {
         dailyActiveUsers: number,
         weeklyActiveUsers: number,
         monthlyActiveUsers: number,
         averageSessionDuration: number,
         averageSessionsPerUser: number
       }
```

#### Top Lists
```
GET    /api/v1/admin/analytics/top-courses          - Top courses by enrollments
GET    /api/v1/admin/analytics/top-students         - Top students by progress/score
GET    /api/v1/admin/analytics/instructors          - Instructor performance
```

### Data Sources
- User Service: users, progress, sessions, goals
- Course Service: courses, enrollments, progress
- Exercise Service: exercises, submissions, scores
- Auth Service: login history

### Ước tính Effort
- **Development**: 1.5-2 tuần
- **Testing**: 1 tuần
- **Total**: ~2.5-3 tuần

---

## 🟢 4. ADMIN - SYSTEM MANAGEMENT (ƯU TIÊN THẤP)

### Tình trạng
- ❌ **Chưa có endpoints**
- ✅ Frontend đã có UI (`/admin/system`)

### Endpoints Cần Implement

#### System Health
```
GET    /api/v1/admin/system/health                  - System health check
       Response: {
         status: "healthy|degraded|down",
         services: [
           {name: "auth-service", status: "up", responseTime: 50},
           {name: "user-service", status: "up", responseTime: 45},
           ...
         ],
         database: {status: "connected", latency: 10},
         timestamp: "2025-01-15T10:00:00Z"
       }
```

#### Service Status
```
GET    /api/v1/admin/system/status                  - Detailed service status
       Response: {
         services: [...],
         systemResources: {
           cpu: 45.2,
           memory: 62.5,
           disk: 78.1
         }
       }
```

#### System Logs
```
GET    /api/v1/admin/system/logs                    - Error logs
       Query params: service, level (error/warning/info), from, to
       Response: LogEntry[]
```

#### System Settings
```
GET    /api/v1/admin/system/settings                 - Get system settings
PUT    /api/v1/admin/system/settings                 - Update system settings
```

### Implementation Notes
- Health check: ping tất cả services
- Logs: có thể dùng centralized logging (ELK, Grafana Loki)
- Settings: lưu trong database hoặc config file

### Ước tính Effort
- **Development**: 1 tuần
- **Testing**: 3 ngày
- **Total**: ~1.5 tuần

---

## 🟢 5. ADMIN - NOTIFICATION MANAGEMENT (THIẾU MỘT SỐ)

### Tình trạng
- ✅ Đã có: `POST /admin/notifications`, `POST /admin/notifications/bulk`
- ❌ **Thiếu một số endpoints**

### Endpoints Còn Thiếu

#### Notification Stats
```
GET    /api/v1/admin/notifications/:id/stats        - Delivery stats của notification
       Response: {
         sent: 1000,
         delivered: 950,
         read: 800,
         clicked: 120,
         deliveryRate: 95.0,
         readRate: 84.2
       }
```

#### Notification Templates
```
GET    /api/v1/admin/notifications/templates        - List notification templates
POST   /api/v1/admin/notifications/templates        - Create template
PUT    /api/v1/admin/notifications/templates/:id    - Update template
DELETE /api/v1/admin/notifications/templates/:id    - Delete template
```

#### Scheduled Notifications
```
POST   /api/v1/admin/notifications/scheduled       - Schedule notification
       (Có thể dùng endpoint của user-service đã có,
        nhưng cần thêm bulk scheduling)
```

### Ước tính Effort
- **Development**: 3-5 ngày
- **Testing**: 2 ngày
- **Total**: ~1 tuần

---

## 🟢 6. COURSE SERVICE - MỘT SỐ ENDPOINTS NHỎ

### Endpoints Còn Thiếu

#### Module Endpoints
```
GET    /api/v1/courses/:id/modules                  - Get modules của course
       (Hiện tại có trong GetCourseDetail, nhưng chưa có endpoint riêng)
```

#### Material Management (cho Admin)
```
POST   /api/v1/admin/lessons/:id/materials          - Upload material
PUT    /api/v1/admin/materials/:id                 - Update material
DELETE /api/v1/admin/materials/:id                  - Delete material
```

#### Review Moderation
```
DELETE /api/v1/admin/reviews/:id                   - Delete inappropriate review
PUT    /api/v1/admin/reviews/:id/hide              - Hide review
```

### Ước tính Effort
- **Development**: 2-3 ngày
- **Testing**: 1 ngày
- **Total**: ~3-4 ngày

---

## 📋 ƯU TIÊN THỰC HIỆN

### Phase 1: Critical (4-6 tuần)
1. ✅ **AI Service** - Writing & Speaking evaluation
   - Time: 4-5 tuần
   - Impact: Cao (core feature cho IELTS platform)

### Phase 2: Important (3-4 tuần)
2. ✅ **Admin User Management**
   - Time: 1.5 tuần
   - Impact: Cao (admin cần quản lý users)

3. ✅ **Admin Analytics**
   - Time: 2.5-3 tuần
   - Impact: Trung bình-Cao (insights cho admin)

### Phase 3: Nice to Have (2 tuần)
4. ✅ **Admin System Management**
   - Time: 1.5 tuần
   - Impact: Trung bình

5. ✅ **Admin Notification Enhancements**
   - Time: 1 tuần
   - Impact: Thấp-Trung bình

6. ✅ **Course Service Enhancements**
   - Time: 3-4 ngày
   - Impact: Thấp

---

## 📊 TỔNG KẾT

| Service/Feature | Status | Endpoints Thiếu | Priority | Estimated Time |
|------------------|--------|------------------|-----------|----------------|
| **AI Service** | ❌ Chưa có | ~12 endpoints | 🔴 Cao | 4-5 tuần |
| **Admin User Management** | ❌ Chưa có | ~13 endpoints | 🔴 Cao | 1.5 tuần |
| **Admin Analytics** | ❌ Chưa có | ~10 endpoints | 🟡 Trung bình | 2.5-3 tuần |
| **Admin System Management** | ❌ Chưa có | ~4 endpoints | 🟢 Thấp | 1.5 tuần |
| **Admin Notifications** | ⚠️ Một phần | ~3 endpoints | 🟢 Thấp | 1 tuần |
| **Course Enhancements** | ⚠️ Một phần | ~4 endpoints | 🟢 Thấp | 3-4 ngày |

**Total Estimated Time:** ~10-12 tuần (2.5-3 tháng với 1 developer)

---

## 🔗 TÀI LIỆU THAM KHẢO

- [ROLES_AND_PERMISSIONS.md](./ROLES_AND_PERMISSIONS.md) - Chi tiết permissions và endpoints theo role
- [DATA_MODEL_RELATIONSHIPS.md](./DATA_MODEL_RELATIONSHIPS.md) - Data model và relationships
- [database/schemas/05_ai_service.sql](../database/schemas/05_ai_service.sql) - AI Service database schema
- [Frontend admin API](../Frontend-IELTSGo/lib/api/admin.ts) - Frontend đã expect các endpoints này

---

**Lưu ý:** Tài liệu này dựa trên phân tích codebase tại thời điểm 2025-01-15. Các endpoints có thể thay đổi trong quá trình phát triển.
