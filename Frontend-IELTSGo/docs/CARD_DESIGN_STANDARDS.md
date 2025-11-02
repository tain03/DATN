# Card Design Standards - Quy Chuẩn Thiết Kế Card Thực Tế

> Phân tích quy chuẩn thiết kế card dựa trên code thực tế trong hệ thống

---

## 📐 Base Card Component (`components/ui/card.tsx`)

### Cấu trúc mặc định:

```tsx
<Card>
  // Base: rounded-xl border py-6 shadow-sm gap-6
  // - py-6: padding vertical 24px (top & bottom)
  // - gap-6: gap giữa các children 24px
  
  <CardHeader>
    // Base: px-6 (padding horizontal 24px)
    // Grid layout với auto-rows-min
    
    <CardTitle>
      // Base: leading-none font-semibold
    </CardTitle>
    
    <CardDescription>
      // Base: text-muted-foreground text-sm
    </CardDescription>
  </CardHeader>
  
  <CardContent>
    // Base: px-6 (chỉ padding horizontal 24px, KHÔNG có py)
  </CardContent>
  
  <CardFooter>
    // Base: px-6 flex items-center
  </CardFooter>
</Card>
```

**Lưu ý quan trọng:**
- Card base có `py-6` (vertical padding 24px)
- CardContent base chỉ có `px-6` (horizontal padding), KHÔNG có vertical padding
- CardFooter base chỉ có `px-6` (horizontal padding)

---

## 🎨 Card Variants (`lib/utils/card-variants.ts`)

### 1. Default Card
```tsx
"bg-card border shadow-sm"
```
- Background: `bg-card`
- Border: `border` (1px solid)
- Shadow: `shadow-sm` (subtle shadow)

### 2. Interactive Card (cho clickable cards)
```tsx
"bg-card border shadow-sm hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200 cursor-pointer"
```
- Base giống default
- **Hover**: `shadow-lg` + `-translate-y-0.5` (lift effect)
- **Transition**: `duration-200`
- **Cursor**: `cursor-pointer`

### 3. Highlight Card
```tsx
"bg-gradient-to-br from-card to-accent/30 border shadow-sm"
```
- Gradient background từ card đến accent/30

### 4. Gradient Variants
- `blue`, `green`, `purple`, `orange`
- Mỗi variant có light/dark mode support

**Usage:**
```tsx
<Card className={cn(getCardVariant('interactive'))}>
```

---

## 📋 Card Component Patterns Thực Tế

### Pattern 1: Vertical Cards với Image (CourseCard, ExerciseCard)

```tsx
<Card className={cn(
  "group overflow-hidden p-0",  // ⚠️ Override py-6 thành p-0
  getCardVariant('interactive')
)}>
  {/* Image Section */}
  <div className="relative aspect-video">
    <Image ... />
    <Badge>...</Badge>
  </div>
  
  <CardContent className="p-4">  // ⚠️ Override px-6 thành p-4
    <h3 className="font-semibold text-lg mb-2">Title</h3>
    <p className="text-sm text-muted-foreground line-clamp-2 mb-3">Description</p>
    {/* Stats */}
  </CardContent>
  
  <CardFooter className="p-4 pt-0">  // ⚠️ Override px-6 thành p-4 pt-0
    <Button className="w-full">Action</Button>
  </CardFooter>
</Card>
```

**Đặc điểm:**
- Card: `p-0` (loại bỏ base `py-6`)
- CardContent: `p-4` (16px all sides)
- CardFooter: `p-4 pt-0` (16px, nhưng top = 0)
- Image: `aspect-video` (responsive 16:9)

---

### Pattern 2: Horizontal Cards (my-courses/my-exercises tabs)

```tsx
<Card className={cn(
  "cursor-pointer",
  getCardVariant('interactive')
)}>
  {/* ⚠️ KHÔNG override Card base, vẫn có py-6 */}
  
  <CardContent className="p-6">  // ⚠️ Override px-6 thành p-6
    <div className="flex items-start gap-6">
      {/* Thumbnail */}
      <div className="relative w-48 h-32 bg-muted rounded-lg">
        <Image ... />
      </div>
      
      {/* Content */}
      <div className="flex-1">
        <h3 className="font-semibold text-lg mb-1">Title</h3>
        <p className="text-sm text-muted-foreground line-clamp-2">Description</p>
        {/* Progress, Stats */}
        <Button className="w-full mt-4">Action</Button>
      </div>
    </div>
  </CardContent>
  {/* ⚠️ KHÔNG có CardFooter */}
</Card>
```

