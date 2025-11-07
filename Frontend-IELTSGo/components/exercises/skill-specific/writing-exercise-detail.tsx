"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { FileText, Image as ImageIcon, Target, Clock } from "lucide-react"
import Image from "next/image"
import { useTranslations } from "@/lib/i18n"

interface WritingExerciseDetailProps {
  exercise: {
    writing_task_type?: string
    writing_prompt_text?: string
    writing_visual_type?: string
    writing_visual_url?: string
    writing_word_requirement?: number
    time_limit_minutes?: number
  }
}

export function WritingExerciseDetail({ exercise }: WritingExerciseDetailProps) {
  const t = useTranslations('exercises')
  
  const taskType = exercise.writing_task_type
  const isTask1 = taskType === 'task1'
  const isTask2 = taskType === 'task2'

  return (
    <div className="space-y-6">
      {/* Task Type Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            {isTask1 ? t('writing_task_1') : t('writing_task_2')}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="flex items-center gap-3">
              <Clock className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="text-sm text-muted-foreground">{t('recommended_time')}</p>
                <p className="font-medium">{exercise.time_limit_minutes || 20} {t('minutes')}</p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <Target className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="text-sm text-muted-foreground">{t('minimum_words')}</p>
                <p className="font-medium">{exercise.writing_word_requirement || 250} {t('words')}</p>
              </div>
            </div>
          </div>

          {isTask1 && (
            <div className="pt-4 border-t">
              <div className="flex items-center gap-2 mb-3">
                <Badge variant="outline" className="bg-blue-50 text-blue-700 dark:bg-blue-950">
                  {exercise.writing_visual_type?.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) || 'Data Description'}
                </Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                {t('writing_task1_description')}
              </p>
            </div>
          )}

          {isTask2 && (
            <div className="pt-4 border-t">
              <p className="text-sm text-muted-foreground">
                {t('writing_task2_description')}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Prompt Card */}
      <Card>
        <CardHeader>
          <CardTitle>{t('writing_prompt')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Visual for Task 1 */}
          {isTask1 && exercise.writing_visual_url && (
            <div className="relative w-full h-64 rounded-lg overflow-hidden border bg-muted">
              <Image
                src={exercise.writing_visual_url}
                alt={exercise.writing_visual_type || 'Chart'}
                fill
                className="object-contain"
              />
              <div className="absolute bottom-2 right-2">
                <Badge variant="secondary">
                  <ImageIcon className="w-3 h-3 mr-1" />
                  {exercise.writing_visual_type?.replace('_', ' ')}
                </Badge>
              </div>
            </div>
          )}

          {/* Prompt Text */}
          {exercise.writing_prompt_text && (
            <div className="p-4 rounded-lg bg-orange-50 dark:bg-orange-950 border border-orange-200 dark:border-orange-800">
              <p className="text-sm leading-relaxed whitespace-pre-wrap">
                {exercise.writing_prompt_text}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Evaluation Criteria Card */}
      <Card>
        <CardHeader>
          <CardTitle>{t('evaluation_criteria')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {isTask1 ? (
              <>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-blue-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('task_achievement')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('task_achievement_desc')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-green-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('coherence_cohesion')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('coherence_cohesion_desc_task1')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-purple-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('lexical_resource')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('lexical_resource_desc_task1')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-orange-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('grammatical_range')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('grammatical_range_desc_task1')}
                    </p>
                  </div>
                </div>
              </>
            ) : (
              <>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-blue-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('task_response')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('task_response_desc')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-green-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('coherence_cohesion')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('coherence_cohesion_desc_task2')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-purple-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('lexical_resource')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('lexical_resource_desc_task2')}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 p-3 rounded-lg border">
                  <div className="w-2 h-2 rounded-full bg-orange-500 mt-2" />
                  <div>
                    <h4 className="font-semibold mb-1">{t('grammatical_range')}</h4>
                    <p className="text-sm text-muted-foreground">
                      {t('grammatical_range_desc_task2')}
                    </p>
                  </div>
                </div>
              </>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

