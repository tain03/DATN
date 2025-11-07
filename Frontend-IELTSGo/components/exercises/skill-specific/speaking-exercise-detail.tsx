"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Mic, Clock, MessageSquare, ListChecks, HelpCircle } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

interface SpeakingExerciseDetailProps {
  exercise: {
    speaking_part_number?: number
    speaking_prompt_text?: string
    speaking_cue_card_topic?: string
    speaking_cue_card_points?: string[]
    speaking_follow_up_questions?: string[]
    speaking_preparation_time_seconds?: number
    speaking_response_time_seconds?: number
    time_limit_minutes?: number
  }
}

export function SpeakingExerciseDetail({ exercise }: SpeakingExerciseDetailProps) {
  const t = useTranslations('exercises')
  
  const partNumber = exercise.speaking_part_number || 1
  const isPart1 = partNumber === 1
  const isPart2 = partNumber === 2
  const isPart3 = partNumber === 3

  const partConfig = {
    1: {
      title: t('speaking_part_1'),
      description: t('speaking_part_1_desc'),
      color: "bg-blue-500",
      icon: MessageSquare
    },
    2: {
      title: t('speaking_part_2'),
      description: t('speaking_part_2_desc'),
      color: "bg-purple-500",
      icon: ListChecks
    },
    3: {
      title: t('speaking_part_3'),
      description: t('speaking_part_3_desc'),
      color: "bg-orange-500",
      icon: HelpCircle
    }
  }

  const config = partConfig[partNumber as 1 | 2 | 3]
  const Icon = config.icon

  return (
    <div className="space-y-6">
      {/* Part Info Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Icon className="w-5 h-5" />
            {config.title}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">{config.description}</p>
          
          <div className="grid grid-cols-2 gap-4 pt-2">
            {isPart2 && (
              <>
                <div className="flex items-center gap-3">
                  <Clock className="w-5 h-5 text-blue-500" />
                  <div>
                    <p className="text-sm text-muted-foreground">{t('preparation_time')}</p>
                    <p className="font-medium">{(exercise.speaking_preparation_time_seconds || 60) / 60} {t('minutes')}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Mic className="w-5 h-5 text-purple-500" />
                  <div>
                    <p className="text-sm text-muted-foreground">{t('speaking_time')}</p>
                    <p className="font-medium">{(exercise.speaking_response_time_seconds || 120) / 60} {t('minutes')}</p>
                  </div>
                </div>
              </>
            )}
            {(isPart1 || isPart3) && (
              <div className="flex items-center gap-3 col-span-2">
                <Clock className="w-5 h-5 text-muted-foreground" />
                <div>
                  <p className="text-sm text-muted-foreground">{t('expected_time')}</p>
                  <p className="font-medium">{exercise.time_limit_minutes || 5} {t('minutes')}</p>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Prompt Card */}
      <Card>
        <CardHeader>
          <CardTitle>
            {isPart1 && t('discussion_questions')}
            {isPart2 && t('cue_card_topic')}
            {isPart3 && t('in_depth_questions')}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Main Prompt */}
          {exercise.speaking_prompt_text && (
            <div className="p-4 rounded-lg bg-purple-50 dark:bg-purple-950 border border-purple-200 dark:border-purple-800">
              <p className="text-sm leading-relaxed whitespace-pre-wrap">
                {exercise.speaking_prompt_text}
              </p>
            </div>
          )}

          {/* Cue Card Points for Part 2 */}
          {isPart2 && exercise.speaking_cue_card_points && exercise.speaking_cue_card_points.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <ListChecks className="w-4 h-4 text-purple-500" />
                <h4 className="font-semibold">{t('points_to_cover')}</h4>
              </div>
              <div className="space-y-2">
                {exercise.speaking_cue_card_points.map((point, index) => (
                  <div key={index} className="flex items-start gap-3 p-3 rounded-lg border bg-card">
                    <div className="w-6 h-6 rounded-full bg-purple-500 text-white flex items-center justify-center text-xs font-semibold flex-shrink-0">
                      {index + 1}
                    </div>
                    <p className="text-sm">{point}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Follow-up Questions for Part 3 */}
          {isPart3 && exercise.speaking_follow_up_questions && exercise.speaking_follow_up_questions.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <HelpCircle className="w-4 h-4 text-orange-500" />
                <h4 className="font-semibold">{t('follow_up_questions')}</h4>
              </div>
              <div className="space-y-2">
                {exercise.speaking_follow_up_questions.map((question, index) => (
                  <div key={index} className="flex items-start gap-3 p-3 rounded-lg border bg-card">
                    <div className="w-6 h-6 rounded-full bg-orange-500 text-white flex items-center justify-center text-xs font-semibold flex-shrink-0">
                      {index + 1}
                    </div>
                    <p className="text-sm">{question}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Evaluation Criteria Card */}
      <Card>
        <CardHeader>
          <CardTitle>{t('speaking_evaluation_criteria')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            <div className="flex items-start gap-3 p-3 rounded-lg border">
              <div className="w-2 h-2 rounded-full bg-blue-500 mt-2" />
              <div>
                <h4 className="font-semibold mb-1">{t('fluency_coherence')}</h4>
                <p className="text-sm text-muted-foreground">
                  {t('fluency_coherence_desc')}
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg border">
              <div className="w-2 h-2 rounded-full bg-green-500 mt-2" />
              <div>
                <h4 className="font-semibold mb-1">{t('lexical_resource_speaking')}</h4>
                <p className="text-sm text-muted-foreground">
                  {t('lexical_resource_speaking_desc')}
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg border">
              <div className="w-2 h-2 rounded-full bg-purple-500 mt-2" />
              <div>
                <h4 className="font-semibold mb-1">{t('grammatical_range_speaking')}</h4>
                <p className="text-sm text-muted-foreground">
                  {t('grammatical_range_speaking_desc')}
                </p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg border">
              <div className="w-2 h-2 rounded-full bg-orange-500 mt-2" />
              <div>
                <h4 className="font-semibold mb-1">{t('pronunciation')}</h4>
                <p className="text-sm text-muted-foreground">
                  {t('pronunciation_desc')}
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tips Card */}
      <Card className={`border-l-4 ${
        isPart1 ? 'border-l-blue-500 bg-blue-50/30 dark:bg-blue-950/20' :
        isPart2 ? 'border-l-purple-500 bg-purple-50/30 dark:bg-purple-950/20' :
        'border-l-orange-500 bg-orange-50/30 dark:bg-orange-950/20'
      }`}>
        <CardHeader>
          <CardTitle className="text-base">💡 {t('speaking_tips')}</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm text-muted-foreground">
            {isPart1 && (
              <>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part1_1')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part1_2')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part1_3')}</li>
              </>
            )}
            {isPart2 && (
              <>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part2_1')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part2_2')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part2_3')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part2_4')}</li>
              </>
            )}
            {isPart3 && (
              <>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part3_1')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part3_2')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part3_3')}</li>
                <li className="flex gap-2"><span className="text-primary">•</span> {t('speaking_tip_part3_4')}</li>
              </>
            )}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}
