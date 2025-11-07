"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { FileText } from "lucide-react"
import { exercisesApi } from "@/lib/api/exercises"
import { useTranslations } from "@/lib/i18n"

export default function WritingSubmissionDetailPage() {
  return (
    <ProtectedRoute>
      <WritingSubmissionDetailContent />
    </ProtectedRoute>
  )
}

function WritingSubmissionDetailContent() {
  const params = useParams()
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")

  const submissionId = params.id as string
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    const redirectToResult = async () => {
      try {
        setLoading(true)
        setError(false)
        // Get submission result to find exercise_id
        const result = await exercisesApi.getSubmissionResult(submissionId)
        if (result && result.exercise) {
          // Redirect to the unified result page
          router.replace(`/exercises/${result.exercise.id}/result/${submissionId}`)
        } else {
          setError(true)
          setLoading(false)
        }
      } catch (err) {
        console.error("[Writing Submission] Failed to load:", err)
        setError(true)
        setLoading(false)
      }
    }

    if (submissionId) {
      redirectToResult()
    }
  }, [submissionId, router])

  if (loading) {
    return (
      <AppLayout>
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  if (error) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={FileText}
            title={t("submission_not_found") || "Submission not found"}
            description={t("submission_not_found_description") || "This submission may have been removed"}
            actionLabel={tCommon("go_back") || "Go Back"}
            actionOnClick={() => router.push("/exercises/list")}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  // Should not reach here as redirect should happen
  return null
}
