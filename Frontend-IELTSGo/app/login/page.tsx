"use client"

import type React from "react"

import { useState } from "react"
import Link from "next/link"
import { useAuth } from "@/lib/contexts/auth-context"
import { Button } from "@/components/ui/button"
import { EnhancedFormField } from "@/components/ui/enhanced-form-field"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { Users, BookOpen, Trophy, Sparkles } from "lucide-react"
import { Logo } from "@/components/layout/logo"
import { useTranslations } from '@/lib/i18n'
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"

export default function LoginPage() {

  const t = useTranslations('auth')
  const toast = useToastWithI18n()

  const { login, loginWithGoogle } = useAuth()
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false,
  })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isLoading, setIsLoading] = useState(false)
  const [isGoogleLoading, setIsGoogleLoading] = useState(false)

  const validateForm = () => {
    const newErrors: Record<string, string> = {}

    if (!formData.email) {
      newErrors.email = t('email_is_required')
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = t('email_is_invalid')
    }

    if (!formData.password) {
      newErrors.password = t('password_is_required')
    } else if (formData.password.length < 6) {
      newErrors.password = t('password_must_be_at_least_6')
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!validateForm()) return

    setIsLoading(true)
    try {
      await login({
        email: formData.email,
        password: formData.password,
      })
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message 
        || error.message 
        || t('login_failed_please_try_again')
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setIsGoogleLoading(true)
    try {
      await loginWithGoogle()
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message 
        || error.message 
        || t('google_login_failed_please_try_again')
      toast.error(errorMessage)
      setIsGoogleLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex relative">
      {/* Left side - Form */}
      <div className="flex-1 flex items-center justify-center p-8 relative overflow-hidden z-10">
        {/* Decorative background elements */}
        <div className="absolute top-0 left-0 w-72 h-72 bg-primary/5 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-accent/30 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />
        
        <div className="w-full max-w-md space-y-8 relative z-10">
          {/* Logo and Welcome Message */}
          <div className="text-center space-y-4">
            <Logo className="justify-center" />
            <div className="space-y-2">
              <h1 className="text-2xl sm:text-3xl font-bold text-foreground">
                {t('welcome_back')}
              </h1>
              <p className="text-sm sm:text-base text-muted-foreground">
                {t('login_continue_journey')}
              </p>
            </div>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-5 bg-card/50 backdrop-blur-sm p-6 rounded-lg border border-border/50 shadow-sm">
            <EnhancedFormField
              label={t('auth.email')}
              name="email"
              type="email"
              placeholder={t('auth.youremailexamplecom')}
              value={formData.email}
              onChange={(value) => setFormData({ ...formData, email: value })}
              error={errors.email}
              required
              showValidationState={!!errors.email}
            />

            <EnhancedFormField
              label={t('auth.password')}
              name="password"
              type="password"
              placeholder={t('auth.enter_your_password')}
              value={formData.password}
              onChange={(value) => setFormData({ ...formData, password: value })}
              error={errors.password}
              required
              showValidationState={!!errors.password}
            />

            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="remember"
                  checked={formData.rememberMe}
                  onCheckedChange={(checked) => setFormData({ ...formData, rememberMe: checked as boolean })}
                />
                <Label htmlFor="remember" className="text-sm cursor-pointer">
                  {t('remember_me')}
                </Label>
              </div>
              <Link href="/forgot-password" className="text-sm text-primary hover:underline">
                {t('forgot_password')}
              </Link>
            </div>

            <Button type="submit" className="w-full" disabled={isLoading || isGoogleLoading}>
              {isLoading ? t('logging_in') : t('login_button')}
            </Button>
          </form>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-border"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-background text-muted-foreground">{t('or_login_with')}</span>
            </div>
          </div>

          {/* Google Login Button */}
          <Button
            type="button"
            variant="outline"
            className="w-full h-11 bg-background hover:bg-accent/50 border-2 border-border hover:border-border/80 shadow-sm hover:shadow-md transition-all duration-200 group"
            onClick={handleGoogleLogin}
            disabled={isLoading || isGoogleLoading}
          >
            <div className="flex items-center justify-center gap-3">
              {/* Google Icon */}
              <svg 
                className="h-5 w-5 transition-transform group-hover:scale-110" 
                viewBox="0 0 24 24"
              >
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              <span className="font-medium text-foreground group-hover:text-foreground">
                {isGoogleLoading ? t('connecting') : t('login_with_google')}
              </span>
            </div>
          </Button>

          {/* Register Link */}
          <div className="text-center pt-4">
            <p className="text-sm text-muted-foreground">
              {t('no_account_yet')}{" "}
              <Link href="/register" className="text-primary hover:underline font-medium">
                {t('signup_now')}
              </Link>
            </p>
          </div>
        </div>
      </div>

      {/* Right side - Promotional Content */}
      <div className="hidden lg:flex flex-1 bg-gradient-to-br from-accent via-accent/80 to-primary/5 items-center justify-center p-8 relative overflow-hidden">
        {/* Enhanced Decorative shapes */}
        <div className="absolute top-0 right-0 w-96 h-96 bg-primary/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-accent/30 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 bg-primary/5 rounded-full blur-3xl" />
        
        {/* Floating sparkles */}
        <div className="absolute top-32 right-32 text-primary/20">
          <Sparkles className="h-8 w-8 animate-pulse" />
        </div>
        <div className="absolute bottom-40 left-40 text-primary/15">
          <Sparkles className="h-6 w-6 animate-pulse delay-300" />
        </div>
        
        <div className="max-w-2xl text-center space-y-10 relative z-10 px-6">
          {/* Header with gradient text effect */}
          <div className="space-y-4">
            <h2 className="text-2xl sm:text-3xl font-bold leading-tight text-foreground lg:whitespace-nowrap">
              {t('conquer_ielts_with_confidence')}
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground leading-relaxed max-w-xl mx-auto">
              {t('join_thousands_of_students')}
            </p>
          </div>
          
          {/* Enhanced Stats with icons */}
          <div className="grid grid-cols-3 gap-6 pt-6">
            <div className="group text-center space-y-2 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="flex justify-center mb-2">
                <div className="p-2.5 rounded-full bg-primary/15 group-hover:bg-primary/25 transition-colors group-hover:scale-110">
                  <Users className="h-5 w-5 text-primary" />
                </div>
              </div>
              <div className="text-2xl sm:text-3xl font-bold text-primary group-hover:scale-110 transition-transform">10K+</div>
              <div className="text-xs sm:text-sm text-muted-foreground font-medium">{t('students_label')}</div>
            </div>
            <div className="group text-center space-y-2 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="flex justify-center mb-2">
                <div className="p-2.5 rounded-full bg-primary/15 group-hover:bg-primary/25 transition-colors group-hover:scale-110">
                  <BookOpen className="h-5 w-5 text-primary" />
                </div>
              </div>
              <div className="text-2xl sm:text-3xl font-bold text-primary group-hover:scale-110 transition-transform">500+</div>
              <div className="text-xs sm:text-sm text-muted-foreground font-medium">{t('lessons_label')}</div>
            </div>
            <div className="group text-center space-y-2 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="flex justify-center mb-2">
                <div className="p-2.5 rounded-full bg-primary/15 group-hover:bg-primary/25 transition-colors group-hover:scale-110">
                  <Trophy className="h-5 w-5 text-primary" />
                </div>
              </div>
              <div className="text-2xl sm:text-3xl font-bold text-primary group-hover:scale-110 transition-transform">8.0</div>
              <div className="text-xs sm:text-sm text-muted-foreground font-medium">{t('avg_score_label')}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
