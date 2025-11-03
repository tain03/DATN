"use client"

import { useState, useEffect } from "react"
import { Star, Edit2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { PageLoading } from "@/components/ui/page-loading"
import { coursesApi } from "@/lib/api/courses"
import { useToast } from "@/hooks/use-toast"
import { useAuth } from "@/lib/contexts/auth-context"
import { getCardVariant } from "@/lib/utils/card-variants"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"

interface Review {
  id: string
  user_id: string
  rating: number
  title?: string
  comment?: string
  created_at: string
}

interface ReviewFormProps {
  courseId: string
  onSuccess?: () => void
}

export function ReviewForm({ courseId, onSuccess }: ReviewFormProps) {
  const { user } = useAuth()
  const t = useTranslations('common')
  const tReviews = useTranslations('reviews')
  const [existingReview, setExistingReview] = useState<Review | null>(null)
  const [rating, setRating] = useState(0)
  const [hoverRating, setHoverRating] = useState(0)
  const [title, setTitle] = useState("")
  const [comment, setComment] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [loadingReview, setLoadingReview] = useState(true)
  const { toast } = useToast()

  // Load existing review on mount
  useEffect(() => {
    const loadExistingReview = async () => {
      if (!user?.id) {
        setLoadingReview(false)
        return
      }

      try {
        setLoadingReview(true)
        const response = await coursesApi.getCourseReviews(courseId, 1, 100) // Get first 100 to find user's review
        const reviews: Review[] = response?.reviews || []
        
        // Find current user's review
        const userReview = reviews.find((r) => r.user_id === user.id)
        
        if (userReview) {
          setExistingReview(userReview)
          setRating(userReview.rating)
          setTitle(userReview.title || "")
          setComment(userReview.comment || "")
        }
      } catch (error) {
        console.error("Failed to load existing review:", error)
      } finally {
        setLoadingReview(false)
      }
    }

    loadExistingReview()
  }, [courseId, user?.id])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Rating is required only for new reviews (not for updates)
    if (!existingReview && rating === 0) {
      toast({
        variant: "destructive",
        title: t('error'),
        description: tReviews('rating_required') || "Vui lòng chọn số sao đánh giá.",
      })
      return
    }

    try {
      setSubmitting(true)

      if (existingReview) {
        // Update existing review
        // Only send fields that have changed or are provided
        const updateData: { rating?: number; title?: string; comment?: string } = {}
        
        // Only update rating if user changed it
        if (rating !== existingReview.rating) {
          updateData.rating = rating
        }
        
        // Update title if provided
        const newTitle = title.trim() || undefined
        if (newTitle !== (existingReview.title || undefined)) {
          updateData.title = newTitle
        }
        
        // Update comment if provided
        const newComment = comment.trim() || undefined
        if (newComment !== (existingReview.comment || undefined)) {
          updateData.comment = newComment
        }

        // If nothing changed, show message
        if (Object.keys(updateData).length === 0) {
          toast({
            title: t('notification') || "Thông báo",
            description: tReviews('no_changes') || "Bạn chưa thay đổi gì trong đánh giá.",
          })
          return
        }

        await coursesApi.updateCourseReview(courseId, updateData)

        toast({
          title: t('success'),
          description: tReviews('success_update') || "Đánh giá của bạn đã được cập nhật!",
        })
      } else {
        // Create new review
        await coursesApi.createCourseReview(courseId, {
          rating,
          title: title.trim() || undefined,
          comment: comment.trim() || undefined,
        })

        toast({
          title: t('success'),
          description: tReviews('success_submit') || "Đánh giá của bạn đã được đăng thành công!",
        })

        // Reset form (will be reloaded via onSuccess)
        setRating(0)
        setTitle("")
        setComment("")
      }

      onSuccess?.()
    } catch (error: any) {
      const errorMessage = error?.response?.data?.error?.message || 
        (existingReview 
          ? (tReviews('error_update') || "Không thể cập nhật đánh giá")
          : (tReviews('error_submit') || "Không thể gửi đánh giá"))
      toast({
        variant: "destructive",
        title: t('error'),
        description: errorMessage,
      })
    } finally {
      setSubmitting(false)
    }
  }

  if (loadingReview) {
    return (
      <Card className={cn(getCardVariant('default'))}>
        <CardContent className="py-12">
          <PageLoading translationKey="loading" />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className={cn(
      "bg-white dark:bg-card",
      "border border-gray-200 dark:border-border",
      "shadow-sm hover:shadow-md",
      "transition-all duration-200",
      "rounded-lg",
      "sticky top-4"
    )}>
      <CardHeader className="px-3 py-2.5 border-b border-border/50">
        <div className="flex items-center gap-1.5 mb-0.5">
          {existingReview && <Edit2 className="w-4 h-4 text-primary" />}
          <CardTitle className="text-base font-semibold">
            {existingReview ? tReviews('edit_review') : tReviews('write_review')}
          </CardTitle>
        </div>
        <CardDescription className="text-xs text-muted-foreground">
          {existingReview 
            ? tReviews('edit_description')
            : tReviews('write_description')
          }
        </CardDescription>
      </CardHeader>
      <CardContent className="px-3 py-2.5">
        <form onSubmit={handleSubmit} className="space-y-2">
          {/* Star Rating - Compact */}
          <div className="space-y-2">
            <Label className="text-xs font-medium">
              {tReviews('your_rating')}
              {existingReview && (
                <span className="text-[10px] text-muted-foreground ml-1.5 font-normal">
                  {tReviews('can_change')}
                </span>
              )}
            </Label>
            <div className="flex items-center gap-2">
              <div className="flex gap-0.5">
                {Array.from({ length: 5 }).map((_, i) => {
                  const starValue = i + 1
                  return (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setRating(starValue)}
                      onMouseEnter={() => setHoverRating(starValue)}
                      onMouseLeave={() => setHoverRating(0)}
                      className="transition-all duration-200 hover:scale-110 active:scale-95"
                      aria-label={`Đánh giá ${starValue} sao`}
                    >
                      <Star
                        className={cn(
                          "w-5 h-5 transition-colors",
                          starValue <= (hoverRating || rating)
                            ? "fill-yellow-400 text-yellow-400"
                            : "text-gray-300 dark:text-gray-600"
                        )}
                      />
                    </button>
                  )
                })}
              </div>
              {rating > 0 && (
                <span className="text-xs font-medium text-muted-foreground">
                  {rating}/5
                </span>
              )}
            </div>
            {existingReview && rating === 0 && (
              <p className="text-[10px] text-muted-foreground">
                {tReviews('keep_current_rating', { rating: existingReview.rating }) || 
                 `Bạn đang giữ nguyên đánh giá ${existingReview.rating} sao hiện tại`}
              </p>
            )}
          </div>

          {/* Title - Compact */}
          <div className="space-y-1.5">
            <Label htmlFor="review-title" className="text-xs font-medium">
              {tReviews('title_label')} <span className="text-muted-foreground font-normal text-[10px]">{tReviews('title_optional')}</span>
            </Label>
            <Input
              id="review-title"
              placeholder={tReviews('title_placeholder')}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={200}
              className="h-8 text-sm"
            />
            {title.length > 0 && (
              <p className="text-[10px] text-muted-foreground text-right">
                {title.length}/200
              </p>
            )}
          </div>

          {/* Comment - Compact */}
          <div className="space-y-1.5">
            <Label htmlFor="review-comment" className="text-xs font-medium">
              {tReviews('comment_label')} <span className="text-muted-foreground font-normal text-[10px]">{tReviews('comment_optional')}</span>
            </Label>
            <Textarea
              id="review-comment"
              placeholder={tReviews('comment_placeholder')}
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              rows={4}
              className="resize-none text-sm"
            />
          </div>

          {/* Submit - Compact */}
          <Button 
            type="submit" 
            disabled={submitting || (!existingReview && rating === 0)} 
            className="w-full h-9 text-sm font-medium shadow-sm"
            size="sm"
          >
            {submitting 
              ? (existingReview ? tReviews('updating') : tReviews('submitting')) 
              : (existingReview ? tReviews('update') : tReviews('submit'))
            }
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
