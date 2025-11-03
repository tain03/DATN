"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { useState, useEffect, useCallback, lazy, Suspense } from "react"
import { progressApi } from "@/lib/api/progress"
import { Button } from "@/components/ui/button"
import { useTranslations } from '@/lib/i18n'

// Lazy load heavy component to improve initial load time
const ActivityTimeline = lazy(() => import("@/components/dashboard/activity-timeline").then(m => ({ default: m.ActivityTimeline })))

export default function HistoryPage() {

  const t = useTranslations('common')

  return (
    <ProtectedRoute>
      <HistoryContent />
    </ProtectedRoute>
  )
}

function HistoryContent() {
  const t = useTranslations('common')
  const [history, setHistory] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(true)

  // Memoize fetchHistory to avoid unnecessary re-renders
  const fetchHistory = useCallback(async () => {
    try {
      setLoading(true)
      const data = await progressApi.getStudyHistory(page, 20)
      setHistory((prev) => (page === 1 ? data.data : [...prev, ...data.data]))
      setHasMore(page < data.totalPages)
    } catch (error) {
      // Mock data for demo
      const mockData = Array.from({ length: 20 }, (_, i) => ({
        id: `${page}-${i}`,
        type: ["course", "exercise", "lesson"][Math.floor(Math.random() * 3)] as any,
        title: `Activity ${page * 20 + i}`,
        completedAt: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString(),
        duration: Math.floor(Math.random() * 60) + 15,
        score: Math.random() > 0.5 ? Math.floor(Math.random() * 3) + 6.5 : undefined,
      }))
      setHistory((prev) => (page === 1 ? mockData : [...prev, ...mockData]))
      setHasMore(page < 5)
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => {
    fetchHistory()
  }, [fetchHistory])

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <PageHeader
        title={t('study_history')}
        subtitle={t('complete_log_of_your_learning_activities')}
      />
      <PageContainer maxWidth="4xl">

        {loading && page === 1 ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4" />
              <p className="text-muted-foreground">{t('loading_history')}</p>
            </div>
          </div>
        ) : (
          <>
            <Suspense fallback={<div className="flex items-center justify-center py-20">Loading timeline...</div>}>
              <ActivityTimeline activities={history} />
            </Suspense>

            {hasMore && (
              <div className="mt-6 text-center">
                <Button onClick={() => setPage((p) => p + 1)} disabled={loading} variant="outline">
                  {loading ? t('loading') : t('load_more') || "Load More"}
                </Button>
              </div>
            )}
          </>
        )}
      </PageContainer>
    </AppLayout>
  )
}
