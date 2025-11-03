"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { CheckCircle2, Target, Home, RotateCcw, Mic, AlertCircle, Play } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { aiApi } from "@/lib/api/ai"
import type { SpeakingSubmissionResponse } from "@/types/ai"
import { useTranslations } from "@/lib/i18n"

export default function SpeakingSubmissionDetailPage() {
  return (
    <ProtectedRoute>
      <SpeakingSubmissionDetailContent />
    </ProtectedRoute>
  )
}

function SpeakingSubmissionDetailContent() {
  const params = useParams()
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")

  const submissionId = params.id as string

  const [data, setData] = useState<SpeakingSubmissionResponse | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchSubmission = async () => {
      try {
        setLoading(true)
        const response = await aiApi.getSpeakingSubmission(submissionId)
        setData(response)
      } catch (error) {
        console.error("[Speaking Submission] Failed to load:", error)
      } finally {
        setLoading(false)
      }
    }

    if (submissionId) {
      fetchSubmission()
    }
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

  if (!data || !data.submission) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={Mic}
            title={t("submission_not_found") || "Submission not found"}
            description={t("submission_not_found_description") || "This submission may have been removed"}
            actionLabel={tCommon("go_back") || "Go Back"}
            actionOnClick={() => router.back()}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  const { submission, evaluation } = data

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, "0")}`
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      case "processing":
        return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      case "transcribing":
        return "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      case "pending":
        return "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200"
      case "failed":
        return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  return (
    <AppLayout>
      <PageContainer maxWidth="4xl">
        {/* Header */}
        <Card className="mb-8">
          <CardHeader className="text-center">
            {evaluation ? (
              <>
                <div className="flex justify-center mb-4">
                  <CheckCircle2 className="w-16 h-16 text-green-500" />
                </div>
                <CardTitle className="text-3xl mb-2">
                  {t("evaluation_complete") || "Evaluation Complete"}
                </CardTitle>
                <p className="text-muted-foreground">
                  {t("your_speaking_has_been_evaluated") || "Your speaking has been evaluated"}
                </p>
              </>
            ) : (
              <>
                <div className="flex justify-center mb-4">
                  <AlertCircle className="w-16 h-16 text-yellow-500" />
                </div>
                <CardTitle className="text-3xl mb-2">
                  {submission.status === "processing" || submission.status === "transcribing"
                    ? (t("processing") || "Processing...")
                    : submission.status === "pending"
                    ? (t("pending_evaluation") || "Pending Evaluation")
                    : (t("evaluation_failed") || "Evaluation Failed")}
                </CardTitle>
                <p className="text-muted-foreground">
                  {t("please_wait_for_evaluation") || "Please wait while we evaluate your speaking..."}
                </p>
              </>
            )}
          </CardHeader>
          <CardContent>
            {evaluation && (
              <>
                {/* Band Score */}
                <div className="text-center mb-6">
                  <div className="text-5xl font-bold mb-2 text-primary">
                    {evaluation.overall_band_score.toFixed(1)}
                  </div>
                  <p className="text-sm text-muted-foreground mb-4">{t("band_score") || "Band Score"}</p>
                  <Progress value={(evaluation.overall_band_score / 9) * 100} className="h-3" />
                </div>

                {/* Criteria Scores */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="text-center p-4 bg-blue-50 dark:bg-blue-950 rounded-lg">
                    <p className="text-sm text-muted-foreground mb-1">{t("fluency_coherence") || "Fluency & Coherence"}</p>
                    <p className="text-2xl font-bold text-blue-600">{evaluation.fluency_coherence.toFixed(1)}</p>
                  </div>
                  <div className="text-center p-4 bg-green-50 dark:bg-green-950 rounded-lg">
                    <p className="text-sm text-muted-foreground mb-1">{t("lexical_resource") || "Lexical Resource"}</p>
                    <p className="text-2xl font-bold text-green-600">{evaluation.lexical_resource.toFixed(1)}</p>
                  </div>
                  <div className="text-center p-4 bg-purple-50 dark:bg-purple-950 rounded-lg">
                    <p className="text-sm text-muted-foreground mb-1">{t("grammatical_range") || "Grammatical Range"}</p>
                    <p className="text-2xl font-bold text-purple-600">{evaluation.grammatical_range.toFixed(1)}</p>
                  </div>
                  <div className="text-center p-4 bg-orange-50 dark:bg-orange-950 rounded-lg">
                    <p className="text-sm text-muted-foreground mb-1">{t("pronunciation") || "Pronunciation"}</p>
                    <p className="text-2xl font-bold text-orange-600">{evaluation.pronunciation.toFixed(1)}</p>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Submission Info */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle>{t("submission_details") || "Submission Details"}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">{t("part_number") || "Part"}</p>
                <p className="font-semibold">Part {submission.part_number}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">{t("duration") || "Duration"}</p>
                <p className="font-semibold">{formatDuration(submission.audio_duration_seconds)}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">{t("status") || "Status"}</p>
                <Badge className={getStatusColor(submission.status)}>
                  {submission.status}
                </Badge>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">{t("submitted_at") || "Submitted At"}</p>
                <p className="font-semibold text-sm">{formatDate(submission.submitted_at)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Audio Player */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Mic className="w-5 h-5" />
              {t("your_recording") || "Your Recording"}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <audio src={submission.audio_url} controls className="w-full" />
            {submission.transcript_text && (
              <div className="mt-4">
                <h4 className="font-semibold mb-2">{t("transcript") || "Transcript"}</h4>
                <div className="prose prose-sm max-w-none">
                  <p className="whitespace-pre-wrap">{submission.transcript_text}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Evaluation Details */}
        {evaluation && (
          <>
            {/* Detailed Feedback */}
            <Card className="mb-8">
              <CardHeader>
                <CardTitle>{t("detailed_feedback") || "Detailed Feedback"}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="prose prose-sm max-w-none">
                  <p className="whitespace-pre-wrap">{evaluation.examiner_feedback}</p>
                </div>
              </CardContent>
            </Card>

            {/* Detailed Scores */}
            {evaluation.detailed_feedback && (
              <Card className="mb-8">
                <CardHeader>
                  <CardTitle>{t("detailed_criteria_scores") || "Detailed Criteria Scores"}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {Object.entries(evaluation.detailed_feedback).map(([key, value]: [string, any]) => (
                    <div key={key} className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-semibold capitalize">{key.replace(/_/g, " ")}</h4>
                        <Badge variant="secondary">{value.score.toFixed(1)}</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground">{value.analysis}</p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}

            {/* Strengths */}
            {evaluation.strengths && evaluation.strengths.length > 0 && (
              <Card className="mb-8">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-green-500" />
                    {t("strengths") || "Strengths"}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="list-disc list-inside space-y-2">
                    {evaluation.strengths.map((strength, idx) => (
                      <li key={idx}>{strength}</li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}

            {/* Areas for Improvement */}
            {evaluation.areas_for_improvement && evaluation.areas_for_improvement.length > 0 && (
              <Card className="mb-8">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Target className="w-5 h-5 text-blue-500" />
                    {t("areas_for_improvement") || "Areas for Improvement"}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="list-disc list-inside space-y-2">
                    {evaluation.areas_for_improvement.map((area, idx) => (
                      <li key={idx}>{area}</li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}

            {/* Additional Metrics */}
            {(evaluation.speech_rate_wpm || evaluation.pause_frequency || evaluation.filler_words_count) && (
              <Card className="mb-8">
                <CardHeader>
                  <CardTitle>{t("speech_metrics") || "Speech Metrics"}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {evaluation.speech_rate_wpm && (
                      <div>
                        <p className="text-sm text-muted-foreground">{t("speech_rate") || "Speech Rate"}</p>
                        <p className="font-semibold">{evaluation.speech_rate_wpm} WPM</p>
                      </div>
                    )}
                    {evaluation.pause_frequency && (
                      <div>
                        <p className="text-sm text-muted-foreground">{t("pause_frequency") || "Pause Frequency"}</p>
                        <p className="font-semibold">{evaluation.pause_frequency}</p>
                      </div>
                    )}
                    {evaluation.filler_words_count !== undefined && (
                      <div>
                        <p className="text-sm text-muted-foreground">{t("filler_words") || "Filler Words"}</p>
                        <p className="font-semibold">{evaluation.filler_words_count}</p>
                      </div>
                    )}
                    {evaluation.vocabulary_level && (
                      <div>
                        <p className="text-sm text-muted-foreground">{t("vocabulary_level") || "Vocabulary Level"}</p>
                        <p className="font-semibold">{evaluation.vocabulary_level}</p>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            )}
          </>
        )}

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button variant="outline" onClick={() => router.push("/ai/speaking")}>
            <Home className="w-4 h-4 mr-2" />
            {t("back_to_prompts") || "Back to Prompts"}
          </Button>
          {evaluation && (
            <Button onClick={() => router.push(`/ai/speaking/${submission.task_prompt_id || ""}`)}>
              <RotateCcw className="w-4 h-4 mr-2" />
              {t("try_again") || "Try Again"}
            </Button>
          )}
        </div>
      </PageContainer>
    </AppLayout>
  )
}

