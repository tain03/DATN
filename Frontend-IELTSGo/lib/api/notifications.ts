import { apiClient } from "./apiClient"
import { apiCache } from "@/lib/utils/api-cache"
import type { Notification, PaginatedResponse } from "@/types"
import { sseManager } from "./sse-manager"

export const notificationsApi = {
  // Get all notifications
  getNotifications: async (page = 1, limit = 20): Promise<{ 
    notifications: Notification[]; 
    pagination: { page: number; limit: number; total: number; total_pages: number }
  }> => {
    const cacheKey = apiCache.generateKey('/notifications', { page, limit })
    
    // Check cache first (shorter TTL for notifications - 10 seconds)
    const cached = apiCache.get<{ 
      notifications: Notification[]; 
      pagination: { page: number; limit: number; total: number; total_pages: number }
    }>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<{
      success: boolean
      data: {
        notifications: Notification[]
        pagination: { page: number; limit: number; total: number; total_pages: number }
      }
    }>(`/notifications?page=${page}&limit=${limit}`)
    
    const result = response.data.data
    
    // Cache for 10 seconds (notifications update frequently)
    apiCache.set(cacheKey, result, 10000)
    return result
  },

  // Get unread count
  getUnreadCount: async (): Promise<number> => {
    const response = await apiClient.get<{ unread_count: number }>("/notifications/unread-count")
    return response.data.unread_count || 0
  },

  // Mark notification as read
  markAsRead: async (notificationId: string): Promise<void> => {
    await apiClient.put(`/notifications/${notificationId}/read`)
  },

  // Mark all as read
  markAllAsRead: async (): Promise<void> => {
    await apiClient.put("/notifications/mark-all-read")
  },

  // Delete notification
  deleteNotification: async (notificationId: string): Promise<void> => {
    await apiClient.delete(`/notifications/${notificationId}`)
  },

  // Get notification preferences (from Notification Service)
  getPreferences: async (): Promise<any> => {
    const response = await apiClient.get("/notifications/preferences")
    return response.data
  },

  // Update notification preferences (from Notification Service)
  updatePreferences: async (updates: any): Promise<any> => {
    const response = await apiClient.put("/notifications/preferences", updates)
    return response.data
  },

  // Connect to SSE stream for realtime notifications
  // Uses singleton SSE manager to ensure only one connection
  connectSSE: (
    onNotification: (notification: Notification) => void,
    onError?: (error: Event | Error) => void,
  ): (() => void) => {
      // Use singleton SSE manager to avoid duplicate connections
      // Always returns a function, never null
      try {
        const unsubscribe = sseManager.connect(onNotification, onError)
        
        // Type guard to ensure we always return a function
        if (typeof unsubscribe !== 'function') {
          // Return no-op function as fallback
          return () => {}
        }
        
        return unsubscribe
      } catch (error) {
        // Return no-op function on error
        return () => {}
      }
  },

  // Legacy implementation (kept for reference, not used)
  _connectSSELegacy: (
    onNotification: (notification: Notification) => void,
    onError?: (error: Event | Error) => void,
  ): (() => void) | null => {
    const token = localStorage.getItem("access_token")
    if (!token) {
      console.error("[SSE] No token available")
      return null
    }

    const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"
    const url = `${API_BASE_URL}/notifications/stream`

    let abortController: AbortController | null = null
    let isConnecting = false
    let reconnectTimeout: NodeJS.Timeout | null = null
    let shouldReconnect = true
    let reconnectDelay = 1000 // Start with 1s delay

    const connect = async () => {
      if (isConnecting || !shouldReconnect) return

      isConnecting = true
      abortController = new AbortController()

      try {
        const response = await fetch(url, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: "text/event-stream",
          },
          signal: abortController.signal,
        })

        if (!response.ok) {
          throw new Error(`SSE connection failed: ${response.status} ${response.statusText}`)
        }

        const reader = response.body?.getReader()
        const decoder = new TextDecoder()

        if (!reader) {
          throw new Error("No reader available")
        }

        let buffer = ""

        // Reset reconnect delay on successful connection
        reconnectDelay = 1000
        
        while (true) {
          const { done, value } = await reader.read()
          if (done) {
            isConnecting = false
            if (shouldReconnect) {
              reconnectTimeout = setTimeout(() => {
                reconnectDelay = Math.min(reconnectDelay * 2, 30000) // Exponential backoff, max 30s
                connect()
              }, reconnectDelay)
            }
            break
          }

          buffer += decoder.decode(value, { stream: true })
          
          // Process complete events (separated by double newline or single newline for last line)
          while (buffer.includes("\n\n") || (buffer.includes("\n") && buffer.endsWith("\n"))) {
            let eventEndIndex = buffer.indexOf("\n\n")
            if (eventEndIndex === -1 && buffer.endsWith("\n")) {
              eventEndIndex = buffer.length - 1
            }
            
            if (eventEndIndex === -1) break
            
            const eventText = buffer.substring(0, eventEndIndex)
            buffer = buffer.substring(eventEndIndex + 2)

            let eventType = "message"
            let eventData = ""

            const eventLines = eventText.split("\n")
            for (const line of eventLines) {
              if (line.startsWith("event: ")) {
                eventType = line.substring(7).trim()
              } else if (line.startsWith("data: ")) {
                const lineData = line.substring(6).trim()
                // Handle multi-line data (append if already has data)
                if (eventData) {
                  eventData += "\n" + lineData
                } else {
                  eventData = lineData
                }
              }
            }

            // Process event
            if (eventData) {
              if (eventType === "notification") {
                try {
                  const notification = JSON.parse(eventData) as Notification
                  // Reset reconnect delay on successful message
                  reconnectDelay = 1000
                  onNotification(notification)
                } catch (error) {
                  console.error("[SSE] ❌ Parse error:", error, eventData)
                }
              } else if (eventType === "connected") {
                reconnectDelay = 1000
              } else if (eventType === "heartbeat") {
                // Ignore heartbeat, just keep connection alive
                reconnectDelay = 1000
              }
            }
          }
        }
      } catch (error: any) {
        isConnecting = false
        if (error.name !== "AbortError") {
          console.error("[SSE] ❌ Connection error:", error)
          if (onError) onError(error)
          // Auto-reconnect on error with exponential backoff
          if (shouldReconnect) {
            reconnectTimeout = setTimeout(() => {
              reconnectDelay = Math.min(reconnectDelay * 2, 30000) // Exponential backoff, max 30s
              connect()
            }, reconnectDelay)
          }
        }
      }
    }

    // Start initial connection
    connect()

    // Return cleanup function
    return () => {
      shouldReconnect = false
      if (abortController) {
        abortController.abort()
      }
      if (reconnectTimeout) {
        clearTimeout(reconnectTimeout)
      }
    }
  },

  // Get notification preferences (from Notification Service)
  getNotificationPreferences: async (): Promise<import("@/types").NotificationPreferences> => {
    const response = await apiClient.get<import("@/types").NotificationPreferences>("/notifications/preferences")
    return response.data
  },

  // Update notification preferences (from Notification Service)
  updateNotificationPreferences: async (
    updates: import("@/types").UpdateNotificationPreferencesRequest,
  ): Promise<import("@/types").NotificationPreferences> => {
    const response = await apiClient.put<import("@/types").NotificationPreferences>("/notifications/preferences", updates)
    return response.data
  },
}

