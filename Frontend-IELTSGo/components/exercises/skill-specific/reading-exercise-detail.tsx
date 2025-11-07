"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { BookOpen, FileText, Clock, GraduationCap, Briefcase } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

interface ReadingExerciseDetailProps {
  exercise: {
    ielts_test_type?: string
    passage_count?: number
    total_sections?: number
    time_limit_minutes?: number
  }
  sections?: Array<{
    section?: {
      id: string
      title?: string
      description?: string
      passage_title?: string
      passage_content?: string
      passage_word_count?: number
      total_questions?: number
    }
  }>
}

export function ReadingExerciseDetail({ exercise, sections = [] }: ReadingExerciseDetailProps) {
  const t = useTranslations('exercises')
  const tCommon = useTranslations('common')
  
  const isAcademic = exercise.ielts_test_type === 'academic'
  const totalQuestions = sections.reduce((sum, s) => sum + (s.section?.total_questions || 0), 0)
  const totalWords = sections.reduce((sum, s) => sum + (s.section?.passage_word_count || 0), 0)

  return (
    <div className="space-y-6">
      {/* Test Type Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BookOpen className="w-5 h-5" />
            {isAcademic ? t('reading_academic') : t('reading_general_training')}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-start gap-3 p-3 rounded-lg bg-indigo-50 dark:bg-indigo-950 border border-indigo-200 dark:border-indigo-800">
            {isAcademic ? (
              <GraduationCap className="w-5 h-5 text-indigo-600 dark:text-indigo-400 flex-shrink-0 mt-0.5" />
            ) : (
              <Briefcase className="w-5 h-5 text-indigo-600 dark:text-indigo-400 flex-shrink-0 mt-0.5" />
            )}
            <div>
              <p className="font-semibold text-indigo-900 dark:text-indigo-100 mb-1">
                {isAcademic ? tCommon('academic') : tCommon('general_training')}
              </p>
              <p className="text-sm text-indigo-700 dark:text-indigo-300">
                {isAcademic ? t('academic_purpose_desc') : t('general_training_purpose_desc')}
              </p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4 pt-2">
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground">{t('time_limit')}</p>
                <p className="text-sm font-medium">{exercise.time_limit_minutes || 60} {t('minutes')}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <FileText className="w-4 h-4 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground">{t('number_of_questions')}</p>
                <p className="text-sm font-medium">{totalQuestions || 40} {t('questions')}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-muted-foreground" />
              <div>
                <p className="text-xs text-muted-foreground">{t('number_of_passages')}</p>
                <p className="text-sm font-medium">{exercise.passage_count || sections.length} {t('passages')}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Passages Structure */}
      {sections && sections.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>{t('reading_structure')}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {sections.map((sectionData, index) => {
                const section = sectionData.section
                return (
                  <div 
                    key={section?.id || index}
                    className="flex items-center justify-between p-4 rounded-lg border hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-green-500 text-white flex items-center justify-center font-semibold">
                        {index + 1}
                      </div>
                      <div>
                        <h4 className="font-medium">
                          {section?.passage_title || section?.title || `${t('passage')} ${index + 1}`}
                        </h4>
                        {section?.description && (
                          <p className="text-sm text-muted-foreground mt-1">{section.description}</p>
                        )}
                        {section?.passage_word_count && (
                          <p className="text-xs text-muted-foreground mt-1">
                            ~{section.passage_word_count} {t('words')}
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <FileText className="w-4 h-4" />
                        <span>{section?.total_questions || 0} {t('questions')}</span>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Question Types Info */}
      <Card className="border-l-4 border-l-green-500 bg-green-50/30 dark:bg-green-950/20">
        <CardHeader>
          <CardTitle className="text-base">📝 {t('reading_question_types')}</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_mc')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_tfng')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_ynng')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_headings')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_sentence')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_summary')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_question_type_info')}</li>
          </ul>
        </CardContent>
      </Card>

      {/* Reading Strategies */}
      <Card className="border-l-4 border-l-green-500 bg-green-50/30 dark:bg-green-950/20">
        <CardHeader>
          <CardTitle className="text-base">💡 {t('reading_strategies')}</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li className="flex gap-2"><span className="text-primary">•</span> <strong>Skimming:</strong> {t('reading_strategy_skimming')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> <strong>Scanning:</strong> {t('reading_strategy_scanning')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> <strong>Time management:</strong> {t('reading_strategy_time')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_strategy_questions_first')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_strategy_paraphrase')}</li>
            <li className="flex gap-2"><span className="text-primary">•</span> {t('reading_strategy_context')}</li>
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}
