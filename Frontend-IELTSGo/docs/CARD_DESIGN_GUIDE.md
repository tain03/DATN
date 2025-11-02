# Card Design Guide - Thiết Kế Đồng Nhất Cho Tất Cả Cards

## 🎯 Mục tiêu
Đảm bảo tất cả các card trong hệ thống có thiết kế đồng nhất, nhất quán về:
- Spacing và padding
- Typography
- Layout structure
- Hover effects và interactions
- Image/thumbnail handling

## 📊 Phân Tích Hiện Tại

### 1. CourseCard (Vertical Layout)
- **File**: `components/courses/course-card.tsx`
- **Layout**: Vertical (image trên, content dưới)
- **Padding**: `p-4` (CardContent), `p-4 pt-0` (CardFooter)
- **Image**: `aspect-video` (responsive)
- **CardFooter**: Có
- **Card Variant**: `getCardVariant('interactive')` ✅

### 2. ExerciseCard (Vertical Layout)
- **File**: `components/exercises/exercise-card.tsx`
- **Layout**: Vertical (placeholder trên, content dưới)
- **Padding**: `p-4` (CardContent), `p-4 pt-0` (CardFooter)
- **Image**: Chỉ có placeholder gradient (không có thumbnail thực)
- **CardFooter**: Có
- **Card Variant**: `getCardVariant('interactive')` ✅

### 3. Horizontal Cards trong my-courses (in-progress, completed tabs)
- **File**: `app/my-courses/page.tsx`
- **Layout**: Horizontal (thumbnail trái, content phải)
- **Padding**: `p-6` (CardContent) ❌ Khác với CourseCard
- **Thumbnail**: `w-48 h-32` (fixed size)
- **CardFooter**: KHÔNG có ❌
- **Card Variant**: `getCardVariant('interactive')` ✅

### 4. Horizontal Cards trong my-exercises (all, in-progress, completed tabs)
- **File**: `app/my-exercises/page.tsx`
- **Layout**: Horizontal (thumbnail trái, content phải)
- **Padding**: `p-6` (CardContent) ❌ Khác với CourseCard
- **Thumbnail**: `w-48 h-32` hoặc `relative w-48 h-32` (không nhất quán)
- **CardFooter**: KHÔNG có ❌
- **Card Variant**: `getCardVariant('interactive')` ✅

### 5. GoalCard
- **File**: `components/goals/goal-card.tsx`
- **Layout**: Vertical (không có image)
- **Padding**: `pb-3` (CardHeader), `space-y-4` (CardContent)
- **CardFooter**: KHÔNG có ❌
- **Card Variant**: KHÔNG dùng `getCardVariant` ❌

## ✅ Thiết Kế Chuẩn Đồng Nhất

### A. Vertical Cards (CourseCard, ExerciseCard)
```
┌─────────────────────┐
│   Image/Thumbnail   │ aspect-video
│   (aspect-video)    │
├─────────────────────┤
│  CardContent (p-4)  │
│  - Title            │
│  - Description      │
│  - Stats/Meta       │
│  - Progress (if)    │
├─────────────────────┤
│  CardFooter (p-4    │
│           pt-0)     │
│  - Button           │
└─────────────────────┘
```

### B. Horizontal Cards (my-courses/my-exercises tabs)
```
┌──────────────────────────────────────┐
│  ┌─────────┐  CardContent (p-6)   │
│  │ Thumbnail│  - Title              │
│  │ w-48 h-32│  - Description        │
│  │         │  - Progress           │
│  │         │  - Stats               │
│  └─────────┘  - Button (in content)│
└──────────────────────────────────────┘
```

### C. GoalCard (Special)
```
┌─────────────────────┐
│ CardHeader (pb-3)   │
│ - Title             │
│ - Badges            │
│ - Dropdown Menu     │
├─────────────────────┤
│ CardContent         │
│ (space-y-4)         │
│ - Description       │
│ - Progress          │
│ - Stats             │
└─────────────────────┘
```

## 🔧 Quy Tắc Chuẩn

### 1. Padding & Spacing
- **Vertical cards**: `p-4` (CardContent), `p-4 pt-0` (CardFooter)
- **Horizontal cards**: `p-6` (CardContent) - OK vì layout khác
- **GoalCard**: `pb-3` (CardHeader), `space-y-4` (CardContent) - OK vì special layout
- **Gap**: `gap-6` cho horizontal layout

### 2. Typography
- **Title**: `font-semibold text-lg` hoặc `text-xl font-bold` - cần chuẩn hóa
- **Description**: `text-sm text-muted-foreground line-clamp-2`
- **Stats**: `text-sm text-muted-foreground`

### 3. Image/Thumbnail
- **Vertical cards**: `aspect-video` (responsive)
- **Horizontal cards**: `w-48 h-32` (fixed, rounded-lg)
- **Placeholder**: Gradient `bg-gradient-to-br from-primary/20 to-accent/20` với icon

### 4. Card Variant
- **Tất cả interactive cards**: Phải dùng `getCardVariant('interactive')`
- **GoalCard**: Nên dùng `getCardVariant('interactive')` hoặc `getCardVariant('default')`

### 5. Layout Consistency
- **Vertical cards** (grid): `grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6`
- **Horizontal cards** (list): `grid-cols-1 gap-4`

## 🎨 Các Vấn Đề Cần Sửa

### Issue 1: ExerciseCard không có thumbnail support
- **Hiện tại**: Chỉ có placeholder gradient
- **Nên**: Support thumbnail nếu có trong data

### Issue 2: Horizontal cards spacing không nhất quán
- **my-courses**: `p-6` ✅
- **my-exercises**: `p-6` ✅
- **Nhưng**: Khác với vertical cards `p-4` - cần giữ như vậy vì layout khác

### Issue 3: Horizontal cards thiếu description ở một số chỗ
- **my-courses/in-progress**: Có description ✅
- **my-courses/completed**: Thiếu description ❌
- **my-exercises/in-progress**: Thiếu description ❌

### Issue 4: GoalCard không dùng getCardVariant
- Cần thêm `getCardVariant('interactive')` hoặc variant phù hợp

### Issue 5: Typography không nhất quán
- **CourseCard**: `font-semibold text-lg`
- **Horizontal cards**: `text-xl font-bold`
- Cần chuẩn hóa: `font-semibold text-lg` hoặc `text-xl font-semibold`

### Issue 6: Button styles không nhất quán
- **CourseCard**: Button trong CardFooter, `w-full`
- **Horizontal cards**: Button trong content, size khác nhau (`size="sm"` hoặc không)

### Issue 7: Thumbnail size trong horizontal cards
- Có chỗ dùng `w-48 h-32`, có chỗ dùng `relative w-48 h-32` - cần chuẩn hóa

### Issue 8: Image component
- Có chỗ dùng `<img>`, có chỗ dùng `Image` - đã sửa, cần kiểm tra lại

## ✅ Action Items

1. ✅ Chuẩn hóa spacing: Giữ `p-6` cho horizontal, `p-4` cho vertical
2. ✅ Thêm description cho horizontal cards thiếu
3. ✅ Chuẩn hóa typography: `font-semibold text-lg` cho tất cả titles
4. ✅ Chuẩn hóa button: `w-full` cho tất cả buttons trong cards
5. ✅ Áp dụng `getCardVariant` cho GoalCard
6. ✅ Đảm bảo tất cả dùng Image component, không dùng `<img>`
7. ✅ Support thumbnail cho ExerciseCard nếu có data
8. ✅ Chuẩn hóa thumbnail size: `relative w-48 h-32` cho horizontal cards


