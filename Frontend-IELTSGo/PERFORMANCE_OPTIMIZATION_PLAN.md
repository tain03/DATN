# 🚀 Performance Optimization Plan

## Tổng quan
Kế hoạch toàn diện để cải thiện hiệu suất ứng dụng IELTSGo, giảm thời gian load, tối ưu bundle size và cải thiện UX.

## 📊 Hiện trạng

### Vấn đề hiện tại
1. **Bundle Size**: Recharts được import trực tiếp ở nhiều pages (~200KB)
2. **Image Optimization**: Đã tắt trong next.config.mjs
3. **Code Splitting**: Chưa sử dụng dynamic imports cho heavy components
4. **Search**: Chưa có debounce
5. **Component Re-renders**: Nhiều components chưa được memoized
6. **API Calls**: Một số chưa có caching

### Metrics mục tiêu
- First Contentful Paint (FCP): < 1.5s
- Time to Interactive (TTI): < 3s
- Largest Contentful Paint (LCP): < 2.5s
- Bundle size: Giảm 30-40%
- API response: Giảm 50% nhờ caching

## ✅ Kế hoạch triển khai

### Phase 1: Next.js Configuration & Build Optimization ✅
- [x] API Caching system
- [x] Enable image optimization (AVIF, WebP)
- [x] Configure code splitting (webpack chunk splitting)
- [x] Optimize webpack config (recharts chunk, vendor chunks)
- [x] SWC minification enabled
- [x] Package imports optimization (lucide-react)

### Phase 2: Code Splitting & Lazy Loading ✅
- [x] Recharts wrapper cho code splitting
- [x] Route-based code splitting (webpack config)
- [ ] Dynamic imports cho heavy pages (instructor, admin) - Optional
- [ ] Lazy load YouTube player - Optional

### Phase 3: Component Optimization ✅
- [x] React.memo cho StatCard, ProgressChart
- [x] React.memo cho CourseCard, ExerciseCard
- [x] Optimize ActivityTimeline (useMemo + React.memo)
- [x] Memoize filters và search components (debounce)

### Phase 4: API & Data Optimization ✅
- [x] API caching (30s TTL) - progress, courses
- [x] Debounce search inputs (500ms) - courses, exercises
- [x] Optimize query parameters (caching keys)
- [ ] Request batching - Future
- [ ] Prefetch critical data - Future

### Phase 5: Asset Optimization ✅
- [x] Image optimization config (Next.js Image)
- [x] CSS optimization (Tailwind purging tự động)
- [ ] Font optimization (subsetting) - Future
- [ ] Reduce unused dependencies - Review needed

### Phase 6: Runtime Performance ✅
- [x] Optimize re-renders với useMemo/useCallback (dashboard)
- [x] React.memo cho heavy components
- [x] Debounce search để giảm API calls
- [ ] Virtual scrolling cho long lists - Future nếu cần
- [ ] Optimize context providers - Review needed

## 🎯 Kết quả mong đợi
- **Load time**: Giảm 40-50%
- **Bundle size**: Giảm 30-40%
- **API calls**: Giảm 60% nhờ caching
- **User experience**: Smooth và responsive hơn

