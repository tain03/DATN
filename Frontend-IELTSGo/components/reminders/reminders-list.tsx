"use client"

import { useState, useEffect } from "react"
import { remindersApi, type StudyReminder } from "@/lib/api/reminders"
import { ReminderCard } from "./reminder-card"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { Clock } from "lucide-react"

export function RemindersList() {
  const t = useTranslations('reminders')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [reminders, setReminders] = useState<StudyReminder[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadReminders()
  }, [])

  const loadReminders = async () => {
    try {
      setLoading(true)
      const response = await remindersApi.getReminders()
      setReminders(response.reminders || [])
    } catch (error: any) {
      console.error('[Reminders] Error loading reminders:', error)
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_load_reminders'),
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (reminderId: string) => {
    try {
      await remindersApi.deleteReminder(reminderId)
      setReminders(reminders.filter(r => r.id !== reminderId))
      toast({
        title: t('delete_reminder'),
        description: tCommon('success'),
      })
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_delete'),
        variant: "destructive",
      })
    }
  }

  const handleToggle = async (reminderId: string) => {
    try {
      const updated = await remindersApi.toggleReminder(reminderId)
      setReminders(reminders.map(r => r.id === reminderId ? updated : r))
      toast({
        title: t('toggle_reminder'),
        description: updated.is_active ? t('active') : t('inactive'),
      })
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_toggle'),
        variant: "destructive",
      })
    }
  }

  const handleUpdate = async () => {
    await loadReminders()
  }

  if (loading) {
    return <PageLoading translationKey="loading" />
  }

  if (reminders.length === 0) {
    return (
      <EmptyState
        icon={Clock}
        title={t('no_reminders')}
        description={t('no_reminders_description') || 'Create your first reminder to never miss a study session'}
      />
    )
  }

  // Group reminders by active status
  const activeReminders = reminders.filter(r => r.is_active)
  const inactiveReminders = reminders.filter(r => !r.is_active)

  return (
    <div className="space-y-8">
      {/* Active Reminders */}
      {activeReminders.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4">{t('active')}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {activeReminders.map((reminder) => (
              <ReminderCard
                key={reminder.id}
                reminder={reminder}
                onDelete={handleDelete}
                onToggle={handleToggle}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}

      {/* Inactive Reminders */}
      {inactiveReminders.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4">{t('inactive')}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {inactiveReminders.map((reminder) => (
              <ReminderCard
                key={reminder.id}
                reminder={reminder}
                onDelete={handleDelete}
                onToggle={handleToggle}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

