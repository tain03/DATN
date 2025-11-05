"use client"

import { useState, useEffect } from "react"
import { goalsApi, type StudyGoal } from "@/lib/api/goals"
import { GoalCard } from "./goal-card"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"
import { Skeleton } from "@/components/ui/skeleton"
import { EmptyState } from "@/components/ui/empty-state"
import { Target } from "lucide-react"

export function GoalsList() {
  const t = useTranslations('goals')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [goals, setGoals] = useState<StudyGoal[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadGoals()
  }, [])

  const loadGoals = async () => {
    try {
      setLoading(true)
      const response = await goalsApi.getGoals()
      setGoals(response.goals || [])
    } catch (error: any) {
      console.error('[GoalsList] Error loading goals:', error)
      // Don't show error toast for empty goals (might be 404 or similar)
      // Just set empty array
      setGoals([])
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (goalId: string) => {
    try {
      await goalsApi.deleteGoal(goalId)
      setGoals(goals.filter(g => g.id !== goalId))
      toast({
        title: t('goal_deleted'),
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

  const handleComplete = async (goalId: string) => {
    try {
      const updated = await goalsApi.completeGoal(goalId)
      setGoals(goals.map(g => g.id === goalId ? updated : g))
      toast({
        title: t('goal_completed'),
        description: tCommon('success'),
      })
    } catch (error: any) {
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_complete'),
        variant: "destructive",
      })
    }
  }

  const handleUpdate = async () => {
    // Refresh list after update
    await loadGoals()
  }

  if (loading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="h-32 w-full" />
        ))}
      </div>
    )
  }

  if (goals.length === 0) {
    return (
      <EmptyState
        icon={Target}
        title={t('no_goals') || 'No goals yet'}
        description={t('no_goals_description') || 'Create your first study goal to start tracking your progress!'}
      />
    )
  }

  // Group goals by status (match DB schema: active, completed, cancelled, expired)
  const active = goals.filter(g => g.status === 'active')
  const completed = goals.filter(g => g.status === 'completed')
  const expired = goals.filter(g => g.status === 'expired')
  const cancelled = goals.filter(g => g.status === 'cancelled')

  return (
    <div className="space-y-8">
      {/* Active Goals */}
      {active.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4">{t('active') || 'Active Goals'}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {active.map((goal) => (
              <GoalCard
                key={goal.id}
                goal={goal}
                onDelete={handleDelete}
                onComplete={handleComplete}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}

      {/* Completed Goals */}
      {completed.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4">{t('completed')}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {completed.map((goal) => (
              <GoalCard
                key={goal.id}
                goal={goal}
                onDelete={handleDelete}
                onComplete={handleComplete}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}

      {/* Expired Goals */}
      {expired.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4 text-muted-foreground">{t('expired') || 'Expired Goals'}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 opacity-60">
            {expired.map((goal) => (
              <GoalCard
                key={goal.id}
                goal={goal}
                onDelete={handleDelete}
                onComplete={handleComplete}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}

      {/* Cancelled Goals */}
      {cancelled.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold mb-4 text-muted-foreground">{t('cancelled') || 'Cancelled Goals'}</h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 opacity-60">
            {cancelled.map((goal) => (
              <GoalCard
                key={goal.id}
                goal={goal}
                onDelete={handleDelete}
                onComplete={handleComplete}
                onUpdate={handleUpdate}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

