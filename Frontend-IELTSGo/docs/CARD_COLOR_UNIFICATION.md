# Card Color & Icon Unification

## ✅ Đã Đồng Nhất

### Icon Colors (Vertical & Horizontal Cards)

**Instructor:**
- Vertical: `GraduationCap` với `text-purple-600` (thay thế avatar)
- Horizontal: `GraduationCap` với `text-purple-600`
- ✅ Đồng nhất

**Rating:**
- Vertical: `Star` với `fill-yellow-400 text-yellow-400`
- Horizontal: `Star` với `fill-yellow-400 text-yellow-400`
- ✅ Đồng nhất

**Enrollments:**
- Vertical: `Users` icon (không màu)
- Horizontal: `Users` với `text-blue-600`
- ✅ Đã thêm vào horizontal để đồng nhất

**Lessons/Questions:**
- Vertical CourseCard: `BookOpen` với `text-blue-600`
- Horizontal: `BookOpen` với `text-blue-600`
- Vertical ExerciseCard: `Target` với `text-blue-600`
- Horizontal: `Target` với `text-blue-600`
- ✅ Đồng nhất

**Time/Duration:**
- Vertical: `Clock` với `text-muted-foreground`
- Horizontal: `Clock` với `text-muted-foreground`
- ✅ Đồng nhất

**Time Spent (Progress Tracking):**
- Horizontal: `TrendingUp` với `text-muted-foreground`
- ✅ Phân biệt với course duration

**Score/Average Score:**
- Vertical ExerciseCard: `TrendingUp` với `text-green-600`
- Horizontal (completed): `TrendingUp` với `text-green-600`
- ✅ Đồng nhất

**Band Score:**
- Horizontal (completed): `Award` với `text-yellow-600`
- ✅ Chỉ có trong horizontal (submission context)

## 🎨 Color Standards

### Icon Colors
- **Purple-600**: Instructor (`GraduationCap`)
- **Yellow-400**: Rating (`Star` filled)
- **Yellow-600**: Band score (`Award`)
- **Blue-600**: Lessons/Questions (`BookOpen`/`Target`), Enrollments (`Users`)
- **Green-600**: Score/Average (`TrendingUp`)
- **Muted-foreground**: Time/Duration (`Clock`), Time spent (`TrendingUp`)

### Badge Colors (Skill Types)
- **Blue-500**: Listening
- **Green-500**: Reading
- **Orange-500**: Writing
- **Purple-500**: Speaking
- **Gray-500**: General

### Badge Colors (Level/Difficulty)
- **Emerald-500**: Beginner/Easy
- **Yellow-500**: Intermediate/Medium
- **Red-500**: Advanced/Hard

### Status Colors
- **Orange-500**: In Progress
- **Green-500**: Completed
- **Gray-500**: Not Started

## 📊 Fields Added to Horizontal Cards

### My-Courses Horizontal Cards
1. ✅ **Instructor**: `GraduationCap` icon (purple-600)
2. ✅ **Rating**: `Star` icon (yellow-400) với reviews count
3. ✅ **Total Enrollments**: `Users` icon (blue-600) - **MỚI THÊM**
4. ✅ **Lessons**: `BookOpen` icon (blue-600)
5. ✅ **Time Spent/Duration**: `TrendingUp`/`Clock` icon (muted-foreground)
6. ✅ **Level Badge**: Color-coded level badge (emerald/yellow/red)

### My-Exercises Horizontal Cards
1. ✅ **Skill Type**: Badge với màu skill
2. ✅ **Status**: Badge (orange/green/gray)
3. ✅ **Score** (completed): `TrendingUp` icon (green-600)
4. ✅ **Band Score** (completed): `Award` icon (yellow-600)
5. ✅ **Questions**: `Target` icon (blue-600)
6. ✅ **Time Spent**: `Clock` icon (muted-foreground)

## ✅ Consistency Checklist

- [x] Instructor icon color đồng nhất (purple-600)
- [x] Rating icon color đồng nhất (yellow-400)
- [x] Lessons/Questions icon color đồng nhất (blue-600)
- [x] Time/Duration icon color đồng nhất (muted-foreground)
- [x] Score icon color đồng nhất (green-600)
- [x] Total enrollments được thêm vào horizontal cards
- [x] Time spent logic (TrendingUp cho time spent, Clock cho duration)


