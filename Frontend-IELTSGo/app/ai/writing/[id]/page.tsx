"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Badge } from "@/components/ui/badge"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Progress } from "@/components/ui/progress"
import { 
  FileText, 
  Clock, 
  Target, 
  ChevronLeft, 
  Loader2, 
  AlertCircle,
  CheckCircle2,
  Info
} from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { aiApi } from "@/lib/api/ai"
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"
import type { WritingPrompt, WritingSubmissionResponse } from "@/types/ai"
import { useTranslations } from "@/lib/i18n"

// Validation constants (matching backend)
const MIN_WORD_COUNT_TASK1 = 150
const MIN_WORD_COUNT_TASK2 = 250
const MAX_WORD_COUNT = 10000
const MAX_ESSAY_LENGTH = 50000

function countWords(text: string): number {
  return text.trim().split(/\s+/).filter(word => word.length > 0).length
}

export default function WritingPromptPage() {
  return (
    <ProtectedRoute>
      <WritingPromptContent />
    </ProtectedRoute>
  )
}

function WritingPromptContent() {
  const params = useParams()
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")
  const toast = useToastWithI18n()

  const promptId = params.id as string

  const [prompt, setPrompt] = useState<WritingPrompt | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [essayText, setEssayText] = useState("")
  const [wordCount, setWordCount] = useState(0)
  const [errors, setErrors] = useState<{
    essay?: string
  }>({})

  useEffect(() => {
    const fetchPrompt = async () => {
      try {
        setLoading(true)
        const data = await aiApi.getWritingPrompt(promptId)
        setPrompt(data)
      } catch (error: any) {
        console.error("[Writing Prompt] Failed to load:", error)
        toast.error(error.response?.data?.error || "Failed to load prompt")
      } finally {
        setLoading(false)
      }
    }

    if (promptId) {
      fetchPrompt()
    }
  }, [promptId, toast])

  useEffect(() => {
    const count = countWords(essayText)
    setWordCount(count)
    
    // Clear errors when typing
    if (errors.essay) {
      setErrors({})
    }
  }, [essayText])

  const validateEssay = (): boolean => {
    const newErrors: typeof errors = {}
    
    if (!essayText.trim()) {
      newErrors.essay = t("essay_required") || "Essay text is required"
      setErrors(newErrors)
      return false
    }

    if (essayText.length > MAX_ESSAY_LENGTH) {
      newErrors.essay = t("essay_too_long") || 
        `Essay exceeds maximum length (${MAX_ESSAY_LENGTH} characters)`
      setErrors(newErrors)
      return false
    }

    if (wordCount > MAX_WORD_COUNT) {
      newErrors.essay = t("essay_word_count_exceeds_max") || 
        `Word count (${wordCount}) exceeds maximum (${MAX_WORD_COUNT} words)`
      setErrors(newErrors)
      return false
    }

    const minWords = prompt?.task_type === "task1" ? MIN_WORD_COUNT_TASK1 : MIN_WORD_COUNT_TASK2
    if (wordCount < minWords) {
      newErrors.essay = t("essay_word_count_below_min") || 
        `Word count (${wordCount}) is below minimum for ${prompt?.task_type === "task1" ? "Task 1" : "Task 2"} (${minWords} words)`
      setErrors(newErrors)
      return false
    }

    setErrors({})
    return true
  }

  const handleSubmit = async () => {
    if (!validateEssay() || !prompt) return

    try {
      setSubmitting(true)
      
      const response: WritingSubmissionResponse = await aiApi.submitWriting({
        task_type: prompt.task_type,
        task_prompt_id: prompt.id,
        task_prompt_text: prompt.prompt_text,
        essay_text: essayText,
      })

      toast.success(t("submission_successful") || "Submission successful!")
      
      // Navigate to result page
      router.push(`/ai/writing/submissions/${response.submission.id}`)
    } catch (error: any) {
      console.error("[Writing Submit] Failed:", error)
      const errorMsg = error.response?.data?.error || 
        error.message || 
        t("submission_failed") || 
        "Failed to submit writing"
      toast.error(errorMsg)
    } finally {
      setSubmitting(false)
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

  if (!prompt) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={FileText}
            title={t("prompt_not_found") || "Prompt not found"}
            description={t("prompt_not_found_description") || "This prompt may have been removed"}
            actionLabel={tCommon("go_back") || "Go Back"}
            actionOnClick={() => router.back()}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  const minWords = prompt.task_type === "task1" ? MIN_WORD_COUNT_TASK1 : MIN_WORD_COUNT_TASK2
  const wordCountProgress = Math.min((wordCount / minWords) * 100, 100)
  const wordCountColor = wordCount >= minWords ? "text-green-600" : wordCount >= minWords * 0.8 ? "text-yellow-600" : "text-red-600"

  return (
    <AppLayout>
      <PageContainer maxWidth="4xl">
        <Button
          variant="ghost"
          onClick={() => router.back()}
          className="mb-4"
        >
          <ChevronLeft className="h-4 w-4 mr-2" />
          {tCommon("go_back") || "Back"}
        </Button>

        <div className="mb-8">
          <div className="flex items-center gap-2 mb-3">
            <Badge variant="outline">
              {prompt.task_type === "task1" ? "Task 1" : "Task 2"}
            </Badge>
            {prompt.difficulty && (
              <Badge>{prompt.difficulty}</Badge>
            )}
            {prompt.topic && (
              <Badge variant="secondary">{prompt.topic}</Badge>
            )}
          </div>
          <h1 className="text-3xl font-bold tracking-tight mb-2">
            {prompt.topic || "Writing Practice"}
          </h1>
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Prompt */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="w-5 h-5" />
                  {t("task_prompt") || "Task Prompt"}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="prose prose-sm max-w-none">
                  <p className="whitespace-pre-wrap">{prompt.prompt_text}</p>
                </div>
                {prompt.visual_url && (
                  <div className="mt-4">
                    <img 
                      src={prompt.visual_url} 
                      alt="Task visual" 
                      className="rounded-lg border max-w-full"
                    />
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Writing Editor */}
            <Card>
              <CardHeader>
                <CardTitle>{t("your_essay") || "Your Essay"}</CardTitle>
                <CardDescription>
                  {t("essay_requirements") || 
                    `Minimum ${minWords} words for ${prompt.task_type === "task1" ? "Task 1" : "Task 2"}`}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Textarea
                    placeholder={t("start_writing_here") || "Start writing your essay here..."}
                    value={essayText}
                    onChange={(e) => setEssayText(e.target.value)}
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
                      {t("word_count") || "Word count"}: <strong>{wordCount}</strong>
                    </span>
                    <span className="text-muted-foreground">
                      {t("minimum") || "Minimum"}: {minWords}
                    </span>
                  </div>
                  <Progress 
                    value={wordCountProgress} 
                    className="h-2"
                  />
                </div>

                {/* Tips */}
                <Alert>
                  <Info className="h-4 w-4" />
                  <AlertDescription>
                    <ul className="list-disc list-inside space-y-1 text-sm">
                      <li>{t("tip_plan_before_writing") || "Plan your essay before writing"}</li>
                      <li>{t("tip_use_clear_structure") || "Use a clear structure (introduction, body, conclusion)"}</li>
                      <li>{t("tip_check_grammar") || "Check grammar and spelling before submitting"}</li>
                    </ul>
                  </AlertDescription>
                </Alert>
              </CardContent>
            </Card>

            {/* Submit Button */}
            <Button
              onClick={handleSubmit}
              disabled={submitting || wordCount < minWords || !!errors.essay}
              className="w-full"
              size="lg"
            >
              {submitting ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  {t("submitting") || "Submitting..."}
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4 mr-2" />
                  {t("submit_for_evaluation") || "Submit for Evaluation"}
                </>
              )}
            </Button>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>{t("requirements") || "Requirements"}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2 text-sm">
                  <Target className="w-4 h-4 text-muted-foreground" />
                  <span>{t("minimum_words") || "Minimum words"}: <strong>{minWords}</strong></span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span>{t("recommended_time") || "Recommended time"}: 
                    <strong> {prompt.task_type === "task1" ? "20" : "40"} {t("minutes") || "minutes"}</strong>
                  </span>
                </div>
              </CardContent>
            </Card>

            {prompt.has_sample_answer && prompt.sample_answer_text && (
              <Card>
                <CardHeader>
                  <CardTitle>{t("sample_answer") || "Sample Answer"}</CardTitle>
                  {prompt.sample_answer_band_score && (
                    <CardDescription>
                      {t("band_score") || "Band Score"}: {prompt.sample_answer_band_score}
                    </CardDescription>
                  )}
                </CardHeader>
                <CardContent>
                  <details className="text-sm">
                    <summary className="cursor-pointer font-medium hover:text-primary">
                      {t("view_sample_answer") || "View sample answer"}
                    </summary>
                    <div className="mt-4 prose prose-sm max-w-none">
                      <p className="whitespace-pre-wrap">{prompt.sample_answer_text}</p>
                    </div>
                  </details>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </PageContainer>
    </AppLayout>
  )
}

