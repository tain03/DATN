# Unified Card Design - My Courses & My Exercises

## 🎯 Mục Tiêu

Đồng nhất thiết kế giữa my-courses và my-exercises theo quy tắc:
- **Progress Tracking Mode** → Horizontal cards (list layout)
- **Browse/Discover Mode** → Vertical cards (grid layout)

## 📊 Thiết Kế Đồng Nhất

### Layout
- **Horizontal cards**: `grid grid-cols-1 gap-4` (list 1 cột)
- **Thumbnail**: Left side, standardized size
- **Content**: Right side với title, description, badges, stats, progress, action

### Badges (Đồng Nhất)
- **Skill type**: `variant="outline"` + `className="capitalize"`
- **Status**: 
  - `in_progress`: `bg-orange-500`
  - `completed`: `bg-green-500`
  - `not_started`: `bg-gray-500`

### Stats (Đồng Nhất Structure)
**My-Courses:**
- Lessons: `BookOpen` icon (blue-600) + `font-medium`
- Time: `Clock` icon (muted-foreground) + regular text

**My-Exercises:**
- Questions: `Target` icon (blue-600) + `font-medium` (giống lessons)
- Time: `Clock` icon (muted-foreground) + regular text
- Score (completed only): `TrendingUp` icon (green-600) + `font-semibold text-foreground`
- Band (completed only): `Award` icon (yellow-600) + `font-semibold text-foreground`

**Typography:**
- Metrics quan trọng (score, band): `font-semibold text-foreground`
- Metrics thông thường (lessons, questions, time): `font-medium` hoặc regular

### Progress Bar
- **In-Progress**: Hiển thị progress bar
- **Completed**: KHÔNG hiển thị progress bar
- **Label**: `t('progress')` (đã có trong common namespace)

### Action Button
- **In-Progress**: Default variant + "continue_learning"/"continue_practice"
- **Completed**: Outline variant + "review_course"/"view_results"

## ✅ Đã Áp Dụng

### My-Courses
- ✅ Tab "all": Vertical cards (browse mode)
- ✅ Tab "in-progress": Horizontal cards với progress bar
- ✅ Tab "completed": Horizontal cards KHÔNG có progress bar

### My-Exercises
- ✅ Tất cả tabs: Horizontal cards
- ✅ In-progress: Có progress bar
- ✅ Completed: KHÔNG có progress bar + hiển thị score & band

## 🔍 Thông Tin Hiển Thị

### My-Courses (In-Progress)
1. Thumbnail
2. Title
3. Description
4. Badges: skill_type + in_progress
5. Stats: lessons completed + time spent
6. Progress bar
7. Action: "continue_learning"

### My-Courses (Completed)
1. Thumbnail
2. Title
3. Description
4. Badges: skill_type + completed
5. Stats: lessons completed + time spent
6. **KHÔNG có** progress bar
7. Action: "review_course" (outline)

### My-Exercises (In-Progress)
1. Thumbnail
2. Title
3. Description
4. Badges: skill_type + in_progress
5. Stats: questions answered + time spent
6. Progress bar
7. Action: "continue_practice"

### My-Exercises (Completed)
1. Thumbnail
2. Title
3. Description
4. Badges: skill_type + completed
5. Stats: score + band + questions + time spent
6. **KHÔNG có** progress bar
7. Action: "view_results" (outline)

## 📐 Spacing & Typography

Tất cả tuân theo `CARD_CONFIG`:
- Horizontal gap: `gap-6` (24px)
- Stats gap: `gap-4` (16px)
- Icon size: `h-4 w-4`
- Title: `font-semibold text-lg`
- Stats: `font-medium` hoặc `font-semibold text-foreground`


