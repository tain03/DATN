"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { CheckCircle2, XCircle, Clock, Target, TrendingUp, Home, RotateCcw } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { exercisesApi } from "@/lib/api/exercises"
import type { SubmissionResult } from "@/types"
import { usePreferences } from "@/lib/contexts/preferences-context"
import { useTranslations } from '@/lib/i18n'

export default function ExerciseResultPage() {

  const t = useTranslations('exercises')

  const params = useParams()
  const router = useRouter()
  const { preferences } = usePreferences()
  const showExplanations = preferences?.show_answer_explanation ?? true // Default to true for backward compatibility
  const exerciseId = params.exerciseId as string
  const submissionId = params.submissionId as string

  const [result, setResult] = useState<SubmissionResult | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchResult = async () => {
      try {
        const data = await exercisesApi.getSubmissionResult(submissionId)
        setResult(data)
      } catch (error) {
        console.error("Failed to fetch result:", error)
      } finally {
        setLoading(false)
      }
    }
    fetchResult()
  }, [submissionId])

  if (loading) {
    return (
      <AppLayout>
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  if (!result) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={<Target className="h-12 w-12 text-muted-foreground" />}
            title={t('results_not_found')}
            description={t('results_not_found_description') || "Không tìm thấy kết quả bài tập"}
            action={{
              label: t('back_to_exercises') || "Quay lại bài tập",
              onClick: () => router.push("/exercises/list")
            }}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  const { submission, exercise, answers, performance } = result
  const isPassed = performance.is_passed

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${minutes}m ${secs}s`
  }

  return (
    <AppLayout>
      <PageContainer maxWidth="4xl">
        {/* Result Header */}
        <Card className="mb-8">
          <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
              {isPassed ? (
                <CheckCircle2 className="w-16 h-16 text-green-500" />
              ) : (
                <XCircle className="w-16 h-16 text-red-500" />
              )}
            </div>
            <CardTitle className="text-3xl mb-2">
              {isPassed ? t('congratulations') : t('keep_practicing')}
            </CardTitle>
            <p className="text-muted-foreground">
              {isPassed
                ? t('successfully_completed')
                : t('dont_give_up')}
            </p>
          </CardHeader>
          <CardContent>
            {/* Score Display */}
            <div className="text-center mb-6">
              <div className="text-5xl font-bold mb-2">
                {performance.score}/{performance.total_questions}
              </div>
              <Progress value={performance.percentage} className="h-3 mb-2" />
              <p className="text-sm text-muted-foreground">{t('percentage_score', { percentage: performance.percentage.toFixed(1) })}</p>
              {performance.band_score && (
                <div className="mt-4">
                  <p className="text-sm text-muted-foreground mb-1">{t('ielts_band_score')}</p>
                  <p className="text-3xl font-bold text-primary">{performance.band_score}</p>
                </div>
              )}
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="text-center p-4 bg-green-50 dark:bg-green-950 rounded-lg">
                <CheckCircle2 className="w-6 h-6 mx-auto mb-2 text-green-600" />
                <p className="text-sm text-muted-foreground">{t('exercises.correct')}</p>
                <p className="text-2xl font-bold text-green-600">{performance.correct_answers}</p>
              </div>
              <div className="text-center p-4 bg-red-50 dark:bg-red-950 rounded-lg">
                <XCircle className="w-6 h-6 mx-auto mb-2 text-red-600" />
                <p className="text-sm text-muted-foreground">{t('exercises.incorrect')}</p>
                <p className="text-2xl font-bold text-red-600">{performance.incorrect_answers}</p>
              </div>
              <div className="text-center p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
                <Target className="w-6 h-6 mx-auto mb-2 text-gray-600" />
                <p className="text-sm text-muted-foreground">{t('exercises.skipped')}</p>
                <p className="text-2xl font-bold text-gray-600">{performance.skipped_answers}</p>
              </div>
              <div className="text-center p-4 bg-blue-50 dark:bg-blue-950 rounded-lg">
                <Clock className="w-6 h-6 mx-auto mb-2 text-blue-600" />
                <p className="text-sm text-muted-foreground">{t('exercises.time')}</p>
                <p className="text-2xl font-bold text-blue-600">
                  {formatTime(performance.time_spent_seconds)}
                </p>
              </div>
            </div>

            {/* Additional Stats */}
            <div className="mt-6 grid grid-cols-2 gap-4 text-sm">
              <div className="flex items-center justify-between p-3 bg-muted rounded-lg">
                <span className="text-muted-foreground">{t('accuracy')}</span>
                <span className="font-semibold">{performance.accuracy.toFixed(1)}%</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-muted rounded-lg">
                <span className="text-muted-foreground">{t('avg_time_per_question')}</span>
                <span className="font-semibold">
                  {performance.average_time_per_question.toFixed(0)}s
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Answer Review */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle>{t('answer_review')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {answers.map((answerData, index) => {
              const { answer, question, correct_answer } = answerData
              const isCorrect = answer.is_correct

              return (
                <div
                  key={answer.id}
                  className={`p-4 border-2 rounded-lg ${
                    isCorrect
                      ? "border-green-200 bg-green-50 dark:bg-green-950"
                      : "border-red-200 bg-red-50 dark:bg-red-950"
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <p className="font-medium">
                      {t('question_label', { number: question.question_number.toString(), text: question.question_text })}
                    </p>
                    <Badge className={isCorrect ? "bg-green-500" : "bg-red-500"}>
                      {isCorrect ? t('correct_badge') : t('incorrect_badge')}
                    </Badge>
                  </div>

                  {question.context_text && (
                    <div className="mb-3 p-3 bg-muted/50 rounded text-sm">
                      {question.context_text}
                    </div>
                  )}

                  <div className="space-y-2 text-sm">
                    <div>
                      <span className="font-medium">{t('your_answer')} </span>
                      <span className={isCorrect ? "text-green-600" : "text-red-600"}>
                        {answer.answer_text ||
                          (typeof correct_answer === "object" && "selected_option_id" in answer
                            ? answer.selected_option_id
                            : t('not_answered'))}
                      </span>
                    </div>

                    {!isCorrect && (
                      <div>
                        <span className="font-medium">{t('correct_answer')} </span>
                        <span className="text-green-600">
                          {typeof correct_answer === "string"
                            ? correct_answer
                            : correct_answer?.option_text}
                        </span>
                      </div>
                    )}

                    {answer.points_earned !== undefined && (
                      <div>
                        <span className="font-medium">{t('points_earned')} </span>
                        <span>{answer.points_earned} / {question.points}</span>
                      </div>
                    )}

                    {answer.time_spent_seconds !== undefined && (
                      <div>
                        <span className="font-medium">{t('time_spent_label')} </span>
                        <span>{answer.time_spent_seconds}s</span>
                      </div>
                    )}
                  </div>

                  {/* Explanation - Only show if user preference allows */}
                  {question.explanation && showExplanations && (
                    <div className="mt-3 p-3 bg-blue-50 dark:bg-blue-950 rounded-lg">
                      <p className="font-medium text-blue-900 dark:text-blue-100 mb-1 text-sm">
                        💡 {t('explanation')}
                      </p>
                      <p className="text-sm text-blue-800 dark:text-blue-200">
                        {question.explanation}
                      </p>
                    </div>
                  )}

                  {/* Tips */}
                  {question.tips && !isCorrect && (
                    <div className="mt-2 p-3 bg-yellow-50 dark:bg-yellow-950 rounded-lg">
                      <p className="font-medium text-yellow-900 dark:text-yellow-100 mb-1 text-sm">
                        💡 {t('tips_label')}
                      </p>
                      <p className="text-sm text-yellow-800 dark:text-yellow-200">{question.tips}</p>
                    </div>
                  )}
                </div>
              )
            })}
          </CardContent>
        </Card>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button variant="outline" onClick={() => router.push("/exercises/list")}>
            <Home className="w-4 h-4 mr-2" />
            {t('back_to_exercises')}
          </Button>
          <Button onClick={() => router.push(`/exercises/${exerciseId}`)}>
            <RotateCcw className="w-4 h-4 mr-2" />
            {t('try_again')}
          </Button>
        </div>
      </PageContainer>
    </AppLayout>
  )
}

