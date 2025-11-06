"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Award, Activity, Info } from "lucide-react"

export function ScoringSystemInfo() {
  return (
    <Alert className="mb-6">
      <Info className="h-4 w-4" />
      <AlertDescription className="ml-2">
        <div className="space-y-2">
          <p className="font-medium">Understanding Your Scores:</p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <div className="flex items-start gap-2">
              <Award className="h-4 w-4 mt-0.5 text-yellow-500 flex-shrink-0" />
              <div>
                <span className="font-medium">Official Test Scores:</span> Your IELTS band scores (0-9) from completed full tests. These represent your actual performance level.
              </div>
            </div>
            <div className="flex items-start gap-2">
              <Activity className="h-4 w-4 mt-0.5 text-blue-500 flex-shrink-0" />
              <div>
                <span className="font-medium">Practice Activities:</span> Your accuracy (%) in drills and practice exercises. These help you prepare but don't affect your official band scores.
              </div>
            </div>
          </div>
        </div>
      </AlertDescription>
    </Alert>
  )
}
