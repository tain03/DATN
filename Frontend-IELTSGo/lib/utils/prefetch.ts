/**
 * Prefetch utilities for faster page navigation
 * Uses router.prefetch and link preloading strategies
 */

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

// Critical routes to prefetch on app load
const PREFETCH_ROUTES = [
    '/dashboard',
    '/courses',
    '/exercises',
    '/login',
]

/**
 * Hook to prefetch critical routes on mount
 * Call this in authenticated layout or homepage
 */
export function usePrefetchRoutes(routes: string[] = PREFETCH_ROUTES) {
    const router = useRouter()

    useEffect(() => {
        // Delay prefetching to avoid blocking initial render
        const timeoutId = setTimeout(() => {
            routes.forEach(route => {
                router.prefetch(route)
            })
        }, 2000) // Wait 2s after initial load

        return () => clearTimeout(timeoutId)
    }, [router, routes])
}

/**
 * Prefetch a route on hover with debounce
 * Use on navigation links for faster perceived navigation
 */
export function usePrefetchOnHover(route: string, delay = 100) {
    const router = useRouter()
    let timeoutId: NodeJS.Timeout

    const onMouseEnter = () => {
        timeoutId = setTimeout(() => {
            router.prefetch(route)
        }, delay)
    }

    const onMouseLeave = () => {
        if (timeoutId) {
            clearTimeout(timeoutId)
        }
    }

    return { onMouseEnter, onMouseLeave }
}

/**
 * Preload image to cache for faster display
 */
export function preloadImage(src: string): Promise<void> {
    return new Promise((resolve, reject) => {
        if (typeof window === 'undefined') {
            resolve()
            return
        }

        const img = new Image()
        img.onload = () => resolve()
        img.onerror = reject
        img.src = src
    })
}

/**
 * Preload multiple images
 */
export function preloadImages(sources: string[]): Promise<void[]> {
    return Promise.all(sources.map(preloadImage))
}
