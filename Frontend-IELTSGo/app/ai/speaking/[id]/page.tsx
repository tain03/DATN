"use client"

import { useState, useRef, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { ProtectedRoute } from "@/components/auth/protected-route"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { 
  Mic, 
  Clock, 
  ChevronLeft, 
  Loader2, 
  AlertCircle,
  CheckCircle2,
  Play,
  Pause,
  Upload,
  Trash2,
  Info
} from "lucide-react"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { aiApi } from "@/lib/api/ai"
import { useToastWithI18n } from "@/lib/hooks/use-toast-with-i18n"
import type { SpeakingPrompt, SpeakingSubmissionResponse } from "@/types/ai"
import { useTranslations } from "@/lib/i18n"

// Validation constants (matching backend)
const MAX_AUDIO_FILE_SIZE_MB = 50
const MAX_AUDIO_FILE_SIZE_BYTES = 50 * 1024 * 1024
const MAX_AUDIO_DURATION_SECONDS = 300 // 5 minutes
const ALLOWED_AUDIO_FORMATS = ["audio/mpeg", "audio/mp3", "audio/wav", "audio/wave", "audio/x-wav", "audio/mp4", "audio/x-m4a", "audio/ogg"]
const ALLOWED_EXTENSIONS = [".mp3", ".wav", ".m4a", ".ogg"]

export default function SpeakingPromptPage() {
  return (
    <ProtectedRoute>
      <SpeakingPromptContent />
    </ProtectedRoute>
  )
}

function SpeakingPromptContent() {
  const params = useParams()
  const router = useRouter()
  const t = useTranslations("ai")
  const tCommon = useTranslations("common")
  const toast = useToastWithI18n()

  const promptId = params.id as string

  const [prompt, setPrompt] = useState<SpeakingPrompt | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [recording, setRecording] = useState(false)
  const [audioFile, setAudioFile] = useState<File | null>(null)
  const [audioURL, setAudioURL] = useState<string | null>(null)
  const [audioDuration, setAudioDuration] = useState<number>(0)
  const [errors, setErrors] = useState<{
    audio?: string
  }>({})

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const audioPlayerRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => {
    const fetchPrompt = async () => {
      try {
        setLoading(true)
        const data = await aiApi.getSpeakingPrompt(promptId)
        setPrompt(data)
      } catch (error: any) {
        console.error("[Speaking Prompt] Failed to load:", error)
        toast.error(error.response?.data?.error || "Failed to load prompt")
      } finally {
        setLoading(false)
      }
    }

    if (promptId) {
      fetchPrompt()
    }
  }, [promptId, toast])

  const validateAudioFile = (file: File): boolean => {
    const newErrors: typeof errors = {}

    // Check file size
    if (file.size > MAX_AUDIO_FILE_SIZE_BYTES) {
      newErrors.audio = t("audio_file_too_large") || 
        `Audio file size (${(file.size / (1024 * 1024)).toFixed(2)} MB) exceeds maximum (${MAX_AUDIO_FILE_SIZE_MB} MB)`
      setErrors(newErrors)
      return false
    }

    // Check file extension
    const ext = "." + file.name.split(".").pop()?.toLowerCase()
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      newErrors.audio = t("audio_format_not_supported") || 
        `File format not supported. Allowed: ${ALLOWED_EXTENSIONS.join(", ")}`
      setErrors(newErrors)
      return false
    }

    setErrors({})
    return true
  }

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    if (!validateAudioFile(file)) return

    setAudioFile(file)
    
    // Create preview URL
    if (audioURL) {
      URL.revokeObjectURL(audioURL)
    }
    const url = URL.createObjectURL(file)
    setAudioURL(url)

    // Get audio duration
    const audio = new Audio(url)
    audio.addEventListener("loadedmetadata", () => {
      setAudioDuration(Math.floor(audio.duration))
      if (audio.duration > MAX_AUDIO_DURATION_SECONDS) {
        setErrors({
          audio: t("audio_duration_too_long") || 
            `Audio duration (${Math.floor(audio.duration)}s) exceeds maximum (${MAX_AUDIO_DURATION_SECONDS}s)`
        })
      }
    })
  }

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const mediaRecorder = new MediaRecorder(stream)
      mediaRecorderRef.current = mediaRecorder
      audioChunksRef.current = []

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data)
        }
      }

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: "audio/webm" })
        const audioUrl = URL.createObjectURL(audioBlob)
        setAudioURL(audioUrl)
        setAudioDuration(0) // Duration will be calculated when audio loads
        
        // Create File object from Blob
        const file = new File([audioBlob], "recording.webm", { type: "audio/webm" })
        setAudioFile(file)

        // Get duration
        const audio = new Audio(audioUrl)
        audio.addEventListener("loadedmetadata", () => {
          setAudioDuration(Math.floor(audio.duration))
        })

        // Stop all tracks
        stream.getTracks().forEach(track => track.stop())
      }

      mediaRecorder.start()
      setRecording(true)
    } catch (error) {
      console.error("Failed to start recording:", error)
      toast.error(t("failed_to_start_recording") || "Failed to start recording. Please check microphone permissions.")
    }
  }

  const stopRecording = () => {
    if (mediaRecorderRef.current && recording) {
      mediaRecorderRef.current.stop()
      setRecording(false)
    }
  }

  const removeAudio = () => {
    if (audioURL) {
      URL.revokeObjectURL(audioURL)
    }
    setAudioFile(null)
    setAudioURL(null)
    setAudioDuration(0)
    setErrors({})
  }

  const handleSubmit = async () => {
    if (!audioFile || !prompt) {
      toast.error(t("audio_required") || "Please record or upload an audio file")
      return
    }

    if (audioDuration > MAX_AUDIO_DURATION_SECONDS) {
      toast.error(t("audio_duration_too_long") || "Audio duration exceeds maximum")
      return
    }

    try {
      setSubmitting(true)
      
      const formData = new FormData()
      formData.append("audio", audioFile)
      formData.append("part_number", String(prompt.part_number))
      formData.append("task_prompt_text", prompt.prompt_text)
      if (prompt.id) {
        formData.append("task_prompt_id", prompt.id)
      }
      formData.append("audio_duration_seconds", String(audioDuration))
      formData.append("audio_file_size_bytes", String(audioFile.size))

      const response: SpeakingSubmissionResponse = await aiApi.submitSpeaking(formData)

      toast.success(t("submission_successful") || "Submission successful!")
      
      // Navigate to result page
      router.push(`/ai/speaking/submissions/${response.submission.id}`)
    } catch (error: any) {
      console.error("[Speaking Submit] Failed:", error)
      const errorMsg = error.response?.data?.error || 
        error.message || 
        t("submission_failed") || 
        "Failed to submit speaking"
      toast.error(errorMsg)
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <AppLayout>
        <PageContainer>
          <PageLoading translationKey="loading" />
        </PageContainer>
      </AppLayout>
    )
  }

  if (!prompt) {
    return (
      <AppLayout>
        <PageContainer>
          <EmptyState
            icon={Mic}
            title={t("prompt_not_found") || "Prompt not found"}
            description={t("prompt_not_found_description") || "This prompt may have been removed"}
            actionLabel={tCommon("go_back") || "Go Back"}
            actionOnClick={() => router.back()}
          />
        </PageContainer>
      </AppLayout>
    )
  }

  return (
    <AppLayout>
      <PageContainer maxWidth="4xl">
        <Button
          variant="ghost"
          onClick={() => router.back()}
          className="mb-4"
        >
          <ChevronLeft className="h-4 w-4 mr-2" />
          {tCommon("go_back") || "Back"}
        </Button>

        <div className="mb-8">
          <div className="flex items-center gap-2 mb-3">
            <Badge variant="outline">
              Part {prompt.part_number}
            </Badge>
            {prompt.difficulty && (
              <Badge>{prompt.difficulty}</Badge>
            )}
            {prompt.topic_category && (
              <Badge variant="secondary">{prompt.topic_category}</Badge>
            )}
          </div>
          <h1 className="text-3xl font-bold tracking-tight mb-2">
            {prompt.cue_card_topic || prompt.topic_category || "Speaking Practice"}
          </h1>
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Prompt */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Mic className="w-5 h-5" />
                  {t("task_prompt") || "Task Prompt"}
                </CardTitle>
                {prompt.preparation_time_seconds && (
                  <CardDescription>
                    {t("preparation_time") || "Preparation time"}: {prompt.preparation_time_seconds}s
                  </CardDescription>
                )}
                {prompt.speaking_time_seconds && (
                  <CardDescription>
                    {t("speaking_time") || "Speaking time"}: {prompt.speaking_time_seconds}s
                  </CardDescription>
                )}
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="prose prose-sm max-w-none">
                  <p className="whitespace-pre-wrap">{prompt.prompt_text}</p>
                </div>
                
                {prompt.cue_card_points && prompt.cue_card_points.length > 0 && (
                  <div className="border rounded-lg p-4 bg-muted/50">
                    <h4 className="font-semibold mb-2">{t("cue_card_points") || "Cue Card Points"}:</h4>
                    <ul className="list-disc list-inside space-y-1">
                      {prompt.cue_card_points.map((point, idx) => (
                        <li key={idx} className="text-sm">{point}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {prompt.follow_up_questions && prompt.follow_up_questions.length > 0 && (
                  <div className="border rounded-lg p-4">
                    <h4 className="font-semibold mb-2">{t("follow_up_questions") || "Follow-up Questions"}:</h4>
                    <ul className="list-disc list-inside space-y-1">
                      {prompt.follow_up_questions.map((question, idx) => (
                        <li key={idx} className="text-sm">{question}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Audio Recording/Upload */}
            <Card>
              <CardHeader>
                <CardTitle>{t("record_or_upload_audio") || "Record or Upload Audio"}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {errors.audio && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>{errors.audio}</AlertDescription>
                  </Alert>
                )}

                {audioURL ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <CheckCircle2 className="w-5 h-5 text-green-500" />
                        <span className="text-sm font-medium">
                          {t("audio_ready") || "Audio ready"}
                        </span>
                        {audioDuration > 0 && (
                          <span className="text-sm text-muted-foreground">
                            ({Math.floor(audioDuration / 60)}:{(audioDuration % 60).toString().padStart(2, "0")})
                          </span>
                        )}
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={removeAudio}
                      >
                        <Trash2 className="w-4 h-4 mr-2" />
                        {t("remove") || "Remove"}
                      </Button>
                    </div>
                    <audio
                      ref={audioPlayerRef}
                      src={audioURL}
                      controls
                      className="w-full"
                    />
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex gap-3">
                      <Button
                        onClick={recording ? stopRecording : startRecording}
                        variant={recording ? "destructive" : "default"}
                        className="flex-1"
                      >
                        {recording ? (
                          <>
                            <Pause className="w-4 h-4 mr-2" />
                            {t("stop_recording") || "Stop Recording"}
                          </>
                        ) : (
                          <>
                            <Mic className="w-4 h-4 mr-2" />
                            {t("start_recording") || "Start Recording"}
                          </>
                        )}
                      </Button>
                      <Button
                        variant="outline"
                        asChild
                        className="flex-1"
                      >
                        <label>
                          <Upload className="w-4 h-4 mr-2" />
                          {t("upload_file") || "Upload File"}
                          <input
                            type="file"
                            accept="audio/*"
                            onChange={handleFileSelect}
                            className="hidden"
                          />
                        </label>
                      </Button>
                    </div>
                  </div>
                )}

                {/* Tips */}
                <Alert>
                  <Info className="h-4 w-4" />
                  <AlertDescription>
                    <ul className="list-disc list-inside space-y-1 text-sm">
                      <li>{t("tip_speak_clearly") || "Speak clearly and at a moderate pace"}</li>
                      <li>{t("tip_answer_all_points") || "Answer all points in the cue card"}</li>
                      <li>{t("tip_max_duration") || `Maximum duration: ${MAX_AUDIO_DURATION_SECONDS / 60} minutes`}</li>
                    </ul>
                  </AlertDescription>
                </Alert>
              </CardContent>
            </Card>

            {/* Submit Button */}
            <Button
              onClick={handleSubmit}
              disabled={submitting || !audioFile || !!errors.audio || audioDuration > MAX_AUDIO_DURATION_SECONDS}
              className="w-full"
              size="lg"
            >
              {submitting ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  {t("submitting") || "Submitting..."}
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4 mr-2" />
                  {t("submit_for_evaluation") || "Submit for Evaluation"}
                </>
              )}
            </Button>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>{t("requirements") || "Requirements"}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center gap-2 text-sm">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span>{t("max_duration") || "Max duration"}: <strong>{MAX_AUDIO_DURATION_SECONDS / 60} {t("minutes") || "minutes"}</strong></span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Upload className="w-4 h-4 text-muted-foreground" />
                  <span>{t("max_file_size") || "Max file size"}: <strong>{MAX_AUDIO_FILE_SIZE_MB} MB</strong></span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Mic className="w-4 h-4 text-muted-foreground" />
                  <span>{t("allowed_formats") || "Allowed formats"}: <strong>MP3, WAV, M4A, OGG</strong></span>
                </div>
              </CardContent>
            </Card>

            {prompt.has_sample_answer && prompt.sample_answer_audio_url && (
              <Card>
                <CardHeader>
                  <CardTitle>{t("sample_answer") || "Sample Answer"}</CardTitle>
                  {prompt.sample_answer_band_score && (
                    <CardDescription>
                      {t("band_score") || "Band Score"}: {prompt.sample_answer_band_score}
                    </CardDescription>
                  )}
                </CardHeader>
                <CardContent>
                  <audio
                    src={prompt.sample_answer_audio_url}
                    controls
                    className="w-full mb-2"
                  />
                  {prompt.sample_answer_text && (
                    <details className="text-sm">
                      <summary className="cursor-pointer font-medium hover:text-primary">
                        {t("view_transcript") || "View transcript"}
                      </summary>
                      <div className="mt-2 prose prose-sm max-w-none">
                        <p className="whitespace-pre-wrap">{prompt.sample_answer_text}</p>
                      </div>
                    </details>
                  )}
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </PageContainer>
    </AppLayout>
  )
}

