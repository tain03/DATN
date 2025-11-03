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
const RemindersList = lazy(() => import("@/components/reminders/reminders-list").then(m => ({ default: m.RemindersList })))
const CreateReminderDialog = lazy(() => import("@/components/reminders/create-reminder-dialog").then(m => ({ default: m.CreateReminderDialog })))

export default function RemindersPage() {
  return (
    <ProtectedRoute>
      <RemindersContent />
    </ProtectedRoute>
  )
}

function RemindersContent() {
  const t = useTranslations('reminders')
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
            {t('create_reminder')}
          </Button>
        }
      />
      <PageContainer>
        {/* Reminders List */}
        <Suspense fallback={<div className="flex items-center justify-center py-20">Loading reminders...</div>}>
          <RemindersList />
        </Suspense>

        {/* Create Reminder Dialog */}
        {createDialogOpen && (
          <Suspense fallback={null}>
            <CreateReminderDialog
              open={createDialogOpen}
              onOpenChange={setCreateDialogOpen}
            />
          </Suspense>
        )}
      </PageContainer>
    </AppLayout>
  )
}

