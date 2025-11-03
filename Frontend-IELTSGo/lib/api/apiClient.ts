import axios, { type AxiosInstance, type AxiosError, type InternalAxiosRequestConfig } from "axios"

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
  timeout: 15000, // Reduce timeout from 30s to 15s for faster failure
})

// Request interceptor - Add JWT token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getToken()
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // No logging for cleaner console

    return config
  },
  (error: AxiosError) => {
    return Promise.reject(error)
  },
)

// Response interceptor - Handle errors and token refresh
apiClient.interceptors.response.use(
  (response) => {
    // No logging for cleaner console
    return response
  },
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    // Handle 401 Unauthorized
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        // Try to refresh token
        const refreshToken = getRefreshToken()
        if (refreshToken) {
          const response = await axios.post(`${API_BASE_URL}/auth/refresh`, {
            // Backend expects snake_case: refresh_token
            refresh_token: refreshToken,
          })

          const { token } = response.data
          setToken(token)

          // Retry original request with new token
          if (originalRequest.headers) {
            originalRequest.headers.Authorization = `Bearer ${token}`
          }
          return apiClient(originalRequest)
        }
      } catch (refreshError) {
        // Refresh failed, redirect to login
        removeToken()
        removeRefreshToken()
        if (typeof window !== "undefined") {
          window.location.href = "/login"
        }
        return Promise.reject(refreshError)
      }
    }

        // Handle other errors
    if (process.env.NODE_ENV === "development") {
      // Don't log 404 errors for unimplemented endpoints
      const is404UnimplementedEndpoint =
        error.response?.status === 404 && 
        (originalRequest.url?.includes("/progress") || 
         originalRequest.url?.includes("/admin/analytics") ||
         originalRequest.url?.includes("/admin/activities"))

      // Don't log 403 errors for private profiles (expected behavior)
      const is403PrivateProfile =
        error.response?.status === 403 &&
        originalRequest.url?.includes("/users/") &&
        originalRequest.url?.includes("/profile")

      // Don't log 400 errors for register/login (expected validation errors, will be shown to user)
      const is400AuthEndpoint =
        error.response?.status === 400 &&
        (originalRequest.url?.includes("/auth/register") ||
         originalRequest.url?.includes("/auth/login"))

      if (!is404UnimplementedEndpoint && !is403PrivateProfile && !is400AuthEndpoint) {
        console.error("[API Error]", error.response?.status, error.message)
      } else if (is403PrivateProfile) {
        // Log as info instead of error for private profiles
        console.log("[API Info] Profile is private (403)")
      } else if (is400AuthEndpoint) {
        // Log validation errors as warnings (expected behavior)
        console.log("[API Validation]", error.response?.status, error.response?.data?.error?.message || error.message)
      }
    }

    return Promise.reject(error)
  },
)

// Token management functions
function getToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("access_token")
}

function setToken(token: string): void {
  if (typeof window === "undefined") return
  localStorage.setItem("access_token", token)
}

function removeToken(): void {
  if (typeof window === "undefined") return
  localStorage.removeItem("access_token")
}

function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null
  return localStorage.getItem("refresh_token")
}

function setRefreshToken(token: string): void {
  if (typeof window === "undefined") return
  localStorage.setItem("refresh_token", token)
}

function removeRefreshToken(): void {
  if (typeof window === "undefined") return
  localStorage.removeItem("refresh_token")
}

// Export API client and token functions
export { apiClient, getToken, setToken, removeToken, getRefreshToken, setRefreshToken, removeRefreshToken }

// Export typed API methods
export const api = {
  get: <T = any>(url: string, config?: any) => apiClient.get<T>(url, config),
  post: <T = any>(url: string, data?: any, config?: any) => apiClient.post<T>(url, data, config),
  put: <T = any>(url: string, data?: any, config?: any) => apiClient.put<T>(url, data, config),
  patch: <T = any>(url: string, data?: any, config?: any) => apiClient.patch<T>(url, data, config),
  delete: <T = any>(url: string, config?: any) => apiClient.delete<T>(url, config),
}
