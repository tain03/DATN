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

    const response = await apiClient.get<ApiResponse<{ 
      courses: Course[]; 
      pagination: { page: number; limit: number; total: number; total_pages: number }
    }>>(`/courses?${params.toString()}`)
    
    // Transform backend response to frontend format
    const pagination = response.data.data.pagination || { page, limit, total: 0, total_pages: 0 }
    const result: PaginatedResponse<Course> = {
      data: response.data.data.courses || [],
      total: pagination.total || 0,
      page: pagination.page || page,
      pageSize: pagination.limit || limit,
      totalPages: pagination.total_pages || 0,
    }
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get single course by ID with full details (modules and lessons) - WITH CACHING
  getCourseById: async (id: string): Promise<{
    course: Course
    modules: Array<{
      module: any
      lessons: Lesson[]
    }>
    is_enrolled: boolean
    enrollment_details?: any
  }> => {
    const cacheKey = apiCache.generateKey(`/courses/${id}`)
    const cached = apiCache.get(cacheKey)
    if (cached) return cached

    const response = await apiClient.get<ApiResponse<any>>(`/courses/${id}`)
    const result = response.data.data
    
    // Cache for 60 seconds (course detail is less likely to change)
    apiCache.set(cacheKey, result, 60000)
    return result
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

  // Get single lesson - WITH CACHING
  getLessonById: async (
    lessonId: string
  ): Promise<{
    lesson: Lesson
    videos: any[]
    materials: any[]
  }> => {
    const cacheKey = apiCache.generateKey(`/lessons/${lessonId}`)
    const cached = apiCache.get(cacheKey)
    if (cached) return cached

    try {
      const response = await apiClient.get<
        ApiResponse<{
          lesson: Lesson
          videos: any[]
          materials: any[]
        }>
      >(`/lessons/${lessonId}`)

      if (response.data.success && response.data.data) {
        const result = {
          lesson: response.data.data.lesson,
          videos: response.data.data.videos || [],
          materials: response.data.data.materials || [],
        }
        
        // Cache for 60 seconds
        apiCache.set(cacheKey, result, 60000)
        return result
      }

      throw new Error('Failed to fetch lesson')
    } catch (error) {
      throw error
    }
  },

  // Enroll in course
  enrollCourse: async (courseId: string): Promise<void> => {
    await apiClient.post(`/enrollments`, { course_id: courseId })
  },

  // Get user's enrolled courses (with pagination support)
  getEnrolledCourses: async (page = 1, limit = 20): Promise<PaginatedResponse<Course>> => {
    const response = await apiClient.get<ApiResponse<{ 
      enrollments: any[];
      pagination: { page: number; limit: number; total: number; total_pages: number }
    }>>(`/enrollments/my?page=${page}&limit=${limit}`)
    
    // Backend returns { enrollments: [...], pagination: {...} }
    // Each enrollment has { enrollment: {...}, course: {...} }
    if (!response.data.data.enrollments || !Array.isArray(response.data.data.enrollments)) {
      const pagination = response.data.data.pagination || { page, limit, total: 0, total_pages: 0 }
      return {
        data: [],
        total: pagination.total || 0,
        page: pagination.page || page,
        pageSize: pagination.limit || limit,
        totalPages: pagination.total_pages || 0,
      }
    }
    
    const pagination = response.data.data.pagination || { page, limit, total: 0, total_pages: 0 }
    return {
      data: response.data.data.enrollments.map((item: any) => item.course),
      total: pagination.total || 0,
      page: pagination.page || page,
      pageSize: pagination.limit || limit,
      totalPages: pagination.total_pages || 0,
    }
  },

  // ✅ NEW: Get enrolled courses WITH progress data (with pagination)
  getEnrolledCoursesWithProgress: async (page = 1, limit = 20): Promise<{
    data: Array<{ course: Course; enrollment: CourseEnrollment }>
    total: number
    page: number
    pageSize: number
    totalPages: number
  }> => {
    const cacheParams = { page, limit }
    const cacheKey = apiCache.generateKey('/enrollments/my', cacheParams)
    
    // Check cache first
    const cached = apiCache.get<{
      data: Array<{ course: Course; enrollment: CourseEnrollment }>
      total: number
      page: number
      pageSize: number
      totalPages: number
    }>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{ 
      enrollments: any[];
      pagination: { page: number; limit: number; total: number; total_pages: number }
    }>>(`/enrollments/my?page=${page}&limit=${limit}`)
    
    if (!response.data.data.enrollments || !Array.isArray(response.data.data.enrollments)) {
      const pagination = response.data.data.pagination || { page, limit, total: 0, total_pages: 0 }
      return {
        data: [],
        total: pagination.total || 0,
        page: pagination.page || page,
        pageSize: pagination.limit || limit,
        totalPages: pagination.total_pages || 0,
      }
    }
    
    const pagination = response.data.data.pagination || { page, limit, total: 0, total_pages: 0 }
    const result = {
      data: response.data.data.enrollments.map((item: any) => ({
        course: item.course,
        enrollment: item.enrollment,
      })),
      total: pagination.total || 0,
      page: pagination.page || page,
      pageSize: pagination.limit || limit,
      totalPages: pagination.total_pages || 0,
    }
    
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
  
  // Get course reviews (with pagination)
  getCourseReviews: async (courseId: string, page = 1, limit = 10): Promise<{
    reviews: any[]
    total: number
    page: number
    limit: number
    totalPages: number
  }> => {
    const cacheKey = apiCache.generateKey(`/courses/${courseId}/reviews`, { page, limit })
    
    // Check cache first
    const cached = apiCache.get<{
      reviews: any[]
      total: number
      page: number
      limit: number
      totalPages: number
    }>(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{
      reviews: any[]
      total: number
      page: number
      limit: number
      total_pages: number
    }>>(`/courses/${courseId}/reviews?page=${page}&limit=${limit}`)
    
    const data = response.data.data
    const result = {
      reviews: data.reviews || [],
      total: data.total || 0,
      page: data.page || page,
      limit: data.limit || limit,
      totalPages: data.total_pages || 0,
    }
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
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
