"use client"

import { useEffect, useRef, useCallback } from 'react'

interface SwipeGestureOptions {
  onSwipeLeft?: () => void
  onSwipeRight?: () => void
  onSwipeUp?: () => void
  onSwipeDown?: () => void
  onPullToRefresh?: () => void
  threshold?: number // Minimum distance in pixels to trigger swipe
  velocityThreshold?: number // Minimum velocity to trigger swipe
  enabled?: boolean // Enable/disable gestures
}

/**
 * Hook for handling swipe gestures on touch devices
 * Supports:
 * - Swipe left/right for navigation
 * - Swipe up/down for dismiss/refresh
 * - Pull to refresh
 */
export function useSwipeGestures(options: SwipeGestureOptions = {}) {
  const {
    onSwipeLeft,
    onSwipeRight,
    onSwipeUp,
    onSwipeDown,
    onPullToRefresh,
    threshold = 50,
    velocityThreshold = 0.3,
    enabled = true,
  } = options

  const touchStartRef = useRef<{ x: number; y: number; time: number } | null>(null)
  const touchEndRef = useRef<{ x: number; y: number; time: number } | null>(null)
  const pullToRefreshThreshold = 80 // Distance to pull before triggering refresh
  const pullDistanceRef = useRef<number>(0)
  const elementRef = useRef<HTMLElement | null>(null)

  const handleTouchStart = useCallback((e: TouchEvent) => {
    if (!enabled) return

    const touch = e.touches[0]
    touchStartRef.current = {
      x: touch.clientX,
      y: touch.clientY,
      time: Date.now(),
    }
    pullDistanceRef.current = 0
  }, [enabled])

  const handleTouchMove = useCallback((e: TouchEvent) => {
    if (!enabled || !touchStartRef.current) return

    const touch = e.touches[0]
    const deltaY = touch.clientY - touchStartRef.current.y
    const deltaX = touch.clientX - touchStartRef.current.x

    // Pull to refresh - only when scrolling at top
    if (onPullToRefresh && window.scrollY === 0 && deltaY > 0) {
      pullDistanceRef.current = deltaY
      // Visual feedback can be added here (e.g., show refresh indicator)
      e.preventDefault() // Prevent default scroll when pulling to refresh
    }
  }, [enabled, onPullToRefresh])

  const handleTouchEnd = useCallback((e: TouchEvent) => {
    if (!enabled || !touchStartRef.current) return

    const touch = e.changedTouches[0]
    const endTime = Date.now()

    touchEndRef.current = {
      x: touch.clientX,
      y: touch.clientY,
      time: endTime,
    }

    const start = touchStartRef.current
    const end = touchEndRef.current

    const deltaX = end.x - start.x
    const deltaY = end.y - start.y
    const deltaTime = end.time - start.time
    const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
    const velocity = distance / deltaTime

    // Check if this was primarily a horizontal or vertical swipe
    const isHorizontal = Math.abs(deltaX) > Math.abs(deltaY)
    const isVertical = Math.abs(deltaY) > Math.abs(deltaX)

    // Pull to refresh
    if (onPullToRefresh && pullDistanceRef.current >= pullToRefreshThreshold) {
      onPullToRefresh()
      touchStartRef.current = null
      pullDistanceRef.current = 0
      return
    }

    // Only trigger swipe if velocity and distance thresholds are met
    if (velocity >= velocityThreshold && distance >= threshold) {
      if (isHorizontal) {
        // Horizontal swipe
        if (deltaX > 0 && onSwipeRight) {
          // Swipe right
          onSwipeRight()
        } else if (deltaX < 0 && onSwipeLeft) {
          // Swipe left
          onSwipeLeft()
        }
      } else if (isVertical) {
        // Vertical swipe
        if (deltaY > 0 && onSwipeDown) {
          // Swipe down
          onSwipeDown()
        } else if (deltaY < 0 && onSwipeUp) {
          // Swipe up
          onSwipeUp()
        }
      }
    }

    touchStartRef.current = null
    touchEndRef.current = null
    pullDistanceRef.current = 0
  }, [enabled, threshold, velocityThreshold, onSwipeLeft, onSwipeRight, onSwipeUp, onSwipeDown, onPullToRefresh])

  // Attach event listeners to element or window
  useEffect(() => {
    if (!enabled) return

    const target = elementRef.current || window

    target.addEventListener('touchstart', handleTouchStart, { passive: !onPullToRefresh })
    target.addEventListener('touchmove', handleTouchMove, { passive: !onPullToRefresh })
    target.addEventListener('touchend', handleTouchEnd, { passive: true })

    return () => {
      target.removeEventListener('touchstart', handleTouchStart)
      target.removeEventListener('touchmove', handleTouchMove)
      target.removeEventListener('touchend', handleTouchEnd)
    }
  }, [enabled, handleTouchStart, handleTouchMove, handleTouchEnd, onPullToRefresh])

  return {
    ref: elementRef,
  }
}

/**
 * Hook specifically for lesson navigation with swipe left/right
 */
export function useLessonSwipeNavigation(
  onPrevious: () => void,
  onNext: () => void,
  enabled: boolean = true
) {
  return useSwipeGestures({
    onSwipeLeft: onNext, // Swipe left = next lesson
    onSwipeRight: onPrevious, // Swipe right = previous lesson
    threshold: 50,
    velocityThreshold: 0.3,
    enabled,
  })
}

/**
 * Hook for pull to refresh
 */
export function usePullToRefresh(
  onRefresh: () => void,
  enabled: boolean = true
) {
  return useSwipeGestures({
    onPullToRefresh: onRefresh,
    enabled,
  })
}

/**
 * Hook for swipe to dismiss (e.g., notifications)
 */
export function useSwipeToDismiss(
  onDismiss: () => void,
  enabled: boolean = true
) {
  return useSwipeGestures({
    onSwipeLeft: onDismiss,
    onSwipeRight: onDismiss,
    threshold: 100,
    velocityThreshold: 0.5,
    enabled,
  })
}


