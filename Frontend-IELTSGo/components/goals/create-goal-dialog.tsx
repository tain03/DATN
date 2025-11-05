"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { goalsApi, type CreateGoalRequest } from "@/lib/api/goals"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"

interface CreateGoalDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function CreateGoalDialog({ open, onOpenChange, onSuccess }: CreateGoalDialogProps) {
  const t = useTranslations('goals')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  // Calculate default end date (7 days from now for weekly, 30 for monthly)
  const getDefaultEndDate = (type: string) => {
    const date = new Date()
    if (type === "daily") {
      date.setDate(date.getDate() + 1)
    } else if (type === "weekly") {
      date.setDate(date.getDate() + 7)
    } else if (type === "monthly") {
      date.setMonth(date.getMonth() + 1)
    } else {
      date.setMonth(date.getMonth() + 3)
    }
    return date.toISOString().split('T')[0]
  }

  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState<CreateGoalRequest>({
    goal_type: "weekly",
    title: "",
    description: "",
    target_value: 10,
    target_unit: "exercises",
    end_date: getDefaultEndDate("weekly"),
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      // Clean up the data before sending
      const cleanedData: CreateGoalRequest = {
        goal_type: formData.goal_type,
        title: formData.title.trim(),
        target_value: formData.target_value,
        target_unit: formData.target_unit.trim(),
        end_date: formData.end_date,
      }

      // Only add optional fields if they have values
      if (formData.description?.trim()) {
        cleanedData.description = formData.description.trim()
      }
      if (formData.skill_type && formData.skill_type !== "all") {
        cleanedData.skill_type = formData.skill_type
      }

      console.log('[CreateGoal] Submitting data:', cleanedData)
      await goalsApi.createGoal(cleanedData)
      toast({
        title: t('goal_created'),
        description: tCommon('success'),
      })
      // Reset form
      setFormData({
        goal_type: "weekly",
        title: "",
        description: "",
        target_value: 10,
        target_unit: "exercises",
        end_date: getDefaultEndDate("weekly"),
      })
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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto" aria-describedby={undefined}>
        <DialogHeader>
          <DialogTitle>{t('create_goal')}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit}>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="goal_type">{t('goal_type')}</Label>
              <Select
                value={formData.goal_type}
                onValueChange={(value: any) => {
                  setFormData({
                    ...formData,
                    goal_type: value,
                    end_date: getDefaultEndDate(value),
                  })
                }}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">{t('daily')}</SelectItem>
                  <SelectItem value="weekly">{t('weekly')}</SelectItem>
                  <SelectItem value="monthly">{t('monthly')}</SelectItem>
                  <SelectItem value="custom">{t('custom')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="title">{t('goal_title')}</Label>
              <Input
                id="title"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder={t('goal_title_placeholder')}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">{t('description')}</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder={t('description_placeholder')}
                rows={3}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="target_value">{t('target_value')}</Label>
                <Input
                  id="target_value"
                  type="number"
                  min="1"
                  value={formData.target_value}
                  onChange={(e) => setFormData({ ...formData, target_value: parseInt(e.target.value) || 0 })}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="target_unit">{t('target_unit')}</Label>
                <Input
                  id="target_unit"
                  value={formData.target_unit}
                  onChange={(e) => setFormData({ ...formData, target_unit: e.target.value })}
                  placeholder={t('target_unit_placeholder')}
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="skill_type">{t('skill_type')}</Label>
              <Select
                value={formData.skill_type || "all"}
                onValueChange={(value) => setFormData({ ...formData, skill_type: value === "all" ? undefined : value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder={tCommon('select') || "Select..."} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{tCommon('all') || "All"}</SelectItem>
                  <SelectItem value="listening">{t('listening') || "Listening"}</SelectItem>
                  <SelectItem value="reading">{t('reading') || "Reading"}</SelectItem>
                  <SelectItem value="writing">{t('writing') || "Writing"}</SelectItem>
                  <SelectItem value="speaking">{t('speaking') || "Speaking"}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="end_date">{t('end_date')}</Label>
              <Input
                id="end_date"
                type="date"
                value={formData.end_date || getDefaultEndDate(formData.goal_type)}
                onChange={(e) => setFormData({ ...formData, end_date: e.target.value })}
                min={new Date().toISOString().split('T')[0]}
                required
              />
            </div>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              {tCommon('cancel')}
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? tCommon('loading') : t('create_goal')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

