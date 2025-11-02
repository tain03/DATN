# 🚀 Demo Quick Reference - IELTSGo

> Checklist nhanh để chụp ảnh demo

## ⚡ Quick Start

1. **Chuẩn bị tài khoản**: Student, Instructor, Admin
2. **Mở browser**: Chrome, viewport 1920x1080
3. **Start server**: `npm run dev`
4. **Theo flow**: Bắt đầu từ trang chủ → đăng nhập → demo các trang

---

## 📋 CHECKLIST NGẮN GỌN

### 🏠 Public & Auth (3 ảnh)
- [ ] `/` - Homepage (chưa login)
- [ ] `/register` - Đăng ký
- [ ] `/login` - Đăng nhập

### 📊 Student - Main Features (22 ảnh)

#### Core Learning
- [ ] `/dashboard` - Dashboard overview
- [ ] `/my-courses` - My Courses (tất cả tabs: All, In Progress, Completed)
- [ ] `/courses` - Browse courses với filters
- [ ] `/courses/[id]` - Course detail (tất cả tabs: Overview, Curriculum, Reviews)
- [ ] `/courses/[id]/lessons/[id]` - Lesson video player
- [ ] `/exercises/list` - Exercises list với filters
- [ ] `/exercises/[id]` - Exercise detail với preview
- [ ] `/exercises/[id]/take/[id]` - Take exercise (đang làm bài)
- [ ] `/exercises/[id]/result/[id]` - Exercise result với scores
- [ ] `/my-exercises` - My Exercises (tất cả tabs)
- [ ] `/exercises/history` - Exercise history

#### Analytics & Tools
- [ ] `/progress` - Progress Analytics (tất cả tabs và time ranges)
- [ ] `/history` - Study History timeline
- [ ] `/goals` - Goals với Create dialog
- [ ] `/reminders` - Reminders với Create/Edit dialogs
- [ ] `/achievements` - Achievements (Earned và Available tabs)

#### Social & Profile
- [ ] `/notifications` - Notifications (Unread và Read groups)
- [ ] `/leaderboard` - Leaderboard với time filters
- [ ] `/profile` - My Profile với form
- [ ] `/users/[id]` - Public user profile
- [ ] `/settings` - Settings page

### 👨‍🏫 Instructor (7 ảnh)
- [ ] `/instructor` - Dashboard
- [ ] `/instructor/courses` - Courses list
- [ ] `/instructor/courses/create` - Create course form
- [ ] `/instructor/exercises` - Exercises list
- [ ] `/instructor/students` - Students management
- [ ] `/instructor/messages` - Messages với Send Announcement
- [ ] `/instructor/analytics` - Analytics

### 👨‍💼 Admin (6 ảnh)
- [ ] `/admin` - Dashboard
- [ ] `/admin/users` - User management với Create dialog
- [ ] `/admin/content` - Content moderation
- [ ] `/admin/analytics` - Analytics
- [ ] `/admin/notifications` - Notification center
- [ ] `/admin/settings` - System settings

### ✨ Bonus Features (5 ảnh)
- [ ] Command Palette (⌘K) - Global search
- [ ] Toast notifications (success/error)
- [ ] Empty states (no data)
- [ ] Loading states (skeletons)
- [ ] Dark mode toggle (settings)

---

## 🎯 CRITICAL PAGES - MUST CAPTURE

### Top Priority (10 ảnh quan trọng nhất)
1. ✅ Dashboard với stats và charts
2. ✅ Course Detail với Curriculum tab
3. ✅ Lesson video player
4. ✅ Exercise Detail với preview
5. ✅ Take Exercise (đang làm bài)
6. ✅ Exercise Result với detailed breakdown
7. ✅ Progress Analytics với charts
8. ✅ Goals với Create dialog
9. ✅ Notifications với groups
10. ✅ Profile với avatar upload

---

## 📸 SCREENSHOT FLOW ORDER

### Flow 1: New User Journey (30 phút)
```
1. Homepage (not logged in)
2. Register
3. Login
4. Dashboard (first time - có thể empty)
5. Browse Courses
6. Course Detail
7. Enroll Course
8. Lesson Detail
9. Exercises List
10. Exercise Detail
11. Start Exercise
12. Take Exercise
13. Submit Exercise
14. Exercise Result
15. My Exercises (check completed)
16. Progress (xem progress update)
17. Goals (tạo goal mới)
18. Profile (setup profile)
```

### Flow 2: Returning User (20 phút)
```
1. Homepage (logged in)
2. Dashboard (với data)
3. My Courses (In Progress tab)
4. Continue Course → Lesson
5. My Exercises (In Progress tab)
6. Continue Exercise
7. Progress Analytics (30d, 90d)
8. Achievements (check earned)
9. Reminders (active reminders)
10. Notifications (unread/read)
11. Leaderboard
```

### Flow 3: Instructor Flow (15 phút)
```
1. Login as Instructor
2. Instructor Dashboard
3. Instructor Courses
4. Create Course
5. Edit Course (add modules/lessons)
6. Instructor Exercises
7. Create Exercise
8. Students Management
9. Messages (send announcement)
10. Analytics
```

### Flow 4: Admin Flow (10 phút)
```
1. Login as Admin
2. Admin Dashboard
3. User Management (create user)
4. Content Management (review queue)
5. Analytics
6. Notifications (send bulk)
7. System Settings
```

