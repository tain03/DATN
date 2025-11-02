"use client"

import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { cn } from "@/lib/utils"

interface SkeletonCardProps {
  /**
   * Show header skeleton
   * @default true
   */
  showHeader?: boolean
  /**
   * Show content lines
   * @default 3
   */
  lines?: number
  /**
   * Show image placeholder
   * @default false
   */
  showImage?: boolean
  /**
   * Custom className
   */
  className?: string
}

/**
 * SkeletonCard - Loading skeleton for cards
 * 
 * Provides consistent skeleton loading for card-based content
 */
export function SkeletonCard({ 
  showHeader = true, 
  lines = 3,
  showImage = false,
  className 
}: SkeletonCardProps) {
  return (
    <Card className={className}>
      {showHeader && (
        <CardHeader className="space-y-2">
          <Skeleton className="h-5 w-3/4" />
          <Skeleton className="h-4 w-1/2" />
        </CardHeader>
      )}
      
      <CardContent className="space-y-3">
        {showImage && (
          <Skeleton className="h-48 w-full rounded-lg mb-4" />
        )}
        
        {Array.from({ length: lines }).map((_, i) => (
          <Skeleton 
            key={i} 
            className={cn(
              "h-4",
              i === lines - 1 ? "w-3/4" : "w-full"
            )} 
          />
        ))}
      </CardContent>
    </Card>
  )
}

/**
 * SkeletonCardGrid - Grid of skeleton cards
 */
interface SkeletonCardGridProps {
  /**
   * Number of cards
   * @default 3
   */
  count?: number
  /**
   * Grid columns (responsive)
   * @default "grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
   */
  columns?: string
  /**
   * Card props
   */
  cardProps?: Omit<SkeletonCardProps, 'className'>
}

export function SkeletonCardGrid({ 
  count = 3, 
  columns = "grid-cols-1 md:grid-cols-2 lg:grid-cols-3",
  cardProps 
}: SkeletonCardGridProps) {
  return (
    <div className={cn("grid gap-4", columns)}>
      {Array.from({ length: count }).map((_, i) => (
        <SkeletonCard key={i} {...cardProps} />
      ))}
    </div>
  )
}


