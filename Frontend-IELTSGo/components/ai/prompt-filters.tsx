"use client"

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { X, Search } from "lucide-react"
import { cn } from "@/lib/utils"

export interface PromptFilters {
  task_type?: "task1" | "task2"
  part_number?: 1 | 2 | 3
  difficulty?: "easy" | "medium" | "hard"
  search?: string
}

interface PromptFiltersProps {
  type: "writing" | "speaking"
  filters: PromptFilters
  onFiltersChange: (filters: PromptFilters) => void
  onSearch?: (search: string) => void
}

export function PromptFiltersComponent({ 
  type, 
  filters, 
  onFiltersChange,
  onSearch 
}: PromptFiltersProps) {
  const [searchValue, setSearchValue] = useState(filters.search || "")

  const handleSearch = (value: string) => {
    setSearchValue(value)
    if (onSearch) {
      onSearch(value)
    } else {
      onFiltersChange({ ...filters, search: value || undefined })
    }
  }

  const handleFilterChange = (key: keyof PromptFilters, value: string | undefined) => {
    const newFilters = { ...filters }
    if (value && value !== "all") {
      newFilters[key] = value as any
    } else {
      delete newFilters[key]
    }
    onFiltersChange(newFilters)
  }

  const clearFilter = (key: keyof PromptFilters) => {
    const newFilters = { ...filters }
    delete newFilters[key]
    onFiltersChange(newFilters)
  }

  const clearAll = () => {
    setSearchValue("")
    onFiltersChange({})
  }

  const hasActiveFilters = Object.keys(filters).length > 0

  return (
    <Card>
      <CardContent className="pt-6">
        <div className="space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search prompts..."
              value={searchValue}
              onChange={(e) => handleSearch(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Filters */}
          <div className="flex flex-wrap items-center gap-3">
            {type === "writing" && (
              <Select
                value={filters.task_type || "all"}
                onValueChange={(value) => handleFilterChange("task_type", value)}
              >
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="Task Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Tasks</SelectItem>
                  <SelectItem value="task1">Task 1</SelectItem>
                  <SelectItem value="task2">Task 2</SelectItem>
                </SelectContent>
              </Select>
            )}

            {type === "speaking" && (
              <Select
                value={filters.part_number ? String(filters.part_number) : "all"}
                onValueChange={(value) => handleFilterChange("part_number", value)}
              >
                <SelectTrigger className="w-[140px]">
                  <SelectValue placeholder="Part" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Parts</SelectItem>
                  <SelectItem value="1">Part 1</SelectItem>
                  <SelectItem value="2">Part 2</SelectItem>
                  <SelectItem value="3">Part 3</SelectItem>
                </SelectContent>
              </Select>
            )}

            <Select
              value={filters.difficulty || "all"}
              onValueChange={(value) => handleFilterChange("difficulty", value)}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Difficulty" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Levels</SelectItem>
                <SelectItem value="easy">Easy</SelectItem>
                <SelectItem value="medium">Medium</SelectItem>
                <SelectItem value="hard">Hard</SelectItem>
              </SelectContent>
            </Select>

            {hasActiveFilters && (
              <Button
                variant="ghost"
                size="sm"
                onClick={clearAll}
                className="text-muted-foreground hover:text-foreground"
              >
                <X className="w-4 h-4 mr-1" />
                Clear All
              </Button>
            )}
          </div>

          {/* Active Filters Badges */}
          {hasActiveFilters && (
            <div className="flex flex-wrap gap-2">
              {filters.task_type && (
                <Badge variant="secondary" className="gap-1">
                  Task: {filters.task_type === "task1" ? "Task 1" : "Task 2"}
                  <button
                    onClick={() => clearFilter("task_type")}
                    className="ml-1 hover:bg-destructive/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </Badge>
              )}
              {filters.part_number && (
                <Badge variant="secondary" className="gap-1">
                  Part: {filters.part_number}
                  <button
                    onClick={() => clearFilter("part_number")}
                    className="ml-1 hover:bg-destructive/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </Badge>
              )}
              {filters.difficulty && (
                <Badge variant="secondary" className="gap-1">
                  {filters.difficulty}
                  <button
                    onClick={() => clearFilter("difficulty")}
                    className="ml-1 hover:bg-destructive/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </Badge>
              )}
              {filters.search && (
                <Badge variant="secondary" className="gap-1">
                  Search: {filters.search}
                  <button
                    onClick={() => {
                      setSearchValue("")
                      clearFilter("search")
                    }}
                    className="ml-1 hover:bg-destructive/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </Badge>
              )}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  )
}

