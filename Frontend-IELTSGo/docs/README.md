# 📚 IELTSGo Design & UX Documentation

> Tài liệu thiết kế và trải nghiệm người dùng cho nền tảng học IELTS online

---

## 📖 Tài liệu có sẵn

### 🎨 [Design System](./DESIGN_SYSTEM.md)
**Tài liệu chính về Design System**

Bao gồm:
- ✅ Brand Identity & Colors
- ✅ Typography System  
- ✅ Spacing & Layout Grid
- ✅ Component Library Guidelines
- ✅ Interaction Patterns
- ✅ User Flows & Wireframes
- ✅ Accessibility Guidelines
- ✅ Responsive Design
- ✅ Quick Reference

**Dùng khi:** Cần implement component mới, design trang mới, hoặc cần reference về design tokens.

---

### 🚀 [UI/UX Improvements](./UI_UX_IMPROVEMENTS.md)
**Phân tích và đề xuất cải thiện UI/UX**

Bao gồm:
- ✅ Phân tích hiện trạng (điểm mạnh/yếu)
- ✅ Priority improvements (High/Medium/Low)
- ✅ Implementation roadmap
- ✅ Code examples và solutions

**Dùng khi:** Cần cải thiện UX hiện tại, hoặc implement features mới.

---

### 🧠 [Design Reasoning](./DESIGN_REASONING.md)
**Lý do đằng sau mỗi quyết định thiết kế**

Bao gồm:
- ✅ Design Philosophy
- ✅ Color System Decisions
- ✅ Typography Decisions
- ✅ Layout Decisions
- ✅ Component Design Decisions
- ✅ Accessibility Decisions
- ✅ Performance Decisions

**Dùng khi:** Cần hiểu "tại sao" design được làm như vậy, hoặc cần đưa ra decision mới.

---

## 🎯 Quick Start

### Cho Developers

1. **Bắt đầu implement trang mới?**
   - Đọc [Design System - Component Library](./DESIGN_SYSTEM.md#5-component-library)
   - Check [Design System - Checklist](./DESIGN_SYSTEM.md#-checklist-khi-tạo-trang-mới)

2. **Cần cải thiện UX?**
   - Xem [UI/UX Improvements](./UI_UX_IMPROVEMENTS.md)
   - Follow implementation roadmap

3. **Cần đưa ra design decision?**
   - Tham khảo [Design Reasoning](./DESIGN_REASONING.md)
   - Dùng [Decision Checklist](./DESIGN_REASONING.md#-decision-checklist)

### Cho Designers

1. **Design mới component?**
   - Follow [Design System guidelines](./DESIGN_SYSTEM.md)
   - Ensure consistency với existing components
   - Check accessibility requirements

2. **Cải thiện existing design?**
   - Review [UI/UX Improvements](./UI_UX_IMPROVEMENTS.md)
   - Consider user feedback
   - Follow design principles

---

## 🔑 Key Principles

### 1. UX-First
Mọi quyết định đều hướng tới user experience, không phải "đẹp để đẹp".

### 2. Consistency
Tất cả components, pages phải nhất quán về styling, behavior, patterns.

### 3. Accessibility
WCAG 2.1 AA compliance, keyboard navigation, screen reader support.

### 4. Mobile-First
Design bắt đầu từ mobile, progressive enhancement lên desktop.

### 5. Performance
Fast load times, smooth animations, optimized assets.

---

## 📋 Design Tokens Quick Reference

### Colors
```tsx
bg-primary           // #ED372A (Red)
bg-secondary         // #101615 (Dark)
bg-accent           // #FEF7EC (Cream)
text-muted-foreground // Secondary text
```

### Typography
```tsx
text-3xl font-bold        // H1
text-2xl font-semibold    // H2
text-base                // Body
text-sm                  // Small
```

### Spacing
```tsx
gap-4    // 16px
gap-6    // 24px
p-6      // 24px padding
mb-8     // 32px margin
```

### Components
```tsx
<PageHeader title="..." subtitle="..." />
<Card>...</Card>
<Button variant="default|outline|ghost">...</Button>
```

---

## 🔄 Design Process

### 1. Research
- User interviews
- Analytics review
- Competitor analysis

### 2. Design
- Wireframes
- High-fidelity mockups
- Component design

### 3. Review
- Design review với team
- Accessibility check
- Responsive check

### 4. Implement
- Follow Design System
- Use existing components
- Ensure consistency

### 5. Test
- User testing
- Accessibility testing
- Performance testing

### 6. Iterate
- Gather feedback
- Make improvements
- Update documentation

---

## 📞 Liên hệ & Support

### Design System Questions
- Review [Design System](./DESIGN_SYSTEM.md)
- Check [Design Reasoning](./DESIGN_REASONING.md)

### Implementation Help
- Review existing components in `/components/ui`
- Check code examples trong documentation

### Feedback & Suggestions
- Create issue trên GitHub
- Discuss với team trong design review

---

**Last Updated:** 2025-01-11
**Version:** 1.0.0


