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

export interface Achievement {
  id: number
  code: string
  name: string
  description?: string
  criteria_type: string
  criteria_value: number
  icon_url?: string
  badge_color?: string
  points: number
  created_at: string
}

// Backend returns AchievementWithProgress structure
export interface AchievementWithProgress {
  achievement: Achievement
  is_earned: boolean
  earned_at?: string
  progress: number
  progress_percentage: number
}

export interface UserAchievement {
  id: number
  user_id: string
  achievement: Achievement
  earned_at: string
  // Or flat structure
  achievement_id?: number
  achievement_name?: string
  achievement_description?: string
  earned_at_flat?: string
}

export interface AchievementsResponse {
  achievements?: Achievement[]
  count?: number
}

export const achievementsApi = {
  // Get all available achievements
  getAllAchievements: async (): Promise<Achievement[]> => {
    const response = await apiClient.get<ApiResponse<AchievementsResponse | AchievementWithProgress[]>>("/user/achievements")
    const data = response.data.data
    
    // Backend returns {achievements: AchievementWithProgress[], count: number}
    if (data && typeof data === 'object' && 'achievements' in data) {
      const achievementsWithProgress = (data as AchievementsResponse).achievements as AchievementWithProgress[]
      // Flatten: extract achievement from AchievementWithProgress
      return achievementsWithProgress.map(item => 
        'achievement' in item ? item.achievement : item as unknown as Achievement
      )
    }
    
    // Handle array response (if backend returns array directly)
    if (Array.isArray(data)) {
      return data.map(item => 
        'achievement' in item ? item.achievement : item as unknown as Achievement
      )
    }
    
    return []
  },

  // Get earned achievements
  getEarnedAchievements: async (): Promise<UserAchievement[]> => {
    const response = await apiClient.get<ApiResponse<UserAchievement[] | AchievementsResponse>>("/user/achievements/earned")
    const data = response.data.data
    
    // Handle different response structures
    if (Array.isArray(data)) {
      return data
    }
    
    // Handle {achievements: [], count: number}
    if (data && typeof data === 'object' && 'achievements' in data) {
      return (data as AchievementsResponse).achievements as UserAchievement[] || []
    }
    
    return []
  },
}

