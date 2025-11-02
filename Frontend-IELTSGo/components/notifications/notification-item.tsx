"use client"

import { useState, useRef, useEffect } from "react"
import { formatDistanceToNow } from "date-fns"
import { vi, enUS } from "date-fns/locale"
import { useLocale } from "@/lib/i18n"
import { X } from "lucide-react"
import type { Notification } from "@/types"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { useRouter } from "next/navigation"
import { useTranslations } from "@/lib/i18n"
import { useSwipeToDismiss } from "@/lib/hooks/use-swipe-gestures"

interface NotificationItemProps {
  notification: Notification
  onMarkAsRead: (id: string) => void
  onDelete: (id: string) => void
}

export function NotificationItem({ notification, onMarkAsRead, onDelete }: NotificationItemProps) {
  const router = useRouter()
  const t = useTranslations()
  const { locale } = useLocale()
  const tNotif = useTranslations('notifications')
  const [isExpanded, setIsExpanded] = useState(false)
  const [needsTruncation, setNeedsTruncation] = useState(false)
  const messageRef = useRef<HTMLParagraphElement>(null)
  const isRead = notification.read ?? notification.isRead ?? notification.is_read ?? false
  const createdAt = notification.createdAt || notification.created_at

  // Swipe to dismiss
  const { ref: swipeRef } = useSwipeToDismiss(
    () => onDelete(notification.id),
    true // Enable on mobile
  )

  // Mapping for hardcoded notification texts to translation keys
  const getNotificationTranslationKey = (text: string, type: string): string | null => {
    // Map common Vietnamese notification texts to translation keys
    const titleMap: Record<string, string> = {
      "Chào mừng đến với IELTSGo": "notifications.welcome_title",
      "Hoàn thành bài học!": "notifications.lesson_completion_title",
      "Kết quả bài tập": "notifications.exercise_result_title",
      "Bạn đã đạt được thành tựu mới": "notifications.achievement_title",
      "Bạn đã hoàn thành mục tiêu": "notifications.goal_completion_title",
      "Bạn đã duy trì chuỗi học tập": "notifications.streak_milestone_title",
      "Đã đăng ký khóa học thành công": "notifications.course_enrollment_title",
      "Chúc mừng! Bạn đã hoàn thành khóa học": "notifications.course_completion_title",
      "Bài học mới đã được thêm vào khóa học": "notifications.new_lesson_title",
      "Khóa học của bạn vừa nhận đánh giá mới": "notifications.review_received_title",
      "Bạn đã hoàn thành bài học": "notifications.lesson_completed_title",
    }

    // Try exact match first
    if (titleMap[text]) {
      return titleMap[text]
    }

    // Try pattern matching for dynamic content
    if (type === "exercise_graded" && text.includes("Kết quả bài tập")) {
      return "notifications.exercise_result_title"
    }
    if (type === "course_update" && text.includes("đăng ký khóa học")) {
      return "notifications.course_enrollment_title"
    }
    if (type === "course_update" && text.includes("Bài học mới")) {
      return "notifications.new_lesson_title"
    }
    if (type === "course_update" && text.includes("đánh giá mới")) {
      return "notifications.review_received_title"
    }
    if (type === "achievement" && text.includes("thành tựu")) {
      return "notifications.achievement_title"
    }
    if (type === "achievement" && text.includes("hoàn thành khóa học")) {
      return "notifications.course_completion_title"
    }
    if (type === "course_update" && text.includes("Hoàn thành bài học")) {
      return "notifications.lesson_completion_title"
    }

    // Check if already a translation key
    if (text.startsWith("notifications.")) {
      return text
    }

    return null
  }

  // Translate notification title and message
  const getTranslatedTitle = (): string => {
    const title = notification.title
    const translationKey = getNotificationTranslationKey(title, notification.type)
    
    if (translationKey) {
      try {
        const translated = t(translationKey)
        return translated !== translationKey ? translated : title
      } catch {
        return title
      }
    }
    return title
  }

  const getTranslatedMessage = (): string => {
    const message = notification.message
    const params: Record<string, string | number> = {}
    
    // Extract params from action_data and message content
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

    // Map message patterns to translation keys
    let messageKey: string | null = null

    // Check if message is already a translation key
    if (message.startsWith("notifications.")) {
      messageKey = message
    } else {
      // Pattern matching for Vietnamese messages
      if (message.includes("Cảm ơn bạn đã tham gia IELTSGo")) {
        messageKey = "notifications.welcome_message"
      } else if (message.includes("Bạn đã hoàn thành bài học") && message.includes("Tiến độ")) {
        messageKey = "notifications.lesson_completion_message"
      } else if (message.includes("Bạn đã hoàn thành bài tập") && message.includes("điểm")) {
        messageKey = "notifications.exercise_result_message"
      } else if (message.includes("Chúc mừng! Bạn đã đạt được thành tựu")) {
        messageKey = "notifications.achievement_message"
      } else if (message.includes("Chúc mừng! Bạn đã hoàn thành mục tiêu")) {
        messageKey = "notifications.goal_completion_message"
      } else if (message.includes("Bạn đã học liên tục") && message.includes("ngày")) {
        messageKey = "notifications.streak_milestone_message"
      } else if (message.includes("Bạn đã đăng ký khóa học") && message.includes("Bắt đầu học ngay")) {
        messageKey = "notifications.course_enrollment_message"
      } else if (message.includes("Bạn đã hoàn thành khóa học") && message.includes("Tiếp tục")) {
        messageKey = "notifications.course_completion_message"
      } else if (message.includes("vừa có bài học mới") && message.includes("Truy cập")) {
        messageKey = "notifications.new_lesson_message"
      } else if (message.includes("vừa nhận được đánh giá") && message.includes("sao từ")) {
        messageKey = "notifications.review_received_message"
      } else if (message.includes("Chúc mừng! Bạn đã hoàn thành bài học") && message.includes("Tiến độ khóa học")) {
        messageKey = "notifications.lesson_completed_message"
      }
      // Pattern matching for English messages (from backend hardcoded or old notifications)
      else if (message.includes("started following you") || (message.includes("{") && message.includes("started following"))) {
        messageKey = "notifications.new_follower_message"
        // Extract name from {Name} pattern - MUST extract BEFORE translating
        if (!params.name) {
          // Try multiple patterns: {Name}, '{Name}', "{Name}"
          const match1 = message.match(/\{([^}]+)\}/)
          const match2 = message.match(/'\{([^}]+)\}'/)
          const match3 = message.match(/"\{([^}]+)\}"/)
          if (match1) params.name = match1[1].trim()
          else if (match2) params.name = match2[1].trim()
          else if (match3) params.name = match3[1].trim()
        }
      } else if (message.includes("You have completed the exercise") || (message.includes("completed the exercise") && message.includes("score"))) {
        messageKey = "notifications.exercise_result_message"
        // Extract exercise title from '{Exercise Title}' or {Exercise Title} pattern - MUST extract BEFORE translating
        if (!params.exercise_title) {
          // Match: exercise '{Exercise 1: True/False/Not Given}' with a score
          // Match: exercise '{Title}' or exercise {Title}
          // Also handle already processed messages: exercise Exercise 1: True/False/Not Given with a score
          const patterns = [
            /exercise\s+['"]?\{([^}]+)\}['"]?\s+with a score/i,
            /exercise\s+['"]\{([^}]+)\}['"]\s+with a score/i,
            /['"]?\{([^}]+)\}['"]?\s+with a score/i,
            // Handle already processed (quotes removed)
            /exercise\s+([^'"]+?)\s+with a score/i,
          ]
          for (const pattern of patterns) {
            const match = message.match(pattern)
            if (match && match[1]) {
              params.exercise_title = match[1].trim()
              break
            }
          }
        }
        // Extract score from {0} or score of {0} or score of 0 - MUST extract BEFORE translating
        if (!params.score && typeof params.score !== 'number') {
          // First check action_data (most reliable source)
          if (notification.action_data?.score !== undefined) {
            params.score = typeof notification.action_data.score === 'number' 
              ? notification.action_data.score 
              : parseFloat(notification.action_data.score as string)
            if (!isNaN(params.score as number)) {
              // Score found in action_data, skip regex patterns
            } else {
              params.score = undefined
            }
          }
          
          // If not in action_data, try regex patterns
          if (!params.score || isNaN(params.score as number)) {
            const patterns = [
              /with a score of\s+\{([\d.]+)\}/i,
              /with a score\s+of\s+(\d+(?:\.\d+)?)/i,
              /score of\s+\{([\d.]+)\}/i,
              /score\s+of\s+(\d+(?:\.\d+)?)/i,
              /with a score of\s+(\d+(?:\.\d+)?)/i,
              // Handle remaining {score} or {0} placeholders
              /with a score of\s+\{score\}/i,
              /with a score of\s+\{(\d+(?:\.\d+)?)\}/i,
              /\{(\d+(?:\.\d+)?)\}/i, // Any number in braces at the end
            ]
            for (const pattern of patterns) {
              const match = message.match(pattern)
              if (match && match[1]) {
                const scoreValue = parseFloat(match[1])
                if (!isNaN(scoreValue)) {
                  params.score = scoreValue
                  break
                }
              }
            }
          }
          
          // Last resort: if message contains {score} placeholder and we still don't have a value
          // This means the backend didn't provide it, we'll need to keep the placeholder
          // or try to infer from message context
        }
      } else if (message.includes("Thank you for joining IELTSGo") || message.includes("Start your IELTS learning journey")) {
        messageKey = "notifications.welcome_message"
      }

      // Extract dynamic values from message if not in action_data (Vietnamese patterns)
      if (!params.course_title && message.includes("khóa học '")) {
        const match = message.match(/khóa học '([^']+)'/)
        if (match) params.course_title = match[1]
      }
      if (!params.lesson_title && message.includes("bài học '")) {
        const match = message.match(/bài học '([^']+)'/)
        if (match) params.lesson_title = match[1]
      }
      if (!params.exercise_title && message.includes("bài tập '")) {
        const match = message.match(/bài tập '([^']+)'/)
        if (match) params.exercise_title = match[1]
      }
      if (!params.achievement_name && message.includes("thành tựu '")) {
        const match = message.match(/thành tựu '([^']+)'/)
        if (match) params.achievement_name = match[1]
      }
      if (!params.goal_title && message.includes("mục tiêu '")) {
        const match = message.match(/mục tiêu '([^']+)'/)
        if (match) params.goal_title = match[1]
      }
      if (!params.days && message.includes("học liên tục")) {
        const match = message.match(/(\d+) ngày/)
        if (match) params.days = parseInt(match[1])
      }
      if (!params.progress && message.includes("Tiến độ")) {
        const match = message.match(/(\d+)%/)
        if (match) params.progress = parseInt(match[1])
      }
      // Extract from English patterns
      if (!params.score && message.includes("with a score")) {
        const match = message.match(/with a score (?:of )?\{?([\d.]+)\}?/)
        if (match) params.score = parseFloat(match[1])
      }
      if (!params.rating && message.includes("đánh giá") && message.includes("sao")) {
        const match = message.match(/(\d+) sao/)
        if (match) params.rating = parseInt(match[1])
      }
      if (!params.reviewer_name && message.includes("sao từ")) {
        const match = message.match(/sao từ ([^.]+)/)
        if (match) params.reviewer_name = match[1].trim()
      }
    }

    if (messageKey) {
      try {
        // Debug: log params to ensure they're extracted
        if (process.env.NODE_ENV === 'development') {
          console.log('[Notification] Translating:', {
            key: messageKey,
            params: params,
            message: message.substring(0, 100)
          })
        }
        
        const translated = t(messageKey, params)
        
        // If translation still has unreplaced placeholders, try to extract from original message
        if (translated.includes('{{score}}') || translated.includes('{score}')) {
          // Score not replaced - try one more time to extract from original message
          // Check multiple patterns including Vietnamese and English
          const scorePatterns = [
            /với điểm\s+([\d.]+)/i,
            /điểm\s+([\d.]+)/i,
            /score\s+(?:of\s+)?(\d+(?:\.\d+)?)/i,
            /score of\s+(\d+(?:\.\d+)?)/i,
            /with a score of\s+(\d+(?:\.\d+)?)/i,
            /with a score\s+(\d+(?:\.\d+)?)/i,
            // Look for any number near the word "score"
            /score.*?(\d+(?:\.\d+)?)/i,
          ]
          
          for (const pattern of scorePatterns) {
            const scoreMatch = message.match(pattern)
            if (scoreMatch && scoreMatch[1]) {
              const extractedScore = parseFloat(scoreMatch[1])
              if (!isNaN(extractedScore)) {
                params.score = extractedScore
                // Retry translation with score param
                const retranslated = t(messageKey, params)
                if (!retranslated.includes('{{score}}') && !retranslated.includes('{score}')) {
                  return retranslated
                }
                break
              }
            }
          }
          
          // If still no score, and message literally contains "{score}", remove it
          if (translated.includes('{score}') && (!params.score || isNaN(params.score as number))) {
            // Replace {score} with empty or "N/A" - but this is not ideal
            // Better to keep placeholder or log error
            if (process.env.NODE_ENV === 'development') {
              console.warn('[Notification] Cannot extract score from message:', message)
            }
          }
        }
        
        // If still has placeholders after all attempts, log warning but return translated
        if ((translated.includes('{{') && !translated.match(/\{\{[a-z_]+\}\}/)) || 
            (translated.includes('{') && !translated.match(/\{[a-z_]+\}/))) {
          if (process.env.NODE_ENV === 'development') {
            console.warn('[Notification] Translation has unreplaced placeholders:', translated, 'params:', params)
          }
        }
        
        return translated !== messageKey ? translated : message
      } catch (error) {
        if (process.env.NODE_ENV === 'development') {
          console.error('[Notification] Translation error:', error, 'key:', messageKey, 'params:', params)
        }
        return message
      }
    }

    // If no translation key found, try to clean up message but preserve content
    // Replace {content} with content (remove brackets but keep the text)
    const cleanedMessage = message.replace(/\{([^}]+)\}/g, '$1').replace(/\s+/g, ' ').trim()
    return cleanedMessage !== message ? cleanedMessage : message
  }

  const translatedTitle = getTranslatedTitle()
  const translatedMessage = getTranslatedMessage()

  // Format notification message with proper styling (like real-world systems: LinkedIn, Facebook)
  // Removes ugly {} and formats names/values properly
  const formatNotificationMessage = (msg: string): React.ReactNode => {
    let formatted = msg
    
    // Remove quotes around titles if they exist
    formatted = formatted.replace(/'([^']+)'/g, '$1').replace(/"([^"]+)"/g, '$1')
    
    // Clean up any remaining {} brackets - extract content and remove brackets
    formatted = formatted.replace(/\{([^}]+)\}/g, '$1')
    
    // Split message into parts for formatting
    const parts: React.ReactNode[] = []
    let lastIndex = 0
    
    // Find and format names (bold like LinkedIn/Facebook)
    if (notification.action_data?.follower_name) {
      const name = notification.action_data.follower_name as string
      const nameIndex = formatted.indexOf(name)
      if (nameIndex !== -1) {
        // Add text before name
        if (nameIndex > lastIndex) {
          parts.push(formatted.substring(lastIndex, nameIndex))
        }
        // Add bold name
        parts.push(
          <span key={`name-${nameIndex}`} className="font-semibold text-gray-900 dark:text-gray-100">
            {name}
          </span>
        )
        lastIndex = nameIndex + name.length
      }
    }
    
    // Add remaining text
    if (lastIndex < formatted.length) {
      const remaining = formatted.substring(lastIndex)
      // Format numbers (scores, progress, days) with semibold
      const numberRegex = /\b(\d+(?:\.\d+)?)\b/g
      let numberLastIndex = 0
      let numberMatch
      
      while ((numberMatch = numberRegex.exec(remaining)) !== null) {
        const beforeNumber = remaining.substring(numberLastIndex, numberMatch.index)
        if (beforeNumber) parts.push(beforeNumber)
        parts.push(
          <span key={`number-${numberMatch.index}`} className="font-semibold">
            {numberMatch[0]}
          </span>
        )
        numberLastIndex = numberMatch.index + numberMatch[0].length
      }
      
      if (numberLastIndex < remaining.length) {
        parts.push(remaining.substring(numberLastIndex))
      }
    }
    
    return parts.length > 0 ? parts : formatted
  }
  
  // Check if message actually needs truncation by comparing heights
  // Wait for DOM to render before checking
  useEffect(() => {
    // Use requestAnimationFrame to ensure DOM is fully rendered
    const checkTruncation = () => {
      if (messageRef.current && !isExpanded) {
        // Temporarily remove line-clamp to get full height
        const originalClasses = messageRef.current.className
        messageRef.current.classList.remove('line-clamp-2')
        const fullHeight = messageRef.current.scrollHeight
        
        // Restore line-clamp
        messageRef.current.className = originalClasses
        
        // Get line height and calculate max height for 2 lines
        const lineHeight = parseFloat(getComputedStyle(messageRef.current).lineHeight) || 20
        const maxHeight = lineHeight * 2 + 2 // 2 lines with small buffer
        
        // Only show "Xem thêm" if content actually exceeds 2 lines
        setNeedsTruncation(fullHeight > maxHeight)
      } else {
        setNeedsTruncation(false)
      }
    }
    
    // Small delay to ensure DOM is rendered
    const timeoutId = setTimeout(checkTruncation, 10)
    return () => clearTimeout(timeoutId)
  }, [translatedMessage, isExpanded])

  const handleClick = (e: React.MouseEvent) => {
    // Don't navigate if clicking expand button or delete button
    if ((e.target as HTMLElement).closest('button')) {
      return
    }

    if (!isRead) {
      onMarkAsRead(notification.id)
    }

    // Handle action navigation (giống Udemy/Coursera)
    if (notification.action_type && notification.action_data) {
      if (notification.action_type === "navigate_to_course" && notification.action_data.course_id) {
        router.push(`/courses/${notification.action_data.course_id}`)
      } else if (notification.action_type === "navigate_to_lesson" && notification.action_data.course_id && notification.action_data.lesson_id) {
        router.push(`/courses/${notification.action_data.course_id}/lessons/${notification.action_data.lesson_id}`)
      } else if (notification.action_type === "navigate_to_user_profile" && notification.action_data.user_id) {
        router.push(`/users/${notification.action_data.user_id}`)
      } else if (notification.action_type === "external_link" && notification.action_data.url) {
        window.open(notification.action_data.url, "_blank")
      } else if (notification.actionUrl) {
        router.push(notification.actionUrl)
      }
    } else if (notification.actionUrl) {
      router.push(notification.actionUrl)
    }
  }

  const formatTime = () => {
    if (!createdAt) return tNotif('just_now')
    try {
      const date = new Date(createdAt)
      if (isNaN(date.getTime())) {
        return tNotif('just_now')
      }
      // Use locale based on current user locale
      const dateFnsLocale = locale === 'vi' ? vi : enUS
      return formatDistanceToNow(date, { addSuffix: true, locale: dateFnsLocale })
    } catch {
      return tNotif('just_now')
    }
  }

  return (
    <div
      ref={swipeRef as React.RefObject<HTMLDivElement>}
      className={cn(
        "group relative flex items-start gap-3 px-4 py-3.5 hover:bg-gray-50/80 dark:hover:bg-gray-800/50 cursor-pointer",
        "transition-all duration-200 border-b border-gray-100/80 dark:border-gray-800/50 last:border-b-0",
        !isRead && "bg-primary/5 dark:bg-primary/10"
      )}
      onClick={handleClick}
    >
      {/* Unread indicator - subtle left border với màu chủ đạo */}
      {!isRead && (
        <div className="absolute left-0 top-0 bottom-0 w-1 bg-primary rounded-r-full" />
      )}

      {/* Content - clean text layout */}
      <div className="flex-1 min-w-0 pt-0.5">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <p className={cn(
              "text-sm font-semibold text-gray-900 dark:text-gray-100 leading-5 mb-1.5",
              !isRead && "text-gray-900 dark:text-gray-50"
            )}>
              {translatedTitle}
            </p>
            <div className="space-y-1.5">
              <div className="relative">
                {/* Message with gradient fade (professional approach like Udemy/Coursera) */}
                <div className="relative">
                  <p 
                    ref={messageRef}
                    className={cn(
                      "text-sm text-gray-600 dark:text-gray-400 leading-relaxed whitespace-pre-wrap break-words",
                      "transition-all duration-300 ease-in-out",
                      !isExpanded && needsTruncation && "line-clamp-2"
                    )}
                  >
                    {formatNotificationMessage(translatedMessage)}
                  </p>
                  
                  {/* Gradient fade overlay when truncated (subtle, professional) */}
                  {/* Matches notification background: white/gray-50 for read, primary/5 for unread */}
                  {!isExpanded && needsTruncation && (
                    <>
                      {/* Light mode - white background */}
                      <div 
                        className="absolute bottom-0 left-0 right-0 h-8 pointer-events-none dark:hidden"
                        style={{
                          background: isRead 
                            ? 'linear-gradient(to bottom, transparent, white)' 
                            : 'linear-gradient(to bottom, transparent, rgba(237, 55, 42, 0.05))',
                        }}
                      />
                      {/* Dark mode - gray-900 background */}
                      <div 
                        className="absolute bottom-0 left-0 right-0 h-8 pointer-events-none hidden dark:block"
                        style={{
                          background: isRead
                            ? 'linear-gradient(to bottom, transparent, rgb(17 24 39))'
                            : 'linear-gradient(to bottom, transparent, rgba(237, 55, 42, 0.1))',
                        }}
                      />
                    </>
                  )}
                </div>
                
                {/* Subtle inline "Xem thêm" button (professional style) */}
                {needsTruncation && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      setIsExpanded(!isExpanded)
                    }}
                    className={cn(
                      "inline-flex items-center text-xs text-primary/70 hover:text-primary",
                      "transition-all duration-200 font-normal",
                      "mt-1 -ml-0.5 px-0.5 py-0",
                      "focus:outline-none focus:underline"
                    )}
                  >
                    {isExpanded ? (
                      <span className="underline">Thu gọn</span>
                    ) : (
                      <span>... Xem thêm</span>
                    )}
                  </button>
                )}
              </div>
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2.5">
              {formatTime()}
            </p>
          </div>

          {/* Delete button - only show on hover */}
          <Button
            variant="ghost"
            size="icon"
            className={cn(
              "shrink-0 opacity-0 group-hover:opacity-100 transition-all duration-200",
              "text-gray-400 hover:text-gray-700 dark:hover:text-gray-200",
              "hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full"
            )}
            onClick={(e) => {
              e.stopPropagation()
              onDelete(notification.id)
            }}
          >
            <X className="h-3.5 w-3.5" />
          </Button>
        </div>
      </div>
    </div>
  )
}
