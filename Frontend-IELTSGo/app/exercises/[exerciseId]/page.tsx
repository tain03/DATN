"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter, useSearchParams } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Clock, BookOpen, FileText, PlayCircle, Award, Target, CheckCircle, ChevronLeft, Loader2 } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"
import { exercisesApi } from "@/lib/api/exercises"
import type { ExerciseDetailResponse } from "@/types"
import { useAuth } from "@/lib/contexts/auth-context"
import { useTranslations } from "@/lib/i18n"

export default function ExerciseDetailPage() {
  const params = useParams()
  const router = useRouter()
  const searchParams = useSearchParams()
  const { user } = useAuth()
  const toast = useToastWithI18n()
  const t = useTranslations('exercises')
  const tCommon = useTranslations('common')

  const exerciseId = params.exerciseId as string

  // Get lesson context from URL params (optional, fallback to API data)
  const lessonId = searchParams.get('lessonId')

  const [exerciseData, setExerciseData] = useState<ExerciseDetailResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [starting, setStarting] = useState(false)

  useEffect(() => {
    const fetchExercise = async () => {
      try {
        setLoading(true)
        const data = await exercisesApi.getExerciseById(exerciseId)
        setExerciseData(data)
      } catch (error) {
        console.error('[Exercise Detail] Failed to load:', error)
      } finally {
        setLoading(false)
      }
    }

    if (exerciseId) {
      fetchExercise()
    }
  }, [exerciseId])

  const handleStartExercise = async () => {
    if (!user) {
      router.push('/login')
      return
    }

    try {
      setStarting(true)

      const submission = await exercisesApi.startExercise(exerciseId)

      router.push(`/exercises/${exerciseId}/take/${submission.id}`)
    } catch (error: any) {
      console.error('[Exercise Detail] Failed to start:', error)

      // Better error messages
      if (error.response?.status === 401) {
        toast.error(t('session_expired_please_login_again'))
        router.push('/login')
      } else if (error.response?.status === 404) {
        toast.error(t('exercise_not_found'))
      } else {
        const errorMsg = error.response?.data?.error?.message || error.message || t('cannot_start_exercise_please_try_again')
        toast.error(errorMsg)
      }
    } finally {
      setStarting(false)
    }
  }

  if (loading) {
    return (
      <AppLayout>
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  if (!exerciseData) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={FileText}
            title={t('exercise_not_found')}
            description={t('exercise_not_found_description') || "This exercise may have been removed or does not exist"}
            action={{
              label: tCommon('go_back') || "Go Back",
              onClick: () => router.back()
            }}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  const { exercise, sections } = exerciseData
  // Backend returns sections as array of {section, questions}
  const totalQuestions = sections?.reduce((sum, sectionData) => {
    return sum + (sectionData.section?.total_questions || 0)
  }, 0) || 0

  const getSkillLabel = (skillType: string) => {
    const skillMap: Record<string, string> = {
      listening: '🎧 Listening',
      reading: '📖 Reading',
      writing: '✍️ Writing',
      speaking: '🗣️ Speaking'
    }
    return skillMap[skillType] || skillType
  }

  return (
    <AppLayout>
      <PageContainer maxWidth="6xl">
        {/* Back to Lesson Button - Only show if exercise is linked to a lesson */}
        {exercise.lesson_id && (
          <Button
            variant="ghost"
            onClick={() => router.push(`/lessons/${lessonId || exercise.lesson_id}`)}
            className="mb-4"
          >
            <ChevronLeft className="h-4 w-4 mr-2" />
            {t('back_to_lessons')}
          </Button>
        )}

        <div className="mb-8">
          <div className="flex items-center gap-2 mb-3 flex-wrap">
            <Badge className="capitalize">
              {getSkillLabel(exercise.skill_type)}
            </Badge>
            <Badge variant="outline" className="capitalize">{exercise.difficulty_level}</Badge>
            {/* Show test type badge for Reading exercises */}
            {exercise.skill_type?.toLowerCase() === 'reading' && exercise.ielts_test_type && (
              <Badge variant="outline" className="bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-950 dark:text-indigo-300">
                {exercise.ielts_test_type === 'academic' 
                  ? tCommon('academic') 
                  : tCommon('general_training')}
              </Badge>
            )}
            {exercise.is_official && (
              <Badge variant="secondary">
                <Award className="w-3 h-3 mr-1" />
                Official
              </Badge>
            )}
          </div>

          <h1 className="text-3xl font-bold tracking-tight mb-2">{exercise.title}</h1>
          {exercise.description && (
            <p className="text-base text-muted-foreground">{exercise.description}</p>
          )}
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>{t('exercise_information')}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex items-center gap-3">
                    <Clock className="w-5 h-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">{t('time_limit')}</p>
                      <p className="font-medium">
                        {exercise.time_limit_minutes ? `${exercise.time_limit_minutes} ${t('minutes')}` : t('no_time_limit')}
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <FileText className="w-5 h-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">{t('number_of_questions')}</p>
                      <p className="font-medium">{totalQuestions} {t('questions')}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <Target className="w-5 h-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">{t('maximum_score')}</p>
                      <p className="font-medium">
                        {exercise.total_points || exercise.max_score || totalQuestions} {t('points')}
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <BookOpen className="w-5 h-5 text-muted-foreground" />
                    <div>
                      <p className="text-sm text-muted-foreground">{t('number_of_sections')}</p>
                      <p className="font-medium">{sections.length} {t('sections')}</p>
                    </div>
                  </div>
                </div>

                {exercise.instructions && (
                  <>
                    <Separator />
                    <div>
                      <h4 className="font-semibold mb-2">{t('instructions')}</h4>
                      <div 
                        className="prose prose-sm max-w-none text-muted-foreground"
                        dangerouslySetInnerHTML={{ __html: exercise.instructions }}
                      />
                    </div>
                  </>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>{t('exercise_structure')}</CardTitle>
                <CardDescription>
                  {t('sections_with_total_questions', { sections: sections.length.toString(), total: totalQuestions.toString() })}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {sections && sections.length > 0 ? (
                    sections.map((sectionData, index) => {
                      const section = sectionData.section
                      const questionCount = sectionData.questions?.length || section?.total_questions || 0
                      return (
                        <div
                          key={section?.id || `section-${index}`}
                          className="flex items-center justify-between p-4 rounded-lg border hover:bg-muted/50 transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                              <span className="text-sm font-semibold text-primary">
                                {index + 1}
                              </span>
                            </div>
                            <div>
                              <h4 className="font-medium">{section?.title}</h4>
                              {section?.description && (
                                <p className="text-sm text-muted-foreground">{section.description}</p>
                              )}
                            </div>
                          </div>
                          <div className="flex items-center gap-4 text-sm text-muted-foreground">
                            <span>{questionCount} {t('questions')}</span>
                          </div>
                        </div>
                      )
                    })
                  ) : (
                    <p className="text-sm text-muted-foreground text-center py-4">
                      {t('no_sections_yet')}
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>{t('important_notes')}</CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 mt-0.5 text-green-500" />
                    <span>{t('read_instructions_carefully')}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 mt-0.5 text-green-500" />
                    <span>{t('manage_time_effectively')}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 mt-0.5 text-green-500" />
                    <span>{t('review_answers_before_submit')}</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 mt-0.5 text-green-500" />
                    <span>{t('save_draft_and_continue')}</span>
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>

          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>{t('start_exercise')}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Button 
                  onClick={handleStartExercise} 
                  disabled={starting}
                  className="w-full"
                  size="lg"
                >
                  {starting ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      {t('preparing')}
                    </>
                  ) : (
                    <>
                      <PlayCircle className="w-4 h-4 mr-2" />
                      {t('start_exercise')}
                    </>
                  )}
                </Button>
                
                <div className="text-xs text-muted-foreground space-y-1">
                  <p>• {t('time_limit')}: {exercise.time_limit_minutes ? `${exercise.time_limit_minutes} ${t('minutes')}` : t('no_time_limit')}</p>
                  <p>• {t('number_of_questions')}: {totalQuestions} {t('questions')}</p>
                  <p>• {t('can_retry_multiple_times')}</p>
                </div>
              </CardContent>
            </Card>

            {(exercise.total_attempts || exercise.average_score) && (
              <Card>
                <CardHeader>
                  <CardTitle>{t('statistics')}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {exercise.total_attempts !== null && exercise.total_attempts !== undefined && (
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">{t('total_attempts_count')}</span>
                      <span className="font-semibold">{exercise.total_attempts}</span>
                    </div>
                  )}

                  {exercise.average_score !== null && exercise.average_score !== undefined && (
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-muted-foreground">{t('average_score')}</span>
                      <span className="font-semibold text-primary">
                        {exercise.average_score.toFixed(1)}% {/* average_score is percentage (0-100) */}
                      </span>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}

            <Card>
              <CardHeader>
                <CardTitle>{t('exercise_details')}</CardTitle>
              </CardHeader>
              <CardContent className="text-sm space-y-2">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{t('skill_type_label')}</span>
                  <span className="font-medium">{exercise.skill_type}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{t('difficulty_level_label')}</span>
                  <span className="font-medium">{exercise.difficulty_level}</span>
                </div>
                {exercise.target_band_score && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">{t('band_score_label')}</span>
                    <span className="font-medium">{exercise.target_band_score}</span>
                  </div>
                )}
                {/* Show test type for Reading exercises */}
                {exercise.skill_type?.toLowerCase() === 'reading' && exercise.ielts_test_type && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">{tCommon('test_type')}</span>
                    <Badge variant="outline" className="capitalize">
                      {exercise.ielts_test_type === 'academic' 
                        ? tCommon('academic') 
                        : tCommon('general_training')}
                    </Badge>
                  </div>
                )}
                <div className="flex justify-between">
                  <span className="text-muted-foreground">{t('status_label')}</span>
                  <Badge variant={exercise.is_published ? "default" : "secondary"}>
                    {exercise.is_published ? t('published') : t('draft')}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </PageContainer>
    </AppLayout>
  )
}
