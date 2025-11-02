"use client"

import { useState } from "react"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"
import { Eye, EyeOff, CheckCircle2, AlertCircle, Loader2 } from "lucide-react"
import { cn } from "@/lib/utils"

interface EnhancedFormFieldProps {
  label: string
  name: string
  type?: "text" | "email" | "password" | "number" | "textarea"
  placeholder?: string
  value: string | number | undefined
  onChange: (value: string) => void
  onBlur?: () => void
  error?: string
  success?: boolean
  validating?: boolean
  required?: boolean
  disabled?: boolean
  className?: string
  rows?: number
  autoComplete?: string
  autoFocus?: boolean
  helperText?: string
  showValidationState?: boolean
}

/**
 * EnhancedFormField - Form field with enhanced validation feedback
 * 
 * Features:
 * - Real-time validation states (error, success, validating)
 * - Visual indicators (icons) for each state
 * - Smooth transitions between states
 * - Helper text support
 */
export function EnhancedFormField({
  label,
  name,
  type = "text",
  placeholder,
  value,
  onChange,
  onBlur,
  error,
  success,
  validating,
  required,
  disabled,
  className,
  rows = 4,
  autoComplete,
  autoFocus,
  helperText,
  showValidationState = true,
}: EnhancedFormFieldProps) {
  const [showPassword, setShowPassword] = useState(false)
  const [hasBlurred, setHasBlurred] = useState(false)
  const id = `field-${name}`
  const isPassword = type === "password"
  const inputType = isPassword && showPassword ? "text" : type
  
  // Show validation state only after blur or if error exists
  const showError = error && (hasBlurred || !!error)
  const showSuccess = success && !error && hasBlurred && showValidationState
  const showValidating = validating && showValidationState

  const handleBlur = () => {
    setHasBlurred(true)
    onBlur?.()
  }

  return (
    <div className={cn("space-y-2", className)}>
      <Label htmlFor={id} className="text-sm font-medium">
        {label}
        {required && <span className="text-destructive ml-1">*</span>}
      </Label>
      
      <div className="relative">
        {type === "textarea" ? (
          <Textarea
            id={id}
            name={name}
            placeholder={placeholder}
            value={value ?? ""}
            onChange={(e) => onChange(e.target.value)}
            onBlur={handleBlur}
            disabled={disabled}
            rows={rows}
            autoFocus={autoFocus}
            className={cn(
              "transition-all duration-200",
              showError && "border-destructive focus-visible:ring-destructive/20 focus-visible:ring-[3px]",
              showSuccess && "border-green-500/50 focus-visible:ring-green-500/20 focus-visible:ring-[3px]",
              showValidating && "border-blue-500/50"
            )}
            aria-invalid={!!showError}
            aria-describedby={
              showError ? `${id}-error` : helperText ? `${id}-helper` : undefined
            }
          />
        ) : (
          <Input
            id={id}
            name={name}
            type={inputType}
            placeholder={placeholder}
            autoFocus={autoFocus}
            value={value ?? ""}
            onChange={(e) => onChange(e.target.value)}
            onBlur={handleBlur}
            disabled={disabled || validating}
            {...(autoComplete ? { autoComplete } : {})}
            className={cn(
              "transition-all duration-200 pr-10",
              showError && "border-destructive focus-visible:ring-destructive/20 focus-visible:ring-[3px]",
              showSuccess && "border-green-500/50 focus-visible:ring-green-500/20 focus-visible:ring-[3px]",
              showValidating && "border-blue-500/50",
              isPassword && "pr-20"
            )}
            aria-invalid={!!showError}
            aria-describedby={
              showError ? `${id}-error` : helperText ? `${id}-helper` : undefined
            }
          />
        )}

        {/* Right side icons */}
        <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-2">
          {/* Validation state icons */}
          {showValidating && (
            <Loader2 className="h-4 w-4 text-blue-500 animate-spin" />
          )}
          {showSuccess && !showValidating && (
            <CheckCircle2 className="h-4 w-4 text-green-500" />
          )}
          {showError && !showValidating && (
            <AlertCircle className="h-4 w-4 text-destructive" />
          )}
          
          {/* Password toggle (only for password fields) */}
          {isPassword && !showValidating && !showSuccess && (
            <Button
              type="button"
              variant="ghost"
              size="icon-sm"
              className="hover:bg-transparent"
              onClick={() => setShowPassword(!showPassword)}
              disabled={disabled}
              aria-label={showPassword ? "Hide password" : "Show password"}
            >
              {showPassword ? (
                <EyeOff className="h-4 w-4 text-muted-foreground" />
              ) : (
                <Eye className="h-4 w-4 text-muted-foreground" />
              )}
            </Button>
          )}
        </div>
      </div>

      {/* Error message */}
      {showError && (
        <p 
          id={`${id}-error`}
          className="text-sm text-destructive flex items-center gap-1.5 animate-in fade-in slide-in-from-top-1 duration-200"
          role="alert"
        >
          <AlertCircle className="h-3.5 w-3.5 shrink-0" />
          {error}
        </p>
      )}

      {/* Helper text (shown when no error) */}
      {!showError && helperText && (
        <p 
          id={`${id}-helper`}
          className="text-sm text-muted-foreground"
        >
          {helperText}
        </p>
      )}
    </div>
  )
}

