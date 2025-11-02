"use client"

import { Button } from "@/components/ui/button"
import { LanguageSelector } from "@/components/layout/language-selector"
import { NotificationBell } from "@/components/notifications/notification-bell"
import { User, LogOut, Settings, BookOpen, ChevronDown } from "lucide-react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useAuth } from "@/lib/contexts/auth-context"
import { useTranslations } from "@/lib/i18n"
import { cn } from "@/lib/utils"
import Link from "next/link"

interface DashboardHeaderProps {
  welcomeMessage: string
  subtitle: string
  timeRange: "7d" | "30d" | "90d" | "all"
  onTimeRangeChange: (range: "7d" | "30d" | "90d" | "all") => void
  timeRangeLabels: {
    "7d": string
    "30d": string
    "90d": string
    "all": string
  }
}

export function DashboardHeader({
  welcomeMessage,
  subtitle,
  timeRange,
  onTimeRangeChange,
  timeRangeLabels,
}: DashboardHeaderProps) {
  const { user, logout } = useAuth()
  const t = useTranslations('common')

  const handleLogout = async () => {
    try {
      await logout()
    } catch (error) {
      console.error("Logout failed:", error)
    }
  }

  const getUserInitials = () => {
    if (!user?.fullName || !user.fullName.trim()) return "U"
    return user.fullName
      .trim()
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2)
  }

  return (
    <div className="sticky top-0 z-50 bg-background/95 backdrop-blur-md border-b border-border h-16 flex items-center">
      <div className="w-full px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-[1fr_auto_1fr] lg:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center h-full gap-4 lg:gap-6">
          {/* Left: Welcome & Subtitle */}
          <div className="min-w-0">
            <h1 className="text-xl sm:text-2xl font-bold tracking-tight truncate">
              {welcomeMessage}
            </h1>
            <p className="text-sm text-muted-foreground hidden sm:block mt-0.5 truncate">
              {subtitle}
            </p>
          </div>

          {/* Center: Time Range Filters */}
          <div className="hidden md:flex items-center gap-0.5 px-1.5 py-1 bg-muted/60 rounded-lg border border-border/50 flex-shrink-0">
            {(["7d", "30d", "90d", "all"] as const).map((range) => (
              <Button
                key={range}
                variant="ghost"
                size="sm"
                onClick={() => onTimeRangeChange(range)}
                className={cn(
                  "h-7 px-3 text-xs font-medium transition-all rounded-md",
                  timeRange === range
                    ? "bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
                    : "hover:bg-muted/80 text-muted-foreground hover:text-foreground"
                )}
              >
                {timeRangeLabels[range]}
              </Button>
            ))}
          </div>

          {/* Right: Actions (Language, Notifications, User Menu) + Mobile Time Range */}
          <div className="flex items-center gap-2 justify-end flex-shrink-0">
            {/* Mobile Time Range - Dropdown */}
            <div className="md:hidden">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm" className="text-xs">
                    {timeRangeLabels[timeRange]}
                    <ChevronDown className="ml-1.5 h-3.5 w-3.5" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {(["7d", "30d", "90d", "all"] as const).map((range) => (
                    <DropdownMenuItem
                      key={range}
                      onClick={() => onTimeRangeChange(range)}
                      className={timeRange === range ? "bg-accent" : ""}
                    >
                      {timeRangeLabels[range]}
                    </DropdownMenuItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            {/* Language Selector */}
            <LanguageSelector />

            {/* Notifications */}
            <NotificationBell />

            {/* User Menu */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button 
                  variant="ghost" 
                  className="relative h-9 w-9 rounded-full p-0 hover:bg-accent transition-colors"
                >
                  <Avatar className="h-9 w-9 cursor-pointer border-2 border-transparent hover:border-primary/20 transition-colors">
                    <AvatarImage src={user?.avatar || "/placeholder.svg"} alt={user?.fullName} />
                    <AvatarFallback className="bg-primary/10 text-primary font-semibold text-xs">
                      {getUserInitials()}
                    </AvatarFallback>
                  </Avatar>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuLabel>
                  {user ? (
                    <Link 
                      href={`/users/${user.id}`}
                      className="flex flex-col space-y-1 hover:opacity-80 transition-opacity cursor-pointer"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <p className="text-sm font-medium leading-none">
                        {user.fullName || "Người dùng"}
                      </p>
                      <p className="text-xs leading-none text-muted-foreground">{user.email}</p>
                    </Link>
                  ) : (
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-medium leading-none">Người dùng</p>
                      <p className="text-xs leading-none text-muted-foreground">-</p>
                    </div>
                  )}
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem asChild>
                  <Link href="/dashboard" className="cursor-pointer">
                    <BookOpen className="mr-2 h-4 w-4" />
                    {t('dashboard')}
                  </Link>
                </DropdownMenuItem>
                {user && (
                  <DropdownMenuItem asChild>
                    <Link href={`/users/${user.id}`} className="cursor-pointer flex items-center">
                      <User className="mr-2 h-4 w-4" />
                      {t('my_profile') || "Hồ sơ của tôi"}
                    </Link>
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem asChild>
                  <Link href="/settings" className="cursor-pointer">
                    <Settings className="mr-2 h-4 w-4" />
                    {t('settings')}
                  </Link>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleLogout} className="text-destructive cursor-pointer">
                  <LogOut className="mr-2 h-4 w-4" />
                  {t('logout')}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </div>
  )
}

