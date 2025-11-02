"use client"

import { Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"

interface PageLoadingProps {
  /**
   * Loading message to display (translation key or custom message)
   * If not provided, will use translation key 'loading'
   */
  message?: string
  /**
   * Use translation key instead of direct message
   */
  translationKey?: string
  /**
   * Custom className
   */
  className?: string
  /**
   * Size of the spinner
   * @default "lg"
   */
  size?: "sm" | "md" | "lg"
  /**
   * Show animated dots
   * @default true
   */
  showDots?: boolean
}

/**
 * PageLoading - Enhanced loading state component
 * 
 * Provides consistent loading experience across all pages with:
 * - Centered spinner
 * - Loading message (with i18n support)
 * - Optional animated dots
 */
export function PageLoading({ 
  message,
  translationKey,
  className,
  size = "lg",
  showDots = true 
}: PageLoadingProps) {
  const t = useTranslations('common')
  
  // Use translation if translationKey provided, otherwise use message or fallback
  const loadingMessage = translationKey 
    ? t(translationKey) 
    : message || t('loading') || "Đang tải..."

  const sizeClasses = {
    sm: "h-6 w-6",
    md: "h-10 w-10",
    lg: "h-12 w-12",
  }

  return (
    <div className={cn(
      "flex flex-col items-center justify-center h-64 space-y-4",
      className
    )}>
      <Loader2 className={cn(
        "animate-spin text-primary",
        sizeClasses[size]
      )} />
      
      <p className="text-muted-foreground text-sm">{loadingMessage}</p>
      
      {showDots && (
        <div className="flex gap-1.5 mt-2">
          <div 
            className="w-2 h-2 bg-primary rounded-full animate-bounce" 
            style={{ animationDelay: '0ms' }} 
          />
          <div 
            className="w-2 h-2 bg-primary rounded-full animate-bounce" 
            style={{ animationDelay: '150ms' }} 
          />
          <div 
            className="w-2 h-2 bg-primary rounded-full animate-bounce" 
            style={{ animationDelay: '300ms' }} 
          />
        </div>
      )}
    </div>
  )
}
