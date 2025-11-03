"use client"

import { useState, useEffect, useCallback, useMemo } from "react"
import { useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card" // Still used for empty state cards
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { 
  Target, 
  CheckCircle,
  PlayCircle,
  Award,
  TrendingUp
} from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { SkeletonCard } from "@/components/ui/skeleton-card"
import { EmptyState } from "@/components/ui/empty-state"
import { ExerciseSubmissionCard } from "@/components/exercises/exercise-submission-card"
import { exercisesApi } from "@/lib/api/exercises"
import { useAuth } from "@/lib/contexts/auth-context"
import type { SubmissionWithExercise } from "@/types"
import { useTranslations } from '@/lib/i18n'
import { usePullToRefresh } from "@/lib/hooks/use-swipe-gestures"

export default function MyExercisesPage() {

  const t = useTranslations('common')

  const router = useRouter()
  const { user } = useAuth()
  const [submissions, setSubmissions] = useState<SubmissionWithExercise[]>([])
  const [totalSubmissions, setTotalSubmissions] = useState(0)
  const [loading, setLoading] = useState(true)

  // Memoize loadSubmissions to avoid unnecessary re-renders
  const loadSubmissions = useCallback(async () => {
    try {
      setLoading(true)
      const data = await exercisesApi.getMySubmissions(1, 100) // Load all for stats calculation
      setSubmissions(data.submissions || [])
      setTotalSubmissions(data.total || 0)
    } catch (error) {
      // Silent fail - keep previous data
    } finally {
      setLoading(false)
    }
  }, [])

  // Pull to refresh - must be called before useEffect (Rules of Hooks)
  const { ref: pullToRefreshRef } = usePullToRefresh(() => {
    if (user) {
      loadSubmissions()
    }
  }, true)

  useEffect(() => {
    if (user) {
      loadSubmissions()
    }
  }, [user, loadSubmissions])

  // Memoize filtered submissions - MUST be before conditional return
  const { completedSubmissions, inProgressSubmissions } = useMemo(() => {
    const completed = submissions.filter(item => item.submission.status === 'completed')
    const inProgress = submissions.filter(item => item.submission.status === 'in_progress')
    return { completedSubmissions: completed, inProgressSubmissions: inProgress }
  }, [submissions])

  // Calculate average score - Memoized - MUST be before conditional return
  const calculateScore = useCallback((submission: SubmissionWithExercise['submission']): number => {
    if (submission.score !== undefined && submission.score !== null && submission.score > 0) {
      return submission.score
    }
    // Calculate percentage from correct answers
    if (submission.total_questions > 0 && submission.correct_answers !== undefined) {
      return (submission.correct_answers / submission.total_questions) * 100
    }
    return 0
  }, [])

  const { averageScore, totalTimeMinutes } = useMemo(() => {
    const completedWithScore = completedSubmissions.filter(
      item => item.submission.total_questions > 0
    )
    const avgScore = completedWithScore.length > 0
      ? completedWithScore.reduce((sum, item) => sum + calculateScore(item.submission), 0) / completedWithScore.length
      : 0
    
    const totalTimeSeconds = submissions.reduce(
      (sum, item) => sum + (item.submission.time_spent_seconds || 0),
      0
    )
    const totalMins = Math.floor(totalTimeSeconds / 60)
    
    return { averageScore: avgScore, totalTimeMinutes: totalMins }
  }, [completedSubmissions, submissions, calculateScore])

  // Memoize format functions
  const formatTime = useCallback((minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
  }, [])

  const formatScore = useCallback((score?: number) => {
    if (score === undefined || score === null) return t('not_available')
    return `${score.toFixed(1)}%`
  }, [t])

  if (!user) {
    return (
      <AppLayout showSidebar={true} showFooter={false} hideNavbar={true}>
        <PageContainer className="py-12 text-center">
          <h1 className="text-2xl font-bold mb-4">{t('please_sign_in')}</h1>
          <p className="text-muted-foreground mb-6">
            {t('you_need_to_be_signed_in_to_view_exercises')}
          </p>
          <Button onClick={() => router.push('/auth/login')}>
            {t('sign_in')}
          </Button>
        </PageContainer>
      </AppLayout>
    )
  }


  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <div ref={pullToRefreshRef as React.RefObject<HTMLDivElement>}>
      <PageHeader
        title={t('my_exercises')}
        subtitle={t('track_your_practice_progress')}
      />
      <PageContainer maxWidth="7xl">

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('total_attempts')}</p>
                  <p className="text-3xl font-bold">{totalSubmissions}</p>
                </div>
                <Target className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('in_progress')}</p>
                  <p className="text-3xl font-bold">{inProgressSubmissions.length}</p>
                </div>
                <PlayCircle className="h-8 w-8 text-orange-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('completed')}</p>
                  <p className="text-3xl font-bold">{completedSubmissions.length}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('average_score')}</p>
                  <p className="text-3xl font-bold">
                    {completedSubmissions.length > 0 && averageScore > 0 ? formatScore(averageScore) : "N/A"}
                  </p>
                </div>
                <TrendingUp className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Exercises Tabs */}
        <Tabs defaultValue="all" className="space-y-6">
          <TabsList>
            <TabsTrigger value="all">
              {t('all_exercises')} ({submissions.length})
            </TabsTrigger>
            <TabsTrigger value="in-progress">
              {t('in_progress')} ({inProgressSubmissions.length})
            </TabsTrigger>
            <TabsTrigger value="completed">
              {t('completed')} ({completedSubmissions.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="all" className="space-y-4">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <PageLoading translationKey="loading" size="md" />
              </div>
            ) : submissions.length === 0 ? (
              <EmptyState
                icon={Target}
                title={t('no_exercises_yet')}
                description={t('start_practicing_by_attempting')}
                actionLabel={t('browse_exercises')}
                actionOnClick={() => router.push('/exercises/list')}
              />
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {submissions.map((item) => {
                  const { submission, exercise } = item
                  return (
                    <ExerciseSubmissionCard
                      key={submission.id}
                      exercise={exercise}
                      submission={submission}
                    />
                  )
                })}
              </div>
            )}
          </TabsContent>

          <TabsContent value="in-progress" className="space-y-4">
            {inProgressSubmissions.length === 0 ? (
              <EmptyState
                icon={PlayCircle}
                title={t('no_exercises_in_progress')}
                description={t('start_practicing_to_see_progress')}
                actionLabel={t('browse_exercises')}
                actionOnClick={() => router.push('/exercises/list')}
              />
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {inProgressSubmissions.map((item) => {
                  const { submission, exercise } = item
                  return (
                    <ExerciseSubmissionCard
                      key={submission.id}
                      exercise={exercise}
                      submission={submission}
                    />
                  )
                })}
              </div>
            )}
          </TabsContent>

          <TabsContent value="completed" className="space-y-4">
            {completedSubmissions.length === 0 ? (
              <EmptyState
                icon={Award}
                title={t('no_completed_exercises_yet')}
                description={t('complete_your_first_exercise')}
                actionLabel={t('browse_exercises')}
                actionOnClick={() => router.push('/exercises/list')}
              />
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {completedSubmissions.map((item) => {
                  const { submission, exercise } = item
                  return (
                    <ExerciseSubmissionCard
                      key={submission.id}
                      exercise={exercise}
                      submission={submission}
                    />
                  )
                })}
              </div>
            )}
          </TabsContent>
        </Tabs>
      </PageContainer>
      </div>
    </AppLayout>
  )
}

