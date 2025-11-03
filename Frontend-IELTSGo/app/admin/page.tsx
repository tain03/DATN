"use client"

import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Users, BookOpen, PenTool, TrendingUp, TrendingDown, Bell, Activity as ActivityIcon, FileText } from "lucide-react"
import { adminApi } from "@/lib/api/admin"
import type { DashboardStats, Activity as ActivityType } from "@/types/admin"
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "@/components/charts/chart-wrapper"
import { formatDistanceToNow } from "@/lib/utils/date"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { useTranslations } from '@/lib/i18n'

export default function AdminDashboard() {

  const t = useTranslations('common')

  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [userGrowthData, setUserGrowthData] = useState<{ date: string; count: number }[]>([])
  const [enrollmentData, setEnrollmentData] = useState<{ date: string; enrollments: number; completions: number }[]>([])
  const [activities, setActivities] = useState<ActivityType[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboardData()
    const interval = setInterval(() => {
      loadActivities()
    }, 30000) // Refresh activities every 30 seconds

    return () => clearInterval(interval)
  }, [])

  const loadDashboardData = async () => {
    try {
      setLoading(true)
      
      // TODO: Uncomment when backend admin API is implemented
      // const [statsData, growthData, enrollData, activitiesData] = await Promise.all([
      //   adminApi.getDashboardStats(),
      //   adminApi.getUserGrowthData(30),
      //   adminApi.getEnrollmentData(7),
      //   adminApi.getRecentActivities(20),
      // ])
      // setStats(statsData)
      // setUserGrowthData(growthData)
      // setEnrollmentData(enrollData)
      // setActivities(activitiesData)
      
      // Using mock data until backend is ready
      setStats({
        totalUsers: 1247,
        totalStudents: 892,
        totalInstructors: 23,
        totalAdmins: 5,
        userGrowth: 12.5,
        totalCourses: 45,
        activeCourses: 38,
        draftCourses: 7,
        totalExercises: 234,
        submissionsToday: 87,
        averageCompletionRate: 78.5,
        systemHealth: "healthy",
        cpuUsage: 45,
        memoryUsage: 62,
      })
      
      setUserGrowthData(
        Array.from({ length: 30 }, (_, i) => ({
          date: new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000).toISOString(),
          count: Math.floor(Math.random() * 50) + 20,
        }))
      )
      
      setEnrollmentData(
        Array.from({ length: 7 }, (_, i) => ({
          date: new Date(Date.now() - (6 - i) * 24 * 60 * 60 * 1000).toISOString(),
          enrollments: Math.floor(Math.random() * 20) + 10,
          completions: Math.floor(Math.random() * 10) + 5,
        }))
      )
      
      setActivities([
        {
          id: "1",
          type: "user",
          action: "registered",
          actorName: "John Doe",
          actorAvatar: "/placeholder-user.jpg",
          timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
        },
        {
          id: "2",
          type: "course",
          action: "completed IELTS Writing Masterclass",
          actorName: "Jane Smith",
          actorAvatar: "/placeholder-user.jpg",
          timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        },
        {
          id: "3",
          type: "exercise",
          action: "submitted IELTS Reading Practice Test 5",
          actorName: "Mike Johnson",
          timestamp: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        },
        {
          id: "4",
          type: "review",
          action: "reviewed Writing Task 2 submission",
          actorName: "Sarah Williams",
          actorAvatar: "/placeholder-user.jpg",
          timestamp: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
        },
      ])
    } catch (error) {
      console.error("Failed to load dashboard data:", error)
    } finally {
      setLoading(false)
    }
  }

  const loadActivities = async () => {
    try {
      // TODO: Uncomment when backend admin API is implemented
      // const activitiesData = await adminApi.getRecentActivities(20)
      // setActivities(activitiesData)
      
      // Mock data - no need to refresh
    } catch (error) {
      console.error("Failed to load activities:", error)
    }
  }

  if (loading || !stats) {
    return (
      <div className="space-y-6">
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="h-32 bg-gray-200 rounded-lg"></CardHeader>
            </Card>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-foreground">{t('dashboard')}</h1>
        <p className="text-muted-foreground mt-1">{t('admin_welcome_message')}</p>
      </div>
        {/* Stat Cards */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {/* Total Users */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">{t('total_users')}</CardTitle>
              <Users className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalUsers.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                {stats.userGrowth >= 0 ? (
                  <>
                    <TrendingUp className="w-3 h-3 text-green-500" />
                    <span className="text-green-500">+{stats.userGrowth}%</span>
                  </>
                ) : (
                  <>
                    <TrendingDown className="w-3 h-3 text-red-500" />
                    <span className="text-red-500">{stats.userGrowth}%</span>
                  </>
                )}
                {" "}{t('from_last_month')}
              </p>
            </CardContent>
          </Card>

          {/* Total Courses */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">{t('total_courses')}</CardTitle>
              <BookOpen className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalCourses.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.activeCourses} {t('active')}, {stats.draftCourses} {t('draft')}
              </p>
            </CardContent>
          </Card>

          {/* Total Exercises */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">{t('total_exercises')}</CardTitle>
              <PenTool className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalExercises.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.submissionsToday} {t('submissions_today')}
              </p>
            </CardContent>
          </Card>

          {/* Total Students */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">{t('total_students')}</CardTitle>
              <ActivityIcon className="w-4 h-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalStudents.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stats.totalInstructors} {t('instructors')}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Charts */}
        <div className="grid gap-6 lg:grid-cols-2">
          {/* User Growth Chart */}
          <Card>
            <CardHeader>
              <CardTitle>{t('user_growth_last_30_days')}</CardTitle>
            </CardHeader>
            <CardContent className="pt-6">
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={userGrowthData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#ED372A20" />
                  <XAxis 
                    dataKey="date" 
                    tick={{ fontSize: 12, fill: '#101615' }}
                    tickFormatter={(value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  />
                  <YAxis tick={{ fontSize: 12, fill: '#101615' }} />
                  <Tooltip 
                    labelFormatter={(value) => new Date(value).toLocaleDateString()}
                    contentStyle={{ border: '1px solid #ED372A20', borderRadius: '8px' }}
                  />
                  <Line type="monotone" dataKey="count" stroke="#ED372A" strokeWidth={3} dot={{ fill: '#ED372A' }} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          {/* Enrollment Statistics */}
          <Card>
            <CardHeader>
              <CardTitle>{t('enrollment_statistics_last_7_days')}</CardTitle>
            </CardHeader>
            <CardContent className="pt-6">
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={enrollmentData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#ED372A20" />
                  <XAxis 
                    dataKey="date" 
                    tick={{ fontSize: 12, fill: '#101615' }}
                    tickFormatter={(value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  />
                  <YAxis tick={{ fontSize: 12, fill: '#101615' }} />
                  <Tooltip 
                    labelFormatter={(value) => new Date(value).toLocaleDateString()}
                    contentStyle={{ border: '1px solid #ED372A20', borderRadius: '8px' }}
                  />
                  <Legend />
                  <Bar dataKey="enrollments" fill="#ED372A" name={t('new_enrollments')} radius={[4, 4, 0, 0]} />
                  <Bar dataKey="completions" fill="#101615" name={t('completions')} radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>

        {/* Activity Feed & Quick Actions */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Activity Feed */}
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle>{t('recent_activity')}</CardTitle>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="space-y-4 max-h-96 overflow-y-auto">
                {activities && activities.length > 0 ? (
                  activities.map((activity) => (
                    <div key={activity.id} className="flex items-start gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors">
                      <Avatar className="h-10 w-10">
                        <AvatarImage src={activity.actorAvatar || "/placeholder.svg"} />
                        <AvatarFallback>
                          {activity.actorName?.charAt(0) || "?"}
                        </AvatarFallback>
                      </Avatar>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm">
                          <span className="font-medium">{activity.actorName || t('unknown')}</span>{" "}
                          <span className="text-muted-foreground">{activity.action || t('performed_an_action')}</span>
                        </p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {activity.timestamp ? formatDistanceToNow(activity.timestamp) : t('just_now')}
                        </p>
                      </div>
                      <Badge variant="outline" className="text-xs">
                        {activity.type}
                      </Badge>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 text-muted-foreground">
                    <p>{t('no_recent_activity')}</p>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>{t('quick_actions')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 pt-6">
              <Button className="w-full justify-start" variant="default">
                <Bell className="mr-2 h-4 w-4" />
                {t('create_notification')}
              </Button>
              <Button className="w-full justify-start" variant="outline">
                <Users className="mr-2 h-4 w-4" />
                {t('add_new_user')}
              </Button>
              <Button className="w-full justify-start" variant="outline">
                <BookOpen className="mr-2 h-4 w-4" />
                {t('review_pending_content')}
              </Button>
              <Button className="w-full justify-start" variant="outline">
                <FileText className="mr-2 h-4 w-4" />
                {t('view_system_logs')}
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
  )
}
