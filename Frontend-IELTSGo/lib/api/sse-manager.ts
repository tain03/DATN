import type { Notification } from "@/types"

type SSEListener = (notification: Notification) => void
type ErrorListener = (error: Event | Error) => void

class SSEManager {
  private abortController: AbortController | null = null
  private reconnectTimeout: NodeJS.Timeout | null = null
  private shouldReconnect = true
  private listeners: Set<SSEListener> = new Set()
  private errorListeners: Set<ErrorListener> = new Set()
  private isConnected = false
  private isConnecting = false
  private apiBaseUrl: string

  constructor() {
    this.apiBaseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"
  }

  connect(
    onNotification: SSEListener,
    onError?: ErrorListener
  ): () => void {
    // Add listeners FIRST, before starting connection
    // Set doesn't allow duplicates, so we don't need to check
    this.listeners.add(onNotification)
    if (onError) {
      this.errorListeners.add(onError)
    }

    // Create unsubscribe function FIRST (before any async operations)
    const unsubscribe = () => {
      this.listeners.delete(onNotification)
      if (onError) {
        this.errorListeners.delete(onError)
      }
      
      // Only disconnect if no listeners left
      // Use longer delay to avoid race conditions when component re-renders quickly
      if (this.listeners.size === 0) {
        // Longer delay to avoid race conditions
        setTimeout(() => {
          // Double check - maybe a new listener was added during the delay
          if (this.listeners.size === 0) {
            this.disconnect()
          }
        }, 500)
      }
    }

    // Start connection if not already connected or connecting
    // Only create ONE connection regardless of how many listeners
    // Use timeout to handle React Strict Mode double-invoke cycle
    if (!this.isConnected && !this.isConnecting) {
      // Use delay (1200ms) to fully handle React Strict Mode double-invoke cycle
      setTimeout(() => {
        // Double-check listeners before starting
        if (this.listeners.size > 0 && !this.isConnected && !this.isConnecting) {
          this.startConnection()
        }
      }, 1200)
    }

    // Return unsubscribe function (ALWAYS return a function)
    return unsubscribe
  }

  private startConnection() {
    if (this.isConnected || this.isConnecting) {
      return
    }

    // Final check - ensure we have listeners before starting
    if (this.listeners.size === 0) {
      return
    }

    const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null
    if (!token) {
      return
    }

    this.shouldReconnect = true
    // Call private async connectAsync() method
    this.connectAsync()
  }

  private async connectAsync() {
    if (this.isConnecting || !this.shouldReconnect) {
      return
    }

    // Double-check listeners before starting connection
    // If no listeners, wait for React Strict Mode to finish
    if (this.listeners.size === 0) {
      await new Promise(resolve => setTimeout(resolve, 1500))
      
      if (this.listeners.size === 0) {
        this.isConnecting = false
        // Retry connection after React Strict Mode cycle completes
        setTimeout(() => {
          if (this.listeners.size > 0 && !this.isConnected && !this.isConnecting) {
            this.startConnection()
          }
        }, 2000)
        return
      }
    }


    this.isConnecting = true
    this.abortController = new AbortController()
    const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null
    if (!token) {
      console.error("[SSE-Manager] No token available")
      this.isConnecting = false
      return
    }

    const url = `${this.apiBaseUrl}/notifications/stream`
    let reconnectDelay = 1000

    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "text/event-stream",
        },
        signal: this.abortController?.signal,
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
      this.isConnecting = false
      this.isConnected = true

      reconnectDelay = 1000

