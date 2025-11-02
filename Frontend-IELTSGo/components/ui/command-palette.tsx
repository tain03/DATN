"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import { useTranslations } from "@/lib/i18n"
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogHeader, 
  DialogTitle 
} from "@/components/ui/dialog"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList, CommandSeparator, CommandShortcut } from "@/components/ui/command"
import { 
  LayoutDashboard, 
  BookOpen, 
  Target, 
  BarChart3, 
  History, 
  Settings, 
  User, 
  Trophy,
  Search,
  FileText,
  MessageSquare
} from "lucide-react"
import { cn } from "@/lib/utils"

interface CommandPaletteProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

interface SearchItem {
  id: string
  label: string
  icon: React.ComponentType<{ className?: string }>
  href: string
  keywords?: string[]
  group: string
}

/**
 * CommandPalette - Global search with Command palette (⌘K)
 * 
 * Features:
 * - Keyboard shortcut (⌘K / Ctrl+K)
 * - Search across pages and features
 * - Quick navigation
 * - Keyboard navigation
 */
export function CommandPalette({ open, onOpenChange }: CommandPaletteProps) {
  const router = useRouter()
  const t = useTranslations('common')

  // Define searchable items
  const searchItems: SearchItem[] = [
    // Main pages
    {
      id: "dashboard",
      label: t('dashboard') || "Dashboard",
      icon: LayoutDashboard,
      href: "/dashboard",
      keywords: ["dashboard", "home", "main"],
      group: "Pages"
    },
    {
      id: "courses",
      label: t('courses') || "Courses",
      icon: BookOpen,
      href: "/my-courses",
      keywords: ["courses", "lessons", "learning"],
      group: "Pages"
    },
    {
      id: "exercises",
      label: t('exercises') || "Exercises",
      icon: Target,
      href: "/my-exercises",
      keywords: ["exercises", "practice", "tests"],
      group: "Pages"
    },
    {
      id: "goals",
      label: "Goals",
      icon: Target,
      href: "/goals",
      keywords: ["goals", "targets", "objectives"],
      group: "Pages"
    },
    {
      id: "progress",
      label: "Progress",
      icon: BarChart3,
      href: "/progress",
      keywords: ["progress", "analytics", "stats", "performance"],
      group: "Pages"
    },
    {
      id: "history",
      label: "History",
      icon: History,
      href: "/history",
      keywords: ["history", "timeline", "activity"],
      group: "Pages"
    },
    {
      id: "profile",
      label: t('profile') || "Profile",
      icon: User,
      href: "/profile",
      keywords: ["profile", "account", "settings"],
      group: "Account"
    },
    {
      id: "settings",
      label: t('settings') || "Settings",
      icon: Settings,
      href: "/settings",
      keywords: ["settings", "preferences", "config"],
      group: "Account"
    },
    {
      id: "leaderboard",
      label: t('leaderboard') || "Leaderboard",
      icon: Trophy,
      href: "/leaderboard",
      keywords: ["leaderboard", "ranking", "scores"],
      group: "Social"
    },
  ]

  const [search, setSearch] = React.useState("")

  // Filter items based on search
  const filteredItems = React.useMemo(() => {
    if (!search) return searchItems

    const lowerSearch = search.toLowerCase()
    return searchItems.filter(item => {
      const matchLabel = item.label.toLowerCase().includes(lowerSearch)
      const matchKeywords = item.keywords?.some(kw => kw.toLowerCase().includes(lowerSearch))
      return matchLabel || matchKeywords
    })
  }, [search])

  // Group items by group
  const groupedItems = React.useMemo(() => {
    const groups: Record<string, SearchItem[]> = {}
    filteredItems.forEach(item => {
      if (!groups[item.group]) {
        groups[item.group] = []
      }
      groups[item.group].push(item)
    })
    return groups
  }, [filteredItems])

  const handleSelect = (item: SearchItem) => {
    router.push(item.href)
    onOpenChange(false)
    setSearch("")
  }

  // Keyboard shortcut handler
  React.useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        onOpenChange(true)
      }
    }

    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [onOpenChange])

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="overflow-hidden p-0 sm:max-w-[640px]">
        <DialogHeader className="px-4 pb-4 pt-5 sm:px-6 sm:pt-6">
          <DialogTitle className="text-lg font-semibold">
            {t('search') || "Search"}
          </DialogTitle>
          <DialogDescription className="text-sm text-muted-foreground">
            {t('search_description') || "Quickly navigate to pages and features"}
          </DialogDescription>
        </DialogHeader>
        <Command className="rounded-lg border-none">
          <CommandInput 
            placeholder={t('search_placeholder') || "Search pages, courses, exercises..."}
            value={search}
            onValueChange={setSearch}
          />
          <CommandList>
            <CommandEmpty>
              <div className="flex flex-col items-center justify-center py-6 text-center">
                <Search className="h-8 w-8 text-muted-foreground mb-2" />
                <p className="text-sm text-muted-foreground">
                  {t('no_results_found') || "No results found"}
                </p>
              </div>
            </CommandEmpty>
            {Object.entries(groupedItems).map(([group, items]) => (
              <React.Fragment key={group}>
                <CommandGroup heading={group}>
                  {items.map((item) => {
                    const Icon = item.icon
                    return (
                      <CommandItem
                        key={item.id}
                        value={item.id}
                        onSelect={() => handleSelect(item)}
                        className="cursor-pointer"
                      >
                        <Icon className="mr-2 h-4 w-4 text-muted-foreground" />
                        <span>{item.label}</span>
                        <CommandShortcut>
                          {item.href.includes("dashboard") && "⌘D"}
                          {item.href.includes("courses") && "⌘C"}
                          {item.href.includes("exercises") && "⌘E"}
                          {item.href.includes("settings") && "⌘,"}
                        </CommandShortcut>
                      </CommandItem>
                    )
                  })}
                </CommandGroup>
                <CommandSeparator />
              </React.Fragment>
            ))}
          </CommandList>
        </Command>
      </DialogContent>
    </Dialog>
  )
}

/**
 * useCommandPalette - Hook to manage command palette state
 */
export function useCommandPalette() {
  const [open, setOpen] = React.useState(false)

  return {
    open,
    setOpen,
    toggle: () => setOpen(prev => !prev),
  }
}

