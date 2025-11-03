"use client"

import { useState, useEffect } from "react"
import { Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { NotificationList } from "./notification-list"
import { notificationsApi } from "@/lib/api/notifications"
import { Badge } from "@/components/ui/badge"

export function NotificationBell() {
  const [unreadCount, setUnreadCount] = useState(0)
  const [isOpen, setIsOpen] = useState(false)
  const [newNotification, setNewNotification] = useState<any>(null)

  useEffect(() => {
    let isMounted = true
    let disconnectSSE: (() => void) | null = null

    // Load initial unread count
    loadUnreadCount()

    // Connect to SSE for realtime notifications (singleton connection)
    const handleNotification = (notification: any) => {
      if (!isMounted) return
      
      // Pass notification to NotificationList via state update trigger
      setNewNotification(notification)
      
      // Refresh unread count from server immediately (single source of truth)
      // Don't increment locally to avoid duplicates from SSE reconnections
      loadUnreadCount()
    }

    const handleError = (error: Event | Error) => {
      if (!isMounted) return
      loadUnreadCount()
    }
    
    try {
      disconnectSSE = notificationsApi.connectSSE(handleNotification, handleError)
    } catch (error) {
      // Silent error - SSE connection failed, will fallback to polling
    }

    // Fallback: Poll every 60 seconds (reduced frequency since SSE handles real-time)
    const interval = setInterval(() => {
      if (isMounted) {
        loadUnreadCount()
      }
    }, 60000)

    return () => {
      isMounted = false
      if (disconnectSSE && typeof disconnectSSE === 'function') {
        disconnectSSE()
      }
      clearInterval(interval)
    }
  }, []) // Empty deps - only run once on mount

  const loadUnreadCount = async () => {
    try {
      const count = await notificationsApi.getUnreadCount()
      setUnreadCount(count)
    } catch (error) {
      // Silent error handling
    }
  }

  const handleMarkAllAsRead = async () => {
    try {
      await notificationsApi.markAllAsRead()
      // Reload unread count from server immediately (single source of truth)
      loadUnreadCount()
    } catch (error) {
      // Silent error handling
      console.error("[NotificationBell] Failed to mark all as read:", error)
    }
  }

  // Sync unread count when dropdown opens
  useEffect(() => {
    if (isOpen) {
      // Reload unread count when dropdown opens to ensure accuracy
      loadUnreadCount()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen])

  return (
    <DropdownMenu open={isOpen} onOpenChange={setIsOpen}>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <Badge
              variant="destructive"
              className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-xs"
            >
              {unreadCount > 9 ? "9+" : unreadCount}
            </Badge>
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent 
        align="end" 
        className="w-[400px] p-0 rounded-xl shadow-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900"
        sideOffset={8}
        style={{ maxHeight: 'calc(100vh - 100px)' }}
      >
        <NotificationList
          onMarkAllAsRead={handleMarkAllAsRead}
          onNotificationRead={() => loadUnreadCount()}
          newNotification={newNotification}
          onNewNotificationHandled={() => setNewNotification(null)}
          isOpen={isOpen}
          onUnreadCountSync={setUnreadCount}
        />
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

