import { apiClient } from "./apiClient"
import type { PaginatedResponse, SkillType } from "./types"
import { apiCache, cachedFetch } from "@/lib/utils/api-cache"

interface ApiResponse<T> {
  success: boolean
  message?: string
  data: T
}

export const progressApi = {
  // Get user's overall progress summary
  // Uses: GET /api/v1/user/progress (User Service)
  getProgressSummary: async () => {
    const cacheKey = apiCache.generateKey('/user/progress')
    
    // Check cache first
    const cached = apiCache.get(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{
      profile: any
      progress: {
        user_id: string
        total_study_hours: number
        total_lessons_completed: number
        total_exercises_completed: number
        listening_progress: number
        reading_progress: number
        writing_progress: number
        speaking_progress: number
        listening_score?: number
        reading_score?: number
        writing_score?: number
        speaking_score?: number
        overall_score?: number
        current_streak_days: number
        longest_streak_days: number
        last_study_date?: string
      }
      recent_sessions: any[]
      achievements: any[]
      total_points: number
    }>>("/user/progress")

    // Transform to match frontend expectations
    const data = response.data.data.progress
    const result = {
      totalCourses: 0, // Not available in current backend
      completedCourses: 0, // Not available in current backend
      inProgressCourses: 0, // Not available in current backend
      totalExercises: data.total_exercises_completed,
      completedExercises: data.total_exercises_completed,
      totalStudyTime: Math.round(data.total_study_hours * 60), // Convert hours to minutes
      currentStreak: data.current_streak_days,
      longestStreak: data.longest_streak_days,
      averageScore: data.overall_score || 0,
      skillScores: {
        listening: data.listening_score || 0,
        reading: data.reading_score || 0,
        writing: data.writing_score || 0,
        speaking: data.speaking_score || 0,
      }
    }
    
    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get detailed progress analytics
  // Uses: GET /api/v1/user/progress/history (User Service)
  getProgressAnalytics: async (timeRange: "7d" | "30d" | "90d" | "all" = "30d") => {
    const cacheKey = apiCache.generateKey('/user/progress/history', { timeRange })
    
    // Check cache first
    const cached = apiCache.get(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{
      count: number
      sessions: Array<{
        id: string
        session_type: string
        resource_id: string
        skill_type?: string
        duration_minutes: number
        score?: number
        created_at: string
      }>
    }>>(`/user/progress/history?page=1&page_size=100`)

    const history = response.data.data.sessions || []

    // Transform to analytics format
    const studyTimeByDay: { [key: string]: number } = {}
    const scoresBySkill: { [key: string]: number[] } = {
      listening: [],
      reading: [],
      writing: [],
      speaking: []
    }
    const completionByDay: { [key: string]: { completed: number, total: number } } = {}
    const exercisesBySkillType: { [key: string]: { count: number, scores: number[] } } = {}

    history.forEach(item => {
      const date = item.created_at.split('T')[0]
      
      // Study time by day
      studyTimeByDay[date] = (studyTimeByDay[date] || 0) + item.duration_minutes

      // Completion tracking (lesson sessions)
      if (item.session_type === 'lesson') {
        if (!completionByDay[date]) {
          completionByDay[date] = { completed: 0, total: 0 }
        }
        completionByDay[date].total++
        if (item.duration_minutes >= 1) {
          completionByDay[date].completed++
        }
      }

      // Exercise breakdown by skill type
      if (item.session_type === 'exercise' && item.skill_type) {
        if (!exercisesBySkillType[item.skill_type]) {
          exercisesBySkillType[item.skill_type] = { count: 0, scores: [] }
        }
        exercisesBySkillType[item.skill_type].count++
        if (item.score !== undefined && item.score !== null) {
          exercisesBySkillType[item.skill_type].scores.push(item.score)
        }
      }

      // Scores by skill
      if (item.skill_type && item.score) {
        scoresBySkill[item.skill_type]?.push(item.score)
      }
    })

    const result = {
      studyTimeByDay: Object.entries(studyTimeByDay).map(([date, minutes]) => ({ date, value: minutes })),
      scoresBySkill: Object.entries(scoresBySkill).map(([skill, scores]) => ({ skill, scores })),
      completionRate: Object.entries(completionByDay).map(([date, stats]) => ({ 
        date, 
        value: stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0 
      })),
      exercisesByType: Object.entries(exercisesBySkillType).map(([type, data]) => ({
        type: type.charAt(0).toUpperCase() + type.slice(1),
        count: data.count,
        avgScore: data.scores.length > 0 
          ? data.scores.reduce((sum, score) => sum + score, 0) / data.scores.length 
          : 0
      }))
    }

    // Cache for 30 seconds
    apiCache.set(cacheKey, result, 30000)
    return result
  },

  // Get study history/activity log
  // Uses: GET /api/v1/user/progress/history (User Service)
  getStudyHistory: async (page = 1, pageSize = 20) => {
    const cacheKey = apiCache.generateKey('/user/progress/history', { page, pageSize })
    
    // Check cache first (shorter TTL for activity log - 15 seconds)
    const cached = apiCache.get(cacheKey)
    if (cached) {
      return cached
    }

    const response = await apiClient.get<ApiResponse<{
      sessions: Array<{
        id: string
        session_type: string
        resource_id: string
        skill_type?: string
        duration_minutes: number
        score?: number
        created_at: string
      }>
      pagination: { page: number; limit: number; total: number; total_pages: number }
    }>>(`/user/progress/history?page=${page}&limit=${pageSize}`)

    const historyData = response.data.data
    const pagination = historyData.pagination || { page, limit: pageSize, total: 0, total_pages: 0 }

    const result = {
      data: historyData.sessions.map(item => ({
        id: item.id,
        type: item.session_type as "course" | "exercise" | "lesson",
        title: item.resource_id 
          ? `${item.session_type} - ${item.resource_id.substring(0, 8)}`
          : `${item.session_type} - ${item.id.substring(0, 8)}`,
        completedAt: item.created_at,
        duration: item.duration_minutes,
        score: item.score,
        skillType: item.skill_type as SkillType | undefined
      })),
      total: pagination.total || 0,
      page: pagination.page || page,
      pageSize: pagination.limit || pageSize,
      totalPages: pagination.total_pages || 0,
    }

    // Cache for 15 seconds (shorter for activity log)
    apiCache.set(cacheKey, result, 15000)
    return result
  },

  // Get course progress details
  // Note: This endpoint doesn't exist in backend yet
  // Using enrollment progress as fallback
  getCourseProgress: async (courseId: string) => {
    // This would need to be implemented in backend
    // For now, return mock data
    // getCourseProgress not implemented in backend
    return {
      courseId,
      progress: 0,
      completedLessons: 0,
      totalLessons: 0,
      lastAccessedAt: new Date().toISOString(),
      timeSpent: 0,
      lessonProgress: []
    }
  },

  // Update lesson progress - DEPRECATED
  // Use coursesApi.updateLessonProgress instead
  updateLessonProgress: async (lessonId: string, progress: number) => {
    // Use coursesApi.updateLessonProgress instead
    const response = await apiClient.put(`/progress/lessons/${lessonId}`, {
      progress_percentage: progress,
    })
    return response.data
  },

  // Mark lesson as completed - DEPRECATED
  // Use coursesApi.completeLesson instead
  completeLesson: async (lessonId: string) => {
    // Use coursesApi.completeLesson instead
    const response = await apiClient.put(`/progress/lessons/${lessonId}`, {
      is_completed: true,
    })
    return response.data
  },

  // Get skill-specific progress
  // Uses: GET /api/v1/user/statistics/:skill (User Service)
  getSkillProgress: async (skill: SkillType) => {
    const response = await apiClient.get<ApiResponse<{
      skill_type: string
      total_practices: number
      total_time_minutes: number
      average_score?: number
      best_score?: number
      recent_scores: Array<{
        score: number
        created_at: string
      }>
      strengths: string[]
      weaknesses: string[]
    }>>(`/user/statistics/${skill}`)

    const data = response.data.data

    return {
      skill: skill,
      level: data.average_score ? (data.average_score >= 7 ? 'Advanced' : data.average_score >= 5 ? 'Intermediate' : 'Beginner') : 'Beginner',
      currentScore: data.average_score || 0,
      targetScore: 7.0, // Default target, should come from user profile
      exercisesCompleted: data.total_practices,
      averageScore: data.average_score || 0,
      recentScores: data.recent_scores.map(s => ({
        date: s.created_at,
        score: s.score
      })),
      strengths: data.strengths || [],
      weaknesses: data.weaknesses || []
    }
  },
}
