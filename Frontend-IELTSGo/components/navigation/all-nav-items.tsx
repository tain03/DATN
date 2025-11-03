"use client"

import { useTranslations } from "@/lib/i18n"

/**
 * All navigation items hooks
 * Provides translated navigation items for different contexts
 */

export function useNavItems() {
  const t = useTranslations('common')
  
  return [
    {
      title: t('home'),
      href: "/",
      icon: "Home",
    },
    {
      title: t('courses'),
      href: "/courses",
      icon: "BookOpen",
    },
    {
      title: t('exercises'),
      href: "/exercises",
      icon: "PenTool",
    },
    {
      title: t('leaderboard'),
      href: "/leaderboard",
      icon: "Trophy",
    },
  ] as const
}

export function useUserNavItems() {
  const t = useTranslations('common')
  
  return [
    {
      title: t('profile'),
      href: "/profile",
      icon: "User",
    },
    {
      title: t('settings'),
      href: "/settings",
      icon: "Settings",
    },
  ] as const
}

type SidebarNavItem = 
  | {
      title: string
      href: string
      icon: string
    }
  | {
      type: "separator"
      label: string
    }

export function useSidebarNavItems(): SidebarNavItem[] {
  const t = useTranslations('common')
  const tGoals = useTranslations('goals')
  const tReminders = useTranslations('reminders')
  const tAchievements = useTranslations('achievements')
  
  return [
    {
      title: t('dashboard'),
      href: "/dashboard",
      icon: "LayoutDashboard",
    },
    {
      title: t('courses'),
      href: "/my-courses",
      icon: "BookOpen",
    },
    {
      title: t('exercises'),
      href: "/my-exercises",
      icon: "CheckSquare",
    },
    {
      title: t('my_exercise_history') || "Exercise History",
      href: "/exercises/history",
      icon: "FileText",
    },
    {
      type: "separator",
      label: t('ai_practice') || "AI Practice",
    },
    {
      title: t('writing_practice') || "Writing Practice",
      href: "/ai/writing",
      icon: "FileText",
    },
    {
      title: t('speaking_practice') || "Speaking Practice",
      href: "/ai/speaking",
      icon: "Mic",
    },
    {
      type: "separator",
      label: t('study_tools') || "Study Tools",
    },
    {
      title: t('progress_analytics') || "Progress",
      href: "/progress",
      icon: "BarChart3",
    },
    {
      title: t('study_history') || "History",
      href: "/history",
      icon: "History",
    },
    {
      title: tGoals('title'),
      href: "/goals",
      icon: "Target",
    },
    {
      title: tReminders('title'),
      href: "/reminders",
      icon: "Clock",
    },
    {
      title: tAchievements('title'),
      href: "/achievements",
      icon: "Award",
    },
    {
      type: "separator",
      label: t('social') || "Social",
    },
    {
      title: t('leaderboard'),
      href: "/leaderboard",
      icon: "Trophy",
    },
    {
      title: t('notifications'),
      href: "/notifications",
      icon: "Bell",
    },
  ]
}

export function useInstructorNavItems() {
  const t = useTranslations('common')
  
  return [
    {
      title: t('dashboard'),
      href: "/instructor",
      icon: "LayoutDashboard",
    },
    {
      title: t('courses'),
      href: "/instructor/courses",
      icon: "BookOpen",
    },
    {
      title: t('exercises'),
      href: "/instructor/exercises",
      icon: "PenTool",
    },
    {
      title: t('students'),
      href: "/instructor/students",
      icon: "Users",
    },
    {
      title: t('messages'),
      href: "/instructor/messages",
      icon: "MessageSquare",
    },
  ] as const
}

export function useAdminNavItems() {
  const t = useTranslations('common')
  
  return [
    {
      title: t('dashboard'),
      href: "/admin",
      icon: "LayoutDashboard",
      children: [],
    },
    {
      title: t('userManagement'),
      href: "/admin/users",
      icon: "Users",
      children: [],
    },
    {
      title: t('contentManagement'),
      href: "/admin/content",
      icon: "FileText",
      children: [],
    },
    {
      title: t('analytics'),
      href: "/admin/analytics",
      icon: "BarChart",
      children: [],
    },
    {
      title: t('notifications'),
      href: "/admin/notifications",
      icon: "Bell",
      children: [],
    },
    {
      title: t('systemSettings'),
      href: "/admin/settings",
      icon: "Settings",
      children: [],
    },
  ] as const
}



