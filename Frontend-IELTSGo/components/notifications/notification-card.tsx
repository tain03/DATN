"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Trash2, Check, ExternalLink } from "lucide-react"
import { type Notification } from "@/types"
import { useTranslations } from "@/lib/i18n"
import { cn } from "@/lib/utils"
import { useRouter } from "next/navigation"
import { formatDistanceToNow } from "date-fns"

interface NotificationCardProps {
  notification: Notification
  onMarkAsRead: (id: string) => void
  onDelete: (id: string) => void
}

export function NotificationCard({ notification, onMarkAsRead, onDelete }: NotificationCardProps) {
  const t = useTranslations('notifications')
  const tCommon = useTranslations('common')
  const router = useRouter()
  
  const isRead = notification.isRead || notification.is_read || notification.read
  const createdAt = notification.createdAt || notification.created_at

  // Get translated title
  const getTranslatedTitle = (): string => {
    const title = notification.title
    if (!title) return ''
    
    // Check if title is a translation key (starts with "notifications.")
    if (title.startsWith('notifications.')) {
      try {
        return t(title.replace('notifications.', ''))
      } catch {
        return title
      }
    }
    return title
  }

  // Get translated message
  const getTranslatedMessage = (): string => {
    const message = notification.message
    if (!message) return ''
    
    const params: Record<string, string | number> = {}
    
    // Extract params from action_data
    if (notification.action_data) {
      if (notification.action_data.follower_name) {
        params.name = notification.action_data.follower_name as string
      }
      if (notification.action_data.course_title) {
        params.course_title = notification.action_data.course_title as string
      }
      if (notification.action_data.lesson_title) {
        params.lesson_title = notification.action_data.lesson_title as string
      }
      if (notification.action_data.exercise_title) {
        params.exercise_title = notification.action_data.exercise_title as string
      }
      if (notification.action_data.achievement_name) {
        params.achievement_name = notification.action_data.achievement_name as string
      }
      if (notification.action_data.goal_title) {
        params.goal_title = notification.action_data.goal_title as string
      }
      if (notification.action_data.days) {
        params.days = notification.action_data.days as number
      }
      if (notification.action_data.progress) {
        params.progress = notification.action_data.progress as number
      }
      if (notification.action_data.score) {
        params.score = notification.action_data.score as number
      }
      if (notification.action_data.rating) {
        params.rating = notification.action_data.rating as number
      }
      if (notification.action_data.reviewer_name) {
        params.reviewer_name = notification.action_data.reviewer_name as string
      }
    }
    
    // Check if message is a translation key (starts with "notifications.")
    if (message.startsWith('notifications.')) {
      try {
        const key = message.replace('notifications.', '')
        return t(key, params)
      } catch {
        return message
      }
    }
    return message
  }
  
  const translatedTitle = getTranslatedTitle()
  const translatedMessage = getTranslatedMessage()

  const getCategoryColor = () => {
    const category = notification.category || 'info'
    switch (category) {
      case 'success': return 'bg-green-500/10 text-green-700 border-green-500/20'
      case 'warning': return 'bg-yellow-500/10 text-yellow-700 border-yellow-500/20'
      case 'alert': return 'bg-red-500/10 text-red-700 border-red-500/20'
      default: return 'bg-blue-500/10 text-blue-700 border-blue-500/20'
    }
  }

  const handleAction = () => {
    if (!notification.actionUrl && !notification.action_type) return

    if (notification.actionUrl) {
      if (notification.actionUrl.startsWith('http')) {
        window.open(notification.actionUrl, '_blank')
      } else {
        router.push(notification.actionUrl)
      }
    } else if (notification.action_type && notification.action_data) {
      const data = notification.action_data
      if (notification.action_type === 'navigate_to_course' && data.course_id) {
        router.push(`/courses/${data.course_id}`)
      } else if (notification.action_type === 'navigate_to_lesson' && data.lesson_id) {
        router.push(`/lessons/${data.lesson_id}`)
      } else if (notification.action_type === 'navigate_to_user_profile' && data.user_id) {
        router.push(`/users/${data.user_id}`)
      } else if (notification.action_type === 'external_link' && data.url) {
        window.open(data.url, '_blank')
      }
    }

    if (!isRead) {
      onMarkAsRead(notification.id)
    }
  }

  return (
    <Card 
      className={cn(
        "relative transition-all cursor-pointer hover:shadow-md",
        !isRead && "border-l-4 border-l-primary bg-primary/5"
      )}
      onClick={handleAction}
    >
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-1">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h3 className={cn(
                    "font-semibold text-sm",
                    !isRead && "font-bold"
                  )}>
                    {translatedTitle}
                  </h3>
                  {!isRead && (
                    <div className="h-2 w-2 rounded-full bg-primary" />
                  )}
                  {notification.category && (
                    <Badge variant="outline" className={cn("text-xs", getCategoryColor())}>
                      {notification.category}
                    </Badge>
                  )}
                </div>
                <p className="text-sm text-muted-foreground">
                  {translatedMessage}
                </p>
              </div>
            </div>
            
            {createdAt && (
              <p className="text-xs text-muted-foreground mt-2">
                {(() => {
                  try {
                    return formatDistanceToNow(new Date(createdAt), { addSuffix: true })
                  } catch {
                    return new Date(createdAt).toLocaleDateString()
                  }
                })()}
              </p>
            )}
          </div>

          <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
            {!isRead && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => onMarkAsRead(notification.id)}
                className="h-8 w-8 p-0"
              >
                <Check className="h-4 w-4" />
              </Button>
            )}
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onDelete(notification.id)}
              className="h-8 w-8 p-0 text-destructive hover:text-destructive"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