      while (true) {
        const { done, value } = await reader.read()
        if (done) {
          this.isConnected = false
          this.isConnecting = false
          if (this.shouldReconnect && this.listeners.size > 0) {
            this.reconnectTimeout = setTimeout(() => {
              reconnectDelay = Math.min(reconnectDelay * 2, 30000)
              this.connectAsync()
            }, reconnectDelay)
          }
          break
        }

        buffer += decoder.decode(value, { stream: true })

        // Process complete events (SSE format: event: <type>\ndata: <data>\n\n)
        while (buffer.includes("\n\n") || (buffer.includes("\n") && buffer.endsWith("\n"))) {
          let eventEndIndex = buffer.indexOf("\n\n")
          if (eventEndIndex === -1 && buffer.endsWith("\n")) {
            eventEndIndex = buffer.length - 1
          }

          if (eventEndIndex === -1) break

          const eventText = buffer.substring(0, eventEndIndex)
          buffer = buffer.substring(eventEndIndex + 2)

          let eventType = "message" // Default SSE event type
          let eventData = ""

          // Parse SSE format lines (split by \n or \r\n)
          const eventLines = eventText.split(/\r?\n/)
          
          for (let i = 0; i < eventLines.length; i++) {
            const line = eventLines[i]
            const trimmedLine = line.trim()
            if (!trimmedLine) continue // Skip empty lines
            
            const lowerLine = trimmedLine.toLowerCase()
            
            // Parse event type: "event:connected" or "event: connected" (case-insensitive)
            if (lowerLine.startsWith("event:")) {
              const afterColon = trimmedLine.substring(6) // After "event:"
              eventType = afterColon.trim()
              continue
            }
            
            // Parse data: "data:{\"message\":\"...\"}" or "data: {\"message\":\"...\"}" (case-insensitive)
            if (lowerLine.startsWith("data:")) {
              const afterColon = trimmedLine.substring(5) // After "data:"
              const lineData = afterColon.trim()
              // Handle multi-line data (join with newline)
              if (eventData) {
                eventData += "\n" + lineData
              } else {
                eventData = lineData
              }
              continue
            }
            
            // Ignore other lines (comments starting with ":", id, retry, etc.)
          }

          // Process event - only process if there's data
          if (!eventData) {
            continue
          }
          
          if (eventType === "notification") {
            try {
              const notification = JSON.parse(eventData) as Notification
              reconnectDelay = 1000
              
              // Notify all listeners - use Array.from to avoid iterator issues
              const listenersToNotify = Array.from(this.listeners)
              
              // Notify listeners synchronously to ensure immediate delivery
              listenersToNotify.forEach((listener) => {
                try {
                  listener(notification)
                } catch (error) {
                  // Silent error handling - log only in development
                  if (process.env.NODE_ENV === 'development') {
                    console.error("[SSE-Manager] Error in listener:", error)
                  }
                }
              })
            } catch (error) {
              // Silent error handling
              if (process.env.NODE_ENV === 'development') {
                console.error("[SSE-Manager] Parse error:", error)
              }
            }
          } else if (eventType === "connected") {
            reconnectDelay = 1000
          } else if (eventType === "heartbeat") {
            reconnectDelay = 1000
          }
        }
      }
    } catch (error: any) {
      this.isConnected = false
      this.isConnecting = false
      if (error.name !== "AbortError") {
        // Only log errors in development
        if (process.env.NODE_ENV === 'development') {
          console.error("[SSE-Manager] Connection error:", error)
        }
        this.errorListeners.forEach((listener) => {
          try {
            listener(error)
          } catch (err) {
            // Silent error handling
          }
        })
        // Auto-reconnect on error
        if (this.shouldReconnect && this.listeners.size > 0) {
          this.reconnectTimeout = setTimeout(() => {
            reconnectDelay = Math.min(reconnectDelay * 2, 30000)
            this.connectAsync()
          }, reconnectDelay)
        }
      }
    }
  }

  private disconnect() {
    this.shouldReconnect = false
    this.isConnected = false
    this.isConnecting = false
    
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
    
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout)
      this.reconnectTimeout = null
    }
  }

  // Public method to manually disconnect (when user logs out, etc.)
  destroy() {
    this.listeners.clear()
    this.errorListeners.clear()
    this.disconnect()
  }

  // Check if connected
  getConnected() {
    return this.isConnected
  }

  // Get listener count
  getListenerCount() {
    return this.listeners.size
  }
}

// Singleton instance
export const sseManager = new SSEManager()

