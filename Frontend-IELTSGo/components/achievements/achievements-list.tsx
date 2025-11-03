"use client"

import { useState, useEffect } from "react"
import { achievementsApi, type Achievement, type UserAchievement } from "@/lib/api/achievements"
import { AchievementCard } from "./achievement-card"
import { useToast } from "@/hooks/use-toast"
import { useTranslations } from "@/lib/i18n"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { Award, Trophy } from "lucide-react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

export function AchievementsList() {
  const t = useTranslations('achievements')
  const tCommon = useTranslations('common')
  const { toast } = useToast()
  const [allAchievements, setAllAchievements] = useState<Achievement[]>([])
  const [earnedAchievements, setEarnedAchievements] = useState<UserAchievement[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadAchievements()
  }, [])

  const loadAchievements = async () => {
    try {
      setLoading(true)
      const [all, earned] = await Promise.all([
        achievementsApi.getAllAchievements(),
        achievementsApi.getEarnedAchievements(),
      ])
      
      // Debug: Log achievement data to check structure
      if (process.env.NODE_ENV === 'development') {
        console.log('[Achievements] Raw API response:', { all, earned })
        if (all && all.length > 0) {
          console.log('[Achievements] First achievement full object:', JSON.stringify(all[0], null, 2))
          console.log('[Achievements] First achievement keys:', Object.keys(all[0]))
        }
      }
      
      setAllAchievements(all || [])
      setEarnedAchievements(earned || [])
    } catch (error: any) {
      console.error('[Achievements] Error loading achievements:', error)
      toast({
        title: tCommon('error'),
        description: error?.message || t('failed_to_load_achievements'),
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <PageLoading translationKey="loading_achievements" />
  }

  // Create a map of earned achievement IDs
  const earnedIds = new Set(
    earnedAchievements.map(ea => {
      // Handle both nested and flat structures
      if (ea.achievement) {
        return ea.achievement.id
      }
      return ea.achievement_id
    })
  )

  // Separate achievements into earned and available
  const earned = allAchievements.filter(a => earnedIds.has(a.id))
  const available = allAchievements.filter(a => !earnedIds.has(a.id))

  return (
    <Tabs defaultValue="earned" className="space-y-6">
      <TabsList>
        <TabsTrigger value="earned">
          {t('earned_achievements')} ({earned.length})
        </TabsTrigger>
        <TabsTrigger value="available">
          {t('all_achievements')} ({allAchievements.length})
        </TabsTrigger>
      </TabsList>

      <TabsContent value="earned" className="space-y-6">
        {earned.length === 0 ? (
          <EmptyState
            icon={Trophy}
            title={t('no_earned')}
            description={t('no_earned_description')}
          />
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {earned.map((achievement, index) => {
              const userAchievement = earnedAchievements.find(
                ea => (ea.achievement?.id || ea.achievement_id) === achievement.id
              )
              return (
                <AchievementCard
                  key={achievement.id || `earned-${index}`}
                  achievement={achievement}
                  earned={true}
                  earnedAt={userAchievement?.earned_at || userAchievement?.earned_at_flat}
                />
              )
            })}
          </div>
        )}
      </TabsContent>

      <TabsContent value="available" className="space-y-6">
        {available.length === 0 ? (
          <EmptyState
            icon={Award}
            title={t('no_available') || t('no_achievements') || 'No achievements available'}
            description={t('all_achievements_earned')}
          />
        ) : (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {available.map((achievement, index) => (
              <AchievementCard
                key={achievement.id || `available-${index}`}
                achievement={achievement}
                earned={false}
              />
            ))}
          </div>
        )}
      </TabsContent>
    </Tabs>
  )
}

