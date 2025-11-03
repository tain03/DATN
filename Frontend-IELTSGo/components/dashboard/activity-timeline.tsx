import React, { useMemo } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { BookOpen, FileText, GraduationCap } from "lucide-react"
import { formatDistanceToNow } from "date-fns"
import { vi } from "date-fns/locale"
import { useTranslations } from '@/lib/i18n'
import { EmptyState } from "./empty-state"

interface Activity {
  id: string
  type: "course" | "exercise" | "lesson"
  title: string
  completedAt: string
  duration: number
  score?: number
}

interface ActivityTimelineProps {
  activities: Activity[]
}

const activityConfig = {
  course: {
    icon: GraduationCap,
    label: "Course",
    color: "text-blue-600 bg-blue-100",
  },
  exercise: {
    icon: FileText,
    label: "Exercise",
    color: "text-green-600 bg-green-100",
  },
  lesson: {
    icon: BookOpen,
    label: "Lesson",
    color: "text-purple-600 bg-purple-100",
  },
}

function ActivityTimelineComponent({ activities }: ActivityTimelineProps) {
  const t = useTranslations('common')
  
  // Memoize grouping and sorting to avoid recalculating on every render
  const sorted = useMemo(() => {
    // Group activities by type+title, keep only latest, count attempts
    const grouped: Record<string, { activity: Activity; count: number }> = {}
    activities.forEach((activity) => {
      if (activity.type === "exercise") {
        const key = `${activity.type}-${activity.title}`
        if (!grouped[key] || new Date(activity.completedAt) > new Date(grouped[key].activity.completedAt)) {
          grouped[key] = { activity, count: 1 }
        } else {
          grouped[key].count += 1
        }
      } else {
        // For course/lesson, just show all
        const key = `${activity.type}-${activity.id}`
        if (!grouped[key]) grouped[key] = { activity, count: 1 }
      }
    })
    // Sort by completedAt desc
    return Object.values(grouped).sort((a, b) => new Date(b.activity.completedAt).getTime() - new Date(a.activity.completedAt).getTime())
  }, [activities])
  return (
    <Card className="overflow-hidden">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold">{t('recent_activity')}</CardTitle>
      </CardHeader>
      <CardContent>
        {sorted.length === 0 ? (
          <EmptyState 
            type="activity"
            title={t('no_recent_activity') || "Chưa có hoạt động gần đây"}
            description="Hoàn thành bài học hoặc bài tập đầu tiên để xem hoạt động của bạn"
            actionLabel="Bắt đầu học"
            actionHref="/courses"
          />
        ) : (
          <div className="space-y-4">
            {sorted.map(({ activity, count }, index) => {
              const config = activityConfig[activity.type] || activityConfig.exercise // Fallback to exercise if type unknown
              const Icon = config.icon
              return (
                <div key={activity.id + '-' + activity.completedAt} className="flex gap-4">
                  {/* Timeline line */}
                  <div className="flex flex-col items-center">
                    <div className={`p-2 rounded-full ${config.color}`}>
                      <Icon className="h-4 w-4" />
                    </div>
                    {index < sorted.length - 1 && <div className="w-px h-full bg-border mt-2" />}
                  </div>
                  {/* Activity content */}
                  <div className="flex-1 pb-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium text-sm">{activity.title}</p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {t(activity.type === 'course' ? 'course' : activity.type === 'exercise' ? 'exercise' : 'lesson')} • {activity.duration} {t('minutes')}
                          {activity.score !== undefined && ` • ${t('score')}: ${activity.score}`}
                          {activity.type === "exercise" && count > 1 && (
                            <span className="ml-2 text-orange-600">{t('retried_times', { count })}</span>
                          )}
                        </p>
                      </div>
                      <span className="text-xs text-muted-foreground whitespace-nowrap">
                        {formatDistanceToNow(new Date(activity.completedAt), {
                          addSuffix: true,
                          locale: vi,
                        })}
                      </span>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export const ActivityTimeline = React.memo(ActivityTimelineComponent)
