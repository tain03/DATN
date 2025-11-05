"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { useAuth } from "@/lib/contexts/auth-context"
import { usePreferences } from "@/lib/contexts/preferences-context"
import { PageHeader } from "@/components/layout/page-header"
import { BookOpen, CheckCircle, Clock, TrendingUp, Flame, BarChart3, Target, ArrowRight } from "lucide-react"
import { useEffect, useState, useCallback, useMemo, lazy, Suspense } from "react"
import { useRouter } from "next/navigation"
import { progressApi } from "@/lib/api/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { getCardVariant } from "@/lib/utils/card-variants"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"
import { PageLoading } from "@/components/ui/page-loading"
import { usePullToRefresh } from "@/lib/hooks/use-swipe-gestures"

// Lazy load heavy components to improve initial load time
const ProgressChart = lazy(() => import("@/components/dashboard/progress-chart").then(m => ({ default: m.ProgressChart })))
const SkillProgressCard = lazy(() => import("@/components/dashboard/skill-progress-card").then(m => ({ default: m.SkillProgressCard })))
const ActivityTimeline = lazy(() => import("@/components/dashboard/activity-timeline").then(m => ({ default: m.ActivityTimeline })))
const StatCard = lazy(() => import("@/components/dashboard/stat-card").then(m => ({ default: m.StatCard })))

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
  const router = useRouter()
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

  // Time range filter buttons component - Memoized
  // MUST be before conditional return to maintain hook order
  const timeRangeFilters = useMemo(() => (
    <div className="flex items-center gap-0.5 px-1.5 py-1 bg-muted/60 rounded-lg border border-border/50">
      {(["7d", "30d", "90d", "all"] as const).map((range) => (
        <Button
          key={range}
          variant="ghost"
          size="sm"
          onClick={() => handleTimeRangeChange(range)}
          className={cn(
            "px-3 text-xs font-medium transition-all rounded-md",
            timeRange === range
              ? "bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
              : "hover:bg-muted/80 text-muted-foreground hover:text-foreground"
          )}
        >
          {range === "7d" ? t('timeRange.7d') :
           range === "30d" ? t('timeRange.30d') :
           range === "90d" ? t('timeRange.90d') :
           t('timeRange.all')}
        </Button>
      ))}
    </div>
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

        {/* Quick Actions - Refined design */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Card 
            className={cn(
              getCardVariant({ gradient: 'blue' }),
              "group relative overflow-hidden hover:border-primary/30 cursor-pointer hover:shadow-lg hover:shadow-blue-500/10"
            )}
            onClick={() => router.push("/my-courses")}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/0 via-blue-500/0 to-blue-500/5 group-hover:from-blue-500/5 group-hover:via-blue-500/5 group-hover:to-blue-500/10 transition-all duration-200" />
            <CardContent className="p-5 relative">
              <div className="flex items-start gap-4">
                <div className="p-3 rounded-xl bg-blue-100 dark:bg-blue-900/40 group-hover:bg-blue-200 dark:group-hover:bg-blue-900/60 transition-all duration-200 shadow-sm group-hover:shadow-md">
                  <BookOpen className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-base mb-1 group-hover:text-primary transition-colors">{tCommon('courses')}</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{tCommon('manage_your_courses') || "Quản lý khóa học của bạn"}</p>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-1 transition-all duration-200 flex-shrink-0 mt-1" />
              </div>
            </CardContent>
          </Card>

          <Card 
            className={cn(
              getCardVariant({ gradient: 'green' }),
              "group relative overflow-hidden hover:border-primary/30 cursor-pointer hover:shadow-lg hover:shadow-green-500/10"
            )}
            onClick={() => router.push("/exercises/list")}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-green-500/0 via-green-500/0 to-green-500/5 group-hover:from-green-500/5 group-hover:via-green-500/5 group-hover:to-green-500/10 transition-all duration-200" />
            <CardContent className="p-5 relative">
              <div className="flex items-start gap-4">
                <div className="p-3 rounded-xl bg-green-100 dark:bg-green-900/40 group-hover:bg-green-200 dark:group-hover:bg-green-900/60 transition-all duration-200 shadow-sm group-hover:shadow-md">
                  <CheckCircle className="h-5 w-5 text-green-600 dark:text-green-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-base mb-1 group-hover:text-primary transition-colors">{tCommon('exercises')}</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{tCommon('practice_exercises') || "Luyện tập bài tập"}</p>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-1 transition-all duration-200 flex-shrink-0 mt-1" />
              </div>
            </CardContent>
          </Card>

          <Card 
            className={cn(
              getCardVariant({ gradient: 'purple' }),
              "group relative overflow-hidden hover:border-primary/30 cursor-pointer hover:shadow-lg hover:shadow-purple-500/10"
            )}
            onClick={() => router.push("/goals")}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-purple-500/0 via-purple-500/0 to-purple-500/5 group-hover:from-purple-500/5 group-hover:via-purple-500/5 group-hover:to-purple-500/10 transition-all duration-200" />
            <CardContent className="p-5 relative">
              <div className="flex items-start gap-4">
                <div className="p-3 rounded-xl bg-purple-100 dark:bg-purple-900/40 group-hover:bg-purple-200 dark:group-hover:bg-purple-900/60 transition-all duration-200 shadow-sm group-hover:shadow-md">
                  <Target className="h-5 w-5 text-purple-600 dark:text-purple-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-base mb-1 group-hover:text-primary transition-colors">{t('goals')}</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">{t('set_and_track_goals') || "Đặt và theo dõi mục tiêu"}</p>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-1 transition-all duration-200 flex-shrink-0 mt-1" />
              </div>
            </CardContent>
          </Card>
        </div>

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
                description={t('stats.coursesCompleted', { count: summary?.completedCourses || 0 })}
                icon={BookOpen}
              />
              <StatCard
                title={t('stats.exercisesCompleted')}
                value={uniqueExercises}
                description={t('stats.exercisesDescription', { exercises: uniqueExercises, attempts: totalAttempts })}
                icon={CheckCircle}
              />
              <StatCard
                title={t('stats.studyTime')}
                value={`${Math.floor(stats.totalMinutes / 60)}h ${stats.totalMinutes % 60}m`}
                description={t('stats.studyTimeDescription', { period: t(`timeRange.${timeRange}`) })}
                icon={Clock}
              />
              <StatCard
                title={t('stats.averageScore')}
                value={stats.avgScore > 0 ? stats.avgScore.toFixed(1) : (summary?.averageScore?.toFixed(1) || "0.0")}
                description={t('stats.bandScore')}
                icon={Target}
              />
              <StatCard
                title={t('stats.currentStreak')}
                value={t('stats.days', { count: stats.activeStreak || summary?.currentStreak || 0 })}
                description={t('stats.longestStreak', { count: summary?.longestStreak || 0 })}
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
                  title={t('charts.studyTime', { period: t(`timeRange.${timeRange}`) })}
                  data={analytics?.studyTimeByDay || []}
                  color="#ED372A"
                  valueLabel={t('charts.minutes')}
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
                    title={t('charts.dailyStudyTime', { period: t(`timeRange.${timeRange}`) })}
                    data={analytics?.studyTimeByDay || []}
                    color="#ED372A"
                    valueLabel={t('charts.minutes')}
                  />
                </Suspense>
                <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                  <ProgressChart
                    title={t('charts.completionRate', { period: t(`timeRange.${timeRange}`) })}
                    data={analytics?.completionRate || []}
                    color="#10B981"
                    valueLabel="%"
                  />
                </Suspense>
                <div>
                  <h3 className="text-lg font-semibold mb-4">{t('exerciseBreakdown')}</h3>
                  {analytics?.exercisesByType?.length > 0 ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                      {analytics.exercisesByType.map((item: any) => (
                        <Card key={item.type}>
                          <CardHeader>
                            <CardTitle className="text-base">{item.type}</CardTitle>
                          </CardHeader>
                          <CardContent>
                            <div className="space-y-2">
                              <div className="flex justify-between">
                                <span className="text-sm text-muted-foreground">{t('completed')}</span>
                                <span className="font-bold">{item.count}</span>
                              </div>
                              <div className="flex justify-between">
                                <span className="text-sm text-muted-foreground">{t('avgScore')}</span>
                                <span className="font-bold">{item.avgScore.toFixed(1)}</span>
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
                          {t('noExercisesCompleted')}
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
                    currentScore={stats.skillScores.listening}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('listening')}
                  />
                  <SkillProgressCard
                    skill="READING"
                    currentScore={stats.skillScores.reading}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('reading')}
                  />
                  <SkillProgressCard
                    skill="WRITING"
                    currentScore={stats.skillScores.writing}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('writing')}
                  />
                  <SkillProgressCard
                    skill="SPEAKING"
                    currentScore={stats.skillScores.speaking}
                    targetScore={user?.targetBandScore || 9}
                    exercisesCompleted={getSkillExerciseCount('speaking')}
                  />
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
