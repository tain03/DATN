"use client"

import React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { LucideIcon } from "lucide-react"
import { cn } from "@/lib/utils"
import { useTranslations } from '@/lib/i18n'

interface StatCardProps {
  title: string
  value: string | number
  description?: string
  icon: LucideIcon
  trend?: {
    value: number
    isPositive: boolean
  }
  className?: string
}

function StatCardComponent({ title, value, description, icon: Icon, trend, className }: StatCardProps) {
  const t = useTranslations('common')
  return (
    <Card className={cn(
      "group relative overflow-hidden border transition-all duration-200",
      "hover:shadow-md hover:border-primary/20 bg-card",
      className
    )}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
        <CardTitle className="text-xs font-medium text-muted-foreground uppercase tracking-wide">{title}</CardTitle>
        <div className="p-1.5 rounded-md bg-muted/50 group-hover:bg-primary/10 transition-colors">
          <Icon className="h-3.5 w-3.5 text-muted-foreground group-hover:text-primary transition-colors" />
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        <div className="text-2xl font-bold tracking-tight mb-1.5">{value}</div>
        {description && (
          <p className="text-xs text-muted-foreground leading-relaxed">{description}</p>
        )}
        {trend && (
          <div className="flex items-center gap-1.5 mt-2 pt-2 border-t border-border/50">
            <span className={cn(
              "text-xs font-semibold",
              trend.isPositive ? "text-green-600 dark:text-green-500" : "text-red-600 dark:text-red-500"
            )}>
              {trend.isPositive ? "↑" : "↓"} {trend.isPositive ? "+" : ""}{trend.value}%
            </span>
            <span className="text-[10px] text-muted-foreground">{t('from_last_period')}</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export const StatCard = React.memo(StatCardComponent)
