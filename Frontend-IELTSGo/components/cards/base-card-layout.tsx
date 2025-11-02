"use client"

import * as React from "react"
import Link from "next/link"
import Image from "next/image"
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { getCardVariant } from "@/lib/utils/card-variants"
import { cn } from "@/lib/utils"
import { CARD_CONFIG, type CardLayoutType } from "./card-config"
import type { LucideIcon } from "lucide-react"

/**
 * Base Vertical Card Layout
 * 
 * Standardized vertical card layout with image on top and content below.
 * Used for CourseCard, ExerciseCard, etc.
 */
interface VerticalCardLayoutProps {
  // Card props
  variant?: keyof typeof import("@/lib/utils/card-variants").cardVariants | "interactive" | "default"
  className?: string
  onClick?: () => void
  
  // Image props
  image?: {
    src?: string | null
    alt: string
    priority?: boolean
    overlay?: React.ReactNode // Badges, price, etc.
    placeholder?: {
      icon: LucideIcon
      text?: string
    }
  }
  
  // Content props
  title: string
  titleHref?: string
  description?: string | null
  content?: React.ReactNode // Custom content (stats, meta, etc.)
  
  // Footer props
  footer?: {
    action: string | React.ReactNode
    href?: string
    onClick?: (e: React.MouseEvent) => void
    variant?: "default" | "outline" | "ghost" | "destructive"
  }
  
  // Progress (optional)
  progress?: {
    value: number
    label?: string
  }
  
  children?: React.ReactNode // For additional custom content
}

export function VerticalCardLayout({
  variant = "interactive",
  className,
  onClick,
  image,
  title,
  titleHref,
  description,
  content,
  footer,
  progress,
  children,
}: VerticalCardLayoutProps) {
  const padding = CARD_CONFIG.padding.vertical
  const typography = CARD_CONFIG.typography
  const imageConfig = CARD_CONFIG.image.vertical

  const CardWrapper = onClick ? "div" : "div"
  const cardProps = onClick ? { onClick, role: "button", tabIndex: 0, onKeyDown: (e: React.KeyboardEvent) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      onClick()
    }
  } } : {}

  return (
    <Card
      className={cn(
        "group overflow-hidden",
        padding.card,
        getCardVariant(variant as any),
        className
      )}
      {...cardProps}
    >
      {/* Image Section */}
      {image && (
        <div className={imageConfig.className}>
          {image.src ? (
            <>
              <Image
                src={image.src}
                alt={image.alt}
                fill
                className="object-cover group-hover:scale-105 transition-transform duration-300"
                sizes={imageConfig.sizes}
                priority={image.priority}
              />
              {image.overlay}
            </>
          ) : (
            <div className={CARD_CONFIG.image.placeholder.className}>
              {image.placeholder ? (
                <>
                  <image.placeholder.icon className={cn(
                    CARD_CONFIG.image.placeholder.iconSize,
                    CARD_CONFIG.image.placeholder.iconColor
                  )} />
                  {image.placeholder.text && (
                    <span className={typography.stats.className}>{image.placeholder.text}</span>
                  )}
                </>
              ) : (
                <div className={cn(
                  CARD_CONFIG.image.placeholder.iconSize,
                  CARD_CONFIG.image.placeholder.iconColor
                )} />
              )}
            </div>
          )}
        </div>
      )}

      {/* Content Section */}
      <CardContent className={padding.content}>
        {titleHref ? (
          <Link href={titleHref}>
            <h3 className={cn(
              typography.title.className,
              "group-hover:text-primary transition-colors"
            )}>
              {title}
            </h3>
          </Link>
        ) : (
          <h3 className={typography.title.className}>{title}</h3>
        )}

        {description && (
          <p className={typography.description.className}>
            {description}
          </p>
        )}

        {content}

        {progress && (
          <div className="mt-3">
            <div className="flex justify-between text-sm mb-1">
              <span className={typography.stats.className}>{progress.label || "Progress"}</span>
              <span className="font-medium">{progress.value}%</span>
            </div>
            <div className="w-full bg-muted rounded-full h-2">
              <div
                className="bg-primary h-2 rounded-full transition-all"
                style={{ width: `${progress.value}%` }}
              />
            </div>
          </div>
        )}

        {children}
      </CardContent>

      {/* Footer Section */}
      {footer && (
        <CardFooter className={padding.footer}>
          {footer.href ? (
            <Button asChild variant={footer.variant} className={CARD_CONFIG.button.footer.className}>
              <Link href={footer.href}>{footer.action}</Link>
            </Button>
          ) : (
            <Button
              variant={footer.variant}
              className={CARD_CONFIG.button.footer.className}
              onClick={footer.onClick}
            >
              {footer.action}
            </Button>
          )}
        </CardFooter>
      )}
    </Card>
  )
}