---

## 🎨 UI STATES CẦN CHỤP

### Loading States
- [ ] SkeletonCard trong Courses/Exercises list
- [ ] PageLoading trong Dashboard
- [ ] Button loading states

### Empty States
- [ ] EmptyState trong My Courses (no courses)
- [ ] EmptyState trong My Exercises (no submissions)
- [ ] EmptyState trong Goals (no goals)
- [ ] EmptyState trong Achievements (no earned)

### Interactive States
- [ ] Hover states trên cards
- [ ] Active tab states
- [ ] Selected filters
- [ ] Form validation states

### Error States (Optional)
- [ ] Error toast notifications
- [ ] 404 page (nếu có)
- [ ] Form validation errors

---

## 💡 TIPS & TRICKS

### 1. Browser Extensions Recommended
- **Full Page Screen Capture** (Chrome extension)
- **Awesome Screenshot** hoặc **Nimbus Screenshot**

### 2. Data Preparation Script
```bash
# Đảm bảo có data để demo đẹp:
- Tạo ít nhất 5 courses
- Enroll vào 3 courses
- Complete 2 lessons
- Start 5 exercises
- Complete 3 exercises
- Tạo 3 goals
- Tạo 2 reminders
- Earn ít nhất 3 achievements
```

### 3. Viewport Settings
- Desktop: 1920x1080 (preferred) hoặc 1366x768
- Tablet: 1024x768 (optional)
- Mobile: 375x667 (optional - nếu cần demo responsive)

### 4. Screenshot Quality
- Format: PNG (lossless)
- Resolution: 2x (Retina) nếu có thể
- File size: Optimize sau khi chụp (nhưng giữ quality)

### 5. Naming Convention
```
[number]_[section]_[page]_[state].png

Ví dụ:
01_public_homepage_logged_out.png
02_auth_register_form.png
03_dashboard_overview_with_data.png
04_courses_browse_filtered.png
05_course_detail_curriculum_tab.png
06_lesson_video_player_active.png
07_exercises_list_with_filters.png
08_exercise_detail_preview_sections.png
09_take_exercise_question_1.png
10_exercise_result_detailed_breakdown.png
11_progress_analytics_study_time_chart.png
```

---

## 🔄 DEMO SCENARIOS (Use Cases)

### Scenario 1: New Student Enrollment
```
1. Browse courses
2. View course detail
3. Enroll course
4. Start first lesson
5. Watch video
6. Take notes
7. Complete lesson
8. View progress update
```

### Scenario 2: Practice Exercise Flow
```
1. Browse exercises
2. Filter by skill (e.g., Listening)
3. View exercise detail
4. Review sections preview
5. Start exercise
6. Answer questions (show timer)
7. Submit exercise
8. View detailed results
9. Check score breakdown
10. View in My Exercises
```

### Scenario 3: Progress Tracking
```
1. Dashboard (overview)
2. Progress Analytics
   - Change time range (7d → 30d → 90d)
   - View different charts
3. Study History (timeline)
4. Achievements (check earned)
5. Goals (check progress)
```

### Scenario 4: Social Features
```
1. Leaderboard (different time ranges)
2. View user profile (click từ leaderboard)
3. Follow user
4. Check notifications
5. View achievements of other users
```

---

## ✅ FINAL CHECKLIST

### Before Starting
- [ ] Server đang chạy (`npm run dev`)
- [ ] Có đủ tài khoản (Student, Instructor, Admin)
- [ ] Browser extension cho screenshot đã cài
- [ ] Thư mục lưu ảnh đã tạo
- [ ] Data đã được seed đủ

### During Demo
- [ ] Follow đúng flow trong DEMO_SCENARIO.md
- [ ] Chụp đủ các tabs và states
- [ ] Đảm bảo UI nhất quán (light/dark mode)
- [ ] Kiểm tra quality trước khi lưu

### After Demo
- [ ] Review tất cả ảnh
- [ ] Đảm bảo không thiếu trang quan trọng
- [ ] Rename files theo convention
- [ ] Organize vào folders (student/instructor/admin)

---

## 📁 FOLDER STRUCTURE SUGGESTION

```
screenshots/
├── 01-public/
│   ├── homepage.png
│   ├── register.png
│   └── login.png
├── 02-dashboard/
│   └── dashboard-overview.png
├── 03-courses/
│   ├── my-courses.png
│   ├── browse-courses.png
│   ├── course-detail.png
│   └── lesson-player.png
├── 04-exercises/
│   ├── exercises-list.png
│   ├── exercise-detail.png
│   ├── take-exercise.png
│   └── exercise-result.png
├── 05-progress/
│   ├── progress-analytics.png
│   └── study-history.png
├── 06-tools/
│   ├── goals.png
│   ├── reminders.png
│   └── achievements.png
├── 07-social/
│   ├── notifications.png
│   ├── leaderboard.png
│   └── user-profile.png
├── 08-profile/
│   ├── my-profile.png
│   └── settings.png
├── 09-instructor/
│   ├── dashboard.png
│   ├── courses.png
│   ├── exercises.png
│   └── students.png
└── 10-admin/
    ├── dashboard.png
    ├── users.png
    ├── content.png
    └── analytics.png
```

---

**Happy Screenshotting! 📸**

*See DEMO_SCENARIO.md for detailed step-by-step guide*

