/**
 * Card Configuration - Centralized card design tokens
 * 
 * Tất cả các giá trị spacing, sizing, typography cho cards được định nghĩa ở đây
 * để dễ dàng thay đổi và mở rộng sau này.
 */

export const CARD_CONFIG = {
  /**
   * Padding configurations
   */
  padding: {
    /** Vertical cards (CourseCard, ExerciseCard) */
    vertical: {
      card: "p-0", // Remove base padding
      content: "p-4", // 16px all sides
      footer: "p-4 pt-0", // 16px, no top padding
    },
    
    /** Horizontal cards (my-courses, my-exercises) */
    horizontal: {
      card: "", // Keep base py-6, but remove horizontal padding
      content: "p-6", // 24px all sides
      footer: "p-6 pt-0", // 24px, no top padding (if used)
    },
    
    /** Goal cards (special layout) */
    goal: {
      card: "", // Keep base padding
      header: "pb-3", // 12px bottom
      content: "px-6 space-y-4", // Horizontal 24px, vertical spacing 16px
    },
    
    /** Stat cards (dashboard) */
    stat: {
      card: "", // Keep base padding
      content: "p-5", // 20px all sides
    },
  },

  /**
   * Spacing between card elements
   */
  spacing: {
    /** Gap between thumbnail and content in horizontal cards */
    horizontalGap: "gap-6", // 24px
    
    /** Gap between stats/meta items */
    metaGap: "gap-4", // 16px
    
    /** Vertical spacing in content sections */
    contentGap: "space-y-4", // 16px between children
  },

  /**
   * Typography configurations
   */
  typography: {
    title: {
      className: "font-semibold text-lg mb-2",
      size: "text-lg", // 18px
      weight: "font-semibold", // 600
      margin: "mb-2", // 8px bottom
    },
    
    description: {
      className: "text-sm text-muted-foreground line-clamp-2 mb-3",
      size: "text-sm", // 14px
      color: "text-muted-foreground",
      clamp: "line-clamp-2", // 2 lines max
      margin: "mb-3", // 12px bottom
    },
    
    stats: {
      className: "text-sm text-muted-foreground",
      size: "text-sm", // 14px
      color: "text-muted-foreground",
    },
  },

  /**
   * Image/Thumbnail configurations
   */
  image: {
    /** Vertical cards - responsive aspect ratio */
    vertical: {
      aspectRatio: "aspect-video", // 16:9
      className: "relative aspect-video overflow-hidden bg-muted",
      sizes: "(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw",
    },
    
    /** Horizontal cards - fixed size */
    horizontal: {
      width: "w-48", // 192px
      height: "h-32", // 128px
      className: "relative w-48 h-32 bg-muted rounded-lg flex-shrink-0 overflow-hidden",
      sizes: "192px", // For Next.js Image optimization
    },
    
    /** Placeholder styling */
    placeholder: {
      className: "w-full h-full flex items-center justify-center bg-gradient-to-br from-primary/20 to-accent/20",
      iconSize: "w-16 h-16", // 64px
      iconColor: "text-muted-foreground",
    },
  },

  /**
   * Button configurations
   */
  button: {
    /** Button in card footer (vertical cards) */
    footer: {
      className: "w-full",
      width: "w-full",
    },
    
    /** Button in card content (horizontal cards) */
    content: {
      className: "mt-3 h-9 text-sm", // Smaller, more refined button
      width: "w-auto", // Auto width instead of full width
      margin: "mt-3", // 12px top (smaller gap)
    },
  },

  /**
   * Layout configurations
   */
  layout: {
    /** Grid for vertical cards */
    verticalGrid: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6",
    
    /** Grid for horizontal cards */
    horizontalGrid: "grid grid-cols-1 gap-4",
  },
} as const

/**
 * Card variant configurations
 */
export const CARD_VARIANTS = {
  /** Interactive cards - for clickable cards */
  interactive: "interactive",
  
  /** Default cards - basic display cards */
  default: "default",
  
  /** Highlight cards - special emphasis */
  highlight: "highlight",
} as const

/**
 * Card layout types
 */
export type CardLayoutType = "vertical" | "horizontal" | "goal" | "stat"

/**
 * Get padding configuration for a specific layout type
 */
export function getCardPadding(layout: CardLayoutType) {
  return CARD_CONFIG.padding[layout] || CARD_CONFIG.padding.vertical
}

/**
 * Get typography class names
 */
export function getCardTypography(type: "title" | "description" | "stats") {
  return CARD_CONFIG.typography[type].className
}

/**
 * Get image configuration for layout type
 */
export function getCardImageConfig(layout: "vertical" | "horizontal") {
  return CARD_CONFIG.image[layout]
}

