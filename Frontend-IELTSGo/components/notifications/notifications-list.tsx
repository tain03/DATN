"use client"

import { useState, useEffect } from "react"
import { notificationsApi } from "@/lib/api/notifications"
import { NotificationCard } from "./notification-card"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import type { Notification } from "@/types"

export function NotificationsList() {
  const t = useTranslations('notifications')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(true)

  useEffect(() => {
    loadNotifications()
  }, [page])

  const loadNotifications = async () => {
    try {
      setLoading(true)
      const response = await notificationsApi.getNotifications(page, 20)
      const newNotifications = response.notifications || []
      
      setNotifications(prev => 
        page === 1 ? newNotifications : [...prev, ...newNotifications]
      )
      
      const total = response.pagination?.total || 0
      const limit = response.pagination?.limit || 20
      setHasMore(page * limit < total)
    } catch (error: any) {
      console.error('[Notifications] Error loading notifications:', error)
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_load_notifications'),
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleMarkAsRead = async (notificationId: string) => {
    try {
      await notificationsApi.markAsRead(notificationId)
      setNotifications(notifications.map(n => 
        n.id === notificationId 
          ? { ...n, isRead: true, is_read: true, read: true }
          : n
      ))
    } catch (error: any) {
      console.error('[Notifications] Error marking as read:', error)
    }
  }

  const handleDelete = async (notificationId: string) => {
    try {
      await notificationsApi.deleteNotification(notificationId)
      setNotifications(notifications.filter(n => n.id !== notificationId))
      toast({
        title: tCommon('success'),
        description: t('notification_deleted'),
      })
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_delete_notification'),
        variant: "destructive",
      })
    }
  }

  const refreshList = () => {
    setPage(1)
    loadNotifications()
  }

  if (loading && page === 1) {
    return <PageLoading translationKey="loading" />
  }

  if (notifications.length === 0 && !loading) {
    return (
      <EmptyState
        icon={Bell}
        title={t('no_notifications')}
        description={t('no_notifications_description')}
      />
    )
  }

  // Group by read/unread
  const unread = notifications.filter(n => !(n.isRead || n.is_read || n.read))
  const read = notifications.filter(n => n.isRead || n.is_read || n.read)

  return (
    <div className="space-y-6">
      {/* Unread Notifications */}
      {unread.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold">{t('unread')} ({unread.length})</h2>
          </div>
          <div className="space-y-2">
            {unread.map((notification) => (
              <NotificationCard
                key={notification.id}
                notification={notification}
                onMarkAsRead={handleMarkAsRead}
                onDelete={handleDelete}
              />
            ))}
          </div>
        </div>
      )}

      {/* Read Notifications */}
      {read.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4">{t('read')} ({read.length})</h2>
          <div className="space-y-2">
            {read.map((notification) => (
              <NotificationCard
                key={notification.id}
                notification={notification}
                onMarkAsRead={handleMarkAsRead}
                onDelete={handleDelete}
              />
            ))}
          </div>
        </div>
      )}

      {/* Load More */}
      {hasMore && (
        <div className="text-center pt-4">
          <Button 
            onClick={() => setPage(prev => prev + 1)} 
            disabled={loading}
            variant="outline"
          >
            {loading ? tCommon('loading') : tCommon('load_more')}
          </Button>
        </div>
      )}
    </div>
  )
}

