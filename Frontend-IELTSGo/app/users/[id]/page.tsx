"use client"

import { cn } from "@/lib/utils"

import { useState, useEffect } from "react"
import { useParams } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { socialApi } from "@/lib/api/notifications"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Award, BookOpen, UserPlus, UserMinus, Trophy, Target, Zap, Lock, Edit2, Eye, EyeOff, UserX, Loader2 } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Label } from "@/components/ui/label"
import Link from "next/link"
import { useAuth } from "@/lib/contexts/auth-context"
import { userApi } from "@/lib/api/user"
import { useTranslations } from '@/lib/i18n'
import { useToast } from "@/hooks/use-toast"

interface UserProfile {
  id: string
  fullName: string
  email: string
  avatar?: string
  bio?: string
  level: number
  points: number
  coursesCompleted: number
  exercisesCompleted: number
  studyTime: number
  streak: number
  followersCount: number
  followingCount: number
  isFollowing: boolean
}

interface Achievement {
  id: string
  title: string
  description: string
  icon: string
  unlockedAt: string
  rarity: "common" | "rare" | "epic" | "legendary"
}

export default function UserProfilePage() {

  const t = useTranslations('common')
  const { toast } = useToast()

  const params = useParams()
  const userId = params.id as string
  const { user: currentUser } = useAuth()
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [achievements, setAchievements] = useState<Achievement[]>([])
  const [loading, setLoading] = useState(true)
  
  // Followers/Following modal state
  const [showFollowModal, setShowFollowModal] = useState(false)
  const [followersTab, setFollowersTab] = useState<"followers" | "following">("followers")
  const [followers, setFollowers] = useState<any[]>([])
  const [following, setFollowing] = useState<any[]>([])
  const [followersPage, setFollowersPage] = useState(1)
  const [followingPage, setFollowingPage] = useState(1)
  const [followersPagination, setFollowersPagination] = useState<any>(null)
  const [followingPagination, setFollowingPagination] = useState<any>(null)
  const [loadingFollows, setLoadingFollows] = useState(false)
  const [followLoading, setFollowLoading] = useState(false)
  const [profileVisibility, setProfileVisibilityState] = useState<"public" | "friends" | "private">("public")
  const [updatingVisibility, setUpdatingVisibility] = useState(false)

  const isOwnProfile = currentUser?.id === userId
  
  // ✅ Check if profile should be visible
  const isProfileVisible = () => {
    if (isOwnProfile) return true // Always visible to owner
    if (profileVisibility === "public") return true
    if (profileVisibility === "private") return false
    if (profileVisibility === "friends") {
      // Friends-only: Only visible if already following (mutual follow required to follow)
      // If we can see the profile, it means visibility check passed from backend
      // So we trust the backend response - if profile is loaded, it's visible
      // If not loaded (403 error), it's not visible
      return profile !== null // If profile loaded successfully, it's visible
    }
    return true
  }

  // Load profile visibility preference
  const loadProfileVisibility = async () => {
    if (!isOwnProfile) return
    try {
      const prefs = await userApi.getPreferences()
      setProfileVisibilityState(prefs.profile_visibility || "public")
    } catch (error) {
      console.error("Failed to load profile visibility:", error)
      setProfileVisibilityState("public") // Default to public
    }
  }

  // Update profile visibility
  const handleVisibilityChange = async (value: "public" | "friends" | "private") => {
    if (!isOwnProfile || updatingVisibility) return
    
    setUpdatingVisibility(true)
    const previousVisibility = profileVisibility
    
    // Optimistic update
    setProfileVisibilityState(value)
    
    try {
      await userApi.updatePreferences({
        profile_visibility: value,
      })
      
      // Show success toast
      toast({
        title: t('profile_visibility_updated'),
        description: t('profile_visibility_updated_description'),
      })
    } catch (error) {
      console.error("Failed to update profile visibility:", error)
      // Revert on error
      setProfileVisibilityState(previousVisibility)
      toast({
        title: t('error'),
        description: t('failed_to_update_visibility'),
        variant: "destructive",
      })
    } finally {
      setUpdatingVisibility(false)
    }
  }

  useEffect(() => {
    loadProfile()
    loadAchievements()
    if (isOwnProfile) {
      loadProfileVisibility()
    }
  }, [userId])

  const loadProfile = async () => {
    try {
      setLoading(true)
      console.log("[Profile] Loading profile for userId:", userId)
      const data = await socialApi.getUserProfile(userId)
      console.log("[Profile] Backend response:", data)
      
      // Map BE response to FE UserProfile interface
      // BE returns: user_id, full_name, email, avatar_url, bio, level, points, 
      //             courses_completed, exercises_completed, study_time, streak,
      //             followers_count, following_count, is_following, profile_visibility
      const mappedProfile = {
        id: data.user_id || data.id || userId,
        fullName: data.full_name || data.fullName || "User",
        email: data.email || "",
        avatar: data.avatar_url || data.avatar || undefined,
        bio: data.bio || undefined,
        level: Number(data.level) || 0,
        points: Number(data.points) || 0,
        coursesCompleted: Number(data.courses_completed || data.coursesCompleted) || 0,
        exercisesCompleted: Number(data.exercises_completed || data.exercisesCompleted) || 0,
        studyTime: Number(data.study_time || data.studyTime) || 0,
        streak: Number(data.streak || data.current_streak_days) || 0,
        followersCount: Number(data.followers_count || data.followersCount) || 0,
        followingCount: Number(data.following_count || data.followingCount) || 0,
        isFollowing: Boolean(data.is_following || data.isFollowing) || false,
      }
      
      console.log("[Profile] Mapped profile:", mappedProfile)
      setProfile(mappedProfile)
      
      // ✅ Load profile visibility preference from backend response
      if (!isOwnProfile) {
        // Other user's profile: check visibility from response
        if (data.profile_visibility) {
          setProfileVisibilityState(data.profile_visibility)
        } else {
          // Default to public if not provided (backward compatibility)
          setProfileVisibilityState("public")
        }
      }
    } catch (error: any) {
      // Handle specific error cases - don't log 403 as error (expected for private profiles)
      if (error?.response?.status === 403 || error?.message?.includes("private")) {
        // Profile is private - this is expected behavior, not an error
        setProfileVisibilityState("private")
        setProfile({
          id: userId,
          fullName: "User",
          email: "",
          level: 0,
          points: 0,
          coursesCompleted: 0,
          exercisesCompleted: 0,
          studyTime: 0,
          streak: 0,
          followersCount: 0,
          followingCount: 0,
          isFollowing: false,
        })
      } else if (error?.response?.status === 404 || error?.message?.includes("not found")) {
        // Profile not found
        console.warn("User profile not found:", userId)
        setProfile(null)
      } else {
        // Other unexpected errors - log as error
        console.error("Failed to load profile:", error)
        setProfile(null)
      }
    } finally {
      setLoading(false)
    }
  }

  const loadAchievements = async () => {
    try {
      const data = await socialApi.getUserAchievements(userId)
      // BE returns: [{ achievement_id, title, description, icon, rarity, unlocked_at }]
      const mappedAchievements = (data || []).map((achievement: any) => ({
        id: achievement.achievement_id || achievement.id || "",
        title: achievement.title || "",
        description: achievement.description || "",
        icon: achievement.icon || "🏆",
        unlockedAt: achievement.unlocked_at || achievement.unlockedAt || new Date().toISOString(),
        rarity: achievement.rarity || "common",
      }))
      setAchievements(mappedAchievements)
    } catch (error) {
      console.error("Failed to load achievements:", error)
      setAchievements([]) // Empty array on error instead of mock data
    }
  }

  const handleFollow = async () => {
    if (!profile || isOwnProfile) {
      console.warn("Cannot follow: no profile or own profile")
      return
    }
    
    if (followLoading) {
      console.warn("Follow action already in progress")
      return
    }
    
    const wasFollowing = profile.isFollowing
    const previousCount = profile.followersCount
    
    console.log("[Follow] Starting:", { wasFollowing, userId, previousCount })
    
    setFollowLoading(true)
    
    // Optimistic update
    setProfile({
      ...profile,
      isFollowing: !wasFollowing,
      followersCount: wasFollowing ? Math.max(0, previousCount - 1) : previousCount + 1,
    })
    
    try {
      if (wasFollowing) {
        console.log("[Follow] Unfollowing user:", userId)
        await socialApi.unfollowUser(userId)
        console.log("[Follow] Unfollow successful")
      } else {
        console.log("[Follow] Following user:", userId)
        await socialApi.followUser(userId)
        console.log("[Follow] Follow successful")
      }
      
      // Reload profile to get accurate counts from BE
      console.log("[Follow] Reloading profile...")
      await loadProfile()
      console.log("[Follow] Profile reloaded")
      
      // Show success toast
      toast({
        title: wasFollowing ? t('unfollowed_successfully') : t('followed_successfully'),
        description: wasFollowing 
          ? t('user_unfollowed_description') 
          : t('user_followed_description'),
      })
    } catch (error: any) {
      console.error("[Follow] Error:", error)
      console.error("[Follow] Error response:", error?.response?.data)
      
      // Revert optimistic update on error
      setProfile({
        ...profile,
        isFollowing: wasFollowing,
        followersCount: previousCount,
      })
      
      // Show error message to user
      const errorMessage = error?.response?.data?.error?.message 
        || error?.message 
        || t('failed_to_update_follow_status')
      
      // Use more user-friendly error display
      if (error?.response?.data?.error?.code === "CANNOT_FOLLOW_SELF") {
        toast({
          title: t('error'),
          description: t('cannot_follow_self'),
          variant: "destructive",
        })
      } else if (error?.response?.data?.error?.code === "CANNOT_FOLLOW_PRIVATE") {
        toast({
          title: t('error'),
          description: t('cannot_follow_private_profile'),
          variant: "destructive",
        })
      } else if (error?.response?.data?.error?.code === "CANNOT_FOLLOW_FRIENDS_ONLY") {
        toast({
          title: t('error'),
          description: t('cannot_follow_friends_only'),
          variant: "destructive",
        })
      } else {
        toast({
          title: t('error'),
          description: errorMessage,
          variant: "destructive",
        })
      }
    } finally {
      setFollowLoading(false)
    }
  }

  const loadFollowers = async (page = 1) => {
    try {
      setLoadingFollows(true)
      const response = await socialApi.getFollowers(userId, page, 20)
      setFollowers(response.followers || [])
      setFollowersPagination(response.pagination)
      setFollowersPage(page)
    } catch (error: any) {
      console.error("Failed to load followers:", error)
      // Handle 403 Forbidden for private/friends-only lists
      if (error?.response?.status === 403) {
        toast({
          title: t('access_denied'),
          description: t('followers_list_private'),
          variant: "destructive",
        })
        setShowFollowModal(false)
      }
      setFollowers([])
      setFollowersPagination(null)
    } finally {
      setLoadingFollows(false)
    }
  }

  const loadFollowing = async (page = 1) => {
    try {
      setLoadingFollows(true)
      const response = await socialApi.getFollowing(userId, page, 20)
      setFollowing(response.following || [])
      setFollowingPagination(response.pagination)
      setFollowingPage(page)
    } catch (error: any) {
      console.error("Failed to load following:", error)
      // Handle 403 Forbidden for private/friends-only lists
      if (error?.response?.status === 403) {
        toast({
          title: t('access_denied'),
          description: t('following_list_private'),
          variant: "destructive",
        })
        setShowFollowModal(false)
      }
      setFollowing([])
      setFollowingPagination(null)
    } finally {
      setLoadingFollows(false)
    }
  }

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case "common":
        return "bg-gray-100 text-gray-700 border-gray-300"
      case "rare":
        return "bg-blue-100 text-blue-700 border-blue-300"
      case "epic":
        return "bg-purple-100 text-purple-700 border-purple-300"
      case "legendary":
        return "bg-yellow-100 text-yellow-700 border-yellow-300"
      default:
        return "bg-gray-100 text-gray-700"
    }
  }

  if (loading) {
    return (
      <AppLayout showSidebar={false} showFooter>
        <PageContainer>
          <PageLoading translationKey="loading_profile" />
        </PageContainer>
      </AppLayout>
    )
  }

  // Handle profile not found (404) or null
  if (!profile || (profile.id === userId && !profile.fullName)) {
    return (
      <AppLayout showSidebar={false} showFooter>
        <PageContainer>
          <EmptyState
            icon={Lock}
            title={t('profile_not_found') || "Profile Not Found"}
            description={t('profile_not_found_description') || "The user profile you are looking for could not be found."}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  // Handle private profile (only show message if not own profile and profile is private)
  if (!isOwnProfile && profileVisibility === "private" && !isProfileVisible()) {
    return (
      <AppLayout showSidebar={false} showFooter>
        <PageContainer>
          <EmptyState
            icon={Lock}
            title={t('profile_is_private') || "Profile is Private"}
            description={t('this_user_has_set_their_profile_to_private') || "This user has set their profile to private."}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  return (
    <AppLayout showSidebar={false} showFooter>
      <PageContainer maxWidth="7xl">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold tracking-tight">{t('profile')}</h1>
          <p className="text-base text-muted-foreground mt-2">
            {isOwnProfile ? t('view_your_public_profile') : t('user_profile')}
          </p>
        </div>

        {/* Profile Header */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex flex-col md:flex-row gap-6">
              <Avatar className="h-28 w-28 border-4 border-background shadow-lg">
                <AvatarImage src={profile.avatar || "/placeholder.svg"} />
                <AvatarFallback className="text-2xl bg-primary text-primary-foreground">
                  {profile.fullName.charAt(0).toUpperCase()}
                </AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <div className="flex items-start justify-between gap-4 mb-3">
                  <div className="flex-1 min-w-0">
                    <h2 className="text-2xl font-bold tracking-tight mb-1">{profile.fullName}</h2>
                    <p className="text-muted-foreground truncate">{profile.email}</p>
                  </div>
                  {isOwnProfile ? (
                    <Button asChild variant="outline" size="default" className="flex-shrink-0">
                      <Link href="/profile">
                        <Edit2 className="h-4 w-4 mr-2" />
                        <span className="whitespace-nowrap">{t('edit_profile')}</span>
                      </Link>
                    </Button>
                  ) : (
                    // Only show follow button if profile is visible (not private)
                    isProfileVisible() && (
                      <Button 
                        onClick={(e) => {
                          e.preventDefault()
                          e.stopPropagation()
                          handleFollow()
                        }}
                        variant={profile.isFollowing ? "outline" : "default"}
                        disabled={followLoading}
                        className="h-9 flex-shrink-0"
                      >
                        {followLoading ? (
                          <>
                            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                            {t('loading')}...
                          </>
                        ) : profile.isFollowing ? (
                          <>
                            <UserMinus className="h-4 w-4 mr-2" />
                            {t('unfollow')}
                          </>
                        ) : (
                          <>
                            <UserPlus className="h-4 w-4 mr-2" />
                            {t('follow')}
                          </>
                        )}
                      </Button>
                    )
                  )}
                </div>
                {profile.bio && (
                  <p className="text-sm text-muted-foreground mb-4 leading-relaxed">{profile.bio}</p>
                )}
                
                {/* Profile Settings and Stats - Combined section */}
                <div className="space-y-4 pt-4 border-t">
                  {/* Profile Visibility Toggle - Only for own profile */}
                  {isOwnProfile && (
                    <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                      <div className="flex items-center gap-2.5 flex-1 min-w-0">
                        {profileVisibility === "private" ? (
                          <EyeOff className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                        ) : (
                          <Eye className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                        )}
                        <div className="flex-1 min-w-0">
                          <Label htmlFor="profile_visibility" className="text-sm font-medium leading-none block mb-1.5">
                            {t('profile_visibility')}
                          </Label>
                          <p className="text-xs text-muted-foreground leading-snug line-clamp-2">
                            {profileVisibility === "public" && t('profile_visibility_public_desc')}
                            {profileVisibility === "friends" && t('profile_visibility_friends_desc')}
                            {profileVisibility === "private" && t('profile_visibility_private_desc')}
                          </p>
                        </div>
                      </div>
                      <div className="flex-shrink-0">
                        <Select
                          value={profileVisibility}
                          onValueChange={handleVisibilityChange}
                          disabled={updatingVisibility}
                        >
                          <SelectTrigger id="profile_visibility" className="h-9 px-3 w-full sm:w-[200px] flex-shrink-0">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="public">
                              {t('profile_visibility_public')}
                            </SelectItem>
                            <SelectItem value="friends">
                              {t('profile_visibility_friends')}
                            </SelectItem>
                            <SelectItem value="private">
                              {t('profile_visibility_private')}
                            </SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                  )}
                  
                  {/* Only show followers/following counts and buttons if profile is visible */}
                  {isProfileVisible() && (
                    <div className="flex flex-wrap items-center gap-6 text-sm">
                      <button
                        onClick={() => {
                          setFollowersTab("followers")
                          setShowFollowModal(true)
                          loadFollowers(1)
                        }}
                        className="hover:underline cursor-pointer"
                      >
                        <span className="font-semibold">{profile.followersCount}</span>
                        <span className="text-muted-foreground ml-1">{t('followers')}</span>
                      </button>
                      <button
                        onClick={() => {
                          setFollowersTab("following")
                          setShowFollowModal(true)
                          loadFollowing(1)
                        }}
                        className="hover:underline cursor-pointer"
                      >
                        <span className="font-semibold">{profile.followingCount}</span>
                        <span className="text-muted-foreground ml-1">{t('following')}</span>
                      </button>
                      <div>
                        <Badge variant="secondary">{t('level')} {profile.level}</Badge>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Stats Grid - Only show if profile is visible */}
        {isProfileVisible() ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <div className="p-3 rounded-full bg-yellow-100 dark:bg-yellow-900/20">
                    <Trophy className="h-6 w-6 text-yellow-600 dark:text-yellow-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-2xl font-bold">{profile.points}</p>
                    <p className="text-sm text-muted-foreground">{t('total_points')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <div className="p-3 rounded-full bg-blue-100 dark:bg-blue-900/20">
                    <BookOpen className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-2xl font-bold">{profile.coursesCompleted}</p>
                    <p className="text-sm text-muted-foreground">{t('courses_completed')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <div className="p-3 rounded-full bg-green-100 dark:bg-green-900/20">
                    <Target className="h-6 w-6 text-green-600 dark:text-green-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-2xl font-bold">{profile.exercisesCompleted}</p>
                    <p className="text-sm text-muted-foreground">{t('exercises_done')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center gap-4">
                  <div className="p-3 rounded-full bg-orange-100 dark:bg-orange-900/20">
                    <Zap className="h-6 w-6 text-orange-600 dark:text-orange-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-2xl font-bold">{profile.streak}</p>
                    <p className="text-sm text-muted-foreground">{t('day_streak')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : (
          <Card className="mb-6">
            <CardContent className="pt-6">
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <Lock className="h-12 w-12 text-muted-foreground mb-4" />
                <p className="text-lg font-semibold mb-2">{t('profile_is_private')}</p>
                <p className="text-sm text-muted-foreground">
                  {t('this_user_has_set_their_profile_to_private')}
                </p>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Achievements */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-xl">
              <Award className="h-5 w-5" />
              {t('achievements')} ({achievements.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-6">
            {achievements.length === 0 ? (
              <div className="text-center py-12 text-muted-foreground">
                <Award className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p className="text-sm">{t('no_achievements')}</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {achievements.map((achievement) => (
                  <div 
                    key={achievement.id} 
                    className={cn(
                      "p-4 rounded-lg border-2 transition-all hover:shadow-md",
                      getRarityColor(achievement.rarity)
                    )}
                  >
                    <div className="flex items-start gap-3">
                      <div className="text-3xl flex-shrink-0">{achievement.icon}</div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold mb-1 text-sm">{achievement.title}</h4>
                        <p className="text-xs opacity-80 mb-2 leading-relaxed">{achievement.description}</p>
                        <p className="text-xs opacity-60">
                          {t('unlocked')} {new Date(achievement.unlockedAt).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Followers/Following Modal */}
        <Dialog open={showFollowModal} onOpenChange={setShowFollowModal}>
          <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>
                {followersTab === "followers" ? t('followers') : t('following')}
              </DialogTitle>
            </DialogHeader>
            <Tabs value={followersTab} onValueChange={(v) => {
              setFollowersTab(v as "followers" | "following")
              if (v === "followers") {
                loadFollowers(1)
              } else {
                loadFollowing(1)
              }
            }}>
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="followers">
                  {t('followers')} {followersPagination && `(${followersPagination.total})`}
                </TabsTrigger>
                <TabsTrigger value="following">
                  {t('following')} {followingPagination && `(${followingPagination.total})`}
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="followers" className="mt-4">
                {loadingFollows ? (
                  <div className="text-center py-8">{t('loading')}...</div>
                ) : followers.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    {t('no_followers') || "No followers yet"}
                  </div>
                ) : (
                  <div className="space-y-2">
                    {followers.map((user) => (
                      <div
                        key={user.user_id}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-accent transition-colors"
                      >
                        <Link
                          href={`/users/${user.user_id}`}
                          className="flex items-center gap-3 flex-1"
                        >
                          <Avatar className="h-10 w-10">
                            <AvatarImage src={user.avatar_url || "/placeholder.svg"} />
                            <AvatarFallback>
                              {user.full_name?.charAt(0).toUpperCase() || "U"}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <p className="font-semibold">{user.full_name || "User"}</p>
                            {user.bio && (
                              <p className="text-sm text-muted-foreground line-clamp-1">{user.bio}</p>
                            )}
                            <div className="flex gap-4 text-xs text-muted-foreground mt-1">
                              <span>{t('level')} {user.level}</span>
                              <span>{user.points} {t('points') || "points"}</span>
                            </div>
                          </div>
                        </Link>
                        {/* Show remove button only if viewing own profile's followers */}
                        {isOwnProfile && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={async (e) => {
                              e.preventDefault()
                              e.stopPropagation()
                              if (confirm(t('remove_follower_confirm'))) {
                                try {
                                  await socialApi.removeFollower(user.user_id)
                                  // Reload followers list
                                  await loadFollowers(followersPage)
                                  // Reload profile to update count
                                  await loadProfile()
                                  // Show success toast
                                  toast({
                                    title: t('follower_removed_successfully'),
                                    description: t('follower_removed_description'),
                                  })
                                } catch (error: any) {
                                  toast({
                                    title: t('error'),
                                    description: error?.response?.data?.error?.message || error?.message || t('failed_to_remove_follower'),
                                    variant: "destructive",
                                  })
                                }
                              }
                            }}
                            className="text-muted-foreground hover:text-destructive"
                          >
                            <UserX className="h-4 w-4" />
                          </Button>
                        )}
                      </div>
                    ))}
                    
                    {/* Pagination */}
                    {followersPagination && followersPagination.total_pages > 1 && (
                      <div className="flex justify-center gap-2 mt-4">
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={followersPage === 1}
                          onClick={() => loadFollowers(followersPage - 1)}
                        >
                          {t('previous') || "Previous"}
                        </Button>
                        <span className="flex items-center text-sm text-muted-foreground">
                          {t('page') || "Page"} {followersPage} / {followersPagination.total_pages}
                        </span>
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={followersPage >= followersPagination.total_pages}
                          onClick={() => loadFollowers(followersPage + 1)}
                        >
                          {t('next') || "Next"}
                        </Button>
                      </div>
                    )}
                  </div>
                )}
              </TabsContent>
              
              <TabsContent value="following" className="mt-4">
                {loadingFollows ? (
                  <div className="text-center py-8">{t('loading')}...</div>
                ) : following.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    {t('no_following') || "Not following anyone yet"}
                  </div>
                ) : (
                  <div className="space-y-2">
                    {following.map((user) => (
                      <div
                        key={user.user_id}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-accent transition-colors"
                      >
                        <Link
                          href={`/users/${user.user_id}`}
                          className="flex items-center gap-3 flex-1"
                        >
                          <Avatar className="h-10 w-10">
                            <AvatarImage src={user.avatar_url || "/placeholder.svg"} />
                            <AvatarFallback>
                              {user.full_name?.charAt(0).toUpperCase() || "U"}
                            </AvatarFallback>
                          </Avatar>
                          <div className="flex-1">
                            <p className="font-semibold">{user.full_name || "User"}</p>
                            {user.bio && (
                              <p className="text-sm text-muted-foreground line-clamp-1">{user.bio}</p>
                            )}
                            <div className="flex gap-4 text-xs text-muted-foreground mt-1">
                              <span>{t('level')} {user.level}</span>
                              <span>{user.points} {t('points') || "points"}</span>
                            </div>
                          </div>
                        </Link>
                        {/* Show unfollow button only if viewing own profile's following list */}
                        {isOwnProfile && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={async (e) => {
                              e.preventDefault()
                              e.stopPropagation()
                              if (confirm(t('unfollow_confirm'))) {
                                try {
                                  await socialApi.unfollowUser(user.user_id)
                                  // Reload following list
                                  await loadFollowing(followingPage)
                                  // Reload profile to update count
                                  await loadProfile()
                                  // Show success toast
                                  toast({
                                    title: t('unfollowed_successfully'),
                                    description: t('user_unfollowed_description'),
                                  })
                                } catch (error: any) {
                                  toast({
                                    title: t('error'),
                                    description: error?.response?.data?.error?.message || error?.message || t('failed_to_unfollow'),
                                    variant: "destructive",
                                  })
                                }
                              }
                            }}
                            className="text-muted-foreground hover:text-destructive"
                          >
                            <UserMinus className="h-4 w-4" />
                          </Button>
                        )}
                      </div>
                    ))}
                    
                    {/* Pagination */}
                    {followingPagination && followingPagination.total_pages > 1 && (
                      <div className="flex justify-center gap-2 mt-4">
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={followingPage === 1}
                          onClick={() => loadFollowing(followingPage - 1)}
                        >
                          {t('previous') || "Previous"}
                        </Button>
                        <span className="flex items-center text-sm text-muted-foreground">
                          {t('page') || "Page"} {followingPage} / {followingPagination.total_pages}
                        </span>
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={followingPage >= followingPagination.total_pages}
                          onClick={() => loadFollowing(followingPage + 1)}
                        >
                          {t('next') || "Next"}
                        </Button>
                      </div>
                    )}
                  </div>
                )}
              </TabsContent>
            </Tabs>
          </DialogContent>
        </Dialog>
      </PageContainer>
    </AppLayout>
  )
}
