"use client"

// Re-export recharts components directly (Next.js will handle code splitting automatically)
// Using direct imports with proper webpack chunking in next.config.mjs
export {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts"

