"use client"

import { useState, useEffect } from "react"
import { InstructorLayout } from "@/components/instructor/instructor-layout"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { instructorApi, type InstructorStats, type InstructorActivity } from "@/lib/api/instructor"
import type { Course, Exercise } from "@/types"
import { formatDate } from "@/lib/utils/date"
import { BookOpen, PenTool, Users, TrendingUp, Plus, Star, Target, ArrowRight, Edit, BarChart3 } from "lucide-react"
import Link from "next/link"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "@/components/charts/chart-wrapper"
import { useTranslations } from '@/lib/i18n'

export default function InstructorDashboardPage() {

  const t = useTranslations('common')

  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<InstructorStats | null>(null)
  const [activities, setActivities] = useState<InstructorActivity[]>([])
  const [courses, setCourses] = useState<Course[]>([])
  const [exercises, setExercises] = useState<Exercise[]>([])
  const [engagementData, setEngagementData] = useState<any[]>([])

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      const [statsData, activitiesData, coursesData, exercisesData, engagementData] = await Promise.all([
        instructorApi.getDashboardStats(),
        instructorApi.getRecentActivity(10),
        instructorApi.getMyCourses({ limit: 6 }),
        instructorApi.getMyExercises({ limit: 6 }),
        instructorApi.getEngagementData(30),
      ])

      setStats(statsData)
      setActivities(activitiesData)
      setCourses(Array.isArray(coursesData.data) ? coursesData.data : [])
      setExercises(Array.isArray(exercisesData.data) ? exercisesData.data : [])
      setEngagementData(engagementData)
    } catch (error) {
      console.error("Failed to fetch dashboard data:", error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <ProtectedRoute>
        <InstructorLayout>
          <div className="flex items-center justify-center h-64">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
              <p className="text-muted-foreground">{t('loading_dashboard')}</p>
            </div>
          </div>
        </InstructorLayout>
      </ProtectedRoute>
    )
  }

  return (
    <ProtectedRoute>
      <InstructorLayout>
        <div className="space-y-8">
          {/* Welcome Header */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h1 className="text-3xl font-bold text-foreground">{t('welcome_back_instructor')}</h1>
              <p className="text-muted-foreground mt-1">{t('instructor_welcome_description')}</p>
              <p className="text-sm text-muted-foreground mt-1">{formatDate(new Date().toISOString())}</p>
            </div>
            <div className="flex gap-2">
              <Link href="/instructor/courses/new">
                <Button className="gap-2">
                  <Plus className="h-4 w-4" />
                  {t('create_course')}
                </Button>
              </Link>
              <Link href="/instructor/exercises/new">
                <Button variant="outline" className="gap-2 bg-transparent">
                  <Plus className="h-4 w-4" />
                  {t('create_exercise')}
                </Button>
              </Link>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <Card className="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-950 dark:to-blue-900 border-blue-200">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <BookOpen className="h-8 w-8 text-blue-600" />
                  <Badge variant="secondary">{stats?.publishedCourses} {t('published')}</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-blue-900 dark:text-blue-100">{stats?.totalCourses || 0}</div>
                <p className="text-sm text-blue-700 dark:text-blue-300 mt-1">{t('my_courses')}</p>
                <Link href="/instructor/courses">
                  <Button variant="link" className="p-0 h-auto text-blue-600 mt-2">
                    {t('view_all')} <ArrowRight className="h-3 w-3 ml-1" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-950 dark:to-green-900 border-green-200">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <PenTool className="h-8 w-8 text-green-600" />
                  <Badge variant="secondary">{stats?.publishedExercises} {t('published')}</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-green-900 dark:text-green-100">
                  {stats?.totalExercises || 0}
                </div>
                <p className="text-sm text-green-700 dark:text-green-300 mt-1">{t('my_exercises')}</p>
                <Link href="/instructor/exercises">
                  <Button variant="link" className="p-0 h-auto text-green-600 mt-2">
                    View all <ArrowRight className="h-3 w-3 ml-1" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-orange-50 to-orange-100 dark:from-orange-950 dark:to-orange-900 border-orange-200">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <Users className="h-8 w-8 text-orange-600" />
                  <Badge variant="secondary">{stats?.activeStudents} {t('active')}</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-orange-900 dark:text-orange-100">
                  {stats?.totalStudents || 0}
                </div>
                <p className="text-sm text-orange-700 dark:text-orange-300 mt-1">{t('total_students')}</p>
                <Link href="/instructor/students">
                  <Button variant="link" className="p-0 h-auto text-orange-600 mt-2">
                    {t('view_students')} <ArrowRight className="h-3 w-3 ml-1" />
                  </Button>
                </Link>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-red-50 to-red-100 dark:from-red-950 dark:to-red-900 border-red-200">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <TrendingUp className="h-8 w-8 text-primary" />
                  <Badge variant="secondary" className="bg-green-100 text-green-700">
                    ↑ {stats?.completionTrend || 0}%
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold text-primary">{stats?.averageCompletionRate || 0}%</div>
                <p className="text-sm text-red-700 dark:text-red-300 mt-1">{t('avg_completion_rate')}</p>
                <Link href="/instructor/analytics">
                  <Button variant="link" className="p-0 h-auto text-primary mt-2">
                    {t('view_analytics')} <ArrowRight className="h-3 w-3 ml-1" />
                  </Button>
                </Link>
              </CardContent>
            </Card>
          </div>

          {/* Student Engagement Chart */}
          <Card>
            <CardHeader>
              <CardTitle>{t('student_engagement_last_30_days')}</CardTitle>
              <CardDescription>{t('track_enrollments_attempts_and_completio')}</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={engagementData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="enrollments" stroke="#3b82f6" name={t('enrollments')} />
                  <Line type="monotone" dataKey="attempts" stroke="#10b981" name={t('exercise_attempts')} />
                  <Line type="monotone" dataKey="completions" stroke="#ED372A" name={t('completions')} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Recent Activity */}
            <Card className="lg:col-span-1">
              <CardHeader>
                <CardTitle>{t('recent_activity')}</CardTitle>
                <CardDescription>{t('latest_updates_from_your_students')}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {activities.length > 0 ? (
                    activities.map((activity) => (
                      <div key={activity.id} className="flex gap-3 pb-4 border-b last:border-0 last:pb-0">
                        <div className="flex-shrink-0 w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                          {activity.type === "enrollment" && <Users className="h-4 w-4 text-primary" />}
                          {activity.type === "completion" && <Target className="h-4 w-4 text-green-600" />}
                          {activity.type === "review" && <Star className="h-4 w-4 text-yellow-600" />}
                          {activity.type === "submission" && <PenTool className="h-4 w-4 text-blue-600" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm text-foreground">{activity.action}</p>
                          <p className="text-xs text-muted-foreground mt-1">{formatDate(activity.timestamp)}</p>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-muted-foreground text-center py-8">{t('no_recent_activity')}</p>
                  )}
                </div>
              </CardContent>
            </Card>

            {/* My Courses Preview */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle>{t('my_courses')}</CardTitle>
                    <CardDescription>{t('your_recent_courses')}</CardDescription>
                  </div>
                  <Link href="/instructor/courses">
                    <Button variant="outline" size="sm">
                      {t('view_all')}
                    </Button>
                  </Link>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {courses.length > 0 ? (
                    courses.slice(0, 4).map((course) => (
                      <div key={course.id} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
                        <div className="flex items-start justify-between mb-2">
                          <h4 className="font-semibold text-sm line-clamp-1">{course.title}</h4>
                          <Badge variant={course.status === "published" ? "default" : "secondary"}>
                            {course.status}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground line-clamp-2 mb-3">{course.description}</p>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground mb-2">
                          <span className="flex items-center gap-1">
                            <Users className="h-3 w-3" />
                            {course.enrollmentCount || 0}
                          </span>
                          <span className="flex items-center gap-1">
                            <Star className="h-3 w-3" />
                            {course.averageRating || 0}
                          </span>
                        </div>
                        <Progress value={course.completionRate || 0} className="h-1 mb-2" />
                        <div className="flex gap-2">
                          <Link href={`/instructor/courses/${course.id}/edit`} className="flex-1">
                            <Button variant="outline" size="sm" className="w-full gap-1 bg-transparent">
                              <Edit className="h-3 w-3" />
                              {t('edit')}
                            </Button>
                          </Link>
                          <Link href={`/instructor/courses/${course.id}/analytics`} className="flex-1">
                            <Button variant="outline" size="sm" className="w-full gap-1 bg-transparent">
                              <BarChart3 className="h-3 w-3" />
                              {t('analytics')}
                            </Button>
                          </Link>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="col-span-2 text-center py-8">
                      <BookOpen className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
                      <p className="text-sm text-muted-foreground mb-3">{t('no_courses_yet')}</p>
                      <Link href="/instructor/courses/new">
                        <Button className="gap-2">
                          <Plus className="h-4 w-4" />
                          {t('create_your_first_course')}
                        </Button>
                      </Link>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* My Exercises Preview */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>{t('my_exercises')}</CardTitle>
                  <CardDescription>{t('your_recent_exercises')}</CardDescription>
                </div>
                <Link href="/instructor/exercises">
                  <Button variant="outline" size="sm">
                    {t('view_all')}
                  </Button>
                </Link>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {exercises.length > 0 ? (
                  exercises.slice(0, 6).map((exercise) => (
                    <div key={exercise.id} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
                      <div className="flex items-start justify-between mb-2">
                        <Badge variant="outline">{exercise.type}</Badge>
                        <Badge
                          variant={
                            exercise.difficulty === "easy"
                              ? "default"
                              : exercise.difficulty === "medium"
                                ? "secondary"
                                : "destructive"
                          }
                        >
                          {exercise.difficulty}
                        </Badge>
                      </div>
                      <h4 className="font-semibold text-sm mb-2 line-clamp-2">{exercise.title}</h4>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground mb-3">
                        <span>{exercise.questionCount || 0} {t('questions')}</span>
                        <span>{exercise.totalAttempts || 0} {t('attempts')}</span>
                      </div>
                      <div className="flex gap-2">
                        <Link href={`/instructor/exercises/${exercise.id}/edit`} className="flex-1">
                          <Button variant="outline" size="sm" className="w-full gap-1 bg-transparent">
                            <Edit className="h-3 w-3" />
                            {t('edit')}
                          </Button>
                        </Link>
                        <Link href={`/instructor/exercises/${exercise.id}/analytics`} className="flex-1">
                          <Button variant="outline" size="sm" className="w-full gap-1 bg-transparent">
                            <BarChart3 className="h-3 w-3" />
                            {t('analytics')}
                          </Button>
                        </Link>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="col-span-3 text-center py-8">
                    <PenTool className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
                    <p className="text-sm text-muted-foreground mb-3">{t('no_exercises_yet')}</p>
                    <Link href="/instructor/exercises/new">
                      <Button className="gap-2">
                        <Plus className="h-4 w-4" />
                        {t('create_your_first_exercise')}
                      </Button>
                    </Link>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </InstructorLayout>
    </ProtectedRoute>
  )
}
