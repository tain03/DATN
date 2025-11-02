import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

/**
 * Card Variants - Consistent card styling patterns
 * 
 * Provides reusable card variant classes for consistent styling
 * across the application.
 */

export const cardVariants = {
  /**
   * Default card - Basic card with subtle shadow
   */
  default: "bg-card border shadow-sm",
  
  /**
   * Interactive card - Hover effects for clickable cards
   */
  interactive: twMerge(
    "bg-card border shadow-sm",
    "hover:shadow-lg hover:-translate-y-0.5",
    "transition-all duration-200 cursor-pointer"
  ),
  
  /**
   * Highlight card - Subtle gradient background
   */
  highlight: "bg-gradient-to-br from-card to-accent/30 border shadow-sm",
  
  /**
   * Gradient cards with color variants
   */
  gradient: {
    blue: twMerge(
      "bg-gradient-to-br from-white to-blue-50/50",
      "dark:from-card dark:to-blue-950/10",
      "border shadow-sm"
    ),
    green: twMerge(
      "bg-gradient-to-br from-white to-green-50/50",
      "dark:from-card dark:to-green-950/10",
      "border shadow-sm"
    ),
    purple: twMerge(
      "bg-gradient-to-br from-white to-purple-50/50",
      "dark:from-card dark:to-purple-950/10",
      "border shadow-sm"
    ),
    orange: twMerge(
      "bg-gradient-to-br from-white to-orange-50/50",
      "dark:from-card dark:to-orange-950/10",
      "border shadow-sm"
    ),
  },
} as const

/**
 * Helper function to merge card variant with custom classes
 */
export function getCardVariant(
  variant: keyof typeof cardVariants | { gradient: keyof typeof cardVariants.gradient },
  customClasses?: ClassValue
) {
  let variantClasses: string
  
  if (typeof variant === 'object' && 'gradient' in variant) {
    variantClasses = cardVariants.gradient[variant.gradient]
  } else {
    variantClasses = cardVariants[variant as keyof typeof cardVariants]
  }
  
  return twMerge(variantClasses, typeof customClasses === 'string' ? customClasses : clsx(customClasses))
}

// Re-export cn utility
export { cn } from "@/lib/utils"

