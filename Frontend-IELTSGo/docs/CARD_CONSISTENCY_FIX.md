# Card Consistency Fix - Đồng Nhất My Courses & My Exercises

## ✅ Đã Sửa

### My Courses (In-Progress Tab)
**Trước:**
- badges: chỉ có 1 badge (skill_type)
- stats: 3 items (lessons, minutes, band score)

**Sau:**
- badges: 2 badges (skill_type + in_progress status) ✅
- stats: 2 items (lessons, minutes) ✅ - đồng nhất với my-exercises

### My Exercises (All Tab - In-Progress)
**Đã có:**
- badges: 2 badges (skill_type + status) ✅
- stats: conditional (score, band, time, attempt_number) ✅
- Typography: `font-medium` cho score

**Đã sửa:**
- Typography: `font-semibold text-foreground` cho score và band (đồng nhất với completed tab) ✅
- Thêm `t('score_label')` và `t('band_label')` cho consistency ✅

## 📊 Structure Nhất Quán

### In-Progress Cards
**Pattern:**
- badges: skill_type (outline) + status (color)
- stats: 2+ items (tùy context)
- progress: có progress bar
- action: default variant, primary action

**My Courses (In-Progress):**
- badges: skill_type + "in_progress" (orange)
- stats: lessons, minutes
- progress: có
- action: "continue_learning"

**My Exercises (In-Progress):**
- badges: skill_type + "in_progress" (orange)
- stats: questions answered/total, time
- progress: conditional (có nếu total_questions > 0)
- action: "continue_practice"

### Completed Cards
**Pattern:**
- badges: skill_type (outline) + "completed" (green)
- stats: 2+ items (tùy context, thường không có progress-related)
- progress: KHÔNG CÓ (đã hoàn thành)
- action: outline variant, review/view action

**My Courses (Completed):**
- badges: skill_type + "completed" (green)
- stats: lessons, minutes
- progress: không có
- action: "review_course" (outline)

**My Exercises (Completed):**
- badges: skill_type + "completed" (green)
- stats: score (nếu có), band (nếu có), time
- progress: không có
- action: "view_results" (outline)

## ✅ Kết Luận

Tất cả cards trong my-courses và my-exercises đã được đồng nhất:
- ✅ Badges structure (skill_type + status)
- ✅ Stats layout và typography
- ✅ Progress bar (chỉ trong in-progress)
- ✅ Action buttons (default trong in-progress, outline trong completed)
- ✅ Translation keys đầy đủ
- ✅ Typography consistency (`font-semibold text-foreground` cho metrics)


