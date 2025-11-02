"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { GoalsList } from "@/components/goals/goals-list"
import { CreateGoalDialog } from "@/components/goals/create-goal-dialog"
import { Button } from "@/components/ui/button"
import { Plus } from "lucide-react"
import { useTranslations } from "@/lib/i18n"
import { useState } from "react"

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
        <GoalsList />

        {/* Create Goal Dialog */}
        <CreateGoalDialog
          open={createDialogOpen}
          onOpenChange={setCreateDialogOpen}
        />
      </PageContainer>
    </AppLayout>
  )
}

