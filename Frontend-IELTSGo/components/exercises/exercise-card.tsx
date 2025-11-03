"use client"

import React from "react"
import { Clock, Target, TrendingUp, GraduationCap, Zap, BookOpen } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { VerticalCardLayout } from "@/components/cards/base-card-layout"
import type { Exercise } from "@/types"
import { useTranslations } from '@/lib/i18n'

interface ExerciseCardProps {
  exercise: Exercise
  showCourseLink?: boolean
}

function ExerciseCardComponent({ exercise, showCourseLink = true }: ExerciseCardProps) {
  const t = useTranslations('common')
  const tExercises = useTranslations('exercises')

  // Support both snake_case (backend) and camelCase (legacy)
  const skillType = exercise.skill_type || exercise.skillType || 'reading'
  const difficulty = exercise.difficulty || 'medium'
  const questionCount = exercise.total_questions || exercise.questionCount || 0
  const timeLimit = exercise.time_limit_minutes || exercise.timeLimit || 0
  const isFromCourse = !!(exercise.module_id && exercise.course_id)
  const averageScore = exercise.average_score
  const totalAttempts = exercise.total_attempts || 0
  
  // Skill and difficulty color mappings
  const skillColors: Record<string, string> = {
    listening: "bg-blue-500",
    reading: "bg-green-500",
    writing: "bg-orange-500",
    speaking: "bg-purple-500",
  }

  const levelColors: Record<string, string> = {
    easy: "bg-emerald-500",
    medium: "bg-yellow-500",
    hard: "bg-red-500",
    beginner: "bg-emerald-500",
    intermediate: "bg-yellow-500",
    advanced: "bg-red-500",
  }

  // Build image overlay with badges
  const imageOverlay = (
    <>
      <div className="absolute top-3 left-3 flex gap-2">
        <Badge 
          className={skillColors[skillType.toLowerCase()] || "bg-gray-500"}
          aria-label={t(skillType.toLowerCase() || 'reading')}
        >
          {t(skillType.toLowerCase() || 'reading').toUpperCase()}
        </Badge>
        <Badge 
          className={levelColors[difficulty.toLowerCase()] || levelColors.easy} 
          variant="secondary"
          aria-label={t(difficulty.toLowerCase() || 'medium')}
        >
          {t(difficulty.toLowerCase() || 'medium').toUpperCase()}
        </Badge>
      </div>
      <div className="absolute top-3 right-3">
        {isFromCourse ? (
          <Badge 
            variant="outline" 
            className="bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-950 dark:text-blue-300"
            aria-label={t('from_course') || 'From Course'}
          >
            <GraduationCap className="w-3 h-3 mr-1" aria-hidden="true" />
            {t('course') || 'Course'}
          </Badge>
        ) : (
          <Badge 
            variant="outline" 
            className="bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-950 dark:text-purple-300"
            aria-label={t('practice') || 'Practice'}
          >
            <Zap className="w-3 h-3 mr-1" aria-hidden="true" />
            {t('practice') || 'Practice'}
          </Badge>
        )}
      </div>
    </>
  )

  // Build content section with stats
  const contentSection = (
    <>
      {/* Questions and Time Limit */}
      <div 
        className="flex items-center gap-4 text-sm text-muted-foreground" 
        role="group" 
        aria-label={t('exercise_details') || 'Exercise details'}
      >
        {questionCount > 0 && (
          <div className="flex items-center gap-1">
            <Target className="w-4 h-4 text-blue-600" aria-hidden="true" />
            <span>
              {questionCount} {t('questions')}
            </span>
          </div>
        )}
        {timeLimit > 0 && (
          <div className="flex items-center gap-1">
            <Clock className="w-4 h-4 text-muted-foreground" aria-hidden="true" />
            <span>
              {timeLimit} {t('minutes')}
            </span>
          </div>
        )}
      </div>

      {/* Average Score */}
      {averageScore && totalAttempts > 0 && (
        <div 
          className="flex items-center gap-1 mt-3 text-sm text-muted-foreground"
          aria-label={t('average_score') || 'Average score'}
        >
          <TrendingUp className="w-4 h-4 text-green-600" aria-hidden="true" />
          <span>
            {Math.round(averageScore)}% {t('avg_score') || 'avg score'}
          </span>
        </div>
      )}
    </>
  )

  return (
    <VerticalCardLayout
      variant="interactive"
      image={{
        src: exercise.thumbnail_url || undefined,
        alt: exercise.title,
        overlay: imageOverlay,
        placeholder: {
          icon: BookOpen,
        }
      }}
      title={exercise.title}
      titleHref={`/exercises/${exercise.id}`}
      description={exercise.description || null}
      content={contentSection}
      footer={{
        action: t('start_practice'),
        href: `/exercises/${exercise.id}`,
      }}
      onClick={() => {
        // Optional: Allow clicking entire card to navigate
        if (typeof window !== 'undefined') {
          window.location.href = `/exercises/${exercise.id}`
        }
      }}
    />
  )
}

export const ExerciseCard = React.memo(ExerciseCardComponent)
