"use client"

import type React from "react"

import { useState } from "react"
import { Navbar } from "./navbar"
import { Sidebar } from "./sidebar"
import { TopBar } from "./topbar"
import { Footer } from "./footer"
import { MobileBottomNav } from "./mobile-bottom-nav"
import { CommandPalette, useCommandPalette } from "@/components/ui/command-palette"
import { useAuth } from "@/lib/contexts/auth-context"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"

interface AppLayoutProps {
  children: React.ReactNode
  showSidebar?: boolean
  showFooter?: boolean
  hideNavbar?: boolean // Hide navbar when sidebar is shown (for dashboard-like pages)
  hideTopBar?: boolean // Hide topbar when custom header is used (e.g., DashboardHeader)
  showMobileBottomNav?: boolean // Show mobile bottom navigation (default: true for authenticated pages)
}

export function AppLayout({ children, showSidebar = false, showFooter = true, hideNavbar = false, hideTopBar = false, showMobileBottomNav }: AppLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const commandPalette = useCommandPalette()
  const { user } = useAuth()
  const pathname = usePathname()
  
  // Determine if mobile bottom nav should be shown
  // Show on authenticated pages (except auth pages, admin/instructor pages)
  const shouldShowMobileBottomNav = showMobileBottomNav !== undefined 
    ? showMobileBottomNav 
    : user && !pathname.startsWith('/login') && !pathname.startsWith('/register') 
      && !pathname.startsWith('/admin') && !pathname.startsWith('/instructor')
      && !pathname.startsWith('/auth')

  return (
    <>
      <CommandPalette open={commandPalette.open} onOpenChange={commandPalette.setOpen} />
      <div className="min-h-screen flex flex-col relative bg-background">
      {/* Show full navbar if not hidden */}
      {!hideNavbar && (
        <Navbar 
          onMenuClick={() => setSidebarOpen(!sidebarOpen)} 
          showMenuButton={showSidebar}
        />
      )}

      {/* Show compact topbar when sidebar is shown and navbar is hidden (unless custom header is used) */}
      {hideNavbar && showSidebar && !hideTopBar && (
        <div className="relative z-50">
          <TopBar />
        </div>
      )}

      <div className="flex flex-1 relative z-10 min-h-0">
        {showSidebar && (
          <>
            {/* Desktop sidebar - hidden on mobile when bottom nav is used */}
            <div className="hidden lg:block relative self-stretch">
              <Sidebar />
            </div>

            {/* Mobile sidebar - only show when sidebar is explicitly opened, not when bottom nav is available */}
            {sidebarOpen && (
              <>
                <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={() => setSidebarOpen(false)} />
                <div className="fixed inset-y-0 left-0 z-50 lg:hidden">
                  <Sidebar />
                </div>
              </>
            )}
          </>
        )}

        <main className={cn(
          "flex-1 relative z-10 flex flex-col",
          hideNavbar && showSidebar ? "bg-gradient-to-b from-background via-muted/20 to-background" : "bg-background",
          // Add bottom padding on mobile to account for bottom navigation
          shouldShowMobileBottomNav && "pb-16 lg:pb-0"
        )}>
          {children}
        </main>
      </div>

      {showFooter && <Footer />}
      
      {/* Mobile Bottom Navigation - show on all authenticated pages on mobile */}
      {shouldShowMobileBottomNav && <MobileBottomNav />}
      </div>
    </>
  )
}
