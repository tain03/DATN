# Card System Implementation - Hệ Thống Card Components

> Hệ thống card components có thể tái sử dụng, dễ mở rộng và maintain

## 🎯 Mục Tiêu

Tạo một hệ thống card components:
- ✅ **Tái sử dụng**: Base components dùng được ở nhiều nơi
- ✅ **Dễ mở rộng**: Thêm layout/variant mới dễ dàng
- ✅ **Nhất quán**: Tất cả cards follow cùng design standards
- ✅ **Centralized Config**: Thay đổi spacing/typography ở một chỗ

## 📁 Cấu Trúc File

```
components/cards/
├── card-config.ts              # ✅ Design tokens & configuration
├── base-card-layout.tsx        # ✅ Base layout components
├── README.md                   # ✅ Quick start guide
└── card-components.md          # ✅ Detailed documentation
```

## 🔧 Components

### 1. `card-config.ts`

Centralized configuration file chứa tất cả design tokens:

- **Padding configurations**: Vertical, horizontal, goal, stat cards
- **Spacing values**: Gap between elements, content spacing
- **Typography classes**: Title, description, stats styles
- **Image/thumbnail sizes**: Vertical (aspect-video), horizontal (fixed)
- **Button styles**: Footer vs content buttons
- **Layout grids**: Grid configurations

**Lợi ích:**
- Thay đổi một chỗ → áp dụng cho tất cả cards
- Type-safe với TypeScript
- Dễ maintain và extend

### 2. `base-card-layout.tsx`

#### `VerticalCardLayout`
- **Mục đích**: Vertical cards với image trên, content dưới
- **Use cases**: CourseCard, ExerciseCard, ProductCard, etc.
- **Props**: 
  - `image`: Configurable image/thumbnail với overlay và placeholder
  - `title`, `titleHref`: Title với optional link
  - `description`: Optional description
  - `content`: Custom content (stats, meta, etc.)
  - `footer`: Footer action button
  - `progress`: Optional progress bar
  - `variant`: Card variant (interactive, default, etc.)
  - `onClick`: Optional click handler
  - `children`: Additional custom content

#### `HorizontalCardLayout`
- **Mục đích**: Horizontal cards với thumbnail trái, content phải
- **Use cases**: my-courses, my-exercises, list items with thumbnails
- **Props**:
  - `thumbnail`: Thumbnail configuration với placeholder
  - `title`, `description`: Title and description
  - `badges`: Badges on the right side of title
  - `stats`: Stats row (icons + text)
  - `progress`: Optional progress bar
  - `action`: Action button in content
  - `variant`: Card variant
  - `onClick`: Optional click handler
  - `children`: Additional custom content

## 📚 Usage Examples

### Example 1: Vertical Card (CourseCard)

```tsx
import { VerticalCardLayout } from "@/components/cards/base-card-layout"
import { Badge } from "@/components/ui/badge"
import { BookOpen, Clock, Users, Star } from "lucide-react"

function CourseCard({ course, showProgress, progress, priority }: Props) {
  const skillColors = { listening: "bg-blue-500", reading: "bg-green-500", ... }
  const levelColors = { beginner: "bg-emerald-500", ... }
  
  return (
    <VerticalCardLayout
      variant="interactive"
      image={{
        src: course.thumbnail_url,
        alt: course.title,
        priority,
        overlay: (
          <>
            <Badge className={skillColors[skillType]}>{skillType}</Badge>
            <Badge className={levelColors[level]}>{level}</Badge>
          </>
        ),
        placeholder: { icon: BookOpen }
      }}
      title={course.title}
      titleHref={`/courses/${course.id}`}
      description={course.short_description || course.description}
      content={
        <>
          {/* Instructor */}
          {course.instructor_name && (
            <div className="flex items-center gap-2 mb-3">
              <div className="w-6 h-6 rounded-full bg-primary/10">
                <span className="text-xs font-medium text-primary">
                  {course.instructor_name.charAt(0)}
                </span>
              </div>
              <span className="text-sm text-muted-foreground">
                {course.instructor_name}
              </span>
            </div>
          )}
          
          {/* Stats */}
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
            <span>{course.rating.toFixed(1)}</span>
            <Users className="w-4 h-4" />
            <span>{course.enrollments}</span>
          </div>
          
          <div className="flex items-center gap-4 mt-3 text-sm text-muted-foreground">
            <BookOpen className="w-4 h-4" />
            <span>{course.total_lessons} lessons</span>
            <Clock className="w-4 h-4" />
            <span>{course.duration}</span>
          </div>
        </>
      }
      footer={{
        action: showProgress ? "Continue Learning" : "View Course",
        href: `/courses/${course.id}`
      }}
      progress={showProgress && progress ? {
        value: progress,
        label: "Progress"
      } : undefined}
    />
  )
}
```

### Example 2: Horizontal Card (my-courses)

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
        placeholder: { icon: BookOpen }
      }}
      title={course.title}
      description={course.short_description || course.description}
      badges={
        <Badge variant="outline">{course.skill_type}</Badge>
      }
      stats={
        <>
          <div className="flex items-center gap-1">
            <BookOpen className="h-4 w-4" />
            <span>{enrollment.lessons_completed}/{course.total_lessons} lessons</span>
          </div>
          <div className="flex items-center gap-1">
            <Clock className="h-4 w-4" />
            <span>{enrollment.total_time_spent_minutes} min</span>
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
export const CARD_CONFIG = {
  padding: {
    vertical: {
      content: "p-6", // Thay đổi từ p-4 → p-6
      // → Tất cả vertical cards sẽ có padding mới
    }
  }
}
```

### Thay đổi Typography:

```ts
export const CARD_CONFIG = {
  typography: {
    title: {
      className: "font-bold text-xl mb-3", // Thay đổi từ font-semibold text-lg mb-2
    }
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

### Phase 1: Base Components ✅
- [x] Tạo `card-config.ts` với design tokens
- [x] Tạo `VerticalCardLayout` component
- [x] Tạo `HorizontalCardLayout` component
- [x] Tạo documentation

### Phase 2: Migrate CourseCard
- [ ] Refactor `CourseCard` để sử dụng `VerticalCardLayout`
- [ ] Test và verify
- [ ] Update các trang sử dụng CourseCard

### Phase 3: Migrate ExerciseCard
- [ ] Refactor `ExerciseCard` để sử dụng `VerticalCardLayout`
- [ ] Test và verify

### Phase 4: Migrate Horizontal Cards
- [ ] Refactor horizontal cards trong `my-courses/page.tsx`
- [ ] Refactor horizontal cards trong `my-exercises/page.tsx`
- [ ] Test và verify

### Phase 5: Update GoalCard (Optional)
- [ ] Xem xét GoalCard có cần refactor không
- [ ] Có thể tạo `GoalCardLayout` nếu cần

## 📝 Notes

- Base components không enforce business logic (course-specific, exercise-specific)
- Business logic nên ở wrapper components (CourseCard, ExerciseCard)
- Có thể tạo specialized cards dựa trên base components nếu cần
- Tất cả design tokens có thể thay đổi ở `card-config.ts`

## 🔗 Related Files

- `components/cards/card-config.ts` - Configuration
- `components/cards/base-card-layout.tsx` - Base components
- `components/cards/README.md` - Quick start
- `components/cards/card-components.md` - Detailed guide
- `docs/CARD_DESIGN_STANDARDS.md` - Design standards analysis


