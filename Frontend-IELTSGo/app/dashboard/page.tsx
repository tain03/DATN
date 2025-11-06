"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { useAuth } from "@/lib/contexts/auth-context"
import { usePreferences } from "@/lib/contexts/preferences-context"
import { PageHeader } from "@/components/layout/page-header"
import { BookOpen, CheckCircle, Clock, TrendingUp, Flame, BarChart3, Target } from "lucide-react"
import { useEffect, useState, useCallback, useMemo, lazy, Suspense } from "react"
import { progressApi } from "@/lib/api/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"
import { PageLoading } from "@/components/ui/page-loading"
import { usePullToRefresh } from "@/lib/hooks/use-swipe-gestures"

// Lazy load heavy components to improve initial load time
const ProgressChart = lazy(() => import("@/components/dashboard/progress-chart").then(m => ({ default: m.ProgressChart })))
const SkillProgressCard = lazy(() => import("@/components/dashboard/skill-progress-card").then(m => ({ default: m.SkillProgressCard })))
const ActivityTimeline = lazy(() => import("@/components/dashboard/activity-timeline").then(m => ({ default: m.ActivityTimeline })))
const StatCard = lazy(() => import("@/components/dashboard/stat-card").then(m => ({ default: m.StatCard })))
const TestResultsSection = lazy(() => import("@/components/dashboard/test-results-section").then(m => ({ default: m.TestResultsSection })))
const ScoringSystemInfo = lazy(() => import("@/components/dashboard/scoring-system-info").then(m => ({ default: m.ScoringSystemInfo })))

export default function DashboardPage() {
  return (
    <ProtectedRoute>
      <DashboardContent />
    </ProtectedRoute>
  )
}

