"use client"

import React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { useMemo } from "react"
import { EmptyState } from "./empty-state"

interface DataPoint {
  date: string
  value: number
}

interface ProgressChartProps {
  title: string
  data: DataPoint[]
  color?: string
  valueLabel?: string
}

function ProgressChartComponent({ title, data, color = "#ED372A", valueLabel = "Value" }: ProgressChartProps) {
  const maxValue = useMemo(() => {
    if (!data || data.length === 0) return 100
    const values = data.map((d) => d.value).filter(v => typeof v === 'number' && !isNaN(v))
    if (values.length === 0) return 100
    return Math.max(...values, 1)
  }, [data])

  const chartHeight = 200
  const minBarHeight = 16 // Minimum 16px for visibility
  
  // Ensure data is valid
  const validData = data?.filter(d => d && typeof d.value === 'number' && !isNaN(d.value)) || []

  const hasData = validData.length > 0

  return (
    <Card className="overflow-hidden">
      <CardHeader className="pb-3">
        <CardTitle className="text-lg font-semibold">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {!hasData ? (
          <EmptyState 
            type="chart"
            title="Chưa có dữ liệu học tập"
            description="Bắt đầu học để xem biểu đồ tiến độ của bạn theo thời gian"
            actionLabel="Khám phá khóa học"
            actionHref="/courses"
          />
        ) : (
        <div className="relative" style={{ height: chartHeight }}>
          {/* Y-axis labels */}
          <div className="absolute left-0 top-0 bottom-0 flex flex-col justify-between text-xs text-muted-foreground pr-2">
            <span>{maxValue.toFixed(0)}</span>
            <span>{Math.round(maxValue / 2)}</span>
            <span>0</span>
          </div>

          {/* Chart area */}
          <div className="ml-8 flex items-end justify-between gap-1" style={{ height: chartHeight }}>
            {validData.map((point, index) => {
              // Calculate height in PIXELS (not percentage) to avoid flexbox issues
              const heightPx = (point.value / maxValue) * chartHeight
              // Ensure minimum visible height for small values
              const displayHeightPx = point.value > 0 ? Math.max(heightPx, minBarHeight) : 0
              const isSmallValue = heightPx < minBarHeight && point.value > 0
              
              return (
                <div key={index} className="flex-1 flex items-end justify-center group relative">
                  {/* Bar */}
                  <div
                    className="w-full rounded-t transition-all hover:opacity-80 cursor-pointer relative"
                    style={{
                      height: `${displayHeightPx}px`,
                      backgroundColor: color,
                    }}
                  >
                    {/* Tooltip */}
                    <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-10">
                      {point.value} {valueLabel}
                      <div className="text-[10px] text-gray-300">
                        {new Date(point.date).toLocaleDateString("vi-VN", {
                          month: "short",
                          day: "numeric",
                        })}
                      </div>
                    </div>
                    
                    {/* Indicator for very small values */}
                    {isSmallValue && (
                      <div className="absolute -top-3 left-1/2 -translate-x-1/2 text-[9px] text-muted-foreground">
                        ↓
                      </div>
                    )}
                  </div>
                </div>
              )
            })}
          </div>

          {/* X-axis labels */}
          <div className="ml-8 mt-2 flex justify-between text-xs text-muted-foreground">
            {validData.length > 0 && (
              <>
                <span>
                  {new Date(validData[0].date).toLocaleDateString("vi-VN", {
                    month: "short",
                    day: "numeric",
                  })}
                </span>
                <span>
                  {new Date(validData[validData.length - 1].date).toLocaleDateString("vi-VN", {
                    month: "short",
                    day: "numeric",
                  })}
                </span>
              </>
            )}
          </div>
        </div>
        )}
      </CardContent>
    </Card>
  )
}

export const ProgressChart = React.memo(ProgressChartComponent)
