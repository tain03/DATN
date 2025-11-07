"use client"

import React from "react"
import { Card, CardContent } from "@/components/ui/card"
import { 
  Loader2, 
  Sparkles, 
  FileText, 
  Mic, 
  Upload, 
  MessageSquare, 
  Brain, 
  Award
} from "lucide-react"
import { useTranslations } from '@/lib/i18n'

interface AIEvaluationLoadingProps {
  type: "writing" | "speaking"
  submissionId?: string
  progress?: number
  currentStep?: number
  totalSteps?: number
}

const getStepInfo = (step: number, type: "writing" | "speaking", t: any) => {
  if (type === "writing") {
    const steps = [
      { 
        icon: FileText, 
        label: t("step_submitting") || "Đang xử lý bài viết...", 
        description: t("step_submitting_desc") || "Đang kiểm tra và phân tích nội dung bài viết của bạn" 
      },
      { 
        icon: Brain, 
        label: t("step_analyzing") || "Đang phân tích...", 
        description: t("step_analyzing_desc_writing") || "Đánh giá cấu trúc, ngữ pháp và từ vựng" 
      },
      { 
        icon: MessageSquare, 
        label: t("step_evaluating") || "Đang chấm điểm...", 
        description: t("step_evaluating_desc_writing") || "Đánh giá theo các tiêu chí IELTS chấm điểm" 
      },
      { 
        icon: Award, 
        label: t("step_generating_feedback") || "Đang tạo phản hồi...", 
        description: t("step_generating_feedback_desc") || "Tạo phản hồi chi tiết và đề xuất cải thiện" 
      },
    ]
    return steps[step] || steps[0]
  } else {
    const steps = [
      { 
        icon: Upload, 
        label: t("step_uploading") || "Đang tải file âm thanh...", 
        description: t("step_uploading_desc") || "Đang xử lý và tải lên file ghi âm của bạn" 
      },
      { 
        icon: MessageSquare, 
        label: t("step_transcribing") || "Đang chuyển đổi giọng nói...", 
        description: t("step_transcribing_desc") || "Đang chuyển đổi giọng nói thành văn bản để phân tích" 
      },
      { 
        icon: Brain, 
        label: t("step_analyzing") || "Đang phân tích...", 
        description: t("step_analyzing_desc_speaking") || "Đánh giá phát âm, ngữ pháp và từ vựng" 
      },
      { 
        icon: Award, 
        label: t("step_evaluating") || "Đang chấm điểm...", 
        description: t("step_evaluating_desc_speaking") || "Đánh giá theo các tiêu chí IELTS Speaking" 
      },
    ]
    return steps[step] || steps[0]
  }
}

