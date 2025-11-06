import { apiClient } from "./apiClient"
import type { SkillType } from "@/types"
import { apiCache } from "@/lib/utils/api-cache"

/**
 * NEW SCORING SYSTEM (November 2025)
 * 
 * The platform now separates:
 * 1. OFFICIAL TEST RESULTS - Real IELTS band scores (0-9) from full tests
 *    - Source of truth for user's actual band scores
 *    - Updates learning_progress.{skill}_score fields
 *    - Displayed as "Band Score"
 * 
 * 2. PRACTICE ACTIVITIES - Training exercises with accuracy (%)
 *    - Drills, part tests, section practices
 *    - Tracked separately, don't affect official band scores
 *    - Displayed as "Practice Accuracy"
 * 
 * API Endpoints:
 * - /user/progress - Returns overall progress with official band scores
 * - /user/test-results - Official test history
 * - /user/practice-activities - Practice exercise history
 * - /user/practice-statistics - Aggregated practice stats
 */

interface ApiResponse<T> {
  success: boolean
  message?: string
  data: T
}

const normalizeScore = (score?: number | null): number => {
  if (score === undefined || score === null) {
    return 0
  }

  const numeric = Number(score)
  if (!Number.isFinite(numeric)) {
    return 0
  }

  const normalized = numeric > 9 ? (numeric / 100) * 9 : numeric
  return Math.max(0, Math.min(9, normalized))
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
        // New scoring system - these come from official_test_results
        listening_score?: number
        reading_score?: number
        writing_score?: number
        speaking_score?: number
        overall_score?: number
        // Test counts
        listening_tests_taken?: number
        reading_tests_taken?: number
        writing_tests_taken?: number
        speaking_tests_taken?: number
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
      // Overall score now comes from official test results average
      averageScore: normalizeScore(data.overall_score),
      // Skill scores come from latest official test results
      skillScores: {
        listening: normalizeScore(data.listening_score),
        reading: normalizeScore(data.reading_score),
        writing: normalizeScore(data.writing_score),
        speaking: normalizeScore(data.speaking_score),
      },
      // Track test counts
      testsTaken: {
        listening: data.listening_tests_taken || 0,
        reading: data.reading_tests_taken || 0,
        writing: data.writing_tests_taken || 0,
        speaking: data.speaking_tests_taken || 0,
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
      const hasScore = item.score !== undefined && item.score !== null
      const normalizedScore = hasScore ? normalizeScore(item.score) : null
      
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
        if (normalizedScore !== null) {
          exercisesBySkillType[item.skill_type].scores.push(normalizedScore)
        }
      }

      // Scores by skill
      if (item.skill_type && normalizedScore !== null) {
        scoresBySkill[item.skill_type]?.push(normalizedScore)
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
  score: normalizeScore(item.score),
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
    const averageScore = normalizeScore(data.average_score)
    const bestScore = normalizeScore(data.best_score)

    return {
      skill: skill,
      level: averageScore >= 7 ? 'Advanced' : averageScore >= 5 ? 'Intermediate' : 'Beginner',
      currentScore: averageScore,
      targetScore: 7.0, // Default target, should come from user profile
      exercisesCompleted: data.total_practices,
      averageScore,
      bestScore,
      recentScores: data.recent_scores.map(s => ({
        date: s.created_at,
        score: normalizeScore(s.score)
      })),
      strengths: data.strengths || [],
      weaknesses: data.weaknesses || []
    }
  },

  // ============= NEW SCORING SYSTEM ENDPOINTS =============

  // Get user's official test results history
  // Uses: GET /api/v1/user/test-results (User Service)
  getTestResults: async (skillType?: SkillType, page = 1, limit = 20) => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString()
    })
    if (skillType) {
      params.append('skill', skillType)
    }

    const response = await apiClient.get<ApiResponse<{
      results: Array<{
        id: string
        user_id: string
        test_type: string
        skill_type: string
        raw_score?: number
        total_questions?: number
        band_score: number
        time_spent_minutes?: number
        test_date: string
        test_source?: string
        created_at: string
      }>
      pagination: {
        page: number
        limit: number
        total: number
        total_pages: number
      }
    }>>(`/user/test-results?${params}`)

    return {
      results: response.data.data.results,
      pagination: response.data.data.pagination
    }
  },

  // Get user's practice activities
  // Uses: GET /api/v1/user/practice-activities (User Service)
  getPracticeActivities: async (skillType?: SkillType, page = 1, limit = 20) => {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString()
    })
    if (skillType) {
      params.append('skill', skillType)
    }

    const response = await apiClient.get<ApiResponse<{
      activities: Array<{
        id: string
        user_id: string
        skill: string
        activity_type: string
        exercise_id?: string
        exercise_title?: string
        score?: number
        band_score?: number
        correct_answers: number
        total_questions?: number
        accuracy_percentage?: number
        time_spent_seconds?: number
        completed_at?: string
        created_at: string
      }>
      pagination: {
        page: number
        limit: number
        total: number
        total_pages: number
      }
    }>>(`/user/practice-activities?${params}`)

    return {
      activities: response.data.data.activities,
      pagination: response.data.data.pagination
    }
  },

  // Get practice statistics
  // Uses: GET /api/v1/user/practice-statistics (User Service)
  getPracticeStatistics: async (skillType?: SkillType) => {
    const params = skillType ? `?skill=${skillType}` : ''
    const response = await apiClient.get<ApiResponse<{
      total_activities: number
      total_time_spent_seconds: number
      average_accuracy?: number
      best_accuracy?: number
      activities_by_type: Array<{
        activity_type: string
        count: number
        average_accuracy?: number
      }>
      recent_activities: Array<{
        id: string
        skill: string
        activity_type: string
        accuracy_percentage?: number
        completed_at: string
      }>
    }>>(`/user/practice-statistics${params}`)

    return response.data.data
  },
}
