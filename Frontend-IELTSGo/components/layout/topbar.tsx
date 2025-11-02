"use client"

import { useState } from "react"
import Link from "next/link"
import { User, LogOut, Settings, BookOpen } from "lucide-react"
import { Button } from "@/components/ui/button"
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
import { NotificationBell } from "@/components/notifications/notification-bell"
import { LanguageSelector } from "./language-selector"
import { useTranslations } from "@/lib/i18n"

interface TopBarProps {
  className?: string
}

export function TopBar({ className }: TopBarProps) {
  const { user, isAuthenticated, logout } = useAuth()
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

  if (!isAuthenticated) {
    return null
  }

  return (
    <header className={`sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur-md shadow-sm ${className || ""}`}>
      <div className="flex h-14 items-center justify-end px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-2 flex-shrink-0">
          {/* Language Selector */}
          <LanguageSelector />

          {/* Notifications */}
          <NotificationBell />

          {/* User menu */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="relative rounded-full">
                <Avatar className="h-9 w-9 cursor-pointer">
                  <AvatarImage src={user?.avatar || "/placeholder.svg"} alt={user?.fullName} />
                  <AvatarFallback className="bg-primary text-primary-foreground text-xs">
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
    </header>
  )
}
