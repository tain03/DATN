"use client"

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Trophy, Award, Star } from "lucide-react"
import { type Achievement } from "@/lib/api/achievements"
import { useTranslations } from "@/lib/i18n"
import { cn } from "@/lib/utils"

interface AchievementCardProps {
  achievement: Achievement
  earned: boolean
  earnedAt?: string
}

export function AchievementCard({ achievement, earned, earnedAt }: AchievementCardProps) {
  const t = useTranslations('achievements')

  const getBadgeColor = () => {
    if (achievement.badge_color) {
      return achievement.badge_color
    }
    // Default colors based on points
    if (achievement.points >= 100) return '#FFD700' // Gold
    if (achievement.points >= 50) return '#C0C0C0' // Silver
    if (achievement.points >= 20) return '#CD7F32' // Bronze
    return '#6B7280' // Gray
  }

  const formatCriteria = () => {
    const type = achievement.criteria_type
    const value = achievement.criteria_value
    
    // Debug in development
    if (process.env.NODE_ENV === 'development' && (!type || type === 'unknown')) {
      console.warn('[AchievementCard] Missing or invalid criteria_type:', {
        id: achievement.id,
        name: achievement.name,
        criteria_type: type,
        criteria_value: value,
        achievement: achievement
      })
    }
    
    // If no type, return default message
    if (!type || type === 'unknown') {
      return t('criteria_default', { type: 'unknown', value: value || 0 })
    }
    
    // Ensure value is a number
    const numValue = typeof value === 'number' ? value : parseInt(String(value || 0), 10)
    
    // Map criteria types to translation keys (case-insensitive)
    const typeLower = String(type).toLowerCase().trim()
    const criteriaMap: Record<string, string> = {
      // Exercise/Course completion
      'exercises_completed': 'criteria_complete_exercises',
      'courses_completed': 'criteria_complete_courses',
      'complete_exercises': 'criteria_complete_exercises',
      'complete_courses': 'criteria_complete_courses',
      'exercises': 'criteria_complete_exercises',
      'courses': 'criteria_complete_courses',
      'completion': 'criteria_completion', // Generic completion (lessons, exercises, etc.)
      // Study time
      'study_time': 'criteria_study_time',
      'time': 'criteria_study_time',
      // Streak
      'streak': 'criteria_streak',
      // Score
      'score': 'criteria_score',
    }
    
    const translationKey = criteriaMap[typeLower] || 'criteria_default'
    
    // Return translated string with value
    if (translationKey === 'criteria_default') {
      // For default, show type and value (human-readable)
      const typeLabel = type ? String(type).replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()) : 'Unknown'
      return t(translationKey, { type: typeLabel, value: numValue })
    }
    
    return t(translationKey, { value: numValue })
  }

  return (
    <Card className={cn(
      "relative overflow-hidden transition-all",
      earned ? "ring-2 ring-primary" : "opacity-75"
    )}>
      <div 
        className="absolute top-0 left-0 right-0 h-1"
        style={{ backgroundColor: earned ? getBadgeColor() : '#e5e7eb' }}
      />
      
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <CardTitle className="text-lg flex items-center gap-2">
              {earned ? (
                <Trophy className="h-5 w-5 text-yellow-500" />
              ) : (
                <Award className="h-5 w-5 text-muted-foreground" />
              )}
              {achievement.name}
            </CardTitle>
            {achievement.description && (
              <CardDescription className="mt-2">
                {achievement.description}
              </CardDescription>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <Badge variant="secondary" className="flex items-center gap-1">
              <Star className="h-3 w-3" />
              {achievement.points} {t('points')}
            </Badge>
            {earned && (
              <Badge variant="default">
                {t('earned')}
              </Badge>
            )}
          </div>

          <div className="text-sm">
            <p className="text-muted-foreground mb-1">
              <span className="font-medium">{t('criteria')}:</span> {formatCriteria()}
            </p>
            {earned && earnedAt && (
              <p className="text-muted-foreground text-xs mt-2">
                {t('earned_at')}: {new Date(earnedAt).toLocaleDateString()}
              </p>
            )}
          </div>

          {!earned && (
            <div className="pt-2 border-t">
              <p className="text-xs text-muted-foreground italic">
                {t('locked_continue_learning')}
              </p>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

