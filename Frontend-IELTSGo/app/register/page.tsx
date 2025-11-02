"use client"

import type React from "react"

import { useState } from "react"
import Link from "next/link"
import { useAuth } from "@/lib/contexts/auth-context"
import { Button } from "@/components/ui/button"
import { EnhancedFormField } from "@/components/ui/enhanced-form-field"
import { Label } from "@/components/ui/label"
import { BookOpen, PenTool, BarChart3, Sparkles, CheckCircle2 } from "lucide-react"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Logo } from "@/components/layout/logo"
import { useTranslations } from '@/lib/i18n'
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"

export default function RegisterPage() {

  const t = useTranslations('auth')
  const toast = useToastWithI18n()

  const { register, loginWithGoogle } = useAuth()
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    confirmPassword: "",
    phone: "",
    role: "student" as "student" | "instructor",
    targetBandScore: "",
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
    } else if (formData.password.length < 8) {
      newErrors.password = t('password_must_be_at_least_8')
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = t('please_confirm_your_password')
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = t('passwords_do_not_match')
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!validateForm()) return

    setIsLoading(true)
    try {
      await register({
        email: formData.email,
        password: formData.password,
        phone: formData.phone || undefined,
        role: formData.role,
        fullName: formData.fullName || undefined,
        targetBandScore: formData.targetBandScore ? parseFloat(formData.targetBandScore) : undefined,
      })
    } catch (error: any) {
      // Parse error message from backend
      let errorMessage = t('registration_failed_please_try_again')
      
      if (error.response?.data) {
        // Backend returns: { success: false, error: { code, message, details } }
        if (error.response.data.error?.message) {
          errorMessage = error.response.data.error.message
        } else if (error.response.data.message) {
          errorMessage = error.response.data.message
        }
      } else if (error.message) {
        errorMessage = error.message
      }
      
      // Map common error codes to user-friendly messages
      const errorCode = error.response?.data?.error?.code
      if (errorCode === "EMAIL_EXISTS") {
        errorMessage = t('email_already_registered') || "Email đã được đăng ký"
      } else if (errorCode === "PHONE_EXISTS") {
        errorMessage = t('phone_already_registered') || "Số điện thoại đã được đăng ký"
      } else if (errorCode === "WEAK_PASSWORD") {
        errorMessage = t('password_must_be_at_least_8') || "Mật khẩu phải có ít nhất 8 ký tự"
      } else if (errorCode === "VALIDATION_ERROR") {
        // Show validation error details if available
        errorMessage = error.response?.data?.error?.message || errorMessage
      }
      
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleRegister = async () => {
    setIsGoogleLoading(true)
    try {
      await loginWithGoogle()
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message 
        || error.message 
        || t('google_registration_failed_please_try_ag')
      toast.error(errorMessage)
      setIsGoogleLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex relative">
      {/* Left side - Promotional Content */}
      <div className="hidden lg:flex flex-1 bg-gradient-to-br from-accent via-accent/80 to-primary/5 items-center justify-center p-8 relative overflow-hidden">
        {/* Enhanced Decorative shapes */}
        <div className="absolute top-0 left-0 w-96 h-96 bg-primary/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-0 right-0 w-[500px] h-[500px] bg-accent/30 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 bg-primary/5 rounded-full blur-3xl" />
        
        {/* Floating sparkles */}
        <div className="absolute top-40 left-32 text-primary/20">
          <Sparkles className="h-8 w-8 animate-pulse" />
        </div>
        <div className="absolute bottom-32 right-40 text-primary/15">
          <Sparkles className="h-6 w-6 animate-pulse delay-500" />
        </div>
        
        <div className="max-w-2xl text-center space-y-10 relative z-10 px-6">
          {/* Header with gradient text effect */}
          <div className="space-y-4">
            <h2 className="text-2xl sm:text-3xl font-bold leading-tight text-foreground">
              {t('start_ielts_journey_today')}
            </h2>
            <p className="text-sm sm:text-base text-muted-foreground leading-relaxed max-w-xl mx-auto">
              {t('personalized_learning_path')}
            </p>
          </div>
          
          {/* Enhanced Features with icons */}
          <div className="space-y-4 pt-6 text-left max-w-xl mx-auto">
            <div className="group flex items-start gap-4 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="p-2.5 rounded-lg bg-primary/15 group-hover:bg-primary/25 transition-colors flex-shrink-0 group-hover:scale-110">
                <BookOpen className="h-5 w-5 text-primary" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-sm sm:text-base mb-1 flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                  {t('comprehensive_courses')}
                </h3>
                <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                  {t('access_500_lessons')}
                </p>
              </div>
            </div>
            <div className="group flex items-start gap-4 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="p-2.5 rounded-lg bg-primary/15 group-hover:bg-primary/25 transition-colors flex-shrink-0 group-hover:scale-110">
                <PenTool className="h-5 w-5 text-primary" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-sm sm:text-base mb-1 flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                  {t('practice_exercises_label')}
                </h3>
                <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                  {t('test_skills_real_ielts')}
                </p>
              </div>
            </div>
            <div className="group flex items-start gap-4 p-5 rounded-xl bg-card/40 backdrop-blur-md border-2 border-border/40 hover:border-primary/50 transition-all duration-300 hover:shadow-xl hover:shadow-primary/20 hover:-translate-y-1">
              <div className="p-2.5 rounded-lg bg-primary/15 group-hover:bg-primary/25 transition-colors flex-shrink-0 group-hover:scale-110">
                <BarChart3 className="h-5 w-5 text-primary" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-sm sm:text-base mb-1 flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                  {t('track_progress_label')}
                </h3>
                <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                  {t('monitor_progress_analytics')}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Right side - Form */}
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
                {t('create_account_title')}
              </h1>
              <p className="text-sm sm:text-base text-muted-foreground">
                {t('start_your_ielts_journey_today')}
              </p>
            </div>
          </div>

          {/* Register Form */}
          <form onSubmit={handleSubmit} className="space-y-5 bg-card/50 backdrop-blur-sm p-6 rounded-lg border border-border/50 shadow-sm">
            <EnhancedFormField
              label={t('full_name')}
              name="fullName"
              type="text"
              placeholder={t('john_doe')}
              value={formData.fullName}
              onChange={(value) => setFormData({ ...formData, fullName: value })}
              error={errors.fullName}
              required
              showValidationState={!!errors.fullName}
            />

            <EnhancedFormField
              label={t('email')}
              name="email"
              type="email"
              placeholder={t('youremailexamplecom')}
              value={formData.email}
              onChange={(value) => setFormData({ ...formData, email: value })}
              error={errors.email}
              required
              showValidationState={!!errors.email}
            />

            <EnhancedFormField
              label={t('password')}
              name="password"
              type="password"
              placeholder={t('create_a_strong_password')}
              value={formData.password}
              onChange={(value) => setFormData({ ...formData, password: value })}
              error={errors.password}
              required
              autoComplete="new-password"
              showValidationState={!!errors.password}
            />

            <EnhancedFormField
              label={t('confirm_password')}
              name="confirmPassword"
              type="password"
              placeholder={t('reenter_your_password')}
              value={formData.confirmPassword}
              onChange={(value) => setFormData({ ...formData, confirmPassword: value })}
              error={errors.confirmPassword}
              required
              autoComplete="new-password"
              showValidationState={!!errors.confirmPassword}
            />

            <div className="space-y-2">
              <Label htmlFor="targetBandScore" className="text-sm font-medium">
                {t('target_score_optional')}
              </Label>
              <Select
                value={formData.targetBandScore}
                onValueChange={(value) => setFormData({ ...formData, targetBandScore: value })}
              >
                <SelectTrigger id="targetBandScore">
                  <SelectValue placeholder={t('chn_im_s_mc_tiu_ca_bn')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="5.5">5.5</SelectItem>
                  <SelectItem value="6.0">6.0</SelectItem>
                  <SelectItem value="6.5">6.5</SelectItem>
                  <SelectItem value="7.0">7.0</SelectItem>
                  <SelectItem value="7.5">7.5</SelectItem>
                  <SelectItem value="8.0">8.0</SelectItem>
                  <SelectItem value="8.5">8.5</SelectItem>
                  <SelectItem value="9.0">9.0</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? t('creating_account') : t('create_account_button')}
            </Button>

            <p className="text-xs text-center text-muted-foreground">
              {t('by_creating_account')}{" "}
              <Link href="/terms" className="text-primary hover:underline">
                {t('terms_of_service')}
              </Link>{" "}
              {t('and')}{" "}
              <Link href="/privacy" className="text-primary hover:underline">
                {t('privacy_policy')}
              </Link>
            </p>
          </form>

          {/* Login Link */}
          <div className="text-center pt-2">
            <p className="text-sm text-muted-foreground">
              {t('already_have_account')}{" "}
              <Link href="/login" className="text-primary hover:underline font-medium">
                {t('login_now')}
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
