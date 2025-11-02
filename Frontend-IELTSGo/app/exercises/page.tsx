"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { AppLayout } from "@/components/layout/app-layout"
import { PageLoading } from "@/components/ui/page-loading"

export default function ExercisesPage() {
  const router = useRouter()

  useEffect(() => {
    // Redirect to exercise list page
    router.push("/exercises/list")
  }, [router])

  return (
    <AppLayout>
      <div className="flex items-center justify-center min-h-[60vh]">
        <PageLoading translationKey="loading" />
      </div>
    </AppLayout>
  )
}
