"use client"

import { useState, useEffect } from "react"
import { useAuth } from "@/lib/contexts/auth-context"
import { usePreferences } from "@/lib/contexts/preferences-context"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { Switch } from "@/components/ui/switch"
import { Bell, Monitor, BookOpen, Lock, Save, CheckCircle2, Clock, Settings } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"
import type { UserPreferences, UpdatePreferencesRequest, NotificationPreferences, UpdateNotificationPreferencesRequest } from "@/types"
import { notificationsApi } from "@/lib/api/notifications"
import { useLocale, useTranslations } from "@/lib/i18n/hooks"

export default function SettingsPage() {
  return (
    <ProtectedRoute>
      <SettingsContent />
    </ProtectedRoute>
  )
}

function SettingsContent() {
  const { user } = useAuth()
  const { preferences: contextPrefs, isLoading: contextLoading, updatePreferences: updateContextPrefs } = usePreferences()
  const { setLocale } = useLocale()
  const toast = useToastWithI18n()
  const t = useTranslations("settings")
  const tCommon = useTranslations("common")
  const [preferences, setPreferences] = useState<UserPreferences | null>(null)
  const [originalPreferences, setOriginalPreferences] = useState<UserPreferences | null>(null)
  const [notificationPreferences, setNotificationPreferences] = useState<NotificationPreferences | null>(null)
  const [originalNotificationPreferences, setOriginalNotificationPreferences] = useState<NotificationPreferences | null>(null)
  const [isLoadingNotificationPrefs, setIsLoadingNotificationPrefs] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  // Sync with context preferences
  useEffect(() => {
    if (contextPrefs) {
      setPreferences(contextPrefs)
      setOriginalPreferences(JSON.parse(JSON.stringify(contextPrefs))) // Deep clone
    }
  }, [contextPrefs])

  // Load notification preferences from Notification Service
  useEffect(() => {
    const loadNotificationPreferences = async () => {
      if (!user) return
      try {
        setIsLoadingNotificationPrefs(true)
        const prefs = await notificationsApi.getNotificationPreferences()
        setNotificationPreferences(prefs)
        setOriginalNotificationPreferences(JSON.parse(JSON.stringify(prefs))) // Deep clone
      } catch (err: any) {
        console.error("Failed to load notification preferences:", err)
      } finally {
        setIsLoadingNotificationPrefs(false)
      }
    }
    loadNotificationPreferences()
  }, [user])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!preferences || !originalPreferences) return

    setIsSaving(true)
    setErrors({})

    try {
      // Build update payload - only include fields that have changed
      const updateData: UpdatePreferencesRequest = {}
      
      if (preferences.email_notifications !== originalPreferences.email_notifications) {
        updateData.email_notifications = preferences.email_notifications
      }
      if (preferences.push_notifications !== originalPreferences.push_notifications) {
        updateData.push_notifications = preferences.push_notifications
      }
      if (preferences.study_reminders !== originalPreferences.study_reminders) {
        updateData.study_reminders = preferences.study_reminders
      }
      if (preferences.weekly_report !== originalPreferences.weekly_report) {
        updateData.weekly_report = preferences.weekly_report
      }
      if (preferences.theme !== originalPreferences.theme) {
        updateData.theme = preferences.theme
      }
      if (preferences.font_size !== originalPreferences.font_size) {
        updateData.font_size = preferences.font_size
      }
      if (preferences.locale !== originalPreferences.locale) {
        updateData.locale = preferences.locale
      }
      if (preferences.auto_play_next_lesson !== originalPreferences.auto_play_next_lesson) {
        updateData.auto_play_next_lesson = preferences.auto_play_next_lesson
      }
      if (preferences.show_answer_explanation !== originalPreferences.show_answer_explanation) {
        updateData.show_answer_explanation = preferences.show_answer_explanation
      }
      if (preferences.playback_speed !== originalPreferences.playback_speed) {
        updateData.playback_speed = preferences.playback_speed
      }
      if (preferences.profile_visibility !== originalPreferences.profile_visibility) {
        updateData.profile_visibility = preferences.profile_visibility
      }
      if (preferences.show_study_stats !== originalPreferences.show_study_stats) {
        updateData.show_study_stats = preferences.show_study_stats
      }

      // Check if there are any changes
      if (Object.keys(updateData).length === 0) {
        toast.info("No changes to save")
        setIsSaving(false)
        return
      }

      // Use context update which handles API call and state sync
      await updateContextPrefs(updateData)
      
      // If locale changed, update i18n store immediately
      if (updateData.locale) {
        setLocale(updateData.locale)
      }
      
      // Also update notification preferences if changed
      if (notificationPreferences && originalNotificationPreferences) {
        const notificationUpdates: UpdateNotificationPreferencesRequest = {}
        
        // Check for changes in notification preferences
        if (notificationPreferences.push_enabled !== originalNotificationPreferences.push_enabled) {
          notificationUpdates.push_enabled = notificationPreferences.push_enabled
        }
        if (notificationPreferences.push_achievements !== originalNotificationPreferences.push_achievements) {
          notificationUpdates.push_achievements = notificationPreferences.push_achievements
        }
        if (notificationPreferences.push_reminders !== originalNotificationPreferences.push_reminders) {
          notificationUpdates.push_reminders = notificationPreferences.push_reminders
        }
        if (notificationPreferences.push_course_updates !== originalNotificationPreferences.push_course_updates) {
          notificationUpdates.push_course_updates = notificationPreferences.push_course_updates
        }
        if (notificationPreferences.push_exercise_graded !== originalNotificationPreferences.push_exercise_graded) {
          notificationUpdates.push_exercise_graded = notificationPreferences.push_exercise_graded
        }
        if (notificationPreferences.quiet_hours_enabled !== originalNotificationPreferences.quiet_hours_enabled) {
          notificationUpdates.quiet_hours_enabled = notificationPreferences.quiet_hours_enabled
        }
        if (notificationPreferences.quiet_hours_start !== originalNotificationPreferences.quiet_hours_start) {
          notificationUpdates.quiet_hours_start = notificationPreferences.quiet_hours_start
        }
        if (notificationPreferences.quiet_hours_end !== originalNotificationPreferences.quiet_hours_end) {
          notificationUpdates.quiet_hours_end = notificationPreferences.quiet_hours_end
        }
        if (notificationPreferences.max_notifications_per_day !== originalNotificationPreferences.max_notifications_per_day) {
          notificationUpdates.max_notifications_per_day = notificationPreferences.max_notifications_per_day
        }
        
        if (Object.keys(notificationUpdates).length > 0) {
          await notificationsApi.updateNotificationPreferences(notificationUpdates)
          // Reload notification preferences
          const updated = await notificationsApi.getNotificationPreferences()
          setNotificationPreferences(updated)
          setOriginalNotificationPreferences(JSON.parse(JSON.stringify(updated)))
        }
      }
      
      toast.success(t("saveSuccess"))
      
      // Preferences will be updated via context useEffect
    } catch (error: any) {
        setErrors({
          general: error.response?.data?.error?.message || t("saveError"),
        })
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <AppLayout showSidebar={false} showFooter>
      <PageContainer maxWidth="4xl">
        <div className="space-y-6">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold tracking-tight mb-2 text-foreground">{t("title")}</h1>
            <p className="text-base text-muted-foreground dark:text-muted-foreground">{t("description")}</p>
          </div>


          {contextLoading ? (
            <Card>
              <CardContent className="flex items-center justify-center py-12">
                <PageLoading translationKey="loading" size="sm" showDots={false} />
              </CardContent>
            </Card>
          ) : preferences ? (
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Notifications Section - Unified */}
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Bell className="h-5 w-5 text-primary" />
                    <CardTitle>{t("notifications.title")}</CardTitle>
                  </div>
                  <CardDescription>{t("notifications.description")}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Master Switches */}
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <Settings className="h-4 w-4 text-muted-foreground" />
                      <Label className="text-base font-medium text-foreground dark:text-foreground">{t("notifications.general")}</Label>
                    </div>
                    
                    <div className="flex items-center justify-between py-2">
                      <div className="space-y-0.5 flex-1">
                        <Label htmlFor="push_notifications" className="text-base text-foreground dark:text-foreground">{t("notifications.pushNotifications")}</Label>
                        <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("notifications.pushNotificationsDesc")}</p>
                      </div>
                      <Switch
                        id="push_notifications"
                        checked={preferences.push_notifications}
                        onCheckedChange={(checked) => {
                          setPreferences({ ...preferences, push_notifications: checked })
                          // Sync with notification preferences
                          if (notificationPreferences) {
                            setNotificationPreferences({
                              ...notificationPreferences,
                              push_enabled: checked,
                              in_app_enabled: checked
                            })
                          }
                        }}
                      />
                    </div>

                    <Separator />

                    <div className="flex items-center justify-between py-2">
                      <div className="space-y-0.5 flex-1">
                        <Label htmlFor="email_notifications" className="text-base text-foreground dark:text-foreground">{t("notifications.emailNotifications")}</Label>
                        <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("notifications.emailNotificationsDesc")}</p>
                      </div>
                      <Switch
                        id="email_notifications"
                        checked={preferences.email_notifications}
                        onCheckedChange={(checked) =>
                          setPreferences({ ...preferences, email_notifications: checked })
                        }
                      />
                    </div>
                  </div>

                  <Separator className="my-4" />

                  {/* Notification Types - Only show when push is enabled */}
                  {notificationPreferences && preferences.push_notifications && (
                    <div className="space-y-4">
                      <div className="flex items-center gap-2">
                        <Bell className="h-4 w-4 text-muted-foreground" />
                        <Label className="text-base font-medium text-foreground dark:text-foreground">{t("notifications.whatToNotify")}</Label>
                      </div>
                      
                      <div className="space-y-3 pl-2">
                        <div className="flex items-center justify-between py-2">
                          <div className="space-y-0.5 flex-1">
                            <Label htmlFor="push_achievements" className="text-sm text-foreground dark:text-foreground">{t("notifications.achievements")}</Label>
                            <p className="text-xs text-muted-foreground dark:text-muted-foreground">{t("notifications.achievementsDesc")}</p>
                          </div>
                          <Switch
                            id="push_achievements"
                            checked={notificationPreferences.push_achievements}
                            onCheckedChange={(checked) =>
                              setNotificationPreferences({ ...notificationPreferences, push_achievements: checked })
                            }
                          />
                        </div>

                        <Separator />

                        <div className="flex items-center justify-between py-2">
                          <div className="space-y-0.5 flex-1">
                            <Label htmlFor="push_reminders" className="text-sm text-foreground dark:text-foreground">{t("notifications.reminders")}</Label>
                            <p className="text-xs text-muted-foreground dark:text-muted-foreground">{t("notifications.remindersDesc")}</p>
                          </div>
                          <Switch
                            id="push_reminders"
                            checked={notificationPreferences.push_reminders}
                            onCheckedChange={(checked) =>
                              setNotificationPreferences({ ...notificationPreferences, push_reminders: checked })
                            }
                          />
                        </div>

                        <Separator />

                        <div className="flex items-center justify-between py-2">
                          <div className="space-y-0.5 flex-1">
                            <Label htmlFor="push_course_updates" className="text-sm text-foreground dark:text-foreground">{t("notifications.courseUpdates")}</Label>
                            <p className="text-xs text-muted-foreground dark:text-muted-foreground">{t("notifications.courseUpdatesDesc")}</p>
                          </div>
                          <Switch
                            id="push_course_updates"
                            checked={notificationPreferences.push_course_updates}
                            onCheckedChange={(checked) =>
                              setNotificationPreferences({ ...notificationPreferences, push_course_updates: checked })
                            }
                          />
                        </div>

                        <Separator />

                        <div className="flex items-center justify-between py-2">
                          <div className="space-y-0.5 flex-1">
                            <Label htmlFor="push_exercise_graded" className="text-sm text-foreground dark:text-foreground">{t("notifications.exerciseResults")}</Label>
                            <p className="text-xs text-muted-foreground dark:text-muted-foreground">{t("notifications.exerciseResultsDesc")}</p>
                          </div>
                          <Switch
                            id="push_exercise_graded"
                            checked={notificationPreferences.push_exercise_graded}
                            onCheckedChange={(checked) =>
                              setNotificationPreferences({ ...notificationPreferences, push_exercise_graded: checked })
                            }
                          />
                        </div>
                      </div>
                    </div>
                  )}

                  {notificationPreferences && !preferences.push_notifications && (
                    <div className="rounded-lg bg-muted/50 p-4 border border-border">
                      <p className="text-sm text-muted-foreground dark:text-muted-foreground text-center">
                        {t("notifications.enablePushToCustomize")}
                      </p>
                    </div>
                  )}

                  <Separator className="my-4" />

                  {/* Schedule Settings */}
                  <div className="space-y-4">
                    <div className="flex items-center gap-2">
                      <Clock className="h-4 w-4 text-muted-foreground" />
                      <Label className="text-base font-medium text-foreground dark:text-foreground">{t("notifications.schedule")}</Label>
                    </div>

                    <div className="space-y-3">
                      <div className="flex items-center justify-between py-2">
                        <div className="space-y-0.5 flex-1">
                          <Label htmlFor="study_reminders" className="text-base text-foreground dark:text-foreground">{t("notifications.studyReminders")}</Label>
                          <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("notifications.studyRemindersDesc")}</p>
                        </div>
                        <Switch
                          id="study_reminders"
                          checked={preferences.study_reminders}
                          onCheckedChange={(checked) =>
                            setPreferences({ ...preferences, study_reminders: checked })
                          }
                        />
                      </div>

                      <Separator />

                      <div className="flex items-center justify-between py-2">
                        <div className="space-y-0.5 flex-1">
                          <Label htmlFor="weekly_report" className="text-base text-foreground dark:text-foreground">{t("notifications.weeklyReport")}</Label>
                          <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("notifications.weeklyReportDesc")}</p>
                        </div>
                        <Switch
                          id="weekly_report"
                          checked={preferences.weekly_report}
                          onCheckedChange={(checked) =>
                            setPreferences({ ...preferences, weekly_report: checked })
                          }
                        />
                      </div>

                      {notificationPreferences && (
                        <>
                          <Separator />

                          <div className="flex items-center justify-between py-2">
                            <div className="space-y-0.5 flex-1">
                              <Label htmlFor="quiet_hours_enabled" className="text-base text-foreground dark:text-foreground">{t("notifications.quietHours")}</Label>
                              <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("notifications.quietHoursDesc")}</p>
                            </div>
                            <Switch
                              id="quiet_hours_enabled"
                              checked={notificationPreferences.quiet_hours_enabled}
                              onCheckedChange={(checked) =>
                                setNotificationPreferences({ ...notificationPreferences, quiet_hours_enabled: checked })
                              }
                            />
                          </div>

                          {notificationPreferences.quiet_hours_enabled && (
                            <div className="grid grid-cols-2 gap-4 mt-4 pl-2">
                              <div className="space-y-2">
                                <Label htmlFor="quiet_hours_start" className="text-sm text-foreground dark:text-foreground">{t("notifications.startTime")}</Label>
                                <input
                                  id="quiet_hours_start"
                                  type="time"
                                  value={notificationPreferences.quiet_hours_start?.substring(0, 5) || "22:00"}
                                  onChange={(e) => {
                                    const time = e.target.value + ":00"
                                    setNotificationPreferences({ ...notificationPreferences, quiet_hours_start: time })
                                  }}
                                  className="w-full px-3 py-2 border border-border rounded-md bg-background text-foreground text-sm"
                                />
                              </div>
                              <div className="space-y-2">
                                <Label htmlFor="quiet_hours_end" className="text-sm text-foreground dark:text-foreground">{t("notifications.endTime")}</Label>
                                <input
                                  id="quiet_hours_end"
                                  type="time"
                                  value={notificationPreferences.quiet_hours_end?.substring(0, 5) || "08:00"}
                                  onChange={(e) => {
                                    const time = e.target.value + ":00"
                                    setNotificationPreferences({ ...notificationPreferences, quiet_hours_end: time })
                                  }}
                                  className="w-full px-3 py-2 border border-border rounded-md bg-background text-foreground text-sm"
                                />
                              </div>
                            </div>
                          )}
                        </>
                      )}
                    </div>
                  </div>

                  {/* Advanced Settings */}
                  {notificationPreferences && (
                    <>
                      <Separator className="my-4" />

                      <div className="space-y-4">
                        <Label className="text-base font-medium text-foreground dark:text-foreground">{t("notifications.advanced")}</Label>
                        
                        <div className="space-y-2 pl-2">
                          <Label htmlFor="max_notifications_per_day" className="text-sm text-foreground dark:text-foreground">{t("notifications.maxNotificationsPerDay")}</Label>
                          <input
                            id="max_notifications_per_day"
                            type="number"
                            min="0"
                            max="100"
                            value={notificationPreferences.max_notifications_per_day}
                            onChange={(e) => {
                              const value = parseInt(e.target.value) || 0
                              setNotificationPreferences({ ...notificationPreferences, max_notifications_per_day: value })
                            }}
                            className="w-full md:w-[200px] px-3 py-2 border border-border rounded-md bg-background text-foreground"
                          />
                          <p className="text-xs text-muted-foreground dark:text-muted-foreground">
                            {t("notifications.maxNotificationsPerDayDesc")}
                          </p>
                        </div>
                      </div>
                    </>
                  )}
                </CardContent>
              </Card>

              {/* Display Section */}
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Monitor className="h-5 w-5 text-primary" />
                    <CardTitle>{t("display.title")}</CardTitle>
                  </div>
                  <CardDescription>{t("display.description")}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="space-y-2">
                    <Label htmlFor="theme" className="text-base text-foreground dark:text-foreground">{t("display.theme")}</Label>
                    <Select
                      value={preferences.theme}
                      onValueChange={(value: "light" | "dark" | "auto") =>
                        setPreferences({ ...preferences, theme: value })
                      }
                    >
                      <SelectTrigger id="theme" className="w-full md:w-[300px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="light">{t("display.themeLight")}</SelectItem>
                        <SelectItem value="dark">{t("display.themeDark")}</SelectItem>
                        <SelectItem value="auto">{t("display.themeAuto")}</SelectItem>
                      </SelectContent>
                    </Select>
                    <p className="text-sm text-muted-foreground dark:text-muted-foreground">{t("display.themeDesc")}</p>
                  </div>

                  <Separator />

                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <Label htmlFor="font_size" className="text-base font-medium text-foreground dark:text-foreground">{t("display.fontSize")}</Label>
                      <span className="text-sm text-muted-foreground dark:text-muted-foreground">
                        {preferences.font_size === "small" && "14px"}
                        {preferences.font_size === "medium" && "16px (Default)"}
                        {preferences.font_size === "large" && "18px"}
                      </span>
                    </div>
                    <Select
                      value={preferences.font_size}
                      onValueChange={(value: "small" | "medium" | "large") =>
                        setPreferences({ ...preferences, font_size: value })
                      }
                    >
                      <SelectTrigger id="font_size" className="w-full md:w-[300px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="small">
                          <span className="flex items-center gap-2">
                            <span className="text-xs">Aa</span>
                            <span>{t("display.fontSizeSmall")}</span>
                          </span>
                        </SelectItem>
                        <SelectItem value="medium">
                          <span className="flex items-center gap-2">
                            <span className="text-sm">Aa</span>
                            <span>{t("display.fontSizeMedium")}</span>
                          </span>
                        </SelectItem>
                        <SelectItem value="large">
                          <span className="flex items-center gap-2">
                            <span className="text-base">Aa</span>
                            <span>{t("display.fontSizeLarge")}</span>
                          </span>
                        </SelectItem>
                    </SelectContent>
                  </Select>
                    <p className="text-sm text-muted-foreground dark:text-muted-foreground">
                    {t("display.fontSizeDesc")}
                  </p>
                </div>

                <Separator />

                <div className="space-y-2">
                  <Label htmlFor="locale" className="text-base text-foreground dark:text-foreground">{t("display.language")}</Label>
                  <Select
                    value={preferences.locale}
                    onValueChange={(value: "vi" | "en") =>
                      setPreferences({ ...preferences, locale: value })
                    }
                  >
                    <SelectTrigger id="locale" className="w-full md:w-[300px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="vi">
                        <span className="flex items-center gap-2">
                          <span>🇻🇳</span>
                          <span>Tiếng Việt</span>
                        </span>
                      </SelectItem>
                      <SelectItem value="en">
                        <span className="flex items-center gap-2">
                          <span>🇬🇧</span>
                          <span>{t('settings.english')}</span>
                        </span>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                  <p className="text-sm text-muted-foreground dark:text-muted-foreground">
                    {t("display.languageDesc")}
                  </p>
                </div>
              </CardContent>
            </Card>

              {/* Study Preferences Section */}
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <BookOpen className="h-5 w-5 text-primary" />
                    <CardTitle>{t("study.title")}</CardTitle>
                  </div>
                  <CardDescription>{t("study.description")}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center justify-between py-2">
                    <div className="space-y-0.5 flex-1">
                      <Label htmlFor="auto_play_next_lesson" className="text-base">{t("study.autoPlayNext")}</Label>
                      <p className="text-sm text-muted-foreground">{t("study.autoPlayNextDesc")}</p>
                    </div>
                    <Switch
                      id="auto_play_next_lesson"
                      checked={preferences.auto_play_next_lesson}
                      onCheckedChange={(checked) =>
                        setPreferences({ ...preferences, auto_play_next_lesson: checked })
                      }
                    />
                  </div>

                  <Separator />

                  <div className="flex items-center justify-between py-2">
                    <div className="space-y-0.5 flex-1">
                      <Label htmlFor="show_answer_explanation" className="text-base">{t("study.showExplanations")}</Label>
                      <p className="text-sm text-muted-foreground">{t("study.showExplanationsDesc")}</p>
                    </div>
                    <Switch
                      id="show_answer_explanation"
                      checked={preferences.show_answer_explanation}
                      onCheckedChange={(checked) =>
                        setPreferences({ ...preferences, show_answer_explanation: checked })
                      }
                    />
                  </div>

                  <Separator />

                  <div className="space-y-2">
                    <Label htmlFor="playback_speed" className="text-base">{t("study.playbackSpeed")}</Label>
                    <Select
                      value={preferences.playback_speed.toString()}
                      onValueChange={(value) =>
                        setPreferences({ ...preferences, playback_speed: parseFloat(value) })
                      }
                    >
                      <SelectTrigger id="playback_speed" className="w-full md:w-[300px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="0.75">0.75x</SelectItem>
                        <SelectItem value="1.0">1.0x (Normal)</SelectItem>
                        <SelectItem value="1.25">1.25x</SelectItem>
                        <SelectItem value="1.5">1.5x</SelectItem>
                        <SelectItem value="2.0">2.0x</SelectItem>
                      </SelectContent>
                    </Select>
                    <p className="text-sm text-muted-foreground">{t("study.playbackSpeedDesc")}</p>
                  </div>
                </CardContent>
              </Card>

              {/* Privacy Section */}
              <Card>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Lock className="h-5 w-5 text-primary" />
                    <CardTitle>{t("privacy.title")}</CardTitle>
                  </div>
                  <CardDescription>{t("privacy.description")}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="profile_visibility" className="text-base">{t("privacy.profileVisibility")}</Label>
                    <Select
                      value={preferences.profile_visibility}
                      onValueChange={(value: "public" | "friends" | "private") =>
                        setPreferences({ ...preferences, profile_visibility: value })
                      }
                    >
                      <SelectTrigger id="profile_visibility" className="w-full md:w-[300px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="public">{t("privacy.profileVisibilityPublic")}</SelectItem>
                        <SelectItem value="friends">{t("privacy.profileVisibilityFriends")}</SelectItem>
                        <SelectItem value="private">{t("privacy.profileVisibilityPrivate")}</SelectItem>
                      </SelectContent>
                    </Select>
                    <p className="text-sm text-muted-foreground">{t("privacy.profileVisibilityDesc")}</p>
                  </div>

                  <Separator />

                  <div className="flex items-center justify-between py-2">
                    <div className="space-y-0.5 flex-1">
                      <Label htmlFor="show_study_stats" className="text-base">{t("privacy.showStudyStats")}</Label>
                      <p className="text-sm text-muted-foreground">{t("privacy.showStudyStatsDesc")}</p>
                    </div>
                    <Switch
                      id="show_study_stats"
                      checked={preferences.show_study_stats}
                      onCheckedChange={(checked) =>
                        setPreferences({ ...preferences, show_study_stats: checked })
                      }
                    />
                  </div>
                </CardContent>
              </Card>

              {/* Save Button */}
              <div className="flex justify-end pt-4">
                <Button type="submit" disabled={isSaving} size="lg" className="gap-2">
                  {isSaving ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Saving...
                    </>
                  ) : (
                    <>
                      <Save className="h-4 w-4" />
                      {t("saveButton")}
                    </>
                  )}
                </Button>
              </div>
            </form>
          ) : (
            <Card>
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground">{t("loadError")}</p>
              </CardContent>
            </Card>
          )}
        </div>
      </PageContainer>
    </AppLayout>
  )
}

