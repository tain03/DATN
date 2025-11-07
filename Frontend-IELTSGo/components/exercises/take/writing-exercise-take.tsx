"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Progress } from "@/components/ui/progress"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Clock, FileText, Image as ImageIcon, Target, Info, CheckCircle2, AlertCircle, Eye, EyeOff } from "lucide-react"
import Image from "next/image"
import { useTranslations } from "@/lib/i18n"

// Validation constants
const MIN_WORD_COUNT_TASK1 = 150
const MIN_WORD_COUNT_TASK2 = 250

function countWords(text: string): number {
  return text.trim().split(/\s+/).filter(word => word.length > 0).length
}

interface WritingExerciseTakeProps {
  exercise: {
    id: string
    title: string
    time_limit_minutes?: number
    writing_task_type?: string
    writing_prompt_text?: string
    writing_visual_type?: string
    writing_visual_url?: string
    writing_word_requirement?: number
  }
  taskType: "task1" | "task2"
  prompt: string
  timeRemaining: number | null
  hasTimeLimit: boolean
  timeSpent: number
  value: string
  onChange: (text: string) => void
  onSubmit: () => void
  submitting: boolean
}

export function WritingExerciseTake({
  exercise,
  taskType,
  prompt,
  timeRemaining,
  hasTimeLimit,
  timeSpent,
  value,
  onChange,
  onSubmit,
  submitting,
}: WritingExerciseTakeProps) {
  const t = useTranslations('exercises')
  const tAI = useTranslations('ai')
  
  const [showPrompt, setShowPrompt] = useState(true)
  const [showVisual, setShowVisual] = useState(true)
  
  const wordCount = countWords(value)
  const minWords = taskType === "task1" ? MIN_WORD_COUNT_TASK1 : MIN_WORD_COUNT_TASK2
  const wordRequirement = exercise.writing_word_requirement || minWords
  const wordCountProgress = Math.min((wordCount / wordRequirement) * 100, 100)
  
  const wordCountColor =
    wordCount >= wordRequirement
      ? "text-green-600 dark:text-green-400"
      : wordCount >= wordRequirement * 0.8
      ? "text-yellow-600 dark:text-yellow-400"
      : "text-red-600 dark:text-red-400"

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
    return formatTime(timeSpent)
  }

  const isTimeVeryLow = hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 60
  const isTimeRunningLow = hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 300

  const isTask1 = taskType === "task1"
  const hasVisual = isTask1 && exercise.writing_visual_url

  return (
    <div className="space-y-4">
      {/* Header with Timer */}
      <Card className="border-blue-200 dark:border-blue-800">
        <CardContent className="py-4">
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div>
              <h2 className="text-lg font-semibold">{exercise.title}</h2>
              <div className="flex items-center gap-2 mt-1">
                <Badge variant="outline" className="bg-blue-50 dark:bg-blue-950">
                  {isTask1 ? t('writing_task_1') : t('writing_task_2')}
                </Badge>
                {exercise.writing_visual_type && (
                  <Badge variant="outline" className="bg-purple-50 dark:bg-purple-950">
                    {exercise.writing_visual_type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </Badge>
                )}
              </div>
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
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Split Layout: Prompt/Visual (Left) + Editor (Right) */}
      <div className="grid lg:grid-cols-2 gap-4">
        {/* Left Side: Prompt & Visual */}
        <div className="space-y-4">
          {/* Prompt Card - Sticky */}
          <div className="lg:sticky lg:top-4">
            <Card className="border-orange-200 dark:border-orange-800">
              <CardHeader className="flex-shrink-0">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg flex items-center gap-2">
                    <FileText className="w-5 h-5 text-orange-600 dark:text-orange-400" />
                    {t('writing_prompt')}
                  </CardTitle>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowPrompt(!showPrompt)}
                    className="lg:hidden"
                  >
                    {showPrompt ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </Button>
                </div>
                <CardDescription>
                  {isTask1 
                    ? t('writing_task1_description')
                    : t('writing_task2_description')
                  }
                </CardDescription>
              </CardHeader>
              <CardContent>
                {showPrompt && (
                  <div className="prose prose-sm max-w-none">
                    <p className="whitespace-pre-wrap text-sm leading-relaxed">{prompt}</p>
                  </div>
                )}
                {!showPrompt && (
                  <div className="flex items-center justify-center h-20 text-muted-foreground">
                    <p>{t('prompt_hidden') || 'Prompt đã được ẩn'}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Visual for Task 1 */}
          {hasVisual && (
            <Card className="border-purple-200 dark:border-purple-800">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg flex items-center gap-2">
                    <ImageIcon className="w-5 h-5 text-purple-600 dark:text-purple-400" />
                    {t('visual') || 'Visual'}
                  </CardTitle>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowVisual(!showVisual)}
                  >
                    {showVisual ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {showVisual && exercise.writing_visual_url && (
                  <div className="relative w-full h-64 rounded-lg overflow-hidden border bg-muted">
                    <Image
                      src={exercise.writing_visual_url}
                      alt={exercise.writing_visual_type || "Visual"}
                      fill
                      className="object-contain"
                      sizes="(max-width: 768px) 100vw, 50vw"
                    />
                  </div>
                )}
                {!showVisual && (
                  <div className="flex items-center justify-center h-40 text-muted-foreground">
                    <p>{t('visual_hidden') || 'Visual đã được ẩn'}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Word Requirement Info */}
          <Card className="bg-blue-50/50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-800">
            <CardContent className="py-4">
              <div className="flex items-center gap-3">
                <Target className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                <div>
                  <p className="text-sm font-medium">{t('minimum_words')}</p>
                  <p className="text-lg font-bold">{wordRequirement} {t('words')}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Side: Editor */}
        <div className="space-y-4">
          {/* Editor Card */}
          <Card className="h-full flex flex-col">
            <CardHeader className="flex-shrink-0">
              <CardTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5" />
                {tAI("your_essay") || "Your Essay"}
              </CardTitle>
              <CardDescription>
                {tAI("essay_requirements")
                  ?.replace('{minWords}', wordRequirement.toString())
                  ?.replace('{taskType}', isTask1 ? "Task 1" : "Task 2") ||
                  `Minimum ${wordRequirement} words for ${isTask1 ? "Task 1" : "Task 2"}`}
              </CardDescription>
            </CardHeader>
            <CardContent className="flex-1 flex flex-col space-y-4">
              {/* Editor */}
              <div className="flex-1">
                <Textarea
                  placeholder={tAI("start_writing_here") || "Start writing your essay here..."}
                  value={value}
                  onChange={(e) => onChange(e.target.value)}
                  className="min-h-[400px] resize-none font-mono text-sm leading-relaxed"
                  disabled={submitting}
                />
              </div>

              {/* Word Count & Progress */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className={wordCountColor}>
                    {tAI("word_count") || "Word count"}: <strong>{wordCount}</strong>
                  </span>
                  <span className="text-muted-foreground">
                    {tAI("minimum") || "Minimum"}: {wordRequirement}
                  </span>
                </div>
                <Progress 
                  value={wordCountProgress} 
                  className={`h-3 ${
                    wordCount >= wordRequirement 
                      ? '[&>div]:bg-green-500' 
                      : wordCount >= wordRequirement * 0.8 
                      ? '[&>div]:bg-yellow-500' 
                      : '[&>div]:bg-red-500'
                  }`}
                />
                {wordCount < wordRequirement && (
                  <p className="text-xs text-muted-foreground">
                    {wordRequirement - wordCount} {t('more_words_needed') || 'more words needed'}
                  </p>
                )}
              </div>

              {/* Tips */}
              <Alert>
                <Info className="h-4 w-4" />
                <AlertDescription>
                  <ul className="list-disc list-inside space-y-1 text-sm">
                    <li>{tAI("tip_plan_before_writing") || "Plan your essay before writing"}</li>
                    <li>
                      {tAI("tip_use_clear_structure") ||
                        "Use a clear structure (introduction, body, conclusion)"}
                    </li>
                    <li>
                      {tAI("tip_check_grammar") ||
                        "Check grammar and spelling before submitting"}
                    </li>
                  </ul>
                </AlertDescription>
              </Alert>
            </CardContent>
          </Card>

          {/* Submit Button */}
          <Card>
            <CardContent className="py-4">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  {submitting && (
                    <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
                      <AlertCircle className="w-4 h-4 animate-spin" />
                      <span>{tAI('submitting') || "Đang nộp bài và đánh giá AI..."}</span>
                    </div>
                  )}
                  <p className="text-sm text-muted-foreground">
                    {tAI('tip_check_grammar') || "Kiểm tra ngữ pháp và chính tả trước khi nộp"}
                  </p>
                </div>
                <Button
                  onClick={onSubmit}
                  disabled={
                    submitting || 
                    value.trim().length === 0 || 
                    wordCount < wordRequirement
                  }
                  size="lg"
                  className="ml-4"
                >
                  {submitting ? (
                    <>
                      <AlertCircle className="w-4 h-4 mr-2 animate-spin" />
                      {tAI('submitting') || "Đang nộp..."}
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="w-4 h-4 mr-2" />
                      {tAI('submit_for_evaluation') || "Nộp để đánh giá"}
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

