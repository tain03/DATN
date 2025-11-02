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
import type { ReactNode } from "react"

interface PageHeaderProps {
  /**
   * Main title displayed on the left side
   */
  title: string
  /**
   * Optional subtitle displayed below title
   */
  subtitle?: string
  /**
   * Optional action buttons or filters displayed in the center
   * Can be used for time range filters, filter buttons, etc.
   */
  centerContent?: ReactNode
  /**
   * Optional additional actions on the right (besides default actions)
   */
  rightActions?: ReactNode
  /**
   * Custom className for the header container
   */
  className?: string
}

/**
 * PageHeader - Consistent header component for all sidebar pages
 * 
 * Provides a unified header design across Dashboard, My Courses, Progress, etc.
 * Includes:
 * - Left: Title and optional subtitle
 * - Center: Optional filters/actions (e.g., time range filters)
 * - Right: Language, Notifications, User menu, and optional custom actions
 * 
 * This replaces the basic TopBar for better consistency and context.
 */
export function PageHeader({
  title,
  subtitle,
  centerContent,
  rightActions,
  className,
}: PageHeaderProps) {
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
    <div className={cn(
      "sticky top-0 z-50 bg-background/95 backdrop-blur-md border-b border-border h-16 flex items-center",
      className
    )}>
      <div className="w-full px-4 sm:px-6 lg:px-8">
        {centerContent ? (
          // Layout với centerContent: 3 cột
          <div className="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center h-full gap-4 lg:gap-6">
            {/* Left: Title & Subtitle */}
            <div className="min-w-0">
              <h1 className="text-xl sm:text-2xl font-bold tracking-tight truncate">
                {title}
              </h1>
              {subtitle && (
                <p className="text-sm text-muted-foreground hidden sm:block mt-0.5 truncate">
                  {subtitle}
                </p>
              )}
            </div>

            {/* Center: Filters/Actions */}
            <div className="hidden md:flex items-center flex-shrink-0">
              {centerContent}
            </div>

            {/* Right: Actions */}
            <div className="flex items-center gap-2 justify-end flex-shrink-0">
              {/* Mobile Center Content - Show as dropdown if exists */}
              <div className="md:hidden">
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="outline" size="sm" className="text-xs">
                      Filters
                      <ChevronDown className="ml-1.5 h-3.5 w-3.5" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-48">
                    <div className="p-2">
                      {centerContent}
                    </div>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>

              {/* Custom Right Actions */}
              {rightActions}

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
        ) : (
          // Layout không có centerContent: flex justify-between
          <div className="flex items-center justify-between h-full gap-4">
            {/* Left: Title & Subtitle */}
            <div className="min-w-0 flex-1">
              <h1 className="text-xl sm:text-2xl font-bold tracking-tight truncate">
                {title}
              </h1>
              {subtitle && (
                <p className="text-sm text-muted-foreground hidden sm:block mt-0.5 truncate">
                  {subtitle}
                </p>
              )}
            </div>

            {/* Right: Actions */}
            <div className="flex items-center gap-2 flex-shrink-0">
              {/* Custom Right Actions */}
              {rightActions}

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
        )}
      </div>
    </div>
  )
}

