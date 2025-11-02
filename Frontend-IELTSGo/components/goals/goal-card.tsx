"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { getCardVariant } from "@/lib/utils/card-variants"
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { MoreVertical, Edit, Trash2, CheckCircle2, Target } from "lucide-react"
import { type StudyGoal } from "@/lib/api/goals"
import { useTranslations } from "@/lib/i18n"
import { cn } from "@/lib/utils"

interface GoalCardProps {
  goal: StudyGoal
  onDelete: (goalId: string) => void
  onComplete: (goalId: string) => void
  onUpdate: () => void
}

export function GoalCard({ goal, onDelete, onComplete, onUpdate }: GoalCardProps) {
  const t = useTranslations('goals')
  const tCommon = useTranslations('common')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [completeDialogOpen, setCompleteDialogOpen] = useState(false)

  const completionPercentage = goal.completion_percentage ?? 
    (goal.target_value > 0 ? Math.min((goal.current_value / goal.target_value) * 100, 100) : 0)

  const getStatusBadge = () => {
    if (goal.status === "completed") {
      return <Badge variant="default" className="bg-green-500">{t('completed')}</Badge>
    } else if (goal.status === "in_progress") {
      return <Badge variant="default" className="bg-blue-500">{t('in_progress')}</Badge>
    }
    return <Badge variant="outline">{t('not_started')}</Badge>
  }

  const getGoalTypeLabel = () => {
    switch (goal.goal_type) {
      case "daily": return t('daily')
      case "weekly": return t('weekly')
      case "monthly": return t('monthly')
      case "custom": return t('custom')
      default: return goal.goal_type
    }
  }

  return (
    <>
      <Card className={cn(
        getCardVariant('interactive'),
        goal.status === "completed" && "border-green-200 dark:border-green-800"
      )}>
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex-1 min-w-0">
              <CardTitle className="font-semibold text-lg mb-2 line-clamp-2">{goal.title}</CardTitle>
              <div className="flex items-center gap-2 flex-wrap">
                {getStatusBadge()}
                <Badge variant="outline" className="text-xs">{getGoalTypeLabel()}</Badge>
                {goal.skill_type && (
                  <Badge variant="outline" className="text-xs capitalize">
                    {t(goal.skill_type.toLowerCase() as 'listening' | 'reading' | 'writing' | 'speaking') || goal.skill_type}
                  </Badge>
                )}
              </div>
            </div>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon">
                  <MoreVertical className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={() => onUpdate()}>
                  <Edit className="h-4 w-4 mr-2" />
                  {t('edit_goal')}
                </DropdownMenuItem>
                {goal.status !== "completed" && (
                  <DropdownMenuItem onClick={() => setCompleteDialogOpen(true)}>
                    <CheckCircle2 className="h-4 w-4 mr-2" />
                    {t('complete_goal')}
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem 
                  onClick={() => setDeleteDialogOpen(true)}
                  className="text-destructive"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  {t('delete_goal')}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {goal.description && (
            <p className="text-sm text-muted-foreground line-clamp-2">{goal.description}</p>
          )}
          
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">{t('completion_percentage')}</span>
              <span className="font-semibold">{completionPercentage.toFixed(0)}%</span>
            </div>
            <Progress value={completionPercentage} className="h-2" />
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>
                {goal.current_value} / {goal.target_value} {goal.target_unit}
              </span>
              {goal.days_remaining !== undefined && goal.days_remaining > 0 && (
                <span>{goal.days_remaining} {t('days')} {t('days_remaining')}</span>
              )}
            </div>
          </div>

          {goal.end_date && (
            <div className="text-xs text-muted-foreground">
              {t('end_date')}: {new Date(goal.end_date).toLocaleDateString()}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('delete_goal')}</AlertDialogTitle>
            <AlertDialogDescription>{t('delete_confirm')}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{tCommon('cancel')}</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                onDelete(goal.id)
                setDeleteDialogOpen(false)
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {t('delete_goal')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Complete Confirmation Dialog */}
      <AlertDialog open={completeDialogOpen} onOpenChange={setCompleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t('complete_goal')}</AlertDialogTitle>
            <AlertDialogDescription>{t('complete_confirm')}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{tCommon('cancel')}</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                onComplete(goal.id)
                setCompleteDialogOpen(false)
              }}
            >
              {t('complete_goal')}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}