/**
 * Base Horizontal Card Layout
 * 
 * Standardized horizontal card layout with thumbnail on left and content on right.
 * Used for my-courses, my-exercises tabs.
 */
interface HorizontalCardLayoutProps {
  // Card props
  variant?: keyof typeof import("@/lib/utils/card-variants").cardVariants | "interactive" | "default"
  className?: string
  onClick?: () => void
  
  // Thumbnail props
  thumbnail?: {
    src?: string | null
    alt: string
    placeholder?: {
      icon: LucideIcon
      text?: string
    }
  }
  
  // Content props
  title: string
  description?: string | null
  badges?: React.ReactNode // Badges on the right side of title
  stats?: React.ReactNode // Stats row (icons + text)
  
  // Progress (optional)
  progress?: {
    value: number
    label?: string
  }
  
  // Action button
  action?: {
    label: string | React.ReactNode
    onClick?: (e: React.MouseEvent) => void
    href?: string
    variant?: "default" | "outline" | "ghost" | "destructive"
  }
  
  children?: React.ReactNode // For additional custom content
}

export function HorizontalCardLayout({
  variant = "interactive",
  className,
  onClick,
  thumbnail,
  title,
  description,
  badges,
  stats,
  progress,
  action,
  children,
}: HorizontalCardLayoutProps) {
  const padding = CARD_CONFIG.padding.horizontal
  const typography = CARD_CONFIG.typography
  const imageConfig = CARD_CONFIG.image.horizontal
  const spacing = CARD_CONFIG.spacing

  const CardWrapper = onClick ? "div" : "div"
  const cardProps = onClick ? { onClick, role: "button", tabIndex: 0, onKeyDown: (e: React.KeyboardEvent) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      onClick()
    }
  } } : {}

  return (
    <Card
      className={cn(
        padding.card === "" ? "" : padding.card,
        getCardVariant(variant as any),
        className
      )}
      {...cardProps}
    >
      <CardContent className={padding.content}>
        <div className={cn("flex items-start", spacing.horizontalGap)}>
          {/* Thumbnail */}
          {thumbnail && (
            <div className={imageConfig.className}>
              {thumbnail.src ? (
                <Image
                  src={thumbnail.src}
                  alt={thumbnail.alt}
                  fill
                  className="object-cover"
                  sizes={imageConfig.sizes}
                />
              ) : (
                <div className={CARD_CONFIG.image.placeholder.className}>
                  {thumbnail.placeholder ? (
                    <>
                      <thumbnail.placeholder.icon className={cn(
                        CARD_CONFIG.image.placeholder.iconSize,
                        CARD_CONFIG.image.placeholder.iconColor
                      )} />
                      {thumbnail.placeholder.text && (
                        <span className={typography.stats.className}>{thumbnail.placeholder.text}</span>
                      )}
                    </>
                  ) : null}
                </div>
              )}
            </div>
          )}

          {/* Content */}
          <div className="flex-1">
            <div className="flex items-start justify-between mb-2">
              <div className="flex-1">
                <h3 className={cn(typography.title.className, "mb-1")}>
                  {title}
                </h3>
                {description && (
                  <p className={typography.description.className}>
                    {description}
                  </p>
                )}
              </div>
              {badges && (
                <div className="flex flex-col gap-2 ml-4 flex-shrink-0">
                  {badges}
                </div>
              )}
            </div>

            {/* Stats */}
            {stats && (
              <div className={cn("flex flex-wrap items-center gap-3", "mt-3", typography.stats.className)}>
                {stats}
              </div>
            )}

            {/* Progress */}
            {progress && (
              <div className="mt-4 space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className={typography.stats.className}>{progress.label || "Progress"}</span>
                  <span className="font-semibold">{progress.value}%</span>
                </div>
                <div className="w-full bg-muted rounded-full h-2">
                  <div
                    className="bg-primary h-2 rounded-full transition-all"
                    style={{ width: `${progress.value}%` }}
                  />
                </div>
              </div>
            )}

            {/* Action Button */}
            {action && (
              <div className="flex items-center justify-end mt-3">
                {action.href ? (
                  <Button 
                    asChild 
                    variant={action.variant || "default"} 
                    size="default"
                    className={cn("h-9 px-4 min-h-[44px] text-sm")}
                  >
                    <Link href={action.href}>{action.label}</Link>
                  </Button>
                ) : (
                  <Button
                    variant={action.variant || "default"}
                    size="default"
                    className={cn("h-9 px-4 min-h-[44px] text-sm")}
                    onClick={action.onClick}
                  >
                    {action.label}
                  </Button>
                )}
              </div>
            )}

            {children}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

