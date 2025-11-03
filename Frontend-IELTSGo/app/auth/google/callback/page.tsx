"use client"

import { useEffect, useState, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { authApi } from "@/lib/api/auth"
import type { User } from "@/types"
import { Loader2, AlertCircle, CheckCircle } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

function GoogleCallbackContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const t = useTranslations('auth')
  const tCommon = useTranslations('common')
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading")
  const [message, setMessage] = useState(tCommon('processing_google_authentication'))

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // First, try to read tokens from query params (backend redirect)
        const success = searchParams.get("success")
        let accessToken = searchParams.get("access_token")
        let refreshToken = searchParams.get("refresh_token")
        let userId = searchParams.get("user_id")
        let email = searchParams.get("email")
        let role = searchParams.get("role")
        let error = searchParams.get("error")

        // Fallback: some OAuth flows (or proxies) may return tokens in URL fragment (#)
        // Parse window.location.hash if tokens are not present in query params
        if ((!accessToken || !refreshToken) && typeof window !== "undefined") {
          try {
            const hash = window.location.hash || ""
            if (hash.startsWith("#")) {
              const params = new URLSearchParams(hash.slice(1))
              accessToken = accessToken || params.get("access_token")
              refreshToken = refreshToken || params.get("refresh_token")
              userId = userId || params.get("user_id")
              email = email || params.get("email")
              role = role || params.get("role")
              error = error || params.get("error")
            }
          } catch (hashErr) {
          }
        }

        // Handle error from backend
        if (error) {
          setStatus("error")
          setMessage(t('google_authentication_failed', { error }))
          setTimeout(() => router.push("/login"), 3000)
          return
        }

        // Backend redirect with tokens
        if (success === "true" && accessToken && refreshToken && userId && email && role) {
          setMessage(t('storing_authentication_tokens'))

          // Store tokens
          localStorage.setItem("access_token", accessToken)
          localStorage.setItem("refresh_token", refreshToken)

          // Get full profile from user service to get actual fullName
          let fullName = ""
          let bio = ""
          let avatar = ""
          let targetBandScore: number | undefined
          try {
            // Import userApi dynamically to avoid circular dependency
            const { userApi } = await import("@/lib/api/user")
            const profile = await userApi.getProfile()
            fullName = (profile.full_name && profile.full_name.trim()) || ""
            bio = profile.bio || ""
            avatar = profile.avatar_url || ""
            targetBandScore = profile.target_band_score
          } catch (error) {
            // Don't fallback to email - leave fullName empty
            fullName = ""
          }

          // Store user data
          const userData: User = {
            id: userId,
            email: email,
            role: role as "student" | "instructor" | "admin",
            fullName: fullName || "",
            bio: bio || undefined,
            avatar: avatar || undefined,
            targetBandScore: targetBandScore,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          }

          localStorage.setItem("user_data", JSON.stringify(userData))

          setStatus("success")
          setMessage(tCommon('successfully_authenticated_redirecting'))

          // Redirect based on role
          const redirectPath = userData.role === "admin" 
            ? "/admin" 
            : userData.role === "instructor" 
            ? "/instructor" 
            : "/dashboard"
          
          
          // Use window.location.href instead of router.push to force a full page reload
          // This ensures AuthContext re-initializes with the new tokens
          setTimeout(() => {
            window.location.href = redirectPath
          }, 1500)
          return
        }

        // Fallback: Old flow with code (shouldn't happen now)
        const code = searchParams.get("code")
        const state = searchParams.get("state")

        if (code) {
          setMessage(t('processing_authorization_code'))

          // Verify state (CSRF protection)
          const storedState = localStorage.getItem("oauth_state")
          if (storedState && state !== storedState) {
            setStatus("error")
            setMessage(t('invalid_state_parameter_csrf'))
            setTimeout(() => router.push("/login"), 3000)
            return
          }

          // Clear stored state
          localStorage.removeItem("oauth_state")

          // Exchange code for tokens (mobile flow)
          const response = await authApi.googleExchangeToken(code, state || undefined)

          if (!response.success || !response.data) {
            throw new Error(response.error?.message || "Failed to authenticate with Google")
          }

          // Store tokens
          localStorage.setItem("access_token", response.data.access_token)
          localStorage.setItem("refresh_token", response.data.refresh_token)

          // Get full profile from user service to get actual fullName
          let fullName = ""
          let bio = ""
          let avatar = ""
          let targetBandScore: number | undefined
          try {
            // Import userApi dynamically to avoid circular dependency
            const { userApi } = await import("@/lib/api/user")
            const profile = await userApi.getProfile()
            fullName = (profile.full_name && profile.full_name.trim()) || ""
            bio = profile.bio || ""
            avatar = profile.avatar_url || ""
            targetBandScore = profile.target_band_score
          } catch (error) {
            // Don't fallback to email - leave fullName empty
            fullName = ""
          }

          // Store user data
          const userData: User = {
            id: response.data.user_id,
            email: response.data.email,
            role: response.data.role,
            fullName: fullName || "",
            bio: bio || undefined,
            avatar: avatar || undefined,
            targetBandScore: targetBandScore,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          }

          localStorage.setItem("user_data", JSON.stringify(userData))

          setStatus("success")
          setMessage(tCommon('successfully_authenticated_redirecting'))

          // Redirect based on role
          setTimeout(() => {
            if (userData.role === "admin") {
              router.push("/admin")
            } else if (userData.role === "instructor") {
              router.push("/instructor")
            } else {
              router.push("/dashboard")
            }
          }, 1500)
          return
        }

        // No valid params
        setStatus("error")
        setMessage(t('no_authentication_data_received'))
        setTimeout(() => router.push("/login"), 3000)
      } catch (error: any) {
        console.error("Google callback error:", error)
        setStatus("error")
        setMessage(error.message || tCommon('authentication_failed_please_try_again'))
        setTimeout(() => router.push("/login"), 3000)
      }
    }

    handleCallback()
  }, [searchParams, router])

  return (
    <div className="min-h-screen flex items-center justify-center relative z-10">
      <div className="max-w-md w-full mx-4">
        <div className="bg-card border border-border rounded-lg p-8 shadow-lg">
          <div className="flex flex-col items-center space-y-4">
            {/* Icon */}
            {status === "loading" && (
              <Loader2 className="h-12 w-12 text-primary animate-spin" />
            )}
            {status === "success" && (
              <CheckCircle className="h-12 w-12 text-green-500" />
            )}
            {status === "error" && (
              <AlertCircle className="h-12 w-12 text-destructive" />
            )}

            {/* Title */}
            <h2 className="text-2xl font-bold text-center">
              {status === "loading" && t('authenticating')}
              {status === "success" && t('success')}
              {status === "error" && tCommon('authentication_failed')}
            </h2>

            {/* Message */}
            <p className="text-center text-muted-foreground">
              {message}
            </p>

            {/* Progress indicator */}
            {status === "loading" && (
              <div className="w-full bg-muted rounded-full h-2">
                <div className="bg-primary h-2 rounded-full animate-pulse" style={{ width: "70%" }} />
              </div>
            )}
          </div>
        </div>

        {/* Help text */}
        {status === "error" && (
          <p className="text-center text-sm text-muted-foreground mt-4">
            {t('you_will_be_redirected_to_login')}
          </p>
        )}
      </div>
    </div>
  )
}

export default function GoogleCallbackPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-12 w-12 text-primary animate-spin" />
      </div>
    }>
      <GoogleCallbackContent />
    </Suspense>
  )
}