**Đặc điểm:**
- Card: Giữ nguyên `py-6` từ base
- CardContent: `p-6` (24px all sides) - LỚN HƠN vertical cards
- Layout: `flex items-start gap-6`
- Thumbnail: `w-48 h-32` (fixed size, không responsive)
- KHÔNG có CardFooter (button trong CardContent)

**⚠️ Vấn đề:**
- Base Card có `py-6` nên card sẽ có padding top/bottom 24px
- CardContent có `p-6` nên có thêm 24px padding all sides
- → Tổng padding vertical: 24px (Card) + 24px (CardContent) = 48px ❌ Có thể quá nhiều

---

### Pattern 3: GoalCard (Special Layout)

```tsx
<Card className={cn(
  getCardVariant('interactive')
  // ⚠️ KHÔNG override Card base
)}>
  <CardHeader className="pb-3">  // ⚠️ Override padding bottom
    <CardTitle className="font-semibold text-lg mb-2">Title</CardTitle>
    {/* Badges, Dropdown */}
  </CardHeader>
  
  <CardContent className="space-y-4">  // ⚠️ Override thành space-y-4
    {/* Description, Progress, Stats */}
  </CardContent>
  {/* ⚠️ KHÔNG có CardFooter */}
</Card>
```

**Đặc điểm:**
- Card: Giữ nguyên base padding
- CardHeader: `pb-3` (padding bottom 12px)
- CardContent: `space-y-4` (vertical spacing 16px giữa children)
- KHÔNG có CardFooter

---

### Pattern 4: Dashboard Stat Cards

```tsx
<Card>
  {/* Giữ nguyên base padding */}
  <CardContent className="p-5 relative">  // ⚠️ p-5 (20px) - khác với các pattern khác
    <div className="flex items-start gap-4">
      {/* Content */}
    </div>
  </CardContent>
</Card>
```

**Đặc điểm:**
- CardContent: `p-5` (20px) - KHÁC với pattern khác (`p-4` hoặc `p-6`)
- Thường dùng cho stat cards với icon

---

## 🔍 So Sánh Padding Patterns

| Pattern | Card Base | CardContent | CardFooter | Total Vertical Padding |
|---------|-----------|-------------|------------|------------------------|
| **Vertical Cards** | `p-0` | `p-4` (16px) | `p-4 pt-0` | 16px (chỉ CardContent) |
| **Horizontal Cards** | `py-6` (24px) | `p-6` (24px) | ❌ | 48px (Card + Content) |
| **GoalCard** | `py-6` (24px) | `px-6` + `space-y-4` | ❌ | 24px (Card) |
| **Dashboard Stats** | `py-6` (24px) | `p-5` (20px) | ❌ | 44px (Card + Content) |

**⚠️ Vấn đề không nhất quán:**
- Horizontal cards có padding vertical TỔNG CỘNG 48px (quá nhiều?)
- Dashboard stats dùng `p-5` (không theo scale 8px)
- Mỗi pattern override base padding khác nhau

---

## 📐 Typography Standards

### Title Typography:

| Component | Pattern | Size | Weight | Notes |
|-----------|---------|------|--------|-------|
| **CourseCard** | `font-semibold text-lg` | 18px | 600 | ✅ Chuẩn |
| **ExerciseCard** | `font-semibold text-lg` | 18px | 600 | ✅ Chuẩn |
| **Horizontal Cards** | `font-semibold text-lg` | 18px | 600 | ✅ Đã chuẩn hóa |
| **GoalCard** | `font-semibold text-lg` | 18px | 600 | ✅ Chuẩn |

**✅ Đã đồng nhất:** Tất cả dùng `font-semibold text-lg`

### Description Typography:
- Pattern: `text-sm text-muted-foreground line-clamp-2`
- Size: 14px
- Color: `text-muted-foreground`
- Truncate: 2 lines

### Stats Typography:
- Pattern: `text-sm text-muted-foreground`
- Size: 14px
- Color: `text-muted-foreground`
- Icons: `w-4 h-4` (16px)

---

## 🖼️ Image/Thumbnail Standards

