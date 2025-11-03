"use client"

import { useState, useRef, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { AlertCircle, Info, Mic, Play, Pause, Upload, Trash2 } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

// Validation constants (matching backend)
const MAX_AUDIO_FILE_SIZE_MB = 50
const MAX_AUDIO_FILE_SIZE_BYTES = 50 * 1024 * 1024
const MAX_AUDIO_DURATION_SECONDS = 300 // 5 minutes
const ALLOWED_EXTENSIONS = [".mp3", ".wav", ".m4a", ".ogg"]

interface SpeakingExerciseFormProps {
  prompt: string // Task prompt text from exercise instructions or section
  partNumber?: 1 | 2 | 3 // Determine from exercise or default to 1
  onSubmit: (audioFile: File, duration: number) => void // Changed to sync callback
  submitting?: boolean
  onFileChange?: (file: File | null, duration: number) => void // For controlled component
}

export function SpeakingExerciseForm({
  prompt,
  partNumber = 1,
  onSubmit,
  submitting = false,
  onFileChange,
}: SpeakingExerciseFormProps) {
  const t = useTranslations("exercises")
  const tAI = useTranslations("ai")

  const [recording, setRecording] = useState(false)
  const [audioFile, setAudioFile] = useState<File | null>(null)
  const [audioURL, setAudioURL] = useState<string | null>(null)
  const [audioDuration, setAudioDuration] = useState<number>(0)
  const [errors, setErrors] = useState<{ audio?: string }>({})

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])

  const validateAudioFile = (file: File): boolean => {
    const newErrors: typeof errors = {}

    if (file.size > MAX_AUDIO_FILE_SIZE_BYTES) {
      newErrors.audio =
        tAI("audio_file_too_large") ||
        `Audio file size (${(file.size / (1024 * 1024)).toFixed(2)} MB) exceeds maximum (${MAX_AUDIO_FILE_SIZE_MB} MB)`
      setErrors(newErrors)
      return false
    }

    const ext = "." + file.name.split(".").pop()?.toLowerCase()
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      newErrors.audio =
        tAI("audio_format_not_supported") ||
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

    if (audioURL) {
      URL.revokeObjectURL(audioURL)
    }
    const url = URL.createObjectURL(file)
    setAudioURL(url)

    const audio = new Audio(url)
    audio.addEventListener("loadedmetadata", () => {
      const dur = Math.floor(audio.duration)
      setAudioDuration(dur)
      onFileChange?.(file, dur)
      if (dur > MAX_AUDIO_DURATION_SECONDS) {
        setErrors({
          audio:
            tAI("audio_duration_too_long") ||
            `Audio duration (${dur}s) exceeds maximum (${MAX_AUDIO_DURATION_SECONDS}s)`,
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
        setAudioDuration(0)

        const file = new File([audioBlob], "recording.webm", { type: "audio/webm" })
        setAudioFile(file)

        const audio = new Audio(audioUrl)
        audio.addEventListener("loadedmetadata", () => {
          const dur = Math.floor(audio.duration)
          setAudioDuration(dur)
          onFileChange?.(file, dur)
        })

        stream.getTracks().forEach((track) => track.stop())
      }

      mediaRecorder.start()
      setRecording(true)
    } catch (error) {
      console.error("Failed to start recording:", error)
      setErrors({
        audio: tAI("failed_to_start_recording") || "Failed to start recording. Please check microphone permissions.",
      })
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
    if (!audioFile) {
      setErrors({ audio: tAI("audio_required") || "Please record or upload an audio file" })
      return
    }

    if (audioDuration > MAX_AUDIO_DURATION_SECONDS) {
      setErrors({ audio: tAI("audio_duration_too_long") || "Audio duration exceeds maximum" })
      return
    }

    await onSubmit(audioFile, audioDuration)
  }

  return (
    <div className="space-y-6">
      {/* Prompt */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            🗣️ {tAI("task_prompt") || "Task Prompt"}
          </CardTitle>
          {partNumber && (
            <CardDescription>
              {tAI("part_number") || "Part"}: {partNumber}
            </CardDescription>
          )}
        </CardHeader>
        <CardContent>
          <div className="prose prose-sm max-w-none">
            <p className="whitespace-pre-wrap">{prompt}</p>
          </div>
        </CardContent>
      </Card>

      {/* Audio Recording/Upload */}
      <Card>
        <CardHeader>
          <CardTitle>{tAI("record_or_upload_audio") || "Record or Upload Audio"}</CardTitle>
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
                  <span className="text-sm font-medium">
                    {tAI("audio_ready") || "Audio ready"}
                  </span>
                  {audioDuration > 0 && (
                    <span className="text-sm text-muted-foreground">
                      ({Math.floor(audioDuration / 60)}:
                      {(audioDuration % 60).toString().padStart(2, "0")})
                    </span>
                  )}
                </div>
                <Button variant="outline" size="sm" onClick={removeAudio}>
                  <Trash2 className="w-4 h-4 mr-2" />
                  {tAI("remove") || "Remove"}
                </Button>
              </div>
              <audio src={audioURL} controls className="w-full" />
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
                      {tAI("stop_recording") || "Stop Recording"}
                    </>
                  ) : (
                    <>
                      <Mic className="w-4 h-4 mr-2" />
                      {tAI("start_recording") || "Start Recording"}
                    </>
                  )}
                </Button>
                <Button variant="outline" asChild className="flex-1">
                  <label>
                    <Upload className="w-4 h-4 mr-2" />
                    {tAI("upload_file") || "Upload File"}
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
                <li>
                  {tAI("tip_speak_clearly") ||
                    "Speak clearly and at a moderate pace"}
                </li>
                <li>
                  {tAI("tip_max_duration") ||
                    `Maximum duration: ${MAX_AUDIO_DURATION_SECONDS / 60} minutes`}
                </li>
              </ul>
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>

    </div>
  )
}

// Export hook for parent component
export function useSpeakingExerciseForm() {
  const [audioFile, setAudioFile] = useState<File | null>(null)
  const [audioDuration, setAudioDuration] = useState<number>(0)
  const [errors, setErrors] = useState<{ audio?: string }>({})

  const validate = (): boolean => {
    if (!audioFile) {
      setErrors({ audio: "Please record or upload an audio file" })
      return false
    }

    if (audioDuration > MAX_AUDIO_DURATION_SECONDS) {
      setErrors({ audio: "Audio duration exceeds maximum" })
      return false
    }

    setErrors({})
    return true
  }

  return {
    audioFile,
    setAudioFile,
    audioDuration,
    setAudioDuration,
    errors,
    validate,
  }
}

