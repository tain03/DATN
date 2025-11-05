import { apiClient } from "./apiClient"

interface ApiResponse<T> {
  success: boolean
  message?: string
  data: T
  error?: {
    code: string
    message: string
  }
}

export interface StudyGoal {
  id: string
  user_id: string
  goal_type: "daily" | "weekly" | "monthly" | "custom"
  title: string
  description?: string
  target_value: number
  target_unit: string // minutes, lessons, exercises, score
  current_value: number
  skill_type?: string
  start_date: string
  end_date: string
  status: "active" | "completed" | "cancelled" | "expired" // Match DB schema
  reminder_enabled: boolean
  created_at: string
  updated_at: string
  completed_at?: string
  // Enriched fields
  completion_percentage?: number
  days_remaining?: number
  status_message?: string
}

export interface CreateGoalRequest {
  goal_type: "daily" | "weekly" | "monthly" | "custom"
  title: string
  description?: string
  target_value: number
  target_unit: string
  skill_type?: string
  end_date: string // YYYY-MM-DD - start_date will be auto-set by backend
}

export interface UpdateGoalRequest {
  title?: string
  description?: string
  target_value?: number
  current_value?: number
  end_date?: string
}

export interface GoalsResponse {
  goals: StudyGoal[]
  count: number
}

export const goalsApi = {
  // Create a new study goal
  createGoal: async (goal: CreateGoalRequest): Promise<StudyGoal> => {
    const response = await apiClient.post<ApiResponse<StudyGoal>>("/user/goals", goal)
    return response.data.data
  },

  // Get all user goals
  getGoals: async (): Promise<GoalsResponse> => {
    const response = await apiClient.get<ApiResponse<GoalsResponse>>("/user/goals")
    const data = response.data.data
    
    // Handle both {goals, count} and array response
    if (Array.isArray(data)) {
      return { goals: data, count: data.length }
    }
    return data
  },

  // Get goal by ID
  getGoalById: async (goalId: string): Promise<StudyGoal> => {
    const response = await apiClient.get<ApiResponse<StudyGoal>>(`/user/goals/${goalId}`)
    return response.data.data
  },

  // Update goal
  updateGoal: async (goalId: string, updates: UpdateGoalRequest): Promise<StudyGoal> => {
    const response = await apiClient.put<ApiResponse<StudyGoal>>(`/user/goals/${goalId}`, updates)
    return response.data.data
  },

  // Complete goal
  completeGoal: async (goalId: string): Promise<StudyGoal> => {
    const response = await apiClient.post<ApiResponse<StudyGoal>>(`/user/goals/${goalId}/complete`, {})
    return response.data.data
  },

  // Delete goal
  deleteGoal: async (goalId: string): Promise<void> => {
    await apiClient.delete<ApiResponse<void>>(`/user/goals/${goalId}`)
  },
}

