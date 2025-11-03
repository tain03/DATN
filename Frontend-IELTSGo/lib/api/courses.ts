import { apiClient } from "./apiClient"
import type {
  Course,
  Lesson,
  CourseProgress,
  LessonProgress,
  UpdateLessonProgressRequest,
  EnrollmentProgressResponse,
  CourseEnrollment
} from "@/types"
import { apiCache } from "@/lib/utils/api-cache"

export interface CourseFilters {
  level?: string | string[]
  skill_type?: string | string[]
  enrollment_type?: string | string[]
  is_featured?: boolean
  search?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
  error?: {
    code: string
    message: string
    details?: string
  }
}

export const coursesApi = {
  // Get all courses with filters - WITH CACHING
  getCourses: async (filters?: CourseFilters, page = 1, limit = 12): Promise<PaginatedResponse<Course>> => {
    // Generate cache key including all filter params
    const cacheParams: Record<string, any> = {
      page,
      limit,
      ...(filters?.level && { level: Array.isArray(filters.level) ? filters.level.sort().join(",") : filters.level }),
      ...(filters?.skill_type && { skill_type: Array.isArray(filters.skill_type) ? filters.skill_type.sort().join(",") : filters.skill_type }),
      ...(filters?.enrollment_type && { enrollment_type: Array.isArray(filters.enrollment_type) ? filters.enrollment_type.sort().join(",") : filters.enrollment_type }),
      ...(filters?.is_featured !== undefined && { is_featured: filters.is_featured }),
      ...(filters?.search && { search: filters.search }),
    }
    const cacheKey = apiCache.generateKey('/courses', cacheParams)
    
    // Check cache first (30s TTL for course listings)
    const cached = apiCache.get<PaginatedResponse<Course>>(cacheKey)
    if (cached) {
      return cached
    }

    const params = new URLSearchParams()

    // Backend uses: skill_type, level, enrollment_type, is_featured, search, page, limit
    // Support comma-separated values for OR logic
    if (filters?.level) {
      const levelValue = Array.isArray(filters.level) ? filters.level.join(",") : filters.level
      params.append("level", levelValue)
    }
    if (filters?.skill_type) {
      const skillValue = Array.isArray(filters.skill_type) ? filters.skill_type.join(",") : filters.skill_type
      params.append("skill_type", skillValue)
    }
    if (filters?.enrollment_type) {
      const enrollmentValue = Array.isArray(filters.enrollment_type) ? filters.enrollment_type.join(",") : filters.enrollment_type
      params.append("enrollment_type", enrollmentValue)
    }
    if (filters?.is_featured !== undefined) params.append("is_featured", String(filters.is_featured))
    if (filters?.search) params.append("search", filters.search)

    params.append("page", page.toString())
    params.append("limit", limit.toString())

    const response = await apiClient.get<ApiResponse<{ courses: Course[]; count: number }>>(`/courses?${params.toString()}`)
    
    // Transform backend response to frontend format
    const result: PaginatedResponse<Course> = {
      data: response.data.data.courses || [],
      total: response.data.data.count || 0,
      page: page,
      pageSize: limit,
      totalPages: Math.ceil((response.data.data.count || 0) / limit),
    }
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get single course by ID with full details (modules and lessons)
  getCourseById: async (id: string): Promise<{
    course: Course
    modules: Array<{
      module: any
      lessons: Lesson[]
    }>
    is_enrolled: boolean
    enrollment_details?: any
  }> => {
    const response = await apiClient.get<ApiResponse<any>>(`/courses/${id}`)
    return response.data.data
  },

  // Alias for getCourseById (for consistency)
  getCourseDetail: async (id: string) => {
    return coursesApi.getCourseById(id)
  },

  // Get course curriculum (lessons) - using course detail endpoint
  getCourseLessons: async (courseId: string): Promise<Lesson[]> => {
    const courseDetail = await coursesApi.getCourseById(courseId)
    // Flatten all lessons from all modules
    const allLessons: Lesson[] = []
    if (courseDetail.modules && Array.isArray(courseDetail.modules)) {
      courseDetail.modules.forEach(moduleData => {
        if (moduleData.lessons && Array.isArray(moduleData.lessons)) {
          allLessons.push(...moduleData.lessons)
        }
      })
    }
    return allLessons
  },

  // Get single lesson
  getLessonById: async (
    lessonId: string
  ): Promise<{
    lesson: Lesson
    videos: any[]
    materials: any[]
  }> => {
    try {
      const response = await apiClient.get<
        ApiResponse<{
          lesson: Lesson
          videos: any[]
          materials: any[]
        }>
      >(`/lessons/${lessonId}`)

      if (response.data.success && response.data.data) {
        return {
          lesson: response.data.data.lesson,
          videos: response.data.data.videos || [],
          materials: response.data.data.materials || [],
        }
      }

      throw new Error('Failed to fetch lesson')
    } catch (error) {
      console.error('Error fetching lesson:', error)
      throw error
    }
  },

  // Enroll in course
  enrollCourse: async (courseId: string): Promise<void> => {
    await apiClient.post(`/enrollments`, { course_id: courseId })
  },

  // Get user's enrolled courses
  getEnrolledCourses: async (): Promise<Course[]> => {
    const response = await apiClient.get<ApiResponse<{ enrollments: any[]; total: number }>>("/enrollments/my")
    // Backend returns { enrollments: [...], total: number }
    // Each enrollment has { enrollment: {...}, course: {...} }
    if (!response.data.data.enrollments || !Array.isArray(response.data.data.enrollments)) {
      return []
    }
    return response.data.data.enrollments.map((item: any) => item.course)
  },

  // ✅ NEW: Get enrolled courses WITH progress data
  getEnrolledCoursesWithProgress: async (): Promise<Array<{
    course: Course
    enrollment: CourseEnrollment
  }>> => {
    const cacheKey = apiCache.generateKey('/enrollments/my')
    
    // Check cache first
    const cached = apiCache.get<Array<{ course: Course; enrollment: CourseEnrollment }>>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{ enrollments: any[]; total: number }>>("/enrollments/my")
    if (!response.data.data.enrollments || !Array.isArray(response.data.data.enrollments)) {
      return []
    }
    const result = response.data.data.enrollments.map((item: any) => ({
      course: item.course,
      enrollment: item.enrollment,
    }))
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get enrollment progress (detailed progress with modules)
  getEnrollmentProgress: async (enrollmentId: string): Promise<EnrollmentProgressResponse> => {
    const response = await apiClient.get<ApiResponse<EnrollmentProgressResponse>>(`/enrollments/${enrollmentId}/progress`)
    return response.data.data
  },

  // Get course progress (simple progress percentage)
  getCourseProgress: async (enrollmentId: string): Promise<CourseProgress> => {
    const response = await apiClient.get<ApiResponse<CourseProgress>>(`/enrollments/${enrollmentId}/progress`)
    return response.data.data
  },

  // ✅ Get all lesson progress for a course (by courseId)
  getCourseProgressByCourseId: async (courseId: string): Promise<{ lessons: LessonProgress[] }> => {
    const response = await apiClient.get<ApiResponse<{ lessons: LessonProgress[] }>>(`/courses/${courseId}/progress`)
    return response.data.data
  },

  // Update lesson progress
  updateLessonProgress: async (
    lessonId: string,
    progress: UpdateLessonProgressRequest,
  ): Promise<LessonProgress> => {
    const response = await apiClient.put<ApiResponse<LessonProgress>>(`/progress/lessons/${lessonId}`, progress)
    return response.data.data
  },

  // Mark lesson as completed
  completeLesson: async (lessonId: string): Promise<LessonProgress> => {
    const response = await apiClient.put<ApiResponse<LessonProgress>>(`/progress/lessons/${lessonId}`, {
      is_completed: true
    })
    return response.data.data
  },

  // Add lesson note
  addLessonNote: async (
    courseId: string,
    lessonId: string,
    note: { content: string; timestamp?: number },
  ): Promise<void> => {
    await apiClient.post(`/courses/${courseId}/lessons/${lessonId}/notes`, note)
  },

  // Get lesson notes
  getLessonNotes: async (
    courseId: string,
    lessonId: string,
  ): Promise<Array<{ id: string; content: string; timestamp?: number; createdAt: string }>> => {
    const response = await apiClient.get(`/courses/${courseId}/lessons/${lessonId}/notes`)
    return response.data
  },

  // ============================================
  // VIDEO WATCH TRACKING - REMOVED
  // ============================================
    // ℹ️ Video tracking removed - lesson progress (updateLessonProgress) already includes:
    //    - video_watched_seconds
    //    - video_total_seconds
    //    - last_position_seconds (for resume)
    //    - progress_percentage (single source of truth)
  // Note: video_watch_percentage was removed in migration 011.

  // trackVideoProgress: REMOVED - use updateLessonProgress instead
  // getVideoWatchHistory: REMOVED - use lesson progress history instead

  // Get lesson progress (for resume watching)
  getLessonProgress: async (lessonId: string): Promise<LessonProgress | null> => {
    try {
      const response = await apiClient.get<ApiResponse<LessonProgress>>(`/progress/lessons/${lessonId}`)
      return response.data.data
    } catch (error: any) {
      // Return null if no progress yet (404)
      if (error.response?.status === 404) {
        return null
      }
      throw error
    }
  },

  // ============================================
  // COURSE REVIEWS & RATINGS
  // ============================================
  
  // Get course reviews
  getCourseReviews: async (courseId: string): Promise<any> => {
    const response = await apiClient.get(`/courses/${courseId}/reviews`)
    return response.data
  },

  // Create course review
  createCourseReview: async (
    courseId: string,
    review: {
      rating: number
      title?: string
      comment?: string
    }
  ): Promise<any> => {
    const response = await apiClient.post(`/courses/${courseId}/reviews`, review)
    return response.data
  },

  // Update course review
  updateCourseReview: async (
    courseId: string,
    review: {
      rating?: number
      title?: string
      comment?: string
    }
  ): Promise<any> => {
    const response = await apiClient.put(`/courses/${courseId}/reviews`, review)
    return response.data
  },

  // Get user's review for a course (to check if user has already reviewed)
  getUserReview: async (courseId: string): Promise<any> => {
    // This will be handled by checking the reviews list and finding the current user's review
    // We'll implement this in the frontend component
    const response = await apiClient.get(`/courses/${courseId}/reviews`)
    return response.data
  },
}
