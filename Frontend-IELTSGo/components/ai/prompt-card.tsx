"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Clock, Target, FileText, ArrowRight, Award } from "lucide-react"
import { getCardVariant } from "@/lib/utils/card-variants"
import { cn } from "@/lib/utils"
import type { WritingPrompt, SpeakingPrompt } from "@/types/ai"
import Link from "next/link"

interface PromptCardProps {
  prompt: WritingPrompt | SpeakingPrompt
  type: "writing" | "speaking"
  onClick?: () => void
}

export function PromptCard({ prompt, type, onClick }: PromptCardProps) {
  const isWriting = type === "writing"
  const writingPrompt = isWriting ? (prompt as WritingPrompt) : null
  const speakingPrompt = !isWriting ? (prompt as SpeakingPrompt) : null

  const getDifficultyColor = (difficulty?: string) => {
    switch (difficulty) {
      case "easy":
        return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      case "medium":
        return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      case "hard":
        return "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  const getTaskTypeLabel = () => {
    if (isWriting) {
      return writingPrompt?.task_type === "task1" ? "Task 1" : "Task 2"
    }
    return `Part ${speakingPrompt?.part_number || 1}`
  }

  const href = isWriting 
    ? `/ai/writing/${prompt.id}`
    : `/ai/speaking/${prompt.id}`

  return (
    <Card 
      className={cn(
        getCardVariant("interactive"),
        "h-full flex flex-col"
      )}
      onClick={onClick}
    >
      <CardHeader>
        <div className="flex items-start justify-between gap-2 mb-2">
          <Badge variant="outline" className="capitalize">
            {getTaskTypeLabel()}
          </Badge>
          {prompt.difficulty && (
            <Badge className={getDifficultyColor(prompt.difficulty)}>
              {prompt.difficulty}
            </Badge>
          )}
        </div>
        <CardTitle className="text-lg line-clamp-2">
          {prompt.topic || speakingPrompt?.topic_category || "IELTS Prompt"}
        </CardTitle>
        <CardDescription className="line-clamp-3 text-sm">
          {prompt.prompt_text.slice(0, 150)}
          {prompt.prompt_text.length > 150 && "..."}
        </CardDescription>
      </CardHeader>
      <CardContent className="flex-1 flex flex-col justify-end">
        <div className="flex items-center gap-4 text-sm text-muted-foreground mb-4">
          {isWriting ? (
            <>
              <div className="flex items-center gap-1">
                <FileText className="w-4 h-4" />
                <span>{writingPrompt?.task_type === "task1" ? "150+" : "250+"} words</span>
              </div>
            </>
          ) : (
            <>
              {speakingPrompt?.preparation_time_seconds && (
                <div className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  <span>{speakingPrompt.preparation_time_seconds}s prep</span>
                </div>
              )}
              {speakingPrompt?.speaking_time_seconds && (
                <div className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  <span>{speakingPrompt.speaking_time_seconds}s speak</span>
                </div>
              )}
            </>
          )}
          {prompt.times_used > 0 && (
            <div className="flex items-center gap-1">
              <Target className="w-4 h-4" />
              <span>{prompt.times_used} uses</span>
            </div>
          )}
          {prompt.average_score && (
            <div className="flex items-center gap-1">
              <Award className="w-4 h-4" />
              <span>Avg: {prompt.average_score.toFixed(1)}</span>
            </div>
          )}
        </div>
        <Button asChild className="w-full" variant="default">
          <Link href={href}>
            {isWriting ? "Start Writing" : "Start Speaking"}
            <ArrowRight className="w-4 h-4 ml-2" />
          </Link>
        </Button>
      </CardContent>
    </Card>
  )
}

