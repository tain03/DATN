"use client"

import React from "react"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { AlertTriangle, FileText, Mic } from "lucide-react"
import { useTranslations } from '@/lib/i18n'

interface SubmitConfirmationDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onConfirm: () => void
  type?: "writing" | "speaking" | "exercise"
}

export function SubmitConfirmationDialog({
  open,
  onOpenChange,
  onConfirm,
  type = "exercise",
}: SubmitConfirmationDialogProps) {
  const t = useTranslations("exercises")
  const tCommon = useTranslations("common")

  const handleConfirm = () => {
    onConfirm()
    onOpenChange(false)
  }

  const getTitle = () => {
    if (type === "writing") {
      return t("confirm_submit_writing") || "Xác nhận nộp bài viết"
    } else if (type === "speaking") {
      return t("confirm_submit_speaking") || "Xác nhận nộp bài nói"
    }
    return t("confirm_submit_exercise") || "Xác nhận nộp bài"
  }

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent className="sm:max-w-[500px]">
        <AlertDialogHeader>
          <div className="flex items-center gap-4 mb-2">
            {/* Icon with gradient background */}
            <div className="relative flex-shrink-0">
              <div className="absolute inset-0 rounded-full bg-primary/20 blur-xl animate-pulse" />
              <div className="relative flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-primary/20 to-primary/5 border-2 border-primary/20">
                {type === "writing" ? (
                  <FileText className="w-8 h-8 text-primary" strokeWidth={2} />
                ) : type === "speaking" ? (
                  <Mic className="w-8 h-8 text-primary" strokeWidth={2} />
                ) : (
                  <AlertTriangle className="w-8 h-8 text-primary" strokeWidth={2} />
                )}
              </div>
            </div>
            <div className="flex-1">
              <AlertDialogTitle className="text-xl font-bold text-foreground">
                {getTitle()}
              </AlertDialogTitle>
            </div>
          </div>
          <AlertDialogDescription className="text-base text-muted-foreground pt-2">
            {t('are_you_sure_you_want_to_submit_you_cann') || 
             "Bạn có chắc muốn nộp bài? Bạn sẽ không thể thay đổi câu trả lời sau khi nộp."}
          </AlertDialogDescription>
        </AlertDialogHeader>
        
        {/* Warning box */}
        <div className="my-4 p-4 rounded-lg bg-yellow-50 dark:bg-yellow-950/20 border border-yellow-200 dark:border-yellow-800">
          <div className="flex gap-3">
            <AlertTriangle className="w-5 h-5 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm font-medium text-yellow-900 dark:text-yellow-100 mb-1">
                {t("important_note") || "Lưu ý quan trọng"}
              </p>
              <p className="text-xs text-yellow-800 dark:text-yellow-200">
                {t("cannot_edit_after_submit") || "Sau khi nộp bài, bạn không thể chỉnh sửa hoặc thay đổi câu trả lời. Hãy kiểm tra lại bài làm của bạn trước khi xác nhận."}
              </p>
            </div>
          </div>
        </div>

        <AlertDialogFooter className="gap-2 sm:gap-0">
          <AlertDialogCancel className="w-full sm:w-auto">
            {tCommon("cancel") || t("cancel") || "Hủy"}
          </AlertDialogCancel>
          <AlertDialogAction
            onClick={handleConfirm}
            className="w-full sm:w-auto bg-primary hover:bg-primary/90"
          >
            {t("submit_exercise") || "Xác nhận nộp bài"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

