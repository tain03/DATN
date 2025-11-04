"use client"

import React from "react"
import { Clock, Target, TrendingUp, GraduationCap, Zap, BookOpen } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { VerticalCardLayout } from "@/components/cards/base-card-layout"
import type { Exercise } from "@/types"
import { useTranslations } from '@/lib/i18n'
import { cn } from "@/lib/utils"

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
  // For Writing/Speaking, total_questions might be 0 or null (they don't have questions)
  // Use null instead of 0 to distinguish "not set" from "actually 0"
  const questionCount = exercise.total_questions ?? exercise.questionCount ?? null
  const timeLimit = exercise.time_limit_minutes || exercise.timeLimit || 0
  const isFromCourse = !!(exercise.module_id && exercise.course_id)
  const averageScore = exercise.average_score // Percentage (0-100)
  const totalAttempts = exercise.total_attempts || 0
  const ieltsTestType = exercise.ielts_test_type // academic or general_training (only for Reading)
  
  // Skill and difficulty color mappings (matching Course Card)
  const skillColors: Record<string, string> = {
    listening: "bg-blue-500",
    reading: "bg-green-500",
    writing: "bg-orange-500",
    speaking: "bg-purple-500",
    general: "bg-gray-500",
  }

  const levelColors: Record<string, string> = {
    beginner: "bg-emerald-500",
    intermediate: "bg-yellow-500",
    advanced: "bg-red-500",
    easy: "bg-emerald-500", // Map easy to beginner color
    medium: "bg-yellow-500", // Map medium to intermediate color
    hard: "bg-red-500", // Map hard to advanced color
  }

  // Build image overlay with badges (matching Course Card style)
  const imageOverlay = (
    <>
      <div className="absolute top-3 left-3 flex gap-2 z-20 flex-wrap">
        <Badge 
          className={cn(skillColors[skillType.toLowerCase()] || skillColors.general || "bg-gray-500")}
          aria-label={t(skillType.toLowerCase() || 'reading')}
        >
          {t(skillType.toLowerCase() || 'reading').toUpperCase()}
        </Badge>
        <Badge 
          className={cn(levelColors[difficulty.toLowerCase()] || levelColors.beginner)} 
          variant="secondary"
          aria-label={t(difficulty.toLowerCase() || 'medium')}
        >
          {t(difficulty.toLowerCase() || 'medium').toUpperCase()}
        </Badge>
        {/* Show test type badge for Reading exercises */}
        {skillType.toLowerCase() === 'reading' && ieltsTestType && (
          <Badge 
            className="bg-indigo-500 text-white"
            variant="secondary"
            aria-label={t(ieltsTestType) || ieltsTestType}
          >
            {ieltsTestType === 'academic' 
              ? t('academic') || 'Academic'
              : t('general_training') || 'General Training'}
          </Badge>
        )}
      </div>
      <div className="absolute top-3 right-3 z-20">
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

  // Build content section with stats (matching Course Card style)
  const contentSection = (
    <>
      {/* Questions and Time Limit */}
      {/* Only render container if there's something to show (avoid rendering empty div that might show "0") */}
      {((questionCount !== null && questionCount > 0) || timeLimit > 0) && (
        <div 
          className="flex items-center gap-4 text-sm text-muted-foreground" 
          role="group" 
          aria-label={t('exercise_details') || 'Exercise details'}
        >
          {questionCount !== null && questionCount > 0 && (
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
      )}

      {/* Average Score */}
      {/* Only show if averageScore exists, is > 0, and there are attempts */}
      {averageScore !== null && averageScore !== undefined && averageScore > 0 && totalAttempts > 0 && (
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
