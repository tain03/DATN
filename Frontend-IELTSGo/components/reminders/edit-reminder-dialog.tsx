"use client"

import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { remindersApi, type StudyReminder, type UpdateReminderRequest } from "@/lib/api/reminders"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"

interface EditReminderDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  reminder: StudyReminder
  onSuccess?: () => void
}

export function EditReminderDialog({ open, onOpenChange, reminder, onSuccess }: EditReminderDialogProps) {
  const t = useTranslations('reminders')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState<UpdateReminderRequest>({
    title: reminder.title,
    message: reminder.message,
    reminder_time: reminder.reminder_time,
    days_of_week: reminder.days_of_week,
    is_active: reminder.is_active,
  })
  const [selectedDays, setSelectedDays] = useState<number[]>([])

  const dayNames = [
    tCommon('sunday'),
    tCommon('monday'),
    tCommon('tuesday'),
    tCommon('wednesday'),
    tCommon('thursday'),
    tCommon('friday'),
    tCommon('saturday'),
  ]

  useEffect(() => {
    if (open && reminder) {
      setFormData({
        title: reminder.title,
        message: reminder.message,
        reminder_time: reminder.reminder_time,
        days_of_week: reminder.days_of_week,
        is_active: reminder.is_active,
      })
      
      if (reminder.days_of_week) {
        try {
          setSelectedDays(JSON.parse(reminder.days_of_week))
        } catch {
          setSelectedDays([])
        }
      } else {
        setSelectedDays([])
      }
    }
  }, [open, reminder])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      const submitData: UpdateReminderRequest = {
        ...formData,
        days_of_week: reminder.reminder_type === 'weekly' 
          ? JSON.stringify(selectedDays.sort())
          : undefined,
      }
      await remindersApi.updateReminder(reminder.id, submitData)
      toast({
        title: t('edit_reminder'),
        description: tCommon('success'),
      })
      onOpenChange(false)
      onSuccess?.()
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_update'),
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const toggleDay = (day: number) => {
    setSelectedDays(prev => 
      prev.includes(day) 
        ? prev.filter(d => d !== day)
        : [...prev, day].sort()
    )
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t('edit_reminder')}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">{t('reminder_title')}</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder={t('reminder_title_placeholder')}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="message">{t('message')}</Label>
            <Textarea
              id="message"
              value={formData.message || ''}
              onChange={(e) => setFormData({ ...formData, message: e.target.value })}
              placeholder={t('message_placeholder')}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="reminder_time">{t('reminder_time')}</Label>
              <Input
                id="reminder_time"
                type="time"
                value={formData.reminder_time?.split(':').slice(0, 2).join(':') || '09:00'}
                onChange={(e) => setFormData({ ...formData, reminder_time: `${e.target.value}:00` })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label>{t('is_active')}</Label>
              <Select
                value={formData.is_active ? 'active' : 'inactive'}
                onValueChange={(value) => setFormData({ ...formData, is_active: value === 'active' })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">{t('active')}</SelectItem>
                  <SelectItem value="inactive">{t('inactive')}</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {reminder.reminder_type === 'weekly' && (
            <div className="space-y-2">
              <Label>{t('days_of_week')}</Label>
              <div className="grid grid-cols-7 gap-2">
                {dayNames.map((day, index) => (
                  <div key={index} className="flex items-center space-x-2">
                    <Checkbox
                      id={`day-${index}`}
                      checked={selectedDays.includes(index)}
                      onCheckedChange={() => toggleDay(index)}
                    />
                    <Label
                      htmlFor={`day-${index}`}
                      className="text-sm font-normal cursor-pointer"
                    >
                      {day.slice(0, 3)}
                    </Label>
                  </div>
                ))}
              </div>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              {tCommon('cancel')}
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? tCommon('loading') : tCommon('save')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

