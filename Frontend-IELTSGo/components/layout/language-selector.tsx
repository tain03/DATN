"use client"

import { Globe } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { useLocale } from "@/lib/i18n/hooks"
import { usePreferences } from "@/lib/contexts/preferences-context"
import { useTranslations } from '@/lib/i18n'

const languages = [
  { code: 'vi', label: 'Tiếng Việt', flag: '🇻🇳' },
  { code: 'en', label: 'English', flag: '🇬🇧' },
] as const

export function LanguageSelector() {

  const t = useTranslations('common')

  const { locale, setLocale } = useLocale()
  const { preferences, updatePreferences } = usePreferences()
  const currentLanguage = languages.find(lang => lang.code === locale) || languages[0]

  const handleLanguageChange = async (newLocale: 'vi' | 'en') => {
    // Update i18n store immediately (for instant UI feedback)
    setLocale(newLocale)
    
    // Update user preferences (if user is logged in)
    if (preferences) {
      try {
        await updatePreferences({ locale: newLocale })
      } catch (error) {
        console.error('Failed to update language preference:', error)
        // Revert on error
        setLocale(preferences.locale || 'vi')
      }
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <Globe className="h-5 w-5" />
          <span className="sr-only">{t('select_language')}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-40">
        {languages.map((lang) => (
          <DropdownMenuItem
            key={lang.code}
            onClick={() => handleLanguageChange(lang.code)}
            className={locale === lang.code ? "bg-accent" : ""}
          >
            <span className="mr-2">{lang.flag}</span>
            <span>{lang.label}</span>
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