function DashboardContent() {
  const { user } = useAuth()
  const { preferences } = usePreferences()
  const t = useTranslations('dashboard')
  const tCommon = useTranslations('common')
  const showStats = preferences?.show_study_stats ?? true // Default to true for backward compatibility
  
  // Debug log
  useEffect(() => {
    console.log('[Dashboard] showStats:', showStats, 'preferences:', preferences)
  }, [showStats, preferences])
  const [loading, setLoading] = useState(true)
  const [summary, setSummary] = useState<any>(null)
  const [analytics, setAnalytics] = useState<any>(null)
  const [history, setHistory] = useState<any[]>([])
  const [timeRange, setTimeRange] = useState<"7d" | "30d" | "90d" | "all">("30d")

  const fetchDashboardData = useCallback(async () => {
    setLoading(true)
    try {
      // Use cached fetch for faster initial load
      const [summaryData, analyticsData, historyData] = await Promise.all([
        progressApi.getProgressSummary(),
        progressApi.getProgressAnalytics(timeRange),
        progressApi.getStudyHistory(1, 10),
      ])
      setSummary(summaryData)
      setAnalytics(analyticsData)
      setHistory(Array.isArray(historyData) ? historyData : (historyData as any)?.data || [])
    } catch (error) {
      console.error('[Dashboard] Error fetching data:', error)
      // Keep previous data on error if available (optimistic UI)
    } finally {
      setLoading(false)
    }
  }, [timeRange])

  useEffect(() => {
    fetchDashboardData()
  }, [fetchDashboardData])

  // Pull to refresh
  const { ref: pullToRefreshRef } = usePullToRefresh(() => {
    fetchDashboardData()
  }, true)

  // Count unique exercises completed from history - Memoized
  // MUST be before conditional return to maintain hook order
  const { uniqueExercises, totalAttempts } = useMemo(() => {
    const exerciseAttempts = history.filter(a => a.type === "exercise")
    const unique = new Set(exerciseAttempts.map(a => a.title)).size
    const total = exerciseAttempts.length
    return { uniqueExercises: unique, totalAttempts: total }
  }, [history])

  // Calculate analytics stats - Memoized
  // MUST be before conditional return to maintain hook order
  const stats = useMemo(() => {
    if (!analytics) return { 
      totalMinutes: 0, 
      totalExercises: 0, 
      avgScore: 0, 
      activeStreak: 0,
      skillScores: { listening: 0, reading: 0, writing: 0, speaking: 0 }
    }
    
    const totalMinutes = analytics.studyTimeByDay?.reduce((sum: number, day: any) => sum + (day.value || 0), 0) || 0
    const totalExercises = analytics.exercisesByType?.reduce((sum: number, type: any) => sum + (type.count || 0), 0) || 0
    const avgScore = analytics.exercisesByType?.length > 0
      ? analytics.exercisesByType.reduce((sum: number, type: any) => sum + (type.avgScore || 0), 0) / analytics.exercisesByType.length
      : 0
    
    // Calculate active streak
    let activeStreak = 0
    const sortedDays = [...(analytics.studyTimeByDay || [])].sort((a: any, b: any) => 
      new Date(b.date).getTime() - new Date(a.date).getTime()
    )
    for (const day of sortedDays) {
      if (day.value > 0) activeStreak++
      else break
    }
    
    // Extract skill scores from exercisesByType
    const skillScores = {
      listening: analytics.exercisesByType?.find((t: any) => t.type.toLowerCase() === 'listening')?.avgScore || 0,
      reading: analytics.exercisesByType?.find((t: any) => t.type.toLowerCase() === 'reading')?.avgScore || 0,
      writing: analytics.exercisesByType?.find((t: any) => t.type.toLowerCase() === 'writing')?.avgScore || 0,
      speaking: analytics.exercisesByType?.find((t: any) => t.type.toLowerCase() === 'speaking')?.avgScore || 0,
    }
    
    return { totalMinutes, totalExercises, avgScore, activeStreak, skillScores }
  }, [analytics])
  
  // Get exercise counts by skill - Memoized callback
  // MUST be before conditional return to maintain hook order
  const getSkillExerciseCount = useCallback((skill: string) => {
    return analytics?.exercisesByType?.find((t: any) => t.type.toLowerCase() === skill.toLowerCase())?.count || 0
  }, [analytics])

  // Time range filter handler - Memoized
  // MUST be before conditional return to maintain hook order
  const handleTimeRangeChange = useCallback((range: "7d" | "30d" | "90d" | "all") => {
    setTimeRange(range)
  }, [])

  // Time range filter tabs component - Memoized
  // MUST be before conditional return to maintain hook order
  const timeRangeFilters = useMemo(() => (
    <Tabs value={timeRange} onValueChange={(v) => handleTimeRangeChange(v as "7d" | "30d" | "90d" | "all")}>
      <TabsList className="inline-flex h-10 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground">
        <TabsTrigger
          value="7d"
          className="data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm transition-all px-4 text-sm"
        >
          {t('timeRange.7d')}
        </TabsTrigger>
        <TabsTrigger
          value="30d"
          className="data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm transition-all px-4 text-sm"
        >
          {t('timeRange.30d')}
        </TabsTrigger>
        <TabsTrigger
          value="90d"
          className="data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm transition-all px-4 text-sm"
        >
          {t('timeRange.90d')}
        </TabsTrigger>
        <TabsTrigger
          value="all"
          className="data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm transition-all px-4 text-sm"
        >
          {t('timeRange.all')}
        </TabsTrigger>
      </TabsList>
    </Tabs>
  ), [timeRange, handleTimeRangeChange, t])

  // Conditional return AFTER all hooks
  if (loading) {
    return (
      <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
        <PageHeader
          title={user?.fullName ? `Chào mừng trở lại, ${user.fullName.split(' ')[0]}!` : t('welcome')}
          subtitle={t('track_your_journey')}
        />
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <div ref={pullToRefreshRef as React.RefObject<HTMLDivElement>}>
      <PageHeader
        title={t('welcomeBack', { name: user?.fullName?.split(" ")[0] || tCommon('student') })}
        subtitle={`${t('subtitle')}${user?.targetBandScore ? ` • ${t('targetBand', { score: user.targetBandScore })}` : ''}`}
        centerContent={timeRangeFilters}
      />

      <PageContainer className="py-6">

        {/* Stats Grid - Only show if user preference allows */}
        {showStats && (
          <Suspense fallback={
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
              {[1, 2, 3, 4, 5].map(i => (
                <Card key={i}><CardContent className="p-6"><div className="h-[100px] flex items-center justify-center">Loading...</div></CardContent></Card>
              ))}
            </div>
          }>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
              <StatCard
                title={t('stats.coursesInProgress')}
                value={summary?.inProgressCourses || 0}
                description={`${summary?.completedCourses || 0} khóa đã hoàn thành`}
                icon={BookOpen}
              />
              <StatCard
                title={t('stats.exercisesCompleted')}
                value={uniqueExercises}
                description={`${totalAttempts} lần luyện tập`}
                icon={CheckCircle}
              />
              <StatCard
                title={t('stats.studyTime')}
                value={`${Math.floor(stats.totalMinutes / 60)}h ${stats.totalMinutes % 60}m`}
                description={`Trong ${t(`timeRange.${timeRange}`)}`}
                icon={Clock}
              />
              <StatCard
                title={t('stats.averageScore')}
                value={stats.avgScore > 0 ? stats.avgScore.toFixed(1) : (summary?.averageScore?.toFixed(1) || "0.0")}
                description="Official Test Band Score (0-9)"
                icon={Target}
              />
              <StatCard
                title={t('stats.currentStreak')}
                value={`${stats.activeStreak || summary?.currentStreak || 0} ngày`}
                description={`Kỷ lục: ${summary?.longestStreak || 0} ngày`}
                icon={Flame}
              />
            </div>
          </Suspense>
        )}

        {/* Tabs for different views */}
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className={cn(
            "grid w-full max-w-md bg-muted/50 p-1 h-auto",
            showStats ? "grid-cols-3" : "grid-cols-1"
          )}>
            <TabsTrigger 
              value="overview"
              className="data-[state=active]:bg-background data-[state=active]:shadow-sm transition-all"
            >
              {t('tabs.overview')}
            </TabsTrigger>
            {showStats && (
              <TabsTrigger 
                value="analytics"
                className="data-[state=active]:bg-background data-[state=active]:shadow-sm transition-all"
              >
                {t('tabs.analytics')}
              </TabsTrigger>
            )}
            {showStats && (
              <TabsTrigger 
                value="skills"
                className="data-[state=active]:bg-background data-[state=active]:shadow-sm transition-all"
              >
                {t('tabs.skills')}
              </TabsTrigger>
            )}
          </TabsList>

          {/* Overview Tab */}
          <TabsContent value="overview" className="space-y-6 mt-6">
            {showStats && (
              <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                <ProgressChart
                  title={`Thời gian học (${t(`timeRange.${timeRange}`)})`}
                  data={analytics?.studyTimeByDay || []}
                  color="#ED372A"
                  valueLabel="phút"
                />
              </Suspense>
            )}
            <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading timeline...</div></CardContent></Card>}>
              <ActivityTimeline activities={history} />
            </Suspense>
          </TabsContent>

          {/* Analytics Tab - Only show if user preference allows */}
          {showStats && (
            <TabsContent value="analytics" className="space-y-6">
              <div className="grid gap-6">
                <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                  <ProgressChart
                    title={`Thời gian học theo ngày (${t(`timeRange.${timeRange}`)})`}
                    data={analytics?.studyTimeByDay || []}
                    color="#ED372A"
                    valueLabel="phút"
                  />
                </Suspense>
                <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                  <ProgressChart
                    title={`Tỷ lệ hoàn thành (${t(`timeRange.${timeRange}`)})`}
                    data={analytics?.completionRate || []}
                    color="#10B981"
                    valueLabel="%"
                  />
                </Suspense>
                <div>
                  <h3 className="text-lg font-semibold mb-4">Thống kê bài tập theo kỹ năng</h3>
                  {analytics?.exercisesByType?.length > 0 ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                      {analytics.exercisesByType.map((item: any) => (
                        <Card key={item.type} className="border-border/40">
                          <CardHeader>
                            <CardTitle className="text-base font-semibold capitalize">{item.type}</CardTitle>
                          </CardHeader>
                          <CardContent>
                            <div className="space-y-3">
                              <div className="flex justify-between items-center">
                                <span className="text-sm text-muted-foreground">Đã hoàn thành</span>
                                <span className="font-bold text-lg">{item.count}</span>
                              </div>
                              <div className="flex justify-between items-center">
                                <span className="text-sm text-muted-foreground">Điểm trung bình (0-9)</span>
                                <span className={cn(
                                  "font-bold text-lg",
                                  item.avgScore >= 7 ? "text-green-600 dark:text-green-500" : 
                                  item.avgScore >= 5 ? "text-orange-600 dark:text-orange-500" : 
                                  "text-red-600 dark:text-red-500"
                                )}>{item.avgScore.toFixed(1)}</span>
                              </div>
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  ) : (
                    <Card>
                      <CardContent className="py-12 text-center">
                        <p className="text-muted-foreground">
                          Chưa có bài tập nào được hoàn thành
                        </p>
                      </CardContent>
                    </Card>
                  )}
                </div>
              </div>
            </TabsContent>
          )}

          {/* Skills Tab - Only show if user preference allows */}
          {showStats && (
            <TabsContent value="skills" className="space-y-6">
              {/* Scoring System Info */}
              <Suspense fallback={<div className="h-20 flex items-center justify-center">Loading...</div>}>
                <ScoringSystemInfo />
              </Suspense>

              <Suspense fallback={
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  {[1, 2, 3, 4].map(i => (
                    <Card key={i}><CardContent className="p-8"><div className="h-[150px] flex items-center justify-center">Loading...</div></CardContent></Card>
                  ))}
                </div>
              }>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  <SkillProgressCard
                    skill="LISTENING"
                    currentScore={stats.skillScores.listening || summary?.skillScores?.listening || 0}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('listening')}
                  />
                  <SkillProgressCard
                    skill="READING"
                    currentScore={stats.skillScores.reading || summary?.skillScores?.reading || 0}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('reading')}
                  />
                  <SkillProgressCard
                    skill="WRITING"
                    currentScore={stats.skillScores.writing || summary?.skillScores?.writing || 0}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('writing')}
                  />
                  <SkillProgressCard
                    skill="SPEAKING"
                    currentScore={stats.skillScores.speaking || summary?.skillScores?.speaking || 0}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('speaking')}
                  />
                </div>
              </Suspense>

              {/* Test Results & Practice Activities Section */}
              <Suspense fallback={
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
                  {[1, 2].map(i => (
                    <Card key={i}><CardContent className="p-6"><div className="h-[250px] flex items-center justify-center">Loading...</div></CardContent></Card>
                  ))}
                </div>
              }>
                <div className="mt-6">
                  <TestResultsSection />
                </div>
              </Suspense>
            </TabsContent>
          )}
        </Tabs>
      </PageContainer>
      </div>
    </AppLayout>
  )
}