export function AIEvaluationLoading({
  type,
  submissionId,
  progress = 0,
  currentStep = 0,
  totalSteps = 4,
}: AIEvaluationLoadingProps) {
  const t = useTranslations("ai")
  const stepInfo = getStepInfo(currentStep, type, t)
  const StepIcon = stepInfo.icon
  const progressPercentage = Math.min(95, Math.max(5, ((currentStep + 1) / totalSteps) * 100))

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Animated Background with Gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-background to-primary/5">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(120,119,198,0.1),transparent_50%)] animate-pulse" />
      </div>

      {/* Floating Particles Effect */}
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(6)].map((_, i) => (
          <div
            key={i}
            className="absolute rounded-full bg-primary/20 animate-float"
            style={{
              width: `${20 + i * 10}px`,
              height: `${20 + i * 10}px`,
              left: `${10 + i * 15}%`,
              top: `${10 + i * 12}%`,
              animationDelay: `${i * 0.5}s`,
              animationDuration: `${3 + i * 0.5}s`,
            }}
          />
        ))}
      </div>

      {/* Main Card */}
      <Card className="relative w-full max-w-2xl shadow-2xl border-0 backdrop-blur-xl bg-background/80 dark:bg-background/90 overflow-hidden">
        {/* Gradient Border Effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-primary/20 via-primary/10 to-primary/20 opacity-50" />
        
        <CardContent className="relative p-8 md:p-12">
          <div className="flex flex-col items-center justify-center space-y-8">
            {/* Main Loading Icon with Glow Effect */}
            <div className="relative">
              {/* Outer Glow Rings */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-40 h-40 rounded-full bg-primary/20 blur-2xl animate-pulse" />
              </div>
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-32 h-32 rounded-full bg-primary/10 blur-xl animate-ping" style={{ animationDuration: '2s' }} />
              </div>
              
              {/* Main Icon Container */}
              <div className="relative flex items-center justify-center w-28 h-28">
                {/* Spinning Ring */}
                <div className="absolute inset-0 rounded-full border-4 border-transparent border-t-primary border-r-primary/50 animate-spin" style={{ animationDuration: '2s' }} />
                
                {/* Center Icon */}
                <div className="relative z-10 flex items-center justify-center w-20 h-20 rounded-full bg-gradient-to-br from-primary/20 to-primary/5 backdrop-blur-sm">
                  {type === "writing" ? (
                    <FileText className="w-10 h-10 text-primary animate-pulse" strokeWidth={2} />
                  ) : (
                    <Mic className="w-10 h-10 text-primary animate-pulse" strokeWidth={2} />
                  )}
                </div>
                
                {/* Sparkles Effect */}
                <div className="absolute -top-2 -right-2">
                  <Sparkles className="w-6 h-6 text-primary animate-pulse" />
                </div>
                <div className="absolute -bottom-2 -left-2">
                  <Sparkles className="w-5 h-5 text-primary/70 animate-pulse" style={{ animationDelay: '0.5s' }} />
                </div>
              </div>
            </div>

            {/* Title Section */}
            <div className="text-center space-y-3">
              <h2 className="text-3xl md:text-4xl font-bold bg-gradient-to-r from-primary via-primary/80 to-primary bg-clip-text text-transparent">
                {type === "writing" 
                  ? (t("evaluating_writing") || "Đang chấm điểm bài viết")
                  : (t("evaluating_speaking") || "Đang chấm điểm bài nói")
                }
              </h2>
              <p className="text-muted-foreground text-base md:text-lg">
                {t("please_wait_processing") || "Vui lòng đợi trong khi hệ thống đang xử lý..."}
              </p>
            </div>

            {/* Current Step Indicator */}
            <div className="w-full max-w-md space-y-4">
              <div className="flex items-center justify-center gap-3 p-4 rounded-lg bg-primary/5 border border-primary/10">
                <StepIcon className="w-5 h-5 text-primary animate-pulse" />
                <div className="flex-1 text-left">
                  <p className="font-semibold text-sm text-foreground">
                    {stepInfo.label}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {stepInfo.description}
                  </p>
                </div>
              </div>

              {/* Enhanced Progress Bar */}
              <div className="space-y-2">
                <div className="flex justify-between items-center text-xs text-muted-foreground">
                  <span>{t("progress") || "Tiến độ"}</span>
                  <span className="font-semibold text-primary">{Math.round(progressPercentage)}%</span>
                </div>
                <div className="relative h-3 w-full bg-muted/50 rounded-full overflow-hidden shadow-inner">
                  {/* Progress Fill */}
                  <div 
                    className="relative h-full bg-gradient-to-r from-primary via-primary/90 to-primary rounded-full transition-all duration-700 ease-out shadow-lg overflow-hidden"
                    style={{ 
                      width: `${progressPercentage}%`,
                    }}
                  >
                    {/* Shimmer Effect */}
                    <div 
                      className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"
                      style={{
                        backgroundSize: '200% 100%',
                      }}
                    />
                    {/* Glow Effect on Progress */}
                    <div className="absolute inset-0 bg-white/20 rounded-full blur-sm" />
                  </div>
                </div>
              </div>

              {/* Step Indicators */}
              <div className="flex justify-center gap-2">
                {[...Array(totalSteps)].map((_, index) => (
                  <div
                    key={index}
                    className={`h-2 rounded-full transition-all duration-300 ${
                      index <= currentStep
                        ? 'w-8 bg-primary shadow-lg shadow-primary/50'
                        : 'w-2 bg-muted'
                    }`}
                  />
                ))}
              </div>
            </div>

            {/* Info Message */}
            <div className="text-center max-w-md">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/5 border border-primary/10">
                <Loader2 className="w-4 h-4 text-primary animate-spin" />
                <p className="text-xs text-muted-foreground">
                  {t("evaluation_takes_time") || "Quá trình chấm điểm có thể mất 30-60 giây. Vui lòng không đóng trang này."}
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

    </div>
  )
}