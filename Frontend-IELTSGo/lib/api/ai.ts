import { apiClient } from "./apiClient"
import type {
  WritingSubmissionRequest,
  WritingSubmissionResponse,
  WritingSubmission,
  WritingPrompt,
  WritingPromptsResponse,
  SpeakingSubmissionRequest,
  SpeakingSubmissionResponse,
  SpeakingSubmission,
  SpeakingPrompt,
  SpeakingPromptsResponse,
  CreateWritingPromptRequest,
  UpdateWritingPromptRequest,
  CreateSpeakingPromptRequest,
  UpdateSpeakingPromptRequest,
} from "@/types/ai"

export interface AIFilters {
  task_type?: "task1" | "task2"
  part_number?: 1 | 2 | 3
  difficulty?: "easy" | "medium" | "hard"
  is_published?: boolean
  limit?: number
  offset?: number
}

export const aiApi = {
  // ==================== Writing ====================

  /**
   * Submit writing for evaluation
   */
  submitWriting: async (data: WritingSubmissionRequest): Promise<WritingSubmissionResponse> => {
    const response = await apiClient.post<WritingSubmissionResponse>("/ai/writing/submit", data)
    return response.data
  },

  /**
   * Get user's writing submissions
   */
  getWritingSubmissions: async (limit = 10, offset = 0): Promise<WritingSubmissionsResponse> => {
    const response = await apiClient.get<{
      submissions: WritingSubmission[]
      total: number
    }>(`/ai/writing/submissions?limit=${limit}&offset=${offset}`)
    return {
      submissions: response.data.submissions || [],
      total: response.data.total || 0,
    }
  },

  /**
   * Get writing submission detail with evaluation
   */
  getWritingSubmission: async (id: string): Promise<WritingSubmissionResponse> => {
    const response = await apiClient.get<WritingSubmissionResponse>(`/ai/writing/submissions/${id}`)
    return response.data
  },

  /**
   * Get writing prompts list
   */
  getWritingPrompts: async (filters?: AIFilters): Promise<WritingPromptsResponse> => {
    const params = new URLSearchParams()
    
    if (filters?.task_type) params.append("task_type", filters.task_type)
    if (filters?.difficulty) params.append("difficulty", filters.difficulty)
    if (filters?.is_published !== undefined) params.append("is_published", String(filters.is_published))
    params.append("limit", String(filters?.limit || 20))
    params.append("offset", String(filters?.offset || 0))

    const response = await apiClient.get<{
      prompts: WritingPrompt[]
      total: number
    }>(`/ai/writing/prompts?${params.toString()}`)
    
    return {
      prompts: response.data.prompts || [],
      total: response.data.total || 0,
    }
  },

  /**
   * Get writing prompt detail
   */
  getWritingPrompt: async (id: string): Promise<WritingPrompt> => {
    const response = await apiClient.get<WritingPrompt>(`/ai/writing/prompts/${id}`)
    return response.data
  },

  // ==================== Speaking ====================

  /**
   * Submit speaking with audio file (multipart/form-data)
   */
  submitSpeaking: async (
    data: FormData
  ): Promise<SpeakingSubmissionResponse> => {
    const response = await apiClient.post<SpeakingSubmissionResponse>(
      "/ai/speaking/submit",
      data,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      }
    )
    return response.data
  },

  /**
   * Submit speaking with audio URL (JSON)
   */
  submitSpeakingWithURL: async (
    data: SpeakingSubmissionRequest
  ): Promise<SpeakingSubmissionResponse> => {
    const response = await apiClient.post<SpeakingSubmissionResponse>(
      "/ai/speaking/submit",
      data
    )
    return response.data
  },

  /**
   * Get user's speaking submissions
   */
  getSpeakingSubmissions: async (limit = 10, offset = 0): Promise<SpeakingSubmissionsResponse> => {
    const response = await apiClient.get<{
      submissions: SpeakingSubmission[]
      total: number
    }>(`/ai/speaking/submissions?limit=${limit}&offset=${offset}`)
    return {
      submissions: response.data.submissions || [],
      total: response.data.total || 0,
    }
  },

  /**
   * Get speaking submission detail with evaluation
   */
  getSpeakingSubmission: async (id: string): Promise<SpeakingSubmissionResponse> => {
    const response = await apiClient.get<SpeakingSubmissionResponse>(`/ai/speaking/submissions/${id}`)
    return response.data
  },

  /**
   * Get speaking prompts list
   */
  getSpeakingPrompts: async (filters?: AIFilters): Promise<SpeakingPromptsResponse> => {
    const params = new URLSearchParams()
    
    if (filters?.part_number) params.append("part_number", String(filters.part_number))
    if (filters?.difficulty) params.append("difficulty", filters.difficulty)
    if (filters?.is_published !== undefined) params.append("is_published", String(filters.is_published))
    params.append("limit", String(filters?.limit || 20))
    params.append("offset", String(filters?.offset || 0))

    const response = await apiClient.get<{
      prompts: SpeakingPrompt[]
      total: number
    }>(`/ai/speaking/prompts?${params.toString()}`)
    
    return {
      prompts: response.data.prompts || [],
      total: response.data.total || 0,
    }
  },

  /**
   * Get speaking prompt detail
   */
  getSpeakingPrompt: async (id: string): Promise<SpeakingPrompt> => {
    const response = await apiClient.get<SpeakingPrompt>(`/ai/speaking/prompts/${id}`)
    return response.data
  },

  // ==================== Admin - Writing Prompts ====================

  /**
   * Create writing prompt (admin only)
   */
  createWritingPrompt: async (data: CreateWritingPromptRequest): Promise<WritingPrompt> => {
    const response = await apiClient.post<WritingPrompt>("/admin/ai/writing/prompts", data)
    return response.data
  },

  /**
   * Update writing prompt (admin only)
   */
  updateWritingPrompt: async (
    id: string,
    data: UpdateWritingPromptRequest
  ): Promise<WritingPrompt> => {
    const response = await apiClient.put<WritingPrompt>(
      `/admin/ai/writing/prompts/${id}`,
      data
    )
    return response.data
  },

  /**
   * Delete writing prompt (admin only)
   */
  deleteWritingPrompt: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/ai/writing/prompts/${id}`)
  },

  // ==================== Admin - Speaking Prompts ====================

  /**
   * Create speaking prompt (admin only)
   */
  createSpeakingPrompt: async (data: CreateSpeakingPromptRequest): Promise<SpeakingPrompt> => {
    const response = await apiClient.post<SpeakingPrompt>("/admin/ai/speaking/prompts", data)
    return response.data
  },

  /**
   * Update speaking prompt (admin only)
   */
  updateSpeakingPrompt: async (
    id: string,
    data: UpdateSpeakingPromptRequest
  ): Promise<SpeakingPrompt> => {
    const response = await apiClient.put<SpeakingPrompt>(
      `/admin/ai/speaking/prompts/${id}`,
      data
    )
    return response.data
  },

  /**
   * Delete speaking prompt (admin only)
   */
  deleteSpeakingPrompt: async (id: string): Promise<void> => {
    await apiClient.delete(`/admin/ai/speaking/prompts/${id}`)
  },
}

