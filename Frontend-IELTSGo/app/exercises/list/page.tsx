import { Suspense } from "react"
import { ExercisesClient } from "./exercises-client"
import { getPublicExercises } from "@/lib/api/server-fetch"
import { SkeletonCard } from "@/components/ui/skeleton-card"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import type { Metadata } from "next"

// Static generation with revalidation every 5 minutes
export const revalidate = 300

// Page metadata
export const metadata: Metadata = {
  title: "Bài Tập IELTS | IELTSGo",
  description: "Luyện tập các bài tập IELTS Listening, Reading, Writing, Speaking với đa dạng dạng bài và độ khó.",
  keywords: ["IELTS exercises", "Bài tập IELTS", "Luyện thi IELTS", "IELTS practice"],
}

// Loading fallback for Suspense
function ExercisesLoading() {
  return (
    <AppLayout showFooter={true}>
      <PageContainer>
        <div className="mb-8">
          <div className="h-9 w-64 bg-muted animate-pulse rounded-lg mb-2" />
          <div className="h-5 w-96 bg-muted animate-pulse rounded-lg" />
        </div>
        <div className="h-12 w-full bg-muted animate-pulse rounded-lg mb-8" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} showImage />)}
        </div>
      </PageContainer>
    </AppLayout>
  )
}

/**
 * Exercises List Page - Hybrid Static + Dynamic
 * 
 * Strategy:
 * 1. Server Component fetches initial data at build time / ISR
 * 2. Data is passed to Client Component for instant first paint
 * 3. Client Component handles filtering/pagination dynamically
 */
export default async function ExercisesListPage() {
  // Fetch initial data on server (cached for 5 minutes)
  const { exercises, pagination } = await getPublicExercises(1, 12)

  return (
    <Suspense fallback={<ExercisesLoading />}>
      <ExercisesClient
        initialExercises={exercises}
        initialTotalPages={pagination.total_pages}
        initialTotal={pagination.total}
      />
    </Suspense>
  )
}
