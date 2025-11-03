"use client"

import { useState, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { FileText, Calendar, Target, Eye, TrendingUp, Clock } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { aiApi } from "@/lib/api/ai"
import type { WritingSubmission } from "@/types/ai"
import { useTranslations } from "@/lib/i18n"

export default function WritingSubmissionsPage() {
  return (
    <ProtectedRoute>
      <WritingSubmissionsContent />
    </ProtectedRoute>
  )
}

function WritingSubmissionsContent() {
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")

  const [submissions, setSubmissions] = useState<WritingSubmission[]>([])
  const [loading, setLoading] = useState(true)
  const [offset, setOffset] = useState(0)
  const [total, setTotal] = useState(0)
  const limit = 20

  const fetchSubmissions = useCallback(async () => {
    try {
      setLoading(true)
      const response = await aiApi.getWritingSubmissions(limit, offset)
      setSubmissions(response.submissions || [])
      setTotal(response.total || 0)
    } catch (error) {
      console.error("[Writing Submissions] Failed to load:", error)
    } finally {
      setLoading(false)
    }
  }, [offset])

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

  const getStatusColor = useCallback((status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      case "processing":
        return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
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
          <h1 className="text-3xl font-bold mb-2">{t("writing_submissions") || "Writing Submissions"}</h1>
          <p className="text-muted-foreground">
            {t("writing_submissions_description") || "View all your writing submissions and evaluations"}
          </p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center min-h-[400px]">
            <PageLoading translationKey="loading" size="md" />
          </div>
        ) : submissions.length === 0 ? (
          <EmptyState
            icon={FileText}
            title={t("no_submissions_yet") || "No submissions yet"}
            description={t("no_submissions_description") || "Start practicing writing to see your submissions here"}
            actionLabel={t("browse_prompts") || "Browse Prompts"}
            actionOnClick={() => router.push("/ai/writing")}
          />
        ) : (
          <div className="space-y-4">
            {submissions.map((submission) => (
              <Card
                key={submission.id}
                className="cursor-pointer hover:shadow-lg transition-shadow"
                onClick={() => router.push(`/ai/writing/submissions/${submission.id}`)}
              >
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <CardTitle className="text-lg mb-1">
                        {submission.task_type === "task1" ? "Task 1" : "Task 2"}
                      </CardTitle>
                      <CardDescription className="flex items-center gap-2">
                        <Calendar className="w-3 h-3" />
                        {formatDate(submission.submitted_at)}
                      </CardDescription>
                    </div>
                    <Badge className={getStatusColor(submission.status)}>
                      {submission.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">{t("word_count") || "Word count"}</p>
                      <p className="text-lg font-semibold">{submission.word_count}</p>
                    </div>
                    {submission.time_spent_seconds && (
                      <div>
                        <p className="text-sm text-muted-foreground">{tCommon("time") || "Time spent"}</p>
                        <p className="text-lg font-semibold">
                          {Math.floor(submission.time_spent_seconds / 60)}m {submission.time_spent_seconds % 60}s
                        </p>
                      </div>
                    )}
                    <div>
                      <p className="text-sm text-muted-foreground">{t("task_type") || "Task type"}</p>
                      <p className="text-lg font-semibold">{submission.task_type}</p>
                    </div>
                    <div>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation()
                          router.push(`/ai/writing/submissions/${submission.id}`)
                        }}
                      >
                        <Eye className="w-4 h-4 mr-2" />
                        {t("view_details") || "View Details"}
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* Pagination */}
        {total > limit && (
          <div className="mt-8 flex justify-center gap-2">
            <Button
              variant="outline"
              onClick={() => setOffset(Math.max(0, offset - limit))}
              disabled={offset === 0}
            >
              {tCommon("previous")}
            </Button>
            <span className="flex items-center px-4">
              {tCommon("page_of", {
                page: Math.floor(offset / limit) + 1,
                totalPages: Math.ceil(total / limit),
              })}
            </span>
            <Button
              variant="outline"
              onClick={() => setOffset(offset + limit)}
              disabled={offset + limit >= total}
            >
              {tCommon("next")}
            </Button>
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}

