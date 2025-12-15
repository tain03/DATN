"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { Menu, X, User, LogOut, Settings, BookOpen } from "lucide-react"
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
import { Logo } from "./logo"
import { useNavItems } from "@/components/navigation/nav-items"
import { cn } from "@/lib/utils"
import { useAuth } from "@/lib/contexts/auth-context"
import { NotificationBell } from "@/components/notifications/notification-bell"
import { LanguageSelector } from "./language-selector"
import { useTranslations } from "@/lib/i18n"

interface NavbarProps {
  onMenuClick?: () => void
  showMenuButton?: boolean
  hideLogo?: boolean
  hideNavItems?: boolean
}

export function Navbar({ onMenuClick, showMenuButton = false, hideLogo = false, hideNavItems = false }: NavbarProps) {
  const pathname = usePathname()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const { user, isAuthenticated, logout } = useAuth()
  const t = useTranslations('common')
  const MAIN_NAV_ITEMS = useNavItems()

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
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/85 backdrop-blur-md supports-[backdrop-filter]:bg-background/60 transition-all duration-200">
      <div className="container mx-auto flex h-14 sm:h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Left section */}
        <div className="flex items-center gap-3 flex-shrink-0">
          {showMenuButton && (
            <Button variant="ghost" size="icon" onClick={onMenuClick} className="lg:hidden">
              <Menu className="h-5 w-5" />
            </Button>
          )}
          {/* Always show full logo with brand name */}
          {!hideLogo && <Logo />}
        </div>

        {/* Center section - Desktop navigation */}
        {!hideNavItems && (
          <nav className="hidden md:flex items-center gap-4 flex-1 justify-center max-w-2xl">
            {MAIN_NAV_ITEMS.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "text-sm font-medium transition-colors duration-200 px-3 py-1.5 rounded-md",
                  pathname === item.href
                    ? "text-primary bg-primary/5"
                    : "text-muted-foreground hover:text-foreground hover:bg-accent/50",
                )}
              >
                {item.title}
              </Link>
            ))}
          </nav>
        )}

        {/* Right section */}
        <div className="flex items-center gap-3 flex-shrink-0">
          {isAuthenticated ? (
            <>
              {/* Language Selector */}
              <LanguageSelector />

              {/* Notifications */}
              <NotificationBell />

              {/* User menu */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="relative h-10 w-10 rounded-full p-0">
                    <Avatar className="h-10 w-10 cursor-pointer">
                      <AvatarImage src={user?.avatar || "/placeholder.svg"} alt={user?.fullName} />
                      <AvatarFallback className="bg-primary text-primary-foreground">
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
            </>
          ) : (
            <>
              <Button variant="ghost" asChild className="hidden md:inline-flex text-sm sm:text-base">
                <Link href="/login">{t('login')}</Link>
              </Button>
              <Button asChild className="text-sm sm:text-base">
                <Link href="/register">{t('register')}</Link>
              </Button>
            </>
          )}

          {/* Mobile menu button */}
          <Button variant="ghost" size="icon" className="md:hidden" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </Button>
        </div>
      </div>

      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t bg-background">
          <nav className="container flex flex-col gap-2 py-4 px-4">
            {MAIN_NAV_ITEMS.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "px-4 py-2 rounded-md text-sm font-medium transition-colors",
                  pathname === item.href ? "bg-primary text-primary-foreground" : "hover:bg-accent",
                )}
                onClick={() => setMobileMenuOpen(false)}
              >
                {item.title}
              </Link>
            ))}
            {!isAuthenticated && (
              <>
                <Link
                  href="/login"
                  className="px-4 py-2 rounded-md text-sm font-medium hover:bg-accent"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Sign in
                </Link>
                <Link
                  href="/register"
                  className="px-4 py-2 rounded-md text-sm font-medium bg-primary text-primary-foreground"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Get started
                </Link>
              </>
            )}
          </nav>
        </div>
      )}
    </header>
  )
}
