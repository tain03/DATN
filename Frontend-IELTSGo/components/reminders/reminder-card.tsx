"use client"

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Edit, Trash2, ToggleLeft, ToggleRight, Clock } from "lucide-react"
import { type StudyReminder } from "@/lib/api/reminders"
import { useTranslations } from "@/lib/i18n"
import { EditReminderDialog } from "./edit-reminder-dialog"
import { useState } from "react"

interface ReminderCardProps {
  reminder: StudyReminder
  onDelete: (id: string) => void
  onToggle: (id: string) => void
  onUpdate: () => void
}

export function ReminderCard({ reminder, onDelete, onToggle, onUpdate }: ReminderCardProps) {
  const t = useTranslations('reminders')
  const [editDialogOpen, setEditDialogOpen] = useState(false)

  const parseDaysOfWeek = (daysJson?: string): number[] => {
    if (!daysJson) return []
    try {
      return JSON.parse(daysJson)
    } catch {
      return []
    }
  }

  const tCommon = useTranslations('common')
  
  const dayNames = [
    tCommon('sunday_short'),
    tCommon('monday_short'),
    tCommon('tuesday_short'),
    tCommon('wednesday_short'),
    tCommon('thursday_short'),
    tCommon('friday_short'),
    tCommon('saturday_short'),
  ]
  const days = parseDaysOfWeek(reminder.days_of_week)
  const time = reminder.reminder_time.split(':').slice(0, 2).join(':')

  return (
    <>
      <Card className="relative">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <CardTitle className="text-lg">{reminder.title}</CardTitle>
              {reminder.message && (
                <CardDescription className="mt-1">{reminder.message}</CardDescription>
              )}
            </div>
            <Badge variant={reminder.is_active ? "default" : "secondary"}>
              {reminder.is_active ? t('active') : t('inactive')}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span>{time}</span>
              <span className="mx-1">•</span>
              <span>{t(reminder.reminder_type === 'daily' ? 'daily' : reminder.reminder_type === 'weekly' ? 'weekly' : 'custom')}</span>
            </div>
            
            {reminder.reminder_type === 'weekly' && days.length > 0 && (
              <div className="flex flex-wrap gap-1">
                {days.map((day) => (
                  <Badge key={day} variant="outline" className="text-xs">
                    {dayNames[day]}
                  </Badge>
                ))}
              </div>
            )}

            <div className="flex items-center gap-2 pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => onToggle(reminder.id)}
                className="flex-1"
              >
                {reminder.is_active ? (
                  <>
                    <ToggleRight className="h-4 w-4 mr-2" />
                    {t('inactive')}
                  </>
                ) : (
                  <>
                    <ToggleLeft className="h-4 w-4 mr-2" />
                    {t('active')}
                  </>
                )}
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setEditDialogOpen(true)}
              >
                <Edit className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => onDelete(reminder.id)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <EditReminderDialog
        open={editDialogOpen}
        onOpenChange={setEditDialogOpen}
        reminder={reminder}
        onSuccess={onUpdate}
      />
    </>
  )
}

