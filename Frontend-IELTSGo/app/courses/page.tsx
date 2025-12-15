import { Suspense } from "react"
import { CoursesClient } from "./courses-client"
import { getPublicCourses } from "@/lib/api/server-fetch"
import { SkeletonCard } from "@/components/ui/skeleton-card"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import type { Metadata } from "next"

// Static generation with revalidation every 5 minutes
export const revalidate = 300

// Page metadata
export const metadata: Metadata = {
  title: "Khóa Học IELTS | IELTSGo",
  description: "Khám phá các khóa học IELTS chất lượng cao với giảng viên chuyên nghiệp. Luyện thi Listening, Reading, Writing, Speaking.",
  keywords: ["IELTS courses", "Khóa học IELTS", "Luyện thi IELTS", "IELTS online"],
}

// Loading fallback for Suspense
function CoursesLoading() {
  return (
    <AppLayout showFooter={true}>
      <PageContainer>
        <div className="mb-8">
          <div className="h-9 w-64 bg-muted animate-pulse rounded-lg mb-2" />
          <div className="h-5 w-96 bg-muted animate-pulse rounded-lg" />
        </div>
        <div className="h-12 w-full bg-muted animate-pulse rounded-lg mb-8" />
        <SkeletonCard gridCols={3} count={6} />
      </PageContainer>
    </AppLayout>
  )
}

/**
 * Courses Page - Hybrid Static + Dynamic
 * 
 * Strategy:
 * 1. Server Component fetches initial data at build time / ISR
 * 2. Data is passed to Client Component for instant first paint
 * 3. Client Component handles filtering/pagination dynamically
 * 
 * Benefits:
 * - No loading spinner on initial visit (data already fetched)
 * - SEO friendly (content in HTML)
 * - Fast subsequent navigations (cached)
 */
export default async function CoursesPage() {
  // Fetch initial data on server (cached for 5 minutes)
  const { courses, pagination } = await getPublicCourses(1, 12)

  return (
    <Suspense fallback={<CoursesLoading />}>
      <CoursesClient
        initialCourses={courses}
        initialTotalPages={pagination.total_pages}
        initialTotal={pagination.total}
      />
    </Suspense>
  )
}
