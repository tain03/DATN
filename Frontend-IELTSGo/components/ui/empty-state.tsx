"use client"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import { LucideIcon } from "lucide-react"
import Link from "next/link"

interface EmptyStateProps {
  /**
   * Icon to display (Lucide icon)
   */
  icon: LucideIcon
  /**
   * Title text
   */
  title: string
  /**
   * Description text
   */
  description: string
  /**
   * Action button label
   */
  actionLabel?: string
  /**
   * Action button href (for Link) or onClick handler
   */
  actionHref?: string
  actionOnClick?: () => void
  /**
   * Custom icon size
   * @default "lg"
   */
  iconSize?: "sm" | "md" | "lg"
  /**
   * Custom className
   */
  className?: string
  /**
   * Show illustration background
   * @default true
   */
  showIllustration?: boolean
}

/**
 * EmptyState - Improved empty state component
 * 
 * Provides consistent empty state experience with:
 * - Icon with optional illustration background
 * - Title and description
 * - Optional action button
 */
export function EmptyState({
  icon: Icon,
  title,
  description,
  actionLabel,
  actionHref,
  actionOnClick,
  iconSize = "lg",
  className,
  showIllustration = true,
}: EmptyStateProps) {
  const iconSizeClasses = {
    sm: "h-8 w-8",
    md: "h-10 w-10",
    lg: "h-12 w-12",
  }

  const iconContainerSizeClasses = {
    sm: "p-3",
    md: "p-4",
    lg: "p-6",
  }

  const ActionButton = actionHref ? (
    <Button asChild size="sm" className="gap-2">
      <Link href={actionHref}>
        {actionLabel}
      </Link>
    </Button>
  ) : actionOnClick && actionLabel ? (
    <Button onClick={actionOnClick} size="sm" className="gap-2">
      {actionLabel}
    </Button>
  ) : null

  return (
    <Card className={cn("bg-card", className)}>
      <CardContent className={cn(
        "py-12 sm:py-16 text-center",
        className
      )}>
        {/* Icon with optional illustration */}
        <div className="flex justify-center mb-6">
          {showIllustration ? (
            <div className="relative">
              {/* Background gradient */}
              <div className="absolute inset-0 bg-gradient-to-br from-primary/10 to-primary/5 rounded-full blur-2xl" />
              
              {/* Icon container */}
              <div className={cn(
                "relative bg-muted/50 rounded-full flex items-center justify-center",
                iconContainerSizeClasses[iconSize]
              )}>
                <Icon className={cn(
                  "text-muted-foreground",
                  iconSizeClasses[iconSize]
                )} />
              </div>
            </div>
          ) : (
            <div className={cn(
              "bg-muted/50 rounded-full flex items-center justify-center",
              iconContainerSizeClasses[iconSize]
            )}>
              <Icon className={cn(
                "text-muted-foreground",
                iconSizeClasses[iconSize]
              )} />
            </div>
          )}
        </div>

        {/* Title */}
        <h3 className="text-lg font-semibold mb-2">{title}</h3>
        
        {/* Description */}
        <p className="text-sm text-muted-foreground mb-6 max-w-md mx-auto">
          {description}
        </p>

        {/* Action Button */}
        {ActionButton}
      </CardContent>
    </Card>
  )
}