### Vertical Cards:
```tsx
<div className="relative aspect-video overflow-hidden bg-muted">
  <Image fill className="object-cover" sizes="..." />
</div>
```
- **Aspect Ratio**: `aspect-video` (16:9, responsive)
- **Position**: `relative` + `fill`
- **Sizes**: Responsive breakpoints

### Horizontal Cards:
```tsx
<div className="relative w-48 h-32 bg-muted rounded-lg flex-shrink-0 overflow-hidden">
  <Image fill className="object-cover" sizes="192px" />
</div>
```
- **Size**: `w-48 h-32` (192px × 128px, fixed)
- **Aspect Ratio**: 3:2 (khác với vertical cards)
- **Position**: `relative` + `fill`
- **Rounded**: `rounded-lg`

### Placeholder:
```tsx
<div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary/20 to-accent/20">
  <Icon className="w-16 h-16 text-muted-foreground" />
</div>
```
- **Background**: Gradient `from-primary/20 to-accent/20`
- **Icon**: `w-16 h-16` (64px)

---

## 🎯 Button Standards trong Cards

### Vertical Cards (CardFooter):
```tsx
<CardFooter className="p-4 pt-0">
  <Button asChild className="w-full">
    <Link>Action</Link>
  </Button>
</CardFooter>
```
- **Width**: `w-full`
- **Position**: Trong CardFooter riêng

### Horizontal Cards (trong CardContent):
```tsx
<div className="mt-4">
  <Button className="w-full">Action</Button>
</div>
```
- **Width**: `w-full`
- **Position**: Trong CardContent, cuối content
- **Spacing**: `mt-4` (16px top margin)

**✅ Đã đồng nhất:** Tất cả buttons trong cards dùng `w-full`

---

## 📊 Summary - Quy Chuẩn Thực Tế

### ✅ Nhất Quán:

1. **Card Variants:**
   - Tất cả interactive cards: `getCardVariant('interactive')` ✅
   
2. **Typography:**
   - Title: `font-semibold text-lg` ✅
   - Description: `text-sm text-muted-foreground line-clamp-2` ✅
   - Stats: `text-sm text-muted-foreground` ✅

3. **Button trong cards:**
   - Tất cả: `w-full` ✅

4. **Horizontal layout:**
   - Gap: `gap-6` ✅
   - Thumbnail: `w-48 h-32` ✅

### ⚠️ Không Nhất Quán:

1. **Padding:**
   - Vertical cards: `p-4` (16px)
   - Horizontal cards: `p-6` (24px) + Card base `py-6` = 48px total
   - Dashboard stats: `p-5` (20px)

2. **Card Structure:**
   - Vertical cards: CardContent + CardFooter
   - Horizontal cards: Chỉ CardContent (không có Footer)
   - GoalCard: CardHeader + CardContent (không có Footer)

3. **Base Padding Override:**
   - Vertical cards: `p-0` (loại bỏ hoàn toàn)
   - Horizontal cards: Giữ nguyên base `py-6`
   - GoalCard: Giữ nguyên base, chỉ override CardHeader `pb-3`

---

## 💡 Recommendations

### 1. Chuẩn hóa Padding Pattern:

**Option A: Consistent với Base Card**
- Giữ nguyên Card base `py-6`
- CardContent dùng `px-6` (default) hoặc override cụ thể
- → Nhất quán nhưng có thể quá nhiều padding cho một số cards

**Option B: Override cho tất cả**
- Vertical cards: `p-0` trên Card, `p-4` trên CardContent/Footer
- Horizontal cards: `p-0` trên Card, `p-6` trên CardContent
- → Nhất quán nhưng phải override nhiều

**Option C: Thêm Card Variants mới**
```tsx
cardVariants = {
  compact: "p-0", // Cho vertical cards
  default: "py-6", // Cho horizontal cards
  ...
}
```

### 2. Chuẩn hóa Card Structure:

- **Vertical cards**: Luôn có CardFooter
- **Horizontal cards**: Có thể không có CardFooter (button trong content)
- **GoalCard**: Special case, OK

### 3. Typography: ✅ Đã đồng nhất

---

## 📝 Notes

- Base Card component có `py-6` và `gap-6` built-in
- CardContent chỉ có `px-6` (không có vertical padding)
- Mỗi pattern override base padding khác nhau
- Horizontal cards có tổng padding vertical lớn nhất (48px)


