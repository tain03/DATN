"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Button } from "@/components/ui/button"
import { Plus } from "lucide-react"
import { useTranslations } from "@/lib/i18n"
import { useState, lazy, Suspense } from "react"

// Lazy load heavy components to improve initial load time
const GoalsList = lazy(() => import("@/components/goals/goals-list").then(m => ({ default: m.GoalsList })))
const CreateGoalDialog = lazy(() => import("@/components/goals/create-goal-dialog").then(m => ({ default: m.CreateGoalDialog })))

export default function GoalsPage() {
  return (
    <ProtectedRoute>
      <GoalsContent />
    </ProtectedRoute>
  )
}

function GoalsContent() {
  const t = useTranslations('goals')
  const tCommon = useTranslations('common')
  const [createDialogOpen, setCreateDialogOpen] = useState(false)

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <PageHeader
        title={t('title')}
        subtitle={t('subtitle')}
        rightActions={
          <Button onClick={() => setCreateDialogOpen(true)} size="sm">
            <Plus className="h-4 w-4 mr-2" />
            {t('create_goal')}
          </Button>
        }
      />
      <PageContainer>

        {/* Goals List */}
        <Suspense fallback={<div className="flex items-center justify-center py-20">Loading goals...</div>}>
          <GoalsList />
        </Suspense>

        {/* Create Goal Dialog */}
        {createDialogOpen && (
          <Suspense fallback={null}>
            <CreateGoalDialog
              open={createDialogOpen}
              onOpenChange={setCreateDialogOpen}
            />
          </Suspense>
        )}
      </PageContainer>
    </AppLayout>
  )
}

