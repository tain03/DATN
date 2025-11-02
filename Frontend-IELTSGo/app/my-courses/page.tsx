"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import Image from "next/image"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { 
  BookOpen, 
  Clock, 
  CheckCircle,
  PlayCircle,
  Award,
  Target,
  Loader2,
  Star,
  Users,
  GraduationCap,
  TrendingUp
} from "lucide-react"
import { coursesApi } from "@/lib/api/courses"
import { useAuth } from "@/lib/contexts/auth-context"
import type { Course, CourseEnrollment } from "@/types"
import { useTranslations } from '@/lib/i18n'
import { usePullToRefresh } from "@/lib/hooks/use-swipe-gestures"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { CourseCard } from "@/components/courses/course-card"
import { HorizontalCardLayout } from "@/components/cards/base-card-layout"
import { formatDuration, formatNumber } from "@/lib/utils/format"

interface EnrolledCourseWithProgress {
  course: Course
  enrollment: CourseEnrollment
}

export default function MyCoursesPage() {

  const t = useTranslations('common')

  const router = useRouter()
  const { user } = useAuth()
  const [enrolledCourses, setEnrolledCourses] = useState<EnrolledCourseWithProgress[]>([])
  const [totalStudyMinutes, setTotalStudyMinutes] = useState(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      loadEnrolledCourses()
    }
  }, [user])

  // Calculate total study time when enrolledCourses changes
  useEffect(() => {
    calculateTotalStudyTime()
  }, [enrolledCourses])

  const loadEnrolledCourses = async () => {
    try {
      setLoading(true)
      const data = await coursesApi.getEnrolledCoursesWithProgress()
      setEnrolledCourses(data)
      console.log('[My Courses] Loaded with progress:', data)
    } catch (error) {
      console.error('[My Courses] Error:', error)
    } finally {
      setLoading(false)
    }
  }

  // 📊 Calculate total study time from COURSES ONLY (sum from enrollments)
  // NOTE: This is different from Dashboard which shows ALL study time (lessons + exercises)
  const calculateTotalStudyTime = () => {
    // Sum up time_spent from all course enrollments
    const total = enrolledCourses.reduce(
      (sum, item) => sum + (item.enrollment.total_time_spent_minutes || 0), 
      0
    )
    setTotalStudyMinutes(total)
  }

  // Pull to refresh
  const { ref: pullToRefreshRef } = usePullToRefresh(() => {
    loadEnrolledCourses()
  }, true)

  if (!user) {
    return (
      <AppLayout showSidebar={true} showFooter={false} hideNavbar={true}>
        <PageContainer className="py-12 text-center">
          <h1 className="text-2xl font-bold mb-4">{t('please_sign_in')}</h1>
          <p className="text-muted-foreground mb-6">
            {t('you_need_to_be_signed_in_to_view_your_cou')}
          </p>
          <Button onClick={() => router.push('/auth/login')}>
            {t('sign_in')}
          </Button>
        </PageContainer>
      </AppLayout>
    )
  }

  if (loading) {
    return (
      <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
        <PageHeader
          title={t('my_learning')}
          subtitle={t('track_your_progress_and_continue_your_ielt')}
        />
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  // ✅ Filter by progress
  const inProgressCourses = enrolledCourses.filter(
    item => item.enrollment.progress_percentage > 0 && item.enrollment.progress_percentage < 100
  )
  const completedCourses = enrolledCourses.filter(
    item => item.enrollment.progress_percentage >= 100
  )

  // ✅ Format total study time (from all sessions: lessons + exercises)
  const totalStudyHours = Math.floor(totalStudyMinutes / 60)
  const totalStudyMins = totalStudyMinutes % 60

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <div ref={pullToRefreshRef as React.RefObject<HTMLDivElement>}>
      <PageHeader
        title={t('my_learning')}
        subtitle={t('track_your_progress_and_continue_your_ielt')}
      />
      <PageContainer maxWidth="7xl">

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('total_courses')}</p>
                  <p className="text-3xl font-bold">{enrolledCourses.length}</p>
                </div>
                <BookOpen className="h-8 w-8 text-blue-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('in_progress')}</p>
                  <p className="text-3xl font-bold">{inProgressCourses.length}</p>
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
                  <p className="text-3xl font-bold">{completedCourses.length}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-500" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">{t('total_study_time')}</p>
                  <p className="text-3xl font-bold">
                    {totalStudyHours > 0 ? `${totalStudyHours}h ${totalStudyMins}m` : `${totalStudyMins}m`}
                  </p>
                </div>
                <Clock className="h-8 w-8 text-purple-500" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Courses Tabs */}
        <Tabs defaultValue="all" className="space-y-6">
          <TabsList>
            <TabsTrigger value="all">
              {t('all_courses')} ({enrolledCourses.length})
            </TabsTrigger>
            <TabsTrigger value="in-progress">
              {t('in_progress_tab')} ({inProgressCourses.length})
            </TabsTrigger>
            <TabsTrigger value="completed">
              {t('completed_tab')} ({completedCourses.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="all" className="space-y-4">
            {loading ? (
              <PageLoading translationKey="loading" />
            ) : enrolledCourses.length === 0 ? (
              <EmptyState
                icon={<BookOpen className="h-12 w-12 text-muted-foreground" />}
                title={t('no_courses_yet')}
                description={t('start_your_ielts_journey_by_enrolling_in_a')}
                action={{
                  label: t('browse_courses') || "Browse Courses",
                  onClick: () => router.push('/courses')
                }}
              />
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {enrolledCourses.map(({ course, enrollment }) => {
                  const progressPct = Math.round(enrollment.progress_percentage || 0)
                  const level = course.level || 'beginner'
                  const skillType = course.skill_type?.toLowerCase() || 'general'
                  const skillColors: Record<string, string> = {
                    listening: "bg-blue-500",
                    reading: "bg-green-500",
                    writing: "bg-orange-500",
                    speaking: "bg-purple-500",
                    general: "bg-gray-500",
                  }
                  const levelColors: Record<string, string> = {
                    beginner: "bg-emerald-500",
                    intermediate: "bg-yellow-500",
                    advanced: "bg-red-500",
                  }
                  
                  return (
                    <HorizontalCardLayout
                      key={course.id}
                      variant="interactive"
                      onClick={() => router.push(`/courses/${course.id}`)}
                      thumbnail={{
                        src: course.thumbnail_url || undefined,
                        alt: course.title,
                        placeholder: {
                          icon: BookOpen,
                        }
                      }}
                      title={course.title}
                      description={course.short_description || course.description || null}
                      badges={
                        <>
                          <Badge className={skillColors[skillType] || skillColors.general} aria-label={t(skillType)}>
                            {t(skillType).toUpperCase()}
                          </Badge>
                          <Badge className={levelColors[level.toLowerCase()] || levelColors.beginner} variant="secondary">
                            {t(level.toLowerCase() || 'beginner')}
                          </Badge>
                          {enrollment.progress_percentage > 0 && enrollment.progress_percentage < 100 && (
                            <Badge className="bg-orange-500">
                              {t('in_progress')}
                            </Badge>
                          )}
                          {enrollment.progress_percentage >= 100 && (
                            <Badge className="bg-green-500">
                              {t('completed')}
                            </Badge>
                          )}
                        </>
                      }
                      stats={
                        <>
                          {course.instructor_name && (
                            <div className="flex items-center gap-1.5">
                              <GraduationCap className="h-4 w-4 text-purple-600" aria-hidden="true" />
                              <span className="text-sm">{course.instructor_name}</span>
                            </div>
                          )}
                          {course.average_rating > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" aria-hidden="true" />
                              <span className="font-medium">
                                {course.average_rating.toFixed(1)}
                              </span>
                              {course.total_reviews > 0 && (
                                <span className="text-muted-foreground text-sm">
                                  ({formatNumber(course.total_reviews)})
                                </span>
                              )}
                            </div>
                          )}
                          {course.total_enrollments > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Users className="h-4 w-4 text-blue-600" aria-hidden="true" />
                              <span className="text-sm">{formatNumber(course.total_enrollments)}</span>
                            </div>
                          )}
                          <div className="flex items-center gap-1.5">
                            <BookOpen className="h-4 w-4 text-blue-600" aria-hidden="true" />
                            <span className="font-medium">
                              {enrollment.lessons_completed || 0}/{course.total_lessons || 0} {t('lessons')}
                            </span>
                          </div>
                          {enrollment.total_time_spent_minutes > 0 ? (
                            <div className="flex items-center gap-1.5">
                              <TrendingUp className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{enrollment.total_time_spent_minutes || 0} {t('minutes')}</span>
                            </div>
                          ) : course.duration_hours && course.duration_hours > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Clock className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{formatDuration(Math.round(course.duration_hours * 3600))}</span>
                            </div>
                          )}
                        </>
                      }
                      progress={enrollment.progress_percentage > 0 && enrollment.progress_percentage < 100 ? {
                        value: progressPct,
                        label: t('progress'),
                      } : undefined}
                      action={{
                        label: enrollment.progress_percentage >= 100 
                          ? t('review_course')
                          : enrollment.progress_percentage > 0
                          ? t('continue_learning')
                          : t('view_course'),
                        onClick: (e) => {
                          e.stopPropagation()
                          router.push(`/courses/${course.id}`)
                        },
                        variant: enrollment.progress_percentage >= 100 ? 'outline' : 'default',
                      }}
                    />
                  )
                })}
              </div>
            )}
          </TabsContent>

          <TabsContent value="in-progress" className="space-y-4">
            {loading ? (
              <PageLoading translationKey="loading" />
            ) : inProgressCourses.length === 0 ? (
              <EmptyState
                icon={<PlayCircle className="h-12 w-12 text-muted-foreground" />}
                title={t('no_in_progress_courses') || "No courses in progress"}
                description={t('no_in_progress_courses_description') || "Start a course to see your progress here"}
                action={{
                  label: t('browse_courses') || "Browse Courses",
                  onClick: () => router.push('/courses')
                }}
              />
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {inProgressCourses.map((item) => {
                  const { course, enrollment } = item
                  const progressPct = Math.round(enrollment.progress_percentage || 0)
                  const skillType = course.skill_type?.toLowerCase() || 'general'
                  const level = course.level || 'beginner'
                  const skillColors: Record<string, string> = {
                    listening: "bg-blue-500",
                    reading: "bg-green-500",
                    writing: "bg-orange-500",
                    speaking: "bg-purple-500",
                    general: "bg-gray-500",
                  }
                  const levelColors: Record<string, string> = {
                    beginner: "bg-emerald-500",
                    intermediate: "bg-yellow-500",
                    advanced: "bg-red-500",
                  }
                  
                  return (
                    <HorizontalCardLayout
                      key={course.id}
                      variant="interactive"
                      onClick={() => router.push(`/courses/${course.id}`)}
                      thumbnail={{
                        src: course.thumbnail_url || undefined,
                        alt: course.title,
                        placeholder: {
                          icon: BookOpen,
                        }
                      }}
                      title={course.title}
                      description={course.short_description || course.description || null}
                      badges={
                        <>
                          <Badge className={skillColors[skillType] || skillColors.general} aria-label={t(skillType)}>
                            {t(skillType).toUpperCase()}
                          </Badge>
                          <Badge className={levelColors[level.toLowerCase()] || levelColors.beginner} variant="secondary">
                            {t(level.toLowerCase() || 'beginner')}
                          </Badge>
                          <Badge className="bg-orange-500">
                            {t('in_progress')}
                          </Badge>
                        </>
                      }
                      stats={
                        <>
                          {course.instructor_name && (
                            <div className="flex items-center gap-1.5">
                              <GraduationCap className="h-4 w-4 text-purple-600" aria-hidden="true" />
                              <span className="text-sm">{course.instructor_name}</span>
                            </div>
                          )}
                          {course.average_rating > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" aria-hidden="true" />
                              <span className="font-medium">
                                {course.average_rating.toFixed(1)}
                              </span>
                              {course.total_reviews > 0 && (
                                <span className="text-muted-foreground text-sm">
                                  ({formatNumber(course.total_reviews)})
                                </span>
                              )}
                            </div>
                          )}
                          {course.total_enrollments > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Users className="h-4 w-4 text-blue-600" aria-hidden="true" />
                              <span className="text-sm">{formatNumber(course.total_enrollments)}</span>
                            </div>
                          )}
                          <div className="flex items-center gap-1.5">
                            <BookOpen className="h-4 w-4 text-blue-600" aria-hidden="true" />
                            <span className="font-medium">
                              {enrollment.lessons_completed || 0}/{course.total_lessons || 0} {t('lessons')}
                            </span>
                          </div>
                          {enrollment.total_time_spent_minutes > 0 ? (
                            <div className="flex items-center gap-1.5">
                              <TrendingUp className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{enrollment.total_time_spent_minutes || 0} {t('minutes')}</span>
                            </div>
                          ) : course.duration_hours && course.duration_hours > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Clock className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{formatDuration(Math.round(course.duration_hours * 3600))}</span>
                            </div>
                          )}
                        </>
                      }
                      progress={{
                        value: progressPct,
                        label: t('progress'),
                      }}
                      action={{
                        label: t('continue_learning'),
                        onClick: (e) => {
                          e.stopPropagation()
                          router.push(`/courses/${course.id}`)
                        },
                      }}
                    />
                  )
                })}
              </div>
            )}
          </TabsContent>

          <TabsContent value="completed" className="space-y-4">
            {completedCourses.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <Award className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">
                    {t('complete_your_first_course_to_earn_achiev')}
                  </p>
                </CardContent>
              </Card>
            ) : (
              <div className="grid grid-cols-1 gap-4">
                {completedCourses.map((item) => {
                  const { course, enrollment } = item
                  const skillType = course.skill_type?.toLowerCase() || 'general'
                  const level = course.level || 'beginner'
                  const skillColors: Record<string, string> = {
                    listening: "bg-blue-500",
                    reading: "bg-green-500",
                    writing: "bg-orange-500",
                    speaking: "bg-purple-500",
                    general: "bg-gray-500",
                  }
                  const levelColors: Record<string, string> = {
                    beginner: "bg-emerald-500",
                    intermediate: "bg-yellow-500",
                    advanced: "bg-red-500",
                  }
                  
                  return (
                    <HorizontalCardLayout
                      key={course.id}
                      variant="interactive"
                      onClick={() => router.push(`/courses/${course.id}`)}
                      thumbnail={{
                        src: course.thumbnail_url || undefined,
                        alt: course.title,
                        placeholder: {
                          icon: BookOpen,
                        }
                      }}
                      title={course.title}
                      description={course.short_description || course.description || null}
                      badges={
                        <>
                          <Badge className={skillColors[skillType] || skillColors.general} aria-label={t(skillType)}>
                            {t(skillType).toUpperCase()}
                          </Badge>
                          <Badge className={levelColors[level.toLowerCase()] || levelColors.beginner} variant="secondary">
                            {t(level.toLowerCase() || 'beginner')}
                          </Badge>
                          <Badge className="bg-green-500">{t('completed')}</Badge>
                        </>
                      }
                      stats={
                        <>
                          {course.instructor_name && (
                            <div className="flex items-center gap-1.5">
                              <GraduationCap className="h-4 w-4 text-purple-600" aria-hidden="true" />
                              <span className="text-sm">{course.instructor_name}</span>
                            </div>
                          )}
                          {course.average_rating > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" aria-hidden="true" />
                              <span className="font-medium">
                                {course.average_rating.toFixed(1)}
                              </span>
                              {course.total_reviews > 0 && (
                                <span className="text-muted-foreground text-sm">
                                  ({formatNumber(course.total_reviews)})
                                </span>
                              )}
                            </div>
                          )}
                          {course.total_enrollments > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Users className="h-4 w-4 text-blue-600" aria-hidden="true" />
                              <span className="text-sm">{formatNumber(course.total_enrollments)}</span>
                            </div>
                          )}
                          <div className="flex items-center gap-1.5">
                            <BookOpen className="h-4 w-4 text-blue-600" aria-hidden="true" />
                            <span className="font-medium">
                              {enrollment.lessons_completed || 0}/{course.total_lessons || 0} {t('lessons')}
                            </span>
                          </div>
                          {enrollment.total_time_spent_minutes > 0 ? (
                            <div className="flex items-center gap-1.5">
                              <TrendingUp className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{enrollment.total_time_spent_minutes || 0} {t('minutes')}</span>
                            </div>
                          ) : course.duration_hours && course.duration_hours > 0 && (
                            <div className="flex items-center gap-1.5">
                              <Clock className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                              <span className="text-sm">{formatDuration(Math.round(course.duration_hours * 3600))}</span>
                            </div>
                          )}
                        </>
                      }
                      action={{
                        label: t('review_course'),
                        onClick: (e) => {
                          e.stopPropagation()
                          router.push(`/courses/${course.id}`)
                        },
                        variant: "outline",
                      }}
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