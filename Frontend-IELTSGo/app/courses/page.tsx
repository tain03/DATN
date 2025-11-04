"use client"

import { useState, useEffect, useCallback, useMemo } from "react"
import { AppLayout } from "@/components/layout/app-layout"
import { PageContainer } from "@/components/layout/page-container"
import { CourseCard } from "@/components/courses/course-card"
import { CourseFiltersComponent } from "@/components/courses/course-filters"
import { Button } from "@/components/ui/button"
import { PageLoading } from "@/components/ui/page-loading"
import { SkeletonCard } from "@/components/ui/skeleton-card"
import { EmptyState } from "@/components/ui/empty-state"
import { BookOpen } from "lucide-react"
import { coursesApi, type CourseFilters } from "@/lib/api/courses"
import type { Course } from "@/types"
import { useTranslations } from '@/lib/i18n'

export default function CoursesPage() {

  const tCourses = useTranslations('courses')
  const t = useTranslations('common')

  const [courses, setCourses] = useState<Course[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [filters, setFilters] = useState<CourseFilters>({})
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  // Use stable filter key to trigger refetch only when filters actually change
  const filterKey = useMemo(() => {
    return JSON.stringify({
      search: filters.search || '',
      skill_type: filters.skill_type || '',
      level: filters.level || '',
      enrollment_type: filters.enrollment_type || '',
      is_featured: filters.is_featured !== undefined ? filters.is_featured : '',
      sort: filters.sort || '',
      sort_order: filters.sort_order || '',
    })
  }, [filters.search, filters.skill_type, filters.level, filters.enrollment_type, filters.is_featured, filters.sort, filters.sort_order])

  // Fetch courses when filters or page changes
  useEffect(() => {
    let isMounted = true
    
    const fetchCourses = async () => {
      try {
        setLoading(true)
        setError(null)
        const response = await coursesApi.getCourses(filters, page, 12)

        if (!isMounted) return

        setCourses(Array.isArray(response.data) ? response.data : [])
        setTotalPages(response.totalPages || 1)
      } catch (error) {
        if (!isMounted) return
        console.error("[v0] Failed to fetch courses:", error)
        setError(tCourses('failed_to_load_courses_please_try_again_'))
        setCourses([])
      } finally {
        if (isMounted) {
          setLoading(false)
        }
      }
    }

    fetchCourses()

    return () => {
      isMounted = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterKey, page]) // filterKey is stable string, page is primitive

  // Refetch function for error retry
  const refetchCourses = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await coursesApi.getCourses(filters, page, 12)
      setCourses(Array.isArray(response.data) ? response.data : [])
      setTotalPages(response.totalPages || 1)
    } catch (error) {
      console.error("[v0] Failed to fetch courses:", error)
      setError(tCourses('failed_to_load_courses_please_try_again_'))
      setCourses([])
    } finally {
      setLoading(false)
    }
  }, [filters, page, tCourses])

  const handleFiltersChange = (newFilters: CourseFilters) => {
    // Remove undefined and empty values to ensure clean filter state
    const cleanFilters: CourseFilters = {}
    if (newFilters.search && newFilters.search.trim()) {
      cleanFilters.search = newFilters.search.trim()
    }
    if (newFilters.skill_type) {
      cleanFilters.skill_type = newFilters.skill_type
    }
    if (newFilters.level) {
      cleanFilters.level = newFilters.level
    }
    if (newFilters.enrollment_type) {
      cleanFilters.enrollment_type = newFilters.enrollment_type
    }
    if (newFilters.is_featured !== undefined) {
      cleanFilters.is_featured = newFilters.is_featured
    }
    if (newFilters.sort) {
      cleanFilters.sort = newFilters.sort
      // Always include sort_order when sort is set
      cleanFilters.sort_order = newFilters.sort_order || "desc"
    }
    // Always set to clean object (even if empty) to clear all filters
    setFilters(cleanFilters)
    setPage(1)
  }

  const handleSearch = (search: string) => {
    setFilters((prev) => ({ ...prev, search: search || undefined }))
    setPage(1)
  }

  return (
    <AppLayout showFooter={true}>
      <PageContainer>
        <div className="mb-8">
          <h1 className="text-3xl font-bold tracking-tight mb-2">{tCourses('explore_courses')}</h1>
          <p className="text-base text-muted-foreground">
            {tCourses('description')}
          </p>
        </div>

        <CourseFiltersComponent filters={filters} onFiltersChange={handleFiltersChange} onSearch={handleSearch} />

        {loading ? (
          <>
            <SkeletonCard gridCols={3} count={6} className="mt-8" />
          </>
        ) : error ? (
          <EmptyState
            icon={BookOpen}
            title={error}
            description={t('please_try_again_later') || "Please try again later"}
            actionLabel={t('try_again') || "Try Again"}
            actionOnClick={refetchCourses}
            className="mt-8"
          />
        ) : courses.length === 0 ? (
          <EmptyState
            icon={BookOpen}
            title={tCourses('no_courses_found_matching_your_criteria')}
            description={tCourses('try_adjusting_your_filters') || "Try adjusting your filters or search terms"}
            actionLabel={t('clear_filters') || "Clear Filters"}
            actionOnClick={() => handleFiltersChange({})}
            className="mt-8"
          />
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8">
              {courses.map((course, index) => (
                <CourseCard 
                  key={course.id} 
                  course={course}
                  priority={index < 3} // Priority for first 3 above-fold cards
                />
              ))}
            </div>

            {totalPages > 1 && (
              <div className="flex items-center justify-center gap-2 mt-8">
                <Button
                  variant="outline"
                  disabled={page === 1}
                  onClick={() => setPage(page - 1)}
                  className="bg-transparent"
                >
                  {t('previous')}
                </Button>
                <span className="text-sm text-muted-foreground">
                  {t('page_of', { page, totalPages })}
                </span>
                <Button
                  variant="outline"
                  disabled={page === totalPages}
                  onClick={() => setPage(page + 1)}
                  className="bg-transparent"
                >
                  {t('next')}
                </Button>
              </div>
            )}
          </>
        )}
      </PageContainer>
    </AppLayout>
  )
}