export const leaderboardApi = {
  // Get leaderboard with period filtering and pagination
  getLeaderboard: async (
    period: "daily" | "weekly" | "monthly" | "all-time" = "all-time",
    page = 1,
    limit = 50,
  ): Promise<{
    leaderboard: any[]
    pagination: {
      total: number
      page: number
      limit: number
      total_pages: number
    }
  }> => {
    // Generate cache key
    const cacheParams = { period, page, limit }
    const cacheKey = apiCache.generateKey('/user/leaderboard', cacheParams)

    // Check cache
    const cached = apiCache.get<{
      leaderboard: any[]
      pagination: {
        total: number
        page: number
        limit: number
        total_pages: number
      }
    }>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<{
      success: boolean
      data: {
        leaderboard: any[]
        pagination: {
          total: number
          page: number
          limit: number
          total_pages: number
        }
      }
    }>(`/user/leaderboard?period=${period}&page=${page}&limit=${limit}`)
    
    const result = response.data.data
    
    // Cache for 30 seconds (leaderboard updates frequently)
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get current user rank (backend: GET /user/leaderboard/rank)
  getUserRank: async (): Promise<any> => {
    const cacheKey = apiCache.generateKey('/user/leaderboard/rank')
    
    // Check cache
    const cached = apiCache.get<any>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<{
      success: boolean
      data: any
    }>(`/user/leaderboard/rank`)
    
    const result = response.data.data
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },
}

// Types for Social Features
interface ApiResponse<T> {
  success: boolean
  data?: T
  message?: string
  error?: {
    code: string
    message: string
    details?: string
  }
}

interface UserFollowInfo {
  user_id: string
  full_name: string
  avatar_url?: string | null
  bio?: string | null
  level: number
  points: number
  followed_at: string
}

interface FollowersResponse {
  followers: UserFollowInfo[]
  pagination: {
    total: number
    page: number
    page_size: number
    total_pages: number
  }
}

interface FollowingResponse {
  following: UserFollowInfo[]
  pagination: {
    total: number
    page: number
    page_size: number
    total_pages: number
  }
}

export const socialApi = {
  // Get user profile
  // BE Response: { success: true, data: { ...profile with isFollowing, followersCount, followingCount... } }
  // BE Error 403: Profile is private
  // BE Error 404: User not found
  getUserProfile: async (userId: string): Promise<any> => {
    try {
      const response = await apiClient.get<ApiResponse<any>>(`/users/${userId}/profile`)
      if (!response.data.success) {
        throw new Error(response.data.error?.message || "Failed to get profile")
      }
      return response.data.data
    } catch (error: any) {
      // Re-throw with status code preserved for better error handling
      if (error.response?.status === 403) {
        const customError: any = new Error("Profile is private")
        customError.response = error.response
        throw customError
      }
      if (error.response?.status === 404) {
        const customError: any = new Error("User not found")
        customError.response = error.response
        throw customError
      }
      throw error
    }
  },

  // Get user achievements
  // BE Response: { success: true, data: [...] }
  getUserAchievements: async (userId: string): Promise<any[]> => {
    const response = await apiClient.get<ApiResponse<any[]>>(`/users/${userId}/achievements`)
    if (!response.data.success) {
      throw new Error(response.data.error?.message || "Failed to get achievements")
    }
    return response.data.data || []
  },

  // Follow user
  // BE Response: { success: true, message: "User followed successfully" }
  // BE Error: { success: false, error: { code: "CANNOT_FOLLOW_SELF", message: "..." } }
  followUser: async (userId: string): Promise<void> => {
    const response = await apiClient.post<ApiResponse<void>>(`/users/${userId}/follow`)
    
    if (!response.data.success) {
      const errorCode = response.data.error?.code || "FOLLOW_FAILED"
      const errorMsg = response.data.error?.message || "Failed to follow user"
      
      console.error("[Social API] Follow failed:", { errorCode, errorMsg })
      
      // Handle specific error codes
      if (errorCode === "CANNOT_FOLLOW_SELF") {
        const error: any = new Error("You cannot follow yourself")
        error.response = { data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      if (errorCode === "CANNOT_FOLLOW_PRIVATE") {
        const error: any = new Error("Cannot follow a private profile")
        error.response = { status: 403, data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      if (errorCode === "CANNOT_FOLLOW_FRIENDS_ONLY") {
        const error: any = new Error("Cannot follow a friends-only profile")
        error.response = { status: 403, data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      const error: any = new Error(errorMsg)
      error.response = { data: { error: { code: errorCode, message: errorMsg } } }
      throw error
    }
  },

  // Unfollow user
  // BE Response: { success: true, message: "User unfollowed successfully" }
  // BE Error: { success: false, error: { code: "NOT_FOLLOWING", message: "..." } } (404)
  unfollowUser: async (userId: string): Promise<void> => {
    const response = await apiClient.delete<ApiResponse<void>>(`/users/${userId}/follow`)
    
    if (!response.data.success) {
      const errorCode = response.data.error?.code || "UNFOLLOW_FAILED"
      const errorMsg = response.data.error?.message || "Failed to unfollow user"
      
      console.error("[Social API] Unfollow failed:", { errorCode, errorMsg })
      
      // Handle specific error codes
      if (errorCode === "NOT_FOLLOWING") {
        const error: any = new Error("You are not following this user")
        error.response = { status: 404, data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      const error: any = new Error(errorMsg)
      error.response = { data: { error: { code: errorCode, message: errorMsg } } }
      throw error
    }
  },

  // Get followers
  // BE Response: { success: true, data: { followers: [...], pagination: {...} } }
  getFollowers: async (userId: string, page = 1, pageSize = 20): Promise<FollowersResponse> => {
    const response = await apiClient.get<ApiResponse<FollowersResponse>>(
      `/users/${userId}/followers?page=${page}&pageSize=${pageSize}`,
    )
    if (!response.data.success) {
      throw new Error(response.data.error?.message || "Failed to get followers")
    }
    return response.data.data!
  },

  // Get following
  // BE Response: { success: true, data: { following: [...], pagination: {...} } }
  getFollowing: async (userId: string, page = 1, pageSize = 20): Promise<FollowingResponse> => {
    const response = await apiClient.get<ApiResponse<FollowingResponse>>(
      `/users/${userId}/following?page=${page}&pageSize=${pageSize}`,
    )
    if (!response.data.success) {
      throw new Error(response.data.error?.message || "Failed to get following")
    }
    return response.data.data!
  },

  // Remove follower (remove someone who is following you)
  // BE Response: { success: true, message: "Follower removed successfully" }
  // BE Error: { success: false, error: { code: "FOLLOWER_NOT_FOUND", message: "..." } }
  removeFollower: async (followerId: string): Promise<void> => {
    const response = await apiClient.delete<ApiResponse<void>>(`/user/followers/${followerId}`)
    
    if (!response.data.success) {
      const errorCode = response.data.error?.code || "REMOVE_FOLLOWER_FAILED"
      const errorMsg = response.data.error?.message || "Failed to remove follower"
      
      console.error("[Social API] Remove follower failed:", { errorCode, errorMsg })
      
      // Handle specific error codes
      if (errorCode === "FOLLOWER_NOT_FOUND") {
        const error: any = new Error("This user is not following you")
        error.response = { status: 404, data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      if (errorCode === "CANNOT_REMOVE_SELF") {
        const error: any = new Error("You cannot remove yourself")
        error.response = { data: { error: { code: errorCode, message: errorMsg } } }
        throw error
      }
      const error: any = new Error(errorMsg)
      error.response = { data: { error: { code: errorCode, message: errorMsg } } }
      throw error
    }
  },
}
