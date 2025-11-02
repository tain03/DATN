"use client"

import { toast as sonnerToast } from "sonner"
import { useTranslations } from "@/lib/i18n"

/**
 * useToastWithI18n - Toast utility hook with i18n support
 * 
 * Provides easy-to-use toast notifications with translation support
 */
export function useToastWithI18n() {
  const t = useTranslations('common')

  return {
    /**
     * Show success toast
     */
    success: (message: string, options?: { translationKey?: string; duration?: number }) => {
      const text = options?.translationKey ? t(options.translationKey) : message
      return sonnerToast.success(text, {
        duration: options?.duration || 4000,
      })
    },

    /**
     * Show error toast
     */
    error: (message: string, options?: { translationKey?: string; duration?: number }) => {
      const text = options?.translationKey ? t(options.translationKey) : message
      return sonnerToast.error(text, {
        duration: options?.duration || 5000,
      })
    },

    /**
     * Show info toast
     */
    info: (message: string, options?: { translationKey?: string; duration?: number }) => {
      const text = options?.translationKey ? t(options.translationKey) : message
      return sonnerToast.info(text, {
        duration: options?.duration || 4000,
      })
    },

    /**
     * Show warning toast
     */
    warning: (message: string, options?: { translationKey?: string; duration?: number }) => {
      const text = options?.translationKey ? t(options.translationKey) : message
      return sonnerToast.warning(text, {
        duration: options?.duration || 4000,
      })
    },

    /**
     * Show loading toast (returns dismiss function)
     */
    loading: (message: string, options?: { translationKey?: string }) => {
      const text = options?.translationKey ? t(options.translationKey) : message
      return sonnerToast.loading(text)
    },

    /**
     * Dismiss toast by id
     */
    dismiss: (toastId: string | number) => {
      sonnerToast.dismiss(toastId)
    },

    /**
     * Dismiss all toasts
     */
    dismissAll: () => {
      sonnerToast.dismiss()
    },

    /**
     * Promise toast - shows loading, then success/error
     */
    promise: <T,>(
      promise: Promise<T>,
      options: {
        loading: string | { message: string; translationKey?: string }
        success: string | { message: string; translationKey?: string } | ((data: T) => string | { message: string; translationKey?: string })
        error: string | { message: string; translationKey?: string } | ((error: any) => string | { message: string; translationKey?: string })
      }
    ) => {
      const getText = (input: string | { message: string; translationKey?: string }) => {
        if (typeof input === 'string') return input
        return input.translationKey ? t(input.translationKey) : input.message
      }

      return sonnerToast.promise(promise, {
        loading: getText(options.loading),
        success: (data) => {
          const result = typeof options.success === 'function' ? options.success(data) : options.success
          return getText(result)
        },
        error: (error) => {
          const result = typeof options.error === 'function' ? options.error(error) : options.error
          return getText(result)
        },
      })
    },
  }
}

/**
 * Direct toast functions for use outside components
 * Note: These don't support translations, use useToastWithI18n hook in components
 */
export const toast = {
  success: (message: string) => sonnerToast.success(message),
  error: (message: string) => sonnerToast.error(message),
  info: (message: string) => sonnerToast.info(message),
  warning: (message: string) => sonnerToast.warning(message),
  loading: (message: string) => sonnerToast.loading(message),
  dismiss: (id?: string | number) => sonnerToast.dismiss(id),
  dismissAll: () => sonnerToast.dismiss(),
  promise: <T,>(promise: Promise<T>, options: any) => sonnerToast.promise(promise, options),
}


