"use client"

import React, { useState, useEffect, useCallback, useRef } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import Image from "next/image"
import { Clock, ChevronLeft, ChevronRight, Flag, Eye, EyeOff, Loader2, CheckCircle2 } from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { exercisesApi } from "@/lib/api/exercises"
import { aiApi } from "@/lib/api/ai"
import type { ExerciseSection, QuestionWithOptions } from "@/types"
import { useTranslations } from '@/lib/i18n'
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"
import { WritingExerciseForm, useWritingExerciseForm } from "@/components/exercises/writing-exercise-form"
import { SpeakingExerciseForm, useSpeakingExerciseForm } from "@/components/exercises/speaking-exercise-form"
import { AIEvaluationLoading } from "@/components/exercises/ai-evaluation-loading"
import { SubmitConfirmationDialog } from "@/components/exercises/submit-confirmation-dialog"
import { ListeningExerciseTake, ReadingExerciseTake, WritingExerciseTake, SpeakingExerciseTake } from "@/components/exercises/take"
import { storageApi } from "@/lib/api/storage"

interface ExerciseData {
  exercise: {
    id: string
    title: string
    time_limit_minutes?: number
    skill_type?: string
    instructions?: string
    description?: string
    writing_task_type?: string
    writing_prompt_text?: string
    writing_visual_type?: string
    writing_visual_url?: string
    writing_word_requirement?: number
    speaking_part_number?: number
    speaking_prompt_text?: string
    speaking_cue_card_topic?: string
    speaking_cue_card_points?: string[]
    speaking_follow_up_questions?: string[]
    speaking_preparation_time_seconds?: number
    speaking_response_time_seconds?: number
  }
  sections: ExerciseSection[]
}

