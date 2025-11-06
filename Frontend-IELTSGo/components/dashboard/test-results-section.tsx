"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useEffect, useState } from "react"
import { progressApi } from "@/lib/api/progress"
import { Award, TrendingUp, Target, Activity } from "lucide-react"
import { useTranslations } from "@/lib/i18n"

interface TestResult {
  id: string
  test_type: string
  skill_type: string
  band_score: number
  test_date: string
  test_source?: string
}

interface PracticeActivity {
  id: string
  skill: string
  activity_type: string
  accuracy_percentage?: number
  completed_at?: string
}

export function TestResultsSection() {
  const t = useTranslations('dashboard')
  const [testResults, setTestResults] = useState<TestResult[]>([])
  const [practiceStats, setPracticeStats] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchData() {
      try {
        const [testsData, practiceData] = await Promise.all([
          progressApi.getTestResults(undefined, 1, 5),
          progressApi.getPracticeStatistics()
        ])
        setTestResults(testsData.results)
        setPracticeStats(practiceData)
      } catch (error) {
        console.error('Error fetching test data:', error)
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card><CardContent className="p-6"><div className="h-[200px] flex items-center justify-center">Loading...</div></CardContent></Card>
        <Card><CardContent className="p-6"><div className="h-[200px] flex items-center justify-center">Loading...</div></CardContent></Card>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {/* Official Test Results */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Award className="h-5 w-5 text-yellow-500" />
              Official Test Scores
            </CardTitle>
            <Badge variant="secondary">
              {testResults.length} tests
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          {testResults.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <Target className="h-12 w-12 mx-auto mb-2 opacity-50" />
              <p>No official test results yet</p>
              <p className="text-sm">Complete a full IELTS test to see your band scores</p>
            </div>
          ) : (
            <div className="space-y-3">
              {testResults.map((result) => (
                <div
                  key={result.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-muted/50 hover:bg-muted transition-colors"
                >
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className="capitalize">
                        {result.skill_type}
                      </Badge>
                      <Badge variant="secondary" className="text-xs">
                        {result.test_type.replace('_', ' ')}
                      </Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {new Date(result.test_date).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-primary">
                      {result.band_score.toFixed(1)}
                    </div>
                    <p className="text-xs text-muted-foreground">Band Score</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Practice Statistics */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5 text-blue-500" />
              Practice Activities
            </CardTitle>
            <Badge variant="secondary">
              {practiceStats?.total_activities || 0} activities
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          {!practiceStats || practiceStats.total_activities === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <TrendingUp className="h-12 w-12 mx-auto mb-2 opacity-50" />
              <p>No practice activities yet</p>
              <p className="text-sm">Start practicing to track your progress</p>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Overall Stats */}
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 rounded-lg bg-muted/50">
                  <p className="text-xs text-muted-foreground">Avg Accuracy</p>
                  <p className="text-xl font-bold">
                    {practiceStats.average_accuracy?.toFixed(1) || 0}%
                  </p>
                </div>
                <div className="p-3 rounded-lg bg-muted/50">
                  <p className="text-xs text-muted-foreground">Total Time</p>
                  <p className="text-xl font-bold">
                    {Math.round((practiceStats.total_time_spent_seconds || 0) / 60)} min
                  </p>
                </div>
              </div>

              {/* By Activity Type */}
              <div className="space-y-2">
                <p className="text-sm font-medium">By Activity Type</p>
                {practiceStats.activities_by_type?.map((type: any) => (
                  <div
                    key={type.activity_type}
                    className="flex items-center justify-between p-2 rounded bg-muted/30"
                  >
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className="text-xs capitalize">
                        {type.activity_type.replace('_', ' ')}
                      </Badge>
                      <span className="text-sm text-muted-foreground">
                        {type.count}x
                      </span>
                    </div>
                    <span className="text-sm font-medium">
                      {type.average_accuracy?.toFixed(1) || 0}%
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
