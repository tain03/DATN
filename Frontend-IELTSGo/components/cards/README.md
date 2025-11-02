# Card Components System

Hệ thống card components có thể tái sử dụng, dễ mở rộng và maintain.

## 🎯 Mục Tiêu

- **Tái sử dụng**: Base components dùng được ở nhiều nơi
- **Dễ mở rộng**: Thêm layout/variant mới dễ dàng
- **Nhất quán**: Tất cả cards follow cùng design standards
- **Centralized Config**: Thay đổi spacing/typography ở một chỗ

## 📁 Cấu Trúc

```
components/cards/
├── card-config.ts              # Design tokens & configuration
├── base-card-layout.tsx        # Base layout components
├── README.md                   # Documentation
└── card-components.md          # Detailed guide
```

## 🚀 Quick Start

### Vertical Card (CourseCard, ExerciseCard)

```tsx
import { VerticalCardLayout } from "@/components/cards/base-card-layout"
import { Badge } from "@/components/ui/badge"
import { BookOpen } from "lucide-react"

<VerticalCardLayout
  variant="interactive"
  image={{
    src: course.thumbnail_url,
    alt: course.title,
    overlay: (
      <>
        <Badge className="absolute top-3 left-3">LISTENING</Badge>
        <Badge className="absolute top-3 right-3">BEGINNER</Badge>
      </>
    ),
    placeholder: { icon: BookOpen }
  }}
  title={course.title}
  titleHref={`/courses/${course.id}`}
  description={course.description}
  footer={{
    action: "View Course",
    href: `/courses/${course.id}`
  }}
/>
```

### Horizontal Card (my-courses, my-exercises)

```tsx
import { HorizontalCardLayout } from "@/components/cards/base-card-layout"
import { Badge } from "@/components/ui/badge"
import { BookOpen, Clock } from "lucide-react"

<HorizontalCardLayout
  variant="interactive"
  onClick={() => router.push(`/courses/${course.id}`)}
  thumbnail={{
    src: course.thumbnail_url,
    alt: course.title,
    placeholder: { icon: BookOpen }
  }}
  title={course.title}
  description={course.description}
  badges={<Badge variant="outline">{course.skill_type}</Badge>}
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
    value: 75,
    label: "Progress"
  }}
  action={{
    label: "Continue Learning",
    onClick: () => router.push(`/courses/${course.id}`)
  }}
/>
```

## ⚙️ Configuration

Tất cả design tokens được định nghĩa trong `card-config.ts`:

```ts
// Thay đổi padding cho tất cả vertical cards
CARD_CONFIG.padding.vertical.content = "p-6" // từ p-4 → p-6

// Thay đổi typography
CARD_CONFIG.typography.title.className = "font-bold text-xl" // từ font-semibold text-lg
```

## 📚 Components

### `VerticalCardLayout`

Vertical card với image trên, content dưới.

**Props:**
- `variant`: Card variant ("interactive", "default", etc.)
- `image`: Image configuration (src, alt, overlay, placeholder)
- `title`: Card title
- `titleHref`: Optional link for title
- `description`: Optional description
- `content`: Custom content (stats, meta, etc.)
- `footer`: Footer action button
- `progress`: Optional progress bar
- `onClick`: Optional click handler
- `children`: Additional custom content

### `HorizontalCardLayout`

Horizontal card với thumbnail trái, content phải.

**Props:**
- `variant`: Card variant
- `thumbnail`: Thumbnail configuration
- `title`: Card title
- `description`: Optional description
- `badges`: Badges on the right side of title
- `stats`: Stats row (icons + text)
- `progress`: Optional progress bar
- `action`: Action button in content
- `onClick`: Optional click handler
- `children`: Additional custom content

## 🔧 Customization

### Thay đổi Global Spacing

Edit `card-config.ts`:

```ts
export const CARD_CONFIG = {
  padding: {
    vertical: {
      content: "p-6", // Change from p-4 to p-6
    }
  }
}
```

### Thêm Layout Mới

1. Add config to `card-config.ts`
2. Create new component or extend `base-card-layout.tsx`

## ✅ Benefits

- **DRY**: Không duplicate code
- **Consistency**: Tất cả cards follow cùng standards
- **Maintainability**: Thay đổi ở một chỗ
- **Type Safety**: TypeScript ensures correct props
- **Flexibility**: Vẫn có thể customize cho từng use case

## 📝 Migration Guide

Để migrate existing cards:

1. Import base layout component
2. Map existing props → base component props
3. Test và verify
4. Remove old card code

Xem `card-components.md` cho detailed examples.


