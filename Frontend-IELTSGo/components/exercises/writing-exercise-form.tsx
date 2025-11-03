"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Textarea } from "@/components/ui/textarea"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Progress } from "@/components/ui/progress"
import { AlertCircle, Info, CheckCircle2 } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

// Validation constants (matching backend)
const MIN_WORD_COUNT_TASK1 = 150
const MIN_WORD_COUNT_TASK2 = 250
const MAX_WORD_COUNT = 10000
const MAX_ESSAY_LENGTH = 50000

function countWords(text: string): number {
  return text.trim().split(/\s+/).filter(word => word.length > 0).length
}

interface WritingExerciseFormProps {
  prompt: string // Task prompt text from exercise instructions or section
  taskType: "task1" | "task2" // Determine from exercise title/description or default to task2
  onSubmit: (essayText: string) => void // Changed to sync callback
  submitting?: boolean
  timeSpentSeconds?: number
  value?: string // Controlled component - value from parent
  onChange?: (text: string) => void // Controlled component - onChange callback
}

export function WritingExerciseForm({
  prompt,
  taskType,
  onSubmit,
  submitting = false,
  timeSpentSeconds = 0,
  value,
  onChange,
}: WritingExerciseFormProps) {
  const t = useTranslations("exercises")
  const tAI = useTranslations("ai")

  const [essayText, setEssayText] = useState(value || "")
  const [wordCount, setWordCount] = useState(0)
  const [errors, setErrors] = useState<{ essay?: string }>({})

  // Controlled vs uncontrolled
  const currentText = value !== undefined ? value : essayText
  const handleTextChange = (text: string) => {
    if (value === undefined) {
      setEssayText(text)
    }
    onChange?.(text)
  }

  useEffect(() => {
    if (value !== undefined) {
      setEssayText(value)
    }
  }, [value])

  useEffect(() => {
    const count = countWords(currentText)
    setWordCount(count)
    if (errors.essay) {
      setErrors({})
    }
  }, [currentText])

  const minWords = taskType === "task1" ? MIN_WORD_COUNT_TASK1 : MIN_WORD_COUNT_TASK2
  const wordCountProgress = Math.min((wordCount / minWords) * 100, 100)
  const wordCountColor =
    wordCount >= minWords
      ? "text-green-600"
      : wordCount >= minWords * 0.8
      ? "text-yellow-600"
      : "text-red-600"

  return (
    <div className="space-y-6">
      {/* Prompt */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            📝 {t("task_prompt") || "Task Prompt"}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="prose prose-sm max-w-none">
            <p className="whitespace-pre-wrap">{prompt}</p>
          </div>
        </CardContent>
      </Card>

      {/* Writing Editor */}
      <Card>
        <CardHeader>
          <CardTitle>{tAI("your_essay") || "Your Essay"}</CardTitle>
          <CardDescription>
            {tAI("essay_requirements") ||
              `Minimum ${minWords} words for ${taskType === "task1" ? "Task 1" : "Task 2"}`}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
                  <Textarea
                    placeholder={tAI("start_writing_here") || "Start writing your essay here..."}
                    value={currentText}
                    onChange={(e) => handleTextChange(e.target.value)}
                    rows={20}
                    className={errors.essay ? "border-destructive" : ""}
                    disabled={submitting}
                  />
            {errors.essay && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{errors.essay}</AlertDescription>
              </Alert>
            )}
          </div>

          {/* Word Count & Progress */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className={wordCountColor}>
                {tAI("word_count") || "Word count"}: <strong>{wordCount}</strong>
              </span>
              <span className="text-muted-foreground">
                {tAI("minimum") || "Minimum"}: {minWords}
              </span>
            </div>
            <Progress value={wordCountProgress} className="h-2" />
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

    </div>
  )
}

// Export the submit handler for parent to call
export function useWritingExerciseForm() {
  const [essayText, setEssayText] = useState("")
  const [wordCount, setWordCount] = useState(0)
  const [errors, setErrors] = useState<{ essay?: string }>({})

  useEffect(() => {
    const count = countWords(essayText)
    setWordCount(count)
    if (errors.essay) {
      setErrors({})
    }
  }, [essayText])

  const validateEssay = (taskType: "task1" | "task2"): boolean => {
    const newErrors: typeof errors = {}

    if (!essayText.trim()) {
      newErrors.essay = "Essay text is required"
      setErrors(newErrors)
      return false
    }

    if (essayText.length > MAX_ESSAY_LENGTH) {
      newErrors.essay = `Essay exceeds maximum length (${MAX_ESSAY_LENGTH} characters)`
      setErrors(newErrors)
      return false
    }

    if (wordCount > MAX_WORD_COUNT) {
      newErrors.essay = `Word count (${wordCount}) exceeds maximum (${MAX_WORD_COUNT} words)`
      setErrors(newErrors)
      return false
    }

    const minWords = taskType === "task1" ? MIN_WORD_COUNT_TASK1 : MIN_WORD_COUNT_TASK2
    if (wordCount < minWords) {
      newErrors.essay = `Word count (${wordCount}) is below minimum for ${taskType === "task1" ? "Task 1" : "Task 2"} (${minWords} words)`
      setErrors(newErrors)
      return false
    }

    setErrors({})
    return true
  }

  return {
    essayText,
    setEssayText,
    wordCount,
    errors,
    validateEssay,
  }
}

