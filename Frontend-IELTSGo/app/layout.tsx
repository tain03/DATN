import type React from "react"
import type { Metadata } from "next"
import { Noto_Sans, Noto_Sans_Display } from "next/font/google"
import "./globals.css"
import { AuthProvider } from "@/lib/contexts/auth-context"
import { PreferencesProvider } from "@/lib/contexts/preferences-context"
import { ThemeProvider } from "@/components/theme-provider"
import { LocaleSync } from "@/components/layout/locale-sync"
import { Toaster } from "@/components/ui/sonner"
import "@/lib/utils/console-filter"

const notoSans = Noto_Sans({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-sans",
  display: "swap",
})

const notoSansDisplay = Noto_Sans_Display({
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-heading",
  display: "swap",
})

export const metadata: Metadata = {
  title: "IELTSGo - Chinh phục IELTS",
  description: "Nền tảng học IELTS toàn diện với khóa học, bài tập và theo dõi tiến độ",
  keywords: ["IELTS", "Học Tiếng Anh", "Luyện Thi", "Khóa Học Trực Tuyến"],
  generator: 'v0.app'
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="vi" className={`${notoSans.variable} ${notoSansDisplay.variable}`} suppressHydrationWarning>
      <body className="antialiased" suppressHydrationWarning>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          <AuthProvider>
            <PreferencesProvider>
              <LocaleSync />
              {children}
              <Toaster position="top-right" richColors closeButton />
            </PreferencesProvider>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}
