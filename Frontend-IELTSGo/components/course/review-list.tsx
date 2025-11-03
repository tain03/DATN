"use client"

import { useState, useEffect, useMemo } from "react"
import { Star, MessageSquare, ThumbsUp, MoreVertical, Trash2, ChevronDown, ChevronUp } from "lucide-react"
import Link from "next/link"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { PageLoading } from "@/components/ui/page-loading"
import { EmptyState } from "@/components/ui/empty-state"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu"
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
import { coursesApi } from "@/lib/api/courses"
import { getCardVariant } from "@/lib/utils/card-variants"
import { cn } from "@/lib/utils"
import { useTranslations } from "@/lib/i18n"
import { formatRelativeDate } from "@/lib/utils/format-date-i18n"
import { useAuth } from "@/lib/contexts/auth-context"
import { useToast } from "@/hooks/use-toast"

interface Review {
  id: string
  user_id: string
  course_id: string
  rating: number
  title?: string
  comment?: string
  helpful_count: number
  is_approved: boolean
  created_at: string
  user_name?: string
  user_email?: string
  user_avatar_url?: string
}

interface ReviewListProps {
  courseId: string
  refreshTrigger?: number // For triggering refresh from parent
}

export function ReviewList({ courseId, refreshTrigger }: ReviewListProps) {
  const t = useTranslations('common')
  const tReviews = useTranslations('reviews')
  const { user } = useAuth()
  const { toast } = useToast()
  const [reviews, setReviews] = useState<Review[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [sortBy, setSortBy] = useState<"newest" | "oldest" | "highest" | "lowest">("newest")
  const [filterRating, setFilterRating] = useState<number | null>(null)
  const [expandedComments, setExpandedComments] = useState<Set<string>>(new Set())
  const [deleteDialogOpen, setDeleteDialogOpen] = useState<string | null>(null)
  const [helpfulLoading, setHelpfulLoading] = useState<Set<string>>(new Set())
  const COMMENT_PREVIEW_LENGTH = 200

  useEffect(() => {
    const fetchReviews = async () => {
      try {
        setLoading(true)
        const response = await coursesApi.getCourseReviews(courseId, page, 10)
        // Backend returns { reviews: [], total, page, limit, total_pages }
        setReviews(response?.reviews || [])
        setTotalPages(response?.totalPages || 1)
      } catch (error) {
        console.error("[ReviewList] Failed to fetch reviews:", error)
        setReviews([])
      } finally {
        setLoading(false)
      }
    }

    fetchReviews()
  }, [courseId, refreshTrigger, page])

  // Filter and sort reviews - MUST be called before any conditional returns
  const filteredAndSortedReviews = useMemo(() => {
    let filtered = [...reviews]
    
    // Filter by rating
    if (filterRating !== null) {
      filtered = filtered.filter(r => r.rating === filterRating)
    }
    
    // Sort
    filtered.sort((a, b) => {
      switch (sortBy) {
        case "newest":
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        case "oldest":
          return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        case "highest":
          return b.rating - a.rating
        case "lowest":
          return a.rating - b.rating
        default:
          return 0
      }
    })
    
    return filtered
  }, [reviews, sortBy, filterRating])

  // All hooks must be defined before any conditional returns
  const handleMarkHelpful = async (reviewId: string) => {
    // TODO: Implement API call when backend supports it
    if (helpfulLoading.has(reviewId)) return
    
    setHelpfulLoading(prev => new Set(prev).add(reviewId))
    
    try {
      // Simulate API call - will be replaced with actual API
      await new Promise(resolve => setTimeout(resolve, 300))
      
      setReviews(prev => prev.map(r => 
        r.id === reviewId 
          ? { ...r, helpful_count: r.helpful_count + 1 }
          : r
      ))
      
      toast({
        title: t('success'),
        description: tReviews('mark_helpful') || "Đã đánh dấu hữu ích",
      })
    } catch (error) {
      toast({
        title: t('error'),
        description: tReviews('error_submit') || "Không thể đánh dấu hữu ích",
        variant: "destructive",
      })
    } finally {
      setHelpfulLoading(prev => {
        const next = new Set(prev)
        next.delete(reviewId)
        return next
      })
    }
  }

  const handleDeleteReview = async (reviewId: string) => {
    try {
      // TODO: Implement delete API when backend supports it
      // await coursesApi.deleteCourseReview(courseId, reviewId)
      
      setReviews(prev => prev.filter(r => r.id !== reviewId))
      setDeleteDialogOpen(null)
      
      toast({
        title: t('success'),
        description: tReviews('delete_success') || "Đã xóa đánh giá thành công",
      })
    } catch (error) {
      toast({
        title: t('error'),
        description: tReviews('delete_error') || "Không thể xóa đánh giá",
        variant: "destructive",
      })
    }
  }

  const toggleCommentExpansion = (reviewId: string) => {
    setExpandedComments(prev => {
      const next = new Set(prev)
      if (next.has(reviewId)) {
        next.delete(reviewId)
      } else {
        next.add(reviewId)
      }
      return next
    })
  }

  // Calculate review statistics - Memoized
  const { totalReviews, averageRating, ratingDistribution } = useMemo(() => {
    const total = reviews.length
    const avg = total > 0 
      ? reviews.reduce((sum, r) => sum + r.rating, 0) / total 
      : 0
    const distribution = [5, 4, 3, 2, 1].map(rating => ({
      rating,
      count: reviews.filter(r => r.rating === rating).length,
      percentage: total > 0 
        ? (reviews.filter(r => r.rating === rating).length / total) * 100 
        : 0
    }))
    return { totalReviews: total, averageRating: avg, ratingDistribution: distribution }
  }, [reviews])

  // Now safe to have conditional returns
  if (loading) {
    return (
      <Card>
        <CardContent className="py-12">
          <PageLoading translationKey="loading" />
        </CardContent>
      </Card>
    )
  }

  if (!reviews || reviews.length === 0) {
    return (
      <EmptyState
        icon={MessageSquare}
        title={tReviews('no_reviews_title') || t('no_reviews') || "Chưa có đánh giá nào"}
        description={tReviews('no_reviews_description') || t('no_reviews_description') || "Hãy là người đầu tiên đánh giá khóa học này!"}
      />
    )
  }

  return (
    <div className="space-y-4">
      {/* Review Statistics and Filters - Compact */}
      <div className="space-y-3">
        {/* Statistics - More Compact */}
        <Card className="bg-gradient-to-br from-blue-50/50 to-indigo-50/50 dark:from-blue-950/10 dark:to-indigo-950/10 border-blue-100 dark:border-blue-900">
          <CardContent className="p-3.5">
            <div className="flex items-center justify-between flex-wrap gap-3">
              <div className="flex items-center gap-4">
                <div>
                  <p className="text-xs text-muted-foreground mb-0.5">{tReviews('average_rating')}</p>
                  <div className="flex items-center gap-1.5">
                    <span className="text-xl font-bold">{averageRating.toFixed(1)}</span>
                    <div className="flex gap-0.5">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star
                          key={i}
                          className={cn(
                            "w-3.5 h-3.5",
                            i < Math.round(averageRating)
                              ? "fill-yellow-400 text-yellow-400"
                              : "text-gray-300 dark:text-gray-600"
                          )}
                        />
                      ))}
                    </div>
                  </div>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-0.5">{tReviews('total_reviews')}</p>
                  <p className="text-lg font-bold">{totalReviews}</p>
                </div>
              </div>
              
              {/* Rating Distribution - Compact */}
              <div className="hidden md:flex flex-col gap-1">
                {ratingDistribution.reverse().map(({ rating, count, percentage }) => (
                  <div key={rating} className="flex items-center gap-1.5 min-w-[100px]">
                    <div className="flex items-center gap-0.5">
                      <span className="text-xs font-medium w-3">{rating}</span>
                      <Star className="w-2.5 h-2.5 fill-yellow-400 text-yellow-400" />
                    </div>
                    <div className="flex-1 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-yellow-400 transition-all duration-300"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                    <span className="text-[10px] text-muted-foreground w-6 text-right">{count}</span>
                  </div>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Filters and Sort - Compact */}
        <div className="flex flex-col sm:flex-row gap-2">
          <Select value={filterRating?.toString() || "all"} onValueChange={(value) => {
            setFilterRating(value === "all" ? null : parseInt(value))
          }}>
            <SelectTrigger className="w-full sm:w-[160px] h-9 text-sm">
              <SelectValue placeholder={tReviews('filter_by_rating')} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">{tReviews('filter_all')}</SelectItem>
              <SelectItem value="5">{tReviews('filter_5_stars')}</SelectItem>
              <SelectItem value="4">{tReviews('filter_4_stars')}</SelectItem>
              <SelectItem value="3">{tReviews('filter_3_stars')}</SelectItem>
              <SelectItem value="2">{tReviews('filter_2_stars')}</SelectItem>
              <SelectItem value="1">{tReviews('filter_1_star')}</SelectItem>
            </SelectContent>
          </Select>

          <Select value={sortBy} onValueChange={(value: any) => setSortBy(value)}>
            <SelectTrigger className="w-full sm:w-[160px] h-9 text-sm">
              <SelectValue placeholder={tReviews('sort_by')} />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="newest">{tReviews('sort_newest')}</SelectItem>
              <SelectItem value="oldest">{tReviews('sort_oldest')}</SelectItem>
              <SelectItem value="highest">{tReviews('sort_highest_rating')}</SelectItem>
              <SelectItem value="lowest">{tReviews('sort_lowest_rating')}</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Reviews List - Compact */}
      {filteredAndSortedReviews.length === 0 ? (
        <Card>
          <CardContent className="py-8">
            <EmptyState
              icon={MessageSquare}
              title={tReviews('no_reviews_title') || "Không có đánh giá"}
              description={tReviews('no_reviews_description') || "Không có đánh giá phù hợp với bộ lọc của bạn"}
            />
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filteredAndSortedReviews.map((review) => {
            const isOwnReview = user?.id === review.user_id
            const isExpanded = expandedComments.has(review.id)
            const isLongComment = review.comment && review.comment.length > COMMENT_PREVIEW_LENGTH
            const showPreview = isLongComment && !isExpanded
            const commentToShow = showPreview 
              ? review.comment!.substring(0, COMMENT_PREVIEW_LENGTH) + "..."
              : review.comment

            return (
              <Card 
                key={review.id}
                className={cn(
                  "group relative overflow-hidden",
                  "bg-white dark:bg-card",
                  "border border-gray-200 dark:border-border",
                  "shadow-sm hover:shadow-md",
                  "transition-all duration-200 ease-in-out",
                  "hover:border-primary/20 dark:hover:border-primary/30",
                  "rounded-lg",
                  isOwnReview && "ring-1 ring-primary/20"
                )}
              >
                {/* Subtle accent bar on top for visual interest */}
                <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-primary/20 via-primary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                
                <CardContent className="px-3 py-2">
                  <div className="flex items-start gap-2.5">
                    {/* Avatar - Smaller */}
                    <Link 
                      href={`/users/${review.user_id}`}
                      className="hover:opacity-90 transition-opacity flex-shrink-0"
                    >
                      <Avatar className="h-10 w-10 cursor-pointer ring-1 ring-gray-100 dark:ring-gray-800 shadow-sm hover:ring-primary/30 transition-all duration-200">
                        {review.user_avatar_url && (
                          <AvatarImage src={review.user_avatar_url} alt={review.user_name || review.user_email || 'avatar'} />
                        )}
                        <AvatarFallback className="bg-gradient-to-br from-primary/20 to-primary/10 text-primary font-semibold text-sm border border-primary/10">
                          {review.user_name 
                            ? review.user_name
                                .split(" ")
                                .map(word => word[0])
                                .slice(0, 2)
                                .join("")
                                .toUpperCase()
                            : "U"}
                        </AvatarFallback>
                      </Avatar>
                    </Link>
                    
                    <div className="flex-1 min-w-0 space-y-1">
                      {/* User info row - Compact */}
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5 mb-0 flex-wrap">
                            <Link 
                              href={`/users/${review.user_id}`}
                              className="font-semibold text-base text-gray-900 dark:text-foreground hover:text-primary transition-colors cursor-pointer line-clamp-1"
                            >
                              {review.user_name || tReviews('anonymous_user') || "Người dùng ẩn danh"}
                            </Link>
                            {isOwnReview && (
                              <Badge variant="secondary" className="text-[10px] px-1.5 py-0 h-4">
                                {t('you') || "Bạn"}
                              </Badge>
                            )}
                            <span className="text-xs text-gray-400 dark:text-muted-foreground">•</span>
                            <span className="text-xs text-gray-500 dark:text-muted-foreground">
                              {formatRelativeDate(review.created_at, tReviews)}
                            </span>
                          </div>
                          
                          {/* Star rating - Compact */}
                          <div className="flex items-center gap-1.5 mt-0.5">
                            <div className="flex gap-0.5 items-center">
                              {Array.from({ length: 5 }).map((_, i) => (
                                <Star
                                  key={i}
                                  className={cn(
                                    "w-3.5 h-3.5 transition-colors",
                                    i < review.rating
                                      ? "fill-yellow-400 text-yellow-400"
                                      : "text-gray-200 dark:text-gray-700"
                                  )}
                                />
                              ))}
                            </div>
                            {review.rating > 0 && (
                              <span className="text-sm font-semibold text-gray-700 dark:text-foreground">
                                {review.rating}/5
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Actions menu (only for own reviews) - Smaller */}
                        {isOwnReview && (
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-7 w-7">
                                <MoreVertical className="h-3.5 w-3.5" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem
                                onClick={() => setDeleteDialogOpen(review.id)}
                                className="text-destructive text-sm"
                              >
                                <Trash2 className="h-3.5 w-3.5 mr-2" />
                                {tReviews('delete_review')}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        )}
                      </div>
                      
                      {/* Review title - Compact */}
                      {review.title && (
                        <div className="mt-1">
                          <h4 className="font-semibold text-base text-gray-900 dark:text-foreground line-clamp-2 leading-snug">
                            {review.title}
                          </h4>
                        </div>
                      )}
                      
                      {/* Review comment - Compact */}
                      {review.comment && (
                        <div className="mt-1">
                          <p className="text-base text-gray-700 dark:text-muted-foreground leading-normal whitespace-pre-wrap break-words">
                            {commentToShow}
                          </p>
                          {isLongComment && (
                            <button
                              onClick={() => toggleCommentExpansion(review.id)}
                              className="mt-0.5 text-xs text-primary hover:underline font-medium flex items-center gap-1"
                            >
                              {isExpanded ? (
                                <>
                                  {tReviews('show_less')} <ChevronUp className="h-3 w-3" />
                                </>
                              ) : (
                                <>
                                  {tReviews('show_more')} <ChevronDown className="h-3 w-3" />
                                </>
                              )}
                            </button>
                          )}
                        </div>
                      )}
                      
                      {/* Empty state message - Compact */}
                      {!review.title && !review.comment && (
                        <div className="mt-1">
                          <p className="text-sm text-gray-400 dark:text-muted-foreground italic">
                            {tReviews('no_content') || "Đánh giá này chỉ có xếp hạng sao"}
                          </p>
                        </div>
                      )}

                      {/* Helpful button and count - Compact */}
                      <div className="flex items-center gap-3 pt-1 mt-1 border-t border-border/50">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleMarkHelpful(review.id)}
                          disabled={helpfulLoading.has(review.id)}
                          className="h-7 gap-1 text-xs text-muted-foreground hover:text-primary px-2"
                        >
                          <ThumbsUp className={cn(
                            "h-3 w-3 transition-colors",
                            helpfulLoading.has(review.id) && "animate-pulse"
                          )} />
                          <span className="text-xs">
                            {tReviews('helpful')}
                          </span>
                          {review.helpful_count > 0 && (
                            <span className="text-xs font-medium">
                              ({review.helpful_count})
                            </span>
                          )}
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>

                {/* Delete Confirmation Dialog */}
                <AlertDialog open={deleteDialogOpen === review.id} onOpenChange={(open) => {
                  if (!open) setDeleteDialogOpen(null)
                }}>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>{tReviews('delete_review')}</AlertDialogTitle>
                      <AlertDialogDescription>
                        {tReviews('delete_confirm')}
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>{t('cancel')}</AlertDialogCancel>
                      <AlertDialogAction
                        onClick={() => handleDeleteReview(review.id)}
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                      >
                        {tReviews('delete_review')}
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </Card>
            )
          })}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-2 mt-4 pt-4 border-t">
          <Button
            variant="outline"
            size="sm"
            disabled={page === 1 || loading}
            onClick={() => setPage(p => Math.max(1, p - 1))}
          >
            {t('previous') || "Trước"}
          </Button>
          <span className="text-sm text-muted-foreground">
            {t('page_of', { page: page.toString(), totalPages: totalPages.toString() }) || `Trang ${page}/${totalPages}`}
          </span>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= totalPages || loading}
            onClick={() => setPage(p => Math.min(totalPages, p + 1))}
          >
            {t('next') || "Sau"}
          </Button>
        </div>
      )}
    </div>
  )
}

