"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { remindersApi, type CreateReminderRequest } from "@/lib/api/reminders"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"

interface CreateReminderDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function CreateReminderDialog({ open, onOpenChange, onSuccess }: CreateReminderDialogProps) {
  const t = useTranslations('reminders')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState<CreateReminderRequest>({
    title: "",
    message: "",
    reminder_type: "daily",
    reminder_time: "09:00:00",
    days_of_week: undefined,
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      const submitData: CreateReminderRequest = {
        ...formData,
        days_of_week: formData.reminder_type === 'weekly' 
          ? JSON.stringify(selectedDays.sort())
          : undefined,
      }
      await remindersApi.createReminder(submitData)
      toast({
        title: t('create_reminder'),
        description: tCommon('success'),
      })
      // Reset form
      setFormData({
        title: "",
        message: "",
        reminder_type: "daily",
        reminder_time: "09:00:00",
        days_of_week: undefined,
      })
      setSelectedDays([])
      onOpenChange(false)
      onSuccess?.()
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_create'),
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
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto" aria-describedby={undefined}>
        <DialogHeader>
          <DialogTitle>{t('create_reminder')}</DialogTitle>
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
              value={formData.message}
              onChange={(e) => setFormData({ ...formData, message: e.target.value })}
              placeholder={t('message_placeholder')}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="reminder_type">{t('reminder_type')}</Label>
              <Select
                value={formData.reminder_type}
                onValueChange={(value: "daily" | "weekly" | "custom") => 
                  setFormData({ ...formData, reminder_type: value })
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">{t('daily')}</SelectItem>
                  <SelectItem value="weekly">{t('weekly')}</SelectItem>
                  <SelectItem value="custom">{t('custom')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="reminder_time">{t('reminder_time')}</Label>
              <Input
                id="reminder_time"
                type="time"
                value={formData.reminder_time.split(':').slice(0, 2).join(':')}
                onChange={(e) => setFormData({ ...formData, reminder_time: `${e.target.value}:00` })}
                required
              />
            </div>
          </div>

          {formData.reminder_type === 'weekly' && (
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
              {selectedDays.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  {t('select_at_least_one_day')}
                </p>
              )}
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              {tCommon('cancel')}
            </Button>
            <Button type="submit" disabled={loading || (formData.reminder_type === 'weekly' && selectedDays.length === 0)}>
              {loading ? tCommon('loading') : tCommon('save')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

