"use client"

import { useState, useEffect, useCallback } from "react"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { PromptCard } from "@/components/ai/prompt-card"
import { PromptFiltersComponent, type PromptFilters } from "@/components/ai/prompt-filters"
import { PageLoading } from "@/components/ui/page-loading"
import { SkeletonCard } from "@/components/ui/skeleton-card"
import { EmptyState } from "@/components/ui/empty-state"
import { FileText, Target } from "lucide-react"
import { aiApi } from "@/lib/api/ai"
import type { WritingPrompt } from "@/types/ai"
import { useTranslations } from "@/lib/i18n"
import { usePullToRefresh } from "@/lib/hooks/use-swipe-gestures"
import { Button } from "@/components/ui/button"

export default function WritingPromptsPage() {
  return (
    <ProtectedRoute>
      <WritingPromptsContent />
    </ProtectedRoute>
  )
}

function WritingPromptsContent() {
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")

  const [prompts, setPrompts] = useState<WritingPrompt[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<PromptFilters>({})
  const [offset, setOffset] = useState(0)
  const [total, setTotal] = useState(0)
  const limit = 12

  const fetchPrompts = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await aiApi.getWritingPrompts({
        ...filters,
        is_published: true,
        limit,
        offset,
      })
      setPrompts(response.prompts || [])
      setTotal(response.total || 0)
    } catch (error: any) {
      console.error("[Writing Prompts] Failed to load:", error)
      setError(error.response?.data?.error || "Failed to load prompts")
      setPrompts([])
    } finally {
      setLoading(false)
    }
  }, [filters, offset])

  useEffect(() => {
    fetchPrompts()
  }, [fetchPrompts])

  const { ref: pullToRefreshRef } = usePullToRefresh(() => {
    fetchPrompts()
  }, true)

  const handleFiltersChange = (newFilters: PromptFilters) => {
    setFilters(newFilters)
    setOffset(0)
  }

  const handleSearch = (search: string) => {
    setFilters((prev) => ({ ...prev, search: search || undefined }))
    setOffset(0)
  }

  const totalPages = Math.ceil(total / limit)
  const currentPage = Math.floor(offset / limit) + 1

  return (
    <AppLayout showFooter={true}>
      <div ref={pullToRefreshRef as React.RefObject<HTMLDivElement>}>
        <PageContainer>
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight mb-2">
              {t("writing_prompts") || "Writing Prompts"}
            </h1>
            <p className="text-base text-muted-foreground">
              {t("writing_prompts_description") || 
                "Browse and practice with IELTS Writing prompts. Choose a prompt and start writing!"}
            </p>
          </div>

          <PromptFiltersComponent
            type="writing"
            filters={filters}
            onFiltersChange={handleFiltersChange}
            onSearch={handleSearch}
          />

          {loading ? (
            <SkeletonCard gridCols={3} count={6} className="mt-8" />
          ) : error ? (
            <EmptyState
              icon={Target}
              title={error}
              description={tCommon("please_try_again_later") || "Please try again later"}
              actionLabel={tCommon("try_again") || "Try Again"}
              actionOnClick={fetchPrompts}
              className="mt-8"
            />
          ) : prompts.length === 0 ? (
            <EmptyState
              icon={FileText}
              title={t("no_prompts_found") || "No prompts found"}
              description={
                t("no_prompts_found_description") || 
                "Try adjusting your filters or search terms"
              }
              actionLabel={tCommon("clear_filters") || "Clear Filters"}
              actionOnClick={() => handleFiltersChange({})}
              className="mt-8"
            />
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8">
                {prompts.map((prompt) => (
                  <PromptCard
                    key={prompt.id}
                    prompt={prompt}
                    type="writing"
                  />
                ))}
              </div>

              {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2 mt-8">
                  <Button
                    variant="outline"
                    disabled={offset === 0}
                    onClick={() => setOffset(Math.max(0, offset - limit))}
                  >
                    {tCommon("previous")}
                  </Button>
                  <span className="text-sm text-muted-foreground px-4">
                    {tCommon("page_of", {
                      page: currentPage.toString(),
                      totalPages: totalPages.toString(),
                    })}
                  </span>
                  <Button
                    variant="outline"
                    disabled={offset + limit >= total}
                    onClick={() => setOffset(offset + limit)}
                  >
                    {tCommon("next")}
                  </Button>
                </div>
              )}
            </>
          )}
        </PageContainer>
      </div>
    </AppLayout>
  )
}

