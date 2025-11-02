# Card Components System - Hệ Thống Card Components

> Hệ thống card components có thể tái sử dụng, dễ mở rộng và thay đổi

## 📁 Cấu Trúc

```
components/cards/
├── card-config.ts              # Configuration & tokens
├── base-card-layout.tsx        # Base layouts (Vertical, Horizontal)
├── card-components.md          # Documentation (this file)
└── (future: specialized cards)
    ├── course-card.tsx         # Course-specific card
    ├── exercise-card.tsx       # Exercise-specific card
    └── ...
```

## 🎯 Mục Tiêu

1. **Tái sử dụng**: Base components có thể dùng ở nhiều nơi
2. **Dễ mở rộng**: Thêm layout mới, variant mới dễ dàng
3. **Nhất quán**: Tất cả cards follow cùng design standards
4. **Configurable**: Thay đổi spacing, typography ở một chỗ (card-config.ts)

## 📚 Components

### 1. `card-config.ts`

Centralized configuration file chứa tất cả design tokens:
- Padding configurations
- Spacing values
- Typography classes
- Image/thumbnail sizes
- Button styles
- Layout grids

**Lợi ích:**
- Thay đổi một chỗ → áp dụng cho tất cả cards
- Type-safe với TypeScript
- Dễ maintain và extend

### 2. `base-card-layout.tsx`

#### `VerticalCardLayout`
- **Mục đích**: Vertical cards với image trên, content dưới
- **Use cases**: CourseCard, ExerciseCard, ProductCard, etc.
- **Props**: Configurable image, title, description, content, footer, progress

#### `HorizontalCardLayout`
- **Mục đích**: Horizontal cards với thumbnail trái, content phải
- **Use cases**: my-courses, my-exercises, list items with thumbnails
- **Props**: Configurable thumbnail, title, description, badges, stats, progress, action

## 🔧 Sử Dụng

### Example 1: Vertical Card (CourseCard replacement)

```tsx
import { VerticalCardLayout } from "@/components/cards/base-card-layout"
import { Badge } from "@/components/ui/badge"
import { BookOpen, Clock, Users, Star } from "lucide-react"

function CourseCard({ course }: { course: Course }) {
  return (
    <VerticalCardLayout
      variant="interactive"
      image={{
        src: course.thumbnail_url,
        alt: course.title,
        priority: false,
        overlay: (
          <>
            <Badge className="absolute top-3 left-3">SKILL</Badge>
            <Badge className="absolute top-3 right-3">LEVEL</Badge>
          </>
        ),
        placeholder: {
          icon: BookOpen,
        }
      }}
      title={course.title}
      titleHref={`/courses/${course.id}`}
      description={course.short_description || course.description}
      content={
        <>
          {/* Custom stats */}
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <Star className="w-4 h-4" />
            <span>{course.rating}</span>
            <Users className="w-4 h-4" />
            <span>{course.enrollments}</span>
          </div>
        </>
      }
      footer={{
        action: "View Course",
        href: `/courses/${course.id}`,
      }}
      progress={showProgress ? {
        value: progress,
        label: "Progress"
      } : undefined}
    />
  )
}
```

### Example 2: Horizontal Card (my-courses replacement)

```tsx
import { HorizontalCardLayout } from "@/components/cards/base-card-layout"
import { Badge } from "@/components/ui/badge"
import { BookOpen, Clock, Target } from "lucide-react"

function CourseListItem({ course, enrollment }: Props) {
  return (
    <HorizontalCardLayout
      variant="interactive"
      onClick={() => router.push(`/courses/${course.id}`)}
      thumbnail={{
        src: course.thumbnail_url,
        alt: course.title,
        placeholder: {
          icon: BookOpen,
        }
      }}
      title={course.title}
      description={course.short_description}
      badges={
        <>
          <Badge variant="outline">{course.skill_type}</Badge>
        </>
      }
      stats={
        <>
          <div className="flex items-center gap-1">
            <BookOpen className="h-4 w-4" />
            <span>10 lessons</span>
          </div>
          <div className="flex items-center gap-1">
            <Clock className="h-4 w-4" />
            <span>45 min</span>
          </div>
        </>
      }
      progress={{
        value: enrollment.progress_percentage,
        label: "Progress"
      }}
      action={{
        label: "Continue Learning",
        onClick: (e) => {
          e.stopPropagation()
          router.push(`/courses/${course.id}`)
        }
      }}
    />
  )
}
```

## 🎨 Customization

### Thay đổi Padding cho tất cả Vertical Cards:

```ts
// card-config.ts
padding: {
  vertical: {
    content: "p-6", // Thay đổi từ p-4 → p-6
    // → Tất cả vertical cards sẽ có padding mới
  }
}
```

### Thêm Layout Mới:

1. Thêm config vào `card-config.ts`:
```ts
padding: {
  compact: {
    card: "p-0",
    content: "p-3",
  }
}
```

2. Tạo component mới hoặc extend `base-card-layout.tsx`

## ✅ Benefits

1. **DRY Principle**: Không duplicate code
2. **Consistency**: Tất cả cards follow cùng standards
3. **Maintainability**: Thay đổi ở một chỗ
4. **Type Safety**: TypeScript đảm bảo props đúng
5. **Flexibility**: Vẫn có thể customize cho từng use case

## 🚀 Migration Path

1. **Phase 1**: Tạo base components (DONE)
2. **Phase 2**: Migrate CourseCard để sử dụng VerticalCardLayout
3. **Phase 3**: Migrate ExerciseCard
4. **Phase 4**: Migrate horizontal cards trong my-courses/my-exercises
5. **Phase 5**: Update GoalCard nếu cần

## 📝 Notes

- Base components không enforce business logic (course-specific, exercise-specific)
- Business logic nên ở wrapper components (CourseCard, ExerciseCard)
- Có thể tạo specialized cards dựa trên base components nếu cần


