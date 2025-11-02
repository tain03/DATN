"use client"

import type React from "react"

import { useState, useRef, useEffect } from "react"
import { useAuth } from "@/lib/contexts/auth-context"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { Button } from "@/components/ui/button"
import { EnhancedFormField } from "@/components/ui/enhanced-form-field"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Camera, CheckCircle2, Edit2, Save, X } from "lucide-react"
import { userApi } from "@/lib/api/user"
import { authApi } from "@/lib/api/auth"
import { useTranslations } from '@/lib/i18n'
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"

export default function ProfilePage() {

  const t = useTranslations('profile')

  return (
    <ProtectedRoute>
      <ProfileContent />
    </ProtectedRoute>
  )
}

function ProfileContent() {
  const t = useTranslations('profile')
  const { user, updateProfile, refreshUser } = useAuth()
  const toast = useToastWithI18n()
  const [isEditing, setIsEditing] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [isUploadingAvatar, setIsUploadingAvatar] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [formData, setFormData] = useState({
    fullName: user?.fullName || "",
    email: user?.email || "",
    bio: user?.bio || "",
    targetBandScore: user?.targetBandScore?.toString() || "",
  })

  // Update form data when user changes
  useEffect(() => {
    if (user) {
      setFormData({
        fullName: user.fullName || "",
        email: user.email || "",
        bio: user.bio || "",
        targetBandScore: user.targetBandScore?.toString() || "",
      })
    }
  }, [user])
  const [passwordData, setPasswordData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  })
  const [errors, setErrors] = useState<Record<string, string>>({})

  const getUserInitials = () => {
    if (!user?.fullName) return "U"
    return user.fullName
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2)
  }

  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrors({})

    const newErrors: Record<string, string> = {}
    if (!formData.fullName) {
      newErrors.fullName = t('full_name_is_required')
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)
      return
    }

    setIsLoading(true)
    try {
      await updateProfile({
        fullName: formData.fullName.trim(),
        bio: formData.bio?.trim() || "",
        targetBandScore: formData.targetBandScore ? parseFloat(formData.targetBandScore) : undefined,
      })
      
      setIsEditing(false)
      
      // Refresh user data from backend to get updated values
      await refreshUser()
      
      // Show success toast
      toast.success(t('profile_updated_successfully'))
    } catch (error: any) {
      console.error("Profile update error:", error)
      const errorMessage = error.response?.data?.error?.message 
        || error.response?.data?.message 
        || error.message 
        || t('failed_to_update_profile')
      toast.error(errorMessage)
      setErrors({ general: errorMessage })
    } finally {
      setIsLoading(false)
    }
  }

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    // Validate file size (max 2MB)
    if (file.size > 2 * 1024 * 1024) {
      setErrors({ avatar: t('file_size_must_be_less_than_2mb') })
      return
    }

    // Validate file type
    if (!file.type.startsWith("image/")) {
      setErrors({ avatar: t('file_must_be_an_image') })
      return
    }

    setIsUploadingAvatar(true)
    setErrors({})

    try {
      // Convert file to base64 data URL
      const reader = new FileReader()
      reader.onloadend = async () => {
        const base64String = reader.result as string
        try {
          // Upload avatar URL to backend
          await userApi.uploadAvatar(base64String)
          
          // Update user state
          if (user) {
            const updatedUser = { ...user, avatar: base64String }
            localStorage.setItem("user_data", JSON.stringify(updatedUser))
            refreshUser()
          }
          
          toast.success(t('avatar_updated_successfully'))
        } catch (error: any) {
          const errorMsg = error.response?.data?.error?.message || t('failed_to_upload_avatar')
          toast.error(errorMsg)
          setErrors({ avatar: errorMsg })
        } finally {
          setIsUploadingAvatar(false)
        }
      }
      reader.onerror = () => {
        setErrors({ avatar: t('failed_to_read_file') })
        setIsUploadingAvatar(false)
      }
      reader.readAsDataURL(file)
    } catch (error: any) {
      setErrors({ avatar: t('failed_to_process_file') })
      setIsUploadingAvatar(false)
    }
  }

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrors({})

    const newErrors: Record<string, string> = {}
    if (!passwordData.currentPassword) {
      newErrors.currentPassword = t('current_password_is_required')
    }
    if (!passwordData.newPassword) {
      newErrors.newPassword = t('new_password_is_required')
    } else if (passwordData.newPassword.length < 8) {
      newErrors.newPassword = t('password_must_be_at_least_8_characters')
    }
    if (passwordData.newPassword !== passwordData.confirmPassword) {
      newErrors.confirmPassword = t('passwords_do_not_match')
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)
      return
    }

    setIsLoading(true)
    try {
      const response = await authApi.changePassword(
        passwordData.currentPassword,
        passwordData.newPassword
      )
      
      if (response.success) {
        toast.success(t('password_changed_successfully'))
        setPasswordData({ currentPassword: "", newPassword: "", confirmPassword: "" })
      } else {
        const errorMsg = response.message || t('failed_to_change_password')
        toast.error(errorMsg)
        setErrors({ general: errorMsg })
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message 
        || error.response?.data?.message 
        || error.message 
        || t('failed_to_change_password')
      
      // Handle specific error codes from backend
      if (error.response?.data?.error?.code === "CHANGE_PASSWORD_FAILED") {
        const message = error.response.data.error.message
        if (message.includes("invalid old password")) {
          setErrors({ currentPassword: t('current_password_is_incorrect') })
          toast.error(t('current_password_is_incorrect'))
        } else {
          setErrors({ general: message })
          toast.error(message)
        }
      } else {
        setErrors({ general: errorMessage })
        toast.error(errorMessage)
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <AppLayout showSidebar={false} showFooter>
      <PageContainer maxWidth="7xl">
        <div className="space-y-6">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight">{t('profile_settings')}</h1>
            <p className="text-base text-muted-foreground mt-2">{t('manage_your_account_settings_and_prefere')}</p>
          </div>


          <Tabs defaultValue="profile" className="space-y-6">
            <TabsList>
              <TabsTrigger value="profile">{t('profile')}</TabsTrigger>
              <TabsTrigger value="security">{t('security')}</TabsTrigger>
            </TabsList>

            {/* Profile Tab */}
            <TabsContent value="profile" className="space-y-6">
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>{t('profile_information')}</CardTitle>
                      <CardDescription className="mt-1">{t('update_your_personal_information_and_profi')}</CardDescription>
                    </div>
                    {!isEditing && (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => setIsEditing(true)}
                        className="gap-2"
                      >
                        <Edit2 className="h-4 w-4" />
                        {t('edit_profile')}
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Avatar */}
                  <div className="flex items-center gap-6 pb-6 border-b">
                    <Avatar className="h-28 w-28 border-4 border-background shadow-lg">
                      <AvatarImage src={user?.avatar || "/placeholder.svg"} alt={user?.fullName} />
                      <AvatarFallback className="bg-primary text-primary-foreground text-2xl">
                        {getUserInitials()}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <input
                        ref={fileInputRef}
                        type="file"
                        id="avatar-upload"
                        accept="image/jpeg,image/png,image/gif"
                        onChange={handleAvatarChange}
                        className="hidden"
                        disabled={isUploadingAvatar}
                      />
                      <label
                        htmlFor="avatar-upload"
                        className={`
                          inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all
                          border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground
                          h-8 rounded-md gap-1.5 px-3
                          cursor-pointer
                          ${isUploadingAvatar ? 'opacity-50 pointer-events-none' : ''}
                        `}
                      >
                        <Camera className="mr-2 h-4 w-4" />
                        {isUploadingAvatar ? t('uploading') : t('change_photo')}
                      </label>
                      {errors.avatar && (
                        <p className="text-xs text-destructive mt-1">{errors.avatar}</p>
                      )}
                      <p className="text-xs text-muted-foreground mt-2">{t('jpg_png_or_gif_max_size_2mb')}</p>
                    </div>
                  </div>

                  {/* Form */}
                  <form onSubmit={handleProfileUpdate} className="space-y-5">
                    {isEditing ? (
                      <>
                        <FormField
                          label={t('full_name')}
                          name="fullName"
                          value={formData.fullName}
                          onChange={(value) => setFormData({ ...formData, fullName: value })}
                          error={errors.fullName}
                          required
                          autoFocus
                        />

                        <FormField
                          label={t('email')}
                          name="email"
                          type="email"
                          value={formData.email}
                          onChange={(value) => setFormData({ ...formData, email: value })}
                          disabled
                          className="bg-muted/50"
                        />

                        <FormField
                          label={t('bio')}
                          name="bio"
                          type="textarea"
                          placeholder={t('tell_us_about_yourself')}
                          value={formData.bio}
                          onChange={(value) => setFormData({ ...formData, bio: value })}
                          rows={3}
                        />

                        <div className="space-y-2">
                          <Label htmlFor="targetBandScore">{t('target_band_score')}</Label>
                          <Select
                            value={formData.targetBandScore}
                            onValueChange={(value) => setFormData({ ...formData, targetBandScore: value })}
                          >
                            <SelectTrigger id="targetBandScore">
                              <SelectValue placeholder={t('select_your_target_score')} />
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


                        <div className="flex items-center justify-end gap-3 pt-4 border-t">
                          <Button
                            type="button"
                            variant="outline"
                            onClick={() => {
                              setIsEditing(false)
                              setFormData({
                                fullName: user?.fullName || "",
                                email: user?.email || "",
                                bio: user?.bio || "",
                                targetBandScore: user?.targetBandScore?.toString() || "",
                              })
                              setErrors({})
                            }}
                            disabled={isLoading}
                            className="gap-2"
                          >
                            <X className="h-4 w-4" />
                            {t('cancel')}
                          </Button>
                          <Button type="submit" disabled={isLoading} className="gap-2">
                            <Save className="h-4 w-4" />
                            {isLoading ? t('saving') : t('save_changes')}
                          </Button>
                        </div>
                      </>
                    ) : (
                      <>
                        {/* View Mode - Display as read-only */}
                        <div className="space-y-4">
                          <div className="space-y-2">
                            <Label className="text-sm font-medium text-muted-foreground">{t('full_name')}</Label>
                            <p className="text-sm font-medium">{formData.fullName || t('not_set')}</p>
                          </div>

                          <div className="space-y-2">
                            <Label className="text-sm font-medium text-muted-foreground">{t('email')}</Label>
                            <p className="text-sm">{formData.email}</p>
                          </div>

                          <div className="space-y-2">
                            <Label className="text-sm font-medium text-muted-foreground">{t('bio')}</Label>
                            <p className="text-sm text-muted-foreground whitespace-pre-wrap">
                              {formData.bio || t('no_bio_added_yet')}
                            </p>
                          </div>

                          <div className="space-y-2">
                            <Label className="text-sm font-medium text-muted-foreground">{t('target_band_score')}</Label>
                            <p className="text-sm">
                              {formData.targetBandScore ? `${t('band')} ${formData.targetBandScore}` : t('not_set')}
                            </p>
                          </div>
                        </div>
                      </>
                    )}
                  </form>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Security Tab */}
            <TabsContent value="security" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>{t('change_password')}</CardTitle>
                  <CardDescription>{t('update_your_password_to_keep_your_accoun')}</CardDescription>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handlePasswordChange} className="space-y-4">
                    <EnhancedFormField
                      label={t('current_password')}
                      name="currentPassword"
                      type="password"
                      value={passwordData.currentPassword}
                      onChange={(value) => setPasswordData({ ...passwordData, currentPassword: value })}
                      error={errors.currentPassword}
                      required
                      showValidationState={!!errors.currentPassword}
                    />

                    <EnhancedFormField
                      label={t('new_password')}
                      name="newPassword"
                      type="password"
                      value={passwordData.newPassword}
                      onChange={(value) => setPasswordData({ ...passwordData, newPassword: value })}
                      error={errors.newPassword}
                      required
                      showValidationState={!!errors.newPassword}
                    />

                    <EnhancedFormField
                      label={t('confirm_new_password')}
                      name="confirmPassword"
                      type="password"
                      value={passwordData.confirmPassword}
                      onChange={(value) => setPasswordData({ ...passwordData, confirmPassword: value })}
                      error={errors.confirmPassword}
                      required
                      showValidationState={!!errors.confirmPassword}
                    />


                    <Button type="submit" disabled={isLoading}>
                      {isLoading ? t('changing_password') : t('change_password')}
                    </Button>
                  </form>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </PageContainer>
    </AppLayout>
  )
}
