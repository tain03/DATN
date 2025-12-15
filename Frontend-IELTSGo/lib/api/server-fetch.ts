/**
 * Server-side data fetching utilities
 * Used by Server Components to fetch initial data for faster first paint
 */

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api/v1'

interface ServerFetchOptions {
    revalidate?: number | false  // Cache duration in seconds, or false for no cache
    tags?: string[]  // Cache tags for on-demand revalidation
}

/**
 * Server-side fetch with Next.js caching
 * Use this in Server Components for static/ISR data
 */
export async function serverFetch<T>(
    endpoint: string,
    options: ServerFetchOptions = {}
): Promise<T> {
    const { revalidate = 60, tags } = options

    const url = endpoint.startsWith('http')
        ? endpoint
        : `${API_BASE_URL}${endpoint}`

    const fetchOptions: RequestInit = {
        headers: {
            'Content-Type': 'application/json',
        },
        next: {
            revalidate,
            ...(tags && { tags }),
        },
    }

    try {
        const response = await fetch(url, fetchOptions)

        if (!response.ok) {
            console.error(`[ServerFetch] Error ${response.status}: ${endpoint}`)
            throw new Error(`HTTP ${response.status}`)
        }

        return response.json()
    } catch (error) {
        console.error(`[ServerFetch] Failed to fetch ${endpoint}:`, error)
        throw error
    }
}

/**
 * Fetch public courses list (no auth required)
 * Cached for 5 minutes (300 seconds)
 */
export async function getPublicCourses(page = 1, limit = 12) {
    try {
        const data = await serverFetch<{
            success: boolean
            data: {
                courses: any[]
                pagination: {
                    page: number
                    limit: number
                    total: number
                    total_pages: number
                }
            }
        }>(`/courses?page=${page}&limit=${limit}`, {
            revalidate: 300, // 5 minutes
            tags: ['courses'],
        })

        return {
            courses: data.data?.courses || [],
            pagination: data.data?.pagination || { page, limit, total: 0, total_pages: 0 },
        }
    } catch (error) {
        console.error('[getPublicCourses] Error:', error)
        // Return empty data on error, let client-side handle retry
        return {
            courses: [],
            pagination: { page, limit, total: 0, total_pages: 0 },
        }
    }
}

/**
 * Fetch featured courses for homepage
 * Cached for 10 minutes (600 seconds)
 */
export async function getFeaturedCourses(limit = 6) {
    try {
        const data = await serverFetch<{
            success: boolean
            data: {
                courses: any[]
                pagination: any
            }
        }>(`/courses?is_featured=true&limit=${limit}`, {
            revalidate: 600, // 10 minutes
            tags: ['featured-courses'],
        })

        return data.data?.courses || []
    } catch (error) {
        console.error('[getFeaturedCourses] Error:', error)
        return []
    }
}

/**
 * Fetch single course (public info only)
 * Cached for 5 minutes
 */
export async function getPublicCourse(courseId: string) {
    try {
        const data = await serverFetch<{
            success: boolean
            data: any
        }>(`/courses/${courseId}`, {
            revalidate: 300,
            tags: [`course-${courseId}`],
        })

        return data.data
    } catch (error) {
        console.error(`[getPublicCourse] Error fetching ${courseId}:`, error)
        return null
    }
}

/**
 * Fetch public exercises list (no auth required)
 * Cached for 5 minutes (300 seconds)
 */
export async function getPublicExercises(page = 1, limit = 12) {
    try {
        const data = await serverFetch<{
            success: boolean
            data: {
                exercises: any[]
                pagination: {
                    page: number
                    limit: number
                    total: number
                    total_pages: number
                }
            }
        }>(`/exercises?page=${page}&limit=${limit}`, {
            revalidate: 300, // 5 minutes
            tags: ['exercises'],
        })

        return {
            exercises: data.data?.exercises || [],
            pagination: data.data?.pagination || { page, limit, total: 0, total_pages: 0 },
        }
    } catch (error) {
        console.error('[getPublicExercises] Error:', error)
        return {
            exercises: [],
            pagination: { page, limit, total: 0, total_pages: 0 },
        }
    }
}

