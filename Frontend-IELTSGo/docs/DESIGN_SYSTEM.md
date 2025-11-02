# 🎨 IELTSGo Design System & UI/UX Guidelines

> Tài liệu thiết kế hệ thống cho nền tảng học IELTS online - Đảm bảo tính nhất quán và trải nghiệm người dùng tối ưu

---

## 📋 Mục lục

1. [Tổng quan Design System](#1-tổng-quan-design-system)
2. [Brand Identity & Colors](#2-brand-identity--colors)
3. [Typography System](#3-typography-system)
4. [Spacing & Layout](#4-spacing--layout)
5. [Component Library](#5-component-library)
6. [Interaction Patterns](#6-interaction-patterns)
7. [User Flows & Wireframes](#7-user-flows--wireframes)
8. [Accessibility Guidelines](#8-accessibility-guidelines)
9. [Responsive Design](#9-responsive-design)
10. [Improvements & Recommendations](#10-improvements--recommendations)

---

## 1. Tổng quan Design System

### 1.1. Design Principles

**IELTSGo Design System** được xây dựng dựa trên 5 nguyên tắc cốt lõi:

#### 🎯 1. UX-First (Người dùng là trung tâm)
- Mỗi quyết định thiết kế đều hướng tới mục tiêu: giúp học viên học IELTS hiệu quả hơn
- Giảm thiểu cognitive load - người dùng không cần suy nghĩ nhiều để sử dụng
- Focus on task completion, không phải "đẹp mà vô dụng"

#### 🧭 2. Clear Navigation (Điều hướng rõ ràng)
- **3-click rule**: Người dùng có thể đến bất kỳ chức năng chính nào trong 3 lần click
- **Visual hierarchy**: Sử dụng size, color, spacing để phân cấp thông tin
- **Consistent patterns**: Mọi trang đều có cấu trúc điều hướng tương tự

#### 🎨 3. Visual Consistency (Nhất quán về mặt hình ảnh)
- **Color**: Palette thống nhất trên toàn bộ ứng dụng
- **Typography**: Font system nhất quán
- **Components**: Tái sử dụng component để đảm bảo tính nhất quán
- **Spacing**: Grid system 8px base unit

#### 📱 4. Mobile-First & Responsive
- Thiết kế bắt đầu từ mobile (320px)
- Progressive enhancement lên tablet, desktop
- Touch-friendly: buttons ≥ 44x44px, spacing đủ rộng

#### ♿ 5. Accessibility First
- WCAG 2.1 AA compliance
- Contrast ratio ≥ 4.5:1 cho text thường, 3:1 cho text lớn
- Keyboard navigation đầy đủ
- Screen reader support

---

## 2. Brand Identity & Colors

### 2.1. Brand Colors

#### Primary Colors (Màu chính)

```css
/* Primary Red - #ED372A */
--primary: oklch(0.55 0.22 25);
--primary-foreground: oklch(1 0 0);
```
**Usage:**
- Primary actions: buttons, links, CTAs
- Brand elements: logo, highlights
- Status indicators: errors, warnings

**Rationale:** 
- Red tạo cảm giác urgency và motivation (phù hợp cho học tập)
- Đủ contrast để dễ nhìn trên nền trắng/đen
- Tạo điểm nhấn, thu hút attention đến actions quan trọng

#### Secondary Colors (Màu phụ)

```css
/* Secondary Dark - #101615 */
--secondary: oklch(0.97 0 0);
--secondary-foreground: oklch(0.145 0 0);
```
**Usage:**
- Secondary buttons
- Headers, footers
- Dark mode backgrounds

**Rationale:**
- Tạo contrast với primary red
- Professional, trustworthy feeling

#### Accent Colors (Màu nhấn)

```css
/* Cream - #FEF7EC */
--accent: oklch(0.98 0.02 80);
--accent-foreground: oklch(0.145 0 0);
```
**Usage:**
- Subtle backgrounds
- Card highlights
- Hover states

**Rationale:**
- Warm, inviting tone
- Tạo depth và visual interest mà không quá nổi bật

### 2.2. Semantic Colors (Màu ngữ nghĩa)

```css
/* Success */
--success: oklch(0.6 0.118 184.704); /* Green */

/* Warning */
--warning: oklch(0.828 0.189 84.429); /* Yellow/Orange */

/* Error/Destructive */
--destructive: oklch(0.577 0.245 27.325); /* Red */

/* Info */
--info: oklch(0.398 0.07 227.392); /* Blue */
```

### 2.3. Neutral Colors (Màu trung tính)

```css
/* Background */
--background: oklch(1 0 0); /* White */

/* Foreground (Text) */
--foreground: oklch(0.145 0 0); /* Near Black */

/* Muted (Secondary text) */
--muted: oklch(0.97 0 0); /* Light Gray */
--muted-foreground: oklch(0.556 0 0); /* Medium Gray */

/* Border */
--border: oklch(0.922 0 0); /* Light Gray */

/* Card */
--card: oklch(1 0 0); /* White */
```

### 2.4. Dark Mode Colors

Tất cả màu đều được optimize cho Dark Mode với contrast ratio đảm bảo readability.

### 2.5. Color Usage Guidelines

#### ✅ DO:
- Sử dụng Primary cho primary actions (Save, Submit, Continue)
- Sử dụng Muted cho secondary text, descriptions
- Sử dụng Semantic colors cho feedback (success, error, warning)

#### ❌ DON'T:
- Không dùng Primary cho quá nhiều elements (sẽ làm mất hiệu quả)
- Không tạo custom colors ngoài palette (sẽ phá vỡ consistency)
- Không dùng màu đỏ cho text content (khó đọc, tạo cảm giác negative)

---

## 3. Typography System

### 3.1. Font Families

```css
/* Heading Font - Noto Sans Display */
--font-heading: 'Noto Sans Display', sans-serif;

/* Body Font - Noto Sans */
--font-sans: 'Noto Sans', sans-serif;
```

**Rationale:**
- **Noto Sans**: Clean, readable, hỗ trợ Vietnamese tốt
- **Noto Sans Display**: Modern, professional cho headings
- Đều từ Google Fonts, free và tốc độ load nhanh

### 3.2. Type Scale (Responsive)

| Scale | Mobile | Desktop | Usage |
|-------|--------|---------|-------|
| **H1** | 2rem (32px) | 2.25rem (36px) | Page titles |
| **H2** | 1.75rem (28px) | 1.875rem (30px) | Section titles |
| **H3** | 1.5rem (24px) | 1.5rem (24px) | Subsection titles |
| **H4** | 1.25rem (20px) | 1.25rem (20px) | Card titles |
| **Body** | 1rem (16px) | 1rem (16px) | Default text |
| **Small** | 0.875rem (14px) | 0.875rem (14px) | Captions, labels |
| **Tiny** | 0.75rem (12px) | 0.75rem (12px) | Helper text |

**Font Size Scaling:**
- System hỗ trợ user font size preferences (Small/Medium/Large)
- Tất cả sử dụng `rem` để scale theo base font size

### 3.3. Font Weights

```css
400 - Regular  /* Body text */
500 - Medium   /* Emphasized text, labels */
600 - Semibold /* Subheadings */
700 - Bold     /* Headings, CTAs */
```

### 3.4. Line Heights

- **Headings**: 1.2 - 1.4 (tight, compact)
- **Body**: 1.5 - 1.6 (comfortable reading)
- **Small text**: 1.4

### 3.5. Typography Usage Guidelines

#### Headings (H1-H6)
```tsx
// ✅ Correct
<h1 className="text-3xl font-bold">Dashboard</h1>
<h2 className="text-2xl font-semibold">My Courses</h2>

// ❌ Incorrect - Don't style headings like body text
<p className="text-3xl font-bold">Dashboard</p>
```

#### Body Text
```tsx
// ✅ Correct
<p className="text-base text-muted-foreground">
  Track your progress and continue learning
</p>

// ❌ Incorrect - Don't use heading styles for body
<p className="text-3xl font-bold">Description text</p>
```

---

## 4. Spacing & Layout

### 4.1. Spacing Scale (8px Base Unit)

```css
/* Tailwind spacing scale */
0px   = 0
4px   = 0.5
8px   = 1
12px  = 1.5
16px  = 2
24px  = 3
32px  = 4
40px  = 5
48px  = 6
64px  = 8
80px  = 10
96px  = 12
128px = 16
```

**Rationale:**
- 8px base unit tạo visual rhythm
- Dễ tính toán và maintain
- Tạo consistency trong layout

### 4.2. Layout Grid

#### Container Max Widths

```tsx
sm:  640px   // Small screens
md:  768px   // Tablets
lg:  1024px  // Desktop
xl:  1280px  // Large desktop
2xl: 1536px  // Extra large
4xl: 896px   // Content width (optimal reading)
6xl: 1152px  // Wide content
7xl: 1280px  // Full width on large screens
```

#### Page Container Padding

```tsx
// Horizontal padding
Mobile:  px-4 (16px)
Tablet:  px-6 (24px)
Desktop: px-8 (32px)

// Vertical padding
Default: py-5 sm:py-6 lg:py-8
```

### 4.3. Component Spacing

```tsx
// Card padding
CardContent: p-6 (24px)

// Button padding
Default: px-4 py-2
Large:   px-6 py-3

// Input padding
px-3 py-1

// Section spacing
mb-8 (32px) for sections
gap-4 (16px) for grid items
gap-6 (24px) for larger grids
```

---

## 5. Component Library

### 5.1. Button Component

#### Variants

```tsx
// Primary (default)
<Button variant="default">
  Đăng nhập
</Button>
// bg-primary, text-white, hover:bg-primary/90

// Secondary
<Button variant="secondary">
  Hủy
</Button>
// bg-secondary, text-secondary-foreground

// Outline
<Button variant="outline">
  Xem thêm
</Button>
// border, bg-transparent, hover:bg-accent

// Ghost
<Button variant="ghost">
  Bỏ qua
</Button>
// transparent, hover:bg-accent

// Destructive
<Button variant="destructive">
  Xóa
</Button>
// bg-destructive, text-white
```

#### Sizes

```tsx
sm:  h-8 px-3    // Small buttons, inline actions
default: h-9 px-4  // Standard buttons
lg:  h-10 px-6   // Prominent CTAs
icon: size-9     // Icon-only buttons
```

#### Usage Guidelines

**✅ DO:**
- Primary cho main action (Save, Submit, Continue)
- Outline cho secondary actions
- Ghost cho tertiary actions
- Destructive cho destructive actions (Delete, Remove)

**❌ DON'T:**
- Không dùng quá nhiều primary buttons trên 1 trang
- Không đổi màu tự do (phá vỡ semantic meaning)

### 5.2. Card Component

#### Structure

```tsx
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
    <CardDescription>Description</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Content */}
  </CardContent>
  <CardFooter>
    {/* Actions */}
  </CardFooter>
</Card>
```

#### Styling Variants

```tsx
// Default Card
<Card className="shadow-sm border">
  {/* Subtle shadow, light border */}
</Card>

// Interactive Card
<Card className="hover:shadow-lg transition-shadow cursor-pointer">
  {/* Hover effect for clickable cards */}
</Card>

// Gradient Card (for special highlights)
<Card className="bg-gradient-to-br from-white to-blue-50/50">
  {/* Subtle gradient background */}
</Card>
```

### 5.3. Input Components

#### Text Input

```tsx
<FormField
  label="Email"
  type="email"
  placeholder="email@example.com"
  required
  error={errors.email}
/>
```

**Features:**
- Auto focus ring (primary color)
- Error state với red border + message
- Disabled state với opacity 50%
- Placeholder text với muted color

#### Textarea

```tsx
<FormField
  label="Bio"
  type="textarea"
  rows={3}
  placeholder="Tell us about yourself"
/>
```

### 5.4. Navigation Components

#### Sidebar

```tsx
<Sidebar>
  {/* Logo */}
  {/* Navigation items */}
  {/* User profile */}
</Sidebar>
```

**Features:**
- Collapsible (desktop)
- Mobile: overlay với backdrop
- Active state highlighting
- Icon + text labels

#### PageHeader

```tsx
<PageHeader
  title="Dashboard"
  subtitle="Track your progress"
  centerContent={<TimeRangeFilters />}
  rightActions={<Button>Action</Button>}
/>
```

**Layout:**
- **Left**: Title + Subtitle
- **Center**: Optional filters/actions
- **Right**: Language, Notifications, User menu + custom actions

### 5.5. Data Display Components

#### StatCard

```tsx
<StatCard
  title="Courses in Progress"
  value={5}
  description="3 completed"
  icon={BookOpen}
/>
```

#### ProgressChart

```tsx
<ProgressChart
  title="Study Time (30 Days)"
  data={studyData}
  color="#ED372A"
  valueLabel="minutes"
/>
```

#### ActivityTimeline

```tsx
<ActivityTimeline activities={activities} />
```

---

## 6. Interaction Patterns

### 6.1. Hover States

#### Buttons
```css
/* Primary */
hover:bg-primary/90        /* Slightly darker */

/* Outline */
hover:bg-accent           /* Light background */
hover:text-accent-foreground

/* Ghost */
hover:bg-accent/50        /* Subtle highlight */
```

#### Cards
```css
/* Interactive Card */
hover:shadow-lg           /* Larger shadow */
hover:-translate-y-1     /* Slight lift */
transition-all duration-200
```

#### Links
```css
hover:underline
hover:text-primary
transition-colors duration-150
```

### 6.2. Active States

```css
/* Button active */
active:scale-[0.98]       /* Subtle press effect */

/* Tab active */
data-[state=active]:bg-background
data-[state=active]:shadow-sm
```

### 6.3. Focus States

```css
/* Keyboard navigation */
focus-visible:ring-ring/50
focus-visible:ring-[3px]
focus-visible:outline-none
```

**Rationale:**
- Rõ ràng nhưng không quá nổi bật
- Hỗ trợ keyboard navigation
- WCAG compliant

### 6.4. Loading States

```tsx
// Button loading
<Button disabled>
  <Loader2 className="animate-spin mr-2" />
  Đang tải...
</Button>

// Page loading
<div className="flex items-center justify-center h-64">
  <Loader2 className="w-8 h-8 animate-spin text-primary" />
  <p className="text-muted-foreground ml-4">Đang tải...</p>
</div>

// Skeleton loading
<Skeleton className="h-4 w-full" />
```

### 6.5. Empty States

```tsx
<Card>
  <CardContent className="py-12 text-center">
    <BookOpen className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
    <h3 className="text-lg font-semibold mb-2">No courses yet</h3>
    <p className="text-muted-foreground mb-6">
      Start your IELTS journey by enrolling in a course
    </p>
    <Button onClick={() => router.push('/courses')}>
      Browse Courses
    </Button>
  </CardContent>
</Card>
```

**Components:**
- Icon (large, muted)
- Title (semibold)
- Description (muted)
- CTA button

### 6.6. Error States

```tsx
// Form error
<Alert variant="destructive">
  <AlertDescription>
    {errors.general || "Something went wrong"}
  </AlertDescription>
</Alert>

// Inline field error
<FormField
  error={errors.email}
  // Shows red border + error message below
/>
```

### 6.7. Success States

```tsx
<Alert className="bg-green-50 border-green-200">
  <CheckCircle2 className="h-4 w-4 text-green-600" />
  <AlertDescription className="text-green-800">
    Profile updated successfully
  </AlertDescription>
</Alert>
```

### 6.8. Micro-interactions

#### Smooth Transitions

```css
/* Standard transitions */
transition-all duration-200    /* Cards, buttons */
transition-colors duration-150 /* Hover states */
transition-transform duration-200 /* Movements */

/* Specific transitions */
transition-shadow duration-200 /* Shadow changes */
```

#### Animations

```css
/* Spinner */
@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Fade in */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Slide up */
@keyframes slideUp {
  from { transform: translateY(10px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

---

## 7. User Flows & Wireframes

### 7.1. Authentication Flow

#### Flow Diagram

```
Landing Page
    ↓
[Login] or [Register]
    ↓
Login Form → API → Success → Dashboard
    ↓
Register Form → API → Success → Email Verification → Dashboard
```

#### Login Page Design

**Layout:**
```
┌─────────────────────────────────────────┐
│              [Navbar]                    │
├─────────────────────────────────────────┤
│                                          │
│  ┌──────────┐      ┌──────────────┐     │
│  │  Logo    │      │   Promo      │     │
│  │          │      │   Content    │     │
│  │ Email    │      │              │     │
│  │ Password │      │  Statistics  │     │
│  │          │      │              │     │
│  │ [Login]  │      │              │     │
│  │          │      │              │     │
│  │ Google   │      │              │     │
│  └──────────┘      └──────────────┘     │
│                                          │
└─────────────────────────────────────────┘
```

**Key Elements:**
- Split layout: Form (left) + Promo (right)
- Clear CTA: Primary button "Đăng nhập"
- Social login option
- Forgot password link
- Link to register

**UX Considerations:**
- Auto-focus email field
- Show/hide password toggle
- Validation errors inline
- Loading state on submit
- Remember me checkbox

### 7.2. Dashboard Flow

#### Flow Diagram

```
Dashboard
    ↓
[View Stats] → Quick Actions → [Navigate to Course/Exercise/Goals]
    ↓
[Change Time Range] → Update Charts
    ↓
[View Activity Timeline] → Click Activity → Detail Page
```

#### Dashboard Layout

**Header:**
```
┌────────────────────────────────────────────────────────┐
│ Welcome Back, [Name]!    [7d][30d][90d][All]    [Lang][🔔][👤] │
│ Track your journey...                                  │
└────────────────────────────────────────────────────────┘
```

**Content:**
```
┌────────────────────────────────────────────────────────┐
│ [Quick Actions: Courses | Exercises | Goals]            │
├────────────────────────────────────────────────────────┤
│ [Stat Cards: 5 cards in grid]                          │
├────────────────────────────────────────────────────────┤
│ [Tabs: Overview | Analytics | Skills]                   │
│                                                         │
│ ┌──────────────┐  ┌────────────────────────────────┐ │
│ │ Study Time   │  │ Activity Timeline               │ │
│ │ Chart        │  │ • Lesson - 2h ago              │ │
│ │              │  │ • Exercise - 5h ago            │ │
│ └──────────────┘  └────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

**UX Considerations:**
- Personalized welcome message
- Time range filters easily accessible
- Quick actions for common tasks
- Visual stats at a glance
- Recent activity for context

### 7.3. Course Learning Flow

#### Flow Diagram

```
Courses List
    ↓
[Filter/Search] → Results
    ↓
[Select Course] → Course Detail
    ↓
[Enroll] → My Courses
    ↓
[Continue Learning] → Lesson/Module
    ↓
[Complete Lesson] → Progress Update → Next Lesson
```

#### Course Card Design

```
┌────────────────────────────────────┐
│ [Thumbnail Image]                  │
│                                    │
│ IELTS Speaking Basics              │
│ Complete guide to fundamentals     │
│                                    │
│ [Badge: FREE] [Level: Beginner]   │
│                                    │
│ 📚 6 lessons  ⏱ 2h  🎯 Band 6     │
│                                    │
│ [Enroll Now Button]                │
└────────────────────────────────────┘
```

**Interactive States:**
- Hover: Shadow + slight lift
- Click: Navigate to detail
- Loading: Skeleton placeholder

### 7.4. Exercise Flow

#### Flow Diagram

```
Exercises List
    ↓
[Filter by Skill] → Results
    ↓
[Start Exercise] → Instructions
    ↓
[Begin] → Question 1
    ↓
[Answer] → Question 2 → ... → Question N
    ↓
[Submit] → Results Page
    ↓
[Review Answers] → Detailed Feedback
```

#### Exercise Page Layout

```
┌────────────────────────────────────────────────────────┐
│ [Header: Exercise Title]  [Timer]  [Progress: 5/20]   │
├────────────────────────────────────────────────────────┤
│                                                        │
│ ┌──────────────────┐  ┌─────────────────────────┐   │
│ │ Question 5/20     │  │ Navigation Panel        │   │
│ │                   │  │                         │   │
│ │ [Question Text]   │  │ [Question List]         │   │
│ │                   │  │ • Q1 ✓                  │   │
│ │ [Answer Options]  │  │ • Q2 ✓                  │   │
│ │ ○ Option A        │  │ • Q3 ← current          │   │
│ │ ○ Option B        │  │ • Q4 ○                  │   │
│ │ ○ Option C        │  │ ...                      │   │
│ │ ○ Option D        │  │                         │   │
│ │                   │  │ [Submit]                │   │
│ │ [Previous] [Next] │  └─────────────────────────┘   │
│ └──────────────────┘                                   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 7.5. Profile & Settings Flow

#### Profile Page Layout

```
┌────────────────────────────────────────────────────────┐
│ Profile Settings                                        │
│ Manage your account settings and preferences            │
├────────────────────────────────────────────────────────┤
│                                                         │
│ [Avatar Upload]                                         │
│                                                         │
│ [Tabs: Profile | Security | Preferences]               │
│                                                         │
│ ┌─────────────────────────────────────────────────┐   │
│ │ Full Name:    [Input field]        [Edit]        │   │
│ │ Email:        user@example.com (read-only)       │   │
│ │ Bio:          [Textarea]                          │   │
│ │ Target Score: [Select: 5.5 - 9.0]                 │   │
│ │                                                      │   │
│ │                     [Cancel] [Save Changes]          │   │
│ └─────────────────────────────────────────────────┘   │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## 8. Accessibility Guidelines

### 8.1. Color Contrast

**Minimum Requirements:**
- **Normal text**: 4.5:1 contrast ratio
- **Large text** (18px+): 3:1 contrast ratio
- **UI components**: 3:1 contrast ratio

**Current Implementation:**
```css
/* ✅ Passes WCAG AA */
--foreground: oklch(0.145 0 0); /* Near black on white */
--muted-foreground: oklch(0.556 0 0); /* Medium gray */

/* ✅ Primary button */
--primary: oklch(0.55 0.22 25); /* Red */
--primary-foreground: oklch(1 0 0); /* White */
```

### 8.2. Keyboard Navigation

**Tab Order:**
1. Navigation links (top → bottom)
2. Form inputs (top → bottom)
3. Buttons (left → right)
4. Footer links

**Key Behaviors:**
- `Tab`: Move forward
- `Shift+Tab`: Move backward
- `Enter/Space`: Activate button/link
- `Esc`: Close modal/dropdown
- `Arrow keys`: Navigate lists, menus

### 8.3. Screen Reader Support

```tsx
// ✅ Correct
<button aria-label="Close dialog">
  <X className="h-4 w-4" />
</button>

<nav aria-label="Main navigation">
  {/* Links */}
</nav>

<img 
  src="logo.png" 
  alt="IELTSGo Logo" 
  // ✅ Always provide alt text
/>

// ❌ Incorrect
<button>
  <X /> {/* No label */}
</button>
```

### 8.4. Focus Indicators

```css
/* Visible focus ring */
focus-visible:ring-ring/50
focus-visible:ring-[3px]
focus-visible:outline-none
```

**Rationale:**
- 3px ring đủ rõ để thấy
- Sử dụng primary color
- Không hiển thị khi click (chỉ keyboard)

### 8.5. Form Accessibility

```tsx
// ✅ Correct
<label htmlFor="email">Email</label>
<input 
  id="email"
  type="email"
  required
  aria-required="true"
  aria-invalid={!!errors.email}
  aria-describedby={errors.email ? "email-error" : undefined}
/>
{errors.email && (
  <p id="email-error" role="alert" className="text-destructive">
    {errors.email}
  </p>
)}
```

---

## 9. Responsive Design

### 9.1. Breakpoints

```css
sm:  640px   /* Small tablets, large phones */
md:  768px   /* Tablets */
lg:  1024px  /* Desktop */
xl:  1280px  /* Large desktop */
2xl: 1536px  /* Extra large desktop */
```

### 9.2. Layout Patterns

#### Mobile (< 768px)
- **Sidebar**: Hidden, accessible via menu button
- **Header**: Compact, stack vertically
- **Cards**: Full width, stack vertically
- **Grids**: 1 column

#### Tablet (768px - 1024px)
- **Sidebar**: Collapsible
- **Header**: Horizontal layout
- **Cards**: 2 columns
- **Grids**: 2-3 columns

#### Desktop (≥ 1024px)
- **Sidebar**: Always visible
- **Header**: Full 3-column layout
- **Cards**: 3-4 columns
- **Grids**: 4+ columns

### 9.3. Component Responsiveness

#### PageHeader
```tsx
// Mobile: Stack title + subtitle, hide center content
// Desktop: 3-column grid

className="grid grid-cols-[1fr] lg:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)]"
```

#### Cards Grid
```tsx
// Responsive columns
className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
```

#### Buttons
```tsx
// Responsive sizing
className="w-full sm:w-auto"
```

---

## 10. Improvements & Recommendations

### 10.1. Current Strengths ✅

1. **Consistent Header System**
   - ✅ PageHeader component đồng bộ
   - ✅ Chiều cao nhất quán (64px)
   - ✅ Layout structure rõ ràng

2. **Color System**
   - ✅ Palette nhất quán
   - ✅ Dark mode support
   - ✅ Semantic colors rõ ràng

3. **Typography**
   - ✅ Font system nhất quán
   - ✅ Responsive scaling
   - ✅ User font size preferences

### 10.2. Areas for Improvement 🔄

#### 1. Card Styling Consistency

**Current Issue:**
- Dashboard cards có gradients và hover effects
- My Courses cards đơn giản hơn
- Không đồng bộ visual style

**Recommendation:**
```tsx
// Tạo CardVariant component
<Card variant="interactive" className="hover:shadow-lg transition-shadow">
  {/* Consistent hover effects */}
</Card>

<Card variant="highlight" className="bg-gradient-to-br from-white to-blue-50/50">
  {/* Consistent gradients */}
</Card>
```

#### 2. Loading States Standardization

**Current Issue:**
- Loading states không nhất quán giữa các trang

**Recommendation:**
```tsx
// Tạo LoadingSpinner component
<LoadingSpinner size="lg" message="Đang tải dữ liệu..." />
```

#### 3. Empty States Enhancement

**Current Issue:**
- Một số empty states thiếu illustration hoặc guidance

**Recommendation:**
- Thêm illustrations cho empty states
- Cung cấp clear next steps
- Thêm motivation messages

#### 4. Animation Consistency

**Recommendation:**
```tsx
// Tạo animation utilities
const fadeIn = "animate-in fade-in duration-200"
const slideUp = "animate-in slide-in-from-bottom-2 duration-200"
```

#### 5. Error Handling UX

**Recommendation:**
- Consistent error message styling
- Clear error recovery actions
- Retry buttons cho failed API calls

### 10.3. New Features to Consider

#### 1. Toast Notifications
```tsx
// Thêm toast system cho feedback
toast.success("Profile updated successfully")
toast.error("Failed to save changes")
```

#### 2. Skeleton Loading
```tsx
// Replace spinners với skeletons cho better UX
<SkeletonCard />
<SkeletonList />
```

#### 3. Search Enhancement
```tsx
// Global search với suggestions
<SearchDialog 
  placeholder="Search courses, exercises..."
  results={results}
/>
```

#### 4. Keyboard Shortcuts
```tsx
// Add keyboard shortcuts
⌘K - Open search
⌘/ - Open help
Esc - Close modals
```

### 10.4. Performance Optimizations

1. **Image Optimization**
   - Lazy loading cho images
   - WebP format với fallback
   - Responsive images với srcset

2. **Code Splitting**
   - Route-based code splitting
   - Component lazy loading

3. **Bundle Size**
   - Tree shaking
   - Dynamic imports cho heavy components

---

## 📚 Component Usage Examples

### Example 1: Dashboard Card

```tsx
<Card className="group hover:shadow-lg transition-all duration-200 cursor-pointer bg-gradient-to-br from-white to-blue-50/50">
  <CardContent className="p-5">
    <div className="flex items-start gap-4">
      <div className="p-3 rounded-xl bg-blue-100 dark:bg-blue-900/40 group-hover:bg-blue-200 transition-all">
        <BookOpen className="h-5 w-5 text-blue-600" />
      </div>
      <div className="flex-1">
        <h3 className="font-semibold text-base mb-1 group-hover:text-primary transition-colors">
          {t('courses')}
        </h3>
        <p className="text-sm text-muted-foreground">
          {t('explore_courses')}
        </p>
      </div>
      <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-1 transition-all" />
    </div>
  </CardContent>
</Card>
```

**Key Features:**
- Gradient background
- Icon với color coding
- Hover animations
- Clear hierarchy

### Example 2: Form with Validation

```tsx
<form onSubmit={handleSubmit} className="space-y-5">
  <FormField
    label="Full Name"
    name="fullName"
    value={formData.fullName}
    onChange={(value) => setFormData({ ...formData, fullName: value })}
    error={errors.fullName}
    required
    autoFocus
  />
  
  <FormField
    label="Email"
    name="email"
    type="email"
    value={formData.email}
    disabled
    className="bg-muted/50"
  />
  
  {errors.general && (
    <Alert variant="destructive">
      <AlertDescription>{errors.general}</AlertDescription>
    </Alert>
  )}
  
  <div className="flex justify-end gap-3 pt-4 border-t">
    <Button variant="outline" onClick={handleCancel}>
      Cancel
    </Button>
    <Button type="submit" disabled={isLoading}>
      {isLoading ? "Saving..." : "Save Changes"}
    </Button>
  </div>
</form>
```

---

## 🎯 Design Decision Rationale

### Why OKLCH Color Space?

**OKLCH** (instead of RGB/HSL):
- ✅ Perceptually uniform - màu sắc thay đổi đều nhau
- ✅ Better for dark mode - dễ tính toán contrast
- ✅ Future-proof - được các browser modern support
- ✅ Accessibility - dễ đảm bảo contrast ratios

### Why Noto Sans?

- ✅ Excellent Vietnamese support
- ✅ Clean, modern, professional
- ✅ Good readability ở mọi sizes
- ✅ Free, fast loading từ Google Fonts

### Why 8px Spacing Base?

- ✅ Divisible by 2, 4, 8 - flexible
- ✅ Visual rhythm rõ ràng
- ✅ Standard trong industry
- ✅ Dễ implement với Tailwind

### Why PageHeader Component?

- ✅ Consistency across all pages
- ✅ No layout shift khi chuyển trang
- ✅ Context information luôn visible
- ✅ Filters/actions ở vị trí nhất quán

---

## 📖 Quick Reference

### Color Classes
```tsx
bg-primary           // Primary red background
text-primary         // Primary red text
bg-secondary         // Secondary dark background
bg-accent           // Accent cream background
bg-muted            // Muted gray background
text-muted-foreground // Secondary text color
```

### Spacing Utilities
```tsx
gap-4    // 16px
gap-6    // 24px
p-6      // 24px padding
mb-8     // 32px margin bottom
```

### Typography
```tsx
text-3xl font-bold        // H1
text-2xl font-semibold    // H2
text-base                 // Body
text-sm text-muted-foreground // Small
```

---

## ✅ Checklist khi tạo trang mới

- [ ] Header sử dụng `PageHeader` component
- [ ] Layout sử dụng `AppLayout` với props đúng
- [ ] Container sử dụng `PageContainer`
- [ ] Colors sử dụng design tokens (không hardcode)
- [ ] Spacing tuân theo 8px grid
- [ ] Typography sử dụng heading/body styles
- [ ] Loading states có feedback
- [ ] Empty states có guidance
- [ ] Error states có recovery actions
- [ ] Responsive trên mobile, tablet, desktop
- [ ] Keyboard navigation works
- [ ] Screen reader friendly
- [ ] Dark mode tested

---

**Last Updated:** 2025-01-11
**Version:** 1.0.0
**Maintainer:** Frontend Team


