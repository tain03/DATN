"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { LayoutDashboard, BookOpen, Target, User } from "lucide-react"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"

interface NavItem {
  icon: React.ElementType
  label: string
  href: string
  translationKey: string
}

export function MobileBottomNav() {
  const pathname = usePathname()
  const t = useTranslations('common')

  const navItems: NavItem[] = [
    {
      icon: LayoutDashboard,
      label: t('dashboard'),
      href: "/dashboard",
      translationKey: 'dashboard',
    },
    {
      icon: BookOpen,
      label: t('courses'),
      href: "/my-courses",
      translationKey: 'courses',
    },
    {
      icon: Target,
      label: t('exercises'),
      href: "/my-exercises",
      translationKey: 'exercises',
    },
    {
      icon: User,
      label: t('profile'),
      href: "/profile",
      translationKey: 'profile',
    },
  ]

  // Check if pathname matches or starts with href (for nested routes)
  const isActiveRoute = (href: string) => {
    if (href === "/dashboard") {
      return pathname === href
    }
    return pathname.startsWith(href)
  }

  return (
    <nav 
      className="fixed bottom-0 left-0 right-0 z-50 lg:hidden border-t border-border bg-background/95 backdrop-blur-md supports-[backdrop-filter]:bg-background/80"
      aria-label="Mobile navigation"
    >
      <div className="grid grid-cols-4 gap-0.5 p-1 safe-area-bottom">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = isActiveRoute(item.href)

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "relative flex flex-col items-center justify-center gap-1 py-2 px-1 rounded-lg transition-all duration-200",
                "min-h-[56px] min-w-[56px]", // Minimum 56px for better touch target (larger than 44px requirement)
                isActive
                  ? "text-primary bg-primary/10"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted/50 active:bg-muted"
              )}
              aria-label={item.label}
              aria-current={isActive ? "page" : undefined}
            >
              {/* Active indicator dot */}
              {isActive && (
                <div className="absolute top-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-primary" />
              )}
              
              <Icon 
                className={cn(
                  "h-5 w-5 transition-transform duration-200",
                  isActive && "scale-110"
                )}
                aria-hidden="true"
              />
              <span 
                className={cn(
                  "text-[10px] font-medium leading-tight text-center transition-colors duration-200",
                  isActive ? "text-primary" : "text-muted-foreground"
                )}
              >
                {item.label}
              </span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}

