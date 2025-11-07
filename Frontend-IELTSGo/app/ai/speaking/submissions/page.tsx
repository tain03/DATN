"use client"

import { useState, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Mic, Calendar, Target, Eye, Clock } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { exercisesApi } from "@/lib/api/exercises"
import type { SubmissionWithExercise } from "@/types"
import { useTranslations } from "@/lib/i18n"

export default function SpeakingSubmissionsPage() {
  return (
    <ProtectedRoute>
      <SpeakingSubmissionsContent />
    </ProtectedRoute>
  )
}

function SpeakingSubmissionsContent() {
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")

  const [submissions, setSubmissions] = useState<SubmissionWithExercise[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const limit = 20

  const fetchSubmissions = useCallback(async () => {
    try {
      setLoading(true)
      const response = await exercisesApi.getMySubmissions(
        {
          skill: ['speaking'],
          sort_by: 'date',
          sort_order: 'desc',
        },
        page,
        limit
      )
      setSubmissions(response.submissions || [])
      setTotal(response.total || 0)
    } catch (error) {
      console.error("[Speaking Submissions] Failed to load:", error)
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => {
    fetchSubmissions()
  }, [fetchSubmissions])

  const formatDate = useCallback((dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  }, [])

  const formatDuration = useCallback((seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, "0")}`
  }, [])

  const getStatusColor = useCallback((status: string) => {
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
  }, [])

  return (
    <AppLayout>
      <PageContainer>
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">{t("speaking_submissions") || "Speaking Submissions"}</h1>
          <p className="text-muted-foreground">
            {t("speaking_submissions_description") || "View all your speaking submissions and evaluations"}
          </p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[400px]">
            <PageLoading translationKey="loading" size="md" />
          </div>
        ) : submissions.length === 0 ? (
          <EmptyState
            icon={Mic}
            title={t("no_submissions_yet") || "No submissions yet"}
            description={t("no_submissions_description") || "Start practicing speaking to see your submissions here"}
            actionLabel={t("browse_prompts") || "Browse Prompts"}
            actionOnClick={() => router.push("/ai/speaking")}
          />
        ) : (
          <div className="space-y-4">
            {submissions.map((item) => {
              const submission = item.submission
              const exercise = item.exercise
              const evaluationStatus = submission.evaluation_status || submission.status
              const partNumber = submission.speaking_part_number || 1
              
              return (
                <Card
                  key={submission.id}
                  className="cursor-pointer hover:shadow-lg transition-shadow"
                  onClick={() => router.push(`/exercises/${exercise.id}/result/${submission.id}`)}
                >
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <CardTitle className="text-lg mb-1">
                          {exercise.title || `Speaking Part ${partNumber}`}
                        </CardTitle>
                        <CardDescription className="flex items-center gap-2">
                          <Calendar className="w-3 h-3" />
                          {formatDate(submission.completed_at || submission.created_at)}
                        </CardDescription>
                      </div>
                      <Badge className={getStatusColor(evaluationStatus)}>
                        {evaluationStatus}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      {submission.audio_duration_seconds && (
                        <div>
                          <p className="text-sm text-muted-foreground">{t("duration") || "Duration"}</p>
                          <p className="text-lg font-semibold">{formatDuration(submission.audio_duration_seconds)}</p>
                        </div>
                      )}
                      {submission.transcript_text && (
                        <div>
                          <p className="text-sm text-muted-foreground">{t("transcript") || "Transcript"}</p>
                          <p className="text-lg font-semibold">
                            {submission.transcript_text.split(' ').length} {t("words") || "words"}
                          </p>
                        </div>
                      )}
                      {submission.band_score && (
                        <div>
                          <p className="text-sm text-muted-foreground">{t("band_score") || "Band Score"}</p>
                          <p className="text-lg font-semibold">{submission.band_score.toFixed(1)}</p>
                        </div>
                      )}
                      <div>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={(e) => {
                            e.stopPropagation()
                            router.push(`/exercises/${exercise.id}/result/${submission.id}`)
                          }}
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          {t("view_details") || "View Details"}
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        )}

        {/* Pagination */}
        {total > limit && (
          <div className="mt-8 flex justify-center gap-2">
            <Button
              variant="outline"
              onClick={() => setPage(Math.max(1, page - 1))}
              disabled={page === 1}
            >
              {tCommon("previous")}
            </Button>
            <span className="flex items-center px-4">
              Page {page} of {Math.ceil(total / limit)}
            </span>
            <Button
              variant="outline"
              onClick={() => setPage(page + 1)}
              disabled={page * limit >= total}
            >
              {tCommon("next")}
            </Button>
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}

