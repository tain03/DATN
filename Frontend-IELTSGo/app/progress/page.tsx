"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useState, useEffect, lazy, Suspense, useCallback, useMemo } from "react"
import { progressApi } from "@/lib/api/progress"
import { Button } from "@/components/ui/button"
import { Clock, Target, Flame, BarChart3, BarChart } from "lucide-react"
import { cn } from "@/lib/utils"
import { useTranslations } from '@/lib/i18n'
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"

// Lazy load heavy components to improve initial load time
const ProgressChart = lazy(() => import("@/components/dashboard/progress-chart").then(m => ({ default: m.ProgressChart })))
const StatCard = lazy(() => import("@/components/dashboard/stat-card").then(m => ({ default: m.StatCard })))

export default function ProgressPage() {
  return (
    <ProtectedRoute>
      <ProgressContent />
    </ProtectedRoute>
  )
}

function ProgressContent() {
  const t = useTranslations('common')
  const [timeRange, setTimeRange] = useState<"7d" | "30d" | "90d" | "all">("30d")
  const [analytics, setAnalytics] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let isMounted = true
    
    const fetchAnalytics = async () => {
      try {
        setLoading(true)
        const data = await progressApi.getProgressAnalytics(timeRange)
        
        // Ensure data format is correct - accept empty arrays as valid
        if (data && Array.isArray(data.studyTimeByDay)) {
          // Transform data if needed to match expected format
          const transformedData = {
            studyTimeByDay: data.studyTimeByDay.map((item: any) => ({
              date: item.date || new Date().toISOString(),
              value: item.value ?? item.minutes ?? 0,
            })),
            scoresBySkill: Array.isArray(data.scoresBySkill) ? data.scoresBySkill : [],
            completionRate: Array.isArray(data.completionRate) 
              ? data.completionRate.map((item: any) => ({
                  date: item.date || new Date().toISOString(),
                  value: item.value ?? item.rate ?? 0,
                }))
              : [],
            exercisesByType: Array.isArray(data.exercisesByType) ? data.exercisesByType : [],
          }
          
          if (isMounted) {
            setAnalytics(transformedData)
          }
        } else {
          throw new Error('Invalid data format received from API')
        }
      } catch (error) {
        // Mock data for demo - use hardcoded skill names, will be translated when displayed
        if (isMounted) {
          const mockData = {
            studyTimeByDay: Array.from({ length: 30 }, (_, i) => ({
              date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString(),
              value: Math.floor(Math.random() * 120) + 30,
            })),
            scoresBySkill: [
              { skill: t('listening'), scores: [6.5, 7.0, 7.0, 7.5, 7.5] },
              { skill: t('reading'), scores: [7.0, 7.5, 8.0, 8.0, 8.5] },
              { skill: t('writing'), scores: [6.0, 6.5, 7.0, 7.0, 7.5] },
              { skill: t('speaking'), scores: [6.5, 7.0, 7.0, 7.5, 8.0] },
            ],
            completionRate: Array.from({ length: 30 }, (_, i) => ({
              date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString(),
              value: Math.floor(Math.random() * 40) + 60,
            })),
            exercisesByType: [
              { type: t('reading'), count: 15, avgScore: 8.0 },
              { type: t('listening'), count: 12, avgScore: 7.5 },
              { type: t('writing'), count: 10, avgScore: 7.0 },
              { type: t('speaking'), count: 8, avgScore: 7.5 },
            ],
          }
          setAnalytics(mockData)
        }
      } finally {
        if (isMounted) {
          setLoading(false)
        }
      }
    }

    fetchAnalytics()
    
    return () => {
      isMounted = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [timeRange]) // Only depend on timeRange, t is stable

  // Calculate summary stats - Memoized
  const stats = useMemo(() => {
    if (!analytics) return { totalMinutes: 0, totalExercises: 0, avgScore: 0, activeStreak: 0 }
    
    const totalMinutes = analytics.studyTimeByDay?.reduce((sum: number, day: any) => sum + (day.value || 0), 0) || 0
    const totalExercises = analytics.exercisesByType?.reduce((sum: number, type: any) => sum + (type.count || 0), 0) || 0
    const avgScore = analytics.exercisesByType?.length > 0
      ? analytics.exercisesByType.reduce((sum: number, type: any) => sum + (type.avgScore || 0), 0) / analytics.exercisesByType.length
      : 0
    
    // Calculate active streak (consecutive days with study time)
    let activeStreak = 0
    const sortedDays = [...(analytics.studyTimeByDay || [])].sort((a: any, b: any) => 
      new Date(b.date).getTime() - new Date(a.date).getTime()
    )
    for (const day of sortedDays) {
      if (day.value > 0) activeStreak++
      else break
    }
    
    return { totalMinutes, totalExercises, avgScore, activeStreak }
  }, [analytics])

  // Time range filter buttons component - Memoized
  const timeRangeFilters = useMemo(() => (
    <div className="flex items-center gap-0.5 px-1.5 py-1 bg-muted/60 rounded-lg border border-border/50">
      {(["7d", "30d", "90d", "all"] as const).map((range) => (
        <Button
          key={range}
          variant="ghost"
          size="sm"
          onClick={() => setTimeRange(range)}
          className={cn(
            "h-7 px-3 text-xs font-medium transition-all rounded-md",
            timeRange === range
              ? "bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
              : "hover:bg-muted/80 text-muted-foreground hover:text-foreground"
          )}
        >
          {range === "7d" ? t('last_7_days') :
           range === "30d" ? t('last_30_days') :
           range === "90d" ? t('last_90_days') :
           t('all_time')}
        </Button>
      ))}
    </div>
  ), [timeRange, t])

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <PageHeader
        title={t('progress_analytics')}
        subtitle={t('detailed_insights_into_your_learning_jou')}
        centerContent={!loading ? timeRangeFilters : undefined}
      />
      <PageContainer>
        {loading ? (
          <PageLoading translationKey="loading_analytics" />
        ) : !analytics ? (
          <EmptyState
            icon={BarChart}
            title={t('no_data_available') || 'Không có dữ liệu'}
            description={t('unable_to_load_analytics') || 'Không thể tải dữ liệu phân tích. Vui lòng thử lại sau.'}
          />
        ) : (
          <>
            {/* Summary Stats Grid */}
            <Suspense fallback={
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                {[1, 2, 3, 4].map(i => (
                  <Card key={i}><CardContent className="p-6"><div className="h-[100px] flex items-center justify-center">Loading...</div></CardContent></Card>
                ))}
              </div>
            }>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <StatCard
                  title={t('total_study_time')}
                  value={`${Math.floor(stats.totalMinutes / 60)}h ${stats.totalMinutes % 60}m`}
                  description={t('period_label')}
                  icon={Clock}
                />
                <StatCard
                  title={t('exercises_completed')}
                  value={stats.totalExercises}
                  description={t('period_label')}
                  icon={BarChart3}
                />
                <StatCard
                  title={t('average_score')}
                  value={stats.avgScore.toFixed(1)}
                  description={t('band_score')}
                  icon={Target}
                />
                <StatCard
                  title={t('day_streak')}
                  value={`${stats.activeStreak} ${t('days_label')}`}
                  description={t('active_learning_streak')}
                  icon={Flame}
                />
              </div>
            </Suspense>

            {/* Charts */}
            <Tabs defaultValue="study-time" className="space-y-6">
              <TabsList>
                <TabsTrigger value="study-time">{t('study_time')}</TabsTrigger>
                <TabsTrigger value="completion">{t('completion_rate')}</TabsTrigger>
                <TabsTrigger value="exercises">{t('exercises')}</TabsTrigger>
              </TabsList>

              <TabsContent value="study-time" className="space-y-6">
                <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                  <ProgressChart
                    title={t('daily_study_time')}
                    data={analytics?.studyTimeByDay || []}
                    color="#ED372A"
                    valueLabel={t('minutes')}
                  />
                </Suspense>
              </TabsContent>

              <TabsContent value="completion" className="space-y-6">
                <Suspense fallback={<Card><CardContent className="p-8"><div className="h-[200px] flex items-center justify-center">Loading chart...</div></CardContent></Card>}>
                  <ProgressChart
                    title={t('daily_completion_rate')}
                    data={analytics?.completionRate || []}
                    color="#10B981"
                    valueLabel="%"
                  />
                </Suspense>
              </TabsContent>

              <TabsContent value="exercises" className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  {analytics?.exercisesByType?.map((item: any) => {
                    // Translate skill type name
                    const skillTypeLower = item.type?.toLowerCase() || ''
                    const translatedType = skillTypeLower === 'listening' ? t('listening')
                      : skillTypeLower === 'reading' ? t('reading')
                      : skillTypeLower === 'writing' ? t('writing')
                      : skillTypeLower === 'speaking' ? t('speaking')
                      : item.type
                    return (
                    <Card key={item.type}>
                      <CardHeader>
                        <CardTitle className="text-base">{translatedType}</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="space-y-2">
                          <div className="flex justify-between">
                            <span className="text-sm text-muted-foreground">{t('completed')}</span>
                            <span className="font-bold">{item.count}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-sm text-muted-foreground">{t('avg_score')}</span>
                            <span className="font-bold">{item.avgScore.toFixed(1)}</span>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                    )
                  })}
                </div>
              </TabsContent>
            </Tabs>
          </>
        )}
      </PageContainer>
    </AppLayout>
  )
}
