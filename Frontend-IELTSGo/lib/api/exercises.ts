import { apiClient } from "./apiClient"
import { apiCache } from "@/lib/utils/api-cache"
import type { Exercise, ExerciseSubmission, ExerciseResult } from "@/types"

export interface SubmissionFilters {
  skill?: string[]
  status?: string[]
  sort_by?: 'date' | 'score' | 'band_score'
  sort_order?: 'asc' | 'desc'
  date_from?: string // YYYY-MM-DD
  date_to?: string   // YYYY-MM-DD
  search?: string    // Search by exercise title
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

// Backend response structure
interface BackendExerciseResponse {
  success: boolean
  data: {
    exercises: Exercise[]
    pagination: {
      page: number
      limit: number
      total: number
      total_pages: number
    }
  }
}

export const exercisesApi = {
  // Get all exercises with filters
  getExercises: async (filters?: ExerciseFilters, page = 1, pageSize = 12): Promise<PaginatedResponse<Exercise>> => {
    // Generate cache key
    const cacheParams: Record<string, any> = {
      page,
      limit: pageSize,
      ...(filters?.skill?.length && { skill_type: filters.skill.sort().join(",") }),
      ...(filters?.type?.length && { exercise_type: filters.type.sort().join(",") }),
      ...(filters?.difficulty?.length && { difficulty: filters.difficulty.sort().join(",") }),
      ...(filters?.search && { search: filters.search }),
      ...(filters?.sort && { sort_by: filters.sort }),
      ...(filters?.sort_order && { sort_order: filters.sort_order }),
    }
    const cacheKey = apiCache.generateKey('/exercises', cacheParams)

    // Check cache
    const cached = apiCache.get<PaginatedResponse<Exercise>>(cacheKey)
    if (cached) {
      return cached
    }

    const params = new URLSearchParams()

    if (filters?.skill?.length) params.append("skill_type", filters.skill.join(","))
    if (filters?.type?.length) params.append("exercise_type", filters.type.join(","))
    if (filters?.difficulty?.length) params.append("difficulty", filters.difficulty.join(","))
    if (filters?.search) params.append("search", filters.search)
    if (filters?.sort) params.append("sort_by", filters.sort)
    if (filters?.sort_order) params.append("sort_order", filters.sort_order)

    params.append("page", page.toString())
    params.append("limit", pageSize.toString())

    const response = await apiClient.get<BackendExerciseResponse>(`/exercises?${params.toString()}`)
    
    // Transform backend response to match frontend expectation
    const backendData = response.data.data
    const pagination = backendData.pagination || { page, limit: pageSize, total: 0, total_pages: 0 }
    
    const result: PaginatedResponse<Exercise> = {
      data: backendData.exercises || [],
      total: pagination.total || 0,
      page: pagination.page || page,
      pageSize: pagination.limit || pageSize,
      totalPages: pagination.total_pages || 0,
    }

    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get single exercise by ID with sections and questions
  getExerciseById: async (id: string): Promise<import("@/types").ExerciseDetailResponse> => {
    const response = await apiClient.get<{ 
      success: boolean
      data: import("@/types").ExerciseDetailResponse 
    }>(`/exercises/${id}`)
    return response.data.data
  },

  // Start exercise (create submission)
  startExercise: async (exerciseId: string): Promise<{ id: string; started_at: string }> => {
    const response = await apiClient.post<{
      success: boolean
      data: { id: string; started_at: string }
    }>(`/submissions`, { exercise_id: exerciseId })
    return response.data.data
  },

  // Submit answers for a submission (Listening/Reading)
  submitAnswers: async (submissionId: string, answers: Array<{
    question_id: string
    selected_option_id?: string
    text_answer?: string
    time_spent_seconds?: number
  }>): Promise<void> => {
    await apiClient.put(`/submissions/${submissionId}/answers`, { answers })
  },

  // Submit exercise (unified for all skills - Writing/Speaking use this)
  submitExercise: async (submissionId: string, data: {
    // For Writing
    writing_data?: {
      essay_text: string
      word_count: number
      task_type: string
      prompt_text: string
    }
    // For Speaking
    speaking_data?: {
      audio_url: string
      audio_duration_seconds: number
      speaking_part_number: number
    }
    // Common
    time_spent_seconds?: number
    is_official_test?: boolean
  }): Promise<{ success: boolean }> => {
    const response = await apiClient.post<{ success: boolean }>(
      `/submissions/${submissionId}/submit`,
      data
    )
    return response.data
  },

  // Get submission result
  getSubmissionResult: async (submissionId: string): Promise<any> => {
    const response = await apiClient.get<{
      success: boolean
      data: any
    }>(`/submissions/${submissionId}/result`)
    return response.data.data
  },

  // Get user's submissions with filters
  getMySubmissions: async (filters?: SubmissionFilters, page = 1, limit = 20): Promise<{ submissions: import("@/types").SubmissionWithExercise[]; total: number }> => {
    const params = new URLSearchParams()
    params.append("page", page.toString())
    params.append("limit", limit.toString())
    
    if (filters?.search) {
      params.append("search", filters.search)
    }
    if (filters?.skill?.length) {
      params.append("skill_type", filters.skill.join(","))
    }
    if (filters?.status?.length) {
      params.append("status", filters.status.join(","))
    }
    if (filters?.sort_by) {
      params.append("sort_by", filters.sort_by)
    }
    if (filters?.sort_order) {
      params.append("sort_order", filters.sort_order)
    }
    if (filters?.date_from) {
      params.append("date_from", filters.date_from)
    }
    if (filters?.date_to) {
      params.append("date_to", filters.date_to)
    }
    
    const response = await apiClient.get<{
      success: boolean
      data: { submissions: import("@/types").SubmissionWithExercise[]; total: number }
    }>(`/submissions/my?${params.toString()}`)
    return response.data.data
  },
}