export default function TakeExercisePage() {

  const t = useTranslations('exercises')
  const tAI = useTranslations('ai')
  const toast = useToastWithI18n()

  const params = useParams()
  const router = useRouter()
  const exerciseId = params.exerciseId as string
  const submissionId = params.submissionId as string

  const [exerciseData, setExerciseData] = useState<ExerciseData | null>(null)
  const [loading, setLoading] = useState(true)
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0)
  const [answers, setAnswers] = useState<Map<string, any>>(new Map())
  const [timeSpent, setTimeSpent] = useState(0)
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null) // Countdown timer (seconds)
  const [hasTimeLimit, setHasTimeLimit] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [showSectionContent, setShowSectionContent] = useState(true) // Show passage/audio
  const [showSubmitDialog, setShowSubmitDialog] = useState(false)
  const [pendingSubmit, setPendingSubmit] = useState(false) // Track if submit is pending confirmation
  
  // AI Evaluation states (for writing/speaking exercises)
  const [essayText, setEssayText] = useState("")
  const [wordCount, setWordCount] = useState(0)
  const [audioFile, setAudioFile] = useState<File | null>(null)
  const [audioDuration, setAudioDuration] = useState<number>(0)
  const [showEvaluationLoading, setShowEvaluationLoading] = useState(false)
  const [evaluationProgress, setEvaluationProgress] = useState(0)
  const [evaluationStep, setEvaluationStep] = useState(0)
  const [currentAISubmissionId, setCurrentAISubmissionId] = useState<string | null>(null)
  const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null)
  
  // Helper function to count words
  const countWords = (text: string): number => {
    return text.trim().split(/\s+/).filter(word => word.length > 0).length
  }
  
  useEffect(() => {
    const count = countWords(essayText)
    setWordCount(count)
  }, [essayText])

  // Auto-submit ref to avoid dependency issues
  const autoSubmitRef = useRef(false)
  const answersRef = useRef(answers)
  const submittingRef = useRef(submitting)
  const timerInitializedRef = useRef(false) // Track if timer has been initialized
  const exerciseDataRef = useRef<ExerciseData | null>(null) // Store exerciseData for auto-submit
  const routerRef = useRef(router)
  const toastRef = useRef(toast)
  const tRef = useRef(t)

  // Update refs when state changes
  useEffect(() => {
    answersRef.current = answers
  }, [answers])

  useEffect(() => {
    submittingRef.current = submitting
  }, [submitting])

  useEffect(() => {
    exerciseDataRef.current = exerciseData
  }, [exerciseData])

  useEffect(() => {
    routerRef.current = router
    toastRef.current = toast
    tRef.current = t
  }, [router, toast, t])

  // Timer ref to store interval ID for cleanup
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null)

  // Timer - Count UP for exercises without time limit, Countdown for exercises with time limit
  useEffect(() => {
    // Stop timer if submitting or showing evaluation loading
    if (submitting || showEvaluationLoading) {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current)
        timerIntervalRef.current = null
        timerInitializedRef.current = false
      }
      return
    }

    if (!exerciseData) {
      return
    }

    // Prevent re-initialization if timer already running
    if (timerInitializedRef.current) {
      return
    }

    const timeLimitMinutes = exerciseData.exercise.time_limit_minutes
    
    if (timeLimitMinutes && timeLimitMinutes > 0) {
      // Exercise has time limit - use countdown timer
      setHasTimeLimit(true)
      const totalSeconds = timeLimitMinutes * 60
      setTimeRemaining(totalSeconds)
      timerInitializedRef.current = true
      
      const countdown = setInterval(() => {
        // Check if we should stop the timer
        if (submittingRef.current) {
          clearInterval(countdown)
          timerIntervalRef.current = null
          timerInitializedRef.current = false
          return
        }

        setTimeRemaining((prev) => {
          if (prev === null || prev <= 0) {
            clearInterval(countdown)
            timerIntervalRef.current = null
            timerInitializedRef.current = false
            // Auto-submit when time runs out
            if (!submittingRef.current && !autoSubmitRef.current) {
              autoSubmitRef.current = true
              
              // Auto-submit logic (inline to avoid dependency issues)
              const currentExerciseData = exerciseDataRef.current
              if (!currentExerciseData) return 0
              
              const skillType = currentExerciseData.exercise.skill_type?.toLowerCase()
              const isAIExerciseLocal = skillType === "writing" || skillType === "speaking"
              
              if (!isAIExerciseLocal) {
                // For Listening/Reading exercises, submit answers directly
                setSubmitting(true)
                toastRef.current.info(tRef.current('time_up_auto_submitting') || 'Hết giờ! Đang tự động nộp bài...')
                
                // Format answers correctly - answers are stored as simple strings/IDs
                // Need to check question type to format correctly
                const allQuestionsLocal = exerciseDataRef.current?.sections?.flatMap(s => s.questions || []) || []
                const answersArray = Array.from(answersRef.current.entries())
                  .filter(([questionId, answer]) => {
                    // Filter out empty answers
                    if (!answer || (typeof answer === 'string' && answer.trim() === '')) {
                      return false
                    }
                    return true
                  })
                  .map(([questionId, answer]) => {
                    const question = allQuestionsLocal.find((q: any) => q.question?.id === questionId)
                    const questionType = question?.question?.question_type
                    
                    if (questionType === "multiple_choice") {
                      return {
                        question_id: questionId,
                        selected_option_id: answer, // answer is already the option ID string
                        time_spent_seconds: 0,
                      }
                    } else {
                      return {
                        question_id: questionId,
                        text_answer: answer, // answer is already the text string
                        time_spent_seconds: 0,
                      }
                    }
                  })
                  .filter((answer) => answer !== null && answer !== undefined)

                // Only submit if we have at least one answer
                if (answersArray.length > 0) {
                  exercisesApi.submitAnswers(submissionId, answersArray)
                  .then(() => {
                    routerRef.current.push(`/exercises/${exerciseId}/result/${submissionId}`)
                  })
                  .catch((error) => {
                    console.error("Auto-submit failed:", error)
                    toastRef.current.error(tRef.current('auto_submit_failed') || 'Tự động nộp bài thất bại')
                    setSubmitting(false)
                    autoSubmitRef.current = false
                  })
                } else {
                  // No answers to submit
                  setSubmitting(false)
                  autoSubmitRef.current = false
                }
              } else {
                // For Writing/Speaking, just show warning
                toastRef.current.warning(tRef.current('time_up') || 'Hết giờ! Vui lòng nộp bài thủ công.')
              }
            }
            return 0
          }
          // Continue countdown
          return prev - 1
        })
        // Also update timeSpent for tracking
        setTimeSpent((prev) => prev + 1)
      }, 1000)
      
      timerIntervalRef.current = countdown
      
      return () => {
        if (timerIntervalRef.current) {
          clearInterval(timerIntervalRef.current)
          timerIntervalRef.current = null
        }
        timerInitializedRef.current = false
      }
    } else {
      // Exercise has no time limit - use count up timer
      setHasTimeLimit(false)
      setTimeRemaining(null)
      timerInitializedRef.current = true
      
      const timer = setInterval(() => {
        // Check if we should stop the timer
        if (submittingRef.current) {
          clearInterval(timer)
          timerIntervalRef.current = null
          timerInitializedRef.current = false
          return
        }
        setTimeSpent((prev) => prev + 1)
      }, 1000)
      
      timerIntervalRef.current = timer
      
      return () => {
        if (timerIntervalRef.current) {
          clearInterval(timerIntervalRef.current)
          timerIntervalRef.current = null
        }
        timerInitializedRef.current = false
      }
    }
  }, [exerciseData?.exercise?.time_limit_minutes, submissionId, exerciseId, submitting, showEvaluationLoading])

  // Show warning toast when time is running low (only once)
  const warningShownRef = useRef(false)
  useEffect(() => {
    if (!hasTimeLimit || !timeRemaining || submitting) return
    
    const isVeryLow = timeRemaining > 0 && timeRemaining <= 60 // 1 minute
    const isRunningLow = timeRemaining > 60 && timeRemaining <= 300 // 5 minutes
    
    if (isVeryLow && !warningShownRef.current) {
      toast.warning(t('time_almost_up') || 'Còn ít hơn 1 phút! Hãy nộp bài ngay!')
      warningShownRef.current = true
    } else if (isRunningLow && !warningShownRef.current) {
      const minutesLeft = Math.floor(timeRemaining / 60)
      toast.warning(
        t('time_running_low')?.replace('{minutes}', minutesLeft.toString()) || `Còn ${minutesLeft} phút!`
      )
      warningShownRef.current = true
    }
  }, [timeRemaining, submitting, hasTimeLimit, t, toast])


  // Fetch exercise data
  useEffect(() => {
    const fetchExercise = async () => {
      try {
        const data = await exercisesApi.getExerciseById(exerciseId)
        setExerciseData(data)
      } catch (error) {
        console.error("Failed to fetch exercise:", error)
      } finally {
        setLoading(false)
      }
    }
    fetchExercise()
  }, [exerciseId])

  // Get all questions flattened with section info
  const allQuestions: (QuestionWithOptions & { sectionId: string; sectionData: any })[] =
    exerciseData?.sections.flatMap((sectionData) =>
      (sectionData.questions || []).map((q) => ({
        ...q,
        sectionId: sectionData.section?.id || '',
        sectionData: sectionData.section
      }))
    ) || []
  const currentQuestion = allQuestions[currentQuestionIndex]

  // Get current section
  const currentSection = currentQuestion?.sectionData

  // Polling function to check writing submission status
  const pollWritingSubmissionStatus = useCallback(async (submissionId: string) => {
    let attempts = 0
    const maxAttempts = 60 // Max 5 minutes (60 * 5s)
    let currentStep = 0

    const poll = async () => {
      if (attempts >= maxAttempts) {
        // Timeout - redirect anyway to show result page
        setShowEvaluationLoading(false)
        const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
        router.push(resultUrl)
        if (pollingIntervalRef.current) {
          clearInterval(pollingIntervalRef.current)
          pollingIntervalRef.current = null
        }
        return
      }

      try {
        // Use Exercise Service to get submission result (all submissions are now managed there)
        const response = await exercisesApi.getSubmissionResult(submissionId)
        
        // Update progress based on evaluation_status
        const evaluationStatus = response.submission?.evaluation_status || response.submission?.status || "pending"
        
        if (evaluationStatus === "pending") {
          currentStep = 0
          setEvaluationStep(0)
        } else if (evaluationStatus === "processing" || evaluationStatus === "evaluating") {
          currentStep = Math.min(2, attempts / 10) // Step 1-2 after 10-20 attempts
          setEvaluationStep(Math.floor(currentStep))
        } else if (evaluationStatus === "completed" || response.submission?.status === "completed") {
          // Evaluation complete - navigate to result page
          setShowEvaluationLoading(false)
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
          router.push(resultUrl)
          return
        } else if (evaluationStatus === "failed") {
          // Evaluation failed - still redirect to show error
          setShowEvaluationLoading(false)
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
          router.push(resultUrl)
          return
        }

        attempts++
        setEvaluationProgress(Math.min(95, (attempts / maxAttempts) * 100))
      } catch (error: any) {
        // If 404, the submission might not be ready yet - continue polling
        if (error.response?.status === 404) {
          attempts++
          setEvaluationProgress(Math.min(95, (attempts / maxAttempts) * 100))
          return
        }
        console.error("[Polling] Failed to check status:", error)
        attempts++
        // Continue polling on error (might be temporary)
      }
    }

    // Poll every 5 seconds
    pollingIntervalRef.current = setInterval(poll, 5000)
    
    // Initial poll
    poll()
  }, [exerciseId, submissionId, router])

  // Polling function to check speaking submission status
  const pollSpeakingSubmissionStatus = useCallback(async (submissionId: string) => {
    let attempts = 0
    const maxAttempts = 72 // Max 6 minutes (72 * 5s) - speaking takes longer (transcription + evaluation)
    let currentStep = 0

    const poll = async () => {
      if (attempts >= maxAttempts) {
        // Timeout - redirect anyway to show result page
        setShowEvaluationLoading(false)
        const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
        router.push(resultUrl)
        if (pollingIntervalRef.current) {
          clearInterval(pollingIntervalRef.current)
          pollingIntervalRef.current = null
        }
        return
      }

      try {
        // Use Exercise Service to get submission result (all submissions are now managed there)
        const response = await exercisesApi.getSubmissionResult(submissionId)
        
        // Update progress based on evaluation_status
        const evaluationStatus = response.submission?.evaluation_status || response.submission?.status || "pending"
        
        if (evaluationStatus === "pending") {
          currentStep = 0
          setEvaluationStep(0)
        } else if (evaluationStatus === "transcribing") {
          currentStep = 1
          setEvaluationStep(1)
        } else if (evaluationStatus === "evaluating" || evaluationStatus === "processing") {
          currentStep = 2
          setEvaluationStep(2)
        } else if (evaluationStatus === "completed" || response.submission?.status === "completed") {
          // Evaluation complete - navigate to result page
          setShowEvaluationLoading(false)
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
          router.push(resultUrl)
          return
        } else if (evaluationStatus === "failed") {
          // Evaluation failed - still redirect to show error
          setShowEvaluationLoading(false)
          if (pollingIntervalRef.current) {
            clearInterval(pollingIntervalRef.current)
            pollingIntervalRef.current = null
          }
          const resultUrl = `/exercises/${exerciseId}/result/${submissionId}`
          router.push(resultUrl)
          return
        }

        attempts++
        setEvaluationProgress(Math.min(95, (attempts / maxAttempts) * 100))
      } catch (error: any) {
        // If 404, the submission might not be ready yet - continue polling
        if (error.response?.status === 404) {
          attempts++
          setEvaluationProgress(Math.min(95, (attempts / maxAttempts) * 100))
          return
        }
        console.error("[Polling] Failed to check status:", error)
        attempts++
        // Continue polling on error (might be temporary)
      }
    }

    // Poll every 5 seconds
    pollingIntervalRef.current = setInterval(poll, 5000)
    
    // Initial poll
    poll()
  }, [exerciseId, submissionId, router])

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current)
        pollingIntervalRef.current = null
      }
    }
  }, [])

  const handleAnswerChange = (questionId: string, answer: any) => {
    setAnswers(new Map(answers.set(questionId, answer)))
  }

  const handleNext = () => {
    if (currentQuestionIndex < allQuestions.length - 1) {
      const nextQuestion = allQuestions[currentQuestionIndex + 1]
      const currentSectionId = currentQuestion?.sectionId
      const nextSectionId = nextQuestion?.sectionId

      // Show section content if moving to a new section
      if (currentSectionId !== nextSectionId) {
        setShowSectionContent(true)
      }

      setCurrentQuestionIndex((prev) => prev + 1)
    }
  }

  const handlePrevious = () => {
    if (currentQuestionIndex > 0) {
      const prevQuestion = allQuestions[currentQuestionIndex - 1]
      const currentSectionId = currentQuestion?.sectionId
      const prevSectionId = prevQuestion?.sectionId

      // Show section content if moving to a new section
      if (currentSectionId !== prevSectionId) {
        setShowSectionContent(true)
      }

      setCurrentQuestionIndex((prev) => prev - 1)
    }
  }

  const handleSubmit = async (autoSubmit = false) => {
    // Skip confirmation for auto-submit (when time runs out)
    if (!autoSubmit) {
      setPendingSubmit(true)
      setShowSubmitDialog(true)
      return
    }

    // Proceed with submission (for auto-submit or after confirmation)
    await performSubmit()
  }

  const performSubmit = async () => {
    try {
      setSubmitting(true)
      setShowSubmitDialog(false)
      setPendingSubmit(false)

      // For Writing/Speaking exercises, submit to Exercise Service (which handles AI evaluation)
      if (isAIExercise && exerciseData) {
        // Get prompt text from exercise data
        let promptText = ""
        if (isSpeakingExercise) {
          promptText = exerciseData.exercise.speaking_prompt_text || ""
        } else if (isWritingExercise) {
          promptText = exerciseData.exercise.writing_prompt_text || ""
        }
        
        // Fallback to section instructions or exercise description if prompt not available
        if (!promptText) {
          promptText = 
            exerciseData.sections[0]?.section?.instructions || 
            exerciseData.exercise.instructions || 
            exerciseData.exercise.description || 
            ""
        }
        
        if (isWritingExercise) {
          // Use writing_task_type from exercise data, fallback to task2
          const taskType: "task1" | "task2" = (exerciseData.exercise.writing_task_type as "task1" | "task2") || "task2"

          // Validate essay before submitting
          if (!essayText.trim()) {
            toast.error(tAI('essay_required') || "Please enter your essay")
            setSubmitting(false)
            return
          }

          const minWords = taskType === "task1" ? 150 : 250
          if (wordCount < minWords) {
            const errorMsg = tAI('essay_word_count_below_min')
              ?.replace('{wordCount}', wordCount.toString())
              ?.replace('{taskType}', taskType === "task1" ? "Task 1" : "Task 2")
              ?.replace('{minWords}', minWords.toString()) 
              || `Word count must be at least ${minWords} words`
            toast.error(errorMsg)
            setSubmitting(false)
            return
          }

          try {
            // Validate prompt text is not empty
            if (!promptText.trim()) {
              toast.error(tAI("task_prompt_required") || "Task prompt is required")
              setSubmitting(false)
              return
            }

            // Prepare request payload - omit task_prompt_id if null
            const payload: any = {
              task_type: taskType,
              task_prompt_text: promptText.trim(),
              essay_text: essayText.trim(),
            }
            // Only include task_prompt_id if we have a valid ID (not null/undefined)
            // When omitted, backend will create prompt from task_prompt_text

            // Submit to Exercise Service (which handles AI evaluation internally)
            await exercisesApi.submitExercise(submissionId, {
              writing_data: {
                essay_text: essayText.trim(),
                word_count: wordCount,
                task_type: taskType,
                prompt_text: promptText.trim(),
              },
              time_spent_seconds: timeSpent,
            })

            // Show loading screen and start polling
            setShowEvaluationLoading(true)
            setEvaluationStep(0) // Start at step 0
            pollWritingSubmissionStatus(submissionId)
            return // Exit early, polling will handle navigation
          } catch (error: any) {
            console.error("[Writing Submission] Failed:", error)
            const errorMessage = error.response?.data?.error || error.message || tAI("failed_to_submit") || "Failed to submit essay"
            toast.error(errorMessage)
            setSubmitting(false)
          }
        } else if (isSpeakingExercise) {
          if (!audioFile) {
            toast.error(tAI('audio_required') || "Please record or upload audio")
            setSubmitting(false)
            return
          }

          // Use speaking_part_number from exercise data (from database)
          // Fallback to 1 if not available
          const partNumber: 1 | 2 | 3 = (exerciseData?.exercise?.speaking_part_number as 1 | 2 | 3) || 1

          try {
            // Validate prompt text is not empty
            if (!promptText.trim()) {
              toast.error(tAI("task_prompt_required") || "Task prompt is required")
              setSubmitting(false)
              return
            }

            // Step 1: Upload audio file to storage service to get audio_url
            toast.info(tAI("uploading_audio") || "Uploading audio file...")
            const audioUrl = await storageApi.uploadAudio(audioFile)
            toast.success(tAI("audio_uploaded") || "Audio uploaded successfully")

            // Step 2: Submit to Exercise Service (which handles AI evaluation internally)
            await exercisesApi.submitExercise(submissionId, {
              speaking_data: {
                audio_url: audioUrl,
                audio_duration_seconds: audioDuration,
                speaking_part_number: partNumber,
              },
              time_spent_seconds: timeSpent,
            })

            // Show loading screen and start polling
            setShowEvaluationLoading(true)
            setEvaluationStep(0) // Start at step 0
            pollSpeakingSubmissionStatus(submissionId)
            return // Exit early, polling will handle navigation
          } catch (error: any) {
            console.error("[Speaking Submission] Failed:", error)
            const errorMessage = error.response?.data?.error || error.message || tAI("failed_to_submit") || "Failed to submit audio"
            toast.error(errorMessage)
            setSubmitting(false)
          }
        }
        
        // If we get here, something went wrong - don't continue
        return
      }

      // Original logic for Listening/Reading exercises with questions
      const formattedAnswers = Array.from(answers.entries())
        .filter(([questionId, answer]) => {
          // Filter out empty answers
          if (!answer || (typeof answer === 'string' && answer.trim() === '')) {
            return false
          }
          return true
        })
        .map(([questionId, answer]) => {
          const question = allQuestions.find((q) => q.question.id === questionId)

          if (!question) {
            console.warn(`Question ${questionId} not found in allQuestions`)
          }

          if (question?.question.question_type === "multiple_choice") {
            return {
              question_id: questionId,
              selected_option_id: answer,
              time_spent_seconds: 0, // Will be calculated by backend from started_at to completed_at
            }
          } else {
            return {
              question_id: questionId,
              text_answer: answer,
              time_spent_seconds: 0, // Will be calculated by backend from started_at to completed_at
            }
          }
        })
        .filter((answer) => answer !== null && answer !== undefined)

      // Log submission (even if empty, backend will handle it)
      console.log(`[Submit] Submitting ${formattedAnswers.length} answers for submission ${submissionId}`)

      // Submit answers
      await exercisesApi.submitAnswers(submissionId, formattedAnswers)

      // Navigate to result page
      router.push(`/exercises/${exerciseId}/result/${submissionId}`)
    } catch (error) {
      console.error("Failed to submit answers:", error)
      toast.error(t('failed_to_submit_answers_please_try_agai'))
    } finally {
      setSubmitting(false)
    }
  }

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
    }
    return `${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
  }

  // Format time for display - show countdown if has time limit, otherwise show time spent
  const getDisplayTime = () => {
    if (hasTimeLimit && timeRemaining !== null) {
      return formatTime(timeRemaining)
    }
    return formatTime(timeSpent)
  }

  // Check if time is running low (less than 5 minutes remaining)
  const isTimeRunningLow = () => {
    return hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 300 // 5 minutes
  }

  // Check if time is very low (less than 1 minute remaining)
  const isTimeVeryLow = () => {
    return hasTimeLimit && timeRemaining !== null && timeRemaining > 0 && timeRemaining <= 60 // 1 minute
  }

  // Check if this is a Writing or Speaking exercise (AI evaluation)
  const skillType = exerciseData?.exercise.skill_type?.toLowerCase()
  const isWritingExercise = skillType === "writing"
  const isSpeakingExercise = skillType === "speaking"
  const isAIExercise = isWritingExercise || isSpeakingExercise

  if (loading || !exerciseData) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <PageLoading translationKey="loading" />
        </div>
      </AppLayout>
    )
  }

  // Helper to get dialog type
  const getDialogType = () => {
    if (isWritingExercise) return "writing"
    if (isSpeakingExercise) return "speaking"
    return "exercise"
  }

  // For Writing/Speaking exercises, render optimized components
  if (isAIExercise) {
    // Get prompt text for Speaking/Writing from exercise data
    let promptText = ""
    if (isSpeakingExercise) {
      promptText = exerciseData.exercise.speaking_prompt_text || ""
    } else if (isWritingExercise) {
      promptText = exerciseData.exercise.writing_prompt_text || ""
    }
    
    // Fallback to section instructions or exercise description if prompt not available
    if (!promptText) {
      promptText = 
        exerciseData.sections[0]?.section?.instructions || 
        exerciseData.exercise.instructions || 
        exerciseData.exercise.description || 
        ""
    }

    // Determine task type/part number from exercise data (from database)
    let taskType: "task1" | "task2" = "task2"
    let partNumber: 1 | 2 | 3 = 1
    
    if (isWritingExercise) {
      // Use writing_task_type from exercise data, fallback to task2
      taskType = (exerciseData.exercise.writing_task_type as "task1" | "task2") || "task2"
    } else if (isSpeakingExercise) {
      // Use speaking_part_number from exercise data (required field), fallback to 1
      partNumber = (exerciseData.exercise.speaking_part_number as 1 | 2 | 3) || 1
    }

    // Get cue card points and follow-up questions for Speaking
    // Try from exercise first, then from section
    const cueCardPoints = exerciseData.exercise.speaking_cue_card_points || []
    const followUpQuestions = exerciseData.exercise.speaking_follow_up_questions || []

    return (
      <>
        {/* Submit Confirmation Dialog */}
        <SubmitConfirmationDialog
          open={showSubmitDialog}
          onOpenChange={(open) => {
            setShowSubmitDialog(open)
            if (!open) {
              setPendingSubmit(false)
            }
          }}
          onConfirm={performSubmit}
          type={getDialogType()}
        />
        {/* AI Evaluation Loading Screen */}
        {showEvaluationLoading && (
          <AIEvaluationLoading
            type={isWritingExercise ? "writing" : "speaking"}
            submissionId={submissionId}
            progress={evaluationProgress}
            currentStep={evaluationStep}
            totalSteps={4}
          />
        )}
        <AppLayout>
          <PageContainer maxWidth="7xl" className="py-4">
            {/* Writing Exercise */}
            {isWritingExercise && (
              <WritingExerciseTake
                exercise={{
                  ...exerciseData.exercise,
                  writing_task_type: exerciseData.exercise.writing_task_type || taskType,
                  writing_prompt_text: exerciseData.exercise.writing_prompt_text || promptText,
                  writing_visual_type: exerciseData.exercise.writing_visual_type,
                  writing_visual_url: exerciseData.exercise.writing_visual_url,
                  writing_word_requirement: exerciseData.exercise.writing_word_requirement,
                }}
                taskType={taskType}
                prompt={exerciseData.exercise.writing_prompt_text || promptText}
                timeRemaining={timeRemaining}
                hasTimeLimit={hasTimeLimit}
                timeSpent={timeSpent}
                value={essayText}
                onChange={(text) => setEssayText(text)}
                onSubmit={() => handleSubmit(false)}
                submitting={submitting}
              />
            )}

            {/* Speaking Exercise */}
            {isSpeakingExercise && (
              <SpeakingExerciseTake
                exercise={exerciseData.exercise}
                partNumber={partNumber}
                prompt={promptText}
                cueCardPoints={cueCardPoints}
                followUpQuestions={followUpQuestions}
                timeRemaining={timeRemaining}
                hasTimeLimit={hasTimeLimit}
                timeSpent={timeSpent}
                audioFile={audioFile}
                audioDuration={audioDuration}
                onFileChange={(file, duration) => {
                  setAudioFile(file)
                  setAudioDuration(duration)
                }}
                onSubmit={() => handleSubmit(false)}
                submitting={submitting}
              />
            )}
          </PageContainer>
        </AppLayout>
      </>
    )
  }

  // Original logic for Listening/Reading exercises with questions
  if (!currentQuestion) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <PageLoading translationKey="loading" />
        </div>
      </AppLayout>
    )
  }

  // Original logic for Listening/Reading exercises with questions
  if (!currentQuestion) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <PageLoading translationKey="loading" />
        </div>
      </AppLayout>
    )
  }

  const progress = ((currentQuestionIndex + 1) / allQuestions.length) * 100
  const answeredCount = answers.size

  // Determine skill type and render appropriate component
  const isListening = skillType === 'listening'
  const isReading = skillType === 'reading'

  // Render skill-specific components for Listening
  if (isListening) {
    return (
      <>
        {/* Submit Confirmation Dialog */}
        <SubmitConfirmationDialog
          open={showSubmitDialog}
          onOpenChange={(open) => {
            setShowSubmitDialog(open)
            if (!open) {
              setPendingSubmit(false)
            }
          }}
          onConfirm={performSubmit}
          type="exercise"
        />
        <AppLayout>
          <PageContainer maxWidth="7xl" className="py-4">
            <ListeningExerciseTake
            exercise={exerciseData.exercise}
            sections={exerciseData.sections}
            currentQuestionIndex={currentQuestionIndex}
            answers={answers}
            timeRemaining={timeRemaining}
            hasTimeLimit={hasTimeLimit}
            answeredCount={answeredCount}
            totalQuestions={allQuestions.length}
            progress={progress}
            onAnswerChange={handleAnswerChange}
            onNext={handleNext}
            onPrevious={handlePrevious}
            onSubmit={() => handleSubmit(false)}
            submitting={submitting}
          />
          
          {/* Question Navigator */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle className="text-sm">{t('question_navigator')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-10 gap-2">
                {allQuestions.map((q, index) => (
                  <button
                    key={q.question.id}
                    onClick={() => setCurrentQuestionIndex(index)}
                    className={`
                      p-2 rounded text-sm font-medium transition-all
                      ${index === currentQuestionIndex ? "bg-primary text-primary-foreground" : ""}
                      ${
                        answers.has(q.question.id)
                          ? "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200"
                          : "bg-muted hover:bg-muted/80"
                      }
                    `}
                  >
                    {index + 1}
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>
        </PageContainer>
      </AppLayout>
      </>
    )
  }

  if (isReading) {
    return (
      <>
        {/* Submit Confirmation Dialog */}
        <SubmitConfirmationDialog
          open={showSubmitDialog}
          onOpenChange={(open) => {
            setShowSubmitDialog(open)
            if (!open) {
              setPendingSubmit(false)
            }
          }}
          onConfirm={performSubmit}
          type="exercise"
        />
        <AppLayout>
          <PageContainer maxWidth="7xl" className="py-4">
            <ReadingExerciseTake
            exercise={exerciseData.exercise}
            sections={exerciseData.sections}
            currentQuestionIndex={currentQuestionIndex}
            answers={answers}
            timeRemaining={timeRemaining}
            hasTimeLimit={hasTimeLimit}
            answeredCount={answeredCount}
            totalQuestions={allQuestions.length}
            progress={progress}
            onAnswerChange={handleAnswerChange}
            onNext={handleNext}
            onPrevious={handlePrevious}
            onSubmit={() => handleSubmit(false)}
            submitting={submitting}
          />
          
          {/* Question Navigator */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle className="text-sm">{t('question_navigator')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-10 gap-2">
                {allQuestions.map((q, index) => (
                  <button
                    key={q.question.id}
                    onClick={() => setCurrentQuestionIndex(index)}
                    className={`
                      p-2 rounded text-sm font-medium transition-all
                      ${index === currentQuestionIndex ? "bg-primary text-primary-foreground" : ""}
                      ${
                        answers.has(q.question.id)
                          ? "bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200"
                          : "bg-muted hover:bg-muted/80"
                      }
                    `}
                  >
                    {index + 1}
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>
        </PageContainer>
      </AppLayout>
      </>
    )
  }

  // Fallback to original layout for other skill types (should not happen for Listening/Reading)
  return (
    <>
      {/* Submit Confirmation Dialog */}
      <SubmitConfirmationDialog
        open={showSubmitDialog}
        onOpenChange={(open) => {
          setShowSubmitDialog(open)
          if (!open) {
            setPendingSubmit(false)
          }
        }}
        onConfirm={performSubmit}
        type="exercise"
      />
      <AppLayout>
        <PageContainer maxWidth="7xl" className="py-4">
          <Card>
            <CardContent className="py-4">
              <p>Unsupported exercise type</p>
            </CardContent>
          </Card>
        </PageContainer>
      </AppLayout>
    </>
  )
}

