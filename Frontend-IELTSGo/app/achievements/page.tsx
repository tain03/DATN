"use client"

import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { PageHeader } from "@/components/layout/page-header"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { AchievementsList } from "@/components/achievements/achievements-list"
import { useTranslations } from "@/lib/i18n"

export default function AchievementsPage() {
  return (
    <ProtectedRoute>
      <AchievementsContent />
    </ProtectedRoute>
  )
}

function AchievementsContent() {
  const t = useTranslations('achievements')

  return (
    <AppLayout showSidebar={true} showFooter={false} hideNavbar={true} hideTopBar={true}>
      <PageHeader
        title={t('title')}
        subtitle={t('subtitle')}
      />
      <PageContainer>
        {/* Achievements List */}
        <AchievementsList />
      </PageContainer>
    </AppLayout>
  )
}

