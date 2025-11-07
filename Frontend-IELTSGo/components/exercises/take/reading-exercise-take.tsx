"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Clock, ChevronLeft, ChevronRight, Flag, Eye, EyeOff, Loader2, BookOpen } from "lucide-react"
import { useTranslations } from "@/lib/i18n"
import type { ExerciseSection, QuestionWithOptions } from "@/types"

interface ReadingExerciseTakeProps {
  exercise: {
    id: string
    title: string
    time_limit_minutes?: number
  }
  sections: ExerciseSection[]
  currentQuestionIndex: number
  answers: Map<string, any>
  timeRemaining: number | null
  hasTimeLimit: boolean
  answeredCount: number
  totalQuestions: number
  progress: number
  onAnswerChange: (questionId: string, answer: any) => void
  onNext: () => void
  onPrevious: () => void
  onSubmit: () => void
  submitting: boolean
}

export function ReadingExerciseTake({
  exercise,
  sections,
  currentQuestionIndex,
  answers,
  timeRemaining,
  hasTimeLimit,
  answeredCount,
  totalQuestions,
  progress,
  onAnswerChange,
  onNext,
  onPrevious,
  onSubmit,
  submitting,
}: ReadingExerciseTakeProps) {
  const t = useTranslations('exercises')
  
  // Get current question and section
  const allQuestions: (QuestionWithOptions & { sectionId: string; sectionData: any })[] =
    sections.flatMap((sectionData) =>
      (sectionData.questions || []).map((q) => ({
        ...q,
        sectionId: sectionData.section?.id || '',
        sectionData: sectionData.section
      }))
    ) || []
  const currentQuestion = allQuestions[currentQuestionIndex]
  const currentSection = currentQuestion?.sectionData
  
  const [showPassage, setShowPassage] = useState(true)
  
  // Format time
  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
    }
    return `${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
  }

  const getDisplayTime = () => {
    if (hasTimeLimit && timeRemaining !== null) {
      return formatTime(timeRemaining)
    }
    return formatTime(0)
  }

  const isTimeVeryLow = hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 60
  const isTimeRunningLow = hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 300

  if (!currentQuestion) return null

  return (
    <div className="space-y-4">
      {/* Header with Timer */}
      <Card className="border-green-200 dark:border-green-800">
        <CardContent className="py-4">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div>
              <h2 className="text-lg font-semibold">{exercise.title}</h2>
              <p className="text-sm text-muted-foreground">
                {t('question_of', { current: (currentQuestionIndex + 1).toString(), total: totalQuestions.toString() })}
              </p>
            </div>
            <div className="flex items-center gap-4">
              <div className={`flex items-center gap-2 ${isTimeVeryLow ? 'text-red-600 dark:text-red-400 animate-pulse' : isTimeRunningLow ? 'text-orange-600 dark:text-orange-400' : ''}`}>
                <Clock className="w-4 h-4" />
                <span className="font-mono text-lg">
                  {hasTimeLimit ? (
                    <>
                      {timeRemaining !== null && timeRemaining > 0 ? (
                        <>
                          {getDisplayTime()}
                          {isTimeVeryLow && ' ⚠️'}
                        </>
                      ) : (
                        t('time_up') || 'Hết giờ'
                      )}
                    </>
                  ) : (
                    getDisplayTime()
                  )}
                </span>
              </div>
              <Badge variant="outline" className="bg-green-50 dark:bg-green-950">
                {answeredCount}/{totalQuestions} {t('answered')}
              </Badge>
            </div>
          </div>
          <Progress value={progress} className="mt-3 h-2" />
        </CardContent>
      </Card>

      {/* Split Layout: Passage (Left) + Question (Right) */}
      <div className="grid lg:grid-cols-2 gap-4">
        {/* Passage Card - Left Side */}
        {currentSection?.passage_content && (
          <div className="lg:sticky lg:top-4 lg:h-[calc(100vh-200px)]">
            <Card className="h-full flex flex-col border-green-200 dark:border-green-800">
              <CardHeader className="flex-shrink-0">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg flex items-center gap-2">
                    <BookOpen className="w-5 h-5 text-green-600 dark:text-green-400" />
                    {currentSection.passage_title || t('reading_passage_label')}
                  </CardTitle>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowPassage(!showPassage)}
                    className="lg:hidden"
                  >
                    {showPassage ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </Button>
                </div>
                {currentSection.passage_word_count && (
                  <p className="text-sm text-muted-foreground mt-1">
                    {t('word_count', { count: currentSection.passage_word_count.toString() })}
                  </p>
                )}
              </CardHeader>
              <CardContent className="flex-1 overflow-y-auto">
                {showPassage && (
                  <div
                    className="prose prose-sm max-w-none leading-relaxed text-sm"
                    dangerouslySetInnerHTML={{ __html: currentSection.passage_content }}
                  />
                )}
                {!showPassage && (
                  <div className="flex items-center justify-center h-full text-muted-foreground">
                    <p>{t('passage_hidden') || 'Passage đã được ẩn'}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {/* Question Card - Right Side */}
        <div className="space-y-4">
          {/* Instructions */}
          {currentSection?.instructions && (
            <Card className="border-blue-200 bg-blue-50/50 dark:bg-blue-950/20">
              <CardHeader>
                <CardTitle className="text-sm flex items-center gap-2">
                  📋 {t('instructions')}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div
                  className="prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: currentSection.instructions }}
                />
              </CardContent>
            </Card>
          )}

          {/* Question */}
          <Card>
            <CardHeader>
              <CardTitle className="text-xl">
                {t('question')} {currentQuestion.question.question_number}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Question Text */}
              <div className="text-lg font-medium">{currentQuestion.question.question_text}</div>

              {/* Context */}
              {currentQuestion.question.context_text && (
                <div className="p-4 bg-muted rounded-lg">
                  <p className="text-sm">{currentQuestion.question.context_text}</p>
                </div>
              )}

              {/* Answer Input */}
              <div className="mt-6">
                {currentQuestion.question.question_type === "multiple_choice" ? (
                  <div className="space-y-3">
                    {currentQuestion.options?.map((option) => (
                      <label
                        key={option.id}
                        className={`flex items-start p-4 border-2 rounded-lg cursor-pointer transition-all ${
                          answers.get(currentQuestion.question.id) === option.id
                            ? "border-green-500 bg-green-50 dark:bg-green-950"
                            : "border-border hover:border-green-300"
                        }`}
                      >
                        <input
                          type="radio"
                          name={`question-${currentQuestion.question.id}`}
                          value={option.id}
                          checked={answers.get(currentQuestion.question.id) === option.id}
                          onChange={(e) =>
                            onAnswerChange(currentQuestion.question.id, e.target.value)
                          }
                          className="mt-1 mr-3"
                        />
                        <div className="flex-1">
                          <span className="font-medium mr-2">{option.option_label}.</span>
                          <span>{option.option_text}</span>
                        </div>
                      </label>
                    ))}
                  </div>
                ) : (
                  <input
                    type="text"
                    value={answers.get(currentQuestion.question.id) || ""}
                    onChange={(e) =>
                      onAnswerChange(currentQuestion.question.id, e.target.value)
                    }
                    placeholder={t('type_your_answer_here')}
                    className="w-full p-3 border-2 rounded-lg focus:border-green-500 outline-none"
                  />
                )}
              </div>

              {/* Tips */}
              {currentQuestion.question.tips && (
                <div className="p-3 bg-blue-50 dark:bg-blue-950 rounded-lg">
                  <p className="text-sm font-medium text-blue-900 dark:text-blue-100 mb-1">
                    💡 {t('tip')}:
                  </p>
                  <p className="text-sm text-blue-800 dark:text-blue-200">
                    {currentQuestion.question.tips}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Navigation */}
          <div className="flex justify-between">
            <Button onClick={onPrevious} disabled={currentQuestionIndex === 0} variant="outline">
              <ChevronLeft className="w-4 h-4 mr-2" />
              {t('previous')}
            </Button>

            {currentQuestionIndex === allQuestions.length - 1 ? (
              <Button onClick={onSubmit} disabled={submitting}>
                {submitting ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    {t('submitting')}
                  </>
                ) : (
                  <>
                    <Flag className="w-4 h-4 mr-2" />
                    {t('submit_exercise')}
                  </>
                )}
              </Button>
            ) : (
              <Button onClick={onNext}>
                {t('next')}
                <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

